---
name: testing-conventions
description: >
  Universal testing conventions that apply across all stacks (Elixir, Python, React/TypeScript).
  Trigger: When writing or reviewing tests in any project.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## When to Use

Load in every project regardless of stack. These conventions complement stack-specific skills.

---

## Core Philosophy

**Test behavior, not implementation.**

A test that breaks when you rename a private function is testing implementation.
A test that breaks when the observable behavior changes is testing behavior.

---

## Structure — Arrange · Act · Assert

Every test has three parts, in order. Name them with comments when the test is non-trivial.

```python
# Python
def test_creates_user_when_email_is_valid():
    # Arrange
    request = CreateUserRequest(email="leo@dox.cl", name="Leo")

    # Act
    result = await use_case.execute(request)

    # Assert
    assert result.is_ok()
    assert result.unwrap().email == "leo@dox.cl"
```

```elixir
# Elixir
test "returns error when student level exceeds maximum" do
  # Arrange
  student = build(:student, level: 10)

  # Act
  result = Student.advance_level(student)

  # Assert
  assert {:error, :not_eligible} = result
end
```

```typescript
// TypeScript
test('returns normalized role when user is admin', async () => {
  // Arrange
  mockService.mockResolvedValue({ role: 'ADMIN', email: 'A@B.COM' })

  // Act
  const { result } = renderHook(() => useUserProfile(1), { wrapper })
  await waitFor(() => !result.current.isLoading)

  // Assert
  expect(result.current.data.role).toBe('admin')
})
```

---

## Naming — Describe behavior, not the method

```
✅  "should reject login when password is incorrect"
✅  "returns error when student level exceeds maximum"
✅  "marks goal as completed after all tasks are done"

❌  "test_create_user"
❌  "login test"
❌  "it works"
```

Pattern: `should [expected behavior] when [condition]`
Or in Elixir: `"[verb] [expected outcome] when [condition]"`

---

## One Behavior Per Test

One test verifies one behavior. Multiple asserts are fine if they all describe the same thing.

```python
# OK — multiple asserts, same behavior (user creation)
assert result.is_ok()
assert result.unwrap().email == "leo@dox.cl"
assert result.unwrap().id is not None

# NOT OK — two behaviors in one test
assert result.is_ok()
assert email_service.send.called  # separate concern: notification
```

If a test needs `and` in its name, split it into two tests.

---

## Mocking — Interfaces, not modules

Mock at the boundary of what you own. Never mock your own domain or application logic.

```python
# NO — mocking own application internals
mock_repo.find_by_email.assert_called_once()  # testing how, not what
mock_event_bus.publish.assert_called_once()

# YES — mock external boundary, assert observable output
mock_http_client.post.return_value = {"status": "sent"}
result = await notification_service.send(message)
assert result.is_ok()
```

```elixir
# NO — mocking internal module
expect(Leasing.DocumentValidator, :validate, fn _ -> {:ok, :valid} end)

# YES — mock external dependency (HTTP, external API)
expect(HTTPoison, :post, fn _url, _body, _headers -> {:ok, %{status_code: 200}} end)
```

```typescript
// NO — mock React Query internals
jest.mock('@tanstack/react-query')

// YES — mock the service layer (the I/O boundary)
jest.mock('../services/userService')
mockUserService.getById.mockResolvedValue(dto)
```

---

## Integration Tests for Critical Flows

Unit tests verify isolated logic. Integration tests verify that the pieces work together.

Critical flows that must have integration tests:
- Authentication / authorization paths
- Data creation with side effects (events, emails, state transitions)
- External integrations (payment, signing, messaging)
- Multi-step workflows (state machines, wizard flows)

```elixir
# Integration test — full flow through Phoenix endpoint
test "POST /api/v1/auth/login returns JWT cookie on valid credentials" do
  user = insert(:user, email: "leo@dox.cl", password: "secret123")

  conn = post(conn, "/api/v1/auth/login", %{email: "leo@dox.cl", password: "secret123"})

  assert conn.status == 200
  assert get_resp_header(conn, "set-cookie") != []
end
```

---

## What NOT to Test

- Trivial getters and setters with no logic
- Framework behavior (Ecto validations, Phoenix routing) — trust the framework
- Configuration values
- Test helpers and factories themselves

```python
# NOT worth testing
def get_email(self) -> str:
    return self.email

# Worth testing — has logic
def requires_parental_consent(self) -> bool:
    return self.age() < 13
```

---

## Quick Reference

| Principle | Rule |
|-----------|------|
| What to test | Observable behavior and outputs |
| What not to test | Internal call sequences, private functions |
| Structure | Arrange → Act → Assert |
| Naming | "should [behavior] when [condition]" |
| Mocks | Only at external boundaries (HTTP, DB, email) |
| Integration | Always for auth, state machines, external integrations |
| Skip | Trivial getters, framework behavior, config |
