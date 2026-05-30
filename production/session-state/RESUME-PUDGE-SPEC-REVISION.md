# RESUME — Pudge Spec Revision

> **Open this file FIRST in your next session.**
> It tells you exactly what to do, in order, with commands to copy-paste.

---

## Quick context (30 seconds)

You're mid-way through building the Pudge hero model for a chibi mobile MOBA game in Godot 4.6.

**Last session ended**: 2026-05-31 (revision sprint Steps 1-3 complete)
**Original failure**: 2026-05-30 — Stage 3 failed `/design-review` with MAJOR REVISION NEEDED, 27 blocking items, 3 specs in conflict.
**Current progress**: Steps 1-3 of the 9-step revision plan are DONE. Interface contract exists at `design/gdd/contracts/pudge-interface-contract.md` and locks 8 of the 15 cross-doc conflicts. Steps 4-9 remain (~4-6 working days).

**You are mid-sprint, not starting over.** Brief (Stage 1), T-pose mesh (Stage 2), and the cross-doc interface contract (Step 3 of revision) are all locked. The model spec itself still needs §1/§3/§5/§7/§9/§10/§11 rewrites per the contract's §12 propagation checklist; the rig spec needs §1/§2/§4.3/§7/§13 rewrites.

**Next session starts at Step 4** (phantom tools).

---

## Step 1 — Read these files in this order (5 minutes)

```bash
# 1. This file (you're here)
production/session-state/RESUME-PUDGE-SPEC-REVISION.md

# 2. Full session state (more detail, includes 2026-05-31 update)
production/session-state/active.md

# 3. THE INTERFACE CONTRACT (Step 3 deliverable — authoritative on 8 conflicts)
design/gdd/contracts/pudge-interface-contract.md   # ← READ THIS FIRST after active.md

# 4. The review log (why Stage 3 originally failed — historical context)
design/gdd/reviews/pudge-model-review-log.md

# 5. The three specs (now PARTIALLY superseded by the contract)
design/gdd/models/pudge.md          # NEEDS REVISION per contract §12
design/gdd/rigs/pudge.md            # NEEDS REVISION per contract §12
design/gdd/materials/pudge.md       # 1 minor confirm per contract §12

# 6. Brief and concept (for design intent — already locked)
design/characters/pudge-character-brief.md
design/concept-art/pudge.md
```

**The contract supersedes any conflict between the three specs.** If the
specs disagree with each other on a topic the contract covers, trust the contract.

---

## Step 2 — Resolve 4 gating open questions FIRST (1 hour) — ✅ DONE 2026-05-31

The 4 gating questions are resolved. See the contract §11 (open items) for what's still deferred.

**Resolutions captured**:
- Q1 device tier → DEFERRED (owner tech-director + producer, deadline Stage 7)
- Q2 axis check → DEFERRED (Stage 4 entry criterion, owner blender-specialist)
- Q3 tint shader → **B chosen** (dedicated `body_tintmask.png` 5th map)
- Q4 Jaw bone → **YES** (included in MVP, 22 bones)
- Cascading: bind pose → **T-pose wins** (brief locked), bone naming → **`mixamorig:*` wins** (matches existing code)

(Original question detail preserved below for historical context.)

### Q1: What's the target mobile device tier?

- Samsung Galaxy A54 (mid-range Android 2023)?
- iPhone 12 (mid-range Apple 2020-23)?
- Both?

**Owner**: technical-director + producer
**Why blocks**: Performance gate F.4 cannot be executed without this
**Decision**: ____________

### Q2: Does the current Pudge mesh face -Y in Blender front view?

Open Blender, load `src/assets/models/heroes/anime_pudge.blend`, switch to Front Orthographic view. If you see Pudge's face = correct (-Y forward in Blender → -Z forward in Godot). If you see Pudge's back = wrong (needs 180° rotate around Z, then apply rotation).

**Owner**: blender-specialist (you can verify this in 30 seconds)
**Why blocks**: All Stage 4+ work depends on correct orientation
**Decision**: ____________

### Q3: Tint shader — rewrite to mask-based, or keep existing hue-band?

Current `res://assets/shaders/hero_body_tint.gdshader` is hue-band based (no texture samplers). Both new specs assume a different shader exists. Three options:

