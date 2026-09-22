# Standard PR description template

Use this for medium-to-large PRs (100+ lines diff). For small PRs, see `concise-template.md`.

```markdown
## Summary

<2-3 sentences describing what this PR delivers, at the user-visible or
system-behavior level. Not "refactored foo.ts" — say what the user gets
or what system behavior changed.>

## Motivation

<Why does this change exist? Link to the ADR, issue, user request, or
bug report that drove it. If this is a spontaneous improvement, say so
and explain the trigger.>

## Changes

### Backend
- <Change 1>
- <Change 2>

### Frontend
- <Change 1>

### Database
- <Schema change> — migration: `<migration_name>`

### Infrastructure / CI
- <Change 1>

<Remove sections that don't apply.>

## Screenshots / recordings

<For UI changes: before/after screenshots, or a screen recording for
interactions. Skip this section if there's no user-visible change.>

## How to test

1. Check out this branch: `git checkout <branch-name>`
2. Install deps if package.json changed: `npm install`
3. Run migrations if schema changed: `npx prisma migrate dev`
4. Start the app: `npm run dev`
5. <Specific steps to exercise the new behavior>
6. Expected result: <what the reviewer should observe>

### Edge cases to verify
- <Edge case 1>
- <Edge case 2>

## Checklist

- [ ] Tests added or updated
- [ ] Documentation updated (README, ADR, JSDoc, inline comments where non-obvious)
- [ ] No secrets committed (checked via hook / manually verified)
- [ ] `npm run typecheck` passes
- [ ] `npm run lint` passes
- [ ] `npm run test` passes (if tests exist)
- [ ] Language Policy respected — TS for app runtime, JS only for config/scripts
- [ ] Security-sensitive changes reviewed by `@security-auditor` (auth, admin, contact, env)
- [ ] DB migrations are reversible (if schema changed)
- [ ] Breaking changes documented and called out at the top of this description

## Risks & rollback

**What could go wrong**: <specific failure mode, even if unlikely>

**How to detect**: <what signals would indicate the PR broke something — error rate, logs, user reports>

**How to roll back**:
- Code: `git revert <commit-sha>` then redeploy
- Schema: <migration rollback command or manual steps>
- Data: <if data backfill was involved, how to reverse>

## Related

- Closes #<issue-number>
- ADR: `docs/adr/<NNNN-slug>.md`
- Previous PR: #<N>
- Follow-up PR needed: <yes/no — describe if yes>
```
