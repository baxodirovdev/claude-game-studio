# Story 013: Combat / reaction clips (attack_basic, hit_react)

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M (~1 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §8` — Clip 7 `attack_basic`, Clip 8 `hit_react`
**Why**: Core combat feedback — the basic attack swing and the flinch when taking damage.

**Engine**: Blender 4.x/5.1 | **Risk**: MEDIUM

---

## Acceptance Criteria

- [ ] `attack_basic` authored per §8 Clip 7 (anticipation → contact → recovery)
- [ ] `hit_react` authored per §8 Clip 8 (short, interrupt-friendly flinch)
- [ ] Attack contact frame identifiable for an event marker (Story 015)
- [ ] `hit_react` is short enough to interrupt locomotion without feeling laggy
- [ ] Both blend cleanly from/to `idle` and `walk`

---

## Implementation Notes

Follow §8 Clip 7/8. `hit_react` must be interruptible (additive/upper-body bias is preferable if
the spec allows) so movement isn't fully locked on every hit. Keep the attack's contact pose
readable for the cleaver/hook silhouette.

---

## Out of Scope

- Hit/attack event markers → Story 015. Damage logic → not in this epic.

---

## QA Test Cases

- **AC-1/3 (attack)**:
  - Setup: play `attack_basic`
  - Verify: clear anticipation, single contact frame, recovery
  - Pass condition: contact frame documented; reads as a heavy melee hit
- **AC-2/4 (hit_react)**:
  - Setup: trigger `hit_react` during `walk`
  - Verify: brief flinch, returns to locomotion
  - Pass condition: feels responsive, no long lock; clean blends

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-combat-clips-evidence.md` — playback captures + contact-frame note + sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 009
- Unlocks: Story 015, 018
