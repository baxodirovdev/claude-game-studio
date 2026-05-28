# Pudge — Stage 2 Model Spec

> **Status**: DRAFT — awaiting character-artist approval before sculpt begins
> **Hero ID**: `pudge`
> **Stage**: 2 of 8 (Model Spec)
> **Date**: 2026-04-28
> **Brief**: `/design/characters/pudge_brief.md`
> **Concept**: `/design/concept-art/pudge.md` — Silhouette B (Coiled Hook Carry) LOCKED
> **Previous stage output**: concept turnaround sheet — Silhouette B approved 2026-04-28
> **Next stage gate**: User approval of this spec → high-poly sculpt begins

This document is the written contract between character-artist and all downstream
consumers (texture-artist, rigging-animator, blender-specialist, technical-artist).
Nothing in this spec may change without notifying those consumers and updating this
file.

---

## 1. Polycount Budget (LOD0)

Working target is **7,500 tris**, leaving a 1,500-tri safety margin against the
9,000-tri hard ceiling in the brief. The 10% margin (750 tris of that 1,500)
is reserved for correctives: if the belly deformation loops require a denser ring,
or the raised-arm shoulder socket needs an extra loop, that headroom absorbs it
without renegotiating the budget.

| Region | Tris | Notes |
|---|---|---|
| Torso + belly sphere | 800 | 6 horizontal rings + 8 vertical columns on the gut dome. Front-facing density higher for stitch geometry reception. |
| Apron stub | 120 | See section 3 — merged into torso geo below belt line. |
| Head (skull + face plane) | 600 | Skull half-sphere; face recessed for eye socket and mouth cavity volumes. |
| Jaw lower mass | 160 | Separate geometry block from skull base; allows jaw bone deformation. |
| Teeth row (upper + lower) | 80 | Single low-poly row per jaw; see teeth decision in section 3. |
| Eye geometry (both) | 120 | 2 x separate spheres, 6-sided cap; see section 4. |
| Hook arm (left — chunkier) | 480 | Upper arm + forearm. Forearm radius is 20% larger than right arm equivalent. |
| Other arm (right) | 380 | Upper arm + forearm. Slightly thinner than hook arm. |
| Left hand (hook hand) | 200 | Simplified fist topology — no individual finger separation; fingers merged into 3-segment fist to receive hook prop and chain socket. |
| Right hand | 160 | Same simplified fist; cleaver hold pose. |
| Hips + pelvis mass | 300 | Connects torso base to upper legs; widened to read belly hang under belt. |
| Left leg (upper + lower) | 240 | Stubby upper leg + stubby lower leg. |
| Right leg (upper + lower) | 240 | Mirror of left leg. |
| Left boot | 280 | Toe splay, worn sole, lace geometry stub (2 quad strips per boot face). |
| Right boot | 280 | Mirror of left boot. |
| Belt band + buckle | 200 | Belt is a flat ring around the waist; buckle is a separate 6-tri box attached to front center. |
| Chain (3-4 visible links) | 320 | 4 links modeled as oval toroids; budget is 80 tris per link. See section 3 for placement. |
| Hook prop (separate object) | **600** | See section 6. Within the 500-800 tri brief allowance. |
| **Body total** | **4,840** | All regions above excluding hook prop. |
| Safety margin reserve | 660 | Held for deformation loop additions and corrective quads. |
| **LOD0 working total (body)** | **~5,500** | Comfortably inside 7,500 working target; sculptor has headroom for personality detail. |
| **LOD0 with hook prop** | **~6,100** | Inside 7,500 working target. True ceiling is 9,000 (brief §2). |

### Where to cut if forced under budget

1. Teeth row: drop from 80 to 40 tris (halve the polygon resolution of the tooth
   row strip — acceptable because painted detail carries the read).
2. Chain links: reduce from 4 links to 3, saving 80 tris.
3. Belt buckle: collapse from box geometry to painted quad, saving ~60 tris.
4. Boot lace stubs: remove as geometry, paint into base color, saving ~80 tris total.
5. Eye spheres: reduce from 6-sided to 4-sided cap, saving ~40 tris.

In that worst case, body total drops to approximately 4,540 tris — still fully
functional for all deformation requirements.

---

## 2. Topology / Edge Flow Plan

### Deformation loop requirements

Every joint that moves under animation requires dedicated edge loops. Minimum counts
below; sculptor may add more within budget.

