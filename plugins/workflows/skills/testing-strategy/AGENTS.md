# Testing Strategy — Full Reference

Testing patterns and conventions for Vitest, React Testing Library, MSW, Playwright, and pytest. 46 rules across 12 categories, prioritized by impact. Targets Vitest 3.x, React Testing Library 16.x, MSW 2.x, @testing-library/user-event 14.x, Playwright 1.45+, pytest 8.x, anyio 4.x, pytest-mock 3.x, pytest-xdist 3.x.

## Table of Contents

1. [Test Structure (CRITICAL)](#1-test-structure-critical)
2. [Mocking Strategy (HIGH)](#2-mocking-strategy-high)
3. [Vitest Patterns (HIGH)](#3-vitest-patterns-high)
4. [React Testing Library (HIGH)](#4-react-testing-library-high)
5. [MSW & API Mocking (MEDIUM-HIGH)](#5-msw--api-mocking-medium-high)
6. [Fixtures & Factories (MEDIUM)](#6-fixtures--factories-medium)
7. [Coverage & CI (MEDIUM)](#7-coverage--ci-medium)
8. [Snapshot Testing (LOW-MEDIUM)](#8-snapshot-testing-low-medium)
9. [Playwright Fundamentals (HIGH)](#9-playwright-fundamentals-high)
10. [Playwright CI & Advanced (MEDIUM)](#10-playwright-ci--advanced-medium)
11. [pytest Fundamentals (HIGH)](#11-pytest-fundamentals-high)
12. [pytest Advanced Patterns (MEDIUM)](#12-pytest-advanced-patterns-medium)

---

## 1. Test Structure (CRITICAL)

Test structure determines whether your test suite is trustworthy. Poorly structured tests give false confidence or false alarms.

### `struct-arrange-act-assert`

**Impact: CRITICAL**

Follow the AAA pattern in every test: set up the preconditions, perform the action, then verify the result. Keep the three phases visually distinct.

**Incorrect:**

```typescript
test("submits form", async () => {
  const user = userEvent.setup();
  render(<LoginForm onSubmit={mockSubmit} />);
  await user.type(screen.getByLabelText("Email"), "test@example.com");
  await user.type(screen.getByLabelText("Password"), "password123");
  expect(screen.getByRole("button", { name: "Log in" })).toBeEnabled();
  await user.click(screen.getByRole("button", { name: "Log in" }));
  expect(mockSubmit).toHaveBeenCalledWith({ email: "test@example.com", password: "password123" });
  expect(screen.getByText("Success")).toBeInTheDocument();
});
```

**Correct:**

```typescript
test("submits form with valid credentials", async () => {
  // Arrange
  const user = userEvent.setup();
  const mockSubmit = vi.fn();
  render(<LoginForm onSubmit={mockSubmit} />);

  // Act
  await user.type(screen.getByLabelText("Email"), "test@example.com");
  await user.type(screen.getByLabelText("Password"), "password123");
  await user.click(screen.getByRole("button", { name: "Log in" }));

  // Assert
  expect(mockSubmit).toHaveBeenCalledWith({
    email: "test@example.com",
    password: "password123",
  });
});
```

**Context:** The AAA comments are optional once the pattern is second nature, but keep the visual separation with blank lines. One test, one Act phase. If you need multiple Act phases, split into separate tests.

---

### `struct-single-concept`

**Impact: CRITICAL**

Each test verifies one behavior. Multiple unrelated assertions in a single test obscure which behavior broke when the test fails.

**Incorrect:**

```typescript
test("user profile", async () => {
  render(<UserProfile userId={1} />);
  expect(await screen.findByText("Jane Doe")).toBeInTheDocument();
  expect(screen.getByText("jane@example.com")).toBeInTheDocument();
  expect(screen.getByRole("button", { name: "Edit" })).toBeEnabled();

  await userEvent.click(screen.getByRole("button", { name: "Delete" }));
  expect(screen.getByText("Are you sure?")).toBeInTheDocument();
});
```

**Correct:**

```typescript
test("displays user name and email", async () => {
  render(<UserProfile userId={1} />);

  expect(await screen.findByText("Jane Doe")).toBeInTheDocument();
  expect(screen.getByText("jane@example.com")).toBeInTheDocument();
});

test("shows confirmation dialog on delete", async () => {
  const user = userEvent.setup();
  render(<UserProfile userId={1} />);

  await user.click(await screen.findByRole("button", { name: "Delete" }));

  expect(screen.getByText("Are you sure?")).toBeInTheDocument();
});
```

**Context:** Multiple assertions on the same concept (e.g., name and email of the same rendered profile) are fine. The rule targets mixing unrelated behaviors (display + delete interaction) in one test.

---

### `struct-descriptive-names`

**Impact: CRITICAL**

Test names should describe the expected behavior in plain language. A failing test name should tell you what broke without reading the test body.

**Incorrect:**

```typescript
test("test1", () => { /* ... */ });
test("error", () => { /* ... */ });
test("should work correctly", () => { /* ... */ });
```

**Correct:**

```typescript
test("shows validation error when email format is invalid", () => { /* ... */ });
test("disables submit button while form is submitting", () => { /* ... */ });
test("redirects to dashboard after successful login", () => { /* ... */ });
```

**Context:** Use the pattern "**[action/state] when [condition]**" or "**[expected outcome]**". Avoid "should" — it adds words without information. Nest in `describe` blocks for grouping by component or feature.

---

### `struct-test-isolation`

**Impact: CRITICAL**

Tests must not depend on other tests' state or execution order. Each test should pass when run alone and in any order.

**Incorrect:**

```typescript
let counter = 0;

test("increments counter", () => {
  counter++;
  expect(counter).toBe(1);
});

test("counter is at 1", () => {
  // WRONG: depends on previous test running first
  expect(counter).toBe(1);
});
```

**Correct:**

```typescript
test("increments counter from zero", () => {
  const counter = createCounter(0);

  counter.increment();

  expect(counter.value).toBe(1);
});

test("increments counter from existing value", () => {
  const counter = createCounter(5);

  counter.increment();

  expect(counter.value).toBe(6);
});
```

**Context:** Shared state between tests is the top cause of flaky tests. Each test creates its own data. Use `beforeEach` for common setup, not shared mutable variables.

---

### `struct-no-logic`

**Impact: CRITICAL**

Tests should be straight-line code — no `if`, `for`, `while`, `try/catch`, or ternary operators. Logic in tests can mask failures and makes tests harder to debug.

**Incorrect:**

```typescript
test("handles all status codes", () => {
  const codes = [200, 201, 204];
  for (const code of codes) {
    const result = handleResponse({ status: code });
    if (code === 204) {
      expect(result).toBeNull();
    } else {
      expect(result).toBeDefined();
    }
  }
});
```

**Correct:**

```typescript
test.each([
  { status: 200, expected: { data: "ok" } },
  { status: 201, expected: { data: "created" } },
  { status: 204, expected: null },
])("handles $status response", ({ status, expected }) => {
  const result = handleResponse({ status });

  expect(result).toEqual(expected);
});
```

**Context:** Use `test.each` for parameterized tests instead of loops. Use separate tests instead of conditionals. If you need a try/catch, the test is testing the wrong thing — assert on thrown errors with `expect(() => ...).toThrow()`.

---

## 2. Mocking Strategy (HIGH)

Mocking determines the boundary between what you're testing and what you're simulating. Wrong boundaries produce tests that pass when code is broken (or fail when code works).

### `mock-boundaries`

**Impact: HIGH**

Mock at system boundaries — network calls, filesystem access, timers, randomness. Don't mock internal modules or helper functions.

**Incorrect:**

```typescript
// WRONG: mocking internal helper
vi.mock("./utils/formatPrice", () => ({
  formatPrice: vi.fn(() => "$10.00"),
}));

test("displays formatted price", () => {
  render(<ProductCard price={1000} />);
  expect(screen.getByText("$10.00")).toBeInTheDocument();
});
// This test passes even if formatPrice is broken
```

**Correct:**

```typescript
// Mock the network boundary, not the internal formatting
test("displays product price from API", async () => {
  // MSW handler returns raw price data
  server.use(
    http.get("/api/products/1", () =>
      HttpResponse.json({ name: "Widget", priceInCents: 1000 })
    )
  );

  render(<ProductCard productId={1} />);

  // Tests both the fetch AND the formatting
  expect(await screen.findByText("$10.00")).toBeInTheDocument();
});
```

**Context:** If you mock an internal module, you're testing that your code calls a specific function — not that it produces the right result. Mock the edges: HTTP, database, filesystem, `Date.now`, `Math.random`.

---

### `mock-reset`

**Impact: HIGH**

Reset mocks between tests to prevent state leakage. Stale mock state is a top cause of flaky tests.

```typescript
afterEach(() => {
  vi.restoreAllMocks(); // Restores original implementations
});

// Or per-mock:
const mockFetch = vi.fn();

beforeEach(() => {
  mockFetch.mockReset(); // Clears calls, instances, and implementation
});
```

**Context:** `vi.restoreAllMocks()` in `afterEach` is the safest default — it undoes `vi.spyOn` and restores originals. `vi.resetAllMocks()` clears call history AND removes mock implementations (`.mockReturnValue`, `.mockImplementation`). `vi.clearAllMocks()` clears call history only, preserving mock implementations. Prefer `restoreAllMocks` unless you have a specific reason not to.

---

### `mock-minimal`

**Impact: HIGH**

Mock only what's necessary. Over-mocking creates tests that pass when code is broken because the mock replaces the real behavior under test.

**Incorrect:**

```typescript
// WRONG: mocking the thing we're testing
vi.mock("./auth", () => ({
  validateToken: vi.fn(() => ({ valid: true, userId: 1 })),
}));

test("validates token", () => {
  expect(validateToken("any-string")).toEqual({ valid: true, userId: 1 });
  // This always passes regardless of validateToken's implementation
});
```

**Correct:**

```typescript
// Mock only the external dependency (JWT library), test our logic
vi.mock("jsonwebtoken", () => ({
  verify: vi.fn(() => ({ sub: "user-1", exp: Date.now() / 1000 + 3600 })),
}));

test("returns user ID from valid token", () => {
  const result = validateToken("valid-token");

  expect(result).toEqual({ valid: true, userId: "user-1" });
});
```

**Context:** Ask: "If I change the code under test, will this test catch the bug?" If the answer is no because the mock replaces the relevant behavior, you're over-mocking. For security-critical code (auth, tokens, permissions), always test the rejection path too — e.g., mock an expired token and verify your code rejects it.

---

### `mock-type-safety`

**Impact: HIGH**

Mocked return values should match the real type signature. Type-incorrect mocks hide integration bugs.

**Incorrect:**

```typescript
vi.mock("./api", () => ({
  // Missing required fields that the consumer depends on
  fetchUser: vi.fn(() => ({ name: "Test" })),
}));
```

**Correct:**

```typescript
import type { User } from "./types";

const mockUser: User = {
  id: 1,
  name: "Test User",
  email: "test@example.com",
  createdAt: new Date("2024-01-01"),
};

vi.mock("./api", () => ({
  fetchUser: vi.fn(() => mockUser),
}));
```

**Context:** Use `satisfies` or explicit type annotations on mock return values. This catches shape mismatches at compile time instead of at runtime in production.

---

## 3. Vitest Patterns (HIGH)

Vitest-specific APIs and patterns for effective test implementation.

### `vitest-vi-mock`

**Impact: HIGH**

Use `vi.mock` for module-level mocking and `vi.spyOn` for spying on existing methods without replacing them.

```typescript
// Module mock — replaces the entire module
vi.mock("./api/client", () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
  },
}));

// Spy — wraps an existing method, preserves implementation by default
const consoleSpy = vi.spyOn(console, "error").mockImplementation(() => {});

test("logs error on failure", async () => {
  await performAction();

  expect(consoleSpy).toHaveBeenCalledWith("Action failed");
});
```

**Context:** `vi.mock` is hoisted to the top of the file automatically. For dynamic per-test mocking, use `vi.mock` with a factory and override with `.mockReturnValue` in individual tests. Use `vi.spyOn` when you want to observe calls without changing behavior.

---

### `vitest-test-each`

**Impact: HIGH**

Use `test.each` for parameterized tests. Eliminates duplication and makes adding new cases trivial.

```typescript
test.each([
  { input: "", expected: false, desc: "empty string" },
  { input: "invalid", expected: false, desc: "invalid email" },
  { input: "user@example.com", expected: true, desc: "valid email" },
  { input: "a@b.co", expected: true, desc: "minimal valid email" },
])("returns $expected for $desc", ({ input, expected }) => {
  expect(isValidEmail(input)).toBe(expected);
});
```

**Context:** Use the object form `{ input, expected }` over the array form `[input, expected]` — it's self-documenting. The `$variable` syntax in test names interpolates values from the test case object.

---

### `vitest-setup-teardown`

**Impact: HIGH**

Use `beforeEach`/`afterEach` for per-test setup and `beforeAll`/`afterAll` for expensive one-time setup.

```typescript
describe("DatabaseService", () => {
  let db: TestDatabase;

  // Expensive: create once, share across tests (read-only)
  beforeAll(async () => {
    db = await TestDatabase.create();
  });

  afterAll(async () => {
    await db.destroy();
  });

  // Cheap: fresh state per test
  beforeEach(async () => {
    await db.seed(defaultFixtures);
  });

  afterEach(async () => {
    await db.truncate();
  });

  test("finds user by email", async () => {
    const user = await db.users.findByEmail("jane@example.com");
    expect(user).toBeDefined();
  });
});
```

**Context:** `beforeAll` is for setup that's expensive and read-only (database connections, server start). `beforeEach` is for setup that needs to be fresh per test (data seeding, mock configuration). When in doubt, use `beforeEach` — it's slower but safer.

---

### `vitest-in-source`

**Impact: HIGH**

Use in-source testing for pure utility functions — the test lives in the same file as the code, runs during `vitest` but is tree-shaken out of production builds.

```typescript
// utils/math.ts
export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

if (import.meta.vitest) {
  const { test, expect } = import.meta.vitest;

  test("clamps to minimum", () => {
    expect(clamp(-5, 0, 10)).toBe(0);
  });

  test("clamps to maximum", () => {
    expect(clamp(15, 0, 10)).toBe(10);
  });

  test("returns value when in range", () => {
    expect(clamp(5, 0, 10)).toBe(5);
  });
}
```

**Context:** Requires two config changes. In `vitest.config.ts`, add `test.includeSource` so Vitest discovers in-source test blocks:

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    includeSource: ["src/**/*.ts"], // Required: tells Vitest to run in-source blocks
  },
  define: {
    "import.meta.vitest": "undefined", // Required: tree-shakes tests from prod build
  },
});
```

Without `includeSource`, Vitest silently ignores all in-source tests — no error, they just don't run. Without the `define`, test code ships in production bundles. Best for small, pure functions. Don't use for components, hooks, or anything needing complex setup.

---

### `vitest-fake-timers`

**Impact: HIGH**

Use `vi.useFakeTimers()` for code that depends on `setTimeout`, `setInterval`, `Date.now`, or `performance.now`. Always restore real timers afterward.

```typescript
test("debounces search input", async () => {
  vi.useFakeTimers();
  const onSearch = vi.fn();
  render(<SearchInput onSearch={onSearch} debounceMs={300} />);

  const user = userEvent.setup({ advanceTimers: (ms) => vi.advanceTimersByTime(ms) });
  await user.type(screen.getByRole("searchbox"), "query");

  // Not called yet — still within debounce window
  expect(onSearch).not.toHaveBeenCalled();

  // Advance past debounce
  vi.advanceTimersByTime(300);

  expect(onSearch).toHaveBeenCalledWith("query");

  vi.useRealTimers();
});
```

**Context:** When combining fake timers with `userEvent`, pass `advanceTimers: vi.advanceTimersByTime` to the userEvent setup. Always call `vi.useRealTimers()` in `afterEach` or at the end of each test to prevent timer leakage.

---

## 4. React Testing Library (HIGH)

React Testing Library enforces testing from the user's perspective. These patterns maximize the value of that approach.

### `rtl-query-priority`

**Impact: HIGH**

Follow the query priority order: accessible roles and labels first, text content second, test IDs as a last resort. Never use `container.querySelector`.

**Priority order:**

1. `getByRole` — best: matches how assistive technology sees the page
2. `getByLabelText` — for form fields
3. `getByPlaceholderText` — when no label exists
4. `getByText` — for non-interactive elements
5. `getByDisplayValue` — for filled form inputs
6. `getByAltText` — for images
7. `getByTitle` — for title attributes
8. `getByTestId` — last resort when no semantic query works

**Incorrect:**

```typescript
// WRONG: brittle selector, not accessible
const button = container.querySelector(".btn-primary");
const input = container.querySelector("#email-input");
```

**Correct:**

```typescript
const button = screen.getByRole("button", { name: "Submit" });
const input = screen.getByLabelText("Email address");
```

**Context:** If you can't query by role or label, that's often an accessibility bug in the component, not a testing limitation. Fix the component first.

---

### `rtl-user-event`

**Impact: HIGH**

Use `@testing-library/user-event` instead of `fireEvent`. User-event simulates full interaction sequences (focus, keydown, keyup, input, change) like a real user.

**Incorrect:**

```typescript
// WRONG: fireEvent dispatches a single DOM event, skipping browser behavior
fireEvent.change(input, { target: { value: "hello" } });
fireEvent.click(button);
```

**Correct:**

```typescript
const user = userEvent.setup();

// Types each character: triggers focus, keydown, input, keyup per keystroke
await user.type(screen.getByLabelText("Username"), "hello");
await user.click(screen.getByRole("button", { name: "Submit" }));
```

**Context:** Always create the user instance with `userEvent.setup()` at the start of the test, not with the legacy `userEvent.click()` direct API. The setup API enables proper event sequencing and interleaving.

---

### `rtl-async-queries`

**Impact: HIGH**

Use `findBy*` for elements that appear asynchronously (after data fetching, animations, or state updates). Use `waitFor` to retry assertions.

**Incorrect:**

```typescript
// WRONG: getBy throws immediately if element is not present
render(<UserProfile userId={1} />);
expect(screen.getByText("Jane Doe")).toBeInTheDocument();
// Fails because data hasn't loaded yet
```

**Correct:**

```typescript
render(<UserProfile userId={1} />);

// findBy retries until the element appears or times out
const name = await screen.findByText("Jane Doe");
expect(name).toBeInTheDocument();

// waitFor retries the assertion callback
await waitFor(() => {
  expect(screen.getByText("3 posts")).toBeInTheDocument();
});
```

**Context:** `findBy` = `waitFor` + `getBy`. Use `findBy` when waiting for an element to appear. Use `waitFor` when asserting on something that may change (e.g., text content updating). Default timeout is 1000ms — increase for slow operations with `{ timeout: 3000 }`.

---

### `rtl-avoid-implementation`

**Impact: HIGH**

Test what the user sees and does, not the component's internal implementation. Don't assert on state, props, hooks, or component instances.

**Incorrect:**

```typescript
// WRONG: testing implementation details
const { result } = renderHook(() => useCounter());
expect(result.current.count).toBe(0);
act(() => result.current.increment());
expect(result.current.count).toBe(1);
```

**Correct:**

```typescript
// Test the behavior through the UI
test("increments counter on button click", async () => {
  const user = userEvent.setup();
  render(<Counter />);

  expect(screen.getByText("Count: 0")).toBeInTheDocument();

  await user.click(screen.getByRole("button", { name: "Increment" }));

  expect(screen.getByText("Count: 1")).toBeInTheDocument();
});
```

**Context:** `renderHook` tests are appropriate for shared hooks that are used across many components and have complex logic. For hooks that serve a single component, test through the component's UI. The goal is tests that survive refactoring — if you rename an internal state variable, your tests should still pass.

---

## 5. MSW & API Mocking (MEDIUM-HIGH)

Mock Service Worker intercepts network requests at the service worker level, providing realistic API mocking without modifying application code.

### `msw-handlers`

**Impact: MEDIUM-HIGH**

Define default handlers in a shared file. Override per-test for error states and edge cases.

```typescript
// test/mocks/handlers.ts — shared defaults (happy path)
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("/api/users/:id", ({ params }) =>
    HttpResponse.json({
      id: Number(params.id),
      name: "Jane Doe",
      email: "jane@example.com",
    })
  ),

  http.get("/api/products", () =>
    HttpResponse.json([
      { id: 1, name: "Widget", price: 999 },
      { id: 2, name: "Gadget", price: 1999 },
    ])
  ),
];
```

```typescript
// In a specific test — override for error case
test("shows error message on API failure", async () => {
  server.use(
    http.get("/api/users/:id", () =>
      HttpResponse.json({ error: "Not found" }, { status: 404 })
    )
  );

  render(<UserProfile userId={999} />);

  expect(await screen.findByText("User not found")).toBeInTheDocument();
});
```

**Context:** Default handlers provide the happy path. `server.use()` overrides are per-test and automatically reset after `server.resetHandlers()`. This keeps tests focused on the specific scenario being tested. Use fictional data only (`example.com` domain, invented names) — never copy real user data from staging or production into test fixtures (see `fixture-realistic-data`).

---

### `msw-server-setup`

**Impact: MEDIUM-HIGH**

Configure the MSW server in a setup file loaded by Vitest. Reset handlers between tests, close the server after all tests.

```typescript
// test/setup.ts
import { setupServer } from "msw/node";
import { handlers } from "./mocks/handlers";

export const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    setupFiles: ["./test/setup.ts"],
  },
});
```

**Context:** `onUnhandledRequest: "error"` catches unmocked API calls — they throw instead of silently hitting the network. This prevents tests from accidentally depending on real APIs. Use `"warn"` during migration if you have many unmocked endpoints.

---

### `msw-response-assertions`

**Impact: MEDIUM-HIGH**

Assert on what the user sees after the API response, not on whether fetch was called. MSW makes the network transparent — test outcomes, not plumbing.

**Incorrect:**

```typescript
// WRONG: testing plumbing, not behavior
test("fetches user data", async () => {
  const fetchSpy = vi.spyOn(global, "fetch");
  render(<UserProfile userId={1} />);

  await waitFor(() => {
    expect(fetchSpy).toHaveBeenCalledWith("/api/users/1");
  });
});
```

**Correct:**

```typescript
test("displays user profile from API", async () => {
  render(<UserProfile userId={1} />);

  expect(await screen.findByText("Jane Doe")).toBeInTheDocument();
  expect(screen.getByText("jane@example.com")).toBeInTheDocument();
});
```

**Context:** MSW handles the network layer. Your test should verify the rendered result. Exception: asserting on request bodies for mutations (POST/PUT) is valid — use `server.use()` with a handler that captures the request body.

---

## 6. Fixtures & Factories (MEDIUM)

Test data management patterns that keep tests readable and maintainable.

### `fixture-factories`

**Impact: MEDIUM**

Create factory functions that return valid default objects. Override only the fields relevant to each test.

```typescript
// test/factories.ts
import type { User } from "@/types";

export function createUser(overrides: Partial<User> = {}): User {
  return {
    id: 1,
    name: "Jane Doe",
    email: "jane@example.com",
    role: "member",
    createdAt: new Date("2024-01-15"),
    ...overrides,
  };
}

// Usage in tests
test("displays admin badge for admin users", () => {
  const adminUser = createUser({ role: "admin" });
  render(<UserCard user={adminUser} />);

  expect(screen.getByText("Admin")).toBeInTheDocument();
});
```

**Context:** Factories make the test's intent clear — you only see the fields that matter for this test. All other fields have sensible defaults. Use incremental IDs if you need unique values: `let nextId = 1; function createUser(...) { return { id: nextId++, ... } }`.

---

### `fixture-no-shared-mutation`

**Impact: MEDIUM**

Never mutate shared fixture objects. Create fresh instances for each test.

**Incorrect:**

```typescript
const testUser = createUser();

test("updates name", () => {
  testUser.name = "Updated"; // WRONG: mutates shared object
  expect(formatUser(testUser)).toContain("Updated");
});

test("displays original name", () => {
  // FLAKY: depends on test execution order
  expect(formatUser(testUser)).toContain("Jane Doe");
});
```

**Correct:**

```typescript
test("updates name", () => {
  const user = createUser();
  user.name = "Updated";
  expect(formatUser(user)).toContain("Updated");
});

test("displays original name", () => {
  const user = createUser();
  expect(formatUser(user)).toContain("Jane Doe");
});
```

**Context:** Create fresh objects with `createUser()` inside each test or in `beforeEach`. Shared constants (strings, numbers) are fine — they're immutable. Shared objects are the danger.

---

### `fixture-realistic-data`

**Impact: MEDIUM**

Use realistic data in fixtures. Placeholder strings like "test", "abc", or empty strings hide real-world bugs.

**Incorrect:**

```typescript
const user = { name: "test", email: "test", phone: "123" };
```

**Correct:**

```typescript
const user = {
  name: "Jane Doe",
  email: "jane.doe@example.com",
  phone: "+1-555-867-5309",
};
```

**Context:** Realistic data catches formatting bugs, truncation issues, and validation edge cases that placeholder data misses. Use consistent fictional data (Jane Doe, example.com) rather than random generators — deterministic tests are easier to debug.

---

### `fixture-builders`

**Impact: MEDIUM**

Use the builder pattern for complex objects with many optional fields or nested structures.

```typescript
class OrderBuilder {
  private order: Order = {
    id: "ord-001",
    userId: "usr-001",
    items: [],
    status: "pending",
    total: 0,
    shippingAddress: null,
    createdAt: new Date("2024-01-15"),
  };

  withItems(items: OrderItem[]): this {
    this.order.items = items;
    this.order.total = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
    return this;
  }

  withStatus(status: OrderStatus): this {
    this.order.status = status;
    return this;
  }

  withShipping(address: Address): this {
    this.order.shippingAddress = address;
    return this;
  }

  build(): Order {
    return { ...this.order };
  }
}

// Usage
const shippedOrder = new OrderBuilder()
  .withItems([{ productId: "p1", price: 2999, quantity: 2 }])
  .withStatus("shipped")
  .withShipping({ street: "123 Main St", city: "Portland", zip: "97201" })
  .build();
```

**Context:** Builders are overkill for simple objects (use factory functions instead). Use builders when objects have 8+ fields, computed/dependent fields, or nested structures that need consistent assembly.

---

## 7. Coverage & CI (MEDIUM)

Patterns for meaningful test coverage and efficient CI pipelines.

### `ci-meaningful-coverage`

**Impact: MEDIUM**

Measure branch coverage, not just line coverage. Target 80% as a floor, not a ceiling. Don't chase 100% — it incentivizes testing trivial code.

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov", "json-summary"],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
      exclude: [
        "**/*.d.ts",
        "**/*.config.*",
        "**/types/**",
        "**/test/**",
        "**/mocks/**",
      ],
    },
  },
});
```

**Context:** Branch coverage catches untested `if/else` paths that line coverage misses. Exclude config files, type definitions, and test utilities from coverage — they inflate the number without adding safety. Focus coverage on business logic and UI components.

---

### `ci-parallel-execution`

**Impact: MEDIUM**

Run tests in parallel by default. Isolate tests that need serial execution.

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    // Files run in parallel by default
    pool: "threads",
    poolOptions: {
      threads: {
        // Number of threads
        maxThreads: 4,
        minThreads: 1,
      },
    },
  },
});
```

```typescript
// For tests that need serial execution (shared database, port conflicts)
// vitest.workspace.ts
import { defineWorkspace } from "vitest/config";

export default defineWorkspace([
  {
    test: {
      include: ["src/**/*.test.ts"],
      name: "unit",
    },
  },
  {
    test: {
      include: ["e2e/**/*.test.ts"],
      name: "e2e",
      pool: "forks",
      poolOptions: { forks: { singleFork: true } },
    },
  },
]);
```

**Context:** Parallel tests require isolation (see `struct-test-isolation`). If tests share resources like database ports, either isolate them with unique ports per worker or run them serially in a separate workspace project.

---

### `ci-flaky-quarantine`

**Impact: MEDIUM**

When a test flakes, quarantine it immediately. Don't retry-and-ignore — find and fix the root cause.

```typescript
// Quarantine a flaky test — visible in reports, doesn't block CI
test.skip("flaky: race condition in websocket reconnect", () => {
  // TODO: Fix race condition — see BRI-1234
});
```

**Quarantine process:**

1. Mark the test with `test.skip` and a descriptive name prefix
2. Create a bug issue for the root cause
3. Fix the root cause (usually shared state, timing, or network dependency)
4. Unskip and verify stability over multiple CI runs

**Context:** Retrying flaky tests with `retry: 3` masks the bug and makes CI slower. Common root causes: shared mutable state (`struct-test-isolation`), unmocked network calls (`msw-server-setup`), timer dependencies (`vitest-fake-timers`).

---

### `ci-test-splitting`

**Impact: MEDIUM**

Split test suites across CI workers for faster pipelines.

```yaml
# GitHub Actions example with matrix strategy
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1/3, 2/3, 3/3]
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx vitest --shard ${{ matrix.shard }}
```

**Context:** Vitest's built-in `--shard` flag splits tests by file across workers. For more even splitting based on test duration, use `vitest --reporter=json` to collect timing data and feed it into a splitter. Start with 3-4 shards and adjust based on your suite size.

---

## 8. Snapshot Testing (LOW-MEDIUM)

Snapshot testing captures output and detects unexpected changes. Use sparingly — most tests are better as explicit assertions.

### `snap-inline-small`

**Impact: LOW-MEDIUM**

Use inline snapshots for small, focused outputs. Use file snapshots for larger outputs.

```typescript
// Inline snapshot — output visible in the test file
test("formats currency", () => {
  expect(formatCurrency(1999, "USD")).toMatchInlineSnapshot('"$19.99"');
});

// File snapshot — stored in __snapshots__/
test("renders user card", () => {
  const { container } = render(<UserCard user={createUser()} />);
  expect(container.firstChild).toMatchSnapshot();
});
```

**Context:** Inline snapshots keep the expected output next to the assertion — easier to review and update. File snapshots are better for outputs over ~10 lines, but treat `__snapshots__/` files as important code — review them in PRs.

---

### `snap-avoid-large`

**Impact: LOW-MEDIUM**

Never snapshot entire component trees. Snapshot the specific output you care about.

**Incorrect:**

```typescript
// WRONG: snapshots the entire DOM tree — any change triggers update
test("renders page", () => {
  const { container } = render(<DashboardPage />);
  expect(container).toMatchSnapshot();
});
```

**Correct:**

```typescript
// Snapshot only the data table output
test("renders metrics summary", () => {
  render(<DashboardPage data={mockData} />);

  const summary = screen.getByRole("table", { name: "Metrics" });
  expect(summary).toMatchSnapshot();
});
```

**Context:** Large snapshots are "write-once, ignore-forever" — they break on every change, and reviewers rubber-stamp updates. Focused snapshots on specific elements actually catch regressions. Prefer explicit assertions (`expect(screen.getByText(...))`) over snapshots when possible.

---

### `snap-review-updates`

**Impact: LOW-MEDIUM**

Review every snapshot update in pull request diffs. Never run `vitest --update` without inspecting what changed.

**Process:**

1. Run tests — snapshot failures show the diff
2. Read each diff to verify the change is intentional
3. Only then run `vitest --update` to accept
4. In PR review, check `__snapshots__/` diffs as carefully as source code

**Context:** Blindly updating snapshots defeats their purpose. If a snapshot changed unexpectedly, it may indicate a real bug introduced by your code changes. Treat snapshot diffs like any other test failure — investigate before accepting.

---

## 9. Playwright Fundamentals (HIGH)

Playwright provides cross-browser E2E testing with auto-waiting, network interception, and isolated browser contexts. These patterns ensure reliable, maintainable end-to-end tests.

### `pw-page-objects`

**Impact: HIGH**

Encapsulate page interactions in page object classes. Expose behaviors (methods named after user actions), not raw selectors.

**Incorrect:**

```typescript
// WRONG: selectors and interactions scattered across tests
test("creates a new project", async ({ page }) => {
  await page.click('[data-testid="new-project-btn"]');
  await page.fill('[data-testid="project-name"]', "My Project");
  await page.fill('[data-testid="project-description"]', "A test project");
  await page.click('[data-testid="submit-btn"]');
  await expect(page.locator('[data-testid="project-title"]')).toHaveText("My Project");
});

test("deletes a project", async ({ page }) => {
  // Same selectors duplicated, breaks everywhere if UI changes
  await page.click('[data-testid="project-title"]');
  await page.click('[data-testid="delete-btn"]');
  await page.click('[data-testid="confirm-delete"]');
});
```

**Correct:**

```typescript
// pages/project.page.ts
import { type Locator, type Page, expect } from "@playwright/test";

export class ProjectPage {
  private readonly nameInput: Locator;
  private readonly descriptionInput: Locator;
  private readonly submitButton: Locator;
  private readonly projectTitle: Locator;

  constructor(private readonly page: Page) {
    this.nameInput = page.getByLabel("Project name");
    this.descriptionInput = page.getByLabel("Description");
    this.submitButton = page.getByRole("button", { name: "Create project" });
    this.projectTitle = page.getByRole("heading", { level: 1 });
  }

  async create(name: string, description: string): Promise<void> {
    await this.page.getByRole("button", { name: "New project" }).click();
    await this.nameInput.fill(name);
    await this.descriptionInput.fill(description);
    await this.submitButton.click();
  }

  async expectTitle(title: string): Promise<void> {
    await expect(this.projectTitle).toHaveText(title);
  }
}

// In test
test("creates a new project", async ({ page }) => {
  const projectPage = new ProjectPage(page);

  await projectPage.create("My Project", "A test project");

  await projectPage.expectTitle("My Project");
});
```

**Context:** Page objects centralize selectors so a UI change requires one update, not dozens. Name methods after user behaviors (`create`, `delete`, `search`), not DOM operations (`clickButton`, `fillInput`). Assertion helper methods (`expectTitle`, `expectVisible`) on page objects are acceptable and keep assertion logic DRY. Keep assertions out of action methods (`create`, `delete`) — those should only perform interactions.

---

### `pw-selectors`

**Impact: HIGH**

Prefer accessible selectors: `getByRole` > `getByLabel`/`getByText` > `getByTestId` > CSS selectors. This mirrors the RTL query priority (see `rtl-query-priority`) and catches accessibility issues.

**Incorrect:**

```typescript
// WRONG: fragile CSS selectors tied to implementation
await page.click(".sidebar > ul > li:nth-child(3) > a");
await page.fill("#email-input", "jane@example.com");
await page.locator("div.modal-footer > button.btn-primary").click();
```

**Correct:**

```typescript
// Accessible selectors — resilient and meaningful
await page.getByRole("navigation").getByRole("link", { name: "Settings" }).click();
await page.getByLabel("Email address").fill("jane@example.com");
await page.getByRole("dialog").getByRole("button", { name: "Save" }).click();
```

**Context:** `getByRole` queries match how assistive technology sees the page — if the selector works, accessibility likely works too. `getByTestId` is a valid fallback for elements without semantic roles (e.g., canvas, custom widgets), but prefer semantic queries first. If you can't find an accessible selector, that often signals an accessibility bug in the component.

---

### `pw-test-isolation`

**Impact: HIGH**

Each Playwright test gets a fresh browser context by default. Don't share mutable state between tests — no shared variables, no assumptions about execution order.

**Incorrect:**

```typescript
// WRONG: shared state between tests
let projectId: string;

test("creates a project", async ({ page }) => {
  await page.goto("/projects/new");
  await page.getByLabel("Name").fill("Test Project");
  await page.getByRole("button", { name: "Create" }).click();
  projectId = page.url().split("/").pop()!;
});

test("edits the project", async ({ page }) => {
  // WRONG: depends on previous test's projectId
  await page.goto(`/projects/${projectId}/edit`);
  await page.getByLabel("Name").fill("Updated Project");
  await page.getByRole("button", { name: "Save" }).click();
});
```

**Correct:**

```typescript
test("creates and edits a project", async ({ page }) => {
  // Self-contained: set up, act, verify in one test
  await page.goto("/projects/new");
  await page.getByLabel("Name").fill("Test Project");
  await page.getByRole("button", { name: "Create" }).click();

  await page.getByRole("button", { name: "Edit" }).click();
  await page.getByLabel("Name").fill("Updated Project");
  await page.getByRole("button", { name: "Save" }).click();

  await expect(page.getByRole("heading", { level: 1 })).toHaveText("Updated Project");
});

// Or use fixtures for shared setup (see pw-fixtures)
```

**Context:** Playwright runs tests in parallel by default — shared state causes race conditions. Each test starts with its own `BrowserContext` (isolated cookies, storage, cache). Use fixtures (`pw-fixtures`) for expensive setup that multiple tests need, not shared variables. The `!` non-null assertion on `pop()` in the incorrect example is a second smell — `split('/').pop()` returns `string | undefined` and the assertion discards that without a runtime check. Cross-ref: `struct-test-isolation`.

---

### `pw-fixtures`

**Impact: HIGH**

Use `test.extend` to create custom fixtures. Fixtures provide typed, reusable setup/teardown and compose cleanly.

**Incorrect:**

```typescript
// WRONG: hardcoded credentials AND repeated setup in every test
test("admin sees user list", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel("Email").fill("admin@example.com"); // WRONG: hardcoded credential
  await page.getByLabel("Password").fill("admin-password"); // WRONG: hardcoded credential
  await page.getByRole("button", { name: "Log in" }).click();
  await page.waitForURL("/dashboard");

  await page.goto("/admin/users");
  await expect(page.getByRole("table")).toBeVisible();
});

