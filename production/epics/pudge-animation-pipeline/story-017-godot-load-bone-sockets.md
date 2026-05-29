# Story 017: Godot load + BoneAttachment3D sockets

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M (~0.5-1 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §7` + `src/gameplay/hero/hero_model_builder.gd`
**Why**: The loader already falls back to `pudge.glb` when present (`HERO_GLB_PATH`). This story
verifies it loads correctly and replaces the pre-rig Marker3D sockets with real `BoneAttachment3D`
nodes on the imported skeleton, attaching the hook and exposing VFX/hit/icon anchors.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Verify `BoneAttachment3D` + Skeleton3D API against `docs/engine-reference/godot/`
(post-cutoff). Bone names must match Story 001's reconciliation.

---

## Acceptance Criteria

- [ ] `HeroModelBuilder.build_model` loads `pudge.glb` for `hero_id == "pudge"` (feet at Y=0, forward −Z, capsule-aligned)
- [ ] 5 `BoneAttachment3D` nodes created on the imported skeleton at the §7 sockets, using the reconciled bone names (Story 001)
- [ ] Hook prop attached at `socket_hook_hand` and follows the hand through animation
- [ ] LODs switch via Godot's auto-detected `_lodN` suffixes
- [ ] Pre-rig Marker3D fallback still works when `pudge.glb` is absent (no regression)

---

## Implementation Notes

Build on the existing GLB-override path in `hero_model_builder.gd`. Replace the Marker3D socket
offsets with `BoneAttachment3D` bound to `bone_name`. Confirm the imported skeleton's bone names
match the reconciled PascalCase set (Story 001) — a mismatch silently fails attachment.

---

## Out of Scope

- AnimationTree state machine → Story 018. IK → Story 019.

---

## QA Test Cases

- **AC-1 (load)**:
  - Given: `pudge.glb` at `res://assets/models/heroes/`
  - When: spawn the Pudge hero
  - Then: GLB model appears, feet on the ground plane, facing −Z
  - Edge cases: remove the GLB → primitive fallback still builds (no crash)
- **AC-2/3 (sockets)**:
  - Given: model loaded, an animation playing
  - When: inspect `BoneAttachment3D` world transforms
  - Then: hook tracks the hand; head_top/hit_center anchors track the skeleton
  - Edge cases: bone-name typo → assert/log, not silent failure

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/hero/pudge_glb_load_test.gd` (load + socket existence) + in-engine screenshot/walkthrough in `production/qa/evidence/`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001, 010, 016
- Unlocks: Story 018, 019
