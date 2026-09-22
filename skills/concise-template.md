# Concise PR description template

Use this for small PRs: < 100 lines diff, 1-3 commits, no schema/infra changes.

```markdown
## Summary

<1-2 sentences describing what this delivers.>

## How to test

<2-3 concrete steps to verify.>

## Checklist

- [ ] Tests added/updated (if applicable)
- [ ] `npm run typecheck` passes
- [ ] `npm run lint` passes

Closes #<N>
```

## Examples of when this is enough

- Fixing a typo in user-facing copy
- Bumping a dependency to patch a CVE
- Adding a missing aria-label to one element
- A one-function bug fix with its regression test

## When to upgrade to the standard template

- Any change touching `app/api/**` (server code is never trivial)
- Any change to `prisma/schema.prisma`
- Any UI change the user will notice (use screenshots)
- Any auth / admin / contact / env handling change
- Anything the reviewer might legitimately ask "why?" about
