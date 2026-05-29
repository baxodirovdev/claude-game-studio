# Story 012: Hook clips (hook_throw, hook_recover)

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M (~1 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §8` — Clip 5 `hook_throw`, Clip 6 `hook_recover`
**Why**: Pudge's signature ability animations. The hook release frame must align with the
gameplay hook spawn, and the chain helper bones (ChainLink1-4) drive the chain motion.

**Engine**: Blender 4.x/5.1 | **Risk**: MEDIUM (gameplay-timing-critical)

---

## Acceptance Criteria

- [ ] `hook_throw` authored per §8 Clip 5 (wind-up → release → follow-through)
- [ ] `hook_recover` authored per §8 Clip 6
- [ ] Hook prop + ChainLink bones animate coherently with the throw arc
- [ ] Release frame is identifiable for the `hook_release` event marker (Story 015)
- [ ] Non-looping; clean entry/exit from `idle`

---

## Implementation Notes

Follow §8 Clip 5/6 frame breakdown. The release pose drives `socket_chain_origin` as the VFX
chain anchor fallback (§7). Coordinate the exact release frame with the gameplay-programmer —
it must match the projectile spawn timing. ChainLink simulation should read as weight/whip.

---

## Out of Scope

- The `hook_release` event marker itself → Story 015. Gameplay projectile logic → not in this epic.

---

## QA Test Cases

- **AC-1/4 (throw + release frame)**:
  - Setup: play `hook_throw` frame-by-frame
  - Verify: clear wind-up, a single unambiguous release frame, follow-through
  - Pass condition: release frame documented for Story 015; chain whips believably
- **AC-2 (recover)**:
  - Setup: play `hook_recover` after throw
  - Verify: returns to idle-compatible pose
  - Pass condition: no pop transitioning back to `idle`

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-hook-clips-evidence.md` — playback captures + release-frame note + sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 009 (weights), Story 003 (hook), Story 008 (ChainLink bones)
- Unlocks: Story 015, 018
