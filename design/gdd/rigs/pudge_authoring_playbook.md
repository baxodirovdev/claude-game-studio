# Pudge — Rig Authoring Playbook

> **Status**: ACTIVE — rigger working document
> **Hero ID**: `pudge`
> **Date**: 2026-05-21
> **Author**: `rigging-animator` agent
> **Governs**: `design/gdd/rigs/pudge.md` (Stage 4 spec — the contract)
> **Source mesh**: `src/assets/models/heroes/anime_pudge.blend` (`textured_mesh`, 40k tris, AI-generated)
> **Retopo plan**: `design/gdd/models/pudge_retopo_bake_plan.md` (being authored by character-artist — read before rigging begins)
> **Rig spec**: `design/gdd/rigs/pudge.md` — this playbook is a how-to companion, NOT a replacement. Do not contradict the spec.

This playbook translates the Stage 4 rig spec into concrete Blender procedures, accounts for the specific geometry source (a 40k-tri AI-generated chibi mesh being retopologized to ~6,100 tris), and sequences work so that blockers are resolved before they cost time.

---

## 1. Rig Spec Validity Assessment

### Does the 27-bone spec still hold for the AI-derived mesh?

**Yes, with one targeted revision.** The skeleton hierarchy, bone names, bone count, IK chain count, socket definitions, and all 10 animation clips are fully valid for the AI-derived chibi mesh. The AI mesh is chibi/stylized with pig/boar face, stitched belly, and fused hook — exactly the character the spec was written for. The retopology strategy ("retopo to spec + bake") deliberately targets the same 6,100-tri count and proportions the spec already assumes.

**What must change: bone Y-positions.**

The spec's bind-pose Y-position table (pudge.md §2, "Key Bone Positions in Bind Pose") was derived from `hero_model_builder.gd:58-230` primitive geometry coordinates, then scaled to the 1.4 m height target. Those values are estimates. The AI mesh has real anatomy — a different belly sphere radius, leg length, and skull dome height than the primitive approximation. After retopo, the rigger must re-fit every bone Y-position to the actual mesh rather than using the spec's table values verbatim.

**All angles in the bind-pose rotation table remain valid.** The spine hunch (+5/+5/+5 degrees), shoulder angles, and foot tilt are defined by character design intent, not mesh geometry, so they do not change.

---

## 2. Bone-Fitting Procedure (How to Place Bones on the Retopo'd Mesh)

Perform this step after the character-artist delivers `mesh_pudge_body` with `jiggle_boundary` vertex color (Blocker A — see Section 5). Do not begin bone placement on the AI mesh; work only on the final retopo.

### Pre-fitting setup

1. Open `anime_pudge.blend`. Confirm `mesh_pudge_body` and `mesh_pudge_hook` are present as separate objects with transforms applied (scale 1,1,1; location 0,0,0).
2. Set the viewport to front orthographic (Numpad 1). All Y-fitting happens in this view.
3. Confirm boot soles are touching Y=0. If not, move the mesh, then apply location before proceeding.
4. Add the armature (`Shift+A → Armature`). Name the armature object `arm_pudge`. Name the first bone `Hips` immediately.

### Bone placement — region by region

Work top-down through the spec hierarchy. For each bone: place the head (joint pivot) at the anatomical center of the joint, tail pointing toward the child joint.

**Hips**
- Side view: place Hips head at the horizontal centerline of the pelvis mass — the widest left-right extent of the hip geometry, roughly at the junction where the belly sphere terminates and the upper leg cylinders begin. On the AI-derived chibi mesh, expect this to be lower than 0.30 m because Pudge's leg stubs are short. Measure the actual Y and record it — this is your fitted Hips Y.
- Front view: Hips head sits at X=0, Z=0 (world center). Hips tail points straight up to where Spine begins.

