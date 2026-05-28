# Pudge — Stage 4 Rig + Animation Spec

> **Status**: DRAFT — pending rigger / animator review before Blender work begins
> **Hero ID**: `pudge`
> **Stage**: 4 of 8 (Rig + Animation Spec)
> **Date**: 2026-04-28
> **Author**: `rigging-animator` agent
> **Brief**: `/design/characters/pudge_brief.md`
> **Concept**: `/design/concept-art/pudge.md` — Silhouette B (Coiled Hook Carry) LOCKED
> **Model Spec**: `/design/gdd/models/pudge.md`
> **Loader Contract**: `src/gameplay/hero/hero_model_builder.gd:28-36`
> **Upstream**: character-artist delivers `mesh_pudge_body` + `mesh_pudge_hook`
> **Downstream consumers**: `gameplay-programmer` (event markers), `technical-artist`
>   (AnimationTree wiring, Stage 8), `blender-specialist` (GLB export, Stage 7)

This document is the written contract for all rigging and animation authoring on Pudge.
Nothing here may change without notifying downstream consumers and updating this file.

---

## 1. Skeleton Hierarchy

All bones are part of armature `arm_pudge` (Blender object name per model spec §10).
Indentation denotes parent → child relationships. Bone names use PascalCase to
match Godot Humanoid retargeting expectations (see model spec §10 and brief §5).

```
ROOT (scene root — no bone; world origin, Y=0 plane)
└── Hips
    ├── Spine
    │   └── Spine1
    │       ├── BellyJiggle                   [helper — secondary motion]
    │       └── Chest
    │           ├── Neck
    │           │   └── Head
    │           │       └── Jaw               [helper — optional; see §4]
    │           ├── LeftShoulder
    │           │   └── LeftArm
    │           │       └── LeftForeArm
    │           │           └── LeftHand
    │           │               ├── ChainLink1  [helper — chain sim]
    │           │               │   └── ChainLink2
    │           │               │       └── ChainLink3
    │           │               │           └── ChainLink4
    │           └── RightShoulder
    │               └── RightArm
    │                   └── RightForeArm
    │                       └── RightHand
    ├── LeftUpLeg
    │   └── LeftLeg
    │       └── LeftFoot
    └── RightUpLeg
        └── RightLeg
            └── RightFoot
```

### Bone Count Summary

| Region | Bones | List |
|---|---|---|
| Core spine | 4 | Hips, Spine, Spine1, Chest |
| Head / neck | 3 | Neck, Head, Jaw |
| Left arm chain | 5 | LeftShoulder, LeftArm, LeftForeArm, LeftHand + (see below) |
| Right arm chain | 4 | RightShoulder, RightArm, RightForeArm, RightHand |
| Left leg chain | 3 | LeftUpLeg, LeftLeg, LeftFoot |
| Right leg chain | 3 | RightUpLeg, RightLeg, RightFoot |
| **Humanoid subtotal** | **22** | Standard humanoid bones from brief §5 |
| BellyJiggle | 1 | Child of Spine1 |
| ChainLink1–4 | 4 | Children of LeftHand, chained |
| **Helper subtotal** | **5** | |
| **TOTAL** | **27** | Well inside the 50-bone ceiling (brief §5) |

Twist bones (forearm/thigh twist) are NOT included. Pudge's chibi stubby limbs are
short enough that candy-wrapping is not a visible issue at LOD0 poly density. If the
character-artist's retopo reveals twist artifacts during QA pose testing (see §5),
add `LeftForeArmTwist` and `RightForeArmTwist` as optional bones, keeping total at 29.
This remains well under 50.

Note on Jaw: included in the base count (27). If the `taunt` and `death` clips do not
require jaw movement — see §4 for the decision — the bone is simply left unanimated.
It costs nothing at runtime if unused in AnimationPlayer tracks.

---

## 2. Bind Pose Specification

The bind pose is an A-pose, NOT the Silhouette B raised-arm rest pose. The raised-arm
rest is driven by the `idle` animation clip. This is the standard practice confirmed
in concept §Open Notes for `rigging-animator` note 6 and brief §5.

### Global Orientation

| Axis | Value |
|---|---|
| Forward | -Z (Godot default) |
| Up | +Y |
| Feet plane | Y = 0.0 (bottom of boot soles) |
| Mesh root at | World origin (0, 0, 0) — no transform offset on GLB root |
| Total height | 1.4 m (skull top to boot sole) |

### Joint Angles in Bind Pose (local rotation from parent, Euler XYZ degrees)

All values are approximate targets for the rigger. Symmetrical joints (right = mirror
of left unless noted).

| Bone | X (pitch) | Y (yaw) | Z (roll) | Notes |
|---|---|---|---|---|
| Hips | 0 | 0 | 0 | World-aligned reference bone |
| Spine | +5 | 0 | 0 | Very slight forward lean for the hunch |
| Spine1 | +5 | 0 | 0 | Continues the hunch arc; belly mass anchored here |
| Chest | +5 | 0 | 0 | Total forward lean ~15 degrees from vertical — reads as the hunch |
| Neck | 0 | 0 | 0 | Near-zero rotation; compressed stub per model spec §2 |
| Head | -5 | 0 | 0 | Very slight chin-down; no-neck geometry means minimal tilt needed |
| Jaw | 0 | 0 | 0 | Closed at rest |
| LeftShoulder | 0 | 0 | +5 | Slight outward shrug; hook arm side |
| RightShoulder | 0 | 0 | -5 | Mirror |
| LeftArm | 0 | 0 | -30 | Arms ~30 degrees down from horizontal (A-pose per brief §5) |
| RightArm | 0 | 0 | +30 | Mirror |
| LeftForeArm | 0 | 0 | 0 | Straight continuation of upper arm in bind |
| RightForeArm | 0 | 0 | 0 | Mirror |
| LeftHand | 0 | 0 | 0 | Fist neutral, palm facing medially |
| RightHand | 0 | 0 | 0 | Mirror |
| LeftUpLeg | 0 | 0 | +5 | Slight outward spread; chibi stance |
| RightUpLeg | 0 | 0 | -5 | Mirror |
| LeftLeg | 0 | 0 | 0 | Straight in bind; IK will adapt in animations |
| RightLeg | 0 | 0 | 0 | Mirror |
| LeftFoot | +5 | 0 | 0 | Foot tilted slightly forward; boot sole at Y=0 |
| RightFoot | +5 | 0 | 0 | Mirror |

### Key Bone Positions in Bind Pose (Y values, approximate; model spec §6 reference)

| Bone | Y position (world) | Notes |
|---|---|---|
| LeftFoot / RightFoot | 0.05 | Ankle pivot; boot sole sits at Y=0 |
| Hips | 0.30 | Hip pivot above boot height |
| Spine | 0.42 | Base of belly mass |
| Spine1 | 0.55 | Belly equator height; BellyJiggle child here |
| Chest | 0.72 | Upper chest / socket_chain_origin level |
| Neck | 0.90 | Compressed; nearly at Head level |
| Head | 0.98 | Skull center |
| LeftArm / RightArm | 0.74 | Shoulder joint (at Chest height, chibi) |
| LeftHand / RightHand | 0.38 | A-pose hang position |

These are targets derived from the primitive build in `hero_model_builder.gd:58-230`
(torso center at Y=0.5, head at Y=1.05, hands at Y=0.30) and scaled to the 1.4 m
total-height target from model spec §6.

