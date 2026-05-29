# Story 015: Animation events + library export naming

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M (~0.5 day)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §8` (Animation Clip Summary Table) + `§9` (Animation Library Export Plan)
**Why**: Gameplay/audio hooks fire on animation events (footsteps, hook release, death beats).
The clips must also carry the exact canonical names so Godot's imported AnimationLibrary matches
what `AnimationTree` (Story 018) and gameplay code expect.

**Engine**: Blender 4.x/5.1 → Godot 4.6 | **Risk**: MEDIUM

---

## Acceptance Criteria

- [ ] Every clip's NLA/action name matches the §9 "Clip Names — Exact Strings" exactly
- [ ] Event markers placed at the §8 summary-table frames: walk `footstep_left F0`/`footstep_right F12`, run `F0`/`F9`, death `death_begin F8`/`death_thud F23`/`death_deflate_start F38`, victory `victory_arm_peak F15`/`victory_laugh_sound F20`, hook release, attack contact
- [ ] Loop flags correct per §8 (idle/walk/run/turn/victory loop; hook/attack/hit/death no loop)
- [ ] Markers carried through the §9 Blender export workflow (verify they survive glTF)

---

## Implementation Notes

Godot reads glTF animations into an AnimationLibrary; the importer can map markers to
`AnimationPlayer` call/method tracks or named time markers. Follow §9 "Blender Export Workflow"
for how markers/clip names must be set so they survive export. Coordinate the hook-release and
attack-contact frames with Stories 012/013's documented frames.

---

## Out of Scope

- The GLB export itself → Story 016. Consuming the events in gameplay → outside this epic.

---

## QA Test Cases

- **AC-1/3 (names + loop flags)**:
  - Given: all 10 clips authored
  - When: list actions/NLA tracks
  - Then: names == §9 exact strings; loop flags == §8 table
  - Edge cases: case-sensitivity; no trailing spaces in names
- **AC-2 (event frames)**:
  - Given: each clip
  - When: inspect markers
  - Then: markers at the §8 frame numbers
  - Edge cases: markers must survive glTF export (re-check after Story 016)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `production/qa/evidence/pudge-anim-events-evidence.md` — marker/name table vs §8/§9 + post-export verification.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 011, 012, 013, 014 (all clips authored)
- Unlocks: Story 016, 018
