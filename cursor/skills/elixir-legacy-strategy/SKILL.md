---
name: elixir-legacy-strategy
description: >
  Safety protocol for working with legacy Elixir modules: freeze, document, characterize, then refactor.
  Includes ghost code detection and quarantine workflow.
  Trigger: When a file is identified as legacy, or when asked to refactor a large/undocumented Elixir module.
license: Apache-2.0
metadata:
  author: tsard
  version: "1.0"
---

## Legacy Detection — Trigger Criteria

A module is LEGACY if it meets ANY of these:

| Criterion | Threshold |
|-----------|-----------|
| Size | > 1000 lines (conservative) — see project AGENTS.md for override |
| Missing docs | No `@spec` on public functions OR no `@moduledoc` |
| No test coverage | No corresponding file in `test/` |

> Note: `verification-first` global rule uses 1500 lines as the hard block threshold.
> This skill uses 1000 as the early-warning trigger — start the protocol before you hit the wall.

---

## Legacy Protocol — Mandatory Workflow

When a legacy module is identified: **STOP all refactoring attempts** and follow this sequence.

### Step A — Observational Documentation

Document how it **currently works**, not how it should work.

- Add `@moduledoc` marking the module as `LEGACY`
- Add `@doc` and `@spec` based on actual current types (even if complex or "dirty")
- Do NOT clean up, rename, or improve anything yet

```elixir
@moduledoc """
LEGACY MODULE — Do not refactor without completing the legacy safety protocol.
Current behavior documented as-is. See legacy-strategy skill for workflow.
"""
```

### Step B — Characterization Tests (Safety Net)

Goal: create a regression net, not ideal tests.

- **Snapshot tests**: pass real inputs, verify the output is exactly what the system produces today
- For side effects (DB, external APIs): create mocks that **mimic current behavior**, not ideal behavior
- These tests must PASS before any refactoring begins
- They exist to catch regressions, not to validate correctness

```elixir
# Characterization test pattern
test "legacy behavior — payment calculation for standard lease" do
  # Input taken from production data / existing usage
  input = %{amount: 1000, months: 12, rate: 0.05}
  # Assert current output, whatever it is
  assert LegacyCalc.compute(input) == %{total: 1276.28, monthly: 106.36}
end
```

### Step B.5 — Ghost Code Detection (Optional but recommended)

Run BEFORE refactoring to reduce LOC and clarify what's actually active.

**Ghost code categories** (code that does NOT contribute to current functionality):

| Category | Examples |
|----------|---------|
| Orphaned functions | `defp` functions with no internal callers |
| Commented code zombies | Commented-out blocks (git has history, delete them) |
| Debug pollution | `IO.inspect`, `dbg()`, `Logger.debug("XXX")` in production paths |
| Unused aliases | `alias`/`import` statements not referenced in the file |
| Redundant code | Logic already extracted to another module, duplicated here |
| Deprecated incomplete | `@deprecated` without sunset date or replacement reference |
| Unreachable code | Code after `raise`/`throw`/`exit` in the same branch |

**Ghost detection workflow — quarantine first, never direct delete:**

```
1. AUDIT
   → grep for each category above
   → Build report: category + location + line count

2. QUARANTINE (do NOT delete yet)
   → git stash (backup)
   → Comment out identified blocks with tracking tag: # GHOST-QUARANTINE: [date] [category]
   → run: mix compile && mix test
   → If FAIL → git stash pop (automatic rollback)
   → If PASS → commit quarantine state

3. OBSERVATION PERIOD (6 weeks minimum)
   → Monitor production
   → Track in .ghost-quarantine-log.json at project root

4. PERMANENT DELETION
   → Only after observation period with no issues
   → Remove quarantine comments, delete blocks, run full test suite
```

Typical result: 5–10% LOC reduction per legacy file.

### Step C — Hold State

After Steps A, B, B.5 are complete, emit:

```
⚠️ LEGACY MODULE SECURED

Module: [module name]
Lines: [N]
Actions taken:
  ✓ @moduledoc added (marked LEGACY)
  ✓ @spec/@doc added for all public functions
  ✓ Characterization tests created and passing
  ✓ Ghost detection completed (N ghosts quarantined / none found)

The module is now safe to refactor.
WAITING FOR INSTRUCTIONS TO PROCEED.
```

---

## Non-Intervention Rules (during Steps A–B)

- PROHIBITED: changing business logic
- PROHIBITED: renaming variables or functions
- PROHIBITED: any refactoring of any kind
- ALLOWED: `mix format` only if strictly needed for readability during analysis

---

## Full Workflow Order

```
Identify legacy module
    ↓
Step A: Observational documentation (@moduledoc LEGACY, @spec, @doc)
    ↓
Step B: Characterization tests (snapshot current behavior)
    ↓
Step B.5: Ghost detection + quarantine (optional, recommended)
    ↓
Step C: Hold — report to user, wait for refactor instructions
    ↓
[User approves] → Begin refactoring with safety net in place
```