- **(A) Rewrite shader to mask-based** — what model spec § 5 prescribes (BaseColor alpha = tint mask)
- **(B) Rewrite shader to mask-based with separate texture** — what materials spec § 6 prescribes
- **(C) Keep existing hue-band, conform Pudge's base color to its detection range**

**Owner**: art-director + gameplay-programmer
**Why blocks**: Stage 7 texture authoring can't begin
**Decision**: ____________

### Q4: Is the `Jaw` bone required for MVP?

If `taunt` and `death` clips need mouth gape → YES (22 bones)
If those clips can use blendshape for mouth → NO (21 bones)

**Owner**: game-designer
**Why blocks**: Stage 8 rigging skeleton finalized
**Decision**: ____________

---

## Step 3 — Build the interface contract document (1 day) — ✅ DONE 2026-05-31

Contract authored at `design/gdd/contracts/pudge-interface-contract.md` (898 lines, 12 sections). Locks:

- §2 Axes (Brief wins, T-pose)
- §3 Bone naming (Model spec wins, `mixamorig:*`)
- §4 Helper bones (BellyJiggle conditional on Step 5 API check, Jaw MVP)
- §5 Sockets (Rig spec numbers + Mixamo parent names)
- §6 jiggle_boundary (Rig spec wins, 2-color)
- §7 Materials (Materials spec wins, dedicated tintmask)
- §8 Performance (DEFERRED)
- §9 Axis verification (Stage 4 entry)
- §10 Movement speed (NEW open conflict, gameplay-programmer)
- §12 Propagation checklist for 15 design doc edits + 3 code edits

(Original Step 3 instructions preserved below.)

The contract must lock these 8 items (in order of importance):

| # | Item | Currently conflicting between |
|---|---|---|
| 1 | Bone names (Mixamo `:` vs PascalCase no-prefix) | model spec §9 vs rig spec §1 |
| 2 | Socket bone-local positions (5 sockets × 3 axes) | model spec §7 vs rig spec §7 |
| 3 | `jiggle_boundary` color encoding (3-color vs 2-color) | model spec §3 vs rig spec §4.1 |
| 4 | Tint mask delivery (alpha vs separate texture) | model spec §5 vs materials spec §6 |
| 5 | Bind pose (T-pose vs A-pose) | model spec §1 vs rig spec §2 |
| 6 | Total bone count (21 / 22 / 25) | Tied to Q4 (jaw) |
| 7 | Forward axis convention (and Blender export setting) | model spec §6 unclear |
| 8 | Target device + perf budget | Tied to Q1 |

Per **creative-director recommendation**: rig spec wins on items 1, 2, 3, 5, 6. Materials spec wins on item 4. Conform model spec to both.

---

## Step 4 — Build or remove phantom tools (1-2 days)

4 scripts referenced by spec gates that don't exist. Either build them or remove the gate.

### 4a. `tools/blender/validate_export.py` (PARTIAL — exists)

Already partially written this session. Needs:
- `--asset` arg parsing fix
- Validate all 8 expected export objects
- Run from headless Blender (currently MCP-only)

### 4b. `tools/blender/verify_hook_weights.py` (NEW)

5-line script to verify hook mesh has only `LeftHand` vertex group with non-zero weights.

### 4c. Collection-filter export script (NEW)

The spec says "export from PUDGE_NEW_BUILD collection only" but Blender's GLTF exporter doesn't filter by collection name. Need a script that:
1. Sets PUDGE_NEW_BUILD as active collection
2. Hides PUDGE_REFERENCE and PUDGE_OLD_REFERENCE
3. Selects only objects in NEW_BUILD
4. Runs export with selection mode

### 4d. Impostor billboard generation (DESIGN OR DEFER)

Godot 4.6 has no built-in impostor system. Either:
- **Design**: Blender script that renders 8 camera angles at 30° pitch, packs into 1024×128 strip
- **Defer**: Drop LOD3 from spec — use LOD2 to infinity instead

**Recommendation**: defer impostor. Save work for post-MVP.

---

## Step 5 — Verify Godot 4.6 APIs (1 day)

Spawn `godot-specialist` agent to verify these claims before re-asserting them:

