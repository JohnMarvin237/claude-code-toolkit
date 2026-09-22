# Production-only bugs

Bugs that only appear in production — the hardest kind, because you can't poke at them with a debugger.

## Investigation checklist (run all)

### 1. Environment differences
- Node version: `node --version` locally vs prod runtime
- OS: macOS dev vs Linux prod (casing! `Project.ts` vs `project.ts`)
- Env vars: is every `.env.local` var also in the prod secret store?
- Build vs dev: `npm run dev` uses Turbopack/HMR; `npm run build && npm start` doesn't
- TypeScript: strict mode errors that `next dev` may tolerate but `next build` blocks

### 2. Data differences
- Prod data has values your dev data doesn't: Unicode, trailing spaces, ancient dates, nulls you didn't model
- Scale: prod has 1M rows, dev has 10 — queries that are fine at small scale time out at large
- Reproduce with prod-shaped data: export a sample (anonymized), seed it locally

### 3. Timing / concurrency
- Cold starts on serverless (Vercel Functions, Lambda)
- Database connection pool exhaustion under load
- Race conditions that only trigger with concurrent requests
- Sticky module state between invocations (especially in serverless — Node processes are reused)

### 4. Network
- DNS: `ETIMEDOUT` or slow lookups
- CDN caching: stale asset served for hours
- CORS / same-site cookie rules stricter in prod domain

### 5. Build-time vs runtime
- `process.env.XXX` inlined at build time — changing the env var without redeploying has no effect
- Imports that work in dev (hot-reload) but break at build (cyclic imports, missing `.ts` extensions in some configs)

## Specific common cases

### "Works on my machine", fails on Vercel
- Case-sensitive file imports — `./Project` vs `./project` — macOS is forgiving, Linux is not. SEARCH for mismatches.
- Missing files in git — `git ls-files | grep <file>` to verify it's tracked.
- Build output path assumptions — `.next/standalone` vs `.next/server`.

### 500 error in prod, no stack trace
- Check Vercel/hosting logs — NOT just the browser console.
- Add structured logging with a request ID so you can trace a user-reported failure.
- Check if Sentry or similar is configured — it should have the server-side error.

### Intermittent 500 under load
- Prisma connection pool exhaustion: default pool size may be too small. See `connection_limit` in `DATABASE_URL`.
- Server Component waterfalls under load can cause serialization bottlenecks.

### Database works in staging, fails in prod
- Different Postgres major versions may have different default configurations
- Connection string encoding (special chars in password must be URL-encoded)
- SSL mode — prod often requires `sslmode=require`; dev may be `sslmode=disable`

## Gathering evidence without access to prod

Since you probably can't attach a debugger:

1. **Structured logs**: every error path logs a JSON object with request ID, user ID (not PII), error code.
2. **Error tracking**: Sentry, Bugsnag, or equivalent — captures stack traces with source maps.
3. **Feature flags / kill switches**: disable the suspect feature for 10% of traffic, see if error rate drops.
4. **Reproduce in staging**: if staging is a true prod mirror, reproduce there with the same data shape.

## Deployment rollback decision

If you're uncertain about the cause AND the error impacts users, roll back FIRST, debug SECOND:

```bash
# Vercel
vercel rollback

# Git-based deploys
git revert <bad-commit> && git push
```

Don't spend 30 minutes debugging while users see 500s. Revert, then investigate calmly.
