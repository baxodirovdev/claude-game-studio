# Pudge Model Spec — Review Log

Review history for `design/gdd/models/pudge.md`.

---

## Review — 2026-05-30 — Verdict: MAJOR REVISION NEEDED

**Scope signal**: XL — cross-cutting concern, conflicts with 2 other specs (rig + materials), 4+ new ADRs/scripts required.

**Specialists**: character-artist, texture-artist, rigging-animator, blender-specialist, technical-artist, qa-lead, creative-director (senior synthesis)

**Blocking items**: 27 across 7 themes
**Recommended items**: 22 advisory

**Summary**:

The spec is structurally complete (all 12 sections of the model-spec template filled in substantively) but suffers from systemic cross-document inconsistency with the pre-existing rig spec (`design/gdd/rigs/pudge.md`) and materials spec (`design/gdd/materials/pudge.md`), which were authored separately and now conflict on shared contract surface: bone names (`mixamorig:Spine2` vs `Chest`), socket offsets (model says (0.05, 0, 0); rig says (0, 0, -0.05)), jiggle boundary encoding (3-color gradient vs 2-color), tint mask delivery (BaseColor alpha vs separate texture), and bind pose (T-pose vs A-pose).

Beyond cross-doc conflicts, the spec gates production on 4+ scripts that don't exist (`validate_export.py` partial, collection-filter export, weight conversion, impostor generation), makes 4 unverified claims about Godot 4.6 engine APIs (`SkeletonModification3DJiggle`, LOD auto-detect for pre-authored LODs, texture sharing via material_override, custom shader with non-existent uniforms), and includes performance/acceptance criteria that cannot be executed as written (undefined target device, undefined test scene, subjective "readable" criteria).

Creative-director recommendation: designate the rig spec as authoritative for bone names, sockets, bind pose, and jiggle encoding. Build a `pudge-interface-contract.md` as the single source of truth. Resolve Q12.20 (target device) and Q12.13 (forward axis) first as these unblock 60% of remaining items. Estimated revision effort: 1 sprint (5-10 working days).

**Prior verdict resolved**: First review (no prior).

### 7 Critical Themes

1. **Cross-document schism** (5 BLOCKING) — model vs rig vs materials disagree on bone names, sockets, jiggle, tint, bind pose
2. **Phantom tooling gates** (4 BLOCKING) — spec depends on scripts that don't exist
3. **Unverified engine APIs** (4 BLOCKING) — Godot 4.6 features claimed without verification
4. **Performance & device targets** (4 BLOCKING) — baselines unmeasured, target device undefined
5. **Topology & geometry concerns** (4 BLOCKING) — shoulder loops, belly influence budget, no-neck crease
6. **Export workflow gaps** (4 BLOCKING) — Blender axis convention, transforms order, animation export
7. **Untestable QA criteria** (3 BLOCKING) — subjective gates, undefined test scene, blocking on unresolved questions

### Recommended Revision Plan (Next Session)

1. **Day 1**: Author `pudge-interface-contract.md` — single source of truth for bone names, socket transforms, jiggle encoding, bind pose, forward axis, target device tier
2. **Day 1**: Resolve gating open questions (Q12.20 device, Q12.13 axis, Q12.4 shader, Q12.10 jaw)
3. **Day 2-3**: API verification via godot-specialist (jiggle modifier, LOD, shader params), or remove dependent gates
4. **Day 4**: Performance measurement on one Pudge instance — establish real baseline
5. **Day 5**: Re-author acceptance criteria as testable; build phantom tools or remove gates
6. **Day 6-7**: Re-review cycle (`/design-review` again)

### Resume Path

To resume revision in a fresh session, the next operator should:

1. Read this review log
2. Read `production/session-state/active.md` for session context
3. Read all 3 specs together: `design/gdd/models/pudge.md`, `design/gdd/rigs/pudge.md`, `design/gdd/materials/pudge.md`
4. Begin with the interface contract document
