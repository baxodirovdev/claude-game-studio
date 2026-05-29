# Story 016: Migrate file + export pudge.glb

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Config/Data
> **Estimate**: M (~0.5 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/asset-records/pudge_blender_pipeline.md §1` (file migration) + `§8` (export settings) + `§13` (LOD detection)
**Why**: Consolidate the finished asset into the canonical `.blend`, strip source/bake objects,
and export a Godot-ready GLB with mesh + LODs + skeleton + animation library.

**Engine**: Blender 4.x/5.1 → Godot 4.6 | **Risk**: MEDIUM
**Gate**: `/blender-export-check` must pass clean before hand-off.

---

## Acceptance Criteria

- [ ] Migrate per §1: confirm bakes saved externally, strip `_SOURCE`/`_BAKE` objects, `Save As` `tools/blender/heroes/pudge.blend` (keep `anime_pudge.blend` as archive)
- [ ] Export `pudge.glb` to `res://assets/models/heroes/` with the §8 export settings (forward −Z, +Y up, feet at Y=0, applied transforms, deform bones, animations, `use_name_suffixes` LODs)
- [ ] Hook exported per the loader contract (`pudge_hook.glb` or child node — decide + document)
- [ ] All 10 animation clips present in the GLB's animation library with correct names
- [ ] `/blender-export-check` passes (scale, transforms, normals, UVs, LODs, no empty actions)

---

## Implementation Notes

Follow §1 migration procedure exactly (relinking bakes mid-retopo is error-prone — that's why it
happens now). Use the §8 export settings table verbatim. Confirm `tools/blender/heroes/` exists.
The validation script target is `tools/blender/heroes/pudge.blend` per §1.

---

## Out of Scope

- Loading it in-engine / sockets / AnimationTree → Stories 017-019.

---

## QA Test Cases

- **AC-5 (export-check gate)**:
  - Given: `tools/blender/heroes/pudge.blend`
  - When: run `/blender-export-check`
  - Then: all checks pass (correct scale 1.4 m, transforms applied, normals OK, UVs present, LOD suffixes, no empty armature actions)
  - Edge cases: verify event markers survived export (ties to Story 015)
- **AC-4 (clips present)**:
  - When: inspect the exported GLB
  - Then: 10 named animations present
  - Pass condition: names match §9 exact strings

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: `/blender-export-check` report + `production/qa/smoke-*.md` entry / `production/qa/evidence/pudge-export-evidence.md`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 005, 006, 009, 015
- Unlocks: Stories 017, 018, 019
