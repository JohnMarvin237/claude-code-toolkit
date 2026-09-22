# Prisma common bugs

## Client type errors after schema change

**Symptom**: `Property 'xxx' does not exist on type 'ProjectDelegate'` after editing `schema.prisma`.

**Cause**: The Prisma client is auto-generated from the schema. Editing the schema does not automatically regenerate the client.

**Fix**:
```bash
npx prisma generate
```

Then restart the TS server in your editor if errors persist.

## "Can't reach database server"

**Symptom**: `PrismaClientInitializationError: Can't reach database server at localhost:5432`.

**Checks in order**:
1. Is Postgres running? `brew services list` (macOS) or `systemctl status postgresql` (Linux)
2. Is `DATABASE_URL` in `.env.local` correct? `echo $DATABASE_URL` (from a running dev session)
3. Can you connect manually? `psql $DATABASE_URL -c '\l'`
4. Firewall / VPN blocking the port?

## Migration drift / "pending migration"

**Symptom**: `Drift detected: Your database schema is not in sync with your migration history`.

**Cause**: The DB was modified outside of migrations (often via `db push` or manual SQL).

**Fix (dev only)**:
```bash
# Option A: nuke and restart (loses data)
npx prisma migrate reset

# Option B: create a new migration that matches current DB state
npx prisma migrate dev --create-only --name sync_drift
# ... review the generated SQL carefully, then apply
npx prisma migrate dev
```

Never do this on production. For production drift, work with a DBA.

## N+1 queries

**Symptom**: Page is slow; Prisma query log shows dozens of `SELECT` on the same table with different IDs.

**Cause**: Looping and querying per iteration instead of batching.

**Fix**:
```ts
// ❌
const projects = await prisma.project.findMany()
for (const p of projects) {
  p.author = await prisma.user.findUnique({ where: { id: p.authorId } })
}

// ✅
const projects = await prisma.project.findMany({
  include: { author: true }
})
```

## Seed script can't find Prisma

**Symptom**: `Cannot find module '@prisma/client'` in `prisma/seed.js`.

**Cause**: The seed runs as plain Node, not through Next.js. Make sure the generator output is correctly imported.

**Fix**: Check `package.json` has the seed config, and `prisma/seed.js` imports from the generated path (or from `@prisma/client` if using default output):
```json
{
  "prisma": {
    "seed": "node prisma/seed.js"
  }
}
```

## `P2002 Unique constraint failed`

**Symptom**: Creating a record fails with `P2002` on a unique field.

**Fix**: Use `upsert` when "create or update" is the intent:
```ts
await prisma.user.upsert({
  where: { email: 'a@b.com' },
  create: { email: 'a@b.com', name: 'A' },
  update: { name: 'A' }
})
```

Or wrap `create` with the expected catch:
```ts
try {
  await prisma.user.create({ data })
} catch (err) {
  if (err.code === 'P2002') return { ok: false, error: 'email-exists' }
  throw err
}
```

## `P2025 Record to update/delete not found`

**Symptom**: `PUT /api/projects/[id]` or `DELETE` returns P2025.

**Fix**: Map to a 404 response:
```ts
try {
  await prisma.project.update({ where: { id }, data })
} catch (err) {
  if (err.code === 'P2025') {
    return NextResponse.json({ error: 'Not found' }, { status: 404 })
  }
  throw err
}
```

## Transactions silently not running atomically

**Symptom**: Partial state after a multi-step mutation — some rows created, some missing.

**Cause**: Using `await prisma.$transaction([...])` with unrelated independent queries, or sequential awaits instead of a transaction.

**Fix**:
```ts
// Interactive transaction for dependent operations
await prisma.$transaction(async (tx) => {
  const project = await tx.project.create({ data: projectData })
  await tx.auditLog.create({ data: { action: 'project.created', projectId: project.id } })
})
```

## Prisma logging in dev but not prod

**Useful for investigation**: Enable query logging temporarily:
```ts
export const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development'
    ? ['query', 'info', 'warn', 'error']
    : ['error']
})
```

Never log `query` in production — it's expensive and can leak data.
