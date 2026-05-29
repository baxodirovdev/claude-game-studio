# Story 004: UV unwrap body + hook

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: M (~0.5 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/models/pudge_retopo_bake_plan.md §E` (UV plan) + texture spec `design/gdd/materials/pudge.md`
**Why**: Bake targets and the final material need clean, non-overlapping UVs at the spec's
texel density. Body atlas 1024×1024 (`mat_pudge_body`), hook atlas 512×512 (`mat_pudge_hook`).

**Engine**: Blender 4.x/5.1 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Body LOD0 unwrapped into the 1024² atlas (`mat_pudge_body`) per §E
- [ ] Hook LOD0 unwrapped into the 512² atlas (`mat_pudge_hook`) per §E
- [ ] No overlapping UV islands (except intentional mirrored shells if specified)
- [ ] Texel density consistent and matching the texture spec target
- [ ] Seams hidden in low-visibility areas; deformation zones not split across seams where avoidable

---

## Implementation Notes

Follow §E island/seam layout. Keep face seams off high-stretch deform areas (shoulder, jaw).
UVs must be final before baking (Story 005) — re-unwrapping after a bake invalidates the maps.

---

## Out of Scope

- Baking maps into these UVs → Story 005.

---

## QA Test Cases

- **AC-3 (overlap)**:
  - Setup: UV Editor → Overlap display / Select Overlap
  - Verify: no unintended overlapping islands
  - Pass condition: overlap selection empty
- **AC-4 (texel density)**:
  - Setup: apply a checker texture at atlas resolution
  - Verify: checker squares roughly uniform across body; hook proportional
  - Pass condition: density within spec tolerance, no severe stretching

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-uv-evidence.md` — UV layout + checker screenshots + sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 002, 003
- Unlocks: Story 005
