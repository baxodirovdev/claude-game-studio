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

---

## Review — 2026-05-31 — Verdict: NEEDS REVISION

**Scope signal**: L — multi-section propagation across 1 large document + 1 small bootstrap file (`production/qa/godot-acceptable-warnings.md`) + 1 separate Stage 10 code task. ~15 BLOCKING items reduce to ~8-10 distinct underlying fixes after dedup. No new ADRs required.

**Specialists**: character-artist, texture-artist, rigging-animator, blender-specialist, technical-artist, qa-lead, creative-director (senior synthesis)

**Blocking items**: 15 | **Recommended**: 13

**Summary**:

Downgraded from prior MAJOR REVISION NEEDED. Steps 1-7 of the 9-step revision sprint successfully built the interface contract (`design/gdd/contracts/pudge-interface-contract.md` — Step 3), resolved 8 Godot 4.6 API verifications (Steps 4-5), built the perf measurement framework (Step 6), and rewrote the 6 untestable acceptance criteria in §11 (Step 7). All six specialists converged on the same diagnosis with zero disagreements: **the contract is correct, the model spec body text was not propagated**. Step 7 only updated §11 F-gates and §E; §3 (jiggle 3-color), §5 (alpha-of-basecolor tint shader), §7 (stale socket positions), §9 (spring-conditional BellyJiggle + "25 full" bone count), §10 (false LOD auto-detect claim + wrong texture path + `pudge_` filename prefix), §11.C (compounds the texture path errors), and §12 (Q12.4 still OPEN) all still contain superseded content.

Three new gaps were introduced by Step 7 itself (not present in prior review): (1) §F.4 stress test gate references `pudge.glb` without specifying it must be the Stage 10 final GLB rather than the current prototype primitives build; (2) `production/qa/godot-acceptable-warnings.md` referenced by §F.2 has a circular creation dependency — F.2 requires the list, F.2 says the list is created during F.2 first run; (3) §F.3 pixel measurements (≥3 px pupil, ≥2 px stitches) not reliably verifiable across DPI-scaled displays.

One code-level finding outside the spec: `_apply_hero_tint` at `src/gameplay/hero/hero_model_builder.gd:401-412` uses `set_shader_parameter` (per-material) instead of `set_instance_shader_parameter` (per-instance). When Stage 7 wires up textures this will silently inflate VRAM 10× — should be documented in spec as Stage 10 fix requirement.

Creative-director recommendation: 1 focused session (~6 hours) of mechanical propagation work with the contract open as source of truth, plus design decisions for the three Step 7 regressions. **Not** a full revision sprint — closer to cleanup.

**Prior verdict resolved**: Partially. Prior 27 BLOCKING items reduced to 15 BLOCKING (with ~8 underlying root causes after dedup). Most prior blockers resolved at the contract level via Steps 1-7; remaining gap is propagating contract decisions back into the model spec body text.

### Top Three Next Actions (per creative-director)

1. **Propagation sweep with contract as source of truth.** Open contract + spec side-by-side. Walk through §3, §5, §7, §9, §10, §11.C, §12 in order and overwrite any value that disagrees with the contract. Specifically: bone count 25→26, socket positions, texture paths/filenames (remove `pudge_` prefix), alpha-of-basecolor → `body_tintmask.png` (5 locations), LOD auto-detect → manual visibility_range, jiggle 3-color → 2-color, BellyJiggle spring conditional → keyframe-only, Q12.4 OPEN → RESOLVED. Mechanical work, one focused pass.

2. **Resolve the three Step 7 regressions** (require actual decisions): (a) Split F.4 into F.4a prototype smoke + F.4b Stage 10 acceptance; (b) Bootstrap `production/qa/godot-acceptable-warnings.md` as empty versioned stub NOW; (c) Switch §F.3 pixel measurements to UV-space OR pin viewport "1920×1080, HiDPI disabled" with named screenshot tool.

