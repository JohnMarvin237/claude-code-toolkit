# Next.js 15+ common bugs

## Async `params` / `searchParams`

**Symptom**: `TypeError: Cannot destructure property 'id' of 'params' as it is undefined` or `params.id is undefined`.

**Cause**: In Next.js 15+, `params` and `searchParams` in dynamic routes are Promises.

**Fix**:
```ts
// ❌
export default function Page({ params }: { params: { id: string } }) {
  const { id } = params  // undefined
}

// ✅
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
}
```

Run the codemod if the project has many occurrences:
```bash
npx @next/codemod@latest next-async-request-api .
```

## "Too many connections" / Prisma connection pool exhausted

**Symptom**: Sporadic `Error: P2024: Timed out fetching a new connection from the connection pool` or `FATAL: too many connections for role "postgres"`.

**Cause**: A new `PrismaClient` is being created on every request or every hot-reload, usually because someone imported Prisma wrong or instantiated it in a handler.

**Fix**: Verify `lib/db/prisma.ts` uses the singleton pattern AND that every import comes from there.

```ts
// lib/db/prisma.ts
import { PrismaClient } from '@prisma/client'

const globalForPrisma = global as unknown as { prisma?: PrismaClient }
export const prisma = globalForPrisma.prisma ?? new PrismaClient()
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

Search the codebase for violations:
```bash
grep -rn "new PrismaClient" --include='*.ts' --include='*.tsx' | grep -v 'lib/db/prisma'
```

## `NEXT_REDIRECT` thrown in Server Action

**Symptom**: `Error: NEXT_REDIRECT` in logs after calling `redirect()`.

**Cause**: Not actually an error — Next.js's `redirect()` works by throwing. A `try/catch` around it catches the redirect as if it were a failure.

**Fix**:
```ts
// ❌
try {
  await doSomething()
  redirect('/success')
} catch (err) {
  // catches NEXT_REDIRECT and turns the redirect into a no-op
  console.error(err)
}

// ✅ — call redirect OUTSIDE the try/catch
try {
  await doSomething()
} catch (err) {
  return { ok: false, error: err.message }
}
redirect('/success')
```

## Server Component accessing client-only APIs

**Symptom**: Runtime error `window is not defined` or `document is not defined` in the server build.

**Cause**: A dependency or a lazily-imported module is referencing `window` at module top-level in a file that runs on the server.

**Fix**:
- Move the code into a Client Component (`'use client'` at top)
- Or guard with `if (typeof window !== 'undefined')` for conditional execution
- Or use `next/dynamic` with `{ ssr: false }` to load only on client

## Stale data after mutation

**Symptom**: User submits a form, gets success, but the list doesn't update until refresh.

**Cause**: Missing `revalidatePath()` or `revalidateTag()` after the mutation.

**Fix**:
```ts
'use server'
export async function createProject(data: ProjectInput) {
  const project = await prisma.project.create({ data })
  revalidatePath('/projects')
  revalidatePath('/admin/projects')
  return { ok: true, project }
}
```

## Route handler works in dev, 404 in prod

**Symptom**: `app/api/foo/route.ts` responds 200 in `npm run dev` but 404 after `npm run build && npm start`.

**Possible causes**:
1. File is named wrong (`route.js` instead of `route.ts`, or `Route.ts` with a capital)
2. Exported function is not named correctly — must be `GET`, `POST`, etc. (uppercase)
3. File is excluded by `tsconfig.json` or `next.config.js`
4. Build log shows the route wasn't compiled — check `.next/server/app/api/`

## `fetch()` caching surprises

**Symptom**: Data looks stale; API is called once per deploy then never again.

**Cause**: Next.js 15 changed fetch caching defaults — `fetch()` is NO LONGER cached by default (was cached in 14). Explicit control required.

**Fix**: Specify caching behavior explicitly:
```ts
// For data you want cached indefinitely (ISR with revalidateTag)
fetch(url, { next: { revalidate: 3600, tags: ['projects'] } })

// For uncached / always fresh
fetch(url, { cache: 'no-store' })
```

## TypeScript error on route export

**Symptom**: Build fails with `Type error: Route has an invalid export field`.

**Cause**: Next.js 15+ validates route exports strictly. Only specific identifiers are allowed at module-level in `route.ts` / `page.tsx`.

**Fix**: Only export: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `OPTIONS`, `HEAD`, `runtime`, `revalidate`, `dynamic`, `dynamicParams`, `preferredRegion`, `fetchCache`. Move helper functions to a separate file.
