# Story 007: Build arm_pudge skeleton + A-pose bind

> **Epic**: Pudge Animation Pipeline
> **Status**: In Review — implemented, pending lead sign-off + re-fit on final retopo
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: M (~0.5 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: 2026-05-29

## Context

**Spec**: `design/gdd/rigs/pudge.md §1` (skeleton hierarchy) + `§2` (bind pose)
**Why**: The mesh needs a skeleton before it can deform. The 22 standard humanoid bones form
the core; helper bones come in Story 008.

**Engine**: Blender 4.x/5.1 | **Risk**: MEDIUM
**Engine Notes**: PascalCase bone names are mandatory for Godot humanoid retargeting (§1 note).
A throwaway test (2026-05-29) already confirmed the LOD0 auto-weights cleanly.

---

## Acceptance Criteria

- [x] Armature object `arm_pudge`, data `arm_data_pudge`, in `EXPORT_ARMATURE` collection
- [x] All humanoid bones present with exact §1 hierarchy and PascalCase names —
  **20 bones** (spec §1's "22" is a miscount; its own §13 table tags Jaw/BellyJiggle/ChainLink
  as helpers → 20 humanoid). See evidence deviation #1.
- [x] Bind pose = A-pose per §2 (NOT the Silhouette B raised-arm rest); angles per §2 (intent;
  re-fit on final mesh — see evidence deviation #3)
- [x] Global orientation: forward −Z, up +Y, feet plane Y=0 (Godot space), root at world origin
  (Blender −Y fwd / +Z up / Z=0 feet → Godot on glTF "+Y up" export)
- [~] Passes the §3 Bind Pose QA Checklist — PASS for in-scope items; check #5 (LeftHand at
  palm center) DEFERRED to the real retopo mesh, check #7 (BellyJiggle) is Story-008. See evidence.

**Evidence**: `production/qa/evidence/pudge-skeleton-evidence.md` (front + side renders, QA table, hierarchy)

---

## Implementation Notes

Create bones head→tail per §2 "Key Bone Positions". Apply the §2 joint angles (slight hunch:
Spine/Spine1/Chest +5° each ≈ 15° lean). Bind pose is A-pose; the raised hook arm is driven by
the `idle` clip later. Leave skinning to Story 009.

---

## Out of Scope

- Helper bones → Story 008. Weight painting → Story 009. Sockets → Story 010.

---

## QA Test Cases

- **AC-2 (hierarchy)**:
  - Setup: expand `arm_pudge` in the Outliner
  - Verify: 22 bones, parenting exactly per §1 tree, names PascalCase
  - Pass condition: matches §1 + Bone Count Summary (humanoid subtotal 22)
- **AC-3/4 (bind pose)**:
  - Setup: rest pose view, front + side
  - Verify: A-pose, ~15° forward hunch, feet at Y=0, root at origin
  - Pass condition: passes every item in §3 QA Checklist

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-skeleton-evidence.md` — Outliner + bind-pose screenshots + sign-off.
**Status**: [x] Created — front + side bind-pose renders, §3 QA table, verified hierarchy dump, deviations log. Pending lead sign-off.

---

## Dependencies

- Depends on: Story 002 (mesh to fit the rig to)
- Unlocks: Stories 008, 009, 010
