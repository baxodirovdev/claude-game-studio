# Story 005: Bake PBR maps

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: L (~1 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/models/pudge_retopo_bake_plan.md §F` (bake plan) + texture spec `design/gdd/materials/pudge.md`
**Why**: Transfer surface detail and color from the high-poly AI source onto the clean retopo:
normal + AO from `textured_mesh_bake_hp`, base color projected from `textured_mesh_source_prep`.
Output to `src/assets/textures/heroes/pudge/` as separate files (not embedded).

**Engine**: Blender 4.x/5.1 | **Risk**: MEDIUM (cage/projection artifacts)
**Engine Notes**: Requires the bake source `textured_mesh_bake_hp` and cage `mesh_pudge_body_cage`.
The high-poly source exists on disk in `anime_pudge.blend` — do not save over the file without it.

---

## Acceptance Criteria

- [ ] Build `mesh_pudge_body_cage` (LOD0 inflated ~2 cm) per §F cage settings
- [ ] Bake normal map (tangent-space), AO, and base color for body → `src/assets/textures/heroes/pudge/`
- [ ] Bake hook maps to its 512² atlas
- [ ] No bake artifacts: no skirts/ray-misses at deform zones, no seam bleeding beyond margin
- [ ] Maps named per model spec §10; saved as external files referenced by the materials

---

## Implementation Notes

Follow §F "Bake scene setup", "Cage settings", "Normal bake quality notes", and
"Base color projection". Use Selected-to-Active with the cage. Verify the masked fused-hook
region (Story 003) does not bleed into the body normal bake.

---

## Out of Scope

- Material wiring in Godot → Story 017. LOD1/2 (share LOD0 textures) → Story 006.

---

## QA Test Cases

- **AC-2/4 (bake quality)**:
  - Setup: assign baked normal+AO+base color to the body material, MATERIAL preview
  - Verify: high-poly detail reads on the retopo; no black skirts, no seam halos
  - Pass condition: clean maps at shoulders/jaw/belly under the QA1 raised-arm pose
- **AC-1 (cage)**:
  - Setup: inspect `mesh_pudge_body_cage`
  - Verify: fully envelops LOD0 with ~2 cm offset, no inversions
  - Pass condition: cage encloses all LOD0 geometry

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-bake-evidence.md` — map thumbnails + shaded screenshots + sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (final UVs)
- Unlocks: Story 016 (export references these textures)
