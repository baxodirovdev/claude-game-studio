# Story 006: Generate body + hook LOD1/LOD2

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Core
> **Type**: Config/Data
> **Estimate**: S (~2h)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/asset-records/pudge_blender_pipeline.md §2` (naming) + §13 (LOD auto-detection)
**Why**: Godot 4.6 auto-detects LODs by the `_lodN` name-suffix convention (`use_name_suffixes`).
Provide decimate-derived LOD1/LOD2 so distant Pudges cost less.

**Engine**: Blender 4.x/5.1 → Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Body: `mesh_pudge_body_lod1` (~3,050 tris), `mesh_pudge_body_lod2` (~1,500 tris)
- [ ] Hook: `mesh_pudge_hook_lod1` (~300 tris), `mesh_pudge_hook_lod2` (~150 tris)
- [ ] LOD1/2 share the LOD0 UVs/material (no re-bake)
- [ ] Object + data-block names follow pipeline §2 (`_lodN` suffix, `mesh_data_*` data names)
- [ ] All LODs in `EXPORT_BODY` / `EXPORT_HOOK` collections

---

## Implementation Notes

Use the Decimate modifier (Collapse) from LOD0, then apply. Preserve UV seams (Decimate keeps
UVs if "Symmetry"/"Keep UV" handled). LOD2 silhouette must still read as Pudge. Suffixes are
mandatory for Godot's `use_name_suffixes` LOD detection (§13).

---

## Out of Scope

- Verifying LOD switching in-engine → Story 017 acceptance.

---

## QA Test Cases

- **AC-1/2 (tri budgets)**:
  - Setup: Statistics overlay per LOD object
  - Verify: tri counts within the spec targets
  - Pass condition: lod1 ≈ 55% of lod0, lod2 ≈ 27%, silhouette intact
- **AC-4 (naming)**:
  - Setup: list object + data-block names
  - Verify: exact `_lodN` suffix + `mesh_data_*` convention
  - Pass condition: matches pipeline §2 table exactly (ASCII only)

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check / screenshot of object list + tri counts in `production/qa/evidence/pudge-lods-evidence.md`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 002, 003 (LOD0 final), benefits from 004 (shared UVs)
- Unlocks: Story 016