**Spine / Spine1 / Chest**
- Spine: place at the base of the belly mass — where the gut dome merges into the torso above the pelvis.
- Spine1: place at the belly equator — the maximum forward protrusion point of the gut sphere (use the side view; it is the forward-most vertex ring). The BellyJiggle bone will be a child here, so exact placement matters for belly physics.
- Chest: place at the upper chest, where the torso narrows before the neck stub. On the AI mesh this is where the shoulder mass begins. Verify Chest Y is at or above the LeftArm / RightArm bones (shoulders attach at Chest height per spec §1).
- The three spine bones should divide the torso into roughly equal thirds vertically. If the belly is very large relative to total height (likely on this chibi mesh), Spine1 will be the longest segment.

**Neck / Head**
- Neck: the AI mesh has a fused-trapezius no-neck. Place the Neck bone head directly at the base of the skull, where the trapezius shoulder mass transitions into the skull geometry. Neck bone will be very short — this is correct per model spec §2.
- Head: place at the skull center (approximate geometric centroid of the skull volume in side view). Head tail points to the top of the skull dome. Record Head Y.
- Jaw: place at the lower jaw hinge — the rear-most point of the lower jaw geometry, behind the tooth row. Set the initial rotation to closed (X rotation = 0). The spec offset of (0.0, -0.10, +0.05) in Head local space is a starting approximation; adjust to fit the AI mesh's actual jaw hinge anatomy.

**Shoulders / Arms / Hands**
- LeftShoulder / RightShoulder: place at the top of the shoulder cap, where the arm geometry begins to separate from the torso. The AI mesh arm is fused; the character-artist's retopo will define the actual shoulder socket loop position. If that retopo has not been delivered yet, defer arm bone placement.
- LeftArm / RightArm: shoulder joint pivot. This is the ball-joint center — use the center of the shoulder socket loop. On a chibi mesh expect this to be very close to Chest Y.
- LeftForeArm / RightForeArm: elbow pivot. Place at the center of the elbow loop.
- LeftHand / RightHand: wrist pivot. Place at the center of the wrist loop, not at the fingertip. The hand tail points toward the knuckle geometry.

**A-pose arm separation — critical step before binding**

The AI mesh has the arms fused to the body with no separation at the armpit. The character-artist will retopologize the arms as separated geometry. However, even after retopo the armpit area on a chibi mesh tends to be very tight. Before binding (but after bone placement):

- Enter Edit Mode on `mesh_pudge_body`.
- Confirm at least 2-3 cm of visible gap between the inner arm surface and the lateral torso surface in the armpit region. If the geometry is touching or nearly touching, flag to the character-artist before binding — painting weights through a zero-gap armpit produces bleeding artifacts in the raised-arm pose (QA1).
- If the retopo gap is insufficient: do not retopo-fix it yourself (that is character-artist domain). Instead, in Pose Mode, rotate LeftArm and RightArm to 30 degrees outward (Z-axis) to open the armpit, then apply the armature as a visual reference for the character-artist. Document the required gap in a Blender text block note named `RIGGER_NOTES`.

**ChainLink1-4**
- Place after LeftHand is positioned. ChainLink1 head starts at the LeftHand palm center.
- Use the spec offsets from pudge.md §4.3 as starting values: each link droops slightly downward and slightly inward. Adjust so the chain appears to drape naturally toward the belt coil in the bind A-pose.
- These bones do not need to match any mesh geometry precisely — they drive the separate chain link meshes (each chain link mesh will be weighted 100% to its corresponding ChainLink bone).

**BellyJiggle**
- Parent to Spine1 immediately after placing Spine1.
- Place the BellyJiggle head at the Spine1 origin. The tail extends +Z (forward in Spine1 local space — toward the belly protrusion) by approximately 0.20 m.
- Verify in the side view that the BellyJiggle tail points directly at the belly equator surface. Adjust if the AI mesh belly has a different depth than the 0.20 m spec estimate.