test("admin can disable user", async ({ page }) => {
  // Same login boilerplate repeated
  await page.goto("/login");
  await page.getByLabel("Email").fill("admin@example.com"); // WRONG: hardcoded credential
  await page.getByLabel("Password").fill("admin-password"); // WRONG: hardcoded credential
  await page.getByRole("button", { name: "Log in" }).click();
  await page.waitForURL("/dashboard");

  // ...
});
```

**Correct:**

```typescript
// fixtures.ts
import { test as base, type Page } from "@playwright/test";

type Fixtures = {
  authenticatedPage: Page;
  adminPage: Page;
};

export const test = base.extend<Fixtures>({
  authenticatedPage: async ({ page }, use) => {
    const email = process.env.TEST_USER_EMAIL;
    const password = process.env.TEST_USER_PASSWORD;
    if (!email || !password) {
      throw new Error("TEST_USER_EMAIL and TEST_USER_PASSWORD must be set. See .env.test.example.");
    }
    await page.goto("/login");
    await page.getByLabel("Email").fill(email);
    await page.getByLabel("Password").fill(password);
    await page.getByRole("button", { name: "Log in" }).click();
    await page.waitForURL("/dashboard");
    await use(page);
  },

  adminPage: async ({ authenticatedPage }, use) => {
    // Compose: reuse authenticatedPage, then elevate to admin context
    await authenticatedPage.goto("/admin");
    await use(authenticatedPage);
  },
});

