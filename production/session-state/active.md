# Active Session State — Pudge Model Pipeline

**Last updated**: 2026-05-31 (continuing revision sprint)
**Current stage**: 3 (Model Specification) — **REVISION IN PROGRESS** — interface contract authored, propagation pending

## Where we are

Pudge model pipeline, 10-stage character art workflow.

- ✅ Stage 1 — Character Brief (locked)
- ✅ Stage 2 — Base mesh prep + T-pose conversion (Hunyuan3D → voxel remesh 20mm → coarse skin → T-pose applied as rest)
- ⚠️ **Stage 3 — Model Spec DRAFTED but FAILED design review (MAJOR REVISION NEEDED)**
- ⏸ Stages 4-10 — Pending until Stage 3 revision complete

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
- **Step 8** — Re-run /design-review on revised model spec → target APPROVED
- **Step 9** — Add Pudge to `design/gdd/hero-system.md` (Q12.18)

### Task tracker IDs (live in this session — preserve across compaction)

Tasks #1-#9 created. #1, #2, #3 completed. #4-#9 pending.

### Critical reminder (UPDATED)

This session made substantial progress (Steps 1-3, ~3 hours of the 5-7 day estimate). Context usage is moderate. The user may continue with Step 4 in this session OR stop and resume in a fresh session — both valid.

If continuing here: Step 4 (phantom tools) is mostly Python scripting in `tools/blender/`, low-context-cost.
If stopping: next session reads this file, then `design/gdd/contracts/pudge-interface-contract.md`, then proceeds to Step 4.