```
1. Does SkeletonModification3DJiggle exist in Godot 4.6?
   (Spec assumes yes; specialists say probably no — needs custom SkeletonModifier3D GDScript)

2. Does LOD auto-detect by _lod0/_lod1/_lod2 suffix work for PRE-AUTHORED LODs in Godot 4.6?
   (Spec assumes yes; specialists say it only works for importer-GENERATED LODs)

3. Does per-instance shader parameter (set_instance_shader_parameter) preserve
   texture sharing across 10 instances of the same material?
   (Spec assumes yes; not verified)

4. What's the ETC2 fallback size cost vs ASTC 6x6 for our 1024 atlas?
   (Spec mentions ASTC but doesn't specify Android fallback)
```

If any answer is "no" or "unverified": update spec to either find an alternative or note as known limitation.

---

## Step 6 — Measure real performance baseline (4 hours)

Build a test scene with 10 Pudge instances at LOD0, run on actual device, record frame time.

```bash
# Suggested scene
mkdir -p tests/performance/scenes
# Create: tests/performance/scenes/PudgeStressTest.tscn
# 10 instances of current pudge.glb, no terrain, no VFX, all in frustum
```

Open in Godot, profile, record the actual ms number. Replace the "wishful <16 ms" claim in spec §11 F.4 with the measured number.

---

## Step 7 — Re-author untestable acceptance criteria (4 hours)

These 6 BLOCKING QA items need rewrites:

| Current (untestable) | Rewrite to (testable) |
|---|---|
| "Silhouette is clearly readable as the hook hero" | "Hook prop extends outside body silhouette by ≥20% character height — verified in Godot Scene view, screenshot to `production/qa/evidence/`" |
| "Mid-tier target device" | (Resolved by Q1 above — fill in actual device) |
| "No errors or warnings on import" | "No ERROR in Godot Output. Warnings reviewed against approved list at `production/qa/godot-acceptable-warnings.md`" |
| "Test scene" (undefined for F.4) | "Test scene at `tests/performance/scenes/PudgeStressTest.tscn` — 10 instances, idle anim, all in frustum, shadows OFF" |
| "jiggle_boundary correctly painted" | "Run `tools/blender/verify_jiggle_paint.py` — script validates color distribution per spec § 3 |
| "Open questions resolved" | "All Section 12 questions marked RESOLVED with decision text before any F-gate runs" |

---

## Step 8 — Re-run /design-review (30 minutes)

```
/design-review design/gdd/models/pudge.md
```

If verdict APPROVED → mark Stage 3 complete, proceed to Stage 4 (Sculpt cleanup)
If verdict NEEDS REVISION → iterate Steps 3-7 on the new blockers

---

## Step 9 — Update `hero-system.md` (15 minutes)

Add Pudge as 4th hero alongside Vex/Lash/Maw. This is Q12.18 from the review.

```bash
# File to edit:
design/gdd/hero-system.md
```

Add to roster: Pudge — Pull hero (same hook type as Vex, but different stat profile per game-designer)
Update systems-index if needed.

---

## Total estimated time

| Step | Time |
|---|---|
| 1. Read files | 30 min |
| 2. Resolve 4 questions | 1 hour |
| 3. Interface contract | 1 day |
| 4. Phantom tools | 1-2 days |
| 5. Verify Godot APIs | 1 day |
| 6. Performance measurement | 4 hours |
| 7. Acceptance criteria rewrite | 4 hours |
| 8. Re-review | 30 min |
| 9. Update hero-system.md | 15 min |
| **Total** | **5-7 working days** |

This is the 1-sprint estimate from creative-director.

---

## What NOT to do

- ❌ Don't try to revise the spec in pieces — coordinate across all 3 specs together
- ❌ Don't skip Step 2 (gating questions) — they unblock everything else
- ❌ Don't add new features or scope while revising
- ❌ Don't continue to Stage 4 (sculpt cleanup) before Stage 3 passes review
- ❌ Don't trust any claim in the existing model spec — verify against the rig + materials specs

---

## Status check command (run anytime)

```bash
# See where Pudge is in the pipeline
ls -la design/gdd/models/pudge.md      # Should have NEEDS REVISION in header
cat design/gdd/reviews/pudge-model-review-log.md | head -30
cat production/session-state/active.md | head -50
```

If active.md says "MAJOR REVISION NEEDED" — you're still in the revision sprint.
If active.md says "Stage 3 APPROVED" — proceed to Stage 4 sculpt cleanup.

---

## When in doubt

1. Re-read the review log — every blocker is documented
2. Spawn the relevant specialist with the specific question
3. Don't author in isolation — always cross-reference rig spec and materials spec

Good luck. The hard part (Stage 2 voxel remesh + T-pose) is already done.
