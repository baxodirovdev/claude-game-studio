# Pudge — Stage 5 Blender Pipeline Plan

> **Status**: UPDATED — AI-mesh retopo path (Strategy A). Supersedes the Mixamo-path version.
> **Hero ID**: `pudge`
> **Stage**: 5 of 8 (Blender Pipeline Plan)
> **Date (original)**: 2026-04-28
> **Date (revised)**: 2026-05-22
> **Author**: `blender-specialist` agent
>
> **Upstream specs (all must be read before opening Blender)**
> - Brief (locked): `/design/characters/pudge_brief.md`
> - Concept sheet (approved): `/design/concept-art/pudge.md`
> - Model spec (approved): `/design/gdd/models/pudge.md`
> - Retopo + Bake plan (new — addendum to model spec): `/design/gdd/models/pudge_retopo_bake_plan.md`
> - Texture spec (draft): `/design/gdd/materials/pudge.md`
> - Rig + animation spec (draft): `/design/gdd/rigs/pudge.md`
> - Rig authoring playbook (new): `/design/gdd/rigs/pudge_authoring_playbook.md`
> - Loader contract: `src/gameplay/hero/hero_model_builder.gd:28-36`
>
> **Working source (AI-mesh path)**: `src/assets/models/heroes/anime_pudge.blend`
>   - Object `textured_mesh` — 40k-tri AI-generated chibi Pudge
>   - Source prep already complete: scaled to 1.4 m, feet at Z=0, transforms applied, Z-up corrected
>
> **Downstream consumers**
> - `technical-artist` — Stage 8 import preset, material setup, LOD wiring
> - `gameplay-programmer` — animation event timing confirmation
>
> **Validation gate**: `blender-export-check` skill at `.claude/skills/blender-export-check/SKILL.md`
> must pass clean before the GLB is handed to Godot.

This document is the written operational contract for the Blender artist who will
build and export `pudge.glb`. It does not repeat artistic decisions from upstream specs;
it converts them into exact Blender actions and settings. Nothing in this document may
be changed without notifying the `technical-artist` and updating this file.

**What changed from the original Mixamo-path version**: the high-poly source is now
an AI-generated mesh (`textured_mesh`) requiring manual retopology and baking (Strategy A).
The studio 27-bone rig and all 10 animation clips are authored from scratch (no Mixamo).
A bake stage now exists. Sections 1, 2, 3, 8, 11, 12, 13, and 14 have been updated.
Sections 4–7, 9–10, and the export settings table are carried forward unchanged
(they remain fully valid for both paths).

---

## 1. Working .blend File

### File organization decision — stay in `anime_pudge.blend` through bake; migrate to canonical path for rig+anim

The project currently has two relevant files:
- `src/assets/models/heroes/anime_pudge.blend` — the live working file with the AI source mesh (`textured_mesh`), source prep done, and where retopo+bake work will continue.
- `tools/blender/heroes/pudge.blend` — the canonical path from the original Mixamo-path pipeline spec; this path was never populated (the directory exists but the file was not yet created under the new path).

**Recommendation: perform retopo and bake in `anime_pudge.blend`; migrate to `tools/blender/heroes/pudge.blend` before rig authoring begins.**

Rationale:

1. The retopo mesh (`mesh_pudge_body`, `mesh_pudge_hook`) and all bake sources (`textured_mesh_bake_hp`, bake targets) must coexist in the same file. Moving mid-retopo would require relinking bake sources, which is error-prone.
2. Once bake is complete, the high-poly sources (`textured_mesh`, `textured_mesh_source_prep`, `textured_mesh_bake_hp`, `mesh_pudge_body_cage`) can be stripped. At that point the file is logically a clean rig-ready asset and should be saved to the canonical path.
3. The canonical path `tools/blender/heroes/pudge.blend` is what the validation script targets (`blender tools/blender/heroes/pudge.blend --background --python tools/blender/validate_export.py`). Keeping the source mesh in `src/assets/models/heroes/` mixes source assets with game assets, which violates the directory structure.

**Migration procedure** (one-time, after bake completes):

1. Confirm all bake outputs are saved to `src/assets/textures/heroes/pudge/` (separate files, not embedded in the blend).
2. Delete or move `textured_mesh`, `textured_mesh_source_prep`, `textured_mesh_bake_hp`, and `mesh_pudge_body_cage` from the scene — they are no longer needed for rig authoring.
3. `File → Save As` → `tools/blender/heroes/pudge.blend`. Confirm the `tools/blender/heroes/` subdirectory exists (it was confirmed present in the project).
4. The original `src/assets/models/heroes/anime_pudge.blend` is kept as a historical archive in version control (do not delete — it holds the AI source mesh for future reference).

**Single combined `.blend` file.** Do not split retopo mesh and rig into separate files.

**Canonical path (post-migration)**: `tools/blender/heroes/pudge.blend`

**Blender version**: 4.x (4.1 or later). The export settings described in Section 8
match Blender 4.x glTF exporter UI. Do not use Blender 3.x — the glTF exporter UI
and some animation export behaviors differ.

### Collection structure inside the .blend

**Phase A — During retopo and bake (in `anime_pudge.blend`):**

```
Scene Collection
├── _SOURCE              [hidden by default — AI mesh source objects; do not export]
│   ├── textured_mesh              (original AI mesh, untouched — archive only)
│   ├── textured_mesh_source_prep  (axis-corrected, scaled, feet-at-0 AI mesh; base color projection source)
│   └── textured_mesh_bake_hp      (watertight voxel remesh at 3mm; high-poly bake source for body normals/AO)
│
├── _BAKE                [hidden by default — show only during bake passes]
│   └── mesh_pudge_body_cage       (cage object: mesh_pudge_body inflated 2 cm outward; used in Selected-to-Active bake)
│
├── EXPORT_BODY          [visible — renders/exports]
│   ├── mesh_pudge_body_lod0   (retopo LOD0: ~5,500 tris body + hook total ~6,100)
│   ├── mesh_pudge_body_lod1   (decimate-derived LOD1: ~3,050 tris)
│   └── mesh_pudge_body_lod2   (decimate-derived LOD2: ~1,500 tris)
│
├── EXPORT_HOOK          [visible — renders/exports]
│   ├── mesh_pudge_hook_lod0   (fresh-modeled hook prop: ~600 tris)
│   ├── mesh_pudge_hook_lod1   (~300 tris)
│   └── mesh_pudge_hook_lod2   (~150 tris)
│
└── EXPORT_ARMATURE      [visible — renders/exports; added when rig authoring begins]
    └── arm_pudge              (27-bone armature)
```

**Phase B — After migration to `tools/blender/heroes/pudge.blend`** (bake sources stripped):

```
Scene Collection
├── EXPORT_BODY
│   ├── mesh_pudge_body_lod0
│   ├── mesh_pudge_body_lod1
│   └── mesh_pudge_body_lod2
│
├── EXPORT_HOOK
│   ├── mesh_pudge_hook_lod0
│   ├── mesh_pudge_hook_lod1
│   └── mesh_pudge_hook_lod2
│
└── EXPORT_ARMATURE
    └── arm_pudge
```

**Collection naming rules**:
- Collections prefixed with `_` (underscore) are non-export support collections.
  Keep them hidden in the viewport layer during normal working; toggle visible only
  when needed.
- Collections without a `_` prefix are the export-bound collections.
- Godot's glTF importer does not read Blender collection names as scene nodes — the
  collection structure is a Blender-only organization device. Only objects explicitly
  selected or in the active collection at export time are included in the GLB.

---

## 2. Object Naming Map

The following table lists every Blender object that will exist in the canonical
`tools/blender/heroes/pudge.blend` at the time of GLB export. All names contain
only ASCII alphanumeric characters and underscores — safe through glTF export with
no name mangling.

The `_lod0` suffix on LOD0 objects is a change from the original model spec §10 which
named the LOD0 body `mesh_pudge_body`. The suffix is required for Godot 4.6's
`use_name_suffixes` LOD auto-detection (see Section 13).

| Blender Object Name | Object Type | Parent Collection | Mesh Data-Block Name | Export? |
|---|---|---|---|---|
| `mesh_pudge_body_lod0` | Mesh | EXPORT_BODY | `mesh_data_pudge_body_lod0` | Yes |
| `mesh_pudge_body_lod1` | Mesh | EXPORT_BODY | `mesh_data_pudge_body_lod1` | Yes |
| `mesh_pudge_body_lod2` | Mesh | EXPORT_BODY | `mesh_data_pudge_body_lod2` | Yes |
| `mesh_pudge_hook_lod0` | Mesh | EXPORT_HOOK | `mesh_data_pudge_hook_lod0` | Yes |
| `mesh_pudge_hook_lod1` | Mesh | EXPORT_HOOK | `mesh_data_pudge_hook_lod1` | Yes |
| `mesh_pudge_hook_lod2` | Mesh | EXPORT_HOOK | `mesh_data_pudge_hook_lod2` | Yes |
| `arm_pudge` | Armature | EXPORT_ARMATURE | `arm_data_pudge` | Yes |
| `pudge` | Empty (scene root) | Scene Collection root | N/A | Yes — becomes the GLB root node |
| `textured_mesh` | Mesh | _SOURCE | N/A | No — archive only |
| `textured_mesh_source_prep` | Mesh | _SOURCE | N/A | No — base color projection reference |
| `textured_mesh_bake_hp` | Mesh | _SOURCE | N/A | No — high-poly bake source |
| `mesh_pudge_body_cage` | Mesh | _BAKE | N/A | No — bake cage; delete before migration |