**Legs / Feet**
- LeftUpLeg / RightUpLeg: place at the hip socket center, where the upper leg cylinder connects to the pelvis. On chibi geometry, this is very close to the Hips bone head — expect a gap of 5-8 cm, not 15-20 cm as on a realistic character.
- LeftLeg / RightLeg: knee pivot at the center of the knee loop. Chibi legs are very short; the knee may be almost at boot height.
- LeftFoot / RightFoot: ankle pivot. Place at the ankle loop center. Foot tail points forward (-Z in world space) toward the boot toe. Boot soles must already be at Y=0 before fitting.

### Fitted Y-position record

After fitting, record the actual bone head Y-positions in the Blender text editor (create a text block named `BONE_FITTED_Y`). These replace the spec's derived values for any downstream reference. The spec's Y table remains as design intent; this record is the actual Blender result.

---

## 3. Skinning Order and Method

### Step 0 — Before binding, confirm all blockers

Do not bind until:
- Blocker A is resolved (jiggle_boundary vertex color present on mesh — see Section 5).
- Blocker C is resolved (mesh_pudge_hook exists as a separate object).
- The A-pose armpit gap is confirmed adequate.
- All transforms are applied on both mesh objects and on arm_pudge.

### Step 1 — Parent with Automatic Weights

Select `mesh_pudge_body`, then Shift-select `arm_pudge`. Ctrl+P → "With Automatic Weights."

Blender's Automatic Weights algorithm uses bone heat to assign initial weights. On the AI-derived chibi mesh the following automatic weight problems are expected and must be manually corrected:

| Region | Expected auto-weight failure | Cause |
|---|---|---|
| Belly | BellyJiggle will receive little or no influence (heat misses helper bones) | BellyJiggle is forward-offset; heat algorithm favors bone-center proximity |
| Armpits | LeftShoulder / LeftArm weights will bleed across the inner arm gap | Chibi arms are close to body; heat has no gap to separate them |
| Neck stub | Neck bone will receive almost no influence; weights will skip to Head | The bone is too short for meaningful heat coverage |
| ChainLink1-4 | Chain bones will receive body weights from the nearby hand/wrist geometry | Chain bones are small and near the hand |
| Jaw | Jaw bone may receive partial Neck or Head weights; will not cleanly isolate lower jaw | The lower jaw geometry is very close to the Neck stub |

### Step 2 — Per-region manual corrections (work in this order)

**1. Feet and boots first.**
Lock the foot geometry to LeftFoot / RightFoot at 100%. These are the simplest region — correct any auto-weight bleed from LeftLeg into the boot sole. Boot soles must be 100% LeftFoot / RightFoot with zero Hips contribution. This establishes the IK foot lock baseline.

**2. Legs.**
Apply the 2-loop blend strategy from spec §5 at each knee: 2 loops above the knee joint transition from UpLeg (100%) to Leg (0%); 2 loops below transition from Leg (100%) to UpLeg (0%); center loop 50/50. Verify QA3 pose (squat waddle extreme) after this step before moving on.

**3. Hips and pelvis.**
Hips receives 100% on the core pelvis mass. The transitions into LeftUpLeg and RightUpLeg follow the same 2-loop strategy. Confirm no boot geometry is touched by the Hips bone.

**4. Belly — use jiggle_boundary layer.**
This is the most sensitive region. Use the `jiggle_boundary` vertex color layer delivered by the character-artist as a direct weight-paint reference:
- In Weight Paint mode, select the BellyJiggle bone.
- Manually paint: red pixels on the jiggle_boundary layer = 0.8 weight (max influence per spec §5 = 80%); white pixels = 0.0 weight.
- Keep Spine1 at minimum 20% on the belly equator ring (cap BellyJiggle at 0.8 there).
- Zero out Hips and Spine contributions on the equator ring — only Spine1 and BellyJiggle may influence the equator.
- Verify BellyJiggle has zero influence on any region tagged white in the jiggle_boundary layer.

