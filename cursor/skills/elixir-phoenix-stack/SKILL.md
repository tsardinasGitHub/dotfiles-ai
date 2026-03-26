---
name: elixir-phoenix-stack
description: >
  Conventions, patterns, and philosophy for Elixir/Phoenix/LiveView/Ecto projects.
  Trigger: When working in any Elixir or Phoenix project.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## When to Use

Load when working in any Elixir/Phoenix project. Complements `elixir-antipatterns`
(what NOT to do) — this skill defines what TO do and how.

---

## Core Philosophy

- **Functional first**: prefer higher-order functions and pattern matching over imperative loops
- **Immutability by default**: data transformations, not mutations
- **Let it crash**: unexpected failures belong to supervisors, not defensive `try/rescue`
- **Honest functions**: `@spec` on every public function, return types reflect reality
- **Thin boundaries**: LiveView handles UI events, contexts own business logic, schemas own data shape

---

## Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Files, functions, variables | `snake_case` | `user_signed_in?`, `calculate_total` |
| Modules | `PascalCase` | `UserService`, `AccountsContext` |
| Predicates | End in `?` | `valid?`, `admin?` |
| Side-effect functions | End in `!` (raises) or return `{:ok,_}\|{:error,_}` | `create!` vs `create` |
| Contexts | Noun of the domain | `Accounts`, `Billing`, `Notifications` |
| Schemas | Singular noun | `User`, `Invoice`, `Payment` |

Sort `alias` declarations alphabetically within each block.

---

## Elixir Patterns

### Pattern matching and guards — prefer over conditionals
```elixir
# YES — pattern match in function head
def process(%User{role: :admin} = user), do: admin_flow(user)
def process(%User{} = user), do: default_flow(user)

# YES — guard for type/range checks
def calculate(amount) when is_number(amount) and amount > 0, do: ...
```

### Pipe operator — for transformations, not for assignment chains
```elixir
# YES
params
|> validate_required([:email, :name])
|> validate_format(:email, ~r/@/)
|> cast_embed(:address)

# NO — don't pipe when only 1 step or when introducing side effects mid-pipe
```

### One-line functions — when the body fits cleanly on one line
```elixir
def full_name(user), do: "#{user.first_name} #{user.last_name}"
def admin?(user), do: user.role == :admin
```

### Monadic code — reinforce `{:ok, _} | {:error, _}` discipline
Every function that can fail returns a tagged tuple. No exceptions for expected failures.
See `elixir-error-monad` skill for `Error.m` patterns.

---

## Phoenix Conventions

### Architecture layers — always respect this order
```
Router → Controller/LiveView → Context → Schema/Repo
```
- Controllers and LiveViews: only UI concerns (params, flash, redirects, assigns)
- Contexts: all business logic, validation, orchestration
- Schemas: data shape, changesets, associations

### Contexts — organize by domain, not by technical layer
```elixir
# YES — domain-oriented contexts
Accounts.create_user(params)
Billing.charge_invoice(invoice, payment_method)
Notifications.send_welcome(user)

# NO — technical-layer organization
UserController.create_db_record(params)
```

### Changesets — the right place for data validation
```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email, :password])
  |> validate_required([:name, :email])
  |> validate_format(:email, ~r/@/)
  |> validate_length(:password, min: 8)
  |> unique_constraint(:email)
end
```

### RESTful routing — follow Phoenix conventions
```elixir
resources "/users", UserController, only: [:index, :show, :new, :create, :edit, :update, :delete]
# Use nested routes only when the relationship is strict ownership
```

---

## LiveView

- `handle_event`: receive event → call context → assign result or redirect
- State in assigns, computation in contexts
- Use `phx-debounce` for search inputs, `phx-throttle` for click-heavy actions
- Components for reusable UI; `live_component` only when you need isolated state

---

## GenServer and Concurrency

- **GenServer**: stateful processes, background jobs, rate limiters, caches
- **Task**: one-off concurrent I/O (parallel API calls, fire-and-forget with `Task.start`)
- **Supervisor**: wrap any GenServer that must restart on failure; choose strategy deliberately

```elixir
# GenServer state — always define as a typed struct
defmodule MyApp.Cache do
  use GenServer

  defstruct entries: %{}, ttl: 300

  @type t :: %__MODULE__{entries: map(), ttl: pos_integer()}

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def init(_opts), do: {:ok, %__MODULE__{}}
end
```

---

## Performance

### Caching
- **ETS**: in-process cache for read-heavy, low-TTL data; use `Cachex` for a cleaner API
- **Redis**: shared cache across nodes; use via `Redix` or `Nebulex` with Redis adapter
- Cache at context boundary, not at schema/Repo level

### Database
- Index all columns used in `WHERE`, `JOIN ON`, or `ORDER BY`
- Use `Repo.preload` for associations; use `join + preload` for filtered associations
- Prefer `Repo.all(query)` with composable queries over multiple `Repo.get` calls in loops

---

## Testing

- **ExUnit** for all tests; `async: true` unless the test touches global state or external services
- **ExMachina** for test data factories — one factory per schema, in `test/support/factories.ex`
- TDD cycle: write failing test → implement minimum → refactor
- Test behavior, not implementation details
- Integration tests for critical flows; unit tests for context functions

```elixir
# Factory pattern with ExMachina
defmodule MyApp.Factory do
  use ExMachina.Ecto, repo: MyApp.Repo

  def user_factory do
    %User{
      name: sequence(:name, &"User #{&1}"),
      email: sequence(:email, &"user#{&1}@example.com"),
      role: :member
    }
  end
end

# In tests
user = insert(:user, role: :admin)
```

---

## Security

- **Authentication**: Guardian (JWT) or Pow (session-based) — pick one per project, don't mix
- **Authorization**: plug-based policies or `Bodyguard` library for context-level checks
- **Sobelow**: run `mix sobelow` in CI — catches XSS, SQL injection, insecure configs
- **Strong params**: always use `cast/3` in changesets, never pass raw params to Repo
- **CSRF**: Phoenix handles it automatically via `protect_from_forgery` — don't disable it
- **Secrets**: never in source code, always via `config/runtime.exs` from env vars

---

## Documentation

- `@moduledoc`: every module, even if one line; mark legacy modules explicitly
- `@doc`: every public function, especially context functions that are the public API
- `@spec`: every public function; return type must reflect all possible returns
- Doctests in `@doc` for pure utility functions — they run as tests automatically