export { expect } from "@playwright/test";

// In tests
import { test, expect } from "./fixtures";

test("admin sees user list", async ({ adminPage }) => {
  await adminPage.goto("/admin/users");
  await expect(adminPage.getByRole("table")).toBeVisible();
});
```

**Context:** Fixtures compose — `adminPage` depends on `authenticatedPage` and adds admin-specific navigation. Use `{ scope: "worker" }` for expensive one-time setup shared across tests in the same worker (e.g., seeding a test database). Default scope is per-test, which is the safe choice for isolation. Never hardcode real credentials in fixture files — use environment variables (`.env.test`) or Playwright's `storageState` to log in once in `globalSetup` and reuse the session.

---

## 10. Playwright CI & Advanced (MEDIUM)

Advanced Playwright patterns for network mocking, visual regression, and CI configuration.

### `pw-network-mocking`

**Impact: MEDIUM**

Use `page.route()` to intercept and stub network requests for deterministic E2E tests. Mock the network when you need speed, stability, or to test error states.

**Incorrect:**

```typescript
// WRONG: test depends on real API — slow, flaky, non-deterministic
test("shows user profile", async ({ page }) => {
  await page.goto("/profile/1");
  // If the API is down or data changed, this test breaks
  await expect(page.getByText("Jane Doe")).toBeVisible();
});
```

**Correct:**

```typescript
test("shows user profile", async ({ page }) => {
  // Intercept the API call and return a deterministic response
  await page.route("**/api/users/1", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        id: 1,
        name: "Jane Doe",
        email: "jane@test.example",
      }),
    })
  );

  await page.goto("/profile/1");

  await expect(page.getByText("Jane Doe")).toBeVisible();
  await expect(page.getByText("jane@test.example")).toBeVisible();
});