**5. Spine / Spine1 / Chest — broad blend for waddle.**
Follow spec §5 blends: Spine transitions from Hips (40%) at lower belly, increasing to Spine (60%) at mid-belly; Spine1 at 80% on the equator zone (after BellyJiggle is already set). Do not fight the BellyJiggle weights — lock BellyJiggle verts and paint Spine1 / Spine around them.

**6. Neck stub — rigid to Head.**
Given the AI mesh's fused trapezius, the Neck bone covers almost no unique geometry. Zero out auto-weights on Neck. Assign the skull-to-trapezius transition zone directly to Head (60%) and Chest (40%) in the transition ring. The Neck bone will animate with near-zero rotation; it does not need strong influence.

**7. Head and Jaw.**
Head: 100% on the skull dome. Transition from Chest into Head over the 1-2 loop neck stub region.
Jaw: use the jaw hinge loop as the boundary. Geometry above the hinge → 100% Head. Geometry below the hinge (the lower jaw mass, lower teeth row) → 100% Jaw. No blending at the hinge itself — the jaw pivot is a hard boundary for this character.

**8. Right arm chain (cleaver arm — lower deformation risk).**
Follow the 2-loop elbow and 2-loop wrist blends per spec §5. Verify QA2 equivalent for the right arm (cleaver swing arc — 0 to -70 degrees Z-axis on RightArm).

**9. Left shoulder and arm (hook arm — highest risk, do last on arms).**
This is the most complex skinning region. The AI mesh had the arm fused; after retopo the armpit is narrow. Strategy:
- LeftShoulder: 100% on the top-of-shoulder cap.
- LeftShoulder / LeftArm blend: 4-loop transition zone (spec §5) — 50/50 at the mid-shoulder loop.
- LeftArm: 100% at 2 loops below the shoulder joint.
- LeftForeArm / LeftHand: same 2-loop blend as right side.

After painting, immediately run QA1 (raised hook arm 45 degrees above horizontal). If pinching: pause. Attempt to fix with weight adjustments over the 4-loop zone before requesting a corrective blendshape. If the pinch persists after 2 iterations of weight adjustment, file Blocker B per spec §14 — flag to character-artist with a screenshot of the pinch frame and angle.

**10. ChainLink1-4.**
Zero out all body weights on the 4 chain link mesh objects first (they are separate island geometry merged into mesh_pudge_body — select those faces in weight paint mode). Then assign each chain link's faces 100% to their corresponding ChainLink bone. No blending between chain bones.

**11. mesh_pudge_hook.**
Repeat: 100% LeftHand, zero on all other bones. Verify by selecting `mesh_pudge_hook`, entering Weight Paint, selecting every bone in turn, and confirming zero influence except on LeftHand. Document this confirmation as a comment in the Blender text block `RIGGER_NOTES`. This is Blocker C resolved.

### Step 3 — Normalize weights

After all manual passes: in Object Data Properties → Vertex Groups → "Clean" (remove zero weights), then Ctrl+A → Normalize All. Verify max influences per vertex stays at 4. In the Weights tab, run "Limit Total" with maximum 4 before export.

---

## 4. Clip Authoring Order

All clips share one reference pose: the Silhouette B idle raised-arm pose (left arm raised, hook at shoulder height). Author `idle` first — it is the reference from which every other clip starts and ends.

### Phase 1 — Foundation clips (author first; everything depends on these)

**1. idle (60 frames)**
This is the most important clip. It defines the Silhouette B reference pose at frame 0 and frame 60. All non-looping clips must end in a pose that blends cleanly into `idle`. Author the breathing cycle (frames 0-40) and the hook twitch (frames 40-55) before moving on. Loop-match frames 0 and 60 exactly before proceeding.

The Silhouette B pose established at frame 0 of `idle` becomes the shared "return pose" for all action clips. Screenshot it and save as `idle_frame0_reference.png` in the Blender project folder for reference during all subsequent clip authoring.

