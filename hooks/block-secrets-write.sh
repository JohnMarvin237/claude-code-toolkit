#!/usr/bin/env bash
# block-secrets-write.sh
# PreToolUse hook for Write/Edit/MultiEdit — blocks writes to sensitive files
# AND scans content for common secret patterns.
# Exit 2 = block. Exit 0 = allow.
#
# Input: JSON on stdin with tool_input.file_path + tool_input.content (or .new_str)
# Depends on: jq

set -euo pipefail

INPUT="$(cat)"
TOOL="$(echo "$INPUT" | jq -r '.tool_name // empty')"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

# Merge all possible content fields (Write uses 'content', Edit uses 'new_str', MultiEdit uses 'edits[].new_str')
CONTENT="$(echo "$INPUT" | jq -r '
  [
    .tool_input.content // empty,
    .tool_input.new_str // empty,
    (.tool_input.edits // [] | map(.new_str // empty) | join("\n"))
  ] | map(select(length > 0)) | join("\n")
')"

# ── 1. Block writes to sensitive file paths ───────────────────────────────
SENSITIVE_PATH_PATTERNS=(
  '\.env$'
  '\.env\.[a-z]+$'              # .env.local, .env.production, etc.
  '\.(pem|key|p12|pfx|keystore|jks|asc|gpg)$'
  '/\.ssh/'
  '/\.aws/credentials'
  '/\.gnupg/'
  'secrets?/'
  'credentials\.json$'
  'service-account.*\.json$'
  '\.npmrc$'                    # often contains auth tokens
  '\.pypirc$'
  'id_rsa$'
  'id_ed25519$'
  'id_ecdsa$'
)

for pattern in "${SENSITIVE_PATH_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qE "$pattern"; then
    cat >&2 <<EOF
🚫 BLOCKED write to sensitive file
Path:    $FILE_PATH
Pattern: $pattern

Sensitive files must be edited manually. If this is a false positive
(e.g. editing .env.example), edit it via your terminal instead of Claude,
or adjust ~/.claude/hooks/block-secrets-write.sh.
EOF
    exit 2
  fi
done

# ── 2. Scan content for secret patterns ───────────────────────────────────
# Skip the scan if content is empty (e.g. Read tool, or delete operation)
[ -z "$CONTENT" ] && exit 0

# Each entry: NAME|REGEX
declare -a SECRET_PATTERNS=(
  'AWS Access Key|AKIA[0-9A-Z]{16}'
  'AWS Session Key|ASIA[0-9A-Z]{16}'
  'AWS Secret|aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+]{40}'
  'OpenAI API Key|sk-[a-zA-Z0-9]{48}'
  'OpenAI Project Key|sk-proj-[a-zA-Z0-9_-]{20,}'
  'Anthropic API Key|sk-ant-[a-zA-Z0-9_-]{20,}'
  'GitHub PAT (classic)|ghp_[a-zA-Z0-9]{36}'
  'GitHub PAT (fine-grained)|github_pat_[a-zA-Z0-9_]{82}'
  'GitHub OAuth|gho_[a-zA-Z0-9]{36}'
  'GitLab PAT|glpat-[a-zA-Z0-9_-]{20,}'
  'Slack Token|xox[baprs]-[0-9a-zA-Z-]{10,}'
  'Google API Key|AIza[0-9A-Za-z_-]{35}'
  'Stripe Live Key|sk_live_[0-9a-zA-Z]{24,}'
  'Stripe Restricted Key|rk_live_[0-9a-zA-Z]{24,}'
  'Twilio Auth|SK[0-9a-fA-F]{32}'
  'SendGrid API Key|SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}'
  'Private Key Header|-----BEGIN (RSA|EC|DSA|OPENSSH|PGP|PRIVATE) PRIVATE KEY-----'
  'Postgres URL with password|postgres(ql)?://[^:[:space:]]+:[^@[:space:]]+@[^[:space:]]+'
  'MongoDB URL with password|mongodb(\+srv)?://[^:[:space:]]+:[^@[:space:]]+@[^[:space:]]+'
  'MySQL URL with password|mysql://[^:[:space:]]+:[^@[:space:]]+@[^[:space:]]+'
  'Azure Storage Key|DefaultEndpointsProtocol=https;AccountName=[^;]+;AccountKey=[A-Za-z0-9+/=]{40,}'
)

for entry in "${SECRET_PATTERNS[@]}"; do
  NAME="${entry%%|*}"
  REGEX="${entry#*|}"
  if echo "$CONTENT" | grep -qE -- "$REGEX"; then
    cat >&2 <<EOF
🚫 BLOCKED: content appears to contain a secret
File:     $FILE_PATH
Detected: $NAME

Secrets must live in .env.local (git-ignored) — never in source code.
If this is a false positive (e.g. a placeholder or test fixture),
edit the file manually or adjust ~/.claude/hooks/block-secrets-write.sh.
EOF
    exit 2
  fi
done

exit 0