test("shows error state on API failure", async ({ page }) => {
  await page.route("**/api/users/1", (route) =>
    route.fulfill({ status: 500, body: "Internal Server Error" })
  );

  await page.goto("/profile/1");

  await expect(page.getByText("Something went wrong")).toBeVisible();
});
```

**Context:** `page.route()` intercepts at the browser network level — the app code runs unchanged. Use glob patterns (`**/api/**`) for flexibility. Use `route.continue({ headers: {...} })` to let a request proceed with modified request headers. To intercept and modify the response, use `await route.fetch()` then `route.fulfill()` with the modified body. Unlike MSW (which mocks at the service-worker layer for unit/integration tests), `page.route()` is Playwright's native approach for E2E tests. Decide per-suite: mock for speed and stability, use real APIs for smoke/integration E2E suites.

---

### `pw-visual-regression`

**Impact: MEDIUM**

Use `toHaveScreenshot()` to catch unintended visual changes. Screenshot specific components, not full pages, and set explicit thresholds.

**Incorrect:**

```typescript
// WRONG: full-page screenshot — any layout shift triggers failure
test("dashboard looks correct", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page).toHaveScreenshot();
});
```

**Correct:**

```typescript
test("metrics card renders correctly", async ({ page }) => {
  await page.goto("/dashboard");

  const metricsCard = page.getByTestId("metrics-card");
  await expect(metricsCard).toBeVisible();

  await expect(metricsCard).toHaveScreenshot("metrics-card.png", {
    maxDiffPixelRatio: 0.01, // Allow 1% pixel difference
  });
});

test("chart renders with data", async ({ page }) => {
  // Mock data for deterministic rendering
  await page.route("**/api/metrics", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ revenue: 50000, users: 1234 }),
    })
  );

  await page.goto("/dashboard");

  // CSS selector is acceptable here — recharts wrapper has no semantic role or testId
  const chart = page.locator(".recharts-wrapper");
  await expect(chart).toBeVisible();

  await expect(chart).toHaveScreenshot("revenue-chart.png", {
    maxDiffPixelRatio: 0.02,
  });
});
```

**Context:** First run generates baseline screenshots in a directory named after the test file (e.g., `e2e/dashboard.spec.ts-snapshots/`) colocated with the test — commit these to version control. Review screenshot diffs like you review snapshot diffs (see `snap-review-updates`). Use `maxDiffPixelRatio` over `maxDiffPixels` for responsive-safe thresholds. Mock data before screenshotting to avoid non-deterministic content. Run visual tests on a single browser/OS in CI to avoid cross-platform rendering differences.

---

### `pw-ci-config`

**Impact: MEDIUM**

Configure Playwright for CI: define browser projects, set retries, enable trace on first retry, upload artifacts, and shard for speed.

**Incorrect:**

```typescript
// WRONG: no CI-specific config — slow, no artifacts, no retry insight
// playwright.config.ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  use: {
    baseURL: "http://localhost:3000",
  },
});
```

**Correct:**

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI, // Fail CI if test.only is left in
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? "html" : "list",

  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry", // Capture trace only on failure — fast + debuggable
    screenshot: "only-on-failure",
  },

  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],

  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
});
```

