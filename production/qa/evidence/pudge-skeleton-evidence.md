# Story-007 — arm_pudge Skeleton + A-pose Bind — Test Evidence

> **Story**: `production/epics/pudge-animation-pipeline/story-007-build-arm-pudge-skeleton.md`
> **Type**: Visual/Feel (ADVISORY gate — screenshot + lead sign-off)
> **Spec**: `design/gdd/rigs/pudge.md` §1 (hierarchy), §2 (bind pose), §3 (QA checklist)
> **Built**: 2026-05-29 | **Author**: rigging (Claude)
> **Build script**: `tools/blender/heroes/build_pudge_skeleton.py` (deterministic, re-runnable)
> **Target file**: `src/assets/models/heroes/anime_pudge.blend` → collection `EXPORT_ARMATURE` → `arm_pudge`

---

## Summary

A 20-bone humanoid skeleton (`arm_pudge` / data `arm_data_pudge`) was built in a clean,
symmetric **canonical A-pose**, fitted to the mesh's measured proportions (1.40 m height,
feet plane Z=0). Rest pose == bind pose == A-pose (no pose-mode rotations), the clean
convention for glTF export. Blender Z-up, character faces −Y, Left = +X → maps to Godot
forward −Z / up +Y / feet Y=0 on glTF "+Y up" export per rig spec §2.

The build was authored against `mesh_pudge_body_lod0` (the EXPORT_BODY placeholder). See
**Deviations** — the clean retopo'd A-pose mesh the playbook expects does not exist yet, so
the skeleton is canonical-by-proportion rather than fitted to the placeholder's (asymmetric,
fused) limbs. This was an explicit, approved decision.

---

## Evidence Images

| View | File |
|---|---|
| Front orthographic (bind pose, body as wireframe) | `pudge-skeleton-front.png` |
| Right-side orthographic (bind pose, body as wireframe) | `pudge-skeleton-side.png` |

Both show the white octahedral bones nested inside the orange body wireframe: centered
spine chain, A-pose arms (down + out), legs reaching the Z=0 plane, head bone into the skull
dome. Spine/hips/legs/head align with the mesh core; the placeholder's fused asymmetric arms
intentionally do not match the canonical A-pose arms.

---

## §3 Bind Pose QA Checklist

| # | Check | Result | Note |
|---|---|---|---|
| 1 | Boot sole vertices touch Y=0.0 (no gap/penetration) | **PASS** | `mesh_pudge_body_lod0` Z-bbox = −0.0004 … 1.3995 (Blender Z=0 → Godot Y=0) |
| 2 | Mesh/armature root origin at (0,0,0) | **PASS** | `arm_pudge` location (0,0,0) |
| 3 | All objects scale (1,1,1), transforms applied | **PASS** | armature + `mesh_pudge_body_lod0` scale (1,1,1), rot (0,0,0) |
| 4 | Forward face of belly faces −Z (Godot) | **PASS** | mesh faces −Y in Blender → −Z Godot. (Hook-side is a *mesh* property; placeholder has hook on −X; canonical skeleton uses Left=+X per spec — real retopo will carry the hook on the left arm.) |
| 5 | LeftHand bone tip at palm center of left fist | **DEFERRED** | Cannot verify against the placeholder (its left fist is in a non-A-pose). Re-fit + verify when the real retopo A-pose mesh is delivered. |
| 6 | Hips is the only root-level bone | **PASS** | `roots == ['Hips']` |
| 7 | BellyJiggle lies along +Z of Spine1 parent | **N/A** | BellyJiggle is a **helper → Story-008**; out of scope for 007 |

**Verdict: PASS for in-scope items.** Items 5 (palm-center) and 7 (BellyJiggle) are
correctly out of reach for this story given the placeholder mesh and the 007/008 split.

---

## Bone Hierarchy (verified — 20 bones, single root, all PascalCase)

```
Hips
├── Spine
│   └── Spine1
│       └── Chest
│           ├── Neck
│           │   └── Head
│           ├── LeftShoulder → LeftArm → LeftForeArm → LeftHand
│           └── RightShoulder → RightArm → RightForeArm → RightHand
├── LeftUpLeg → LeftLeg → LeftFoot
└── RightUpLeg → RightLeg → RightFoot
```

