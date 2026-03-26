---
name: elixir-antipatterns
description: >
  Elixir antipattern catalog and verification patterns for Elixir/Phoenix codebases.
  Trigger: When doing code modification, refactoring, or code review in an Elixir project.
license: Apache-2.0
metadata:
  author: tsard
  version: "2.0"
---

## When to Use

Load when working in any Elixir/Phoenix project. Apply patterns silently.

---

## Complexity

### with chains > 4 steps — PROHIBITED
Violates single responsibility, hinders testing.
```elixir
# NO — too many responsibilities in one chain
with {:ok, a} <- step1(), {:ok, b} <- step2(a),
     {:ok, c} <- step3(b), {:ok, d} <- step4(c),
     {:ok, e} <- step5(d), {:ok, f} <- step6(e), do: {:ok, f}

# YES — group into cohesive functions
with {:ok, validated} <- validate_and_fetch(id),
     {:ok, processed} <- process_business_rules(validated),
     {:ok, result}    <- persist_and_notify(processed), do: {:ok, result}
```

### Modules > 800 lines — PROHIBITED
Multiple responsibilities, low cohesion.
```elixir
# NO — monolithic module mixing validation, queries, business logic
defmodule UserService do ... end  # 500+ lines

# YES — split by responsibility
defmodule UserValidator,   do: ...  # ~80 lines
defmodule UserRepository,  do: ...  # ~60 lines
defmodule UserService,     do: ...  # ~120 lines (coordinates)
```

---

## Error Handling

### raise for business errors — PROHIBITED
Expected failures must be values, not exceptions.
```elixir
# NO
def fetch_user(id), do: Repo.get(User, id) || raise "Not found"

# YES
@spec fetch_user(String.t()) :: {:ok, User.t()} | {:error, :not_found}
def fetch_user(id) do
  case Repo.get(User, id) do
    nil  -> {:error, :not_found}
    user -> {:ok, user}
  end
end
```

### nil as error value — PROHIBITED
Loses failure context, makes debugging harder.
```elixir
# NO — nil tells you nothing
def find_user(email), do: Repo.get_by(User, email: email)

# YES — explicit context
@spec find_user(String.t()) :: {:ok, User.t()} | {:error, :not_found}
def find_user(email) do
  case Repo.get_by(User, email: email) do
    nil  -> {:error, :not_found}
    user -> {:ok, user}
  end
end
```

### Mixed error conventions in same module — PROHIBITED
```elixir
# NO — inconsistent within one module
def create(attrs), do: Repo.insert(changeset(attrs))  # {:ok, _} | {:error, _}
def delete(id),    do: Repo.delete!(Repo.get(User, id))  # raises
def find(id),      do: Repo.get(User, id)                # returns nil

# YES — uniform convention with @spec on every public function
@spec create(map())     :: {:ok, User.t()} | {:error, Changeset.t()}
@spec delete(String.t()) :: {:ok, User.t()} | {:error, :not_found}
@spec find(String.t())   :: {:ok, User.t()} | {:error, :not_found}
```

### with/do without pattern matching — PROHIBITED
Does not check errors.
```elixir
# NO — assignment doesn't short-circuit on {:error, _}
with result = call_something(), do: use(result)

# YES — match on success
with {:ok, result} <- call_something(), do: use(result)
```

---

## Separation of Concerns

### Business logic in LiveView — PROHIBITED
View becomes untestable; logic becomes non-reusable.

Architecture layers — always respect this boundary:
```
User Request → LiveView (UI only) → Context (business logic) → Schema/Repo (data)
               handle_event()       Accounts.create_user()      Repo.insert()
```

```elixir
# NO — validation and queries inside handle_event
def handle_event("create", %{"user" => params}, socket) do
  if String.length(params["name"]) < 3 do
    {:noreply, put_flash(socket, :error, "Too short")}
  else
    case Repo.insert(User.changeset(%User{}, params)) do
      {:ok, user} -> send_email(user); redirect(socket)
    end
  end
end

# YES — LiveView delegates to context
def handle_event("create", params, socket) do
  case Accounts.create_user(params) do
    {:ok, user}  -> {:noreply, redirect(socket, to: ~p"/users/#{user}")}
    {:error, cs} -> {:noreply, assign(socket, changeset: cs)}
  end
end
```

### I/O in pure functions — PROHIBITED
Prevents testing without mocks; breaks composability.
```elixir
# NO — Logger inside calculation
def calculate_total(items) do
  total = Enum.reduce(items, 0, &(&1.price + &2))
  Logger.info("Total: #{total}")
  total
end

# YES — separate pure calculation from I/O
def calculate_total(items), do: Enum.reduce(items, 0, &(&1.price + &2))

def calculate_and_log_total(items) do
  total = calculate_total(items)
  Logger.info("Total: #{total}")
  total
end
```

### Derived state in LiveView assigns — PROHIBITED
Data duplication requires manual sync.
```elixir
# NO
assign(socket, users: users, user_count: length(users), has_users: users != [])

# YES — only base data in assigns; derive in helpers
assign(socket, users: users)
def user_count(assigns), do: length(assigns.users)
def has_users?(assigns),  do: assigns.users != []
```

### Logger inside pipelines — PROHIBITED
```elixir
# NO
value |> transform() |> Logger.info() |> next_step()

# YES — use tap/1 for side effects
value |> transform() |> tap(&Logger.info/1) |> next_step()
```

---

## Data & Queries