```yaml
# GitHub Actions — Playwright CI
jobs:
  e2e:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shardIndex: [1, 2, 3]
        shardTotal: [3]
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af # v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps chromium  # Install only browsers you need
      - run: npx playwright test --project=chromium --shard=${{ matrix.shardIndex }}/${{ matrix.shardTotal }}
      - uses: actions/upload-artifact@65c4c4a1ddee5b72f698fdd19549f0f0fb45cf08 # v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report-${{ matrix.shardIndex }}
          path: playwright-report/
          retention-days: 7
```

**Context:** `trace: "on-first-retry"` captures a full trace (DOM snapshots, network, console) only when a test fails and retries — zero overhead on passing tests, full debugging context on failures. Use `--shard` for parallelism across CI workers (cross-ref: `ci-test-splitting`). `forbidOnly` prevents `.only` from accidentally landing in CI. Upload the HTML report as an artifact so anyone can inspect failures without rerunning locally. Pin `playwright install` to only the browsers declared in your `projects` config (e.g., `chromium` instead of all browsers) to reduce install time and limit supply-chain surface. For production CI workflows, pin GitHub Actions to commit SHAs (e.g., `actions/checkout@<sha> # v4`) to guard against supply-chain tag mutation.

---

## 11. pytest Fundamentals (HIGH)

