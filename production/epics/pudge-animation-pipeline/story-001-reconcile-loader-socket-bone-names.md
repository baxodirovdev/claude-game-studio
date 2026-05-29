# Story 001: Reconcile loader socket bone names

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S (~1h)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §7` (sockets) + `src/gameplay/hero/hero_model_builder.gd:28-36`
**Why**: The loader's `HERO_SOCKETS` dict keys bone attachments to **Mixamo** names
(`mixamorig:LeftHand`, `mixamorig:Spine2`, …). The rig is authored with **PascalCase**
Godot-humanoid names (`LeftHand`, `Chest`, `Spine1`, `Head`). If not reconciled, every
`BoneAttachment3D` fails to bind at runtime.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript dictionary edit; no post-cutoff API.

---

## Acceptance Criteria

- [ ] `HERO_SOCKETS` bone names match the rig spec §7 exactly: `socket_hook_hand`→`LeftHand`, `socket_offhand`→`RightHand`, `socket_chain_origin`→`Chest`, `socket_hit_center`→`Spine1`, `socket_head_top`→`Head`
- [ ] No remaining `mixamorig:` references in `hero_model_builder.gd`
- [ ] Fallback Marker3D positions (pre-rig path) left unchanged
- [ ] Code comments referencing "Mixamo standard skeleton" updated to the studio rig

---

## Implementation Notes

Per rig §7, the chain origin moved from `Spine2` (Mixamo) to `Chest`, and hit center from
`Spine1`. Update the `bone` field on each entry; keep the `position` Vector3 fallbacks for
the pre-rig primitive path (used when `pudge.glb` is absent). This story is safe to do now —
it has no dependency on the asset work.

---

## Out of Scope

- Actually attaching `BoneAttachment3D` nodes at runtime → Story 017.

---

## QA Test Cases

- **AC-1/2**: bone-name correctness
  - Given: `hero_model_builder.gd` loaded
  - When: grep for `mixamorig:`
  - Then: zero matches; each socket `bone` equals the rig §7 PascalCase name
  - Edge cases: confirm no typo'd bone names (case-sensitive in Godot Skeleton3D)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/hero/loader_socket_bones_test.gd` OR a documented manual diff against rig §7.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 017 (socket wiring relies on correct bone names)