**2. walk (24 frames)**
Author second. The walk cycle establishes the hip-waddle amplitude and foot-contact timing that `run` scales from. Author the full heel-strike-to-heel-strike half-cycle and loop-match frame 24 = frame 0. Foot contacts at F0 (left) and F12 (right) are the footstep event frames — do not adjust these timings after authoring without notifying the gameplay-programmer.

**3. run (18 frames)**
Derives from `walk`: increase hip sway amplitude (12-14 degrees vs. 8-10 degrees), increase Spine1 forward pitch by 3 degrees, tighten the foot contact interval. Foot contacts at F0 (left) and F9 (right). Loop-match frame 18 = frame 0.

### Phase 2 — Hook ability clips (author as a pair)

**4. hook_throw (12 frames)**
Begin from the idle Silhouette B pose at frame 0. The frame 6 `hook_release` event is load-bearing — the gameplay-programmer spawns the hook projectile at exactly this frame using the socket_hook_hand transform. Before finalizing, confirm the event frame with the gameplay-programmer (Q1 in spec §14). The ChainLink1-4 pay-out animation from frame 3-6 must be authored explicitly in this clip (not left to the spring constraint). Freeze ChainLink bones at frame 8.

**5. hook_recover (9 frames)**
Author immediately after hook_throw. Frame 0 of hook_recover must match frame 12 of hook_throw exactly — copy-paste the frame 12 pose into hook_recover frame 0. Frame 9 must match the idle Silhouette B pose (frame 0 of idle). Verify the pose match by overlaying the two clips in the Blender NLA editor.

The hook_throw → hook_recover chain is the only two-clip sequence in the set where the end-of-clip-A must exactly equal the start-of-clip-B. This is more strict than the general "must blend cleanly into idle" requirement. A mismatch here will produce a visible pop in the hook ability gameplay loop.

### Phase 3 — Combat clips

**6. attack_basic (15 frames)**
Cleaver swing on the right arm. Frame 0 and frame 15 both hold the idle Silhouette B pose with the left arm raised. The left arm does not move in this clip — it holds position throughout. The `hit_active` event at frame 7 must be confirmed with the gameplay-programmer before the clip is locked (Q2 in spec §14, hitbox shape question).

**7. hit_react (9 frames)**
Sharp flinch starting from idle Silhouette B. BellyJiggle is keyframed explicitly in this clip (forward-slosh at frame 3, returns to 0 by frame 9) — do not leave it to the spring modifier. Frame 0 = idle pose; frame 9 = idle pose.

### Phase 4 — Bookend clips

**8. turn_in_place (15 frames)**
Author one clip (left turn). Frames 0 and 15 hold the Silhouette B idle pose. The gameplay-programmer must confirm whether AnimationTree mirroring is used or a second clip is needed before this clip is considered final (Q3 in spec §14).

**9. victory (60 frames)**
Looping celebratory clip. Jaw animates in this clip (laugh cadence, frames 15-40). BellyJiggle is augmented with explicit keyframes at frames 20, 25, 30 to sync the belly shudder with the torso pulse. Frame 60 = frame 0 (idle Silhouette B pose). Author this late because it reuses range-of-motion tested in idle and hook_throw (arm raises higher than idle in victory).

**10. death (45 frames) — author last**
The most complex clip. Author this last because it tests the full-body deformation and belly deflate — both of which require QA4 (death sprawl test pose) to already be passing from the weight-paint phase. The spring modifier must be disabled (weight 0) during death — use an animation layer override. BellyJiggle is keyframed for the deflate in Phase 5 (frames 38-45). If a `death_deflate` blendshape was authored by the character-artist, use it here instead of the bone-driven approach; it is more reliable for a held, timed deformation. Jaw animates in this clip (opens on Phase 1 stagger, held open through impact, limpening close in Phase 4 settle).

The three death event markers (death_begin F8, death_thud F23, death_deflate_start F38) must all be present before the clip is handed off.

### Clip authoring dependency graph

