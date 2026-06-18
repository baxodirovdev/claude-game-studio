# Godot Import — Acceptable Warnings List

> **Status**: Versioned stub — bootstrapped 2026-06-18 (initially empty).
> **Purpose**: Breaks the circular dependency in the Pudge model spec §11 F.2 gate.
> The list **pre-exists**; F.2 *populates* it, it is not created by F.2.

This file is the allow-list of Godot Output-panel **warning** types that are accepted
(non-blocking) when importing project assets. It is referenced by the model-spec import
gates (e.g. `design/gdd/models/pudge.md` §11 F.2).

## How this list works

1. Godot import **ERROR** rows are **never** acceptable — they always block the gate.
2. **WARNING** rows are reviewed against the table below:
   - If the warning type is already listed → accepted, gate may pass.
   - If the warning type is **not** listed → the gate is **blocked** until a
     `technical-artist` reviews it and either fixes the asset or signs off on adding the
     warning type to this list (with a justification).
3. Adding a row requires: the warning text/pattern, why it is harmless, and the
   reviewer's sign-off.

## Accepted warning types

_None yet._ This list is intentionally empty at bootstrap. The first real entries are
expected during Pudge Stage 10 (`pudge.glb` / `pudge_hook.glb` first import).

| Warning pattern | Asset(s) | Why harmless | Approved by | Date |
|---|---|---|---|---|
| _(none)_ | — | — | — | — |

## Change log

- **2026-06-18** — File bootstrapped as empty versioned stub (resolves model-spec F.2
  circular dependency). No accepted warnings yet.