**Source object status at export time**: all `_SOURCE` and `_BAKE` objects must be
deleted before migration to `tools/blender/heroes/pudge.blend`. If they remain in
the file, they will be visible in the EXPORT_* collections only if incorrectly moved —
the visibility check in the export step catches this (see Section 8, Include panel).

**GLB name survival confirmation**: glTF 2.0 exports Blender object names as node
names with no transformation except that Blender may append a numeric suffix if two
objects share a name. All names above are unique — no suffix collisions. The `_lod0`,
`_lod1`, `_lod2` suffix convention on export is discussed in Section 13.

**Empty root node**: The `pudge` empty is the scene root. Parent all mesh objects and
the armature under this empty. This ensures the GLB root node is named `pudge`,
matching the loader's `glb_root.name = "MeshInstance3D"` reassignment in
`hero_model_builder.gd:34`. The loader replaces the name on instantiation, so the
GLB root name is not critical for runtime — but naming it `pudge` is clean.

---

## 3. Modifier Stack Policy

### mesh_pudge_body_lod0 — during retopo (Shrinkwrap live)

While retopologizing, `mesh_pudge_body_lod0` carries a Shrinkwrap modifier (Project mode)
targeting `textured_mesh_bake_hp`. This modifier is ON CAGE, giving real-time surface
snapping. The Shrinkwrap must be removed before UV unwrap and absolutely before baking —
a live Shrinkwrap changes vertex positions between frames and will cause inconsistent
bake results.

**Shrinkwrap removal procedure** (retopo plan §D, step 8): once the mesh topology is
accepted, delete (not apply) the Shrinkwrap modifier. The mesh should hold its position
since it was snapped to the surface — deleting the modifier freezes the current positions.

### mesh_pudge_body_lod0 — at GLB export time

At the time of GLB export, this object must have the following modifier state:

| Modifier | Allowed unapplied at export? | Required action |
|---|---|---|
| Armature | YES — must remain unapplied | Leave in the stack. glTF exporter reads skinning from the Armature modifier. Applying it bakes the deformation and loses skinning data. |
| Shrinkwrap (retopo aid) | NO | Must be deleted (not applied) before UV unwrap. Do not apply — applying would flatten normals. Delete it. |
| Multires / Subdivision Surface | NO | Should not exist on this mesh (retopo is hand-authored, not subdivided). If present from testing, apply or delete before export. |
| Mirror | NO | Must be applied. Any mirrored geometry must be joined into the mesh before export. |
| Solidify | NO | Must be applied. |
| Bevel | NO | Must be applied. |
| Decimate | NO on LOD0 | LOD0 is hand-authored. Decimate is used only to generate LOD1/LOD2 objects (separate objects). |
| Weighted Normal | NO | Must be applied. Godot reads normals from glTF vertex data, not Blender modifier stacks. |
| Data Transfer | NO | Must be applied or deleted. |
| Smooth by Angle | NO | Must be applied or deleted. |

**Summary**: Only the Armature modifier may remain unapplied on `mesh_pudge_body_lod0` at export time.

### mesh_pudge_hook (LOD0)

Identical policy. Only the Armature modifier may remain. The hook is a rigid prop
weighted 100% to LeftHand — it still carries an Armature modifier for skinning
consistency.

### LOD1 and LOD2 objects

LOD1 and LOD2 objects are generated via Decimate (see Section 13). After generation,
the Decimate modifier is applied and the resulting object has NO modifiers at all
except the Armature modifier. Apply Decimate before export.

### Consequence of violating this policy

If a Mirror modifier is left unapplied, the GLB will contain half-geometry that
Godot cannot process correctly. If Subdivision Surface is left unapplied, polycount
explodes (a Level 2 subsurf on 5,500 tris produces ~22,000 tris — above the 9,000
hard ceiling). These are hard export failures.

---

## 4. UV Layout in .blend

### Body mesh — UV map name

**UV map name**: `UVMap` (Blender default slot name).

Do not rename this UV map. The glTF exporter references the first UV channel
(`TEXCOORD_0`) by position, not by name. Keeping the Blender default name avoids
any risk of the exporter silently skipping a renamed UV map. The material spec
(texture spec §3) uses UV space coordinates, not UV map names — no upstream
dependency on the UV name.

If a lightmap UV2 channel is ever required (not in this spec — `meshes/light_baking=1`
in the placeholder import but for baked lighting, not this character), it would go into
a second UV slot named `UVMap2` and export as `TEXCOORD_1`. For Pudge LOD0, only
`TEXCOORD_0` is needed.

**UV island layout**: follows texture spec §3a exactly. The layout is described there in
pixel regions; the artist works in UV space [0.0, 1.0]. The four-quadrant layout maps to:
- Top-left quadrant (U 0.0–0.5, V 0.5–1.0 in Blender UV space): Face + Skull
- Top-right quadrant (U 0.5–1.0, V 0.5–1.0): Torso front + Apron stub
- Bottom-left quadrant (U 0.0–0.5, V 0.0–0.5): Arms + Hands
- Bottom-right quadrant (U 0.5–1.0, V 0.0–0.5): Legs + Boots + Belt + Chain

**Mirrored UVs**: Legs, Boots share a single UV island per the model spec §4.
Arms do NOT share a UV island — the hook arm (left) is non-mirrored. Face is
non-mirrored. Confirm in UV editor before bake: the mirrored islands must have
"Mirror UV" or coincident UV coordinates, not separate islands.

**UV padding**: minimum 8 px padding between all islands at 1024 resolution
(= 0.0078 UV units). Run Blender's "Pack Islands" with margin = 0.008 after layout.
Verify in the UV editor at maximum zoom that no islands overlap or are separated by
fewer than 8 px equivalent.

### Hook prop — UV map name

**UV map name**: `UVMap` (default). Same rationale as body mesh.

**UV island layout**: follows texture spec §3b. Hook body occupies the top ~54% of
the 512x512 atlas. Chain link islands occupy the bottom half. In UV space [0.0, 1.0]:
- Hook body island: V 0.46–1.0 (top 54%)
- Chain link 1: lower-left quadrant
- Chain links 2–4: remaining bottom-half space

---

## 5. Material Slots in .blend

### mesh_pudge_body — 1 material slot

| Property | Value |
|---|---|
| Slot index | 0 (only slot) |
| Material name | `mat_pudge_body` |
| Shader node setup | Principled BSDF with all 5 texture nodes connected |
| Base Color input | Image Texture → `body_basecolor.png` (sRGB) |
| Normal input | Image Texture → `body_normal.png` (Linear) → Normal Map node → Normal socket |
| Roughness input | Image Texture → `body_orm.png` (Linear) → Separate Color node → Green (G) channel |
| Metallic input | Same Separate Color node → Blue (B) channel |
| Ambient Occlusion (Cycles bake) | Image Texture → `body_orm.png` → Red (R) channel wired into AO bake target only |
| Emission Color input | Image Texture → `body_emissive.png` (sRGB) |
| Emission Strength | 3.0 |
| Tint mask visualization (optional) | Image Texture → `body_tintmask.png` (Linear) → Mix Color node for preview in viewport |

**Important**: This Blender material is a stand-in for bake visualization and
viewport preview only. The Godot final material is a custom `ShaderMaterial`
(`mat_pudge_body.tres`) that the `technical-artist` authors in Stage 8 using the
tint multiply formula from texture spec §6. The glTF exporter will write a
`pbrMetallicRoughness` block referencing the texture paths — Godot will import
these as material overrides that the `technical-artist` replaces with the
custom ShaderMaterial.

**GLB material export behavior**: Godot 4.6 glTF import creates a
`StandardMaterial3D` from the embedded `pbrMetallicRoughness` data by default
(when `materials/extract=0`). The `technical-artist` overrides this in Stage 8.
The Blender material setup above ensures the correct texture paths appear in the
glTF JSON so they can be referenced in the .tres files.

### mesh_pudge_hook — 1 material slot

| Property | Value |
|---|---|
| Slot index | 0 (only slot) |
| Material name | `mat_pudge_hook` |
| Shader node setup | Principled BSDF with 3 texture nodes |
| Base Color input | Image Texture → `hook_basecolor.png` (sRGB) |
| Normal input | Image Texture → `hook_normal.png` (Linear) → Normal Map node |
| Roughness input | Image Texture → `hook_orm.png` (Linear) → Separate Color → Green |
| Metallic input | Same Separate Color → Blue |
| Emission | OFF (no emissive on hook) |

