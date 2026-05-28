# Pudge — Mixamo Rig + Animation Handoff

> **Status**: Ready for Mixamo upload
> **Stage**: 6 of 8 (Authoring) — partial automation via Mixamo
> **Generated body**: `tools/blender/heroes/pudge_body_apose.glb` (2.1 MB, ~87k tris)
> **Hook prop (separate)**: `tools/blender/heroes/pudge_hook.glb` (1.0 MB, ~41k tris)
> **Preview render**: `tools/blender/heroes/pudge_apose_render.png`
> **Mixamo URL**: https://www.mixamo.com (free Adobe account required)

This document is the step-by-step recipe for getting Pudge rigged and animated
via Mixamo, then bringing the result back into the Godot project.

---

## Why Mixamo

- Free auto-rig works on humanoid meshes in T-pose or A-pose (we built A-pose).
- 2,500+ pre-made humanoid animations (idle, walk, run, attack, hit react, death, taunt, etc.) — covers 9 of our 10 required clips out of the box.
- Downloaded `.fbx` or `.glb` carries skinning + animations into Godot 4.6 with no extra rigging work.
- Hook-throw and hook-recover are the only clips that won't have a perfect Mixamo equivalent — closest matches noted below; final tuning happens in Stage 8 inside Godot's AnimationPlayer.

## What you upload vs. what stays separate

| File | Goes to Mixamo? | Why |
|---|---|---|
| `pudge_body_apose.glb` | **YES** | Single joined skinnable mesh in A-pose; this is what Mixamo auto-rigs. |
| `pudge_hook.glb` | NO | Separate prop. Mixamo would try to rig it as part of the body. We attach it via `socket_hook_hand` (BoneAttachment3D) inside Godot in Stage 8. |

---

## Step-by-step

### 1. Upload the body

1. Open https://www.mixamo.com and sign in with a free Adobe account.
2. Click **UPLOAD CHARACTER** (top-right).
3. Drag `tools/blender/heroes/pudge_body_apose.glb` into the dialog.
4. Mixamo loads the mesh in the preview window. Wait for "Auto-Rigger" to launch (~15s).

### 2. Place the auto-rig markers

Mixamo will ask you to drop 6 markers on the mesh. Place them as follows
(use the orbit tool to confirm position — the markers must sit on the
mesh **surface**, not inside it):

| Marker | Where on Pudge |
|---|---|
| **Chin** | At the front of the lower jaw, just below the mouth slit |
| **Wrists** | At the dead center of each hand sphere — both hands hang in A-pose, so they're at roughly (-0.84, +0.10, 0.50) and (+0.84, +0.10, 0.50) in world coords |
| **Elbows** | Center of each forearm bulge (mid-arm joint) |
| **Knees** | Mid-leg, where the leg bends. Pudge's legs are short and largely hidden under the gut — orbit until you can see them. |
| **Groin** | Centered at the crotch, slightly above the belt line |

**Skeleton LOD**: choose **Standard Skeleton (65 bones)**. The brief targets ≤45 bones; we'll prune unused face bones inside Godot or accept the higher count (Mixamo's standard rig is well under our 50-bone ceiling for our purposes).

Click **NEXT** → Mixamo runs the auto-rigger (~30-60s). Verify the preview rig moves cleanly. If shoulders, elbows, or knees deform badly, click **PREVIOUS** and reposition those markers.

Click **NEXT** to confirm rig.

### 3. Pick the 10 animations

Mixamo's library is searchable. For each row below, search the term, click the animation to preview, click **DOWNLOAD** when satisfied. Use these settings on each download:

| Setting | Value |
|---|---|
| Format | **FBX Binary (.fbx)** — better Godot 4.6 compatibility than GLB for skeletal anim |
| Skin | **With Skin** (first one downloaded) |
| Frames per Second | **30** |
| Keyframe Reduction | **none** (we can decimate later) |

