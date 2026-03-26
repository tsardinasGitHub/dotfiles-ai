---
name: elixir-error-monad
description: >
  Correct usage patterns for the Error.m monad in Elixir projects.
  Trigger: When writing or reviewing code that uses Error.m do blocks.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## When to Use

Load when working in an Elixir project that uses the `Error.m` monad (custom or library-based).
Apply patterns silently whenever you write or review `Error.m do` blocks.

---

## Core Rule

`Error.m` short-circuits on `{:error, _}`. Every binding inside must use `<-` (monadic bind),
never `=` (plain assignment). Using `=` breaks the propagation chain silently.

---

## Critical Antipatterns

### = inside Error.m — PROHIBITED
Assignment does not propagate errors; it silences them.
```elixir
# NO — validate/1 returning {:error, _} is ignored
Error.m do
  user      <- fetch_user(id)
  validated  = validate(user)   # ← plain assignment, error swallowed
  save(validated)
end

# YES — monadic bind propagates error automatically
Error.m do
  user      <- fetch_user(id)
  validated <- validate(user)   # ← short-circuits on {:error, _}
  save(validated)
end
```

### Non-monadic functions in Error.m — PROHIBITED
Every bound function must return `{:ok, value} | {:error, reason}`.
```elixir
# NO — String.upcase/1 returns a plain string, not {:ok, _}
Error.m do
  user <- fetch_user(id)
  name <- String.upcase(user.name)   # ← not monadic
  save(name)
end

# YES — wrap with Error.return/1 (or {:ok, ...}) to lift into monad
Error.m do
  user <- fetch_user(id)
  name <- (user.name |> String.upcase() |> Error.return())
  save(name)
end
```

---

## Correct Usage Patterns

### Standard happy-path chain
```elixir
Error.m do
  user    <- fetch_user(id)
  valid   <- validate_permissions(user, :write)
  result  <- perform_action(valid)
  {:ok, result}
end
```

### Mixing pure computation
```elixir
# Pure transformations that cannot fail: use let binding or pipe before entering monad
name = String.upcase(raw_name)

Error.m do
  user   <- fetch_user(id)
  result <- save(%{user | display_name: name})
  {:ok, result}
end
```

### Error enrichment
```elixir
Error.m do
  record <- fetch_record(id)
  _      <- validate(record)
           |> Result.map_error(&{:validation_failed, &1})
  {:ok, record}
end
```

---

## Before Writing any Error.m Block

1. Confirm every bound function (`<-`) returns `{:ok, _} | {:error, _}`
2. For pure functions (String, Enum, Map, etc.): compute outside the block OR wrap with `Error.return/1`
3. If unsure about a function's return type: grep its `@spec` before binding

---

## Checklist

- [ ] No `=` assignments inside `Error.m do` blocks
- [ ] Every `<-` binding calls a function with `{:ok, _} | {:error, _}` return type
- [ ] Pure transformations lifted with `Error.return/1` or extracted before the block
- [ ] `@spec` verified for any non-obvious external function bound in the chain