---

## 3. Bind Pose QA Checklist

Before weight painting begins, the rigger must verify all of the following in Blender:

- [ ] Boot sole vertices touch Y=0.0 (no gap, no penetration)
- [ ] Mesh root (armature object origin) is at (0, 0, 0)
- [ ] All mesh objects have scale (1, 1, 1) after applying transforms
- [ ] Forward face of Pudge's belly faces -Z (hook is on the left from behind)
- [ ] LeftHand bone tip is at the palm center in the left fist mesh
- [ ] Hips bone is the only root-level bone under the armature (no floating bones)
- [ ] BellyJiggle bone lies along the +Z axis of its Spine1 parent (belly protrudes forward)

---

## 4. Helper Bones

### 4.1 BellyJiggle

**Parent**: Spine1
**Position offset from Spine1**: (0.0, 0.0, +0.20) in Spine1 local space. This
places the bone 20 cm forward of Spine1, near the belly equator — the center of mass
for the gut sphere.
**Orientation**: Bone tip points in the +Y direction (upward) in local Spine1 space,
so rotation tracks belly sway vertically. The secondary motion of the gut is primarily
a vertical bob (up-down) with a secondary forward-lag.
**Influence radius**: 100% on the belly equator ring and forward-facing lower rings;
tapers to 0% at the torso-join loop above and hip-join loop below (see §5 skinning
plan and model spec §11, rigger note 1).

**Drive strategy: hybrid — spring constraint in idle/locomotion, keyframed in death.**

Recommendation: Author BellyJiggle as a Blender bone constraint using a `Copy Rotation`
constraint with a `Damped Track` modifier, or use a custom spring simulation script in
Blender's NLA during animation baking. In Godot 4.6, drive the belly sway at runtime
using `SkeletonModifier3D` with a custom GDScript spring simulation (a simple
position-lag on a BoneAttachment3D target). This offloads belly jiggle from all 10
animation clips and makes the jiggle reactive to character acceleration — it will
naturally sway harder during run transitions.

Exception: the `death` clip MUST keyframe BellyJiggle explicitly. Per concept §Open
Notes for `rigging-animator` note 3: the gut-deflate-last sequence after the body
falls requires a deliberate squash on the belly sphere that a spring constraint cannot
reliably author (the deflate is a timed, held deformation, not a reactive bounce).
The animator should use an animation layer to override the spring during the `death`
clip.

**Model spec blocker response**: The model spec §11 rigger note 1 specifies that
the character-artist must mark the BellyJiggle influence boundary on the retopo mesh
using vertex color annotation before weight painting. The rigger must explicitly
request this annotation from the character-artist before touching skin weights.
Failure to do so will result in the jiggle bone bleeding into the spine or hip mesh.
The recommended annotation is a Blender vertex color layer named `jiggle_boundary`
painted red (1.0) at 100% influence, white (0.0) at 0% influence, interpolated
across the transition rings.

### 4.2 Jaw

**Decision: Include. Do not skip.**

Rationale: The `death` clip requires the "gut deflates last" narrative — and that
narrative is more impactful if Pudge's mouth also falls open as he dies. The `victory`
clip (looping post-match) calls for "big laugh" which needs jaw movement. Including
Jaw costs 27 → 27 bones (already counted) and zero animation overhead on clips that
ignore it. Omitting it would require a corrective blendshape or painted-closed
geometry to sell the death expression — more expensive overall.

**Parent**: Head
**Position offset from Head**: (0.0, -0.10, +0.05) in Head local space. Places the
jaw pivot at the lower jaw hinge, behind the front teeth geometry.
**Range of motion**: Maximum 30-degree X-axis rotation (open). Clamp to prevent
jaw-through-belly clipping; Pudge's no-neck geometry means the jaw opens toward
the chest area which is close.
**Clips that animate Jaw**: `death` (opens on impact, closes limply on thud),
`victory` (rhythmic open-close for laugh cadence).
**Clips that leave Jaw at rest**: all others (idle, walk, run, hook_throw,
hook_recover, attack_basic, hit_react, turn_in_place).

### 4.3 ChainLink1–4 (Chain Simulation Bones)

**Parent chain**: ChainLink1 → LeftHand; ChainLink2 → ChainLink1;
ChainLink3 → ChainLink2; ChainLink4 → ChainLink3.