Automated verification (build script + check pass): bone_count 20, roots `['Hips']`,
parent map matches spec §1, no missing/extra bones, every name matches `^([A-Z][a-z0-9]*)+$`,
Left/Right symmetric (LeftHand X +0.390 vs RightHand X −0.390).

---

## Deviations from Spec (require lead awareness)

1. **Bone count: 20, not the "22" in spec §1 summary.** The §1 summary line is an
   arithmetic error — its own authoritative §13 bone-type table tags `Jaw`, `BellyJiggle`,
   and `ChainLink1–4` as **Helper**, and the §1 hierarchy diagram marks them `[helper]`.
   The standard humanoid set is therefore **20** bones. `Jaw` is a helper and belongs to
   **Story-008** (which 007 explicitly defers), so building it now would be scope creep.
   *Recommended: correct the spec §1 summary to "20 humanoid + 6 helper = 26 total"
   (the §1 tree and §13 table both enumerate 26, not the summary's 27).*

2. **Built against the placeholder, not a clean retopo.** The only available mesh
   (`mesh_pudge_body_lod0`) is the fused remesh placeholder (asset record: "to be REPLACED
   by manual retopo, not used as final geometry") and is in an asymmetric non-A-pose. The
   clean retopo deliverable (separated arms, hook as its own object, `jiggle_boundary`
   vertex color) does not exist yet. Per approved decision, the skeleton is canonical
   A-pose fitted to *proportions*. **When the real retopo arrives, re-fit bone Y-positions
   to the actual mesh** (playbook §1) and complete QA check #5.

3. **A-pose arm angle.** Spec §2 says "≈30° down from horizontal," but with the hand-height
   target (Z≈0.38) and chibi-short arms this is geometrically inconsistent; the build uses
   ~30° from *vertical* (the classic A-pose), placing the wrist at Z≈0.41. Angles are design
   intent per playbook §1 and re-fit on the final mesh.

---

## Reproduce

```
blender --background src/assets/models/heroes/anime_pudge.blend \
        --python tools/blender/heroes/build_pudge_skeleton.py
```

---

## Godot Round-Trip Verification (2026-05-29)

Godot is **not installed** on this machine (no binary on PATH, `/usr/bin`, `/opt`, flatpak,
snap, or home — though `src/project.godot` exists). So the round-trip was validated at the
**glTF-data level** — exactly the data Godot 4.6's importer consumes — rather than via a live
editor import.

- **Export** (throwaway, skinned, `.blend` NOT modified): `tools/blender/heroes/export_pudge_skeleton_test.py`
  → `tools/blender/heroes/pudge_skeleton_test.glb`. Body auto-weighted to `arm_pudge` in
  memory (20 vertex groups) purely so the glTF carries a skin; weight quality is Story-009.
- **Verify**: `tools/blender/heroes/verify_pudge_glb.py` → **13/13 PASS**:

| Check | Result |
|---|---|
| Exactly one skin | PASS |
| 20 skin joints | PASS |
| Exact bone-name set, PascalCase preserved | PASS (no missing/extra) |
| Single skeleton root = Hips | PASS |
| A-pose: LeftHand below shoulder | PASS (Y 0.411 < 0.740) |
| A-pose: hands outside shoulders | PASS |
| L/R symmetric (hand X mirrored) | PASS (±0.390) |
| Feet near ground (Y < 0.12) | PASS (Y 0.050) |
| Head above hips (upright) | PASS |
| Height axis is +Y (Z-up→Y-up conversion) | PASS (Y 1.397 m) |
| Total height ~1.4 m | PASS (1.397) |
| Feet plane at Y≈0 | PASS (min Y 0.0002) |
| Skinned mesh (JOINTS_0/WEIGHTS_0) present | PASS |

**Conclusion:** the bind pose, bone names, hierarchy, and orientation survive the glTF
"+Y up" export correctly. Godot will produce a `Skeleton3D` with 20 A-pose bones at the
right scale/orientation. Final visual confirmation pending a live editor import (open
`src/project.godot`, drag in `pudge_skeleton_test.glb`) when Godot is available.

---

## Sign-off

- [ ] Rigging lead review (Visual/Feel ADVISORY gate)
- [ ] Re-fit + QA #5 after clean retopo mesh is delivered
- [ ] Live Godot editor import check (Godot not installed at build time; verified via glTF data)
