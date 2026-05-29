# Story 009: Skin / weight paint + deform QA gate

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: L (~1-1.5 days)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §5` (skinning / weight-paint plan + deformation gate)
**Why**: Auto-weights get the mesh moving (proven in the test rig), but production needs clean,
hand-corrected weights so deformation holds under extreme poses. This is the quality gate that
gates everything downstream — bad weights = broken animation.

**Engine**: Blender 4.x/5.1 | **Risk**: HIGH (deformation quality is the make-or-break)

---

## Acceptance Criteria

- [ ] Body LOD0 skinned to `arm_pudge` per §5 per-region strategy (max influences, smoothing)
- [ ] Hook prop 100%-weighted to `LeftHand` (per §7 / §5)
- [ ] BellyJiggle / ChainLink influences assigned per §4 + §5
- [ ] **Passes all 4 extreme QA poses (§5 Deformation Gate):** QA1 Raised Hook Arm, QA3 Squat Waddle Extreme, QA4 Death Sprawl, + the 4th §5 pose — no pinching, no triangle collapse, no belly clip-through
- [ ] No vertex with stray micro-weights to wrong bones (clean weight islands)

---

## Implementation Notes

Follow §5 per-region strategy. The shoulder 4-loop cap (Story 002) is critical for QA1 — the
raised hook arm is the permanent idle pose. Belly must never clip through under QA4 death sprawl
(BellyJiggle at max squash). Use weight smoothing sparingly near deform boundaries.

---

## Out of Scope

- Authoring the actual clips → Stories 011-014. Engine IK → Story 019.

---

## QA Test Cases

- **AC-4 (deformation gate — the core test)**:
  - Setup: pose `arm_pudge` into each of the 4 §5 QA poses in turn
  - Verify: QA1 shoulder cap (no pinch/collapse); QA3 hip+knee at waddle extreme, soles at Y=0; QA4 full-body sprawl, BellyJiggle squash, nothing clips through belly
  - Pass condition: all 4 poses deform cleanly; rigger sign-off recorded
- **AC-2 (hook weight)**:
  - Setup: rotate LeftHand
  - Verify: hook moves rigidly with the hand
  - Pass condition: hook 100% follows LeftHand, no lag/stretch

---

## Test Evidence

**Story Type**: Visual/Feel (HIGH-risk gate)
**Required evidence**: `production/qa/evidence/pudge-deform-qa-evidence.md` — all 4 QA-pose screenshots + explicit rigger sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 007, 008 (and 003 for the hook)
- Unlocks: Stories 011-014 (animation cannot start on bad weights)
