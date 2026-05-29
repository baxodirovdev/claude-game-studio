# Story 002: Finalize body retopo LOD0

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: L (~1 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/models/pudge_retopo_bake_plan.md §D` (retopology approach)
**Why**: `mesh_pudge_body_lod0` exists (~5.5k verts / ~11k tris) but is unfinished — it
carries an inert Shrinkwrap modifier (its target high-poly was the bake source) and lacks
finalized edge flow at deformation zones. The 37k textured AI mesh has 599 loose parts and
cannot be animated; the retopo is the mesh that gets rigged.

**Engine**: Blender 4.x/5.1 | **Risk**: MEDIUM (AI-mesh topology artifacts)
**Engine Notes**: Work in `anime_pudge.blend` (per pipeline §1) until bake completes.

---

## Acceptance Criteria

- [ ] Apply/finalize Shrinkwrap so LOD0 conforms to `textured_mesh_bake_hp`, then remove the live modifier
- [ ] Clean edge loops at all deformation zones: shoulders (4-loop cap per rig §5), elbows, hips, knees, jaw, and the belly mass
- [ ] Body LOD0 within tri budget (~5,500 body tris per pipeline §1)
- [ ] Manifold, no n-gons in deform zones, consistent normals/winding
- [ ] Mesh data-block named `mesh_data_pudge_body_lod0`, object `mesh_pudge_body_lod0`, in `EXPORT_BODY` collection (pipeline §2)

---

## Implementation Notes

Follow retopo plan §D (Snap-to-Surface + Shrinkwrap method) and §D "Expected AI-mesh topology
problems". The shoulder must have the 4-loop topology the rig spec §5 QA1 pose depends on
(raised hook arm is the permanent idle position — highest-risk deform zone).

---

## Out of Scope

- The hook prop → Story 003. UVs → Story 004. Baking → Story 005. LOD1/2 → Story 006.

---

## QA Test Cases

- **AC-2 (deform-zone edge flow)**:
  - Setup: open `anime_pudge.blend`, isolate `mesh_pudge_body_lod0`, wireframe view
  - Verify: continuous edge loops around shoulder/elbow/hip/knee/jaw; belly has radial loops
  - Pass condition: no triangle fans or poles inside deformation bands; shoulder cap = 4 loops
- **AC-3/4 (budget + manifold)**:
  - Setup: Statistics overlay + Select → All by Trait → Non-Manifold
  - Verify: tri count ≈ 5,500; non-manifold selection empty
  - Pass condition: within budget, zero non-manifold edges

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-retopo-lod0-evidence.md` — wireframe + stats screenshots + lead sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (high-poly bake source present on disk)
- Unlocks: Stories 004, 006, 007
