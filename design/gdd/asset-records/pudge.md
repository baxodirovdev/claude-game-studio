# Pudge — Asset Record

> **Status**: Specs complete (stages 1-5). Authoring in progress (stage 6) — **AI-mesh retopo path**.
> **Hero ID**: `pudge`
> **Asset class**: Character (humanoid, deformable, animated)
> **Date**: 2026-04-28 (updated 2026-05-22)

This record links every produced spec and tracks asset progress end-to-end.

---

## ⚠️ Direction change — 2026-05-22 (AI-mesh source)

The asset originally targeted a **procedural A-pose body** (`tools/blender/heroes/pudge_body_apose.glb`)
destined for **Mixamo auto-rigging** (see stages 6a/6b below — that path was blocked
awaiting the user's Mixamo round-trip).

The project has since **pivoted to a new high-poly source**: an AI-generated mesh
(`textured_mesh`, 40k tris, imported into `src/assets/models/heroes/anime_pudge.blend`).
The chosen strategy is **"retopo to spec + bake"** with the **full studio rig pipeline**
(not Mixamo). Two new docs were authored for this path:

- `design/gdd/models/pudge_retopo_bake_plan.md` — adapts the AI mesh to the model spec (retopo, hook reconstruction, UV re-unwrap, bake config, `jiggle_boundary`, LODs).
- `design/gdd/rigs/pudge_authoring_playbook.md` — validates the 27-bone/10-clip rig spec against the AI mesh and gives the rigger a bone-fitting + clip-authoring playbook.

**Source-prep done (2026-05-22):** `textured_mesh` scaled to 1.4 m, feet at Z=0,
origin-centered, transforms applied. Verified already Z-up (no rotation needed).

**Bake-source stage done (2026-05-22, scripted):**
- `_SOURCE` collection created; `textured_mesh` (scaled AI source) + `textured_mesh_root` moved in.
- `textured_mesh_bake_hp`: islands welded by-distance (27,897→19,949 verts), voxel-remeshed @ 4 mm → **571,960-tri watertight high-poly bake source, 0 non-manifold edges**. High-poly source for normal/AO bakes.
- `EXPORT_BODY` collection created with the decimated blockout (~10,974 tris from the watertight remesh). **Placeholder blockout only — to be REPLACED/refined by manual retopo per the retopo+bake plan, not used as final geometry.**
- **Retopo base configured:** blockout renamed `mesh_pudge_body_lod0`; live **Shrinkwrap modifier** (`Retopo_Shrinkwrap`, NEAREST_SURFACEPOINT) targets `textured_mesh_bake_hp`; `show_in_front` on; scene snapping = FACE base + FACE_NEAREST individual projection. Ready for the artist to retopologize against the high-poly surface.
- Blender file SAVED to `anime_pudge.blend` (backup `anime_pudge.blend1`). Migration to `tools/blender/heroes/pudge.blend` happens after bake completes per pipeline §1.

The Mixamo-path artifacts (6a/6b/8a) below remain valid as fallback / partial reuse —
notably the **Stage 8a Godot integration** (tint shader + socket/hook attachment) is
rig-independent and still applies to the final rigged GLB.

---

## Stage outputs

| Stage | Doc | Status |
|---|---|---|
| 0. Brief | `design/characters/pudge_brief.md` | APPROVED |
| 1. Concept | `design/concept-art/pudge.md` | APPROVED — Silhouette B (Coiled Hook Carry) |
| 2. Model spec | `design/gdd/models/pudge.md` | APPROVED — 6,100 tris, 2 mats, apron merged, teeth as strip |
| 3. Texture spec | `design/gdd/materials/pudge.md` | APPROVED — 5 maps body, 3 maps hook, custom ShaderMaterial |
| 4. Rig + anim spec | `design/gdd/rigs/pudge.md` | APPROVED — 27 bones, 4 IK chains, 10 clips / 267 frames |
| 5. Blender pipeline | `design/gdd/asset-records/pudge_blender_pipeline.md` | APPROVED — single .blend, GLB export settings, validation script |
| 6a. Procedural body + hook (headless bpy) | `tools/blender/heroes/pudge_body_apose.glb`, `pudge_hook.glb` | DONE — A-pose, joined, ready for Mixamo |
| 6b. Mixamo handoff guide | `design/gdd/asset-records/pudge_mixamo_handoff.md` | DONE — awaiting user Mixamo round-trip |
| 7. Export validation | (`/blender-export-check` after Mixamo round-trip) | BLOCKED on user Mixamo step |
| 8a. Rig-independent integration | `src/assets/shaders/hero_body_tint.gdshader`, `src/gameplay/hero/hero_model_builder.gd` (`_apply_hero_tint`, `_setup_hero_sockets`, `_attach_hook_prop`) | DONE — active on current unrigged GLB |
| 8b. Post-Mixamo wiring | `design/gdd/asset-records/pudge_post_mixamo_checklist.md` | BLOCKED on user Mixamo step |

---

## Locked decisions snapshot

| Decision | Value | Source |
|---|---|---|
| Style | Chibi/mobile, ~3-head-tall | Brief §2 |
| Polycount LOD0 (body) | ~6,100 tris (ceiling 9k) | Model spec §2 |
| Polycount (hook prop) | 600 tris | Model spec §2 |
| Materials | 2 (`mat_pudge_body`, `mat_pudge_hook`) | Brief §7, model spec §11 |
| Body texture | 1024², 5 maps (BC, N, ORM, Emissive 256², TintMask) | Texture spec §3 |
| Hook texture | 512², 3 maps (BC, N, ORM) | Texture spec §3 |
| Body shader | Custom ShaderMaterial (tint multiply) | Texture spec §15 |
| Bones | 27 (≤45 target, ≤50 ceiling) | Rig spec §2 |
| Bind pose | A-pose (raised arm via idle anim layer) | Brief §5, concept §B |
| IK | FK baked in Blender → `SkeletonModification3DTwoBoneIK` engine-side | Rig spec §6 |
| BellyJiggle | Runtime spring (Godot), not keyframed | Pipeline §"Authoritative decision" |
| Animations | 10 clips, 267 frames @ 30 fps, in-place | Brief §4, rig spec §8 |
| Sockets | 5 (`socket_hook_hand`, `_offhand`, `_chain_origin`, `_hit_center`, `_head_top`) | Brief §6, rig spec §7 |
| LODs | LOD0 hand / LOD1-2 Decimate / LOD3 impostor | Pipeline §13 |
| Apron | Yes, merged into body mesh, blooded stub under belt | Brief §6 |

---

## File paths (target outputs)

| Asset | Path |
|---|---|
| .blend working file | `tools/blender/heroes/pudge.blend` |
| Final GLB (loaded by game) | `src/assets/models/heroes/pudge.glb` |
| Body BaseColor | `src/assets/textures/heroes/pudge/body_basecolor.png` |
| Body Normal | `src/assets/textures/heroes/pudge/body_normal.png` |
| Body ORM | `src/assets/textures/heroes/pudge/body_orm.png` |
| Body Emissive | `src/assets/textures/heroes/pudge/body_emissive.png` |
| Body TintMask | `src/assets/textures/heroes/pudge/body_tintmask.png` |
| Hook BaseColor | `src/assets/textures/heroes/pudge/hook_basecolor.png` |
| Hook Normal | `src/assets/textures/heroes/pudge/hook_normal.png` |
| Hook ORM | `src/assets/textures/heroes/pudge/hook_orm.png` |
| Body shader | `src/assets/shaders/hero_body_tint.gdshader` |
| Body material | `src/assets/materials/heroes/pudge_body.tres` |
| Hook material | `src/assets/materials/heroes/pudge_hook.tres` |

---

## Cross-stage blocker register

| # | Owner | Item | Blocks | Status |
|---|---|---|---|---|
| 1 | character-artist | Annotate `jiggle_boundary` vertex color layer on retopo | rigger weight paint | open |
| 2 | character-artist | Single combined `pudge.blend` containing body + hook | texture-artist AO bake | open |
| 3 | character-artist | Conditional: corrective blendshape `correct_leftarm_raised` if QA1 fails | rig deformation gate | conditional |
| 4 | rigger | Confirm `mesh_pudge_hook` has 100% LeftHand weight | export validation | open |
| 5 | gameplay-programmer | Confirm `hook_release` frame 6 timing & `hit_active` frame 7 timing | animation finalize | deferable to Stage 8 |
| 6 | character-artist | Rename `mesh_pudge_body` → `mesh_pudge_body_lod0` for LOD auto-detect | export validation | open |
| 7 | character-artist | Audit BellyJiggle has zero animation tracks (except in `death`) | runtime spring vs baked conflict | open |
| 8 | technical-artist | Verify Godot 4.6 `meshes/light_baking` and `gltf/embedded_image_handling` enum values | Godot import preset finalization | Stage 8 |
| 9 | technical-artist | Build custom shader for body tint multiply | material setup | Stage 8 |
| 10 | technical-artist | Add 12 animation event method tracks manually (Blender pose markers don't transfer) | event firing | Stage 8 |

---

## Remaining work

- **Stage 6 (Authoring)**: All 3D work in Blender — sculpt, retopo, UV, texture bake & paint, rig, weight paint, 10 animations. Estimated 1-3 weeks of focused work for a single skilled character artist + animator.
- **Stage 7 (Export validation)**: Run `/blender-export-check` against the authored `pudge.blend`; iterate on failures until PASS.
- **Stage 8 (Godot integration)**: technical-artist sets up shader, materials, animation events, LOD distances, team-tint shader; verifies all 11 acceptance criteria from brief §10.

---

## Acceptance criteria status (brief §10)

| # | Criterion | Status |
|---|---|---|
| 1 | `pudge.glb` imports into Godot 4.6 with no errors | PENDING (Stage 7-8) |
| 2 | Total body tris ≤ 9,000 LOD0 | SPEC OK (~6,100) |
| 3 | Material count ≤ 2 | SPEC OK (2) |
| 4 | All 10 animation clips present in AnimationLibrary | PENDING (Stage 6-7) |
| 5 | Each animation plays without obvious clipping | PENDING (Stage 6-8) |
| 6 | Feet remain at Y≈0 in locomotion clips | SPEC OK (root motion off) |
| 7 | Hook prop attached to `socket_hook_hand`, oriented forward | PENDING (Stage 7-8) |
| 8 | All 5 sockets resolve to valid bones | SPEC OK (rig §7) |
| 9 | Silhouette readable from default camera | PENDING (Stage 8) |
| 10 | All 4 LODs export and switch without pop | PENDING (Stage 6-8) |
| 11 | Per-team tint produces distinct color without bleeding | PENDING (Stage 8) |
