#!/usr/bin/env bash
# session-context.sh
# SessionStart hook — injects useful git/project context into the session.
# Exit 0 + JSON on stdout = add context. Any other output is ignored.
#
# Output format: {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}

set -euo pipefail

INPUT="$(cat)"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"

# Bail silently if we're not in a git repo or can't access cwd
[ -z "$CWD" ] && exit 0
cd "$CWD" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Gather context
BRANCH="$(git branch --show-current 2>/dev/null || echo 'detached')"
LAST_COMMIT="$(git log -1 --pretty=format:'%h %s' 2>/dev/null || echo 'none')"
UNCOMMITTED_COUNT="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
UNTRACKED="$(git status --porcelain 2>/dev/null | grep -E '^\?\?' | head -5 | awk '{print $2}' | tr '\n' ' ')"

# Find latest ADR if the project has one
LATEST_ADR=""
if [ -d "docs/adr" ]; then
  LATEST_ADR="$(ls -t docs/adr/*.md 2>/dev/null | head -1 || echo '')"
fi

# Build context message (keep it short — goes into every agent's context)
CONTEXT="📍 Repo state
Branch:       $BRANCH
Last commit:  $LAST_COMMIT
Uncommitted:  $UNCOMMITTED_COUNT file(s)"

if [ -n "$UNTRACKED" ]; then
  CONTEXT="$CONTEXT
Untracked:    $UNTRACKED"
fi

if [ -n "$LATEST_ADR" ]; then
  CONTEXT="$CONTEXT
Latest ADR:   $LATEST_ADR"
fi

# Output as JSON (jq builds it safely — handles newlines, quotes)
jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'

exit 0