**Material count verification**: 2 materials total across both meshes. No
orphaned materials. Before export, open Blender's Outliner in "Orphan Data" mode
and purge any unused material data-blocks. Leftover test or placeholder materials
that accumulate during development can inflate the GLB and confuse the Godot importer.

---

## 6. Skeleton Export Plan

### Bind pose

A-pose — arms approximately 30 degrees below horizontal, per rig spec §2. This is
the rest pose stored in the GLB's inverse bind matrices. The idle animation's first
frame drives the arms into the Silhouette B raised position; the A-pose bind is
never displayed at runtime.

**Confirmation**: The glTF exporter writes the current Blender rest pose as the bind
pose (inverse bind matrices). In Blender, the rest pose is set via
`Pose → Apply → Apply Pose as Rest Pose` when the armature is in the desired bind
orientation. Ensure the bind pose is applied before export. The per-bone angles from
rig spec §2 Table (Spine +5°/+5°/+5°, arms -30° / +30° Z, etc.) must be encoded
in the rest pose.

### 27 bones

Bone count: 27 (per rig spec §1 summary). All bone names are PascalCase matching
Godot Humanoid retargeting. See rig spec §13 for the authoritative list. Reproduced
here for the export checklist:

```
Hips, Spine, Spine1, Chest, Neck, Head, Jaw
LeftShoulder, LeftArm, LeftForeArm, LeftHand
ChainLink1, ChainLink2, ChainLink3, ChainLink4
RightShoulder, RightArm, RightForeArm, RightHand
BellyJiggle
LeftUpLeg, LeftLeg, LeftFoot
RightUpLeg, RightLeg, RightFoot
```

No `bone_` prefix. No spaces. No accented characters. All names export cleanly
through glTF with no mangling.

### IK constraint stripping before export

Blender IK constraints on the armature (used by the animator during authoring for
convenience) must be stripped or disabled before GLB export. Procedure:

1. With the armature selected, enter Pose Mode.
2. Select All bones (A).
3. Open the Bone Constraint Properties panel.
4. Delete or mute all IK constraints.
5. Alternatively: after baking all actions to FK keyframes (see Section 7 animation
   export step), delete the IK constraints — they served their purpose.

**Why**: glTF 2.0 does not encode Blender IK constraint data. The exporter ignores
them. However, leaving IK constraints active can cause the exporter to write
incorrect rest-pose bone positions if Blender evaluates the IK during the rest pose
bake step. Removing them eliminates this risk entirely.

### BellyJiggle bone — no animation tracks

**BellyJiggle must have zero animation tracks in all 9 non-death clips.**

The locked decision for this project is: BellyJiggle is driven at runtime by a
Godot `SkeletonModifier3D` spring simulation. The only exception is the `death`
clip, where BellyJiggle is explicitly keyframed by the animator for the gut-deflate
sequence (rig spec §8 Clip 9, Phase 5).

**GLB export compatibility confirmation**: Yes, this approach is fully compatible
with glTF export. BellyJiggle will appear in the exported skeleton's bone list with
its bind-pose transform. In the 9 clips where it has no keyframes, Godot's
AnimationPlayer will not create any tracks for it — the bone will be driven entirely
by the `SkeletonModifier3D`. In the `death` clip it will have explicit tracks that
override the spring during playback. The `SkeletonModifier3D` must be weighted to 0
during the `death` animation — the `technical-artist` handles this blend weight
toggle in the AnimationTree setup (Stage 8).

**Verification step**: after baking all actions, open the Dope Sheet → Action Editor,
select each non-death clip, and confirm BellyJiggle has no keyframe rows. If
auto-keying accidentally recorded BellyJiggle during authoring, delete those tracks
before export.

### ChainLink1–4 — FK keyframes only

Per rig spec §12: chain sway is baked from the Blender `Damped Track` constraint into
FK keyframes. After baking, delete the `Damped Track` / `Child Of` constraints from
ChainLink bones. The baked FK keyframes export cleanly as animation tracks in the GLB.

---

## 7. Animation Export Plan

### 10 required actions

Author as separate named Blender Actions. Action names must match clip names exactly:

```
idle
walk
run
turn_in_place
hook_throw
hook_recover
attack_basic
hit_react
death
victory
```

**Case**: all lowercase snake_case. No `pudge_` prefix. No spaces. Verify in the
Action Editor that the exact string matches before pushing to NLA.

### NLA setup — mandatory for glTF multi-action export

For the glTF exporter to include all 10 clips in a single GLB:

1. In the NLA Editor, select the armature.
2. For each action: click "Push Down" to create an NLA strip for that action.
3. Set "Use Fake User" (F icon) on every action in the Action Editor. This prevents
   Blender from garbage-collecting unused actions when the NLA strips reference them.
4. Strips may be placed on separate NLA tracks (one track per clip) or stacked —
   position does not affect glTF export. Recommended: one strip per track, labeled
   with the clip name.
5. Mute all NLA strips during animation authoring (use the mute icon on each strip)
   so they do not interfere with editing individual actions.

**Failure mode if NLA push-down is skipped**: the glTF exporter will only export
the currently active action. The other 9 clips will be absent from the GLB. This is
the single most common cause of "missing animations" reports in Godot.

### FK bake pass before export

After all 10 clips are authored (potentially using Blender IK constraints for
animator convenience):

1. Select the armature in Pose Mode.
2. Select All bones.
3. For each action (switch to it in the Action Editor):
   - `Pose → Animation → Bake Action`
   - Settings: Frame Range = start/end of that clip, Step = 1, Only Selected Bones = OFF,
     Visual Keying = ON, Clear Constraints = YES, Clear Parents = NO,
     Overwrite Current Action = YES.
4. Confirm the action now has pure FK keyframe data and no constraint references.

Visual Keying = ON is critical: it writes the IK-solved positions into the keyframes,
not the FK bone values (which would be wrong if IK was driving them).

### Frame rate

Set Blender scene frame rate to **30 fps** before authoring any clip. Confirm in
`Properties → Output → Frame Rate = 30`.

Verify: the clip frame ranges from rig spec §8 are expressed at 30 fps:
- `idle`: 0–60 frames = 2.0 s at 30 fps
- `walk`: 0–24 frames = 0.8 s
- `run`: 0–18 frames = 0.6 s
- All other clips per the rig spec frame ranges.

The Godot import file (Section 11) sets `animation/fps=30` — this must match.

### Animation event markers — Blender pose markers vs. Godot compatibility

**Assessment**: Blender's native **pose markers** (set via `Pose → Animation → Add Pose Marker`
or the Dope Sheet marker row in Pose Mode) do NOT transfer to Godot 4.6 via glTF
import as Godot animation events. glTF 2.0 has no standard extension for animation
events/markers that Godot 4.6's glTF importer reads natively.

**Decision**: Pose markers are authored in Blender as documentation and timing references
for the animator. They are NOT the delivery mechanism for Godot. The `technical-artist`
adds Godot `AnimationPlayer` method track calls manually in Stage 8, using the exact
frame numbers specified in rig spec §8. The blender artist must document the final
confirmed frame for each event in the handoff note at the bottom of this file.

**Events requiring manual addition in Stage 8**:

| Clip | Event name | Frame (30 fps) |
|---|---|---|
| `hook_throw` | `hook_release` | 6 |
| `attack_basic` | `hit_active` | 7 |
| `walk` | `footstep_left` | 0 |
| `walk` | `footstep_right` | 12 |
| `run` | `footstep_left` | 0 |
| `run` | `footstep_right` | 9 |
| `hit_react` | `hit_react_peak` | 1 (proposed — confirm with gameplay-programmer) |
| `death` | `death_begin` | 8 |
| `death` | `death_thud` | 23 |
| `death` | `death_deflate_start` | 38 |
| `victory` | `victory_arm_peak` | 15 |
| `victory` | `victory_laugh_sound` | 20 |

Add these as Blender pose markers in the Dope Sheet (marker row) for reference.
They will not export, but they give the animator and reviewer a visual frame reference.

---

## 8. Bake Stage — AI-Mesh-Retopo Path

This section is new for the AI-mesh path. It has no equivalent in the original Mixamo-path
spec. The full bake procedure is governed by `design/gdd/models/pudge_retopo_bake_plan.md`
(Section F); what follows is the blender-specialist's integration notes — how the bake stage
fits into this pipeline, what must be confirmed before baking begins, and what the
`blender-export-check` skill verifies after baking.

### Bake gate — prerequisites before any bake pass begins

All of the following must be true before the first bake is started:

| Gate | Description | Source |
|---|---|---|
| Shrinkwrap removed | `mesh_pudge_body_lod0` has no Shrinkwrap modifier. | Section 3 above |
| Watertight bake source | `textured_mesh_bake_hp` passes Select All By Trait → Non-Manifold = zero results. | Retopo plan §B.5 |
| Hook masked on bake source | Wrist-and-below geometry deleted from `textured_mesh_bake_hp`. The truncation cap normals face outward. | Retopo plan §C |
| Interior faces deleted | `textured_mesh_bake_hp` has zero interior faces (Select → All by Trait → Interior Faces → delete). | Retopo plan §I, Risk 3 |
| LOD0 topology final | `mesh_pudge_body_lod0` tri count confirmed ≤ 5,500 tris. | Model spec §1 |
| UV unwrap complete | Both `mesh_pudge_body_lod0` and `mesh_pudge_hook_lod0` have final UV layouts with 8px minimum padding. UV maps named `UVMap`. | Retopo plan §E |
| Bake cage ready | `mesh_pudge_body_cage` exists as a separate object: LOD0 inflated 2 cm uniformly along normals. Cage normals face outward. | Retopo plan §F |
| Bake images created | Blank images for each bake target exist and are assigned to their respective material's Image Texture nodes. See target file list below. | Retopo plan §F |

### Bake target files

| Blender bake target image | Resolution | Bake type | High-poly source |
|---|---|---|---|
| `pudge_body_normal` | 1024x1024 | Tangent-space normal | `textured_mesh_bake_hp` → `mesh_pudge_body_lod0` |
| `pudge_body_basecolor_ai_projection` | 1024x1024 | Emit (source material color projection) | `textured_mesh_source_prep` → `mesh_pudge_body_lod0` |
| `pudge_body_orm` (R channel = AO) | 1024x1024 | Ambient Occlusion | Both `textured_mesh_bake_hp` + `mesh_pudge_hook_lod0` present in scene |
| `pudge_hook_normal` | 512x512 | Tangent-space normal | Fresh high-poly bevel pass on hook → `mesh_pudge_hook_lod0` |
| `pudge_hook_orm` (R channel = AO) | 512x512 | Ambient Occlusion | Combined scene (hook + body both present) |

**Output path for all baked files**: `src/assets/textures/heroes/pudge/`
Do not save baked files inside `src/assets/models/heroes/` — textures live in the
textures subtree per the project directory structure.

**The AI base color projection** (`pudge_body_basecolor_ai_projection.png`) is delivered
labeled as reference only, NOT as the final texture. The texture-artist hand-paints the
final `pudge_body_basecolor.png`. The projection is a starting-point color guide.

### Bake scene setup summary

Run bakes in `anime_pudge.blend` before migration to `tools/blender/heroes/pudge.blend`.

1. Render engine: **Cycles** (baking is not available in EEVEE).
2. Bake mode: **Selected to Active**. Select `textured_mesh_bake_hp`, then Shift-select
   `mesh_pudge_body_lod0` (active). Use the cage object option with `mesh_pudge_body_cage`.
3. Cage settings per retopo plan §F: Extrusion = 0.02 m, Max Ray Distance = 0.06 m.
   Use cage object method (not the auto-extrusion) because the AI mesh's inconsistent
   normals make auto-extrusion unreliable at deep concave areas.
4. AO bake: in the combined scene, both `mesh_pudge_body_lod0` and `mesh_pudge_hook_lod0`
   must be present and in their correct relative positions. AO samples: minimum 64.
   AO distance: 0.3 m. This is the requirement from model spec §5 (open question 5)
   and retopo plan §F.
5. After baking, save all image files explicitly (`Image → Save As`) before closing
   Blender. Blender will not auto-save baked images on file save.

### What the `blender-export-check` skill does NOT check (bake outputs)

The automated validation script operates on the `.blend` scene and the exported `.glb`.
It cannot validate the quality of the baked texture maps. Bake quality is verified
manually by the Blender artist before handoff:

- Normal map: no hard seams at UV island borders; no cage-leak dark spots on the belly,
  shoulder, or eye socket areas.
- AO map: hand-to-hook contact zone shows shadowing (confirming combined-scene bake).
- No texture channels left as blank black images in the material slots (accidental
  unsaved bake results).

These manual checks are part of the retopo handoff checklist in retopo plan §J and
are the character-artist's responsibility before handing to the rigging-animator.

---

## 9. GLB Export Settings — Exact Blender 4.x glTF Exporter Configuration

**Menu path**: `File → Export → glTF 2.0`

Every setting below is specified. "Default" is not an acceptable specification — assume
no defaults.

### Top-level format

| Setting | Value | Reason |
|---|---|---|
| Format | `glTF Binary (.glb)` | Single file, no external .bin or .json. Godot imports the single .glb file. |
| Export path | `src/assets/models/heroes/pudge.glb` (absolute path on disk) | Matches brief §9 output path and the placeholder import file location. |

### Include panel

| Setting | Value | Reason |
|---|---|---|
| Include → Selected Objects | OFF | Export entire scene via active collection instead. |
| Include → Visible Objects | ON | Only objects visible in the viewport (i.e., the EXPORT_* collections, not _HIGH_POLY or _BAKE which are hidden). This is the correct filter. |
| Include → Active Collection | OFF | Use Visible Objects instead; active collection changes based on what the artist last clicked. |
| Include → Custom Properties | ON | Exports Blender object custom properties as glTF extras. Useful for metadata. |
| Include → Cameras | OFF | No cameras in this asset. |
| Include → Punctual Lights | OFF | No lights in this asset. |

### Transform panel

| Setting | Value | Reason |
|---|---|---|
| Y Up | ON | This is the Godot/glTF Y-up convention. With Y Up ON, Blender's Z-up world is remapped to glTF's Y-up. The result: Blender's +Z becomes glTF's +Y, and Blender's -Y becomes glTF's +Z. The character stands upright in Godot with feet on the Y=0 plane. Do NOT turn this off. |

**Y Up clarification**: The model spec §6 states "Y Forward, -Z Up" in one place but
is describing Blender's exporter orientation field from an older workflow. In the
current Blender 4.x glTF exporter, the single "Y Up" toggle is the correct setting.
With Y Up ON, Pudge's feet-at-Y=0 constraint is preserved through export. Verify after
export: open the .glb in a glTF viewer (e.g., Khronos glTF Sample Viewer) and confirm
Pudge stands upright with belly facing -Z.

### Geometry panel

| Setting | Value | Reason |
|---|---|---|
| Geometry → Apply Modifiers | ON | All remaining modifiers (Armature is the only allowed unapplied one) are evaluated at export time. This ensures the exported mesh reflects the correct topology. Note: the Armature modifier is applied by the skinning exporter, not the geometry pipeline — skinning data is written separately as skin weights. |
| Geometry → UVs | ON | Exports `TEXCOORD_0` (UVMap). Required for texture mapping in Godot. |
| Geometry → Normals | ON | Exports vertex normals. Required for correct shading and for the normal map to work. |
| Geometry → Tangents | ON | Exports tangent vectors. REQUIRED for tangent-space normal maps. If OFF, Godot cannot apply the normal map correctly — this produces flat or incorrectly lit surfaces. |
| Geometry → Vertex Colors | OFF | No vertex colors on the export meshes (the `jiggle_boundary` vertex color layer is an authoring aid on the pre-retopo mesh, not on the export mesh). |
| Geometry → Materials | ON | Exports material references. Godot reads these to auto-create material slots. |
| Geometry → Images → Image format | AUTO | Godot re-imports source PNGs from `src/assets/textures/heroes/pudge/`. AUTO mode embeds a JPEG or PNG depending on alpha — acceptable as a fallback. The `technical-artist` replaces embedded textures with project source textures in Stage 8. |
| Geometry → Compression → Draco | OFF | Draco compression is NOT used. Godot's importer adds Draco decompression overhead at load time with no persistent benefit since Godot re-compresses to its own internal format (BasisUniversal/BC7) on import. Draco also can introduce mesh artifacts on low-poly assets. |

### Armature panel

| Setting | Value | Reason |
|---|---|---|
| Armature → Add Leaf Bones | OFF | Leaf bones are synthetic terminal bones added by the exporter. Godot does not need them and they appear as extra bones in the Skeleton3D, polluting the bone list. |
| Armature → Export Deformation Bones Only | OFF | We need all 27 bones exported, including helper bones (BellyJiggle, ChainLink1–4, Jaw). These are real bones in the skeleton that Godot needs to resolve at runtime (BellyJiggle for the spring modifier, ChainLink1–4 for animation tracks). Setting this to ON would strip them. |
| Armature → Bone Influences (skinning) | 4 | Max vertex bone influences per vertex. Matches Godot 4.6 default. Do not set higher — Godot's importer will clamp to 4 anyway. Do not set lower — the shoulder and belly regions may need 3–4 influences for smooth deformation. |
| Armature → Use Rest Position Armature | OFF | Export the posed armature using the current rest pose, not the evaluated frame pose. With this OFF, the GLB bind pose matches the Blender rest pose (A-pose). |

### Animation panel

