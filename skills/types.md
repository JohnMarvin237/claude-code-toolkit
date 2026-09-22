# Commit types reference

Full table of Conventional Commits types. Use the most specific one that fits.

| Type | Use when | Example |
| --- | --- | --- |
| `feat` | New user-facing capability | `feat(projects): add featured filter to public page` |
| `fix` | Bug correction | `fix(auth): prevent session expiry during password reset` |
| `refactor` | Code restructuring without behavior change | `refactor(api): extract auth guard into shared helper` |
| `perf` | Performance improvement | `perf(projects): add index on order + featured columns` |
| `test` | Adding or correcting tests | `test(contact): add rate-limit integration test` |
| `docs` | Documentation only | `docs(readme): update local setup instructions` |
| `style` | Formatting, whitespace, no code change | `style: apply prettier to admin components` |
| `chore` | Tooling, deps, CI, build config | `chore(deps): bump prisma to 5.20.0` |
| `build` | Build system changes | `build: switch bundler to turbopack` |
| `ci` | CI configuration | `ci: add typecheck step to PR workflow` |
| `revert` | Reverting a prior commit | `revert: feat(projects): add featured filter` |

## Scope conventions for Portfolio project

Preferred scopes, in decreasing frequency:
- `projects`, `experiences`, `education`, `certifications`, `volunteer` — entity-level changes
- `admin` — admin dashboard features
- `auth` — NextAuth, login, sessions
- `contact` — contact form + messages
- `api` — cross-cutting API concerns
- `ui` — shared UI primitives
- `db` — Prisma schema + migrations
- `deps` — dependency updates
- `ci` — GitHub Actions
- `security` — security fixes (keep subject vague for undisclosed bugs)

## Breaking changes

Append `!` after scope AND add `BREAKING CHANGE:` footer:

```
feat(api)!: change project list response to envelope shape

BREAKING CHANGE: GET /api/projects now returns { data, meta } instead of Project[].
Clients must update to read response.data instead of response directly.
```

## Multi-type changes

If a commit legitimately mixes two types (e.g., a fix that also adds a test), pick the **primary intent** as the type. A test added alongside a fix is still a `fix:` commit. If the change is large enough that it has two genuinely separate intents, split it into two commits.
