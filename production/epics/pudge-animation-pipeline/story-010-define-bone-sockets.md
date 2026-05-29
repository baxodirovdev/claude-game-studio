# Story 010: Define 5 bone sockets

> **Epic**: Pudge Animation Pipeline
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: S (~2h)
> **Manifest Version**: N/A (no control-manifest.md)
> **Last Updated**: —

## Context

**Spec**: `design/gdd/rigs/pudge.md §7` (sockets — BoneAttachment3D definitions)
**Why**: Gameplay attaches the hook, VFX, status icons, and hit-center to named bone offsets.
This story records the exact bone-space offsets so Story 017 can place `BoneAttachment3D` nodes.

**Engine**: Blender 4.x/5.1 → Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] 5 sockets defined with bone parent + local offset per §7: `socket_hook_hand`→LeftHand, `socket_offhand`→RightHand, `socket_chain_origin`→Chest, `socket_hit_center`→Spine1, `socket_head_top`→Head
- [ ] Each offset matches §7 (e.g. hook_hand 5 cm forward along LeftHand −Z, −15° tilt; head_top 18 cm above Head)
- [ ] Socket positions verified against the bind-pose mesh (visually land at grip / chest / skull-top / etc.)
- [ ] Offsets documented for the Godot side (Story 017) — Blender empties parented to bones, or a recorded offset table

---

## Implementation Notes

Per §7, these become `BoneAttachment3D` in Godot. In Blender, either create empties parented to
the relevant bones at the §7 offsets (they can export as nodes), or just record the bone-local
transforms for Story 017 to apply. Bone names must match Story 001's reconciled names.

---

## Out of Scope

- Creating the runtime `BoneAttachment3D` nodes and attaching props → Story 017.

---

## QA Test Cases

- **AC-2/3 (offsets land correctly)**:
  - Setup: at bind pose, visualize each socket point on the mesh
  - Verify: hook_hand at grip, offhand at right hand, chain_origin at upper-left chest, hit_center mid-torso, head_top at skull dome top
  - Pass condition: each lands within ~1-2 cm of the §7 description

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: documented offset table or `production/qa/evidence/pudge-sockets-evidence.md` with screenshots.
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 007 (skeleton), Story 001 (bone names)
- Unlocks: Story 017