### N+1 queries — PROHIBITED
Impact: 100 users = ~10s with N+1 vs ~5ms with preload.
```elixir
# NO — N+1: 101 queries for 100 users
users = Repo.all(User)
Enum.map(users, fn u -> Repo.all(from p in Post, where: p.user_id == ^u.id) end)

# YES — 2 queries total
User |> Repo.all() |> Repo.preload(:posts)

# YES — complex filtering (e.g. only published posts): use join + preload in query
from(u in User,
  join: p in assoc(u, :posts), on: p.status == :published,
  preload: [posts: p]
) |> Repo.all()
```

### Queries inside Enum — PROHIBITED
```elixir
# NO
Enum.filter(users, fn u -> Repo.exists?(query) end)

# YES
single_query |> where([u], u.id in ^ids) |> Repo.all()
```

### Transactions for single operations — PROHIBITED
Unnecessary overhead and DB locks.
```elixir
# NO
Repo.transaction(fn -> Repo.insert!(user) end)

# YES — direct call
Repo.insert(user)

# YES — transaction only for multi-operation atomicity
Repo.transaction(fn ->
  {:ok, user}    = Repo.insert(user_cs)
  {:ok, profile} = Repo.insert(profile_cs)
  %{user: user, profile: profile}
end)
```

### Queries without indexes on frequently searched columns — PROHIBITED
Impact: full table scan on 1M+ rows vs instant index lookup.
```elixir
# NO — searched column without index
create table(:users) do
  add :email, :string
end

# YES
create table(:users) do
  add :email, :string
end
create unique_index(:users, [:email])
```

---

## Concurrency

### Tasks for simple CPU-bound operations — PROHIBITED
Scheduling overhead with no benefit.
```elixir
# NO — Task for trivial computation
def calculate_total(items) do
  Task.async(fn -> Enum.sum(items) end) |> Task.await()
end

# YES — direct call
def calculate_total(items), do: Enum.sum(items)

# YES — Task only for parallel I/O
def fetch_parallel(ids) do
  ids |> Enum.map(&Task.async(fn -> fetch_api(&1) end)) |> Enum.map(&Task.await/1)
end
```
Use processes only for: I/O, fault isolation, or concurrent state management.

---

## Testing

### Tests without assertions — PROHIBITED
No validation = false sense of coverage.
```elixir
# NO
test "creates user", do: UserService.create_user(%{name: "Juan"})

# YES
test "creates user successfully" do
  assert {:ok, user} = UserService.create_user(%{name: "Juan"})
  assert user.name == "Juan"
end
```

### Dependent / non-isolated tests — PROHIBITED
Fail in different order; cannot be parallelized.
```elixir
# NO — shared state between tests
defmodule UserServiceTest do
  use ExUnit.Case
  test "creates", do: UserService.create_user(%{email: "a@b.com"})
  test "finds",   do: UserService.find_by_email("a@b.com")  # depends on previous
end

# YES — each test isolated, run in parallel
defmodule UserServiceTest do
  use ExUnit.Case, async: true
  setup do: {:ok, user: create_test_user()}
  test "finds user", %{user: u} do
    assert {:ok, _} = UserService.find_by_email(u.email)
  end
end
```

---

## Quick Reference

| Situation | Anti-Pattern | Correct Pattern |
|-----------|-------------|-----------------|
| Error handling | `raise "Not found"` | `{:error, :not_found}` |
| Missing data | Return `nil` | `{:error, :not_found}` |
| Mixed conventions | `raise` in one fn, `nil` in another | `@spec` + `{:ok,_}\|{:error,_}` everywhere |
| Business logic | In LiveView `handle_event` | In context modules |
| Associations | `Enum.map` + `Repo.get` in loop | `Repo.preload/2` |
| Filtered associations | `preload` after Enum filter | `join` + `preload` in query |
| with chains | `validated = fn()` | `{:ok, validated} <- fn()` |
| with length | 6+ steps in one chain | Group into 3 cohesive functions |
| Frequent queries | No index | `create index(:table, [:col])` |
| Pure functions | `Logger.info` inside calculation | Extract to coordinator, keep fn pure |
| LiveView assigns | `user_count: length(users)` | Derive in helper at render time |
| Concurrency | `Task.async` for `Enum.sum` | Direct call; Task only for I/O |
| Testing | No assertions | `assert` expected behavior |
| Test isolation | Shared state, no `async: true` | `async: true` + per-test setup |

---

## High-Risk Patterns — Always Stop to Verify

Stop and verify (grep + read) before modifying:
- `@spec` return type changes (`{:ok, x}` ↔ `{:error, x}`)
- `defstruct` field additions or removals
- `Ecto.Schema` field type changes
- `Repo.(get|insert|update|delete|preload)` — verify associations loaded
- Files in `lib/*/listeners/*.ex` — event side effects
- Files in `lib/*/database/*.ex` — data layer contracts
- Any public function signature change (arity, parameter order)

---

## Context Mapping for Large Files (≥ 800 lines)

Build mental model BEFORE writing code:
```
grep: "^  def |^  defp |@type |@spec |use |import |alias "
```
Extract: module name, public API, types, dependencies, private helpers.
Only hydrate (full read) functions directly relevant to the current task.

If grep returns 0 results on non-empty file → `[!] GREP SANITY FAIL` — read first 200 lines manually.
If file uses `use Ecto.Schema` or `defmacro` → `[!] Metaprogramming` — grep may miss generated functions, use hybrid approach.