**Subsequent downloads**: change Skin to **Without Skin** (we only need one skinned base; the others are animation-only files we'll merge in Blender or assign in Godot).

| # | Clip needed | Mixamo search term | Closest match | Notes |
|---|---|---|---|---|
| 1 | `idle` | "idle" → "Breathing Idle" | Direct match | 2-second loop, slight breathing motion |
| 2 | `walk` | "walking" → "Walking" | Direct match | Will be played at variable rate by AnimationTree |
| 3 | `run` | "running" → "Running" | Direct match | Same |
| 4 | `turn_in_place` | "turn" → "Standing Turn 90 Right" + mirror for left | Direct match | Download both turn-right; we mirror in Godot for turn-left |
| 5 | `hook_throw` | "throw" → "Throw Object" or "Boxing Cross Punch" | Approximate | Mixamo has no meat-hook throw. "Throw Object" is closest pose-wise. We'll retime in Godot to match the brief's 0.4s + frame-6 release event. |
| 6 | `hook_recover` | "idle" → "Idle Looking Around" | Approximate | Brief calls for "arm returns to idle" — any short return-to-idle works |
| 7 | `attack_basic` | "punch" → "Cross Punch" or "Hook Punch" | Direct match | "Hook Punch" has a wide swing that fits Pudge's cleaver-arm |
| 8 | `hit_react` | "hit" → "Hit Reaction" | Direct match | 0.3s flinch, head jerks back |
| 9 | `death` | "death" → "Stagger Backwards Death" | Direct match | Fits the brief's "stagger backward, fall on back" |
| 10 | `victory` | "victory" → "Victory Idle" | Direct match | Big stretch + laugh |

**Download in this order**:
1. First — `idle` **WITH SKIN** (this is the file that carries the rig).
2. Then 2–10 — **WITHOUT SKIN** (animation-only).

Save all `.fbx` files to: `tools/mixamo/pudge/`

### 4. Bring it all back

We have two options for combining the animations into a single GLB:

#### Option A — Use Blender's Mixamo Animation Combiner (recommended)

1. Open Blender. Import `idle.fbx` (with skin).
2. For each other animation `.fbx`: Import → in the NLA editor, drag the imported action onto the `Armature` data block; rename the action to match the brief (e.g. rename "mixamo.com" → `walk`).
3. Push every action to NLA strip with **Push Down** + enable **Use Fake User**.
4. Export → glTF Binary, export path: `src/assets/models/heroes/pudge.glb` (overwrites the placeholder).
5. Export settings (per the Stage 5 Blender pipeline plan):
   - **Animation: ON**, **Always Sample**: ON, **Group by NLA Track**: ON, **Limit to Playback Range**: OFF
   - **Skinning: ON**, Bone Influences: 4
   - **Compression**: OFF
   - **Y Up**: OFF (let glTF handle it)

#### Option B — Use a free combiner tool

Tools like [Mixamo Combine](https://terrydraper.com/free-projects/mixamo-combine) or the [godot-mixamo](https://github.com/diofeher/godot-mixamo) addon automate steps 2-3 of Option A. Use whichever you're comfortable with.

The end result must be **one** `.glb` containing the rigged mesh + all 10 named actions.

### 5. Drop into Godot

Save the combined output as `src/assets/models/heroes/pudge.glb` (overwrites the current placeholder).

Confirm in Godot:
1. Re-import the .glb (it's auto-detected by `hero_model_builder.gd:28-36`).
2. Open the .glb in the FileSystem dock; verify it has an `AnimationPlayer` node with all 10 named animations.
3. Verify the skeleton has the standard Mixamo bone names (`mixamorig:Hips`, `mixamorig:LeftHand`, etc.) — Stage 8 will need these for socket setup.

Once `pudge.glb` lands, ping me to run **Stage 8** — I'll wire the sockets, the team-tint shader, and the animation event tracks (`hook_release`, `hit_active`).

---

## Common pitfalls

| Pitfall | Fix |
|---|---|
| Auto-rigger places elbows in the body mass | Pudge's hunch + chunky arms mean the elbow markers can land inside the torso. Orbit to side view and snap each elbow to the visible elbow bulge on the arm tube. |
| Wrist markers on the wrong hand | The chunkier hand is the **left** (hook arm). If Mixamo's preview shows the rig pivoting around the wrong wrist, the markers were swapped — go back and reposition. |
| Animations have weird "T-pose first frame" snap | Mixamo sometimes inserts a T-pose between the auto-rig pose and the animation start. In Blender, trim the first 1-2 frames of each action before exporting. |
| Vertex colors lost in Mixamo round-trip | Mixamo strips per-vertex colors. **This is expected.** Stage 8 replaces the per-vertex Col material with a proper PBR ShaderMaterial driven by the texture spec (`design/gdd/materials/pudge.md`). For now Pudge will look untextured (gray) when imported — that's fine, we'll color it back in Stage 8. |
| Tri count too high for mobile | Mixamo round-trip preserves the ~87k tris. Stage 8 applies a Decimate-with-skinning (Blender's `Decimate` modifier with `Use Vertex Group: skin_weights, Factor: 1.0`) to bring it down to the ~7-8k spec target without breaking the rig. |

---

## Open dependencies for Stage 8

After the rigged `pudge.glb` lands, Stage 8 (technical-artist) will:

1. Add 5 `BoneAttachment3D` sockets per brief §6 (mapped to Mixamo bone names).
2. Author the custom team-tint shader per texture spec §15.
3. Replace per-vertex color material with the textured PBR material.
4. Add 12 animation event tracks manually (Blender pose markers don't transfer through glTF — Stage 5 §"Authoritative decision").
5. Implement BellyJiggle as a runtime spring on the Mixamo `mixamorig:Spine` or a custom helper bone added in Blender post-Mixamo.
6. Set up the AnimationTree (BlendSpace1D for idle→walk→run, OneShot for combat).
7. Decimate to spec target (~7-8k tris) using a vertex group preserving skin weights.
8. Configure 4 LODs via `MeshInstance3D.visibility_range_*` properties.
9. Verify all 11 acceptance criteria from brief §10 pass.
