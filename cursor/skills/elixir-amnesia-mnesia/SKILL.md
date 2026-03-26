---
name: elixir-amnesia-mnesia
description: >
  Patterns for Mnesia in-memory database via the Amnesia library in Elixir projects.
  Trigger: When working with Mnesia, Amnesia, deftable, or Leasing.Database.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## When to Use

Load when working in any Elixir project that uses Amnesia/Mnesia. Apply silently.

---

## Table Definition

```elixir
require Amnesia
use Amnesia

defdatabase MyApp.Database do
  # :set          — unique keys, unordered
  # :ordered_set  — unique keys, ordered by key
  # :bag          — duplicate keys allowed (multiple records per key)

  deftable Session,      [:sid, :data, :timestamp],                type: :bag, index: [:timestamp]
  deftable Users,        [:username, :unique_id],                  type: :ordered_set
  deftable TasksState,   [:username, :task],                       type: :bag, index: [:task]
  deftable OrdenFirma,   [:id, :document_ids, :state, :id_exp],   type: :set, index: [:state, :id_exp]
end
```

**Table type guide:**
- `:set` — one record per key (like a map); use for entities with unique ID
- `:ordered_set` — same as `:set` but sorted; use for lookup tables (roles, permissions)
- `:bag` — multiple records per key; use for many-to-many (user→roles, task→users)

---

## CRUD Operations

All writes and reads must happen inside `Amnesia.transaction do`.

```elixir
# Write
Amnesia.transaction do
  %Users{username: "leo@dox.cl", unique_id: "abc-123"} |> Users.write()
end

# Read by primary key
Amnesia.transaction do
  Users.read("leo@dox.cl")  # returns struct or nil
end

# Match by field(s) — returns list
Amnesia.transaction do
  Users.match(username: "leo@dox.cl") |> Amnesia.Selection.values()
end

# Read via secondary index
Amnesia.transaction do
  :mnesia.index_read(TasksState, "some-task-id", :task)
end

# Query with where macro
Amnesia.transaction do
  TasksState.where(username != "excluded_user") |> Amnesia.Selection.values()
end

# Stream entire table
Amnesia.transaction do
  Users.stream() |> Enum.to_list()
end

# Delete
Amnesia.transaction do
  Users.delete("leo@dox.cl")
end
```

---

## Tuple vs. Struct — The Critical Gotcha

Mnesia returns raw **tuples** when using `:mnesia.*` calls directly. Amnesia wraps them as **structs** in `Amnesia.transaction`. Always verify what you receive:

```elixir
# Direct :mnesia call → returns tuples
:mnesia.index_read(OrdenFirma, state, :state)
# → [{OrdenFirma, "uuid-1", [...], "pending", "exp-42", "web", "2024-01-01"}, ...]

# Amnesia.transaction → usually returns structs
Amnesia.transaction do
  OrdenFirma.read("uuid-1")
end
# → %OrdenFirma{id: "uuid-1", state: "pending", ...}

# Pattern match defensively
case OrdenFirma.read(id) do
  nil                      -> {:error, :not_found}
  tuple when is_tuple(tuple) -> tuple |> order_tuple_to_struct()
  %OrdenFirma{} = struct   -> struct
end
```

**Tuple-to-struct converter — required when using `:mnesia.*` directly:**

```elixir
def order_tuple_to_struct({module, id, document_ids, state, id_exp, origin, date_ini}) do
  struct(module, %{
    id: id,
    document_ids: document_ids,
    state: state,
    id_exp: id_exp,
    origin: origin,
    date_ini: date_ini,
  })
end

# Fallback for records written before a field was added (schema evolution)
def order_tuple_to_struct({module, id, document_ids, state, id_exp}) do
  struct(module, %{id: id, document_ids: document_ids, state: state, id_exp: id_exp,
                   origin: "unknown", date_ini: nil})
end
```

---

## Adding Indexes After Table Creation

Indexes defined in `deftable` are created automatically, but when adding new indexes or creating tables manually:

```elixir
# After Leasing.Database.create(disk: [node()]):
:mnesia.add_table_index(OrdenFirma, :state)
:mnesia.add_table_index(OrdenFirma, :id_exp)

# Wait for table before adding index (avoids race condition)
:mnesia.wait_for_tables([DistributionListMember], 5000)
:mnesia.add_table_index(DistributionListMember, :list_id)

# Safe index addition (won't crash if already exists)
try do
  :mnesia.add_table_index(Table, :field)
catch
  :exit, reason -> IO.puts("Index already exists or error: #{inspect(reason)}")
end
```

