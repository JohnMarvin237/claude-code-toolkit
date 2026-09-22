# Flaky test patterns

## Time-dependent tests

**Symptom**: Test passes at 11am, fails at 11:59pm, passes again at 12:01am.

**Causes**:
- Assertions on "today's date" vs computed date
- Timezone arithmetic (UTC vs local)
- DST transition edge cases
- Tests running past midnight in CI

**Fix**: Use fake timers / inject the clock:
```ts
import { vi } from 'vitest'

vi.useFakeTimers()
vi.setSystemTime(new Date('2026-01-15T12:00:00Z'))
// ...test...
vi.useRealTimers()
```

Or inject a clock into the code under test:
```ts
// Production code
export function createProject(data: ProjectInput, now = () => new Date()) { /* ... */ }

// Test
createProject(data, () => new Date('2026-01-15'))
```

## Test order dependency

**Symptom**: Test X passes alone. Test X fails when run after test Y.

**Cause**: Test Y leaked state — database rows, module-level variables, mocks not reset.

**Fixes**:
- Reset DB between tests (transaction rollback or truncate)
- `beforeEach(() => vi.clearAllMocks())`
- Avoid module-level mutable state
- Run tests in random order to SURFACE this: `vitest --sequence.shuffle`

## Race conditions on shared resources

**Symptom**: Tests fail when run in parallel, pass with `--pool=forks` or `--poolOptions.threads.singleThread`.

**Cause**: Two tests reading/writing the same DB row, file, or in-memory cache.

**Fix**:
- Give each test its own test data (unique IDs / emails with a timestamp or uuid)
- Use a fresh DB schema per test with a prefix
- Or run DB-touching tests sequentially, not in parallel

## Async assertions that don't await

**Symptom**: Test appears to pass but doesn't actually verify the thing it claims to.

**Cause**: Missing `await` or `return` in front of an async assertion.

**Fix**:
```ts
// ❌ test passes regardless of what the promise does
it('creates a project', () => {
  expect(createProject(data)).resolves.toBeDefined()
})

// ✅
it('creates a project', async () => {
  await expect(createProject(data)).resolves.toBeDefined()
})
```

## Network / external API flakiness

**Symptom**: Test fails occasionally with `ECONNREFUSED` or 500s.

**Cause**: Test is hitting a real external service.

**Fix**: Mock the network boundary with MSW or Vitest mocks. Tests should never depend on external availability.

## Randomness without a seed

**Symptom**: Test fails about 1% of the time.

**Cause**: Unseeded random values (`Math.random()`, `faker.random()`, `crypto.randomUUID()`).

**Fix**:
- For faker, seed it: `faker.seed(12345)`
- For `Math.random`, inject a generator or stub it
- For UUIDs, stub `crypto.randomUUID` for the test OR accept any string matching the UUID pattern

## Fixed `setTimeout` in tests

**Symptom**: `await new Promise(r => setTimeout(r, 100))` sometimes isn't enough.

**Cause**: The 100ms was empirically found to "work most of the time" — classic flaky fix.

**Fix**: Wait for the actual condition, not a time duration:
```ts
// ❌
await new Promise(r => setTimeout(r, 100))
expect(screen.getByText('Success')).toBeInTheDocument()

// ✅
await screen.findByText('Success')  // waits until the element appears, with timeout
```

## Cleanup happening in parallel with next test setup

**Symptom**: Test N+1 fails with "resource in use" or half-initialized state.

**Cause**: `afterEach` is async but not awaited properly, OR `afterEach` timing overlaps with next test's `beforeEach`.

**Fix**:
```ts
afterEach(async () => {
  await prisma.user.deleteMany()  // must await
})
```

## Flaky fix checklist

Before declaring a test "stable":
1. Run it in isolation 10x — must pass all 10
2. Run the full suite 10x with shuffled order — must pass all 10
3. Run on CI — must pass without retries
4. If you had to mark it `.retry(3)` to make it pass, it is NOT fixed — find the real cause
