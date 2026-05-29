# Story 014: Terminal clips (death, victory)

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: M (~1 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §8` — Clip 9 `death` (45f, no loop), Clip 10 `victory` (60f, loop)
**Why**: Match-end states. `death` is the highest-entropy full-body pose (the §5 QA4 gate exists
for exactly this); `victory` loops on the post-match screen.

**Engine**: Blender 4.x/5.1 | **Risk**: MEDIUM

---

## Acceptance Criteria

- [ ] `death` — 45 frames, no loop, full-body sprawl per §8 Clip 9; BellyJiggle squash, nothing clips through belly (ties to §5 QA4)
- [ ] `victory` — 60 frames, loop, per §8 Clip 10
- [ ] Death beat frames identifiable for markers: `death_begin`, `death_thud`, `death_deflate_start` (Story 015)
- [ ] Victory beat frames identifiable: `victory_arm_peak`, `victory_laugh_sound` (Story 015)
- [ ] `death` settles to a stable final frame (body at rest on ground)

---

## Implementation Notes

Follow §8 Clip 9/10. Death uses the QA4 sprawl as its extreme — verify against the Story 009
gate that the belly never clips at the deflate. Victory loops cleanly for the post-match screen.

---

## Out of Scope

- Event markers / sounds wiring → Story 015. Ragdoll → not in this epic.

---

## QA Test Cases

- **AC-1 (death)**:
  - Setup: play `death` once
  - Verify: believable fall+sprawl, belly squash, no clip-through, rests on final frame
  - Pass condition: matches §8 Clip 9; QA4 deformation holds
- **AC-2 (victory loop)**:
  - Setup: loop `victory`
  - Verify: seamless loop
  - Pass condition: no pop; beats land per §8

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-terminal-clips-evidence.md` — playback captures + beat-frame notes + sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 009 (esp. QA4 deform gate)
- Unlocks: Story 015, 018
