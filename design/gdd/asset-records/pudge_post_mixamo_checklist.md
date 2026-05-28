# Pudge — Post-Mixamo Stage 8 Checklist

> **Status**: Half-wired. Awaiting Mixamo-rigged `pudge.glb`.
> **Stage**: 8 of 8 (Godot Integration)
> **Date**: 2026-04-28

The rig-independent half of Stage 8 is complete and currently active in
the game on the existing (unrigged) `pudge.glb`. This document is the
exact remaining work that lights up the moment the Mixamo-rigged GLB
lands at `src/assets/models/heroes/pudge.glb`.

---

## What's already wired (works on current unrigged GLB)

| Item | File | Behavior now | Behavior after Mixamo |
|---|---|---|---|
| Team-tint shader | `src/assets/shaders/hero_body_tint.gdshader` | Active. Tints skin band of vertex colors using `HeroConfig.hero_color`. | Same; will also accept TintMask texture in next iteration. |
| Tint apply on load | `src/gameplay/hero/hero_model_builder.gd` `_apply_hero_tint()` | Applied to every MeshInstance3D in the imported GLB. | Same — works on Mixamo's mesh too. |
| 5 sockets | `_setup_hero_sockets()` | Marker3D placeholders at rest-pose offsets. Gameplay can already query them by name. | Auto-detects Skeleton3D and binds each socket to its Mixamo bone via BoneAttachment3D. |
| Hook prop attach | `_attach_hook_prop()` | No-op (no `pudge_hook.glb` in `src/assets/models/heroes/` yet). | Loads hook GLB and parents it to `socket_hook_hand` (which is now bone-attached). |

## Drop-in zone (no code changes needed)

When you finish the Mixamo round-trip, do exactly these file ops — the loader picks them up automatically:

1. **Replace** `src/assets/models/heroes/pudge.glb` with the Mixamo-rigged + animated GLB.
2. **Copy** `tools/blender/heroes/pudge_hook.glb` → `src/assets/models/heroes/pudge_hook.glb` (separate prop, attaches via socket).

Run the game. Pudge should appear with:
- Mixamo skeleton + 10 named animations on its AnimationPlayer
- 5 BoneAttachment3D sockets named `socket_hook_hand`, `socket_offhand`, `socket_chain_origin`, `socket_hit_center`, `socket_head_top`
- Hook prop hanging from `socket_hook_hand`
- Team tint applied to skin

## Code-side work that requires the rigged GLB

These can't run until the rig is present. Estimated time: 1-2 hours after the GLB lands.

### 1. AnimationTree wiring  *(gameplay-programmer / technical-artist)*

Create `src/gameplay/hero/hero_animation_tree.tres` with:

- **BlendSpace1D** for locomotion (`idle` ↔ `walk` ↔ `run`), driven by horizontal velocity magnitude
- **OneShot** nodes for: `hook_throw`, `hook_recover`, `attack_basic`, `hit_react`, `death`, `victory`
- **Transition** node to handle `turn_in_place` mirroring (left vs right)

Wire it into `src/main.tscn` Player branch — replace the static MeshInstance3D node with a scene that contains MeshInstance3D + AnimationPlayer + AnimationTree.

### 2. Animation event tracks  *(technical-artist)*

Per Stage 5 §"Authoritative decision": Blender pose markers DO NOT transfer through glTF to Godot 4.6. Manually add 12 method-call event tracks in the Godot AnimationPlayer:

| Animation | Frame | Event method | Receiver |
|---|---|---|---|
| `hook_throw` | 6 (of 12) | `_on_hook_release()` | Player gameplay node — fires the projectile |
| `hook_throw` | 0 | `_on_hook_windup_start()` | Optional — anim-driven SFX |
| `attack_basic` | 7 (of 15) | `_on_attack_hit_active()` | Cleaver hitbox enable |
| `attack_basic` | 0 | `_on_attack_swing_start()` | Optional — swing SFX |
| `attack_basic` | 12 (of 15) | `_on_attack_hit_end()` | Cleaver hitbox disable |
| `walk` | 4, 12 (24-frame loop) | `_on_footstep()` | Footstep SFX |
| `run` | 3, 9 (18-frame loop) | `_on_footstep()` | Footstep SFX |
| `death` | 30 (of 45) | `_on_death_thud()` | Body-hits-ground SFX |
| `victory` | 15 (of 60) | `_on_victory_laugh()` | Laugh SFX trigger |

Use Godot's AnimationTrack right-click → "Add Method Call Track" UI.

### 3. BellyJiggle runtime spring  *(gameplay-programmer)*

Per Stage 5 locked decision: BellyJiggle is driven by a runtime spring, not keyframes (except `death`). Implement in `src/gameplay/hero/belly_jiggle.gd`:

```gdscript
class_name BellyJiggle
extends Node

@export var skeleton_path: NodePath
@export var bone_name: String = "mixamorig:Spine"  # closest Mixamo equivalent
@export var spring_strength: float = 6.0
@export var damping: float = 4.0
@export var velocity_scale: float = 0.05

var _skeleton: Skeleton3D
var _bone_idx: int = -1
var _last_pos: Vector3
var _vel: Vector3
var _offset: Vector3
var _offset_vel: Vector3

func _ready() -> void:
	_skeleton = get_node(skeleton_path)
	_bone_idx = _skeleton.find_bone(bone_name)
	_last_pos = _skeleton.global_position

func _physics_process(delta: float) -> void:
	if _bone_idx == -1: return
	var pos := _skeleton.global_position
	_vel = (pos - _last_pos) / delta
	_last_pos = pos
	# Spring physics: target offset = -velocity * scale, restoring force toward 0
	var target := -_vel * velocity_scale
	var force := (target - _offset) * spring_strength - _offset_vel * damping
	_offset_vel += force * delta
	_offset += _offset_vel * delta
	# Apply as a position offset on the bone pose (additive to anim)
	var pose := _skeleton.get_bone_pose(_bone_idx)
	pose.origin += _offset
	_skeleton.set_bone_pose_position(_bone_idx, pose.origin)
```

Note: Mixamo's standard skeleton doesn't have a dedicated belly bone. Either retarget jiggle onto `mixamorig:Spine` (closest match) for an approximate effect, or insert a custom `BellyJiggle` bone in Blender as a child of `Spine` after the Mixamo round-trip and re-export.

### 4. Decimate to spec budget  *(blender-specialist / technical-artist)*

Mixamo round-trip preserves the ~87k tris from the procedural source. Brief targets ≤9k LOD0. After Mixamo, in Blender:

1. Open the Mixamo-rigged GLB in Blender.
2. Select the body mesh.
3. Add **Decimate (Collapse)** modifier with `ratio = 0.10` (87k → 8.7k).
4. **CRITICAL**: in modifier panel, set **Vertex Group** to the auto-generated `Group` (Mixamo's bind weight container) with **Factor = 1.0** — this preserves topology where skin weights are concentrated.
5. Apply modifier.
6. Re-export GLB to `src/assets/models/heroes/pudge.glb`.

Verify in Godot: animations still play without skin tearing.

### 5. LOD setup  *(technical-artist)*

Godot 4.6 supports auto-LOD generation on `MeshInstance3D` via `visibility_range_*` properties. In the imported scene, on the body MeshInstance3D:

| Property | Value | Notes |
|---|---|---|
| `visibility_range_begin` | 0 | LOD0 active from camera origin |
| `visibility_range_begin_margin` | 0 | |
| `visibility_range_end` | 80 | switch to LOD1 at 80m |
| `visibility_range_end_margin` | 5 | 5m fade band |
| `mesh.lod_count` | 4 | LOD0 + 3 generated LODs (handled by `meshes/generate_lods=true` in import preset) |

Already enabled: `pudge.glb.import` has `meshes/generate_lods=true`. Should "just work" once the Mixamo GLB lands.

### 6. Acceptance criteria check  *(qa-tester)*

Run all 11 criteria from `design/characters/pudge_brief.md` §10 against the integrated result. Update `design/gdd/asset-records/pudge.md` "Acceptance criteria status" table.

---

## Mixamo bone-name reference

The socket spec (`src/gameplay/hero/hero_model_builder.gd:HERO_SOCKETS`) targets these Mixamo bones. If your Mixamo download uses different names, update the `bone` field in `HERO_SOCKETS`.

| Socket | Mixamo bone | Brief intent |
|---|---|---|
| `socket_hook_hand` | `mixamorig:LeftHand` | Hook prop spawn + chain anchor |
| `socket_offhand` | `mixamorig:RightHand` | Cleaver / secondary attack |
| `socket_chain_origin` | `mixamorig:Spine2` | Visual fallback if hand offscreen |
| `socket_hit_center` | `mixamorig:Spine1` | Damage VFX |
| `socket_head_top` | `mixamorig:Head` | Status icons |

If the Mixamo download uses unprefixed names (`Hips`, `LeftHand`, …), strip the `mixamorig:` prefix in `HERO_SOCKETS` and the loader will rebind on next play.

---

## Validation steps when the Mixamo GLB lands

1. Import the new `pudge.glb` in Godot. Verify no import errors.
2. Open the imported scene in the FileSystem dock — confirm presence of:
   - `Skeleton3D` with bones (≥40 expected)
   - `AnimationPlayer` with 10 named animations
3. Run the game. Verify:
   - Pudge spawns and is tinted his team color
   - Console has no `bone X not found` warnings (means `HERO_SOCKETS` bone names match)
   - Hook prop appears on his left hand
4. Switch to Player1, walk around — `walk` animation should play (gameplay code can call `AnimationTree.set("parameters/locomotion/blend_position", velocity.length())` once AnimationTree is wired).
5. Run `/blender-export-check` against the source `.blend` if you used Option A from the Mixamo handoff.
6. Tick off acceptance criteria in `design/gdd/asset-records/pudge.md`.

---

## Rollback

If the Mixamo round-trip produces an unusable GLB, restore the unrigged version: the existing pre-Mixamo `pudge.glb` works with the new tint shader and Marker3D sockets. Game stays playable; we just lose the animation upgrade.
