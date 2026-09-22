---
description: Deep multi-lens audit (security + performance + code quality) before a major release. Runs all three auditors in sequence and consolidates findings.
argument-hint: "[optional: scope, e.g. 'last 10 commits' or 'auth module']"
---

# Deep Audit

Perform a comprehensive pre-release audit with scope: **$ARGUMENTS** (default: working directory HEAD vs main).

## Execution

1. **Invoke `@code-reviewer`** — baseline code quality review. Collect findings.
2. **Invoke `@security-auditor`** — threat-modeled security review. Collect findings.
3. **Invoke `@performance-optimizer`** — performance review, only if code changes affect hot paths (data fetching, DB queries, client-side rendering). Collect findings.

## Consolidation

Produce a single consolidated report organized by severity (Critical → High → Medium → Low), NOT by auditor. Each finding tagged with the source auditor.

## Verdict

- 🚫 **BLOCK** — if any critical findings
- ⚠️ **CONDITIONAL** — if high findings have tracked remediation plans
- ✅ **APPROVED** — otherwise

Include a go/no-go recommendation for the release.