| Setting | Value | Reason |
|---|---|---|
| Animation → Export Animations | ON | Export all animation clips. |
| Animation → Limit to Playback Range | OFF | Export each clip's full range (from action first keyframe to last), not the viewport playback range. |
| Animation → Always Sample Animations | ON | Write a keyframe for every frame of every clip, not just on keyframe frames. This is required for Godot to correctly interpolate curved animation paths (F-curve interpolation differences between Blender and Godot's AnimationPlayer). Without this, curved motions (shoulder arcs, breathing) may look wrong in Godot. Performance cost: larger file size. Acceptable — the model is under 5 MB target. |
| Animation → Group by NLA Track | ON | Each NLA strip (= each pushed-down action) exports as a separate animation clip in the GLB AnimationLibrary. This is how the 10 clips appear as `idle`, `walk`, etc. in Godot's AnimationPlayer. |
| Animation → Export Rest Position as RESET | OFF | Matches the placeholder import file setting (`animation/import_rest_as_RESET=false`). If set to ON, Godot adds a `RESET` animation track that fights the AnimationTree. |
| Animation → Optimize Animation Size | ON | Removes redundant keyframes (consecutive keyframes with identical values). Reduces file size without affecting playback quality. Safe for this asset. |
| Animation → Force Sampling All Objects | OFF | Only sample objects that have animation data. Sampling empty objects or non-animated objects wastes keyframes. |

### Skinning panel

| Setting | Value | Reason |
|---|---|---|
| Skinning → Export Skin | ON | Export vertex weight data. Required for skinned character animation. |

### File output summary

After export, the file at `src/assets/models/heroes/pudge.glb` should contain:
- 3 mesh objects: `mesh_pudge_body`, `mesh_pudge_body_lod1`, `mesh_pudge_body_lod2`
- 3 hook objects: `mesh_pudge_hook`, `mesh_pudge_hook_lod1`, `mesh_pudge_hook_lod2`
- 1 armature: `arm_pudge` (27 bones)
- 10 animation clips in 1 AnimationLibrary
- 2 materials: `mat_pudge_body`, `mat_pudge_hook`
- Embedded texture data (fallback; Godot re-imports from source)

Estimated GLB file size: under 5 MB (target). At ~6,100 LOD0 tris + LOD1/LOD2 +
267 frames × 27 bones × 10 clips (FK baked): the animation data is the largest
component. Always-Sample ON at 30 fps over 267 total frames = ~8,010 bone keyframes
across all clips. Compressed in glTF binary: approximately 1–2 MB. Mesh data: < 1 MB.
Total estimated: 2–3 MB. Comfortably under 5 MB.

---

## 10. Output Path

**`/Users/akmalbaxodirov/develop/projects/AI/Claude-Code-Game-Studios/src/assets/models/heroes/pudge.glb`**

This overwrites the existing placeholder. Confirmed match to:
- Brief §9: "Output path: `src/assets/models/heroes/pudge.glb`"
- Loader contract (`hero_model_builder.gd:15`): `const HERO_GLB_PATH := "res://assets/models/heroes/%s.glb"`
  → resolves to `res://assets/models/heroes/pudge.glb`
- Placeholder import file: `src/assets/models/heroes/pudge.glb.import`

The `.import` sidecar file will be regenerated by Godot on first import of the new
GLB. The existing `.import` file is retained as a baseline (see Section 10).

---

## 11. Godot Import Preset — Starting Point for Stage 8

The existing placeholder `.import` file at
`src/assets/models/heroes/pudge.glb.import` is the baseline. Below are the
settings to carry forward, the settings to change, and the settings the
`technical-artist` must tune in Stage 8.

### Carry forward from placeholder (no change needed)

| Parameter | Current value | Rationale |
|---|---|---|
| `nodes/apply_root_scale` | `true` | Apply the root scale at import time. Correct. |
| `nodes/root_scale` | `1.0` | 1 Blender unit = 1 meter; no additional scale needed. |
| `nodes/use_name_suffixes` | `true` | Required for Godot to auto-detect LODs by suffix (`_lod0`, `_lod1`, `_lod2`). See Section 13. |
| `nodes/use_node_type_suffixes` | `true` | Allows Godot to interpret node type from suffix (e.g., `-col` for collision). Harmless for this asset. |
| `meshes/ensure_tangents` | `true` | Ensures tangent data exists for normal mapping. Required even though we export tangents from Blender — belt-and-suspenders. |
| `meshes/generate_lods` | `true` | With `use_name_suffixes=true` and `_lod1`, `_lod2` suffixed objects, Godot 4.6 auto-assigns these as LOD levels. Leave ON. |
| `meshes/create_shadow_meshes` | `true` | Godot generates simplified shadow geometry. Acceptable for this character. |
| `skins/use_named_skins` | `true` | Uses bone names instead of indices — required for BoneAttachment3D sockets to resolve by name at runtime. |
| `animation/fps` | `30` | Matches our authoring frame rate. |
| `animation/trimming` | `false` | Do not trim animation ranges. We author exact start/end frames. |
| `animation/remove_immutable_tracks` | `true` | Removes tracks where values never change, reducing AnimationPlayer overhead. |
| `animation/import_rest_as_RESET` | `false` | Do not add a RESET clip from the rest pose. Matches brief §9 and our AnimationTree plan. |
| `gltf/naming_version` | `2` | Godot 4.6 naming convention for imported node names. Keep at version 2. |

### Change from placeholder

| Parameter | Old value | New value | Reason |
|---|---|---|---|
| `meshes/light_baking` | `1` | `0` | Value `1` = "Disabled" in Godot 4.6 (0-indexed enum). **Confirm**: check Godot 4.6 docs for `meshes/light_baking` enum values — this is a post-knowledge-cutoff version, so the enum may differ from 4.3. The intent is: do NOT generate lightmap UV2 for this character. Pudge is a dynamic character using real-time lighting only. Generating lightmap UVs wastes import time. Technical-artist must verify the correct "disabled" enum value in Godot 4.6. |
| `gltf/embedded_image_handling` | `1` | `1` (no change, but review) | Value `1` = "Discard" embedded images. This is correct — Godot should not use the GLB-embedded textures; source PNGs at `src/assets/textures/heroes/pudge/` are the authoritative textures. Confirm this is the "Discard" value in Godot 4.6. |
| `materials/extract` | `0` | `0` — but Stage 8 must override materials manually | Value `0` = do not auto-extract materials to .tres files. The technical-artist manually creates `mat_pudge_body.tres` (custom ShaderMaterial) and `mat_pudge_hook.tres` and assigns them via the import override. See texture spec §14. |

### Settings the technical-artist must configure in Stage 8 (not in the .import file directly)

| Task | Method | Notes |
|---|---|---|
| Assign `mat_pudge_body.tres` (custom ShaderMaterial) | Import override in Godot editor's import panel → Material Overrides | Cannot be done in the .import file directly; requires the Godot editor's scene import post-process or a script. |
| Assign `mat_pudge_hook.tres` (StandardMaterial3D) | Same import override mechanism | |
| Configure LOD switch distances | On `MeshInstance3D` nodes after import: `visibility_range_begin`, `visibility_range_end`, `visibility_range_begin_margin`, `visibility_range_end_margin` | LOD switch distances from model spec §7: LOD0→LOD1 at 15 m, LOD1→LOD2 at 30 m, LOD2 transition end at 50 m. |
| Add BoneAttachment3D sockets | In the Godot scene after import | See rig spec §7 for socket names, bone targets, and position offsets. |
| Add SkeletonModifier3D for BellyJiggle spring | In the Godot scene after import | GDScript spring or `SkeletonModifier3D` resource. rig spec §4.1 / §14 Q5. |
| Add SkeletonModification3DTwoBoneIK nodes | In the Godot scene after import | rig spec §6. |
| Set animation event method tracks | In the Godot AnimationPlayer after import | Use exact frame numbers from Section 7 event table. |

---

## 12. Validation Script for `blender-export-check`

When the `blender-export-check` skill is invoked against `tools/blender/heroes/pudge.blend`,
the following checks must all pass before the GLB is handed to Godot. This list extends
the generic skill checklist with Pudge-specific constraints for the AI-mesh-retopo path.

**Script invocation:**
```bash
blender tools/blender/heroes/pudge.blend --background --python tools/blender/validate_export.py
```

Script header (spec per Section 14):
```python
# tools/blender/validate_export.py
# Purpose: Pre-export validation for Pudge character GLB — checks transforms,
#           modifier stacks, UV coverage, bone count, animation clips, and mesh budgets.
# Blender: 4.x
# Usage: blender tools/blender/heroes/pudge.blend --background --python tools/blender/validate_export.py
```

### Automated checks

| Check | Pass condition | Failure action |
|---|---|---|
| **Transform: Location** | All export objects (`mesh_pudge_body_lod0`, `mesh_pudge_hook_lod0`, `arm_pudge`, `pudge`) have location (0.0, 0.0, 0.0) in Object Mode | Apply Location (Ctrl+A → Location) on each offending object |
| **Transform: Rotation** | All export objects have rotation_euler (0, 0, 0) | Apply Rotation (Ctrl+A → Rotation) |
| **Transform: Scale** | All export objects have scale (1.0, 1.0, 1.0) | Apply Scale (Ctrl+A → Scale) |
| **Mesh origin** | `mesh_pudge_body_lod0` origin at (0, 0, 0). `mesh_pudge_hook_lod0` origin at (0, 0, 0). | Re-set origin via Object → Set Origin → Origin to Geometry or Origin to Cursor at (0,0,0) |
| **Source objects absent** | None of `textured_mesh`, `textured_mesh_source_prep`, `textured_mesh_bake_hp`, `mesh_pudge_body_cage` exist as objects in the scene (they must have been deleted before migration). | Delete any surviving source objects from the scene. |
| **Modifier stack: body LOD0** | `mesh_pudge_body_lod0` has exactly 1 modifier remaining (Armature). Any Shrinkwrap, Mirror, or other modifier is a blocker. | Apply or delete the offending modifier. |
| **Modifier stack: hook LOD0** | `mesh_pudge_hook_lod0` has exactly 1 modifier remaining (Armature). | Same. |
| **N-gon check** | Zero faces with vertex count > 4 on `mesh_pudge_body_lod0` and `mesh_pudge_hook_lod0`. LOD1/LOD2 objects may have n-gons from Decimate — warn but do not fail. | In Edit Mode: Select → All by Trait → Faces by Sides → Greater Than 4. Should select 0 on LOD0. |
| **Zero-area face check** | Zero faces with area < 0.000001 m² on any export mesh. | Edit Mode → Mesh → Clean Up → Degenerate Dissolve (preview). |
| **Normal direction** | No inside-out (flipped) normals on any export mesh. | Edit Mode → Viewport Overlay → Face Orientation. All blue (outward). Red faces = flip and recalculate outside. |
| **UV coverage: body** | Every face of `mesh_pudge_body_lod0` has UV coordinates within [0.0, 1.0] range. Zero faces with no UV assignment. UV map slot 0 is named `UVMap`. | UV Editor: check for islands outside the [0,1] tile. |
| **UV coverage: hook** | Same for `mesh_pudge_hook_lod0`. UV map slot 0 named `UVMap`. | Same. |
| **Material count** | Exactly 2 materials in the scene: `mat_pudge_body` and `mat_pudge_hook`. Zero orphan materials. | Outliner → Orphan Data → purge materials. |
| **Material assignment** | `mesh_pudge_body_lod0` (and LOD1/LOD2) have exactly 1 slot assigned `mat_pudge_body`. `mesh_pudge_hook_lod0` (and LOD1/LOD2) have exactly 1 slot assigned `mat_pudge_hook`. | Material Properties panel. |
| **jiggle_boundary layer** | `mesh_pudge_body_lod0` has a Color Attribute named `jiggle_boundary` (Domain = Vertex or Face Corner, Data Type = Byte Color or Float Color). | Object Data Properties → Color Attributes. Confirm layer present. If absent, the retopo handoff is incomplete. |
| **Bone count** | `arm_pudge` has exactly 27 bones. | `len(bpy.data.armatures["arm_data_pudge"].bones)` == 27. |
| **Bone names** | All 27 bone names match rig spec §13 exactly. PascalCase. No spaces. Names: Hips, Spine, Spine1, Chest, Neck, Head, Jaw, LeftShoulder, LeftArm, LeftForeArm, LeftHand, ChainLink1, ChainLink2, ChainLink3, ChainLink4, RightShoulder, RightArm, RightForeArm, RightHand, BellyJiggle, LeftUpLeg, LeftLeg, LeftFoot, RightUpLeg, RightLeg, RightFoot. | Rename in Edit Mode on armature. |
| **Armature scale** | `arm_pudge` scale = (1.0, 1.0, 1.0). Non-unit armature scale is the most common cause of wrong character scale in Godot. | Apply Scale on armature in Object Mode. |
| **Animation count** | Exactly 10 actions exist in the blend file. | Dope Sheet → Action Editor dropdown. `len(bpy.data.actions)` == 10. |
| **Animation names** | Exact names: `idle`, `walk`, `run`, `turn_in_place`, `hook_throw`, `hook_recover`, `attack_basic`, `hit_react`, `death`, `victory`. No prefix, no suffix. | Rename in Action Editor. |
| **NLA push-down** | All 10 actions have NLA strips on the armature. | NLA Editor: each action has a visible strip. |
| **Fake User** | All 10 actions have the Fake User flag set. | `bpy.data.actions["idle"].use_fake_user` etc. |
| **BellyJiggle: non-death clips** | BellyJiggle has zero keyframe rows in `idle`, `walk`, `run`, `turn_in_place`, `hook_throw`, `hook_recover`, `attack_basic`, `hit_react`, `victory`. | Check FCurves in each action: no data_path containing "BellyJiggle" except for those explicitly authored per rig spec §8. |
| **BellyJiggle: death clip** | BellyJiggle has at least 1 keyframe in the `death` action. | Confirm gut-deflate keyframes exist. |
| **hit_react BellyJiggle** | BellyJiggle has keyframes in `hit_react` action (the forward-slosh at frame 3 is explicitly authored per rig spec §8 Clip 8). | Check FCurves in hit_react action. |
| **IK constraints** | Zero IK bone constraints on any bone in `arm_pudge`. All IK baked to FK. | Pose Mode → Bone Constraint Properties. `bpy.data.objects["arm_pudge"].pose.bones[bn].constraints` has no type == "IK" for any bone. |
| **Chain constraints** | Zero Damped Track or Child Of constraints on ChainLink1–4. All chain sway baked to FK. | Same constraint check for chain bones. |
| **Hook prop weight: LeftHand 100%** | Every vertex of `mesh_pudge_hook_lod0` has exactly 100% weight to the `LeftHand` vertex group and 0% to all other groups. | Weight Paint mode: cycle through all bone groups and confirm only LeftHand has non-zero influence. |
| **Feet at Y=0** | Lowest vertices of `mesh_pudge_body_lod0` (boot sole) are at Y ≥ −0.001 m and ≤ +0.001 m. | Edit Mode, sort vertices by Y. `min(v.co.y for v in bm.verts)` ≥ −0.001. |
| **Total height** | Maximum Y vertex of `mesh_pudge_body_lod0` is between 1.33 m and 1.47 m (1.4 m ±5%). | `max(v.co.y for v in bm.verts)` in [1.33, 1.47]. |
| **Tri count: body LOD0** | `mesh_pudge_body_lod0` tri count ≤ 5,500 tris (body only, excluding hook). Working target: ≤ 4,840. Hard ceiling from model spec: ≤ 9,000. | Statistics overlay in Edit Mode. |
| **Tri count: hook LOD0** | `mesh_pudge_hook_lod0` tri count ≤ 600 tris (spec §1). | Statistics overlay. |
| **Collection visibility** | `_SOURCE` and `_BAKE` collections are hidden (or absent). `EXPORT_BODY`, `EXPORT_HOOK`, `EXPORT_ARMATURE` collections are visible. | Outliner eye icons. If source collections are absent (migration done correctly), this check passes automatically. |
| **Max vertex influences** | No vertex on any export mesh has more than 4 bone influences. | `Mesh → Weights → Limit Total` must report 0 affected vertices. |
| **GLB file size** | `pudge.glb` file size < 5 MB after export. | `os.path.getsize("src/assets/models/heroes/pudge.glb")`. |
| **Forward axis (post-export spot check)** | Import the exported .glb into a fresh Blender scene: character faces −Z with +Y up (belly facing toward the viewport in front view). | Visual verification in default front-view viewport. |

### Manual checks (performed in Blender before running the automated script)

```
[ ] Boot sole vertices at Y=0: Edit Mode, sort by Y, min Y ≥ -0.001
[ ] Normals: Viewport Overlay → Face Orientation → all faces blue (no red faces)
[ ] UV map named exactly "UVMap" on both body and hook (Object Data Properties → UV Maps)
[ ] jiggle_boundary Color Attribute present on mesh_pudge_body_lod0, lod1, and lod2
[ ] All NLA strips that were muted during authoring: confirm mute state does NOT affect export (test by importing a draft .glb)
[ ] All 10 animation clips played back in Blender: verify at F0 and last frame; loop clips confirm frame 0 = last frame
[ ] BellyJiggle: inspect Dope Sheet on each non-death clip — zero BellyJiggle rows (except hit_react per rig spec §8)
[ ] hook_release pose marker visible at frame 6 in hook_throw Dope Sheet (documentation marker — not exported to Godot)
[ ] hit_active pose marker visible at frame 7 in attack_basic (documentation marker only)
[ ] File → External Data → Report → no missing textures linked from bake outputs
[ ] Source objects absent from scene (textured_mesh*, mesh_pudge_body_cage deleted or in hidden collection)
[ ] Confirm hook_throw → hook_recover pose match: frame 12 of hook_throw = frame 0 of hook_recover (overlay check)
```

---

## 13. LOD Generation Plan

### LOD0 — retopologized low-poly (~6,100 tris including hook prop)

`mesh_pudge_body_lod0` is produced by the character-artist via manual retopology
of `textured_mesh_bake_hp` per retopo plan §D. It is not generated by Decimate.
LOD0 targets ≤ 5,500 tris (body) + ≤ 600 tris (hook) = ≤ 6,100 tris combined.

**Origin of LOD0 in the AI-mesh path**: The retopo is done in `anime_pudge.blend`.
When the file is migrated to `tools/blender/heroes/pudge.blend` (see Section 1),
the retopo mesh is renamed from `mesh_pudge_body` to `mesh_pudge_body_lod0` and
the hook from `mesh_pudge_hook` to `mesh_pudge_hook_lod0` at that time. Coordinate
this rename with the rigging-animator — any Blender constraints or skinning references
using the old name must be updated simultaneously.

**jiggle_boundary layer**: the `jiggle_boundary` Color Attribute must be present on
`mesh_pudge_body_lod0` before weight painting begins (retopo plan §G, rig spec §14
Blocker A). Confirm the layer survives any Duplicate/Join operations during LOD
generation — check after each operation.

### LOD1 — mixed Decimate + manual collapse (~3,050 tris)

Per retopo plan §H, LOD1 is generated by the character-artist (not by the blender-specialist)
via a two-pass approach: Planar Decimate (angle limit 5 degrees) for flat-panel regions,
then manual collapse of specific features listed in model spec §7.

The blender-specialist's role for LOD1:
1. Receive `mesh_pudge_body_lod1` from the character-artist with the `jiggle_boundary`
   Color Attribute present (verify — it must survive the Decimate and manual collapses
   per retopo plan §H step 4).
2. Assign the Armature modifier (`arm_pudge`) to LOD1. LOD1 is skinned and animates
   with the same skeleton — Godot swaps the mesh instance at the LOD distance threshold.
3. Copy vertex group weights from `mesh_pudge_body_lod0` to `mesh_pudge_body_lod1`
   via `Data Transfer` modifier (Source: `mesh_pudge_body_lod0`, mode: Nearest Face
   Interpolated). Apply the Data Transfer modifier. This transfers the rigging-animator's
   weight paint work to the LOD1 mesh without a full weight paint pass.
4. Confirm LOD1 tri count is 2,900–3,200 tris.
5. Repeat for `mesh_pudge_hook_lod1` (~300 tris). Hook prop: copy 100% LeftHand weight
   from hook LOD0 via Data Transfer.

**Features removed at LOD1 vs. LOD0** (model spec §7): chain link toroids → twisted quad
strip (~40 tris), teeth row → recessed single quad, boot lace stubs removed, eye spheres →
flat discs (24 tris), belt buckle → flat painted quad, apron stub deleted.

### LOD2 — Decimate + manual reduction (~1,500 tris)

Per retopo plan §H, LOD2 is generated from LOD1.

The blender-specialist's role for LOD2:
1. Receive `mesh_pudge_body_lod2` from the character-artist.
2. **Critical**: after belly ring reduction from 6 to 3 rings, the `jiggle_boundary`
   Color Attribute must be repainted by the character-artist on LOD2. The equator ring
   index has shifted. Verify the layer is present and correctly painted before proceeding
   (retopo plan §H step 4).
3. Assign Armature modifier. Copy weights from LOD1 via Data Transfer (same procedure
   as LOD1). Apply the modifier.
4. Confirm LOD2 tri count is 1,400–1,600 tris.
5. Repeat for `mesh_pudge_hook_lod2` (~150 tris).

**Verification**: At LOD2, Pudge must still read as a humanoid with a large gut from
the top-down 30-degree game camera at 30–50 m. If the silhouette collapses into an
unrecognizable blob, the Decimate ratio is too aggressive. Add 100–200 tris back.

### LOD3 — impostor billboard

NOT part of the main GLB or the `pudge.blend` working file. The impostor is a
separately generated 2D sprite sheet:

- **Format**: 8-frame sprite sheet, 128x128 px per frame (512x256 px or 1024x128 px strip).
- **Angles**: 8 rotation angles every 45 degrees (N, NE, E, SE, S, SW, W, NW from top-down).
- **Generation**: `technical-artist` renders from the LOD2 model in Stage 8, matching
  the game camera angle (top-down ~12 m, 30° pitch).
- **Output path**: `src/assets/textures/heroes/pudge/body_impostor.png` (per texture spec §11).
- **Delivery**: NOT the blender-artist's deliverable. NOT in `pudge.glb`. The impostor is
  a separate asset created in Stage 8.

### LOD suffix naming — Godot 4.6 auto-detection

**Confirmed behavior**: Godot 4.6 with `nodes/use_name_suffixes=true` (already set in
the placeholder .import) and `meshes/generate_lods=true` (also set) will interpret
mesh object names ending in `_lod0`, `_lod1`, `_lod2` as LOD levels of a parent mesh.
Specifically: Godot looks for objects where the base name before the suffix matches
(e.g., `mesh_pudge_body_lod0`, `mesh_pudge_body_lod1`, `mesh_pudge_body_lod2`).

**Action item**: LOD0 is currently named `mesh_pudge_body` (no `_lod0` suffix).
Rename it to `mesh_pudge_body_lod0` before export. This is the only naming change
from the model spec §10 table — it adds `_lod0` to the LOD0 body and hook objects.
Update the validation script's name checks accordingly.

**Revised naming**:

| Old name (model spec §10) | Revised name for Godot LOD detection |
|---|---|
| `mesh_pudge_body` | `mesh_pudge_body_lod0` |
| `mesh_pudge_hook` | `mesh_pudge_hook_lod0` |
| `mesh_pudge_body_lod1` | unchanged |
| `mesh_pudge_body_lod2` | unchanged |
| `mesh_pudge_hook_lod1` | unchanged |
| `mesh_pudge_hook_lod2` | unchanged |

If Godot 4.6's LOD auto-detection by suffix does not work as expected (the
`technical-artist` must verify during Stage 8 import), the fallback is to set
`visibility_range_begin`, `visibility_range_end` properties manually on each
`MeshInstance3D` node in the Godot editor after import. Either path works —
the suffix naming is the automated path; the manual property path is the fallback.

