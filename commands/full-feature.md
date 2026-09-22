---
description: End-to-end feature pipeline from ADR to deploy-ready PR. Chains architect-planner → implementation agents → test-runner → code-reviewer → security-auditor → devops-engineer.
argument-hint: "<feature description>"
---

# Full Feature Pipeline

Execute the complete development lifecycle for: **$ARGUMENTS**

Follow this pipeline strictly. Do NOT skip stages. At each stage, delegate to the named subagent and wait for its summary before proceeding.

## Stage 1 — Plan (🔵 @architect-planner)
Invoke `@architect-planner` with the feature description. Do not proceed until it produces an ADR with `READY_FOR_BUILD` status.

**Gate**: Confirm the ADR's acceptance criteria and implementation plan with the user before continuing.

## Stage 2 — Build
Walk the ADR's implementation plan step by step. For each step, route to the owner declared in the plan:
- UI changes → `@frontend-dev`
- Server logic → `@backend-dev`
- DB changes → `@db-schema-expert` FIRST, then `@backend-dev` for consuming code

Use `@repo-explorer` whenever an implementer needs codebase context without loading files into the main thread.
Use `@docs-researcher` whenever an implementer needs current framework/library documentation.

## Stage 3 — Test (🟢 @test-runner)
Once all implementation steps are complete, invoke `@test-runner` to write and run tests covering the acceptance criteria.

**Gate**: All tests must pass. Coverage must meet project standards.

## Stage 4 — Review (🟡 @code-reviewer)
Invoke `@code-reviewer` on the full change set.

**Gate**: No critical findings. Warnings addressed or consciously deferred.

## Stage 5 — Security audit (🟠 @security-auditor)
Required if the feature touches: authentication, authorization, user data, external APIs, file uploads, SQL, deserialization, secrets, or if the reviewer flagged security concerns.

**Gate**: No critical or high security findings.

## Stage 6 — Performance check (⚡ @performance-optimizer)
Invoke if the feature:
- Adds DB queries on a hot path
- Adds client-side JavaScript > 20KB
- Adds synchronous work in a request handler
- Reviewer or user flagged performance concerns

## Stage 7 — Ship-ready (🚀 @devops-engineer)
Invoke `@devops-engineer` to:
- Verify CI pipeline passes
- Update deploy config if infra changed
- Document rollback procedure
- Confirm secrets/env vars are handled

## Final summary
Produce a PR-ready summary:
- ADR link
- Files changed (with one-line purpose each)
- Test coverage delta
- Security/perf notes
- Deploy requirements
- Rollback procedure