3. **Add `set_instance_shader_parameter` requirement to spec body** + file separate code task for `hero_model_builder.gd:401-412`. Out of scope for this spec review but must be documented so future programmer doesn't miss it.

---

## Review — 2026-06-18 — Verdict: APPROVED

**Depth**: `lean` (single-session, no specialist subagents — full-mode specialist spawn is blocked under the active 1M-context model without usage credits; the structural + consistency + testability analysis below was performed directly against the interface contract). Re-review of the 2026-05-31 NEEDS REVISION verdict.

**Scope signal**: L (carried over — multi-section spec, contract-coupled). No new ADRs.

**Blocking items**: 0 | **Recommended**: 2 (advisory, non-blocking)

**Summary**:

The contract-propagation cleanup the 2026-05-31 review prescribed is complete and verified. All 15 prior BLOCKING items shared a single root cause — *the interface contract was correct but its decisions had not been propagated into the model-spec body text* — and every propagation target now matches the contract on a value-by-value cross-check:

- **§3 / §9 jiggle** — 2-color (red/white) + linear pink gradient, matching contract §6. No residual yellow band.
- **§5 / §10 / §11.C materials** — dedicated `body_tintmask.png` as the 5th body map; BaseColor is pure RGB (no alpha tint); `team_tint_color` is the only per-instance uniform, samplers stay per-material (contract §7 + O-6); ETC2 baseline ~2.05 MB / ~2.73 MB-with-mips VRAM (contract O-7); texture path `src/assets/textures/heroes/pudge/` with no `pudge_` filename prefix.
- **§7 sockets** — all five socket transforms verbatim from contract §5, including the corrected `socket_hit_center` (0,0,+0.12) and `socket_hook_hand` (0,0,-0.05)/(-15,0,0); world-position verification table consistent.
- **§9 skeleton** — MVP bone count 22 (Jaw included, 4× ChainLink post-MVP, full = 26); the stale "25" is gone; BellyJiggle keyframed in all 10 clips (contract O-4, no Godot 4.6 spring modifier).
- **§10 LODs** — false `_lod*` auto-detect claim replaced with the manual `visibility_range_begin/end` + "Generate LODs off" workflow (contract O-5).
- **§12** — Q12.4/8/9/10/14 RESOLVED, Q12.13/20 DEFERRED, Q12.18 PARTIAL, each citing its contract ID; Decision Status Table consistent.

The three regressions Step 7 introduced are all closed: F.4 is split into F.4a (dev-machine smoke, informational, any build) and F.4b (target-device acceptance, binding, Stage 10 GLB only) with the VRAM figure corrected; the F.2 circular dependency is broken by the pre-existing versioned stub at `production/qa/godot-acceptable-warnings.md`; and §F.3's pixel measures are pinned to a 1920×1080 HiDPI-disabled capture with the silhouette measure moved to world-space AABB. The `set_instance_shader_parameter` requirement is documented in §5 and §11.H and filed as a Stage 10 code task. Dependency graph: all 11 referenced files (contract, rig spec, materials spec, brief, concept, warnings stub, stress scene, perf README, both Blender validators, loader) exist on disk.

**Recommended (advisory, do NOT block Stage 3)**:
1. The remaining open items are all correctly *deferred and tracked*, not unresolved: O-1 target device (gates F.4b only), rig-spec propagation (contract §12 rig rows still open — separate Stage 8 task), `pudge.tres` stat balance (debug placeholders — game-designer, before Stage 10), and the four Stage 10 code tasks (HERO_SOCKETS update, rotation-hack removal, shader rewrite, `set_instance_shader_parameter`). None block the model spec.
2. This verdict is a **lean** review. The two prior verdicts were full 6-specialist adversarial passes. If the studio wants an equally-authoritative specialist sign-off for the phase gate, re-run `/design-review` in full mode once usage credits are enabled (or under a standard-context model).

**Prior verdict resolved**: Yes — all 15 BLOCKING items from 2026-05-31 plus the 3 Step-7 regressions are resolved and verified.