```
idle
  └── walk
        └── run
  └── hook_throw
        └── hook_recover
  └── attack_basic
  └── hit_react
  └── turn_in_place
  └── victory
  └── death (requires QA4 weight-paint pass first)
```

All action clips (hook_throw, attack_basic, hit_react) share the idle Silhouette B pose as their frame 0 and return pose. Author idle first and do not change its frame 0 pose after other clips are started — changing the idle reference pose after the fact invalidates the frame 0 and return poses of all downstream clips.

---

## 5. Blender-to-Godot Export Checklist

Perform this checklist in order before handing off to the blender-specialist. The blender-specialist runs the `blender-export-check` skill at `/tools/blender/` as the final gate — these steps prepare the file to pass that check.

### Pre-export preparation

- [ ] All 10 clips exist as Blender Actions named exactly: `idle`, `walk`, `run`, `turn_in_place`, `hook_throw`, `hook_recover`, `attack_basic`, `hit_react`, `death`, `victory` — snake_case, no pudge_ prefix, no suffix.
- [ ] Each Action has been pushed to an NLA strip in the NLA Editor. No Actions are left floating (stash or push down all).
- [ ] IK bake completed: for every clip, select all bones with IK constraints (LeftArm chain, RightArm chain, LeftLeg chain, RightLeg chain), run `Pose → Animation → Bake Action` with `Visual Keying` enabled. This bakes IK results to FK keyframes. If you did this per-clip during authoring, verify the baked FK tracks are present in the NLA strip.
- [ ] Blender IK constraints removed or muted on the armature after bake — they must not be active during export (they are ignored by GLTF but can cause confusion in the export log).
- [ ] ChainLink spring constraints (Damped Track) baked to FK keyframes for all clips. Constraints removed or muted.
- [ ] BellyJiggle spring constraints (if any Blender constraint was used for authoring) baked and removed. The spring runs at runtime in Godot, not in the GLTF.

### Transform verification

- [ ] `arm_pudge`: Location (0,0,0), Rotation (0,0,0), Scale (1,1,1) in Object Mode.
- [ ] `mesh_pudge_body`: same. Apply transforms if not already at unity.
- [ ] `mesh_pudge_hook`: same.
- [ ] Boot soles of `mesh_pudge_body` touch Y=0 with no gap. Verify in front orthographic with the mesh selected.
- [ ] Pudge's forward face (belly, hook arm) points toward -Z world. Verify in top orthographic.
- [ ] Total height from boot sole (Y=0) to skull top: within the 1.33-1.47 m range (1.4 m target ±5%).

### Weight paint final checks

- [ ] Run `Mesh → Weights → Limit Total` (max 4 influences) on both `mesh_pudge_body` and `mesh_pudge_hook`. Zero vertex count in the result.
- [ ] Run `Mesh → Weights → Normalize All` on both meshes.
- [ ] `mesh_pudge_hook` has 100% LeftHand weight. Verify by selecting `mesh_pudge_hook`, entering Weight Paint, cycling through all bones. Only LeftHand has non-zero influence. Record confirmation in Blender text block `RIGGER_NOTES` (Blocker C resolved).
- [ ] BellyJiggle influence does not exceed 0.8 on any vertex (80% cap from spec §5). Run a vertex weight check if Blender supports it, or spot-check the equator ring manually.
- [ ] No vertex on `mesh_pudge_body` has zero total weight (all vertices assigned to at least one bone). Run `Select → Select All By Vertex Group → (none)` to check.

### GLTF export settings

Use File → Export → glTF 2.0 (.glb). Settings:

| Setting | Value |
|---|---|
| Format | GLB (binary, embedded) |
| Include → Selected Objects | Off (export scene) |
| Include → Visible Objects | On |
| Transform → Y Up | On |
| Geometry → Apply Modifiers | On |
| Geometry → UVs | On |
| Geometry → Normals | On |
| Geometry → Vertex Colors | On (preserves jiggle_boundary if needed) |
| Armature → Export Deformation Bones Only | Off (include ChainLink, BellyJiggle, Jaw helper bones) |
| Armature → Rest & Ranges → Export current frame | Off |
| Animation → Export | On |
| Animation → Mode | Actions (NLA) |
| Animation → Export NLA Strips | On |
| Animation → Export all Armature Actions | On |
| Animation → Group by NLA Track | Off |
| Animation → Force Sampling | On (ensures baked curves survive export) |

Output file: `src/assets/models/heroes/pudge.glb` (overwrites the current placeholder per model spec §10).

### Post-export Godot import verification

After import into Godot 4.6:
- [ ] The scene tree contains a `Skeleton3D` node named `Skeleton3D` with all 27 bones visible in the bone list.
- [ ] An `AnimationPlayer` node is present with an `AnimationLibrary` containing all 10 clip names exactly as specified.
- [ ] Play each clip in the Godot AnimationPlayer preview and verify: no T-pose default, no axis flip (belly faces -Z camera direction), no scale jump on import (model appears at ~1.4 m height).
- [ ] `mesh_pudge_hook` appears as a separate `MeshInstance3D` node, not merged into the body mesh.
- [ ] The `AnimationPlayer` clip named `idle` loops (check the loop icon in the Godot editor or the AnimationPlayer's `loop_mode` property — set to `LOOP_LINEAR` or `LOOP_PINGPONG` depending on project preference; confirm with technical-artist).
- [ ] Verify clip durations match spec: `idle` 2.0 s, `walk` 0.8 s, `run` 0.6 s, `turn_in_place` 0.5 s, `hook_throw` 0.4 s, `hook_recover` 0.3 s, `attack_basic` 0.5 s, `hit_react` 0.3 s, `death` 1.5 s, `victory` 2.0 s.

---

## 6. Dependencies on the Character-Artist

### Blocker A — jiggle_boundary vertex color (BLOCKING for weight paint)

The rigger cannot begin belly weight painting until `mesh_pudge_body` is delivered with a vertex color layer named `jiggle_boundary`. The layer must be present before the Ctrl+P "With Automatic Weights" step — the layer is used during the manual correction pass immediately after auto-weights.

Required annotation specification:
- Color = red (R=1.0, G=0.0, B=0.0) on the belly equator ring and all forward-facing rings below the equator.
- Color = white (R=1.0, G=1.0, B=1.0) at the torso-join loops above the equator and at the hip-pelvis join loops below.
- Interpolation: linear gradient across the transition rings between red and white.
- Layer name: exactly `jiggle_boundary` (case-sensitive; the rigger's weight paint workflow references this name).

The AI mesh (`textured_mesh`) has no such annotation. This annotation must be authored during the retopo pass, not on the AI source mesh.

### Blocker B — corrective blendshape for left shoulder raise (CONDITIONAL)

If QA1 (raised hook arm 45 degrees, spec §5) reveals pinching that cannot be resolved by weight adjustment alone, the rigger will file this blocker with:
- A screenshot of the pinch, labeled with the bone angle and the region.
- The weight values tried in the 4-loop transition zone.

The character-artist must then author a corrective blendshape named `correct_leftarm_raised` on `mesh_pudge_body` in Blender. The blendshape is driven by the LeftArm bone's Z-axis rotation (driver range: -30 degrees = 0.0 value; +45 degrees = 1.0 value). The rigger sets up the ShapeKey driver in Blender.

Status: TBD after QA1 test. The AI mesh's chibi arm proportions may actually reduce this risk (short upper arms deform less than realistic proportions). Do not author the blendshape preemptively.

### Blocker C — separate mesh_pudge_hook with 100% LeftHand weight (BLOCKING for skinning)

`mesh_pudge_hook` must exist as a separate Blender object before the rigger can complete the skinning step. The AI source mesh has the hook fused into the body — the character-artist must model a fresh `mesh_pudge_hook` as part of the retopo handoff.

The hook mesh must:
- Be a separate Blender object named `mesh_pudge_hook`.
- Have transforms applied (scale 1,1,1; location 0,0,0).
- Have its own material slot assigned to `mat_pudge_hook`.
- Carry a clean UV unwrap on the 512x512 hook atlas.
- Have 100% weight painted to LeftHand with zero weight on all other bones (the rigger performs this weight step, but the character-artist must deliver the mesh as a separate object first).

### Additional dependency — deformation loops at joints

The AI mesh has 40k tris and complex geometry, but the retopologized mesh is new geometry. The rigger depends on the character-artist delivering the minimum loop counts from model spec §2:
- Left shoulder socket: 4 loops minimum.
- Right shoulder socket: 3 loops minimum.
- All elbows, knees: 3 loops each.
- Hip pelvis: 4 loops.

If any joint has fewer loops than the minimum, the rigger must flag it before weight painting — a 2-loop elbow will fail QA2 and adding loops after weight painting is done requires a full weight repaint of that region.

---

## 7. Open Questions for Gameplay-Programmer

The following questions from spec §14 remain unresolved and must be answered before the clips that depend on them are finalized. The rigger should not lock those clips until answers are received.

**Q1 — hook_release frame timing (blocks hook_throw finalization)**
Frame 6 of `hook_throw` is the `hook_release` event. Confirm: does the gameplay system read this event from an AnimationPlayer signal track, or does it poll the animation frame each physics tick? If polling, the effective spawn may be delayed by up to one physics frame (16 ms at 60 Hz). The rigger can shift the event by ±1 frame if needed — but the clip must be re-exported if the frame changes. Answer needed before hook_throw is pushed to NLA.

**Q2 — hit_active frame timing and hitbox shape (blocks attack_basic finalization)**
Frame 7 of `attack_basic` is the `hit_active` event. Confirm: is the hitbox a static sphere at `socket_offhand` position at frame 7, or is it a swept volume across multiple frames (e.g., frames 5-9)? If swept, the animator needs the sweep arc to design the cleaver swing to pass through the expected hit zone correctly. This changes the arm swing trajectory.

**Q3 — turn_in_place mirror implementation (blocks turn_in_place finalization)**
The spec authors one left-turn clip and assumes the AnimationTree mirrors it for right turns. If two separate clips (`turn_left`, `turn_right`) are required instead, the authoring plan and the NLA Action list must be updated before NLA strips are finalized. Confirm before turn_in_place is started.

**Q4 — run canonical speed (blocks BlendSpace1D calibration — not a blocker for clip authoring)**
Confirm the maximum character movement speed from the player controller config. The run clip is authored assuming 14 m/s canonical speed. If the actual value differs, the BlendSpace1D thresholds in Stage 8 must be adjusted — the clip itself does not need to be re-exported.

**Q5 — BellyJiggle spring modifier implementation (blocks animation authoring strategy)**
This is the most workflow-impactful open question. If the gameplay-programmer confirms that a runtime `SkeletonModifier3D` spring will drive BellyJiggle, the animator leaves BellyJiggle unanimated in `idle`, `walk`, `run`, `turn_in_place`, `hook_throw`, `hook_recover`, `attack_basic`, and `victory` (spring handles it). Only `death` and `hit_react` keyframe BellyJiggle explicitly.

If the gameplay-programmer requires baked keyframes instead (no runtime spring), the animator must add BellyJiggle keyframes to all 10 clips — significant additional work. This decision must be made before any clip enters the bake-to-FK step, because baking with an active spring constraint vs. without produces different keyframe data.

---

*End of Pudge Rig Authoring Playbook. This document is a working companion to the Stage 4 spec at `design/gdd/rigs/pudge.md`. The spec is the contract; this playbook is the procedure. Any contradiction between the two documents is resolved in favor of the spec — update the playbook, not the spec.*
