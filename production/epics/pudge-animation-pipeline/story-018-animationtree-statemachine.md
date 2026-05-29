# Story 018: AnimationTree (StateMachine + walk/run BlendSpace1D)

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L (~1 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §8` (playback rates / blendspace) + Animation Clip Summary Table
**Why**: Drive the 10 clips at runtime — a state machine for discrete states (idle/attack/hook/hit/death/victory)
and a BlendSpace1D blending walk↔run by character velocity (no root motion; playback rate scales with speed).

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: AnimationTree / AnimationNodeStateMachine / BlendSpace1D APIs are post-LLM-cutoff —
verify against `docs/engine-reference/godot/` before implementing.

---

## Acceptance Criteria

- [ ] `AnimationTree` over the imported AnimationLibrary, with an `AnimationNodeStateMachine`
- [ ] States for idle, attack_basic, hook_throw→hook_recover, hit_react, death, victory with transitions per §8
- [ ] `BlendSpace1D` blends walk↔run; playback rate scales with velocity (canonical walk=8 m/s, run=14 m/s per §8 playback table)
- [ ] `hit_react` can interrupt locomotion; `death` is one-shot and holds the final pose; loops set per §8
- [ ] Transitions are pop-free at typical speeds

---

## Implementation Notes

Follow §8 "Playback rate" notes — the BlendSpace1D scales playback proportionally since clips are
authored in-place. Map gameplay state (moving speed, casting, hit, dead) to state-machine travel
calls. Confirm clip names resolve against the library names from Story 015/016.

---

## Out of Scope

- Engine-side IK (foot/look) → Story 019. Gameplay state source → outside this epic (consume existing signals).

---

## QA Test Cases

- **AC-3 (walk/run blend)**:
  - Given: AnimationTree active
  - When: vary character velocity 0→14 m/s
  - Then: idle→walk→run blends smoothly, playback rate scales with speed
  - Edge cases: instant stop (snap to idle), max speed (run at rate 1.0)
- **AC-4 (interrupts + one-shots)**:
  - Given: walking
  - When: trigger hit_react, then death
  - Then: hit_react interrupts and returns; death plays once and holds
  - Edge cases: death must not loop or be interruptible

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/hero/pudge_animtree_test.gd` (state transitions) + in-engine capture in `production/qa/evidence/`.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 011-015, 016, 017
- Unlocks: Story 019