---

## 14. Reuse from Existing Pipeline

The `tools/blender/` directory contains an active procedural prop generation pipeline
(`generate.py`, `kenney_gen/`) that is unrelated to character export. The following
notes clarify what is reusable and what is not:

### Reusable: `export.py` in `kenney_gen/`

The `tools/blender/kenney_gen/export.py` module handles GLB export via
`bpy.ops.export_scene.gltf()`. The export settings it encodes may differ from the
Pudge character requirements (the kenney_gen pipeline generates simple props, not
skinned characters). However, the pattern of wrapping the glTF export in a Python
function with explicit keyword arguments is worth adopting for the Pudge validation
and batch export scripts. The blender-specialist should read `export.py` before
writing `tools/blender/validate_export.py` to reuse the Blender startup and scene
clear patterns.

### Not reusable: `primitives.py`, `heroes.py`, `generate.py`

These generate procedural Kenney-style primitive models. They are not used in the
Pudge handcrafted pipeline.

### New script to write: `tools/blender/validate_export.py`

The `blender-export-check` skill will write this script when invoked for Pudge.
It is the automated implementation of the check list in Section 11. Script header:

```python
# tools/blender/validate_export.py
# Purpose: Pre-export validation for Pudge character GLB — checks transforms,
#           modifier stacks, UV coverage, bone count, animation clips, and mesh budgets.
# Blender: 4.x
# Usage: blender tools/blender/heroes/pudge.blend --background --python tools/blender/validate_export.py
```

