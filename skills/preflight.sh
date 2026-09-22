#!/usr/bin/env bash
# preflight.sh — PR creation preconditions
# Run all checks and report status. Exit 0 if safe to proceed, 1 if any check fails.

set -uo pipefail

PASS="✓"
FAIL="✗"
WARN="⚠"

errors=0
warnings=0

report_ok()   { echo "$PASS $1"; }
report_fail() { echo "$FAIL $1"; errors=$((errors + 1)); }
report_warn() { echo "$WARN $1"; warnings=$((warnings + 1)); }

echo "── Preflight checks ──"

# Check 1: gh CLI installed
if command -v gh >/dev/null 2>&1; then
  report_ok "gh CLI installed ($(gh --version | head -1))"
else
  report_fail "gh CLI not found — install from https://cli.github.com"
fi

# Check 2: gh authenticated
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    report_ok "gh CLI authenticated"
  else
    report_fail "gh CLI not authenticated — run: gh auth login"
  fi
fi

# Check 3: in a git repo
if git rev-parse --git-dir >/dev/null 2>&1; then
  report_ok "inside a git repository"
else
  report_fail "not in a git repository"
  exit 1
fi

# Check 4: current branch is not default
BRANCH="$(git branch --show-current 2>/dev/null || echo '')"
BASE="${BASE_BRANCH:-}"

# Try to discover the default branch from origin
if [ -z "$BASE" ]; then
  BASE="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo 'main')"
fi

if [ -z "$BRANCH" ]; then
  report_fail "detached HEAD — checkout a branch first"
elif [ "$BRANCH" = "$BASE" ]; then
  report_fail "on default branch ($BRANCH) — create a feature branch first"
else
  report_ok "on feature branch: $BRANCH (base: $BASE)"
fi

# Check 5: working tree clean
UNCOMMITTED="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
if [ "$UNCOMMITTED" -eq 0 ]; then
  report_ok "working tree clean"
else
  report_warn "$UNCOMMITTED uncommitted file(s) — commit, stash, or confirm before pushing"
fi

# Check 6: origin exists
if git remote get-url origin >/dev/null 2>&1; then
  report_ok "remote 'origin' configured: $(git remote get-url origin)"
else
  report_fail "no remote 'origin' configured"
fi

# Check 7: commits ahead of base
if [ -n "$BRANCH" ] && [ "$BRANCH" != "$BASE" ]; then
  # Fetch to be accurate about ahead/behind
  git fetch origin "$BASE" >/dev/null 2>&1 || true
  AHEAD="$(git rev-list --count "origin/$BASE..HEAD" 2>/dev/null || echo 0)"
  BEHIND="$(git rev-list --count "HEAD..origin/$BASE" 2>/dev/null || echo 0)"

  if [ "$AHEAD" -eq 0 ]; then
    report_fail "no commits ahead of origin/$BASE — nothing to PR"
  else
    report_ok "$AHEAD commit(s) ahead of origin/$BASE"
  fi

  if [ "$BEHIND" -gt 0 ]; then
    report_warn "$BEHIND commit(s) behind origin/$BASE — consider rebasing before PR"
  fi
fi

# Summary
echo ""
if [ "$errors" -eq 0 ]; then
  if [ "$warnings" -eq 0 ]; then
    echo "All checks passed."
    exit 0
  else
    echo "Passed with $warnings warning(s)."
    exit 0
  fi
else
  echo "$errors check(s) failed, $warnings warning(s)."
  exit 1
fi
