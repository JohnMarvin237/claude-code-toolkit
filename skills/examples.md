# Commit message examples

## ❌ Bad → ✅ Good

### Vague / non-imperative
❌ `Updated stuff`
✅ `refactor(auth): extract session check into middleware`

❌ `Added new feature`
✅ `feat(projects): add technology filter to public listing`

### Past tense / gerund
❌ `feat(projects): added featured filter`
❌ `feat(projects): adding featured filter`
✅ `feat(projects): add featured filter`

### Too broad
❌ `fix: various bug fixes`
✅ `fix(contact): handle empty subject field`
  (and split any other fixes into separate commits)

### Missing scope on cross-cutting change
❌ `chore: update deps`
✅ `chore(deps): bump prisma, next, and zod to latest`

### Subject too long
❌ `feat(projects): add the ability for visitors to filter projects by technology on the public listing page so they can find relevant work more easily` (152 chars)
✅ `feat(projects): add technology filter to public listing`
  (put the "why" in the body if useful)

### Periods / capitalization
❌ `feat(Projects): Add featured filter.`
✅ `feat(projects): add featured filter`

### Missing BREAKING CHANGE footer
❌ `feat(api): change project list response shape`
✅ 
```
feat(api)!: change project list response to envelope shape

BREAKING CHANGE: GET /api/projects now returns { data, meta } instead of
Project[] directly. Update client code to read response.data.
```

## Good examples with bodies

```
fix(contact): prevent double-submit of contact form

The submit button was not being disabled after first click, allowing
users who double-clicked to send two identical messages. Adds a
useState guard and a disabled attribute tied to isSubmitting.

Closes #47
```

```
perf(projects): add composite index on (order, featured)

Query to fetch public projects was doing a sequential scan on the
projects table. EXPLAIN ANALYZE showed 120ms on a table of 50 rows,
which will degrade as content grows. Composite index brings cold-cache
time to 3ms.

ADR: docs/adr/0012-public-query-performance.md
```

```
feat(admin): add drag-and-drop reordering to project list

Uses @dnd-kit/sortable. Persists new order via PATCH /api/projects/reorder
in a single transaction. Optimistic UI with rollback on server failure.
```

## Trivial changes (subject only, no body)

```
chore(deps): bump next to 15.3.1
```

```
docs(readme): fix broken link to deployment guide
```

```
test(projects): add edge case for empty technologies array
```

```
style: apply prettier to admin/ directory
```