The script does not yet exist. The `blender-export-check` skill creates it on first
invocation, per its SKILL.md specification.

---

## 15. Open Questions and Blockers

### New blockers from the AI-mesh retopo path

**New Blocker N1 — Bake gate: watertight source verification**
Before any normal or AO bake pass, `textured_mesh_bake_hp` must pass the non-manifold
check (Section 8, bake gate table). If the voxel remesh at 3mm leaves any non-manifold
edges, the bake will have ray-cast errors that cannot be corrected in texture paint.
The blender-specialist owns verification; the character-artist fixes any remaining holes.
Status: must pass before bake begins.

**New Blocker N2 — Wrist truncation cap normals on `textured_mesh_bake_hp`**
After the hook geometry is deleted from the bake source (retopo plan §C), the wrist
truncation cap may have inward-facing normals. If these face inward, the left hand fist
area of the normal bake will have a visible seam. Verify and flip before the body normal
bake (retopo plan §I, Risk 2). Medium severity — if missed, the fist base has an unfixable
normal seam that the texture-artist cannot paint over.

**New Blocker N3 — Interior faces in `textured_mesh_bake_hp`**
AI-generated meshes frequently entrap interior geometry inside the closed voxel remesh
surface. Interior faces cause random dark spots in AO bakes. Verify: Select All → All
by Trait → Interior Faces in `textured_mesh_bake_hp`. Delete any interior faces before
baking. Expect 15–30 minutes of cleanup (retopo plan §I, Risk 3).

