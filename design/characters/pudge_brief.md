# Pudge — Character Production Brief

> **Status**: Approved — ready for production
> **Hero ID**: `pudge`
> **Pipeline**: `/team-3d-asset` full pipeline
> **Last Updated**: 2026-04-28
> **Replaces**: `src/assets/models/heroes/pudge.glb` (placeholder block-out)
> **Reference**: `src/assets/models/heroes/pudge.stl` (sculpt silhouette ref)

---

## 1. Identity

**Pudge — The Chain Puller.** A bloated, stitched-together butcher who lives at
the edge of the brawl, lobbing a meat hook to drag enemies into his cleaver range.
Slow but tanky. Reads as **menacing but goofy** — the chibi proportions tip
sinister into comic.

**Hook archetype**: `PULL` — straight-line chain, drags target to Pudge.
**Hero color**: green skin, `Color(0.5, 0.8, 0.2)`.
**Personality cues**: deranged asymmetric eyes (one larger), hunched shoulders,
gut hangs forward, drags hook arm low.

## 2. Style Target — Chibi / Mobile

| Attribute | Target |
|---|---|
| Proportions | ~3-head-tall (chibi). Head is ~30% of total height. |
| Silhouette | Wide round torso, stubby limbs, big head, oversized hook hand |
| Polycount (body) | **6,000–8,000 tris** (LOD0). Hard ceiling 9k. |
| Polycount (hook prop) | 500–800 tris (LOD0) |
| Texture style | Hand-painted PBR — flat base color carries the look, normal/roughness add subtle grime |
| Texture resolution | **1024×1024** body atlas, **512×512** hook prop |
| Texel density | 256 px/m on body, 512 px/m on face |
| Material count | 1 body material + 1 hook prop material (max 2 draw calls) |
| LODs | LOD0 (full), LOD1 (~50%), LOD2 (~25%), LOD3 (impostor/billboard) |

**Style anchors**: Brawl Stars brawler proportions × Dota 2 Pudge personality.
Read clearly at 1080p from a top-down camera ~12m away.

## 3. Visual Design (carry from current placeholder)

These features must survive into the final model — they define Pudge's silhouette:

- **Bloated belly hanging forward** — torso is wider than tall
- **Visible stitches** — vertical seam down chest, 2-3 horizontal seams across belly
- **Hunched, almost-no-neck head** — sunk into shoulders
- **Asymmetric eyes** — left eye larger, slightly higher; deranged stare
- **Wide grin with visible crooked teeth** — uneven, yellowed, a couple of sharp/missing ones for character. Mouth dominates the lower face.
- **Brown leather belt with metal buckle** at waist
- **Hook arm (LEFT) is chunkier** than the right arm — it's the working arm
- **Stubby legs** — barely visible under the gut
- **Ratty boots** — scuffed brown leather, worn soles, slightly too small (toes/laces splaying); reads as "butcher who's been on his feet too long"
- **Hook prop**: classic **meat hook on a chain** (3-4 large iron links visible at rest, more chain coiled at the belt). Hook itself is curved iron, blood-stained, ~30cm long

## 4. Animation Set (10 clips)

Frame rate: 30 fps. Root motion: **off** (movement driven by `CharacterBody3D`).
All clips authored in-place. Loop flags noted.

| # | Clip | Length | Loop | Notes |
|---|---|---|---|---|
| 1 | `idle` | 2.0s | yes | Heavy breathing, belly jiggle, hook arm twitches |
| 2 | `walk` | 0.8s | yes | Heavy waddle, 8 m/s playback rate base |
| 3 | `run` | 0.6s | yes | Same waddle, faster + bigger gut bounce |
| 4 | `turn_in_place` | 0.5s | no | 90° pivot blend; mirror for L/R |
| 5 | `hook_throw` | 0.4s | no | Wind-up + release on frame 6. **Event marker `hook_release`** at the moment hook leaves hand |
| 6 | `hook_recover` | 0.3s | no | Arm returns to idle pose; blends back to `idle`/`walk` |
| 7 | `attack_basic` | 0.5s | no | Off-hand cleaver swing or punch. **Event marker `hit_active`** at frame 7 |
| 8 | `hit_react` | 0.3s | no | Flinch — torso recoil, head jerk |
| 9 | `death` | 1.5s | no | Stagger backward, fall on back, gut deflates last |
| 10 | `victory` | 2.0s | yes | Hook raised triumphant, big laugh; used post-match |