---

## Migration Pattern — Backup → Destroy → Recreate → Restore

Used when adding tables, changing table structure, or resetting the database.

```elixir
def mnesia_setup do
  # 1. Backup data from all existing tables
  {:ok, users_backup} = safe_backup_table(Users)
  {:ok, roles_backup} = safe_backup_table(Role)

  # 2. Tear down and rebuild schema
  Amnesia.stop()
  Amnesia.Schema.destroy()
  Amnesia.Schema.create([node()])
  Amnesia.start()
  MyApp.Database.create(disk: [node()])

  # 3. Add indexes (always after create, not before)
  :mnesia.add_table_index(OrdenFirma, :id_exp)
  :mnesia.add_table_index(OrdenFirma, :state)

  # 4. Restore data
  restore_table(Users, users_backup)
  restore_table(Role, roles_backup)
end

defp safe_backup_table(table) do
  try do
    Amnesia.transaction do
      {:ok, table.stream() |> Enum.to_list()}
    end
  catch
    :exit, {:no_exists, _} -> {:ok, []}  # table didn't exist yet, safe to skip
  end
end

defp restore_table(table, records) when is_list(records) do
  Amnesia.transaction do
    Enum.each(records, fn record ->
      attrs = Amnesia.Table.info(table, :attributes)
      record |> Map.from_struct() |> Map.take(attrs) |> then(&struct(table, &1)) |> table.write()
    end)
  end
end
```

**Rule**: always backup before destroying. `:no_exists` exit is normal for new tables — catch it and return `{:ok, []}`.

---

## Schema Evolution — Adding Fields to Existing Tables

When adding a new field to a table (e.g., `expanded_items` to `SidebarState`):

1. Add the field to the `deftable` definition
2. Run `mnesia_setup` with an `:initial` flag that initializes the new field for existing records
3. After one successful run, use the normal `mnesia_setup` for all future migrations

```elixir
# In restore, initialize new field only on :initial migration
defp restore_with_migration(SidebarState, records, :initial) do
  Amnesia.transaction do
    Enum.each(records, fn record ->
      Map.from_struct(record)
      |> Map.put_new(:expanded_items, %{})  # initialize new field
      |> then(&struct(SidebarState, &1))
      |> SidebarState.write()
    end)
  end
end
```

---

## Jason.Encoder for Amnesia Tables

Amnesia table structs don't serialize automatically. Implement `Jason.Encoder` inside `defdatabase`:

```elixir
defdatabase MyApp.Database do
  deftable OrdenFirma, [:id, :document_ids, :state, :id_exp], type: :set

  defimpl Jason.Encoder, for: [OrdenFirma] do
    def encode(struct, opts) do
      %{
        "id"           => struct.id,
        "document_ids" => struct.document_ids,
        "state"        => struct.state,
        "id_exp"       => struct.id_exp,
      }
      |> Jason.Encode.map(opts)
    end
  end
end
```

Only include fields that external consumers need. Do not expose internal Mnesia metadata.

---

## Checking Table Existence

```elixir
def table_exists?(table) do
  try do
    :mnesia.table_info(table, :all)
    true
  catch
    :exit, {:aborted, {:no_exists, _}} -> false
    :exit, _ -> false
  end
end
```

Use before adding indexes or running queries on tables that may not exist yet (e.g., during migration from an older schema).

---

## Anti-Patterns

```elixir
# NO — read outside transaction (returns undefined or crashes)
Users.read("leo@dox.cl")

# YES — always wrap in transaction
Amnesia.transaction do
  Users.read("leo@dox.cl")
end

# NO — assume :mnesia.index_read returns structs
orders = :mnesia.index_read(OrdenFirma, state, :state)
orders |> Enum.map(& &1.id)  # crashes — tuples don't have .id

# YES — convert tuples to structs first
orders = :mnesia.index_read(OrdenFirma, state, :state)
         |> Enum.map(&order_tuple_to_struct/1)

# NO — add index before table exists
:mnesia.add_table_index(NewTable, :field)  # aborts

# YES — wait for table first
:mnesia.wait_for_tables([NewTable], 5000)
:mnesia.add_table_index(NewTable, :field)
```
