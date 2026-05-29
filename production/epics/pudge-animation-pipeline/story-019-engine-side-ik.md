# Story 019: Engine-side IK (Godot SkeletonModifier3D)

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M (~0.5-1 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §6` (IK chain setup — "FK skeleton in Blender, IK added engine-side in Godot")
**Why**: The rig is authored FK; IK is applied in Godot per §6 (4 IK chains). Keeps animation
data portable and lets feet/aim adapt at runtime.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: §6 "Godot 4.6 IK Modifier Confirmation" — Godot 4.6 restored IK; verify the
`SkeletonModifier3D` / IK modifier API against `docs/engine-reference/godot/` before implementing.

---

## Acceptance Criteria

- [ ] The 4 IK chains from §6 set up as Godot skeleton modifiers (per §6 "IK Chains — 4 Total")
- [ ] IK applied AFTER the AnimationTree in the modifier stack (pose → IK correction)
- [ ] Foot IK keeps boot soles grounded on uneven contact without breaking the walk/run waddle
- [ ] IK can be toggled/blended off for death/victory where full-body authored pose should win
- [ ] No jitter or popping when IK engages/disengages

---

## Implementation Notes

Follow §6 strategy (FK authored, IK engine-side) and §6 "Godot 4.6 IK Modifier Confirmation".
Order matters: the IK `SkeletonModifier3D` must run after the AnimationTree writes the FK pose.
Disable foot IK during `death`/`victory` so the authored sprawl/celebration is preserved.

---

## Out of Scope

- Authoring the FK clips (done in 011-014). Terrain/contact queries feeding IK targets — wire to existing systems, do not build new ones here.

---

## QA Test Cases

- **AC-3 (foot grounding)**:
  - Given: Pudge walking on a stepped/sloped surface
  - When: feet contact different heights
  - Then: soles stay planted, no floating/penetration
  - Edge cases: steep slope (clamp), instant height change (no snap-pop)
- **AC-4/5 (toggle + stability)**:
  - Given: death triggered
  - When: IK disengages
  - Then: authored sprawl plays without IK fighting it; no jitter on toggle
  - Pass condition: clean engage/disengage at all tested speeds

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/hero/pudge_ik_test.gd` (grounding/toggle) + in-engine capture on uneven terrain in `production/qa/evidence/`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 018 (IK runs after the AnimationTree pose)
- Unlocks: None (final story — epic complete when this passes)