**Position offsets** (each bone's tail from parent head, in parent local space):
- ChainLink1: (−0.04, 0.0, +0.08) — exits the left hand palm, angling slightly
  toward the body (chain droops inward toward belt)
- ChainLink2: (0.0, −0.06, +0.08) — begins the catenary drop
- ChainLink3: (0.0, −0.08, +0.06) — continues drop toward belt level
- ChainLink4: (0.0, −0.10, +0.02) — arrives near the belt coil visual anchor

Each bone is 4 cm (0.04 m) in length, matching the approximate 80-tri iron link
geometry from model spec §1. The 4 bones correspond to the 4 visible chain links
that drape between hand and belt in Silhouette B.

**Drive strategy**: See §12 for full chain sway authoring strategy. Short version:
in `idle` and locomotion clips, chain bones are driven by Blender's `Spring Bone`
add-on or a manual lag constraint during animation baking — not keyframed individually
per clip. At LOD1+, these bones become static (technical-artist disables the
spring modifier in Stage 8 for LOD1/LOD2 instances).

**Skinning**: The 4 visible chain link meshes (part of `mesh_pudge_body`) are each
weighted 100% to their corresponding chain bone. No blending between chain bones.
The hook prop (`mesh_pudge_hook`) is 100% weighted to LeftHand only — hook-attached
links are NOT driven by ChainLink bones.

---

## 5. Skinning / Weight Paint Plan

Max influences per vertex: **4** (Godot 4.6 default; do not exceed).
Normalize weights: yes, Godot auto-normalizes on import but normalize in Blender
before export to avoid floating-point artifacts.

### Per-Region Strategy

**Shoulders — Left (4-loop hook arm; highest deformation priority)**

The model spec §2 flags 4 loops on the left shoulder socket. Weight strategy:
- LeftShoulder: 100% on the top-of-shoulder cap geometry
- LeftShoulder / LeftArm blend: 50% each in the mid-shoulder transition loop
- LeftArm: 100% at the upper arm cylinder, 2 loops below the joint

The hook arm raises to ~45 degrees above horizontal in the `idle` animation layer.
Test at 45-degree raise in the QA pose gate before signoff. See §5 QA poses below.

Model spec blocker: if pinching occurs at 45-degree raise, add a corrective
blendshape named `correct_leftarm_raised` on `mesh_pudge_body`. This blendshape
must be flagged to the character-artist to include in the blend file. Decision:
**TBD by rigger after QA pose test** (see §14 open questions).

Right shoulder uses 3 loops (model spec §2) — same strategy with 3-loop blend zone.
Right arm range is limited to the cleaver swing arc in `attack_basic` (approximately
0 to -70 degrees Z-axis); lower risk than the left shoulder.

**Elbows and Knees — standard 2-bone blend**

For LeftForeArm/LeftArm junction and all knee joints:
- Bone above: 100% → 50% gradient over 2 loops above joint
- Bone below: 0% → 100% gradient over 2 loops below joint
- Center loop at joint: 50/50
No more than 2 bone influences needed at elbow/knee; keep at 2 to reserve the
influence budget for shoulders (which may need 3).

**Hips / Spine — broad blend for waddle**

- Hips: 100% on the pelvis mass, transitioning over 2 loops into LeftUpLeg/RightUpLeg
- Spine: blends from Hips (40%) at lower belly, Spine (60%) at mid-belly level
- Spine1: 80% at belly equator, 20% from Spine above; BellyJiggle bleeds in here

**Belly — jiggle bone influence zone**

Driven by the vertex color annotation `jiggle_boundary` from the character-artist:
- BellyJiggle: 0.0–1.0 influence mapped from annotation layer
- Maximum BellyJiggle influence: 80% (keep Spine1 at 20% minimum to prevent
  the belly from detaching visually from the spine during extreme spring deflection)
- The Hips and Spine bones must have zero influence on the belly equator ring;
  only Spine1 and BellyJiggle may touch the equator

**Wrists — clean 2-bone blend**

- LeftForeArm / LeftHand: same 2-loop blend strategy as elbow
- LeftHand: 100% on the fist geometry; no bleed into ChainLink bones
- The hook prop `mesh_pudge_hook` must be weighted 100% to LeftHand, 0% elsewhere
  (confirmed from model spec §3 and §11 rigger note 4). A weight-paint verification
  pass on `mesh_pudge_hook` is a hard gate before handoff.

**Apron Stub — rigid weight to Hips**

Per the brief: the apron stub is rigid, no independent jiggle. Weight 100% to Hips.
This is intentional — the stub is tucked under the belt and barely visible; simulating
it adds complexity for no visual return at game camera distance.

### Deformation Gate — 4 Extreme QA Test Poses

The rigger must test and pass all 4 poses before moving to animation authoring
(Stage 5 gate per brief §11 pipeline stage 5).

| Pose | Description | What to verify | Justification |
|---|---|---|---|
| **QA1 — Raised Hook Arm** | LeftArm raised 45 degrees above horizontal (Silhouette B idle position) | Left shoulder 4-loop deformation; no pinching or triangle collapse at shoulder cap | Highest-risk deform zone; the idle animation lives here permanently |
| **QA2 — Full Hook Throw Wind-up** | LeftArm pulled back ~20 degrees behind body, LeftForeArm bent 90 degrees inward, wrist rotated 45 degrees | Elbow and wrist deformation; no gut clipping; forearm twist acceptable (no twist bone) | hook_throw wind-up is the most extreme arm position in the animation set |
| **QA3 — Squat Waddling Extreme** | Both UpLegs at 30 degrees Z outward, both Legs at 20 degrees X bend, Hips translated down 10 cm from bind | Hip and knee deformation under walk/run waddle extreme frame; boot soles stay at Y=0 IK-locked | Walk/run cycles push the hip and knee into their widest stance frames |
| **QA4 — Death Sprawl** | Hips rotated 90 degrees backward (fallen), Spine1 at -60 degrees (arched back on ground), arms spread wide, BellyJiggle at -0.12 m squash offset | Full-body deformation under fall; spine deformation, shoulder passthrough; BellyJiggle at maximum squash | death clip is the highest-entropy full-body pose; nothing can clip through the belly |

Reasoning for this set over alternatives: "T-pose stretch" was rejected because
Pudge's chibi A-pose already tests the stretch range, and a pure T-pose is not
used in any animation. "Fetal curl" was rejected because Pudge does not reach a
fetal pose — the gut physically prevents it and no animation approaches it.
QA1+QA2 together fully cover the arm deformation space, QA3 covers locomotion, and
QA4 covers the death outlier.

---

## 6. IK Chain Setup

### Strategy Decision: FK skeleton in Blender, IK added engine-side in Godot.

**Rationale**: Blender IK constraints do not export cleanly via GLTF. GLTF 2.0 does
not carry IK constraint data. Exporting Blender IK bakes the IK result into FK keyframes,
which is correct for animations — but loses the live IK solver needed for ground
adaptation at runtime. Therefore: author all animations in Blender using Blender IK
for the animator's convenience during authoring, bake IK to FK on export, and
reconstruct the live IK chains engine-side using Godot 4.6
`SkeletonModification3DTwoBoneIK`.

The GLTF export from Blender bakes IK results into FK bone tracks. The Godot scene
setup (Stage 8, technical-artist) adds `SkeletonModifier3D` nodes with
`SkeletonModification3DTwoBoneIK` for runtime ground adaptation and hook-hand
placement. The `gameplay-programmer` drives the IK target positions via code.

### Godot 4.6 IK Modifier Confirmation

`SkeletonModification3DTwoBoneIK` is confirmed available in Godot 4.6. The IK
system was restored and extended in 4.6 (per `docs/engine-reference/godot/VERSION.md`
— "IK restored" in 4.6 key theme). Use `SkeletonModifier3D` as the container node;
`SkeletonModification3DTwoBoneIK` is the modification resource applied to it.

### IK Chains — 4 Total

**Chain 1: Left Arm IK (hook hand placement)**
- Bones: LeftArm (root) → LeftForeArm → LeftHand (tip/effector)
- Solver: `SkeletonModification3DTwoBoneIK`
- Pole vector: positioned in front of and slightly left of the left shoulder,
  approximately at (−0.5, 0.9, −0.3) in model local space. This pushes the elbow
  forward and outward, which is Pudge's natural hook-carrying stance.
- Use: Hook-throw targeting. During `hook_throw`, the gameplay programmer moves the
  IK target forward to drive the wind-up and release naturally. During `idle`,
  `walk`, `run`, the IK target is parked at a rest position matching the baked FK
  idle pose so the IK solver does not fight the animation.
- Engine-side note: IK is blended off (weight = 0) during most animation clips and
  blended in only for `hook_throw`. The technical-artist handles blend weight in
  the AnimationTree (Stage 8).

**Chain 2: Right Arm IK (optional, cleaver swing assist)**
- Bones: RightArm → RightForeArm → RightHand
- Solver: `SkeletonModification3DTwoBoneIK`
- Pole vector: in front of and slightly right, approximately (0.5, 0.9, −0.3)
- Use: Procedural cleaver target adjustment if the character-artist or gameplay
  programmer needs it for environmental interaction. Primarily driven by FK in
  `attack_basic` and `victory`. Flag to technical-artist: right arm IK is
  lower priority; may be deferred to post-launch polish.

**Chain 3: Left Leg IK (ground adaptation)**
- Bones: LeftUpLeg (root) → LeftLeg → LeftFoot (tip/effector)
- Solver: `SkeletonModification3DTwoBoneIK`
- Pole vector: forward of the knee, approximately (−0.2, 0.3, −0.3) in model space.
  This keeps the knee bending forward-outward (chibi waddle direction).
- IK target: a `Marker3D` node positioned at the projected foot contact point on the
  terrain surface, updated by gameplay code each frame using a raycast.
- Rest target: matches the baked FK foot position from the authored walk/run cycle.
  Per concept §Open Notes for `rigging-animator` note 5: the IK rest target must match
  the squat-forward boot sole position, NOT a straight-leg default. Pudge must not
  straighten his legs on flat ground.

**Chain 4: Right Leg IK (ground adaptation)**
- Identical setup to Chain 3, mirrored.

### IK Workflow in Blender (for animator)

1. Set up Blender Armature IK constraints on both arm chains and both leg chains
   for animation authoring convenience.
2. Author all 10 animation clips using the Blender IK to position hands/feet.
3. Before GLTF export: select all animation clips in the NLA editor and bake to
   FK using `Pose → Animation → Bake Action` with `Visual Keying` enabled.
4. Disable or remove the Blender IK constraints after baking — they must not
   appear in the GLTF (they will be ignored anyway, but clean export is preferred).
5. The blender-specialist verifies baked FK output in the export check pass.

---

## 7. Sockets — BoneAttachment3D Definitions

All transforms are in the parent bone's local space at bind pose (A-pose). Rotations
are Euler XYZ degrees. The technical-artist creates these as `BoneAttachment3D` nodes
in the Godot scene during Stage 8.

### socket_hook_hand → LeftHand

| Property | Value |
|---|---|
| Position offset (bone local) | (0.0, 0.0, −0.05) |
| Rotation (bone local) | (−15, 0, 0) degrees |
| Notes | 5 cm forward along LeftHand's −Z axis, placing socket at the hook handle grip point. The X-rotation of −15 degrees tilts the hook tip slightly forward-downward in the bind A-pose. At the raised-arm idle position (driven by animation), the hook tip faces forward-outward matching Silhouette B. Hook prop mesh is parented here; 100% weighted to LeftHand. |

### socket_offhand → RightHand

| Property | Value |
|---|---|
| Position offset (bone local) | (0.0, 0.0, −0.04) |
| Rotation (bone local) | (0, 0, 0) degrees |
| Notes | 4 cm forward of right palm center. Cleaver/secondary prop attachment. No rotation offset needed — cleaver orientation is authored in the prop itself. |

### socket_chain_origin → Chest

| Property | Value |
|---|---|
| Position offset (bone local) | (−0.08, 0.05, 0.0) |
| Rotation (bone local) | (0, 0, 0) degrees |
| Notes | 8 cm to character's left (hook arm side), 5 cm above Chest bone origin. Places socket at upper-left chest near the visual chain exit point. Used as VFX chain anchor fallback when LeftHand is offscreen during hook_throw. |

### socket_hit_center → Spine1

| Property | Value |
|---|---|
| Position offset (bone local) | (0.0, 0.0, 0.12) |
| Rotation (bone local) | (0, 0, 0) degrees |
| Notes | 12 cm forward of Spine1 origin, at the belly equator maximum protrusion point. Forward is +Z in bone local space (Spine1's forward faces the belly direction). Hit VFX sprays outward from here. |

### socket_head_top → Head

| Property | Value |
|---|---|
| Position offset (bone local) | (0.0, 0.18, 0.0) |
| Rotation (bone local) | (0, 0, 0) degrees |
| Notes | 18 cm above the Head bone origin, reaching the top of the 0.42 m skull dome. Status icons (stun halo, level-up burst) float above this point. |

---

## 8. Animation Set — 10 Clips, Frame-Accurate Spec

**Global settings for all clips**:
- Frame rate: 30 fps
- Root motion: OFF — all clips authored in-place, no horizontal root translation
- Reference pose: A-pose bind. Every clip's first frame must be reachable from the
  A-pose via a short blend. Every non-looping clip must end in a pose compatible
  with `idle` for clean blending back.
- Feet at Y=0: foot IK targets lock the boot soles to Y=0 throughout all locomotion
  clips. No foot slide.
- Belly jiggle: unless noted as "keyframed," the BellyJiggle bone is driven by the
  runtime spring modifier. The animator leaves BellyJiggle unanimated in most clips.

---

### Clip 1 — idle

| Property | Value |
|---|---|
| Name | `idle` |
| Duration | 2.0 s / 60 frames at 30 fps |
| Loop | Yes — first frame and last frame must match pose exactly |
| Root motion | No |
| Playback rate | 1.0 |

**Pose narrative**: Frame 0 is the Silhouette B rest pose — left arm raised, hook at
shoulder height, chain draping. Frames 0–20 are a slow, heavy breathing cycle: the
Chest and Spine1 translate forward by 2–3 cm and the whole torso rises ~1 cm on
inhale. Frames 20–40 exhale back. Frames 40–55 introduce a subtle LeftArm twitch:
the hook rotates 5–10 degrees as if Pudge is idly swinging it. Frame 55–60 returns
to the opening Silhouette B pose. The head rocks very slightly left on the tilt axis
(2–3 degrees Y) in the twitch phase.

**Bones moved**: Spine1 (breathing), Chest (breathing), LeftArm (raise + twitch),
LeftForeArm (twitch), LeftHand (twitch), Head (subtle sway). ChainLink1–4 driven
by spring modifier, NOT keyframed.

**Event markers**: None required. The `idle` clip is a passive loop; no gameplay
events fire from it.

**Belly jiggle**: Spring modifier handles sway reactively. BellyJiggle is not
keyframed in this clip. If testing reveals the spring lag produces a distracting
constant oscillation on a stationary character, the animator may add a very low-
amplitude (0.01 m) manual keyframe cycle to BellyJiggle as a damping baseline.

**Raised-arm rest**: This clip drives the raised-arm rest. Frame 0 is the target
Silhouette B pose, not the A-pose bind. The IK blend for the left arm is active
in idle (IK target parked at the Silhouette B hand position, so IK and FK agree).

**Loop match**: Frame 60 = Frame 0. Verify by overlaying the two frames in Blender
before export.

---

### Clip 2 — walk

| Property | Value |
|---|---|
| Name | `walk` |
| Duration | 0.8 s / 24 frames at 30 fps |
| Loop | Yes |
| Root motion | No |
| Playback rate | Variable (AnimationTree controls speed based on character velocity) |
| Canonical authoring speed | 8 m/s character movement speed. Author the walk cycle at 8 m/s in-place foot timing — i.e., foot contact frames are timed for a character covering 8 m per second, even though no root motion is exported. The AnimationTree's BlendSpace1D (Stage 8) will scale playback rate proportionally. |

**Pose narrative**: A heavy waddle built from side-to-side hip sway. Left foot contact
at frame 0; right foot contact at frame 12 (half-cycle). The gut bounces vertically
on each foot contact — Spine1 translates down by ~1.5 cm at each heel strike. The
left arm maintains the raised Silhouette B position throughout; it does not swing.
Only a subtle 5-degree Z-axis counter-rotation keeps the hook from feeling frozen.
The right arm swings forward-back by ~15 degrees to provide locomotion read.

**Bones moved**: Hips (waddle sway left-right, 8–10 degrees Z), LeftUpLeg,
RightUpLeg, LeftLeg, RightLeg, LeftFoot, RightFoot (leg swing + IK foot plant),
Spine1 (vertical bounce), LeftArm (subtle hold), RightArm (swing), RightForeArm,
RightHand.

**Event markers**:
- Frame 0: `footstep_left` — left foot strikes ground (sound trigger)
- Frame 12: `footstep_right` — right foot strikes ground

**Belly jiggle**: Spring modifier. Foot-contact jolts will trigger natural spring
response without keyframes. If jiggle amplitude is too strong in testing, reduce
spring stiffness for the walk state (technical-artist configures spring parameters
in Stage 8).

**Loop match**: Frame 24 = Frame 0 (exact left foot contact position).

---

### Clip 3 — run

| Property | Value |
|---|---|
| Name | `run` |
| Duration | 0.6 s / 18 frames at 30 fps |
| Loop | Yes |
| Root motion | No |
| Playback rate | Variable (same BlendSpace1D as walk) |
| Canonical authoring speed | 14 m/s (Pudge's maximum sprint speed; confirm value with gameplay-programmer) |

**Pose narrative**: Same waddle as walk but with larger amplitude and more forward
lean. Hips sway 12–14 degrees Z-axis. Spine1 pitches an additional 3 degrees forward
(leaning into the run). Gut bounce amplitude increases to ~2.5 cm per footfall.
The left arm with the hook swings slightly more than in walk — a 10-degree arc on
the Z-axis. Right arm swings 20–25 degrees. Foot contact frames are closer together
(compressed cycle). Pudge's run looks like a jog, not a sprint — his legs are too
short for explosive power, so the animation sells effort through torso motion.

**Bones moved**: Same as walk with increased amplitudes. Spine1 adds forward pitch.
ChainLink1–4 will swing more noticeably via spring due to higher acceleration — test
whether chain sway is excessive in run-to-stop transitions.

**Event markers**:
- Frame 0: `footstep_left`
- Frame 9: `footstep_right` (half-cycle at 18 frames)

**Belly jiggle**: Spring modifier; same as walk but expect more amplitude due to
larger Spine1 excursion.

**Loop match**: Frame 18 = Frame 0.

---

### Clip 4 — turn_in_place

| Property | Value |
|---|---|
| Name | `turn_in_place` |
| Duration | 0.5 s / 15 frames at 30 fps |
| Loop | No |
| Root motion | No |
| Playback rate | 1.0 |

**Pose narrative**: A 90-degree Hips-driven rotation in-place. The body leads; the
head and hook arm lag behind by 2–3 frames, then catch up. Frame 0: Silhouette B
idle pose. Frames 0–8: Hips rotate 90 degrees around Y-axis while the upper body
rotates only 60 degrees (head and arm lagging). Frames 8–15: head and arm complete
the rotation to match Hips. Frame 15 matches a clean cardinal direction hold pose.
Author one clip for left turn; the AnimationTree mirrors it for right turns using
horizontal flip. The brief §4 notes "mirror for L/R" — confirm with gameplay-
programmer that the AnimationTree uses `AnimationNode` flip parameter.

**Bones moved**: Hips (Y rotation 90 degrees), Spine, Spine1, Chest (lag rotation),
Head (lag), LeftArm (lag), RightArm (lag), Neck (minimal).

**Event markers**: None. Turn is a blendable transition clip, not an action clip.

**Belly jiggle**: Spring modifier will produce a natural side-sway on the rapid turn.
This is desirable; no keyframe override.

**Raised-arm note**: Frame 0 and Frame 15 both hold the Silhouette B raised-arm
position so the clip blends cleanly into idle.

---

### Clip 5 — hook_throw

| Property | Value |
|---|---|
| Name | `hook_throw` |
| Duration | 0.4 s / 12 frames at 30 fps |
| Loop | No |
| Root motion | No |
| Playback rate | 1.0 |

**Pose narrative**: Frame 0 is the Silhouette B idle raised-arm pose. Frames 0–3:
wind-up — LeftArm pulls back and upward by ~20 degrees, LeftForeArm extends, the
torso (Spine1, Chest) rotates left 10 degrees. Frame 3 is maximum wind-up. Frames
3–6: release phase — LeftArm drives forward explosively, LeftForeArm snaps out
to near-full extension. The hook prop's forward momentum is implied by the speed
of this motion. Frame 6: **hook_release** fires. At this frame, the hook is at the
forward-most extension of the left hand, and gameplay code spawns the hook projectile.
Frames 6–12: follow-through — the arm continues forward by 10 more degrees, then
begins to arc back toward the recover pose. Frame 12 matches the start of
`hook_recover`.

**Bones moved**: LeftArm, LeftForeArm, LeftHand, LeftShoulder, Spine1 (counter-
rotation), Chest, Hips (slight counter-lean).

**Event markers**:
- **Frame 6**: `hook_release` — CRITICAL. Gameplay spawns the hook projectile at
  this frame using the `socket_hook_hand` transform. Timing confirmed with brief §4.
  Coordinate exact frame with gameplay-programmer before finalizing the clip.

**Belly jiggle**: The torso rotation will trigger spring response. The belly swings
slightly left as Pudge pivots into the throw — natural secondary motion.

**Chain bones during hook_throw**: ChainLink1–4 must be animated explicitly in this
clip to show the chain paying out as the hook is released. Author ChainLink1–4 with
a rapid forward-extend keyframe at frame 6, then snap to static at frame 8
(representing the moment the hook becomes a physics projectile handled by gameplay
code). After frame 6, the chain prop on the character is hidden by gameplay code;
the chain bones can be frozen or collapsed for frames 6–12.

**Raised-arm note**: Frame 0 starts at Silhouette B. The wind-up goes above it before
the release. This is intentional — the raised arm gives extra wind-up range.

---

### Clip 6 — hook_recover

| Property | Value |
|---|---|
| Name | `hook_recover` |
| Duration | 0.3 s / 9 frames at 30 fps |
| Loop | No |
| Root motion | No |
| Playback rate | 1.0 |

**Pose narrative**: Picks up at the end of `hook_throw` (frame 12 of that clip =
frame 0 of this clip). Frames 0–9: the left arm decelerates and arcs back up to the
Silhouette B raised-arm rest position. The torso counter-rotation unwinds. Frame 9
matches the Silhouette B idle pose exactly, allowing a clean blend into `idle` or
`walk`.

**Bones moved**: LeftArm, LeftForeArm, LeftHand, Spine1, Chest.

**Event markers**: None. This clip is the return phase; no gameplay events fire.

**Belly jiggle**: Spring modifier; unwind torso rotation will produce a brief
opposite-direction belly sway.

**Raised-arm note**: Frame 9 = Silhouette B idle pose.

---

### Clip 7 — attack_basic

| Property | Value |
|---|---|
| Name | `attack_basic` |
| Duration | 0.5 s / 15 frames at 30 fps |
| Loop | No |
| Root motion | No |
| Playback rate | 1.0 |

**Pose narrative**: Cleaver swing from Pudge's right hand. Frame 0: neutral idle pose
(Silhouette B; left arm raised, right arm hanging). Frames 0–4: right arm winds up —
RightArm raises and pulls back, RightForeArm bends, cleaver implied to rise. Frame 4
is wind-up peak. Frames 4–7: forward swing — RightArm drives the cleaver downward and
forward in an arc. Frame 7: **hit_active** fires. The cleaver is at its forward-most
point, at the level of the hit_center socket. Frames 7–15: follow-through and
return to idle pose.

**Bones moved**: RightArm, RightForeArm, RightHand, Chest (slight right rotation),
Spine1 (counter twist left).

**Event markers**:
- **Frame 7**: `hit_active` — gameplay activates the hitbox at this frame. Timing
  confirmed with brief §4. Coordinate exact frame with gameplay-programmer. The
  hitbox should align with the socket_offhand position at frame 7.

**Belly jiggle**: The torso twist at frame 7 will produce a right-ward belly swing.
Spring modifier handles this; no keyframe needed.

**Raised-arm note**: Left arm stays at Silhouette B position throughout (Pudge
does not use the hook arm for the basic attack). This reinforces his identity.
Frame 0 and frame 15 both match idle.

---

### Clip 8 — hit_react

| Property | Value |
|---|---|
| Name | `hit_react` |
| Duration | 0.3 s / 9 frames at 30 fps |
| Loop | No |
| Root motion | No |
| Playback rate | 1.0 |

**Pose narrative**: A sharp flinch from a hit arriving from the front. Frame 0:
idle Silhouette B. Frames 0–2: sharp recoil — Spine1 jerks backward (−10 degrees X),
Chest jerks backward (−8 degrees X), Head snaps back (−15 degrees X). The total
recoil makes Pudge appear to be pushed back by the impact. Frames 2–9: recovery,
returning to idle pose. The decay is slightly slower than the initial snap to sell
Pudge's weight — he takes the hit but doesn't recover instantly.

**Bones moved**: Spine1, Chest, Head, Neck (minor), Hips (very slight backward
translate, max 0.02 m — must stay at Y=0 on feet; IK foot lock enforces this).

**Event markers**:
- Frame 1: `hit_react_peak` — recommended addition. Fires at maximum recoil so
  gameplay code (or the technical-artist) can trigger a camera shake or screen
  flash on this exact frame rather than on the clip start. Confirm with
  gameplay-programmer whether this event is needed.

**Belly jiggle**: Keyframe BellyJiggle in this clip. The sharp backward recoil should
produce a forward-sloshing gut effect — BellyJiggle continues +Z direction 2–3 frames
after the spine snaps back. Author: BellyJiggle offset +0.03 m on frame 3, returning
to 0 by frame 9. This makes the belly feel gelatinous on impact.

---

### Clip 9 — death

| Property | Value |
|---|---|
| Name | `death` |
| Duration | 1.5 s / 45 frames at 30 fps |
| Loop | No |
| Root motion | No |
| Playback rate | 1.0 |

**Pose narrative**: The most complex clip. Five phases:

Phase 1 (frames 0–8): Stagger. Spine1 and Chest rock backward 15 degrees, Head
jerks forward (like whiplash). Hips begin to drift backward on the +Z axis by 0.05 m.
Left arm drops from Silhouette B raised position to hanging. Jaw begins to open
(10-degree X rotation).

Phase 2 (frames 8–18): Fall. Hips rotate rapidly backward around the X-axis (from
0 to −70 degrees) — Pudge tips backward. All limbs spread outward as gravity acts.
The body is falling backward; the arms are flailing. Feet stay IK-planted until
frame 15, then release as the body falls past the point of no return.

Phase 3 (frames 18–28): Impact. The body hits the ground. Hips hit Y=0 level (body
fully prone). A sharp impulse through the spine (brief bounce of Spine1 and Chest)
from the impact. Jaw opens fully (25–30 degrees X). Sound marker fires here.

Phase 4 (frames 28–38): Settle. Body relaxes into the ground. Minor spring-out from
the bounce settles. Arms flop to rest positions. Head tilts to the side slightly.
Jaw partially closes (10 degrees) — limply, not all the way.

Phase 5 (frames 38–45): Gut deflate. This is the signature moment per brief §4 and
concept §Open Notes for `rigging-animator` note 3. BellyJiggle is keyframed:
Scale the BellyJiggle bone's influence (or translate it toward the body center by
−0.05 m over 7 frames). This requires the animator to coordinate with the character-
artist — if blendshapes are available, a `death_deflate` blendshape is more reliable
than a bone-driven deflate for this shot. If no blendshape: author BellyJiggle at
−0.06 m Y offset (squash), returning partially to −0.03 m at frame 45 (not fully
deflated; just a significant sag).

**Bones moved**: ALL bones. This is a full-body clip.

**Event markers**:
- **Frame 8**: `death_begin` — gameplay triggers death state (remove physics, begin
  ragdoll transition if any). Recommend adding this event.
- **Frame 23**: `death_thud` — sound cue for the body hitting the ground. Maps to
  the peak of Phase 3 impact. Confirm frame with gameplay-programmer.
- **Frame 38**: `death_deflate_start` — optional; signals the start of the gut
  deflate for any VFX (e.g., a green gas puff from the belly).

**Belly jiggle**: KEYFRAMED in this clip. Spring modifier should be disabled (weight
0) during `death` — the explicit deflate requires authored control. The spring will
fight the deflate keyframes.

**Jaw**: Animates in this clip — see phases above.

---

### Clip 10 — victory

| Property | Value |
|---|---|
| Name | `victory` |
| Duration | 2.0 s / 60 frames at 30 fps |
| Loop | Yes (post-match screen loop) |
| Root motion | No |
| Playback rate | 1.0 |

**Pose narrative**: Pudge celebrates in a looping animation. Frame 0: idle Silhouette B
pose. Frames 0–15: left arm raises higher than the Silhouette B position — the hook
arm lifts to fully overhead (LeftArm at +60 degrees from bind, above horizontal).
The hook swings triumphantly upward. Jaw opens to 20 degrees (laugh). Frames 15–30:
the arm reaches peak and begins a slow arc back down, while the torso does a big
belly-laugh shudder — Spine1 and Chest pulse 3 times rapidly (every 5 frames) with
a +5 degree forward/back oscillation. Frames 30–45: arm continues arc, torso returns
to neutral. Jaw closes partway. Frames 45–60: return to Silhouette B idle pose for
a clean loop.

**Bones moved**: LeftArm, LeftForeArm, LeftHand, Spine1, Chest, Head (nod), Jaw
(laugh open/close rhythm), Hips (slight bounce on shudder).

**Event markers**:
- Frame 15: `victory_arm_peak` — optional; technical-artist may trigger a particle
  burst VFX at the hook tip at this frame.
- Frame 20: `victory_laugh_sound` — audio cue for Pudge laugh bark (when voice is
  added). Included now as a placeholder marker to avoid re-exporting the clip.

**Belly jiggle**: Spring modifier active, but augment with a low-amplitude explicit
BellyJiggle keyframe to sync the belly shudder with the torso pulse at frames 20, 25,
30. Without augmentation, the spring may lag behind the shudder rhythm.

**Loop match**: Frame 60 = Frame 0 (Silhouette B pose).

**Jaw**: Animates in this clip — laugh cadence open/close x3 over frames 15–40.

---

### Animation Clip Summary Table

| # | Name | Frames | Seconds | Loop | Key Events |
|---|---|---|---|---|---|
| 1 | `idle` | 60 | 2.0 | Yes | — |
| 2 | `walk` | 24 | 0.8 | Yes | footstep_left F0, footstep_right F12 |
| 3 | `run` | 18 | 0.6 | Yes | footstep_left F0, footstep_right F9 |
| 4 | `turn_in_place` | 15 | 0.5 | No | — |
| 5 | `hook_throw` | 12 | 0.4 | No | hook_release F6 |
| 6 | `hook_recover` | 9 | 0.3 | No | — |
| 7 | `attack_basic` | 15 | 0.5 | No | hit_active F7 |
| 8 | `hit_react` | 9 | 0.3 | No | hit_react_peak F1 (proposed) |
| 9 | `death` | 45 | 1.5 | No | death_begin F8, death_thud F23, death_deflate_start F38 |
| 10 | `victory` | 60 | 2.0 | Yes | victory_arm_peak F15, victory_laugh_sound F20 |
| **Total** | | **267 frames** | **8.9 s** | | |

---

## 9. Animation Library Export Plan

**All 10 clips export inside the single `pudge.glb` as an embedded
`AnimationLibrary`.** No separate `.anim` or `.tres` files are produced by the
animator. The AnimationPlayer in Godot reads clips from the GLB-embedded library.

### Clip Names — Exact Strings

Per brief §9 and model spec §11 note 4, these are the exact strings expected by the
Godot loader and AnimationTree in Stage 8. Any mismatch silently breaks blending.

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

All are snake_case. No `pudge_` prefix in the clip names — the AnimationLibrary
is already scoped to the Pudge scene node. Adding a prefix would require the
AnimationTree in Stage 8 to use `pudge/idle` rather than `idle`.

### Blender Export Workflow

1. Author all 10 clips as separate **Actions** in the Blender Action Editor.
2. Each Action must be pushed down to an **NLA strip** in the NLA Editor.
3. Action names in Blender must match the clip names exactly (snake_case).
4. In the GLTF export dialog: enable "Animations" → export mode "Actions (NLA)".
5. Verify the GLTF export settings: Y Forward, -Z Up (or the equivalent Godot-
   convention forward axis per model spec §6).
6. The blender-specialist runs the `blender-export-check` skill at `/tools/blender/`
   before delivery.

### Event Markers in Blender

Animation events (hook_release, hit_active, etc.) are authored as Godot Animation
Track `AnimationEvent` signals. In Blender these are authored as **Custom Properties**
on a dedicated "Godot Event" bone (a zero-weight, non-deforming marker bone) or via
the **Godot Blender Exporter** add-on's animation event track support. The
blender-specialist must confirm which method the project uses. Fallback: the
technical-artist adds event tracks manually in the Godot AnimationPlayer editor
after import, referencing the exact frame numbers in this spec.

---

## 10. Root Motion Convention

**Root motion is OFF for all 10 clips.**

`CharacterBody3D` drives all horizontal movement via the physics/movement code.
All animations are authored in-place:

- No horizontal (X or Z) translation on the Hips bone between frames.
- No Y-axis translation on Hips beyond the breathing and waddle vertical bob
  (maximum 0.03 m vertical displacement; Hips must not drift down through Y=0).
- Feet are IK-locked to Y=0 throughout all locomotion clips.
- The `death` clip is an exception: Hips translates vertically as Pudge falls.
  The backward fall is authored as Hips rotation (falling backward = X-axis rotation
  on Hips), not as horizontal root translation. The body falls in-place.

This matches brief §4 ("Root motion: off"), brief §5, and the loader contract at
`hero_model_builder.gd:28-36` which does not configure any root motion extraction.

---

## 11. Animation Playback Rates

| Clip | Default playback rate | Notes |
|---|---|---|
| `idle` | 1.0 | |
| `walk` | Variable | BlendSpace1D scales rate with character velocity. Canonical: 1.0 = 8 m/s character speed |
| `run` | Variable | Same BlendSpace1D. Canonical: 1.0 = 14 m/s character speed |
| `turn_in_place` | 1.0 | Mirror L/R via AnimationTree flip |
| `hook_throw` | 1.0 | Do not speed-scale; event marker timing is frame-accurate |
| `hook_recover` | 1.0 | |
| `attack_basic` | 1.0 | Do not speed-scale; hit_active timing is frame-accurate |
| `hit_react` | 1.0 | |
| `death` | 1.0 | |
| `victory` | 1.0 | |

Note to technical-artist: the walk-to-run blend via BlendSpace1D will linearly scale
playback rate. Ensure the canonical authoring speeds (8 m/s walk, 14 m/s run) match
the actual character movement speeds from `hero-system.md` or the player controller
config. If the movement speeds differ, recalibrate by adjusting the BlendSpace1D
thresholds, not by re-exporting the animation clips.

---

## 12. Hook Chain Animation Strategy

Per concept §Open Notes for `rigging-animator` note 2: the 3-4 chain link bones
(ChainLink1–4) provide organic sway in `idle` and locomotion clips.

### Authoring Approach: Blender Spring Bone / Manual Lag

**Step 1 — Control rig**: In Blender, set up a chain of 4 bones (already defined
in §1 as ChainLink1–4 children of LeftHand). Add a `Damped Track` constraint on each
ChainLink bone targeting the world-down direction, with a `Child Of` constraint
targeting the LeftHand bone. This creates natural gravity-follow behavior when the
hand moves.

**Step 2 — Bake the sway**: During `idle` and locomotion animation authoring, move
the LeftHand through its animated range. The `Damped Track` chain will dynamically
hang below the hand. Bake this to FK keyframes using `Pose → Animation → Bake Action
→ Selected Bones` for the ChainLink1–4 bones only.

**Step 3 — Manual authoring for non-locomotion clips**: For clips where the chain
sway matters expressively (`hook_throw` chain pay-out; `death` chain settling), the
animator keyframes ChainLink1–4 explicitly rather than relying on the constraint bake.
See `hook_throw` §8 note on ChainLink explicit animation.

**Step 4 — Export**: All ChainLink1–4 motion is baked to FK before GLTF export.
No Blender constraints survive into GLTF.

### Runtime Behavior

At LOD0 in Godot: ChainLink1–4 are driven by the AnimationPlayer FK tracks (the
baked sway). No runtime spring is needed for the chain bones; the baked sway is
sufficient for the idle/walk/run loops.

At LOD1+: The technical-artist sets ChainLink1–4 bones to bind pose (static) in
the LOD1 mesh, effectively hiding the chain animation. This is a LOD mesh swap,
not an animation change — the AnimationPlayer still plays the ChainLink tracks
but they drive only the LOD0 mesh.

### Chain Sway Design Guidelines

- Idle: ChainLink1–4 oscillate with a 0.5-second period, 8-10 degrees total arc.
  Chain hangs slightly behind the hand, as if gravity-weighted.
- Walk: chain swings forward-back with each step, amplitude ~15 degrees on the
  axis perpendicular to the walk direction.
- Run: increased amplitude, ~20 degrees; slight delay (ChainLink4 lags ChainLink1
  by 3 frames) gives a sense of chain mass.
- hook_throw: chain pays out forward from frame 3–6, snaps to static at frame 8
  (gameplay code takes over the chain VFX after hook_release).

---

## 13. Naming Convention Table

### Bone Names (authoritative — matches brief §5, model spec §10)

| Bone name | Type | Parent |
|---|---|---|
| `Hips` | Humanoid root | armature root |
| `Spine` | Humanoid | Hips |
| `Spine1` | Humanoid | Spine |
| `Chest` | Humanoid | Spine1 |
| `Neck` | Humanoid | Chest |
| `Head` | Humanoid | Neck |
| `Jaw` | Helper | Head |
| `LeftShoulder` | Humanoid | Chest |
| `LeftArm` | Humanoid | LeftShoulder |
| `LeftForeArm` | Humanoid | LeftArm |
| `LeftHand` | Humanoid | LeftForeArm |
| `ChainLink1` | Helper | LeftHand |
| `ChainLink2` | Helper | ChainLink1 |
| `ChainLink3` | Helper | ChainLink2 |
| `ChainLink4` | Helper | ChainLink3 |
| `RightShoulder` | Humanoid | Chest |
| `RightArm` | Humanoid | RightShoulder |
| `RightForeArm` | Humanoid | RightArm |
| `RightHand` | Humanoid | RightForeArm |
| `BellyJiggle` | Helper | Spine1 |
| `LeftUpLeg` | Humanoid | Hips |
| `LeftLeg` | Humanoid | LeftUpLeg |
| `LeftFoot` | Humanoid | LeftLeg |
| `RightUpLeg` | Humanoid | Hips |
| `RightLeg` | Humanoid | RightUpLeg |
| `RightFoot` | Humanoid | RightLeg |

Bone naming convention: PascalCase throughout. Matches the Godot Humanoid retargeting
bone map and the naming established in model spec §10. No `bone_` prefix (the model
spec §10 table listed `bone_left_hand` in the hook prop note, but the authoritative
bone name table in that same section uses `LeftHand` without prefix — this spec
follows the bone table, not the hook prop note. The model spec §10 hook prop note
was a description, not a binding name declaration).

### Animation Clip Names

```
idle            walk            run             turn_in_place
hook_throw      hook_recover    attack_basic    hit_react
death           victory
```

All snake_case. No character prefix. Embedded in the GLB AnimationLibrary.

### Socket Names (BoneAttachment3D node names in Godot)

| Socket node name | Target bone |
|---|---|
| `socket_hook_hand` | `LeftHand` |
| `socket_offhand` | `RightHand` |
| `socket_chain_origin` | `Chest` |
| `socket_hit_center` | `Spine1` |
| `socket_head_top` | `Head` |

### IK Modifier Node Names (for technical-artist in Stage 8)

| Node name | Bone chain | Modifier type |
|---|---|---|
| `IKLeftArm` | LeftArm → LeftForeArm → LeftHand | SkeletonModification3DTwoBoneIK |
| `IKRightArm` | RightArm → RightForeArm → RightHand | SkeletonModification3DTwoBoneIK |
| `IKLeftLeg` | LeftUpLeg → LeftLeg → LeftFoot | SkeletonModification3DTwoBoneIK |
| `IKRightLeg` | RightUpLeg → RightLeg → RightFoot | SkeletonModification3DTwoBoneIK |

### IK Target Marker Node Names (for gameplay-programmer)

| Marker name | Controlled by |
|---|---|
| `IKTargetLeftHand` | gameplay-programmer; moves during hook_throw |
| `IKTargetRightHand` | gameplay-programmer; optional |
| `IKTargetLeftFoot` | gameplay code; raycasts terrain each frame |
| `IKTargetRightFoot` | gameplay code; raycasts terrain each frame |

---

## 14. Open Questions / Blockers

### Blockers for character-artist (must resolve before weight paint begins)

**Blocker A — BellyJiggle vertex color annotation**
The rigger cannot begin weight painting the belly region until the character-artist
delivers the retopo mesh with a vertex color layer named `jiggle_boundary`. The layer
must paint the BellyJiggle influence gradient: red (1.0) at the belly equator ring
and forward-facing lower rings; white (0.0) at the torso-join rings and hip-pelvis
join rings. Source: model spec §11 rigger note 1 and this spec §4.1.
Action: character-artist annotates during retopo pass, before UV unwrap handoff.

**Blocker B — Corrective blendshape for raised left shoulder (TBD by rigger)**
The model spec §11 rigger note 5 flags that the 4-loop left shoulder must be tested
at 45-degree raise before handoff. If QA pose QA1 (§5) reveals pinching:
- The rigger flags the pinch and its frame to the character-artist.
- The character-artist authors a corrective blendshape named `correct_leftarm_raised`
  on `mesh_pudge_body` in Blender.
- The rigger drives this blendshape via a `ShapeKey` driven by the LeftArm bone's
  Z-axis rotation in the range [−30, +45] degrees.
Decision status: **TBD by rigger after QA1 test.** If the 4-loop deformation holds
clean, no blendshape is needed. Do not author the blendshape preemptively — it adds
export complexity and an additional AnimationPlayer track.

**Blocker C — Hook prop 100% LeftHand weight confirmation**
The rigger must deliver a written note in the Blender file comments (or in the
Stage 7 handoff notes) confirming that `mesh_pudge_hook` has zero weight on any
bone other than `LeftHand`. This is a hard gate for the blender-specialist's export
check. Source: model spec §3, §11 rigger note 4.

### Questions for gameplay-programmer (must resolve before hook_throw and attack_basic are finalized)

**Q1 — hook_release frame timing**
This spec places `hook_release` at frame 6 of `hook_throw` (0.2 s into the clip).
The gameplay code must spawn the hook projectile at the `socket_hook_hand` transform
on exactly this frame. Confirm: does the gameplay system read Animation Track events
from the AnimationPlayer, or does it poll the animation frame each physics tick?
If polling: the effective hook spawn may be delayed by up to one physics frame (16 ms
at 60 Hz). Adjust the event marker by ±1 frame if the gameplay programmer finds
a polling-based spawn consistently feels late.

**Q2 — hit_active frame timing**
This spec places `hit_active` at frame 7 of `attack_basic`. The hitbox must align
spatially with the `socket_offhand` transform at that frame. Confirm: is the hitbox
a sphere at socket_offhand's position, or a swept volume across frames 6–9? If swept,
the animator needs to know the sweep arc to design the swing motion to pass through
the expected hit zone.

**Q3 — turn_in_place mirror implementation**
The brief §4 notes "mirror for L/R." This spec assumes the AnimationTree uses an
AnimationNode with a horizontal flip parameter to mirror the single `turn_in_place`
clip. If the gameplay-programmer requires two separate clips (`turn_left` and
`turn_right`), flag before animation authoring begins — adding a second turn clip
changes the export plan.

**Q4 — run canonical speed**
This spec uses 14 m/s as the canonical run authoring speed (see §11). Confirm the
maximum character movement speed from the player controller config. If the actual
run speed differs from 14 m/s, the BlendSpace1D thresholds must be adjusted in
Stage 8 — the animation clips do not need to be re-exported.

**Q5 — BellyJiggle spring modifier implementation**
This spec recommends driving BellyJiggle via a custom GDScript spring simulation
at runtime. The gameplay-programmer must confirm this is acceptable (it requires
a small script running each frame on the Skeleton3D node, or a custom
`SkeletonModifier3D`). If the gameplay programmer prefers the spring to be baked
into animation clips instead, the animator must author BellyJiggle keyframes in
every locomotion clip — significantly more work. Resolve before animation authoring
begins.

### Notes for technical-artist (Stage 8 consumption)

- IK setup: see §6 and §13 for modifier names and target marker names.
- BellyJiggle spring: the spec recommends a runtime spring modifier. The
  technical-artist implements this in Stage 8 as a custom `SkeletonModifier3D`
  resource or an `AnimationTree` node. Spring stiffness and damping must be
  configurable as exported resource properties (data-driven, per coding standards).
- Chain bones at LOD1: disable ChainLink1–4 animation on the LOD1 instance by
  setting those bones to bind pose. Do not modify the AnimationLibrary.
- BlendSpace1D thresholds: `idle` at speed 0, `walk` at canonical 8 m/s, `run`
  at canonical 14 m/s. Tune to actual character movement speeds from config.
- Event markers in AnimationPlayer: if the blender-specialist cannot export
  custom event tracks from Blender, the technical-artist adds them manually in the
  Godot AnimationPlayer after import, using the exact frame numbers in §8.

---

*End of Pudge Stage 4 Rig + Animation Spec. Rigger and animator sign off on this
document before Blender work begins. Any change to bone names, clip lengths, or
event marker frames must be propagated to the gameplay-programmer and technical-artist.*