General pytest patterns for writing reliable, maintainable Python tests. For FastAPI-specific test patterns, see the **python-best-practices** skill.

### `pytest-fixtures`

**Impact: HIGH**

Use fixtures for test setup and teardown. Choose the right scope — `function` (default) for per-test isolation, `session` for expensive shared resources. Use `yield` for teardown. Compose small fixtures instead of building monoliths. Use `autouse` sparingly — only for truly universal setup.

**Incorrect:**

```python
# WRONG: Setup logic duplicated across tests, no teardown
import tempfile
import os

def test_process_file():
    path = tempfile.mktemp()
    with open(path, "w") as f:
        f.write("data")
    result = process_file(path)
    assert result == "processed"
    # Forgot to clean up — temp file leaks

def test_process_empty_file():
    path = tempfile.mktemp()
    with open(path, "w") as f:
        f.write("")
    result = process_file(path)
    assert result == "empty"
    # Same cleanup problem
```

**Correct:**

```python
# RIGHT: Fixture handles setup + teardown, composable, scoped appropriately
import pytest
from pathlib import Path

@pytest.fixture
def tmp_file(tmp_path: Path):
    """Create a temp file with content. Cleanup handled by tmp_path fixture."""
    file_path = tmp_path / "test_data.txt"
    file_path.write_text("data")
    return file_path

@pytest.fixture(scope="session")
def db_engine():
    """Expensive resource — create once per session, teardown after all tests."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()

@pytest.fixture  # function-scoped (default) — can request session-scoped db_engine
def db_session(db_engine):
    """Per-test session — fixture composition with automatic rollback."""
    connection = db_engine.connect()
    transaction = connection.begin()
    session = Session(connection)  # SQLAlchemy 2.0 — positional, not bind=
    yield session
    session.close()
    transaction.rollback()
    connection.close()

def test_process_file(tmp_file: Path):
    result = process_file(tmp_file)
    assert result == "processed"
```