**Optional (stretch)**: `taunt` (1.5s), `level_up` (1.0s) — nice-to-have, not blocking.

## 5. Rig Spec

- **Skeleton type**: Humanoid (Godot `Skeleton3D`), retargetable.
- **Bone count**: ~35–45 bones. Hard ceiling 50.
- **Required bones**: `Hips`, `Spine`, `Spine1`, `Chest`, `Neck`, `Head`,
  `LeftShoulder`/`RightShoulder`, `LeftArm`/`RightArm`, `LeftForeArm`/`RightForeArm`,
  `LeftHand`/`RightHand`, `LeftUpLeg`/`RightUpLeg`, `LeftLeg`/`RightLeg`,
  `LeftFoot`/`RightFoot`.
- **Helper bones**: belly jiggle (1 bone, drives gut bounce in walk/run/death),
  jaw (1 bone, optional for taunt/death).
- **IK chains**: 2-bone IK on each arm (for hook hand placement) + each leg
  (for ground adapt). Set up via Godot's `SkeletonModification3D` (4.6 IK restored).
- **Forward axis**: `-Z` (Godot default). **Up axis**: `+Y`. Feet at `Y=0`.
- **Bind pose**: A-pose (arms ~30° down from T) — better for chibi shoulders.

## 6. Sockets (attachment points)

Required `BoneAttachment3D` targets for gameplay code:

| Socket | Bone | Use |
|---|---|---|
| `socket_hook_hand` | `LeftHand` | Hook prop spawn + chain anchor |
| `socket_offhand` | `RightHand` | Optional cleaver/secondary attack |
| `socket_chain_origin` | `Chest` | Visual fallback if hand is offscreen |
| `socket_hit_center` | `Spine1` | Damage VFX + hit-react origin |
| `socket_head_top` | `Head` | Status icons (stun, level-up FX) |

## 7. Texture / Material Spec

- **Channel pack**: ORM (R=AO, G=Roughness, B=Metallic). Standard for Godot 4.
- **Maps**: BaseColor, Normal (tangent-space), ORM, Emissive (eyes only).
- **Hero color tint**: Implemented via shader uniform on body material so per-team
  color tint can be applied at runtime without re-baking the texture.
- **Eyes**: emissive yellow (`Color(1.0, 0.85, 0.1)`), low intensity ~3.0.
- **Skin highlight**: subtle subsurface fake via warmer base color in cavities;
  no real SSS (mobile budget).

## 8. Collision

- Visual model has **no collision** — gameplay uses the existing `CapsuleShape3D`
  on `CharacterBody3D` (untouched).
- Optional: a low-poly hit volume for ranged-attack accuracy can be added later;
  not in this brief.

## 9. Integration Contract

- **Output path**: `src/assets/models/heroes/pudge.glb` (overwrites placeholder).
- **Loaded by**: `src/gameplay/hero/hero_model_builder.gd:28-36` (already wired).
  The loader expects feet at Y=0, forward = -Z. **Do not add a transform offset
  in the GLB root** — must match the existing capsule pivot.
- **Animation library**: exported inside the `.glb` as a single
  `AnimationLibrary`, clip names match section 4 exactly (snake_case).
- **AnimationTree**: a follow-up task will wire a `BlendSpace1D` for
  idle→walk→run and one-shots for combat clips. Not part of this brief.

## 10. Acceptance Criteria

A QA tester must be able to verify each of the following:

1. ✅ `pudge.glb` imports into Godot 4.6 with no errors or warnings.
2. ✅ Total body tris ≤ 9,000 (LOD0). Verified via Godot import inspector.
3. ✅ Material count ≤ 2. Verified via scene inspector.
4. ✅ All 10 animation clips present in the embedded `AnimationLibrary` with
   matching names from section 4.
5. ✅ Each animation plays without obvious clipping (gut through torso, hands
   through belly) at the canonical playback speed.
6. ✅ Feet remain at Y≈0 throughout all locomotion clips (in-place).
7. ✅ Hook prop attached to `socket_hook_hand` is visible and oriented forward
   in `idle` and `hook_throw`.
8. ✅ All 5 sockets resolve to valid bones at runtime (no
   `BoneAttachment3D: Bone not found` warnings).
9. ✅ Silhouette readable from default game camera (top-down ~12m, 30° pitch).
10. ✅ All 4 LODs export and switch within Godot's distance ranges without pop.
11. ✅ Per-team color tint via shader uniform produces visible distinct color
    on body without affecting eyes/metal/leather.

## 11. Pipeline Stages & Owners

| Stage | Owner | Output | Gate |
|---|---|---|---|
| 1. Concept | `concept-artist` | 3 silhouettes + chosen turnaround sheet | User picks silhouette |
| 2. High-poly sculpt | `character-artist` | ZBrush/Blender sculpt | Approved by user against turnaround |
| 3. Retopo + UVs | `character-artist` | Game-ready mesh (≤9k tris), unwrapped | Polycount + UV check |
| 4. Texture bake + paint | `texture-artist` | BaseColor / Normal / ORM / Emissive | Channel pack + texel density check |
| 5. Rig + skin | `rigging-animator` | Skeleton, weights, sockets | Deformation test on 4 extreme poses |
| 6. Animation | `rigging-animator` | 10 clips per section 4 | Playback in Blender + frame markers |
| 7. Blender export | `blender-specialist` | `pudge.glb` per `blender-export-check` skill | Export check passes clean |
| 8. Godot integration | `technical-artist` | Material setup, LOD switching, team tint shader | All 11 acceptance criteria pass |

## 12. Out of Scope

- Skin variants / cosmetics (future)
- Facial blend shapes beyond a jaw bone (future)
- Cloth simulation (future — current chibi style doesn't need it)
- Voice / barks (separate audio pipeline)
- AnimationTree wiring (separate gameplay task post-asset)

---

## Resolved Decisions (2026-04-28)

1. **Mouth**: visible crooked teeth — uneven, yellowed, a couple sharp/missing.
2. **Feet**: ratty brown leather boots, worn/scuffed, slightly too small.
3. **Hook prop**: meat hook + iron chain. Visible chain links from hand to belt.
4. **Concept stage**: ON. `concept-artist` produced 3 silhouettes — see `design/concept-art/pudge.md`.
5. **Silhouette**: **B — Coiled Hook Carry**. Hook raised at shoulder height, chain catenary arc visible at rest. Bind pose stays A-pose; raised-arm rest is driven by idle animation layer.
6. **Apron**: **Yes** — small bloodied butcher's apron stub tucked under belt (adds material zone to body atlas).
7. **BellyJiggle drive**: **Runtime spring constraint** in Godot (not baked keyframes). Animator does NOT keyframe BellyJiggle except in `death` (deliberate deflate moment). Runtime script reads Hips velocity, applies sway. Decision: avoids per-clip authoring overhead, keeps jiggle behavior consistent.
8. **IK strategy**: **FK baked in Blender, IK added engine-side** via `SkeletonModification3DTwoBoneIK` (Godot 4.6, IK restored). Blender IK constraints exist during animation authoring but are stripped/baked before export.
9. **Tint mask**: **Dedicated 5th texture map** on body material (`body_tintmask.png`, 1024², BC4/single-channel). Justified over packing into BaseColor alpha (BC7 RGBA path issues) or ORM W (geometrically impossible).
10. **Custom ShaderMaterial**: Body material is a **custom ShaderMaterial**, not StandardMaterial3D — needed for tint multiply. Hook material is StandardMaterial3D (no tint).
