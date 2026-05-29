# Story 008: Helper bones (BellyJiggle, Jaw, ChainLink1-4)

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: M (~0.5 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §4` (helper bones: §4.1 BellyJiggle, §4.2 Jaw, §4.3 ChainLink1-4)
**Why**: Secondary motion and detail. BellyJiggle drives belly squash/sway, Jaw for taunt/death,
ChainLink1-4 simulate the hook chain. Brings the rig to the spec's 27-bone total.

**Engine**: Blender 4.x/5.1 | **Risk**: MEDIUM

---

## Acceptance Criteria

- [ ] `BellyJiggle` (child of Spine1) added per §4.1
- [ ] `Jaw` (child of Head) added per §4.2
- [ ] `ChainLink1`→`ChainLink4` chained under `LeftHand` per §4.3
- [ ] Total bone count = 27 (22 humanoid + 5 helpers) per §1 Bone Count Summary
- [ ] Helper bone behaviors/constraints set per §4 (jiggle/sim notes)

---

## Implementation Notes

Follow §4 for each helper's placement and intended motion. BellyJiggle must reach the −0.12 m
squash offset used in the §5 QA4 death pose. ChainLink chain hangs from LeftHand; it is
weighted to the chain geometry, not the body. Jaw stays closed at rest (bind angle 0).

---

## Out of Scope

- Weighting mesh to these bones → Story 009. Authoring jiggle/chain motion in clips → Stories 011-014.

---

## QA Test Cases

- **AC-4 (count)**:
  - Setup: bone count on `arm_pudge`
  - Verify: 27 total
  - Pass condition: matches §1 (humanoid 22 + helper 5)
- **AC-1/2/3 (placement)**:
  - Setup: inspect BellyJiggle/Jaw/ChainLink positions and parents
  - Verify: parented and placed per §4
  - Pass condition: chain hangs from LeftHand; BellyJiggle anchored at belly mass

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-helper-bones-evidence.md` — screenshots + sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 007
- Unlocks: Story 009