**Context:** Fixture scope determines lifetime: `function` (default) runs per-test for full isolation, `class` runs once per test class, `module` once per file, `session` once per test run. Use `yield` to separate setup from teardown — pytest guarantees the teardown code runs even if the test fails. Compose fixtures by accepting other fixtures as parameters. Avoid `autouse=True` except for truly universal needs (like resetting a global config) — implicit setup hides dependencies and makes tests harder to understand.

---

### `pytest-parametrize`

**Impact: HIGH**

Use `@pytest.mark.parametrize` for data-driven tests instead of writing separate test functions or loops. Use `ids` for readable output. Use `indirect` to route parameters through fixtures.

**Incorrect:**

```python
# WRONG: Separate test functions for each case — duplication
def test_validate_email_valid():
    assert validate_email("user@example.com") is True

def test_validate_email_no_at():
    assert validate_email("userexample.com") is False

def test_validate_email_no_domain():
    assert validate_email("user@") is False

# WRONG: Loop inside a single test — first failure hides the rest
def test_validate_email_all():
    cases = [("user@example.com", True), ("bad", False), ("user@", False)]
    for email, expected in cases:
        assert validate_email(email) == expected
```

**Correct:**

```python
# RIGHT: Parametrize — each case runs independently with clear IDs
import pytest

@pytest.mark.parametrize(
    ("email", "expected"),
    [
        ("user@example.com", True),
        ("admin@test.org", True),
        ("userexample.com", False),
        ("user@", False),
        ("", False),
    ],
    ids=["valid-basic", "valid-org", "missing-at", "missing-domain", "empty"],
)
def test_validate_email(email: str, expected: bool):
    assert validate_email(email) == expected

# RIGHT: indirect=True routes parameters through a fixture
@pytest.fixture
def user(request: pytest.FixtureRequest):
    return create_user(role=request.param)

@pytest.mark.parametrize("user", ["admin", "editor", "viewer"], indirect=True)
def test_user_permissions(user):
    assert user.can_access_dashboard() == (user.role in ("admin", "editor"))
```

**Context:** `@pytest.mark.parametrize` runs the test once per parameter set, reports each independently, and stops at the first failure per case (not per function). Use `ids` to label cases — pytest output shows `test_validate_email[valid-basic]` instead of `test_validate_email[user@example.com-True]`. Use `indirect=True` when parameters need fixture processing (e.g., creating objects from role names). Stack multiple `@pytest.mark.parametrize` decorators for combinatorial testing.

---

### `pytest-conftest`

**Impact: HIGH**

Place fixtures in `conftest.py` at the appropriate directory level. Keep test-specific fixtures in the test file. Don't create a single root conftest with everything.

**Incorrect:**

```python
# WRONG: All fixtures in root conftest.py, even test-specific ones
# tests/conftest.py
import pytest

@pytest.fixture
def admin_user():
    return create_user(role="admin")

@pytest.fixture
def mock_stripe_webhook_payload():
    """Only used in tests/billing/test_webhooks.py"""
    return {"type": "invoice.paid", "data": {"amount": 1000}}

@pytest.fixture
def sample_csv_row():
    """Only used in tests/importers/test_csv.py"""
    return {"name": "Alice", "email": "alice@example.com"}
```

**Correct:**

```python
# RIGHT: Root conftest — only widely shared fixtures
# tests/conftest.py
import pytest

@pytest.fixture
def admin_user():
    """Used across multiple test directories."""
    return create_user(role="admin")

# RIGHT: Domain-specific conftest — scoped to its directory
# tests/billing/conftest.py
import pytest

@pytest.fixture
def mock_stripe_webhook_payload():
    """Only used by billing tests."""
    return {"type": "invoice.paid", "data": {"amount": 1000}}

# RIGHT: Test-specific fixture stays in the test file
# tests/importers/test_csv.py
import pytest

@pytest.fixture
def sample_csv_row():
    """Only used in this file — no reason for conftest."""
    return {"name": "Alice", "email": "alice@example.com"}

def test_import_csv_row(sample_csv_row):
    result = import_row(sample_csv_row)
    assert result.name == "Alice"
```

**Context:** pytest discovers `conftest.py` files by walking up the directory tree — a fixture in `tests/billing/conftest.py` is available to all tests under `tests/billing/` but not to `tests/api/`. Place fixtures at the narrowest scope possible: root conftest for cross-cutting concerns (DB sessions, auth helpers), directory conftest for domain-specific fixtures, and the test file itself for single-use fixtures. This keeps fixture discovery fast and makes dependencies explicit.

---

### `pytest-mocking`

**Impact: HIGH**

Use `monkeypatch` for env vars, attributes, and dict entries. Use `pytest-mock`'s `mocker` fixture for spy/stub patterns. Prefer these over raw `unittest.mock` — they auto-restore after each test.

**Incorrect:**

```python
# WRONG: Raw unittest.mock with manual cleanup
from unittest.mock import patch, MagicMock
import os

def test_config_reads_env():
    original = os.environ.get("API_KEY")
    os.environ["API_KEY"] = "test-key"
    try:
        config = load_config()
        assert config.api_key == "test-key"
    finally:
        if original is None:
            del os.environ["API_KEY"]
        else:
            os.environ["API_KEY"] = original

# WRONG: Patching internal implementation details
def test_process_order():
    with patch("app.orders.service._calculate_subtotal") as mock_sub:
        with patch("app.orders.service._apply_discount") as mock_disc:
            mock_sub.return_value = 100
            mock_disc.return_value = 90
            result = process_order(order)
            assert result.total == 90
```

**Correct:**

```python
# RIGHT: monkeypatch auto-restores after each test
def test_config_reads_env(monkeypatch):
    monkeypatch.setenv("API_KEY", "test-key")
    config = load_config()
    assert config.api_key == "test-key"

def test_config_missing_env(monkeypatch):
    monkeypatch.delenv("API_KEY", raising=False)
    with pytest.raises(ConfigError, match="API_KEY"):
        load_config()

# RIGHT: mocker fixture for spy/stub (from pytest-mock)
from unittest import mock

def test_sends_notification(mocker):
    mock_send = mocker.patch("app.notifications.email_client.send")
    process_order(order)
    mock_send.assert_called_once_with(
        to="user@example.com",
        subject=mock.ANY,
    )

# RIGHT: monkeypatch.setattr for replacing attributes
def test_retry_with_backoff(monkeypatch):
    monkeypatch.setattr("app.client.MAX_RETRIES", 1)
    with pytest.raises(ConnectionError):
        fetch_data()
```

