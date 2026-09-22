---
description: Structured bug investigation — reproduce, root-cause, fix, regression-test. Uses the debugger subagent for isolation.
argument-hint: "<bug description or error message>"
---

# Quick Debug

Debug the following issue using rigorous root-cause investigation:

**Issue**: $ARGUMENTS

## Execution

1. **Invoke `@debugger`** with the full issue description.
2. The debugger runs in isolated worktree — let it do noisy reproduction work without polluting the main context.
3. Once `@debugger` returns with a root cause + fix + regression test:
   - If the fix touches security-sensitive code → route to `@security-auditor` for sanity check
   - If the fix changes DB queries → route to `@performance-optimizer` to confirm no perf regression
   - Otherwise → route to `@code-reviewer` for final verification

## Output
Return the debugger's full report to the user — reproduction, hypotheses tested, root cause, fix applied, regression test, and verification evidence.