| Joint / Region | Minimum loops | Notes |
|---|---|---|
| Left shoulder socket | 4 loops | Hook arm raises to ~45 degrees above horizontal in idle; 4 loops prevent pinching at full raise. Extra loop required on hook-arm side only — asymmetric density is intentional. |
| Right shoulder socket | 3 loops | Right arm hangs with limited raise range; 3 loops sufficient. |
| Left elbow | 3 loops | Hook arm bends during hook_throw wind-up. |
| Right elbow | 3 loops | Right arm cleaver swing (attack_basic). |
| Left wrist | 2 loops | Wrist rotation for hook_throw release. |
| Right wrist | 2 loops | Cleaver swing rotation. |
| Hips | 4 loops | Walk/run waddle + death fall backward — highest deformation stress on the rig after the shoulder. |
| Left knee | 3 loops | Stubby leg; knee bend is shallow in walk but active in death stagger. |
| Right knee | 3 loops | Mirror. |
| Left ankle | 2 loops | Boot sole stays near Y=0 throughout locomotion. |
| Right ankle | 2 loops | Mirror. |
| Neck base (trapezius merge) | Special — see below | |
| Mouth | 4 concentric loops | Jaw bone drives lower half. Death and taunt require full open. |
| Eyes | 5 concentric loops each | Left eye is larger — loop count is the same but diameter of the outermost ring is ~15% wider. The asymmetry lives in the sculpt shape, not a different loop count. |

### No-neck hunch — trapezius/skull join

Per concept Open Note #4: the trapezius shoulder mass must merge into the base of
the skull with at most 1-2 cm of visible neck column in model space (~0.01-0.02 m
at 1 unit = 1 meter scale).

Edge flow plan: the neck column is treated as a 4-sided compressed ring. Instead of
a full neck tube with 6-8 vertical segments, the neck column is a single 1-segment
stub — 2 loops, 4 quads wide. The trapezius shoulder geo fans out radially from
that stub in both directions. The Neck bone deforms this region but has near-zero
rotation range by design; the animator is informed it is not a full neck joint.

This must survive retopo without softening. The retopologist must resist the
temptation to add neck height for ergonomic UV unwrapping — force the seam at the
base-of-skull if needed, not by adding neck geometry.

### Belly deformation for gut-jiggle bone

The belly jiggle bone drives the gut bounce in idle, walk, run, and death. The
belly sphere uses concentric horizontal loop rings centered on the gut's forward
protrusion point (not the anatomical waist). Layout:

- 3 rings above the equator of the gut sphere (transitioning into torso)
- 1 ring at the equator (maximum circumference)
- 2 rings below the equator (transitioning into hip/pelvis mass, where the
  jiggle bone's influence fades to zero)
- Total: 6 horizontal rings, 8 vertical column edges = 96 quads on the gut dome

The jiggle bone influence falloff: 100% on the equator ring and forward-facing
lower rings, tapering to 0% at the torso-join rings and hip-join rings. The
character-artist should mark the influence boundary on the retopo mesh with a
seam loop or color annotation for the rigger.

No mixed-quad strategy is needed — full quads on the belly. The only triangles
permitted are the pole caps on the very top of the gut sphere where it merges
into the torso (hidden inside the torso overlap at all camera angles).

### Apron stub — merged into torso

Decision: the apron stub is merged geometry, not a separate mesh.

Rationale: a separate mesh would add a draw call (pushing over the 2-material
limit if the apron needed its own material) or require a second UV island that
competes with belt/body UVs. Since the apron is a small stub tucked under the
belt, it is a geometric protrusion from the lower torso front face, sharing the
body material. Its topology is a flap of 4-6 quad rows hanging from the belt
line, tapering to 2 quads at the bottom. Total: approximately 24-32 tris.
The apron UV island shares the belt region of the body atlas (see UV plan,
section 5).

### Teeth strategy

Decision: single low-poly tooth row, painted detail — no individual tooth geometry.

Rationale: within the 6k-8k tri budget, individual tooth geometry would cost 20-40
tris per tooth (Pudge has 8-10 visible teeth from front view = 160-400 tris) for a
feature that resolves to approximately 8-12 pixels per tooth at 1080p top-down camera
distance. The texture-artist can paint yellowed individual teeth with sharper/missing
gap character using the material table values from the concept sheet at a fraction
of that cost.

Implementation: the mouth is a recessed cavity — the jaw lower mass creates a
slightly open-mouth shape at neutral. The upper lip region and lower jaw edge each
carry a single quad-strip tooth row geometry (1 row top, 1 row bottom). This strip
is 8 quads wide and 1 quad tall — approximately 16 tris per row, 32 total for both
rows. The strip sits just inside the mouth opening so it catches light. The
painted texture provides individual tooth character, dark gap between teeth, and
the missing-tooth "gash" per brief §3.

This tooth row is the first casualty at LOD1 — it collapses to a single painted
dark gash quad, saving 32 tris.

### Quad rule enforcement

Quads only on all deforming surfaces (body, arms, legs, face, belly). Tris are
permitted in the following hidden or flat locations only:

- Pole caps inside the boot sole (hidden from camera entirely)
- Interior of the mouth cavity (fully dark/occluded at game camera distance)
- The very top of the gut-sphere-to-torso merge seam if a pole is required to
  terminate the gut sphere rings

5-poles and 3-poles (edge flow terminators) must be placed on flat stable surfaces:
the center of the back torso panel, the center back of the head skull, and the
interior of the mouth cavity. Never on or within two edge loops of a deforming joint.

---

## 3. Mesh Layout / Object Hierarchy

### Single skinned mesh vs. separated submeshes

Decision: two skinned mesh objects + one separate hook prop object. Three Blender
objects total, two draw calls in Godot.

```
pudge (Empty — scene root, no mesh)
    mesh_pudge_body     (single skinned mesh: torso, head, arms, hands, legs,
                         boots, belt, apron stub, chain links, eye geometry)
    mesh_pudge_hook     (separate skinned mesh: hook prop; parented to arm_pudge
                         via socket_hook_hand bone, separate UV atlas)
```

All body components (torso, head, arms, legs, belt, apron, chain links, eyes) are
joined into `mesh_pudge_body` as a single mesh object with a single material slot.
This costs one draw call. The hook prop is separate for two reasons: it has its own
512x512 texture atlas (per brief §7) requiring a separate material slot, and it
must be detachable during the hook_throw animation (spawned as a separate gameplay
object when the hook is in flight). Total: 2 draw calls, matching brief §2 hard
limit.

### Hook prop as separate object

`mesh_pudge_hook` is parented to the skeleton (`arm_pudge`) and weight-painted
100% to the `bone_left_hand` bone. At rest it follows the hand. During
`hook_throw`, gameplay code detaches it and spawns a projectile. The rigger must
ensure the hook mesh has no weights other than `bone_left_hand` — confirmed in
handoff notes to rigging-animator.

### Eye geometry

Eyes are merged into `mesh_pudge_body`. Two simple 6-sided sphere caps, placed in
the eye socket cavities. They share the body material and UV atlas (emissive region
is painted on the body atlas emissive map, not a separate texture). Eyes are NOT
separate objects — keeping them merged holds draw calls at 2 and avoids a third
material.

The eye asymmetry (left eye larger per brief §3) is authored in the sculpt geometry.
The left eye sphere cap is scaled ~15% larger in X and Y before the cap is joined
into the body mesh.

### Naming convention for Blender objects

See Section 11 (Naming Convention Table) for the authoritative full list.

---

## 4. UV Layout Plan — 1024x1024 Body Atlas

### Texel density targets

| Region | Target density | Notes |
|---|---|---|
| Face (eyes, mouth, nose area) | 512 px/m | Per brief §2. Highest density region. Asymmetric eyes and painted teeth require maximum resolution. |
| Head (skull, back of head, ears) | 256 px/m | Back of head not readable at top-down camera; standard density is acceptable. |
| Torso front (belly, stitches, stitch holes) | 256 px/m | Stitches must resolve at game camera distance; 256 px/m achieves this. |
| Torso back | 128 px/m | Back is rarely visible at top-down angle; can sacrifice density here. |
| Arms (both) | 256 px/m | Hook arm is more visible but does not require higher density than torso. |
| Hands | 256 px/m | Fist detail reads via silhouette, not texture. Standard density. |
| Legs | 128 px/m | Nearly hidden under gut; minimal density acceptable. |
| Boots | 256 px/m | Boots are a personality element visible when Pudge walks. Scuff and lace detail requires 256 px/m. |
| Belt + buckle | 256 px/m | Buckle metallic detail must resolve for material read. |
| Apron stub | 256 px/m | Shares belt region; blood staining must be legible. |
| Chain links | 256 px/m | Chain links need highlight painted on upper face; 256 px/m achieves 8-12 px per link at game camera. |
| Eye sclera + pupil | 512 px/m (subset of face island) | Eyes carry emissive and must read at all distances. |

### UV island layout (1024x1024 atlas, numbered grid)

The atlas is divided conceptually into four quadrants. Island placement below is
described by quadrant and approximate occupancy. Minimum 8 px padding between all
islands at 1024 resolution.

```
+---------------------------+---------------------------+
|                           |                           |
|   FACE ISLAND             |   TORSO FRONT             |
|   (top-left quadrant)     |   (top-right quadrant)    |
|                           |                           |
|   Face takes ~35% of      |   Belly + stitches +      |
|   total atlas.            |   chest panel takes ~25%. |
|   Skull wraps below face  |   Apron stub sub-island   |
|   island within same      |   sits in bottom-right    |
|   quadrant (~10%).        |   corner of this quad.    |
|                           |                           |
+---------------------------+---------------------------+
|                           |                           |
|   ARMS + HANDS            |   LEGS + BOOTS + BELT     |
|   (bottom-left quadrant)  |   (bottom-right quadrant) |
|                           |                           |
|   Left arm (hook arm)     |   Left boot + Right boot  |
|   island is 20% taller    |   islands (mirrored,      |
|   than right arm island   |   sharing one UV strip)   |
|   — matches chunkier      |   Belt band wraps as a    |
|   geometry. Right arm     |   thin horizontal strip.  |
|   beneath left arm.       |   Legs share a narrow     |
|   Both hands stacked      |   strip; mostly occluded. |
|   below arm islands.      |   Chain links: separate   |
|   Chain links share       |   strip at bottom edge.   |
|   edge of arm islands.    |                           |
+---------------------------+---------------------------+
```

### Mirroring strategy

Mirror the following body regions to reclaim UV space:

- Left leg and right leg: mirrored UV, single island. Both legs share the same
  UV strip. Acceptable because legs are nearly identical and barely visible; no
  asymmetric detail planned.
- Left boot and right boot: mirrored UV, single island. Boot wear/scuff is
  symmetric at this budget. Asymmetric detail (split seam on left boot per concept
  back-view description) can be added by the texture-artist using the emissive/
  roughness channel variation rather than breaking UV symmetry.
- Left arm and right arm: NOT mirrored. The hook arm (left) is visibly chunkier
  and has different shadow/light placement at raised position. Each arm gets its
  own UV island.
- Torso left/right halves: NOT mirrored. Stitches, stitch holes, and the belt
  buckle are front-centered and require asymmetric painting capability.
- Face: NOT mirrored. Asymmetric eyes (left larger, different emissive intensity
  subtlety) require full asymmetric UV coverage.

### Padding

8 px minimum between all islands at 1024 resolution. The packer (UV packmaster
or Blender's built-in pack islands) must be run at margin=8px before final layout
is submitted to texture-artist. Verify no seams bleed into adjacent islands at
mipmaps by checking MIP level 2 (256x256) in the import preview.

---

## 5. Hook Prop UV / Texture Plan — 512x512 Hook Atlas

The hook prop (`mesh_pudge_hook`) has its own 512x512 atlas and its own material
(`mat_pudge_hook`). The atlas contains:

| Element | UV region | Notes |
|---|---|---|
| Hook body (J-curve iron bar) | Top half of atlas (~60%) | Hook is the primary read; give it the most pixels. Upper face highlight painted per concept material table. |
| Hook inner curve / tip (blood zone) | Sub-region within hook body island | Blood spatter painting is isolated here; the texture-artist must paint blood only on inner curve and tip, not the full hook. |
| Chain link 1 (closest to hand) | Bottom-left quadrant | Largest link; most visible. |
| Chain link 2 | Bottom-center-left | Second link; slightly smaller island than link 1. |
| Chain link 3 | Bottom-center-right | Third link. |
| Chain link 4 (closest to belt coil) | Bottom-right | Smallest visible link; can be partial island. |

Chain links on the hook prop atlas: the chain links that are part of the idle
silhouette hang between the left hand and the belt coil. They are part of
`mesh_pudge_body` (see object hierarchy, section 4). The hook prop atlas carries
only the chain links that are physically welded to or immediately adjacent to the
hook prop object itself (the 1-2 links exiting the hook's spine). This is a
deliberate split: the visual chain that drapes from hand to belt is skinned to the
chain bones and belongs on the body atlas; the hook-attached links are static
relative to the hook and belong on the hook atlas.

At 512 px resolution, individual link detail is 8-12 px per link. The texture-artist
must hand-paint the upper-face highlight per concept note (texture-artist Open Note #3
in concept sheet) — do not rely on normal map alone at mobile renderer resolution.

AO bake note for texture-artist: bake AO for the hook prop in a combined scene
with `mesh_pudge_body` present, specifically so the hand-to-hook contact zone
receives correct shadowing. This is flagged explicitly in concept Open Note #5 and
repeated here.

---

## 6. Pivot, Scale, and Orientation

### World origin and feet plane

- Mesh origin at world origin (0, 0, 0).
- Feet plane: the bottom of both boot soles must sit at Y=0. The armature root
  bone (Hips) sits above Y=0 at the character's anatomical hip height.
- This matches the loader contract at `hero_model_builder.gd:28-36` which places
  the instantiated GLB root at the player capsule origin with no transform offset.
  Do not add any translation or rotation to the GLB root node.

### Forward axis

Forward = -Z. This is the Godot 4.6 default and the loader expectation. In Blender
the export orientation must be set to Y Forward, -Z Up if using the default Blender
coordinate space, or configured explicitly in the GLTF exporter settings. The
blender-specialist's `blender-export-check` skill must verify this before export.

### Scale

1 Blender unit = 1 meter. Apply scale (Ctrl+A > All Transforms) before export.
Do not leave a non-unity scale on any object.

Pudge total height (chibi 3-head-tall proportions): the head is 30% of total height
per brief §2. Target total height is **1.4 m** (measured from boot sole at Y=0 to
the top of the skull).

- Head height: 1.4 m × 0.30 = **0.42 m**
- Below-head body (torso + legs): **0.98 m**
- Belly sphere radius: approximately 0.28 m (gut protrudes ~0.3 units forward of
  the feet per concept side-view description, making the belly wider than the legs
  beneath it)
- Boot height: approximately 0.10 m — visible tops just beneath gut overhang

These are target values. The sculptor may adjust ±5% for visual appeal provided
the 3-head-tall read is preserved.

### Transforms before export

All transforms must be applied before the GLTF export step: location, rotation,
scale on all mesh objects and on the armature. The blender-export-check skill
enforces this. The character-artist must apply transforms before handing to
blender-specialist.

---

## 7. LOD Plan

### LOD0 — full detail (~6,100 tris including hook prop)

Full body spec as described in sections 1-6. All topology, loops, teeth row, chain
links, boot lace stubs, eye spheres, belt buckle geometry, and hook prop at full
resolution.

### LOD1 — ~50% (~3,050 tris)

Features to collapse or simplify for LOD1:

| Feature | LOD0 state | LOD1 state |
|---|---|---|
| Chain links | 4 separate toroid meshes (320 tris) | Collapsed to static painted geometry — a single twisted quad strip (~40 tris) sharing the body atlas |
| Teeth row | Geometry strip (32 tris) | Replaced by painted dark gash — a single recessed quad in the mouth cavity |
| Boot lace stubs | Quad strips on boot face (~80 tris) | Removed; laces painted into boot base color |
| Eye spheres | 6-sided caps (120 tris) | Replaced by flat discs (24 tris total) |
| Belt buckle | Geometry box (~40 tris) | Replaced by painted quad on belt strip |
| Asymmetric arm radius | Geometry difference maintained | Asymmetry preserved in LOD1 — it is a silhouette-critical feature |
| Apron stub | 24-32 tris | Removed; apron edge painted onto belt strip base color |
| Hook prop | 600 tris | Simplified to 300 tris (remove inner curve bevel, reduce chain link count to 2) |

### LOD2 — ~25% (~1,500 tris)

Features lost or further collapsed:

| Feature | LOD1 state | LOD2 state |
|---|---|---|
| Apron stub | Already removed | (already removed) |
| Hook arm asymmetry | Preserved | Collapsed — both arms use identical polygon count and radius |
| Boot toe splay geometry | Reduced | Removed; boot box is a simple rounded rectangular prism |
| Belly deformation rings | 6 rings | Reduced to 3 rings — sufficient for gut-jiggle bone deformation |
| Stitch geometry (raised edges) | If modeled as slight extrusion | Removed — painted only |
| Hook prop | 300 tris | 150 tris (box + single curve representing hook J, no chain detail) |
| Shoulder deformation loops | 4/3 loops | Reduced to 2 loops per shoulder |
| Face concentric loops | 5 loops eyes, 4 loops mouth | 3 loops each — minimum for functional deformation |

### LOD3 — impostor/billboard

The impostor is a pre-rendered sprite sheet of Pudge at 8 rotation angles (every
45 degrees: 0, 45, 90, 135, 180, 225, 270, 315 degrees). Each frame is rendered
from a top-down 30-degree pitch camera matching the game camera angle, at 128x128
px per frame (total: 1024x128 px horizontal strip, or a 512x256 px grid at 2 rows
of 4).

Minimum frames required for gameplay readability:
- 4 cardinal angles (N, E, S, W)
- 4 diagonal angles (NE, SE, SW, NW)

The impostor must show the raised hook arm silhouette (Silhouette B) in the
front-facing (S from top-down = facing the camera) frame. The technical-artist
generates the impostor sprite in Stage 8 from the LOD2 render — character-artist
is not responsible for impostor generation.

### LOD switch distances (recommended — technical-artist to tune in Stage 8)

| LOD | Switch in | Switch out | Notes |
|---|---|---|---|
| LOD0 | — | 15 m from camera | Full detail at close range |
| LOD1 | 15 m | 30 m | Camera sits at ~12 m per brief; LOD0 is active during normal play |
| LOD2 | 30 m | 50 m | Background/edge-of-map distances |
| LOD3 impostor | 50 m | — | Very far or off-screen |

---

## 8. Sockets

Sockets are implemented as `BoneAttachment3D` nodes on the Godot side, targeting
the bones listed below. The character-artist is responsible for ensuring the mesh
geometry is positioned correctly relative to each bone origin so that socket
offsets are minimal — ideally zero offset if the bone origin is placed with care.

### socket_hook_hand → bone_left_hand

- **Position offset from bone origin**: (0.0, 0.0, -0.05) in bone local space.
  That is: 5 cm forward along the bone's -Z (forward) axis from the palm center.
  This places the socket at the grip point of the hook handle.
- **Orientation**: The socket's -Z axis must point in the direction the hook tip
  faces when carried at rest (forward-left in world space, matching the hook's
  J-curve forward direction in Silhouette B).
- **Mesh region**: Must be near the proximal edge of the left hand fist geometry.
  The hook prop (`mesh_pudge_hook`) is parented here.
- **Hook prop local transform at raised-arm rest pose**: In A-pose bind, the left
  arm hangs at ~30 degrees below horizontal. The idle animation layer raises the
  arm to ~45 degrees above horizontal (Silhouette B pose). At that raised-arm rest
  position, the hook prop's local rotation relative to `bone_left_hand` is
  approximately Rotation = (X: -15 deg, Y: 0 deg, Z: 0 deg) — hook tip tilts
  slightly forward. This rotation is authored in the idle animation clip, not
  baked into the socket's rest orientation. At bind pose (A-pose), the hook prop
  simply hangs forward from the palm.

### socket_offhand → bone_right_hand

- **Position offset**: (0.0, 0.0, -0.04) in bone local space — 4 cm forward of
  right palm center.
- **Orientation**: -Z forward, matching the hand's default forward direction.
- **Mesh region**: Near the proximal edge of the right hand fist geometry.
- **Use**: Optional cleaver/secondary attack prop spawn point.

### socket_chain_origin → bone_chest

- **Position offset**: (-0.08, 0.05, 0.0) in bone local space — 8 cm to the
  character's left (chain side) and 5 cm upward from the chest bone origin.
  This places the socket near the upper-left chest, where the chain visually
  exits the body toward the raised hand.
- **Orientation**: Aligned to world -Z forward so chain VFX spawns pointing
  toward the camera direction.
- **Mesh region**: Upper torso, near the left shoulder/chest junction. The chain
  link geometry in the body mesh begins here visually.
- **Use**: Visual chain anchor fallback if the hook hand is offscreen during
  the hook_throw animation.

### socket_hit_center → bone_spine1

- **Position offset**: (0.0, 0.0, 0.12) in bone local space — 12 cm forward of
  the Spine1 bone origin, placing the socket at the forward-most point of the
  belly sphere.
- **Orientation**: Forward (-Z world). Hit VFX should spray forward/outward.
- **Mesh region**: The belly equator — maximum gut protrusion point. This is
  the fattest and most screen-filling part of Pudge at top-down camera angle.
- **Use**: Damage VFX origin, hit-react impulse reference point.

### socket_head_top → bone_head

- **Position offset**: (0.0, 0.18, 0.0) in bone local space — 18 cm above the
  head bone origin. At 1.4 m total height with a 0.42 m head, the head bone
  origin sits approximately at the base of the skull; 18 cm up places the socket
  at the top of the skull dome.
- **Orientation**: +Y up (default). Status icons float above this point.
- **Mesh region**: Skull top — the highest geometry point on the model.
- **Use**: Status effect icons (stun halo, level-up burst, crowd-control indicator).

---

## 9. Collision Plan

No collision geometry on the visual model. The visual character mesh has no
`CollisionShape3D` or physics body. All gameplay collision is handled by the
existing `CapsuleShape3D` on the `CharacterBody3D` node in the game scene.
Per brief §8, this is confirmed and requires no action from the character-artist.

Do not author any collision mesh proxy. Do not parent any collision geometry to
the GLB hierarchy.

---

## 10. Naming Convention Table

All Blender objects, mesh data-blocks, materials, armature, and bones follow the
table below. This is authoritative — downstream tools and the Godot importer rely
on these exact names. Snake_case for all Blender objects. Bone names use the
PascalCase convention matching Godot's Humanoid retargeting expectations.

### Blender Object Names

| Object type | Blender object name | Notes |
|---|---|---|
| Scene root (empty) | `pudge` | Parent of all objects. No mesh. |
| Body mesh | `mesh_pudge_body` | Contains all body geometry: torso, head, arms, hands, legs, boots, belt, chain, eyes, apron stub. |
| Hook prop mesh | `mesh_pudge_hook` | Hook J-curve + 1-2 immediately adjacent chain links. Separate draw call. |
| Armature | `arm_pudge` | Skeleton. Parented at world origin. |

### Mesh Data-Block Names

| Mesh data | Name | Notes |
|---|---|---|
| Body mesh data | `mesh_data_pudge_body` | Blender internal mesh data-block. Rename after final join. |
| Hook mesh data | `mesh_data_pudge_hook` | |

### Material Names

| Material | Name | Atlas size | Notes |
|---|---|---|---|
| Body material | `mat_pudge_body` | 1024x1024 | Applied to `mesh_pudge_body`. All body regions. |
| Hook material | `mat_pudge_hook` | 512x512 | Applied to `mesh_pudge_hook` only. |

### Bone Names (Armature)

Bone names must match the brief §5 required bone list exactly. Listed here for
reference with the snake_case file convention noted — bones use PascalCase to
match Godot retargeting.

| Bone name | Role | Notes |
|---|---|---|
| `Hips` | Pelvis root | |
| `Spine` | Lower spine | |
| `Spine1` | Upper spine / belly anchor | Belly jiggle bone weighted from here |
| `Chest` | Chest / socket_chain_origin target | |
| `Neck` | Compressed neck stub | Very short; see topology plan |
| `Head` | Skull | |
| `LeftShoulder` | Left shoulder | Hook arm side |
| `RightShoulder` | Right shoulder | |
| `LeftArm` | Left upper arm | |
| `RightArm` | Right upper arm | |
| `LeftForeArm` | Left forearm (chunkier) | |
| `RightForeArm` | Right forearm | |
| `LeftHand` | Left hand / socket_hook_hand target | |
| `RightHand` | Right hand / socket_offhand target | |
| `LeftUpLeg` | Left thigh | |
| `RightUpLeg` | Right thigh | |
| `LeftLeg` | Left shin | |
| `RightLeg` | Right shin | |
| `LeftFoot` | Left foot / boot | |
| `RightFoot` | Right foot / boot | |
| `BellyJiggle` | Belly secondary motion | Child of Spine1; drives gut bounce |
| `Jaw` | Jaw | Optional; used in taunt/death |
| `ChainLink1` | Chain link closest to hand | Child of LeftHand |
| `ChainLink2` | Second chain link | Child of ChainLink1 |
| `ChainLink3` | Third chain link | Child of ChainLink2 |
| `ChainLink4` | Fourth chain link / belt coil | Child of ChainLink3 |

### Texture File Names (output for texture-artist)

| File | Resolution | Notes |
|---|---|---|
| `pudge_body_basecolor.png` | 1024x1024 | Hand-painted base color |
| `pudge_body_normal.png` | 1024x1024 | Tangent-space normal map baked from high-poly |
| `pudge_body_orm.png` | 1024x1024 | ORM channel pack: R=AO, G=Roughness, B=Metallic |
| `pudge_body_emissive.png` | 1024x1024 | Eye emissive only; rest is black |
| `pudge_hook_basecolor.png` | 512x512 | Hook prop base color |
| `pudge_hook_normal.png` | 512x512 | Hook prop normal |
| `pudge_hook_orm.png` | 512x512 | Hook prop ORM |

### Output File Names

| File | Path | Notes |
|---|---|---|
| Final GLB | `src/assets/models/heroes/pudge.glb` | Overwrites placeholder per brief §9 |
| Working Blender file | `tools/blender/pudge.blend` | Canonical working file; not exported to Godot |

---

## 11. Open Questions for Next Stages

### For texture-artist (Stage 4)

1. **Apron blood density**: The apron stub shares the belt UV region on the body
   atlas. Confirm you have enough texel budget to paint legible blood staining
   on the apron face at 256 px/m density — the island will be small. If it is
   under 32x32 px in the atlas, consider whether the blood reads or becomes noise.
   Raise this before starting paint, not after.

2. **Team tint base color validation**: Verify the desaturated skin base (`#8A8A7A`
   per concept material table) reads correctly under all three team tint channels
   (green `Color(0.5, 0.8, 0.2)`, red, blue). The base must not already be green.
   Test the shader tint uniform before painting any facial features — getting the
   base wrong invalidates all subsequent skin work.

3. **Eye emissive boundary**: The emissive map should contain only the sclera
   region. The pupil is NOT emissive (near-black matte per concept material table).
   If the emissive island bleeds into the pupil area even by a few pixels, the eye
   will glow incorrectly. Confirm the UV island for the eye sclera is padded 8+px
   from the pupil sub-region.

4. **Stitch geometry decision**: This spec does not author stitches as modeled
   geometry (they are painted detail). If the texture-artist finds that 256 px/m
   on the torso front does not give enough resolution for stitch detail at top-down
   12m camera distance, flag this before finalizing the UV layout — we may need to
   increase face density or use a stitch decal approach.

5. **Combined AO bake requirement**: AO for both `mat_pudge_body` and
   `mat_pudge_hook` must be baked in the same Blender scene with both meshes
   present. The hand-to-hook contact area will have incorrect AO if baked
   separately. This is a workflow coordination item between character-artist
   (who sets up the bake scene) and texture-artist (who may re-bake if painting
   requires it).

### For rigging-animator (Stage 5)

1. **BellyJiggle bone influence boundary**: The character-artist will mark the
   jiggle influence boundary on the retopo mesh using vertex color or annotation.
   The rigger must request this annotation before weight painting. The boundary is:
   100% influence on the belly equator ring and lower forward rings; 0% at the
   torso-join rings above the equator and at the hip-pelvis join below.

2. **Neck bone range of motion**: The Neck bone has near-zero useful rotation range
   due to the no-neck hunch topology. The rigger must constrain the Neck bone to
   a maximum of 5 degrees rotation in any axis to prevent topology shear at the
   skull-trapezius join. Head rotation is driven by the Head bone, not Neck.

3. **ChainLink bones vs. animation layer**: The spec authors ChainLink1-4 as child
   bones of LeftHand. At LOD0 these drive the 4 visible chain link meshes with an
   organic sway in idle. The rigger should evaluate whether a spring-based Godot
   4.6 SkeletonModification3D modifier can auto-drive chain sway rather than
   keyframing it in every animation clip. If spring modification is used, the chain
   link bones must be excluded from animation clips and driven exclusively by the
   modifier at runtime.

4. **Hook prop weight paint confirmation**: `mesh_pudge_hook` must have 100% weight
   to `LeftHand` and 0% to all other bones. Confirm before delivery to
   blender-specialist. If any other bone has non-zero weight on the hook mesh, the
   hook prop will deform incorrectly when separated as a projectile.

5. **Left shoulder 4-loop deformation test**: The hook arm raises to approximately
   45 degrees above horizontal in the idle animation layer. Test this full raise
   in Blender before handoff — the 4-loop shoulder should hold clean without
   pinching. If it pinches, add a corrective blendshape at the raised-arm position.
   Flag any corrective shapes to the character-artist to ensure they are included
   in the final blend file.

6. **Jaw bone usage**: The Jaw bone is listed as optional in the brief (for taunt
   and death). If the taunt stretch goal is cut, the Jaw bone may be omitted.
   Confirm scope with the user before rigging — an unused bone in the export adds
   unnecessary data to the AnimationLibrary.

### For blender-specialist (Stage 7)

1. **Export orientation verification**: Forward = -Z, Up = +Y in the GLTF export
   settings. Verify with the `blender-export-check` skill at `/tools/blender/`.
   Pudge's forward belly protrusion will be immediately obvious if the axis is
   wrong — a sideways-facing Pudge in Godot is the failure signature.

2. **Transforms applied check**: All objects (`mesh_pudge_body`, `mesh_pudge_hook`,
   `arm_pudge`) must have location=(0,0,0), rotation=(0,0,0), scale=(1,1,1) in
   object mode before export. The blender-export-check skill must flag any non-unity
   scale as a blocker.

3. **LOD object naming for Godot import**: Godot's LOD import system requires mesh
   objects to be named with `_lod0`, `_lod1`, `_lod2` suffixes. The LOD objects
   in the blend file must be named `mesh_pudge_body_lod0`, `mesh_pudge_body_lod1`,
   `mesh_pudge_body_lod2`, and similarly for the hook prop. Confirm this before
   export to avoid a manual re-import pass.

4. **AnimationLibrary clip names**: All 10 animation clips (per brief §4) must be
   named exactly: `idle`, `walk`, `run`, `turn_in_place`, `hook_throw`,
   `hook_recover`, `attack_basic`, `hit_react`, `death`, `victory`. The Godot
   loader and AnimationTree expect these exact strings. A mismatch silently breaks
   animation blending with no error at import time.

---

*End of Pudge Stage 2 Model Spec. Awaiting user approval before sculpt begins.*