**Context:** `monkeypatch` is a built-in pytest fixture that auto-restores patched values after each test — no `try/finally` or context managers needed. Use `monkeypatch.setenv`/`delenv` for environment variables, `monkeypatch.setattr` for module-level attributes and class methods, `monkeypatch.setitem`/`delitem` for dictionary entries. `pytest-mock`'s `mocker` fixture wraps `unittest.mock.patch` with automatic cleanup. Use `unittest.mock.ANY` (not `mocker.ANY`) for argument matchers. Prefer `mocker.patch("app.notifications.email_client.send")` (mock at the boundary) over patching internal helpers. Never use real-looking credential formats (e.g., `sk-`, `AKIA`) as test values — use opaque strings like `"test-key"` or `"fake-value"`.

---

## 12. pytest Advanced Patterns (MEDIUM)

Advanced pytest patterns for async testing, custom markers, and parallel execution.

### `pytest-async`

**Impact: MEDIUM**

Use anyio for async tests. Mark with `@pytest.mark.anyio`. Use `anyio` strict mode to enforce marker usage. For FastAPI-specific async test patterns, see `test-async-client` in the python-best-practices skill.

**Incorrect:**

```python
# WRONG: Using asyncio.run or event loop manipulation
import asyncio

def test_fetch_user():
    result = asyncio.run(fetch_user(1))
    assert result.name == "Alice"

# WRONG: Missing marker — async test silently runs as sync (returns coroutine, no await)
import pytest

async def test_create_user():
    user = await create_user(name="Bob")
    assert user.id is not None  # Never reached — no runner awaits this coroutine
```

**Correct:**

```python
# RIGHT: anyio with strict mode — all async tests must have marker
# pyproject.toml
# [tool.pytest.ini_options]
# anyio_mode = "strict"

import pytest

@pytest.mark.anyio
async def test_fetch_user():
    result = await fetch_user(1)
    assert result.name == "Alice"

@pytest.mark.anyio
async def test_create_user():
    user = await create_user(name="Bob")
    assert user.id is not None

# RIGHT: Async fixture with anyio
@pytest.fixture
async def async_client():
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.mark.anyio
async def test_api_endpoint(async_client):
    response = await async_client.get("/api/users")
    assert response.status_code == 200
```

**Context:** `anyio` includes a pytest plugin that supports `@pytest.mark.anyio` — no separate `pytest-anyio` package needed. Enable `anyio_mode = "strict"` in `pyproject.toml` to ensure every async test has a marker — without it, unmarked async tests silently don't run as async. Unlike `pytest-asyncio` (which requires `@pytest_asyncio.fixture` for async fixtures), anyio works with the standard `@pytest.fixture` decorator on async functions. Prefer anyio over `pytest-asyncio` for new projects — it's backend-agnostic (asyncio and trio) and aligns with modern Python async best practices. For FastAPI apps, combine with `httpx.AsyncClient` (see `test-async-client` in python-best-practices).

---

### `pytest-markers`

**Impact: MEDIUM**

Register custom markers in `pyproject.toml`. Use `--strict-markers` to catch typos. Use `filterwarnings` to control warning behavior in tests.

**Incorrect:**

```python
# WRONG: Unregistered markers — no error, silently ignored with --strict-markers
@pytest.mark.slow
def test_full_pipeline():
    result = run_pipeline(large_dataset)
    assert result.success

@pytest.mark.integation  # Typo! No error without --strict-markers
def test_external_api():
    response = call_external_api()
    assert response.ok

# WRONG: Warnings spam test output, no filterwarnings config
def test_deprecated_function():
    result = old_function()  # DeprecationWarning clutters output
    assert result == 42
```

**Correct:**

```python
# RIGHT: Register markers in pyproject.toml
# [tool.pytest.ini_options]
# markers = [
#     "slow: marks tests as slow (deselect with '-m \"not slow\"')",
#     "integration: marks tests requiring external services",
# ]
# addopts = "--strict-markers -m 'not integration'"  # exclude integration by default
# filterwarnings = [
#     "error",
#     "ignore::DeprecationWarning:third_party_lib.*",
# ]

import pytest

@pytest.mark.slow
def test_full_pipeline():
    result = run_pipeline(large_dataset)
    assert result.success

@pytest.mark.integration
def test_external_api():
    response = call_external_api()
    assert response.ok

# Run subsets: pytest -m "not slow" or pytest -m integration
# In CI, pass -m integration in a separate job with network access
```

**Context:** `--strict-markers` makes unregistered markers a hard error — catches typos like `@pytest.mark.integation` at collection time instead of silently running the test. Register markers in `pyproject.toml` under `[tool.pytest.ini_options]` with descriptions. Use `filterwarnings = ["error"]` to promote all warnings to errors (catches deprecation issues early), then add `ignore` entries for third-party warnings you can't fix — scope `ignore` entries as narrowly as possible (prefer `ignore::DeprecationWarning:specific_module` over broad globs to avoid silencing warnings from security-relevant libraries). Run marker subsets with `-m "not slow"` for fast local iteration, full suite in CI.

---

### `pytest-xdist`

**Impact: MEDIUM**

Use pytest-xdist for parallel test execution. Use `--dist loadscope` or `--dist loadfile` to group related tests on the same worker. Ensure fixtures are worker-safe. Cross-ref: `ci-parallel-execution` for general CI parallelism guidance.

**Incorrect:**

```python
# WRONG: Shared mutable state across tests — breaks under parallel execution
# conftest.py
_cache = {}

@pytest.fixture
def shared_cache():
    return _cache  # Same dict shared across workers — race conditions

def test_add_to_cache(shared_cache):
    shared_cache["key"] = "value"
    assert shared_cache["key"] == "value"

def test_cache_empty(shared_cache):
    assert len(shared_cache) == 0  # Fails even serially — shared mutable state is the root cause

# WRONG: Tests depend on execution order
def test_create_user():
    create_user("alice")

def test_user_exists():
    assert get_user("alice") is not None  # Depends on test_create_user running first
```

**Correct:**

```python
# RIGHT: Worker-safe fixtures — each worker gets its own resources
# conftest.py
import pytest

@pytest.fixture
def isolated_cache():
    """Fresh cache per test — safe for parallel execution."""
    return {}

# RIGHT: Use tmp_path (per-test) or tmp_path_factory (per-session) for file isolation
@pytest.fixture
def worker_db(tmp_path):
    """Each worker gets its own SQLite database."""
    db_path = tmp_path / "test.db"
    engine = create_engine(f"sqlite:///{db_path}")
    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()

def test_add_to_cache(isolated_cache):
    isolated_cache["key"] = "value"
    assert isolated_cache["key"] == "value"

def test_cache_starts_empty(isolated_cache):
    assert len(isolated_cache) == 0  # Always true — fresh dict each test
```

```toml
# pyproject.toml — xdist configuration
[tool.pytest.ini_options]
addopts = "-n auto --dist loadscope"
# -n auto: spawn one worker per CPU core
# --dist loadscope: group tests by module/class on same worker
```

**Context:** `pytest-xdist` distributes tests across multiple processes. `--dist loadscope` groups tests by module (or class) onto the same worker — reduces fixture setup overhead and avoids cross-test interference. `--dist loadfile` is similar but groups by file. `--dist load` (default) distributes individual tests for maximum parallelism but can break tests with shared state. Use `-n auto` to match CPU cores, or `-n 4` for a fixed count. Ensure all fixtures create per-test or per-worker resources — no module-level mutable state. For databases, use `tmp_path` to give each worker its own SQLite file, or use transactions with rollback for shared Postgres (cross-ref: `test-db-isolation` in python-best-practices).
