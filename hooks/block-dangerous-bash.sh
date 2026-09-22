#!/usr/bin/env bash
# block-dangerous-bash.sh
# PreToolUse hook for Bash — blocks destructive commands regardless of permissions.
# Exit 2 = block the tool call. Exit 0 = allow.
#
# Input: JSON on stdin with tool_input.command
# Depends on: jq

set -euo pipefail

INPUT="$(cat)"
COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"

# Empty command — nothing to check
[ -z "$COMMAND" ] && exit 0

# Patterns that are hard-blocked. Each is a Basic Regular Expression (grep -E).
# Order doesn't matter; first match wins.
declare -a DANGEROUS_PATTERNS=(
  # Filesystem destruction
  'rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)[[:space:]]+(/|~|\$HOME|\*)'
  'rm[[:space:]]+--no-preserve-root'
  'sudo[[:space:]]+rm'
  'chmod[[:space:]]+-R[[:space:]]+000[[:space:]]+/'
  'chown[[:space:]]+-R[[:space:]]+[^[:space:]]+[[:space:]]+/'
  # Disk destruction
  'dd[[:space:]]+.*of=/dev/(sda|nvme|disk|hda)'
  'mkfs\.'
  '>[[:space:]]*/dev/(sda|nvme|disk|hda)'
  # Fork bomb
  ':\(\)\{[[:space:]]*:\|:&[[:space:]]*\};:'
  # Network exec (curl|bash, wget|bash)
  'curl[[:space:]]+[^|]*\|[[:space:]]*(bash|sh|zsh|fish)([[:space:]]|$)'
  'wget[[:space:]]+[^|]*\|[[:space:]]*(bash|sh|zsh|fish)([[:space:]]|$)'
  # Git destructive ops on protected branches
  'git[[:space:]]+push[[:space:]]+.*(--force|--force-with-lease|-[a-zA-Z]*f[a-zA-Z]*)[[:space:]]+(origin|upstream)[[:space:]]+(main|master|production|release)'
  'git[[:space:]]+push[[:space:]]+.*:.*[[:space:]]+(origin|upstream)[[:space:]]+(main|master|production|release)' # delete remote branch
  'git[[:space:]]+reset[[:space:]]+.*--hard[[:space:]]+origin/(main|master|production)'
  'git[[:space:]]+filter-branch'
  'git[[:space:]]+clean[[:space:]]+.*-[a-zA-Z]*f[a-zA-Z]*d'
  # Database destruction
  'DROP[[:space:]]+DATABASE'
  'DROP[[:space:]]+TABLE[[:space:]]+[^;]*(;|$)' # DROP TABLE anything
  'TRUNCATE[[:space:]]+TABLE'
  'prisma[[:space:]]+migrate[[:space:]]+reset'
  'prisma[[:space:]]+db[[:space:]]+push[[:space:]]+.*--force-reset'
  # Package publishing (never accidental)
  'npm[[:space:]]+publish'
  'pnpm[[:space:]]+publish'
  'yarn[[:space:]]+publish'
  # Credential leaks
  'aws[[:space:]]+configure[[:space:]]+set'
  # Kubernetes destructive
  'kubectl[[:space:]]+delete[[:space:]]+namespace'
  'kubectl[[:space:]]+delete[[:space:]]+.*--all'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -iqE "$pattern"; then
    cat >&2 <<EOF
🚫 BLOCKED by Claude Code safety hook
Pattern matched: $pattern
Command:         $COMMAND

This command is classified as dangerous. If you really need to run it:
  1. Verify the command is correct
  2. Run it manually in your own terminal (outside Claude)
  3. Or edit ~/.claude/hooks/block-dangerous-bash.sh to whitelist it
EOF
    exit 2
  fi
done

exit 0
