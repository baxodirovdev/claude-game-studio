# Active Session State — Pudge Model Pipeline

**Last updated**: 2026-06-18 (Stage 4 safe auto-prep complete — sculpt handed off)
**Current stage**: 4 (Sculpt cleanup) — entry gate PASS; safe scripted prep done; **artistic sculpt handed off to user in Blender**

> **2026-06-18 Stage 4 safe auto-prep (agent, scripted/safe)**: snapshot `pudge_v2_remesh` →
> `pudge_v2_remesh_preStage4` (hidden `STAGE4_BACKUP`); confirmed chunky arm/hand mass on +X
> (character's left — 1482 vs 628 verts at hand band), matching Silhouette B; removed stale
> `PUDGE_NEW_REFERENCE_RIG` (12 REF_* objects scaled to old 1.5 m); reconciled
> `design/gdd/asset-records/pudge.md` to contract (22/26 bones, T-pose, keyframed jiggle, manual
> LOD); wrote `design/gdd/asset-records/pudge_stage4_sculpt_cleanup.md` checklist; saved .blend.
> Mesh is a single connected island (no loose artifacts) — the −X head/shoulder protrusion
> (708 verts, z 1.12–1.28, x −0.68→−0.30) is *connected* surface → flagged in checklist for human
> sculpt, NOT script-deleted.
>
> **2026-06-18 CORRECTION — "4 arms" was a mis-read; reverted.** An attempted scripted cut
> (extract left-upper to a ref object + delete right-upper) was based on a wrong "spurious extra
> arms" reading. Top-down + front ortho confirmed the mesh has **exactly two arms in a ~T-pose**
> (correct riggable bind pose) — the "4 arms" look was the **hook blade + chain coils fused onto
> the hands**, not real limbs. All cuts **fully reverted** to the clean 19,147-vert backup;
> partial-cut ref object/collection removed; .blend re-saved clean. **User decision: leave the mesh
> as-is** (good 2-arm T-pose base); the fused hook/chain are **deferred to a later prop-separation
> task** (task #13), keeping the left (+X) fused hook/chain as the shape reference. Checklist
> corrected accordingly. **Next**: face/belly/arm-form sculpt refinement (no bulk cutting), then
> Stage 5 (Retopo).

> **2026-06-18 verdict**: `/design-review design/gdd/models/pudge.md` re-run (lean depth — full-mode
> specialist subagents are blocked under the 1M-context model without usage credits) returned
> **APPROVED**, 0 blocking. All 15 prior BLOCKING items (root cause: contract not propagated) plus the
> 3 Step-7 regressions are resolved and value-by-value cross-checked against the interface contract.
> Verdict appended to `design/gdd/reviews/pudge-model-review-log.md`. Spec §1 banner flipped to APPROVED.
> Remaining open items are all correctly deferred/tracked (O-1 device, rig-spec propagation, pudge.tres
> stat balance, 4× Stage 10 code tasks incl. session task #10) — none block Stage 3.
> **Next**: begin Stage 4 (sculpt cleanup), OR re-run full-mode `/design-review` if an authoritative
> 6-specialist phase-gate sign-off is wanted (requires enabling credits / standard-context model).

## Where we are

Pudge model pipeline, 10-stage character art workflow.

- ✅ Stage 1 — Character Brief (locked)
- ✅ Stage 2 — Base mesh prep + T-pose conversion (Hunyuan3D → voxel remesh 20mm → coarse skin → T-pose applied as rest)
- ✅ Stage 3 — Model Spec — **APPROVED** (lean re-review 2026-06-18, 0 blocking)
- 🎨 **Stage 4 — Sculpt cleanup — IN PROGRESS** (safe auto-prep done; artistic sculpt handed off to user)
- ⏸ Stages 5-10 — Pending Stage 4 sculpt completion

## What's done this session

1. Brief authored at `design/characters/pudge-character-brief.md` (corrected axis from -Y to -Z, height from 1.5m to 1.4m)
2. Old Pudge spec archived to `design/gdd/models/_archive/pudge.md.2026-04-28`
3. New Pudge spec authored at `design/gdd/models/pudge.md` — 12 sections, ~1300 lines
4. `tools/blender/validate_export.py` partial implementation
5. Export check baseline log at `production/session-logs/export-check-pudge-2026-05-30.md`
6. Full /design-review run — 6 specialists + creative-director synthesis
7. Review log written at `design/gdd/reviews/pudge-model-review-log.md`

## Why Stage 3 failed review

27 BLOCKING items across 7 themes (full details in review log):

1. **Cross-doc schism** — `design/gdd/models/pudge.md`, `design/gdd/rigs/pudge.md`, `design/gdd/materials/pudge.md` conflict on: bone names, socket offsets, jiggle encoding, tint mask delivery, bind pose
2. **Phantom tooling** — 4+ scripts gated against that don't exist
3. **Unverified APIs** — Godot 4.6 claims for `SkeletonModification3DJiggle`, LOD auto-detect, etc.
4. **Untestable QA** — "readable", undefined target device, undefined test scene
5. Several others (topology compound rotation, performance measurement, export workflow)

## Current Blender scene state

File: `src/assets/models/heroes/anime_pudge.blend` (saved, 28.7 MB)

- `pudge_v2_remesh` — T-posed body, 38k tris, in PUDGE_NEW_BUILD collection — current working mesh
- `prop_hook_snapshot` (red tint) + `prop_blade_snapshot` (blue tint) — reference prop captures
- `pudge_v2_basemesh` — hidden backup (original duplicated Hunyuan3D)
- Hidden: cameras, lights, reference rig markers, OLD Pudge collection

## Resume from here — recommended path

### Step 1 — Read all 3 specs together

- `design/gdd/models/pudge.md` (this session's draft)
- `design/gdd/rigs/pudge.md` (Stage 8 spec — created prior, likely senior)
- `design/gdd/materials/pudge.md` (Stage 7 spec — created prior, likely senior)

### Step 2 — Designate authority

Per creative-director recommendation: **rig spec is authoritative** for bone names, sockets, bind pose, jiggle encoding. Materials spec is authoritative for tint mask delivery and channel packing. Model spec must conform.

### Step 3 — Author the interface contract

Create `design/gdd/contracts/pudge-interface-contract.md` (new file) as the single source of truth for the shared contract surface. All 3 specs link to it.

### Step 4 — Resolve gating open questions

- Q12.20 — target device (technical-director needed)
- Q12.13 — forward axis verification (verify in Blender now)
- Q12.4 — tint shader rewrite scope (art-director needed)
- Q12.10 — jaw bone in MVP (game-designer needed)

### Step 5 — Build phantom tools OR remove gates

- `tools/blender/validate_export.py` — finish the implementation
- `tools/blender/verify_hook_weights.py` — author
- Collection-filter export script — author
- Impostor pipeline — design or defer to LOD2 only

### Step 6 — Verify Godot 4.6 APIs

Spawn `godot-specialist` to verify:
- `SkeletonModification3DJiggle` (probably doesn't exist; need GDScript custom)
- LOD auto-detect by suffix for pre-authored LODs (probably needs manual import setup)
- Texture sharing via per-instance shader params

### Step 7 — Re-run /design-review

Once revisions complete, re-run with prior review log as input.

## Key files

| Type | Path |
|---|---|
| This session state | `production/session-state/active.md` |
| Review log | `design/gdd/reviews/pudge-model-review-log.md` |
| Model spec (NEEDS REVISION) | `design/gdd/models/pudge.md` |
| Rig spec (likely authoritative) | `design/gdd/rigs/pudge.md` |
| Materials spec (likely authoritative) | `design/gdd/materials/pudge.md` |
| Character brief | `design/characters/pudge-character-brief.md` |
| Concept (APPROVED) | `design/concept-art/pudge.md` |
| Working Blender file | `src/assets/models/heroes/anime_pudge.blend` |
| Export check baseline | `production/session-logs/export-check-pudge-2026-05-30.md` |
| Loader code (needs Q12.16, Q12.17 changes at Stage 10) | `src/gameplay/hero/hero_model_builder.gd` |

## Estimated revision effort

**1 sprint (5-10 working days)** per creative-director.

## Critical reminder

The user explicitly chose "Stop here, revise in a separate session." Do NOT attempt to continue revising the spec in this session. If user returns and asks to continue: re-read this file first, then propose a fresh session with /clear.

---

## 2026-05-31 SESSION UPDATE — Revision sprint Steps 1-3 complete

### What got done this session

1. **Step 1** — All 6 context files read end-to-end (resume doc, active.md, review log, model/rig/materials specs, brief, concept). 15 cross-doc conflicts catalogued.

2. **Step 2** — All 4 gating questions resolved + 2 cascading decisions:
   - Q1 device tier: **DEFERRED** — owner tech-director + producer, deadline Stage 7
   - Q2 axis check: **DEFERRED** — Stage 4 entry criterion, owner blender-specialist
   - Q3 tint shader: **B chosen** — dedicated `body_tintmask.png` (5th map), materials spec wins
   - Q4 Jaw bone: **YES** — included in MVP (22 bones), rig spec wins
   - Bind pose (cascading): **T-pose wins** — brief is locked, rig spec §2 gets rewritten
   - Bone naming (cascading): **`mixamorig:*` wins** — model spec wins, matches existing loader code

3. **Step 3** — Interface contract authored at `design/gdd/contracts/pudge-interface-contract.md` (898 lines, 12 sections):
   - §1 Source-of-truth precedence
   - §2 Axes & bind pose (T-pose locked)
   - §3 Skeleton bone naming (`mixamorig:*`)
   - §4 Helper bones (BellyJiggle conditional, Jaw included)
   - §5 Sockets (rig numbers, model parent names, Mixamo bone-roll convention)
   - §6 jiggle_boundary 2-color encoding
   - §7 Materials & tint (5-map body + 3-map hook, dedicated tintmask, shader rewrite)
   - §8 Performance (DEFERRED)
   - §9 Axis verification (DEFERRED)
   - §10 Movement speed (NEW conflict surfaced)
   - §11 Open items roll-up (12 items)
   - §12 Propagation checklist (15 design doc edits + 3 code edits + 3 tools + 3 cross-hero textures)

### What's pending (Steps 5-9 of resume plan)

- ✅ **Step 4 — DONE 2026-05-31** — Phantom tools built:
  - `tools/blender/validate_export.py` extended with LOD budget + jiggle_boundary + bone count + collection checks (tested headlessly, correctly catches all current .blend issues)
  - `tools/blender/verify_hook_weights.py` NEW — verifies hook mesh weighted exclusively to mixamorig:LeftHand
  - `tools/blender/export_pudge.py` NEW — two-pass export (body GLB + hook GLB) with collection filter via hide/select/restore, `--dry-run` and `--out-dir` flags
  - LOD3 impostor DEFERRED to post-MVP (contract O-13 added; model spec §2 LOD table updated; LOD2 extends to infinity)
- ✅ **Step 5 — DONE 2026-05-31** — Godot 4.6 API verifications via project engine reference + WebFetch/WebSearch:
  - **O-4 RESOLVED**: No `SkeletonModification3DJiggle` exists in Godot 4.6 (only CCDIK/FABRIK/Jacobian/Spline/TwoBoneIK + BoneConstraint3D set). BellyJiggle locked to **keyframe in all clips** for MVP. Custom GDScript modifier moves to post-MVP.
  - **O-5 RESOLVED**: `_lod*` suffix auto-detect is a *proposal*, not implemented. Pre-authored LODs require manual `visibility_range_begin/end` setup per MeshInstance3D + disabling automatic LOD generation. Model spec §10 needs revision.
  - **O-6 RESOLVED**: Per-instance sampler uniforms NOT supported (`instance uniform sampler2D` → compile error). Per-instance scalar/vec (like `team_tint_color`) IS supported. Contract §7 is correct as-written; added explicit "samplers stay per-material" note.
  - **O-7 RESOLVED**: ASTC 6×6 is ~2.25× smaller than ETC2 RGBA at 1024² (~0.46 MB vs ~1 MB compressed). Godot's "Mobile / High Quality" preset uses ASTC 4×4 (same size as ETC2 but better quality), not 6×6. ASTC 6×6 requires manual import setting. Final choice gated on O-1 (device tier). Materials spec §12 VRAM table is optimistic — actually ~2× larger than stated.
- ✅ **Step 6 — DONE 2026-05-31 (PARTIAL — dev-machine only)** — Stress test scene built and validated:
  - `src/scenes/perf/pudge_stress_test.tscn` + `src/scenes/perf/pudge_stress_test.gd` — 10-instance Pudge stress harness, configurable instance count / sample duration / vsync-disabled, auto-quits with frame time percentile report
  - `tests/performance/README.md` — usage docs + baseline history table
  - First baseline run: RTX 5050 / Vulkan Forward Mobile / prototype primitives Pudge: **p95 = 0.34 ms** (dev machine, NOT mid-tier mobile target)
  - Caveats documented: result is informational only — final perf verdict requires (1) O-1 device tier resolution, (2) Stage 10 final Pudge GLB, (3) measurement on actual target device
  - Contract O-12 updated: OPEN → PARTIAL (dev baseline captured, mobile measurement still blocked)
- ✅ **Step 7 — DONE 2026-05-31** — 6 untestable acceptance criteria rewritten in `design/gdd/models/pudge.md`:
  - §E: 3-color jiggle_boundary → 2-color + gradient (aligned with contract §6)
  - §F.1: added 3 new check lines (jiggle_boundary layer, bone count, collection placement — all now script-enforced by `validate_export.py`)
  - §F.1b (NEW): added hook weighting gate referencing `verify_hook_weights.py`
  - §F.2: "no errors/warnings" → "no ERROR rows + warnings reviewed against approved list"; LOD auto-detect myth busted (contract O-5), replaced with visibility_range manual setup verification
  - §F.3: "silhouette readable" → objective measurement (hook tip extends body bounds by ≥20% character height, screenshot to evidence dir); "face features resolve" → pixel-counted asymmetric eyes + ≥3px pupils + ≥2px stitch lines, screenshot to evidence dir; tint shader gate expanded to 3 specific color values with named screenshot artifacts
  - §F.4: "mid-tier device" → references contract O-1; "test scene" → concrete path to `src/scenes/perf/pudge_stress_test.tscn`; texture budget "≤ 2 MB" → "≤ 8 MB" with rationale (per O-7 verification, ETC2 RGBA actual size is ~1 MB/1024² — old 2 MB target was impossible)
  - §H: added "All §12 open questions either RESOLVED in spec or migrated to contract §11 with owner + deadline + status"
- ✅ **Step 8 — DONE 2026-05-31** — `/design-review` re-ran on `design/gdd/models/pudge.md`. Verdict: **NEEDS REVISION** (downgraded from MAJOR REVISION NEEDED, 27 → 15 blockers, ~8 underlying root causes after dedup). 6 specialists + creative-director synthesis, zero disagreements. Diagnosis: contract is correct, model spec body text wasn't propagated. Step 7 only touched §11 + §E; §3, §5, §7, §9, §10, §11.C, §12 still carry superseded content. Plus 3 NEW gaps from Step 7 (wrong-asset perf gate, circular approved-warnings file, DPI-unsafe pixel measurements). Verdict + full findings appended to `design/gdd/reviews/pudge-model-review-log.md`. Creative-director estimate: 1 focused session (~6 hours) of propagation cleanup to ship Stage 3.
- ✅ **Step 9 — DONE 2026-05-31 (PARTIAL)** — Pudge added to `design/gdd/hero-system.md` as 4th hero (item 4, Tank/disruptor, hook_type=PULL, fantasy + skill profile written). **Stat values still TBD** — `src/data/heroes/pudge.tres` currently has debug placeholders (hook_damage=99999, xp_on_hook_hit=0); real balance pass remains game-designer task before Stage 10. **Side-finding**: `coil.tres` and `flux.tres` exist (CHARGE / BEAM hook types) but neither is documented — added as new open question in hero-system.md. Contract O-9 status: OPEN → PARTIAL. Also updated hero-system.md's `hook_type` enum line to reflect the 5 actual values (PULL/GRAPPLE/BOOMERANG/CHARGE/BEAM) rather than just 3.

### Task tracker IDs (live in this session — preserve across compaction)

Tasks #1-#9 created. #1, #2, #3 completed. #4-#9 pending.

### Critical reminder (UPDATED)

This session made substantial progress (Steps 1-3, ~3 hours of the 5-7 day estimate). Context usage is moderate. The user may continue with Step 4 in this session OR stop and resume in a fresh session — both valid.

If continuing here: Step 4 (phantom tools) is mostly Python scripting in `tools/blender/`, low-context-cost.
If stopping: next session reads this file, then `design/gdd/contracts/pudge-interface-contract.md`, then proceeds to Step 4.

---

## 2026-06-18 SESSION UPDATE — Step 10: contract-propagation cleanup COMPLETE

The ~6-hour propagation pass the creative-director estimated after Step 8's NEEDS REVISION verdict. All 15 BLOCKING items + 3 Step-7 regressions addressed by propagating the interface contract into the model-spec body text. **No design decisions changed — the contract was already correct; this was mechanical alignment.**

### What got done (`design/gdd/models/pudge.md`)

1. **§1 header** — "Conflicts with" → "Implements contract"; MAJOR-REVISION banner → propagation-complete banner.
2. **§3 jiggle** — 3-color (red/yellow/white) → 2-color (red/white) + linear pink gradient per contract §6; ring diagram + §9 influence table "yellow region" fixed.
3. **§5 materials** — BaseColor-alpha tint → dedicated `body_tintmask.png` (5th map); shader uniforms/logic rewritten mask-based with per-instance `team_tint_color` (instance uniform) + samplers per-material (O-6); VRAM table corrected to ETC2 ~2.05 MB (~2.73 w/ mips) per O-7; `set_instance_shader_parameter` requirement documented; `pudge_` prefixes dropped.
4. **§7 sockets** — 5 rows propagated to contract §5 values (hook_hand (0,0,-0.05)/(-15,0,0); offhand (0,0,-0.04); hit_center -0.28→+0.12); world-position verification table updated; LOD3-socket note marked deferred.
5. **§9 bones** — count locked 22 MVP (full=26, "25" miscount fixed); BellyJiggle spring-conditional → keyframe-only (O-4); ChainLink Optional → POST-MVP; Jaw Optional → INCLUDED (Q4).
6. **§10** — texture path → `src/assets/textures/heroes/pudge/` prefix-free + `body_tintmask.png` added; LOD `_lod*` auto-detect myth busted (O-5) → manual `visibility_range` setup.
7. **§11** — §11.C deliverables path/filename/tintmask fixed; **3 Step-7 regressions resolved**: (a) F.4 split into F.4a dev-smoke (informational) + F.4b target-device acceptance (Stage 10 final GLB only); (b) F.2 warnings-list circular dependency broken (stub bootstrapped — see below); (c) F.3 pixel measures pinned to 1920×1080 HiDPI-off, silhouette measure made world-space/DPI-independent; §11.H + Acceptance Criteria updated.
8. **§12** — Q12.4/8/9/10/14 → RESOLVED, Q12.13/20 → DEFERRED, Q12.18 → PARTIAL, all citing contract IDs; Decision Status Table refreshed; footer status updated.

### Other artifacts this session

- **NEW** `production/qa/godot-acceptable-warnings.md` — empty versioned stub bootstrapped (breaks F.2 circular dep).
- **Contract §12** propagation checklist — model-spec + hero-system items checked off (rig-spec items still OPEN — separate task, NOT done this session).
- **Contract §12 Code** — added explicit `hero_model_builder.gd:401-412` `set_instance_shader_parameter` fix entry (confirmed regression: line 408 uses `set_shader_parameter("tint_color")` + mints fresh ShaderMaterial per build). Filed as session task #10.

### Verification done

Grepped model spec for residual stale content: no `pudge_*.png` filename prefixes, no old texture path (except the explicit "superseded" note), no stale `yellow` jiggle / `tint_color` uniform / auto-detect claim / spring-conditional / alpha-tint / "25 bones" / DRAFT-MAJOR-REVISION banners. All remaining matches are intentional "superseded" references or legitimate current content.

### Next step (NOT done this session)

**Re-run `/design-review design/gdd/models/pudge.md`** — target APPROVED verdict to clear Stage 3 and unblock Stages 4-10. Append verdict to `design/gdd/reviews/pudge-model-review-log.md`.

Still-open (non-blocking for Stage 3 model spec, tracked in contract §11):
- Rig spec (`design/gdd/rigs/pudge.md`) §1/§2/§4.1/§4.3/§7/§13 NOT yet propagated (contract §12 rig items still unchecked).
- `pudge.tres` stat balance (debug placeholders) — game-designer, before Stage 10.
- Stage 10 code tasks: HERO_SOCKETS update, rotation-hack removal, shader rewrite, set_instance_shader_parameter fix (session task #10).
