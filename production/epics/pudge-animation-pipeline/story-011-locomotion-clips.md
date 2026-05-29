# Story 011: Locomotion clips (idle, walk, run, turn_in_place)

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: L (~1.5 days)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §8` — Clip 1 `idle`, Clip 2 `walk`, Clip 3 `run`, Clip 4 `turn_in_place`
**Why**: The default-state animations every match relies on. `idle` holds the Silhouette B
raised-hook-arm pose; walk/run share a BlendSpace1D (wired in Story 018).

**Engine**: Blender 4.x/5.1 | **Risk**: MEDIUM

---

## Acceptance Criteria

- [ ] `idle` — 60 frames, loop, raised hook-arm pose, belly secondary motion (§8 Clip 1; summary frame counts)
- [ ] `walk` — 24 frames, loop, authored at 8 m/s in-place foot timing, no root motion (§8 Clip 2)
- [ ] `run` — 18 frames, loop, shares walk's BlendSpace1D timing (§8 Clip 3)
- [ ] `turn_in_place` — per §8 Clip 4 spec
- [ ] Feet stay at Y=0 contact frames; soles do not float/sink; waddle stance per §5 QA3 holds

---

## Implementation Notes

Follow §8 per-clip frame breakdowns. No root motion is exported — the AnimationTree (Story 018)
scales walk/run playback by velocity. Keep idle's raised arm consistent with the bind→idle
transition (bind is A-pose; idle drives the raise). Belly + chain helper bones should carry
subtle secondary motion on idle.

---

## Out of Scope

- Footstep event markers → Story 015. BlendSpace1D wiring → Story 018.

---

## QA Test Cases

- **AC-1 (idle)**:
  - Setup: play `idle` looped
  - Verify: raised hook-arm pose, seamless loop, belly/chain sway
  - Pass condition: no pop at loop boundary; matches §8 Clip 1
- **AC-2/3 (walk/run feet)**:
  - Setup: play walk then run
  - Verify: foot contacts lock at Y=0, no sliding beyond authored speed
  - Pass condition: frame counts 24/18, clean loops, no foot float

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/pudge-locomotion-evidence.md` — clip playback captures (per clip) + sign-off.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 009 (clean weights)
- Unlocks: Stories 015, 018
