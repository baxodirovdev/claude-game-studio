# Story 003: Model hook prop LOD0

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: M (~0.5 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/models/pudge_retopo_bake_plan.md §C` (hook separation strategy)
**Why**: The hook is fused into the AI mesh. The spec calls for a fresh-modeled, separate
hook prop (`mesh_pudge_hook_lod0`, ~600 tris) so it can be 100%-weighted to `LeftHand` and
attached via `socket_hook_hand`. The fused hook on the source is masked out during the body bake.

**Engine**: Blender 4.x/5.1 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Fresh hook mesh modeled per concept (Silhouette B), ~600 tris
- [ ] Object `mesh_pudge_hook_lod0`, data `mesh_data_pudge_hook_lod0`, in `EXPORT_HOOK` collection
- [ ] Origin at the handle grip point (matches `socket_hook_hand` per rig §7)
- [ ] Manifold, clean normals, scaled to match the 1.4 m character
- [ ] The fused hook region on the bake source is masked (per §C "masking the fused hook")

---

## Implementation Notes

Follow §C "Fresh hook modeling procedure". The grip origin must align with rig §7
`socket_hook_hand` (5 cm forward along LeftHand −Z). Keep it a distinct object — it ships as
`pudge_hook.glb` per the loader's `HERO_HOOK_GLB_PATH`, or as a child node in the main GLB
(decide at export, Story 016).

---

## Out of Scope

- Hook LOD1/2 → Story 006. Weighting the hook to LeftHand → Story 009. Socket attach → Story 017.

---

## QA Test Cases

- **AC-1/4**:
  - Setup: isolate `mesh_pudge_hook_lod0`, Statistics overlay
  - Verify: ~600 tris, manifold, scale consistent with body
  - Pass condition: within budget, non-manifold selection empty, reads as the concept hook
- **AC-3 (origin)**:
  - Setup: snap 3D cursor to object origin
  - Verify: origin sits at the handle grip point
  - Pass condition: matches rig §7 socket position within ~1 cm

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-hook-lod0-evidence.md` — screenshots + sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Stories 004, 006, 009