**New Blocker N4 — File migration timing**
The migration from `anime_pudge.blend` to `tools/blender/heroes/pudge.blend` must
happen after bake is complete but before rig authoring begins (Section 1 recommendation).
If the rigging-animator starts in `anime_pudge.blend` and the blender-specialist
migrates the file mid-session, skin weight data can be lost. Coordinate the migration
as a synchronization point between the character-artist (bake complete), rigging-animator
(not yet started), and blender-specialist (performs the migration).

**New Blocker N5 — LOD rename coordination (`mesh_pudge_body` → `mesh_pudge_body_lod0`)**
The retopo plan §J handoff checklist uses `mesh_pudge_body` as the LOD0 name (matching
the model spec §10 original name). The pipeline plan (Section 2) requires it to be
named `mesh_pudge_body_lod0` for Godot LOD auto-detection. This rename must happen
at migration time and must be propagated to: (a) the armature modifier on the object,
(b) any Blender constraints referencing the object name, (c) the weight paint vertex
groups. Coordinate with the rigging-animator before renaming if weight painting has
begun. Low risk but requires explicit coordination.

### Carried forward from Mixamo-path spec (still apply)

**Blocker A — LOD0 name change** (partially resolved as New Blocker N5 above):
Confirmed: the `_lod0` suffix is required. Action is the same as described above.

**Blocker B — AO bake completion gate**
The GLB may be exported before the final AO bake only if the export check passes
on all non-texture checks. The `technical-artist` cannot set up final Godot materials
in Stage 8 until the ORM maps (including baked AO in the R channel) are delivered.
For the AI-mesh path, the AO bake setup is in Section 8 (bake stage) of this document
and in retopo plan §F. The combined-scene requirement (both body and hook meshes
present during the AO bake) is the blender-specialist's responsibility to enforce.

**Blocker C — FK bake verification**
After baking IK to FK on all 10 clips, visually verify every clip plays back correctly
with IK constraints removed. The most likely failure on this chibi AI-mesh asset: the
left arm raised position in `idle` may look wrong after FK bake if the IK pole vector
was not correctly configured. Test all 10 clips at frame 0 and last frame before export.
Per rig authoring playbook §5, this is part of the pre-export preparation checklist.

**Blocker D — BellyJiggle track audit**
After authoring and baking all clips, audit every non-death clip in the Dope Sheet.
BellyJiggle must have zero keyframe rows in all clips except `death` and `hit_react`
(hit_react explicitly keyframes BellyJiggle per rig spec §8 Clip 8). Auto-keying
during pose adjustments frequently adds accidental tracks. Delete any accidental
BellyJiggle tracks before export.

**Question Q1 — Corrective blendshape (TBD by rigger)**
If the rigging-animator authored a corrective blendshape `correct_leftarm_raised`
on `mesh_pudge_body_lod0` (per rig spec §14 Blocker B), confirm it exports correctly
as a glTF morph target. Blender exports shape keys as morph targets in glTF. Godot
4.6 imports these as blend shapes on the `MeshInstance3D`.
**Knowledge-gap flag**: The glTF morph target import behavior was present in Godot 4.3
and is expected to be unchanged in 4.6, but the blend shape API naming convention
(`MeshInstance3D.get_blend_shape_count()`, etc.) should be verified against Godot 4.6
docs before the technical-artist wires the blend shape driver in Stage 8.
If the corrective blendshape is present, the technical-artist wires it to LeftArm
Z-axis rotation via an AnimationPlayer driven blend shape track.

**Question Q2 — Jaw bone scope**
The rig spec includes Jaw in the 27-bone count. If `taunt` is cut, Jaw may be left
unanimated. Do not remove the Jaw bone — `death` and `victory` animate it.

### For the technical-artist (Stage 8)

**T1 — `meshes/light_baking` enum verification (knowledge-gap flag)**
The placeholder import has `meshes/light_baking=1`. In Godot 4.6 (post-knowledge-cutoff
version), verify the exact integer value that means "Disabled." The LLM's training
data covers Godot up to ~4.3; this enum may have shifted. Setting the wrong value
silently generates UV2 lightmap channels and wastes import time. Verify in the Godot
editor's import dialog by checking the dropdown label that corresponds to value `1`.
The intent is: do NOT generate lightmap UV2 for this character. Use the actual enum
value — do not assume 0 = Disabled.

**T2 — `gltf/embedded_image_handling=1` verification (knowledge-gap flag)**
Confirm that value `1` in Godot 4.6 means "Discard" (ignore embedded GLB textures;
source PNGs at `src/assets/textures/heroes/pudge/` are authoritative). If this enum
value has changed in 4.6, the wrong value causes Godot to use the low-quality GLB-embedded
thumbnails instead of the source textures. Verify against Godot 4.6 import panel.

**T3 — LOD suffix auto-detection test**
After first import with `use_name_suffixes=true`, verify in the Godot editor's scene
tree that LOD meshes are automatically assigned. If suffix detection fails, manually
set `visibility_range_begin`, `visibility_range_end` on each `MeshInstance3D`. See
Section 13 LOD suffix note and import preset table in Section 11.
**Knowledge-gap flag**: LOD auto-detection by `_lod0/_lod1/_lod2` suffix was present
in early Godot 4.x. Behavior in 4.6 should be verified on first import — it may
require a specific import version flag or the suffix format may differ.

**T4 — BellyJiggle spring modifier implementation (knowledge-gap flag)**
The rig spec recommends a runtime `SkeletonModifier3D` GDScript spring. Implement
in Stage 8 as a configurable resource (spring stiffness, damping — data-driven per
coding standards). The modifier must have weight = 0 during the `death` clip.
**Knowledge-gap flag**: `SkeletonModifier3D` as a node type and its API were
present in Godot 4.x but the exact class name, property names, and whether
`SkeletonModification3DTwoBoneIK` (referenced in rig spec §6) is the correct class
name in Godot 4.6 must be verified against `docs/engine-reference/godot/VERSION.md`.
The VERSION.md notes "IK restored" in 4.6 — this is a high-risk area given that the
IK system changed significantly in the 4.4–4.6 range.

**T5 — Animation event method tracks**
Add method call tracks to the AnimationPlayer for all events listed in Section 7.
Coordinate signal names with the gameplay-programmer before adding tracks. If the
blender-specialist cannot export Blender pose markers as glTF extension data (confirmed:
glTF 2.0 has no standard animation event extension that Godot 4.6 reads), the
technical-artist adds all event tracks manually using the exact frame numbers from
Section 7.

**T6 — `jiggle_boundary` Color Attribute in Godot (informational)**
The `jiggle_boundary` vertex color layer exported from Blender as `COLOR_0` in glTF
will appear in Godot as a vertex color channel on the `MeshInstance3D`. The
technical-artist does not need to do anything with it — it is a rig authoring guide
embedded in the mesh for reference. If a custom shader needs to visualize it, it is
accessible as `COLOR_0`. Otherwise it is inert at runtime.

**T7 — LOD1 ChainLink bones at LOD1/LOD2**
Per rig spec §12: at LOD1+, set ChainLink1–4 bones to bind pose (static). Do not
modify the AnimationLibrary. Implement by adding a separate `idle_lod1` override in
the AnimationTree that masks the ChainLink bones to bind pose, or by configuring
the LOD1 MeshInstance3D to not animate chain geometry.

### For the gameplay-programmer

**G1 — hook_release frame timing confirmation**
Frame 6 of `hook_throw` (0.2 s into the 0.4 s clip). Confirm the gameplay event
system reads from AnimationPlayer signal tracks vs. physics-tick polling. If polling:
adjust by ±1 frame if spawning feels consistently early or late.

**G2 — hit_active swept vs. point hitbox**
Frame 7 of `attack_basic`. Confirm whether the hitbox is a sphere at `socket_offhand`
position at frame 7, or a swept volume across frames 6–9. The animator needs the
answer before `attack_basic` is locked.

**G3 — turn_in_place L/R mirror**
Confirm AnimationTree AnimationNode flip is used. If two clips are required, the
export action count changes from 10 to 11 — flag before animation authoring begins.

---

*End of Pudge Stage 5 Blender Pipeline Plan (AI-mesh retopo path, revised 2026-05-22).*

*Stage gate sequence:*
*1. Character-artist: retopo complete + bake complete + `jiggle_boundary` painted → handoff checklist (retopo plan §J) passes.*
*2. Blender-specialist: bake gate verified (Section 8 table) → file migrated to `tools/blender/heroes/pudge.blend`.*
*3. Rigging-animator: 27-bone rig + 10 clips + IK-to-FK bake + playbook §5 pre-export checklist → handoff to blender-specialist.*
*4. Blender-specialist: runs `blender-export-check` against `tools/blender/heroes/pudge.blend` → all Section 12 checks pass → GLB exported to `src/assets/models/heroes/pudge.glb`.*
*5. Technical-artist (Stage 8): imports GLB, verifies Section 11 import preset, resolves all T-items and knowledge-gap flags.*
