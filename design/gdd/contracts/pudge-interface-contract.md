# Pudge — Interface Contract (Single Source of Truth)

> **Status**: DRAFT — section-by-section authoring in progress (2026-05-31)
> **Authoritative for**: bone names, socket transforms, jiggle encoding, tint
> mask delivery, bind pose, axes, bone count. Supersedes any conflicting line
> in `design/gdd/models/pudge.md`, `design/gdd/rigs/pudge.md`,
> `design/gdd/materials/pudge.md`.
> **Resolves**: 15 cross-doc conflicts identified in
> `design/gdd/reviews/pudge-model-review-log.md` (review 2026-05-30).
> **Predecessor**: First contract in `design/gdd/contracts/` — establishes the
> pattern for future per-character contracts.

This document is the written reconciliation between the three Stage 3-4 Pudge
specs (model, rig, materials) that were authored in isolation and now disagree
on shared contract surface. Every value below is binding on all downstream
work; conflicts with earlier specs are resolved in favor of this contract.

The order of authority for any future Pudge change:
1. **This contract** (when present, for items in §3 propagation checklist)
2. **Brief** (`design/characters/pudge-character-brief.md`) for Stage 1 locks
3. **Per-domain specs** (model, rig, materials) for everything else

---

## 1. Source-of-Truth Precedence

This table is the dispute-resolution rule for anyone hitting a conflict
between Pudge documents.

| Concern | Authority | When this applies |
|---|---|---|
| Style direction, proportions, signature features | `design/characters/pudge-character-brief.md` (Stage 1, LOCKED) | Anything in the brief's "Visual Style" or "Silhouette Priorities" sections is final |
| Cross-doc shared interface (items in this contract) | **This contract** (`design/gdd/contracts/pudge-interface-contract.md`) | Bone names, socket transforms, jiggle encoding, tint delivery, bind pose, axes, bone count |
| Topology, polycount, UV layout, LOD geometry | `design/gdd/models/pudge.md` | Sections 2, 3, 4 of model spec |
| Skeleton internals, weight paint, IK, animation clips | `design/gdd/rigs/pudge.md` | Sections 3, 5, 6, 8 of rig spec |
| PBR values, atlas painting, blood placement | `design/gdd/materials/pudge.md` | Sections 4, 5, 7, 10 of materials spec |
| Hero stat profile, gameplay role, ability values | `design/gdd/hero-system.md` (Pudge entry — Q12.18 still open) | Combat behavior, not visuals |

### When two specs disagree

- If both touch a §12 propagation-checklist item: **this contract** is binding.
  The losing spec must be updated to reference this contract.
- If neither is in this contract: escalate to **creative-director** for design
  conflicts, **technical-director** for engine/perf conflicts.
- Never silently merge or split the difference — record the resolution in a
  new contract section or a new ADR.

### Why this contract exists

Stages 3 (model spec) and 4 (rig spec, materials spec) were authored
independently before any cross-doc reconciliation. Each spec's author made
internally consistent decisions but disagreed with the other authors on:

- Bone naming convention (Mixamo prefix vs PascalCase)
- Bind pose (T-pose vs A-pose)
- Spine bone naming (`Spine2` vs `Chest`)
- Socket bone-local coordinate conventions
- jiggle_boundary encoding (3-color vs 2-color)
- Tint mask delivery (BaseColor alpha vs dedicated 5th map)
- Texture file paths and naming prefixes
- Animation canonical authoring speeds

The `/design-review` of 2026-05-30 surfaced these as 27 BLOCKING items across
6 specialist reviews. Rather than re-author all three specs in lockstep, this
contract locks the shared surface in one place; the specs link to this
document for the conflicting values and own only the parts unique to their
domain.

---

## 2. Axes & Bind Pose (Brief wins)

### Axis conventions

| Axis | Blender (authoring) | Godot (runtime) | glTF export setting |
|---|---|---|---|
| Right | +X | +X | passthrough |
| Up | +Z | +Y | "Y Up" |
| Forward | -Y (front view shows face) | -Z (faces movement direction) | "-Z Forward" |

In Blender, Pudge must be authored so his **face points along -Y in front
orthographic view**. When exported with Y-Up / -Z-Forward glTF settings (Godot
4 defaults), this transforms to: Pudge faces -Z in Godot — matching
`player_controller.gd` facing logic.

### Bind pose

**T-pose.** Arms straight out horizontal, palms facing forward-down.

| Bone | X rot | Y rot | Z rot | Notes |
|---|---|---|---|---|
| `mixamorig:Hips` | 0 | 0 | 0 | Root, world (0, 0.30, 0) |
| `mixamorig:Spine` | 0 | 0 | 0 | Vertical |
| `mixamorig:Spine1` | 0 | 0 | 0 | Vertical, BellyJiggle parent |
| `mixamorig:Spine2` | 0 | 0 | 0 | Vertical, chest level |
| `mixamorig:Neck` | 0 | 0 | 0 | Stub, ±5° max range (see §3 no-neck) |
| `mixamorig:Head` | 0 | 0 | 0 | Neutral |
| `mixamorig:LeftShoulder` | 0 | 0 | 0 | Hook-arm side |
| `mixamorig:LeftArm` | 0 | 0 | 0 | **Horizontal (T-pose), NOT -30° A-pose** |
| `mixamorig:LeftForeArm` | 0 | 0 | 0 | Straight |
| `mixamorig:LeftHand` | 0 | 0 | 0 | Fist neutral |
| `mixamorig:RightShoulder` | 0 | 0 | 0 | Mirror |
| `mixamorig:RightArm` | 0 | 0 | 0 | **Horizontal (T-pose), NOT +30° A-pose** |
| `mixamorig:RightForeArm` | 0 | 0 | 0 | Mirror |
| `mixamorig:RightHand` | 0 | 0 | 0 | Mirror |
| `mixamorig:LeftUpLeg` | 0 | 0 | 0 | Vertical (slight outward spread allowed at sculpt only) |
| `mixamorig:LeftLeg` | 0 | 0 | 0 | Straight |
| `mixamorig:LeftFoot` | 0 | 0 | 0 | Sole at Y=0 |
| (Right leg mirror) | 0 | 0 | 0 | Mirror |
| `mixamorig:Jaw` | 0 | 0 | 0 | Closed |
| `mixamorig:BellyJiggle` | 0 | 0 | 0 | Resting (§4.1 for offset from Spine1) |

### Why T-pose wins (resolves rig spec §2 vs brief conflict)

The Stage 1 brief is signed off (`[x] Pose: T-pose — confirmed`). Brief is
the project's locked source-of-truth contract; reopening Stage 1 to amend
T-pose → A-pose would invalidate the concept doc's Silhouette B approval
narrative and require a full Stage 1 re-acceptance cycle.

**Rig spec §2 must be rewritten** to drop the A-pose joint angle table and
re-author with all arm Z rotations = 0 (T-pose). The "slight forward lean
hunch" the rig spec describes (Spine +5°, Spine1 +5°, Chest +5°) is also
removed from bind pose — bind is fully neutral. The hunch silhouette is
delivered by the idle animation clip on top of the T-pose bind, same as the
raised-hook-arm pose.

### Silhouette B raised hook arm — driven by idle clip, NOT bind

Concept Silhouette B requires the hook arm to rest at ~45° above horizontal
("Coiled Hook Carry"). This is **NOT baked into bind**. The `idle` clip
starts at frame 0 with the Silhouette B pose (left arm raised, hook visible);
all other clips that need the raised-arm rest (`walk`, `run`,
`turn_in_place`, `hook_recover`, `victory`) start and end on the same
Silhouette B pose for clean blending.

This matches concept Open Note rigger #6: "keep bind pose at A-pose per
brief, drive the raised-arm rest through an idle animation clip" — except
"A-pose" was a misquote; the brief actually says T-pose, so the bind is
T-pose and idle drives the rest.

### World position and scale

- Mesh root (Empty `pudge`) at world (0, 0, 0)
- Armature `arm_pudge` at world (0, 0, 0)
- Boot soles at **Y = 0.0** (bottom of feet plane)
- Skull top at approximately **Y = 1.40** m
- 1 Blender unit = 1 meter = 1 Godot unit
- All objects (meshes + armature + scene root) have applied transforms:
  Location (0,0,0), Rotation (0,0,0), Scale (1,1,1)

### Implication for `HeroModelBuilder` (Stage 10)

When the new GLB ships built to this contract, the runtime 180° rotation hack
at `src/gameplay/hero/hero_model_builder.gd:74` (`glb_root.rotation.y = PI`)
must be **removed**. Pudge will face -Z natively. Flagged in §12
propagation checklist.

---

## 3. Skeleton — Bone Naming Convention (Model spec wins)

### Naming convention

| Where | Format | Example |
|---|---|---|
| Blender authoring | `mixamorig:BoneName` (colon) | `mixamorig:LeftHand` |
| GLB export | `mixamorig:BoneName` (preserved) | `mixamorig:LeftHand` |
| Godot runtime (post-import) | `mixamorig_BoneName` (colon → underscore, auto-sanitized by glTF importer) | `mixamorig_LeftHand` |
| Code references (`hero_model_builder.gd`) | `mixamorig_BoneName` (matches sanitized runtime form) | `"mixamorig_LeftHand"` |

This is the Mixamo convention. It is preserved because:

1. `HeroModelBuilder.HERO_SOCKETS` already references `mixamorig_*` keys at
   `src/gameplay/hero/hero_model_builder.gd:25-46` — no code change required.
2. Mixamo's free animation library (walk, run, idle, death) is compatible
   with this skeleton out of the box — no manual retargeting.
3. Animations already shipped (`tools/blender/heroes/retarget_pudge_mixamo.py`,
   "rig and animate Pudge with Mixamo walk/death/throw clips" commit 84e33d6)
   assume this convention.

**Rig spec §1 and §13 must be rewritten** to use Mixamo-prefixed PascalCase
(`mixamorig:Hips` not `Hips`, `mixamorig:Spine2` not `Chest`, etc.). The rig
spec's "Chest" bone is functionally the same as Mixamo's `Spine2` — same
parent (`Spine1`), same children (`Neck`, `LeftShoulder`, `RightShoulder`).
Rename, do not restructure.

### Bone hierarchy (22 MVP bones)

```
arm_pudge (armature object)
└── mixamorig:Hips                                  [root]
    ├── mixamorig:Spine
    │   └── mixamorig:Spine1                        [BellyJiggle parent]
    │       ├── mixamorig:BellyJiggle               [helper — secondary motion]
    │       └── mixamorig:Spine2                    [a.k.a. "Chest" in rig spec]
    │           ├── mixamorig:Neck                  [stub, ±5° max]
    │           │   └── mixamorig:Head
    │           │       └── mixamorig:Jaw           [helper — INCLUDED per Q4]
    │           ├── mixamorig:LeftShoulder
    │           │   └── mixamorig:LeftArm
    │           │       └── mixamorig:LeftForeArm
    │           │           └── mixamorig:LeftHand
    │           └── mixamorig:RightShoulder
    │               └── mixamorig:RightArm
    │                   └── mixamorig:RightForeArm
    │                       └── mixamorig:RightHand
    ├── mixamorig:LeftUpLeg
    │   └── mixamorig:LeftLeg
    │       └── mixamorig:LeftFoot
    └── mixamorig:RightUpLeg
        └── mixamorig:RightLeg
            └── mixamorig:RightFoot
```

### Bone count

**MVP target: 22 bones** (20 Mixamo humanoid + 1 BellyJiggle + 1 Jaw).

| Configuration | Bone count | Status |
|---|---|---|
| Minimum (no Jaw, no chain) | 21 | Cut if scope tightens further |
| **MVP** (Jaw included per Q4, no chain) | **22** | **This contract locks at 22** |
| Full (Jaw + 4 ChainLink1-4) | 26 | Post-MVP polish |

### ChainLink1-4 — DEFERRED to post-MVP

The rig spec authored 4 `ChainLink*` bones for organic chain sway (hand-to-
belt drape). Per resolved Q12.9 from the review log and model spec §9
recommendation, these are **excluded from MVP**:

- Skeleton stays at 22 bones for the launch hero.
- The chain drape between hand and belt is rendered as **static painted
  geometry** on the body atlas (per model spec UV layout §4).
- If post-launch profiling shows budget headroom, chain bones can be added
  as ChainLink1 → ChainLink2 → ChainLink3 → ChainLink4 (all children of
  `mixamorig:LeftHand`, all with `mixamorig:` prefix).

**Rig spec §1, §4.3, §12 must be revised** to reflect that ChainLink bones
are post-MVP, not MVP. Rig spec's 27-bone total drops to 22.

### Special bones

| Bone | Role | Notes |
|---|---|---|
| `mixamorig:Hips` | Armature root | Only root-level bone. World (0, ~0.30, 0). |
| `mixamorig:Spine1` | Belly anchor | Parent of BellyJiggle. Weight-paint origin for the gut sphere. |
| `mixamorig:Spine2` | Chest | `socket_chain_origin` target (see §5). |
| `mixamorig:Neck` | Compressed stub | **±5° max rotation per axis** — see model spec §3 "no-neck hunch". Head rotation is driven by `mixamorig:Head`, not `mixamorig:Neck`. |
| `mixamorig:Head` | Skull | `socket_head_top` target. |
| `mixamorig:LeftHand` | Hook hand | `socket_hook_hand` target. Hook prop weighted 100% to this bone. |
| `mixamorig:RightHand` | Cleaver hand | `socket_offhand` target. |
| `mixamorig:BellyJiggle` | Helper | Secondary motion — see §4.1. |
| `mixamorig:Jaw` | Helper | Mouth animation for `death` and `victory` — see §4.2. |

### Twist bones — NOT included

Pudge's chibi limbs are too short for forearm/thigh twist to be a visible
issue. If retopo reveals candy-wrapping during QA pose testing (see rig spec
§5 QA1–QA4), add `mixamorig:LeftForeArmTwist` + `mixamorig:RightForeArmTwist`
as a Stage 8 fix — keeps total at 24 bones, still well under any reasonable
mobile ceiling.

---

## 4. Helper Bones

### 4.1 `mixamorig:BellyJiggle`

Single secondary-motion bone for the gut sphere bounce.

| Property | Value |
|---|---|
| Parent | `mixamorig:Spine1` |
| Local position offset | (0.0, 0.0, +0.20) m in Spine1 local space |
| Local rotation at bind | (0, 0, 0) — bone tip aligned with parent's +Y (along the bone, upward in world) |
| Bone length | 0.10 m (matches belly equator radius) |
| Influence cap (rigger applies) | 80% — remaining 20% goes to `mixamorig:Spine1` |
| Influence source | Vertex color layer `jiggle_boundary` on body mesh (see §6) |

#### Coordinate convention note

The `(0.0, 0.0, +0.20)` offset is in **Spine1's bone-local space** where +Y
points along the bone tail (upward, since Spine1 is vertical at bind) and +Z
points along the bone's forward roll axis (away from the back). With Pudge's
T-pose bind and the brief's -Z world forward, Spine1's local +Z aligns with
world -Z — i.e., toward Pudge's face. The 20 cm offset therefore places the
BellyJiggle bone 20 cm in front of the spine, at the belly equator's
maximum protrusion point.

#### Drive strategy — keyframe in all clips (LOCKED — Godot 4.6 has no spring API)

Per Step 5 verification (O-4, 2026-05-31): **Godot 4.6 ships no built-in
spring/jiggle SkeletonModifier3D.** The available modifiers are CCDIK,
FABRIK, Jacobian IK, Spline IK, TwoBoneIK (4.6 IK restoration) plus 4.5's
BoneConstraint3D set (AimModifier3D, CopyTransformModifier3D,
ConvertTransformModifier3D) — none are physics-driven.

**MVP path**: BellyJiggle is keyframed in all 10 animation clips by the
animator. Estimated ~20% additional animation authoring time vs the runtime-
spring path. This is the locked path because:

- Eliminates engine-API risk before Stage 8 starts
- Animator can hand-tune the bounce per-clip (run wants more amplitude than walk)
- Death clip's deflate beat (rig spec §8 clip 9 phase 5) was always going to
  be keyframed anyway — consistency
- Custom GDScript SkeletonModifier3D for spring (~50 lines) is post-MVP
  polish if profiling shows keyframe drift across clip blends

**Rig spec §4.1 must be revised** to drop the "spring if available, else
keyframe" conditional and lock to keyframe-only. Spring modifier mention
moves to a "post-MVP" footnote.

#### Boundary annotation source

The rigger cannot begin weight painting the belly region until the
character-artist delivers the retopo mesh with a `jiggle_boundary` vertex
color layer per §6 of this contract. This is a Stage 5 → Stage 8 handoff
gate.

### 4.2 `mixamorig:Jaw`

Single mouth-articulation bone. **Included in MVP per Q4 decision.**

| Property | Value |
|---|---|
| Parent | `mixamorig:Head` |
| Local position offset | (0.0, -0.10, +0.05) m in Head local space |
| Local rotation at bind | (0, 0, 0) — closed |
| Bone length | 0.04 m (matches lower jaw mass) |
| Range of motion | ±30° X-axis only (open/close). Clamp to prevent jaw-through-belly clipping per rig spec §4.2 |

#### Coordinate convention note

The `(0.0, -0.10, +0.05)` offset places the jaw pivot 10 cm below Head's
origin (Y = -0.10 in Head local) and 5 cm forward (+Z). This positions the
hinge at the lower jaw line, behind the front teeth geometry.

#### Animation usage

| Clip | Jaw animated? | Notes |
|---|---|---|
| `idle` | No | At rest (closed) |
| `walk` | No | At rest |
| `run` | No | At rest |
| `turn_in_place` | No | At rest |
| `hook_throw` | No | At rest |
| `hook_recover` | No | At rest |
| `attack_basic` | No | At rest |
| `hit_react` | No | At rest |
| `death` | **Yes** | Opens on impact (phase 3, frames 18–28), gapes fully (25–30°), partially closes limp (10°) in settle phase |
| `victory` | **Yes** | Rhythmic open/close for laugh cadence — frames 15–40, 3 cycles |
| `taunt` (if in MVP) | **Yes** | Gape — exact frame plan deferred to Stage 9 |

Per the Q4 decision, Jaw is non-optional in MVP; this avoids a corrective
blendshape (`mouth_open_taunt`) and lets the animator drive mouth motion
directly. Cost: 1 bone, zero animation overhead on the 8 clips that ignore it.

---

## 5. Sockets (Rig spec numbers, model spec parent names)

### Bone-local coordinate convention (locked here)

Pudge's skeleton uses **Mixamo bone roll convention**, identical to what the
rig spec assumes:

| Bone-local axis | Direction (with bone vertical at T-pose bind) |
|---|---|
| +Y | Along the bone tail (head → tip direction) — upward for spine bones, sideways for arms |
| +Z | The bone's roll axis "forward" — faces -Z world when bone is vertical |
| +X | Cross-product (Y × Z) — "right" relative to the bone's roll |

This convention matters because the rig spec's socket offsets use it; the
model spec's `(0.05, 0, 0)` for `socket_hook_hand` was authored with a
different (less standard) convention that placed offsets along +X. The rig
spec convention is preserved — model spec §7 numbers are superseded.

### Socket definitions

| Socket name | Parent bone (Mixamo) | Local position (m) | Local rotation (deg) | Purpose |
|---|---|---|---|---|
| `socket_hook_hand` | `mixamorig:LeftHand` | (0.0, 0.0, -0.05) | (-15, 0, 0) | Hook prop attachment. 5 cm along LeftHand's -Z (away from palm toward fingertip grip). The -15° X tilt orients the hook tip slightly forward-down at bind; at the raised-arm idle pose, hook tip faces forward-outward matching Silhouette B. Hook prop mesh is parented here at runtime, weighted 100% to LeftHand. |
| `socket_offhand` | `mixamorig:RightHand` | (0.0, 0.0, -0.04) | (0, 0, 0) | Cleaver / secondary attack prop spawn point. 4 cm along RightHand's -Z. Cleaver orientation authored in the prop's own transform. |
| `socket_chain_origin` | `mixamorig:Spine2` | (-0.08, 0.05, 0.0) | (0, 0, 0) | Chain VFX anchor when the hook is offscreen during `hook_throw`. 8 cm to character's left of Spine2, 5 cm above. Matches the concept's visible chain exit point on the upper-left chest. **Rig spec calls this parent `Chest`; same bone, Mixamo name is `mixamorig:Spine2`.** |
| `socket_hit_center` | `mixamorig:Spine1` | (0.0, 0.0, +0.12) | (0, 0, 0) | Damage VFX origin + hit-react impulse reference. 12 cm forward of Spine1 (toward face direction) — places socket at the belly equator's most-protruding screen-filling point at top-down camera. **Model spec's `(0, 0, -0.28)` is superseded** — rig spec's smaller `+0.12` forward is more accurate to Spine1's higher placement (the belly equator is below Spine1, not in front of it). |
| `socket_head_top` | `mixamorig:Head` | (0.0, 0.18, 0.0) | (0, 0, 0) | Status effect icon mount (stun halo, level-up burst, CC indicator). 18 cm above Head bone origin — reaches the top of the 0.42 m skull dome. Both specs agree. |

### Per-socket world position at T-pose rest (verification reference)

For the character-artist and rigger to verify that bone placement is correct,
each socket should resolve to approximately the following world position when
Pudge is in T-pose bind:

| Socket | Expected world position (m) | Visual landmark |
|---|---|---|
| `socket_hook_hand` | approximately (+0.55, +0.95, ±0.05) | Left palm center, slightly toward fingertip |
| `socket_offhand` | approximately (-0.55, +0.95, ±0.04) | Right palm center |
| `socket_chain_origin` | approximately (-0.08, +0.78, 0.0) | Upper chest, left-of-center |
| `socket_hit_center` | approximately (0.0, +0.55, -0.12) | Forward belly equator |
| `socket_head_top` | approximately (0.0, +1.40, 0.0) | Top of skull dome |

The Y values shift if bone positions differ from the rig spec §2 targets.
Use these as a sanity check after the rigger places bones — if a socket
resolves >5 cm off the visual landmark, the bone is misplaced, not the socket.

### Implementation in Godot

Each socket is a `BoneAttachment3D` node parented to its target bone in the
imported skeleton. The existing loader at
`src/gameplay/hero/hero_model_builder.gd:423-446` (`_setup_hero_sockets`)
handles this.

**`HeroModelBuilder.HERO_SOCKETS` constant must be updated** (Stage 10
deliverable) to match the values above. The current values reference the OLD
1.88 m Pudge build and are stale. Tracked in §12 propagation checklist.

### Sockets and LODs

Sockets attach to bones, not to mesh data. As Pudge LOD-swaps from LOD0 →
LOD1 → LOD2, the skeleton is unchanged — all 5 sockets remain valid. LOD3
(impostor billboard) does not use sockets; effects spawn at the billboard's
world position with no bone targeting.

---

## 6. `jiggle_boundary` Vertex Color Encoding (Rig spec wins — 2-color)

### Encoding

Two colors only. Linear interpolation between them across the belly's vertical
rings.

| Color | RGB (0-1) | Meaning | Where painted |
|---|---|---|---|
| Red | (1.0, 0.0, 0.0) | 100% BellyJiggle influence | Belly equator ring + forward-lower ring (the most-displacing parts of the gut sphere) |
| White | (1.0, 1.0, 1.0) | 0% BellyJiggle influence | Top torso-join rings + bottom hip-join rings (the parts that must stay glued to the spine/pelvis) |
| Pink gradient | linear between red and white | proportional influence | All rings between red and white — the painter does NOT manually paint mid values; Blender's gradient/smear tool interpolates between the red and white edges |

**Model spec §3's 3-color encoding (red / yellow / white) is superseded.**
The yellow 50% middle band is replaced by linear interpolation produced by
Blender's vertex paint gradient, not by a discrete intermediate paint color.
This is simpler for the painter, more accurate for the rigger
(continuous-domain weights), and matches how Blender's vertex color smooth
operation actually behaves.

### Layer specification

| Property | Value |
|---|---|
| Layer name | `jiggle_boundary` (exact string, case-sensitive) |
| Color domain | Vertex (not Face Corner) |
| Data type | Byte Color (8-bit) — Float Color also acceptable, but Byte is the Blender default and matches glTF export |
| Default fill on layer creation | White (1, 1, 1) — paint red ONLY on the explicit equator rings |

### LOD coverage

The layer must be present on **all 3 body LOD meshes**:

| Mesh | Layer required? | Source |
|---|---|---|
| `mesh_pudge_body_lod0` | Yes | Hand-painted by character-artist at Stage 5 |
| `mesh_pudge_body_lod1` | Yes | Re-painted post-decimate (decimation loses vertex colors; repaint after) |
| `mesh_pudge_body_lod2` | Yes | Re-painted post-decimate |

Decimation in Blender removes vertex color data on collapsed vertices. After
generating LOD1/LOD2 from LOD0, the painter must re-apply red on the
remaining equator-ring vertices and white on the join-ring vertices, with
gradient between. At LOD2 (1,500 tris), the belly has only ~3 horizontal rings
left, so the gradient simplifies to 1-2 mid-ring vertices.

### Rigger consumption (Stage 8)

The rigger reads `jiggle_boundary` directly to derive BellyJiggle weights:

```
# Pseudocode for the rigger's auto-weight script
for vertex in mesh.vertices:
    paint = vertex.colors["jiggle_boundary"]
    raw_influence = paint.r  # red channel only
    final_weight_to_belly_jiggle = clamp(raw_influence, 0.0, 0.80)  # cap at 80%
    final_weight_to_spine1 = 1.0 - final_weight_to_belly_jiggle
```

The 80% cap (§4.1) is applied by the rigger on top of the painted gradient —
the character-artist paints the raw 0-100% intent, the rigger caps it.

### Why this matters

Without this annotation, the BellyJiggle bone's influence is set by Blender's
voxel-heat-diffuse auto-skin, which blends naively across the spine and hip
joins and produces visible mesh detachment ("belly comes off the body")
during spring-driven sway. The vertex color paint forces a clean hard boundary.

### Verification

Before handoff to rigger:

- [ ] Open `mesh_pudge_body_lod0` in Blender Vertex Paint mode
- [ ] Switch active layer to `jiggle_boundary`
- [ ] Confirm: equator rings are pure red, join rings are pure white, gradient
      visible across the transition
- [ ] Repeat for LOD1 and LOD2 meshes
- [ ] Layer name exact string check: `jiggle_boundary` (not `JiggleBoundary`,
      not `jiggle_boundry`, not `belly_jiggle_paint`)

---

## 7. Materials & Tint Delivery (Materials spec wins — dedicated 5th map)

### Material count

Two materials, two draw calls per Pudge instance.

| Material | Mesh | Atlas | Shader type | Tintable? |
|---|---|---|---|---|
| `mat_pudge_body` | `mesh_pudge_body_lod*` | 1024 × 1024 | `ShaderMaterial` (custom — see shader below) | Yes — team color |
| `mat_pudge_hook` | `mesh_pudge_hook_lod*` | 512 × 512 | `StandardMaterial3D` (Godot built-in) | No — neutral iron |

### Texture maps — body (5 maps)

| Map | File | Resolution | Color space | Channels | Compression target |
|---|---|---|---|---|---|
| BaseColor | `body_basecolor.png` | 1024² | sRGB | RGB | BasisUniversal UASTC → BC7 (desktop) / ETC2 RGB (mobile) |
| Normal | `body_normal.png` | 1024² | Linear | RG (B reconstructed in shader) | BC5 (desktop) / ETC2 RG (mobile) |
| ORM | `body_orm.png` | 1024² | Linear | RGB (R=AO, G=Rough, B=Metal) | BC7 RGB (desktop) / ETC2 RGB (mobile) |
| Emissive | `body_emissive.png` | **256²** | sRGB | RGB | BC7 (desktop) / ETC2 RGB (mobile) |
| **Tint mask** | **`body_tintmask.png`** | **1024²** | Linear | **single-channel grayscale** | **BC4 (desktop) / ETC2 R (mobile)** |

**Model spec §5's alpha-of-basecolor tint approach is superseded.** The
dedicated 5th map is preferred because:

1. **Cleaner separation of concerns** — BaseColor stays pure RGB; tint logic
   lives in its own sampler.
2. **Smaller per-pixel cost** — BC4 single-channel (0.5 bytes/px) is cheaper
   than RGBA BC7 (1 byte/px) for the alpha that would be added otherwise.
3. **No coupling** between BaseColor import settings and shader code.
4. **Painter workflow is unambiguous** — one map, one purpose.

Cost: +0.17 MB compressed VRAM per Pudge instance for the dedicated tintmask.

### Texture maps — hook (3 maps)

| Map | File | Resolution | Color space | Channels | Compression |
|---|---|---|---|---|---|
| BaseColor | `hook_basecolor.png` | 512² | sRGB | RGB | BC7 / ETC2 RGB |
| Normal | `hook_normal.png` | 512² | Linear | RG | BC5 / ETC2 RG |
| ORM | `hook_orm.png` | 512² | Linear | RGB | BC7 / ETC2 RGB |

No emissive (hook has no glowing elements). No tint mask (hook is neutral iron).

### File path and naming

All source textures delivered to:

```
src/assets/textures/heroes/pudge/
```

**Naming**: no `pudge_` prefix on filenames. The directory provides the hero
namespace. Per materials spec §13 — supersedes model spec §10's
`pudge_body_basecolor.png` form.

**Model spec §10 must be updated** to reference the new path
(`src/assets/textures/heroes/pudge/`) and prefix-free filenames. The old
referenced path `src/assets/models/heroes/textures/` is wrong on both axes.

### Tint shader contract

#### Shader formula

```glsl
final_albedo = base_color_rgb * mix(vec3(1.0), team_tint_color, tint_mask)
```

Where:
- `base_color_rgb` = `texture(albedo_texture, UV).rgb` — sampled from `body_basecolor.png`
- `team_tint_color` = uniform `vec3` (per-team color, set at runtime)
- `tint_mask` = `texture(tint_mask_texture, UV).r` — single-channel sample from `body_tintmask.png`
- When `team_tint_color = vec3(1.0)`: no tint applied (base unchanged)
- When `team_tint_color = vec3(0.5, 0.8, 0.2)`: skin tinted Pudge-green

#### Shader uniforms

| Uniform | Type | Default | Source |
|---|---|---|---|
| `albedo_texture` | sampler2D | — | `body_basecolor.png` |
| `normal_texture` | sampler2D | — | `body_normal.png` |
| `orm_texture` | sampler2D | — | `body_orm.png` |
| `emission_texture` | sampler2D | — | `body_emissive.png` |
| `tint_mask_texture` | sampler2D | — | `body_tintmask.png` |
| `team_tint_color` | vec3 (Color) | `Color(0.5, 0.8, 0.2)` (Pudge green) | Per-instance set by `HeroConfig.hero_color` via `set_instance_shader_parameter("team_tint_color", color)` |
| `emission_color` | vec3 (Color) | `Color(1.0, 0.7, 0.0)` (eye yellow) | Material constant |
| `emission_energy` | float | 3.0 | Material constant |

#### Tint mask painting guide

| Surface | Tint mask value | Tints to team color? |
|---|---|---|
| Skin (face, body, arms, legs) | 1.0 (white) | Yes |
| Leather (belt, boots) | 0.0 (black) | No |
| Iron (belt buckle, chain links) | 0.0 | No |
| Stitches | 0.0 | No |
| Eyes (sclera + pupil) | 0.0 | No |
| Teeth | 0.0 | No |
| Mouth interior | 0.0 | No |
| Apron stub | 0.0 | No |
| Blood splatter | 0.0 | No |

Soft feather (1-3 px) permitted at skin/cloth boundaries to avoid hard
edges; hard-edged at all non-skin material boundaries.

### Per-instance vs per-material parameter rules (Godot 4.6 constraint)

Per Step 5 verification (O-6, 2026-05-31): Godot 4.6 **does not support
`instance uniform sampler2D`** — the shader compiler rejects sampler types
with the per-instance qualifier. For Pudge's shader this is fine because:

- **Per-instance**: `team_tint_color` (vec3) — declared as
  `instance uniform vec3 team_tint_color`. Each MeshInstance3D sets its own
  value via `set_instance_shader_parameter()`.
- **Per-material (shared across instances)**: all `sampler2D` uniforms
  (`albedo_texture`, `normal_texture`, `orm_texture`, `emission_texture`,
  `tint_mask_texture`). Declared as regular `uniform sampler2D`. Set once on
  the shared `ShaderMaterial`; all 10 Pudge instances read the same texture
  bindings.

The Texture2D resources are reference-counted by Godot — referencing the
same texture from 10 MeshInstance3D nodes loads it into VRAM once.
**Do not attempt to make sampler uniforms per-instance later.** It will fail
to compile.

### Shader rewrite required (Stage 7 blocker)

The current shader at `res://assets/shaders/hero_body_tint.gdshader` is
**hue-band based** (detects skin color by hue range; no texture samplers
beyond albedo). It must be **rewritten** to mask-based per the formula
above.

This shader is shared across all heroes (Vex, Lash, Maw, and soon Pudge).
Rewriting it means **all existing heroes must also receive a
`body_tintmask.png`** painted to their geometry. This is a project-wide
texture-artist task, not Pudge-only.

| Hero | Current state | New deliverable |
|---|---|---|
| Vex | Hue-band tint | Author `body_tintmask.png` for Vex's body atlas |
| Lash | Hue-band tint | Author `body_tintmask.png` for Lash's body atlas |
| Maw | Hue-band tint | Author `body_tintmask.png` for Maw's body atlas |
| Pudge (new) | N/A — building from scratch | Author `body_tintmask.png` as part of Stage 7 |

Owner of shader rewrite: `godot-shader-specialist`. Owner of cross-hero
tintmask painting: `texture-artist`. Tracked in §12 propagation checklist.

### Hook material (StandardMaterial3D)

No custom shader for the hook. Use Godot's built-in `StandardMaterial3D` with:

- Albedo texture: `hook_basecolor.png`
- Normal texture: `hook_normal.png` (Normal Map preset on import)
- ORM texture: `hook_orm.png` (AO/Roughness/Metallic combined slot in Godot 4.6)
- Emission: disabled
- Cull mode: back-face cull (default)

### VRAM budget per Pudge instance

| Map | Resolution | Compressed size (mobile ETC2) | With mips (×1.33) |
|---|---|---|---|
| `body_basecolor.png` | 1024² | 0.50 MB | 0.67 MB |
| `body_normal.png` | 1024² | 0.50 MB | 0.67 MB |
| `body_orm.png` | 1024² | 0.50 MB | 0.67 MB |
| `body_emissive.png` | 256² | 0.03 MB | 0.04 MB |
| `body_tintmask.png` | 1024² | 0.13 MB | 0.17 MB |
| `hook_basecolor.png` | 512² | 0.13 MB | 0.17 MB |
| `hook_normal.png` | 512² | 0.13 MB | 0.17 MB |
| `hook_orm.png` | 512² | 0.13 MB | 0.17 MB |
| **Total per hero (textures shared across instances)** | | **~2.05 MB** | **~2.73 MB** |

With 10 instances on screen all sharing the same textures: **scene texture
cost stays at ~2.7 MB** (not 27 MB — only `team_tint_color` uniform varies
per instance).

Budget headroom: comfortable. If 2 MB ceiling is enforced post-Q1 device
decision, contingency trims per materials spec §12 (drop tintmask to 512²,
or drop body normal to 512²).

---

## 8. Performance & Target Device (DEFERRED)

### Status

**TBD.** Per Q1 decision this session, the target device tier is deferred
until `technical-director` + `producer` decide.

### What this blocks

| Downstream item | Blocked because |
|---|---|
| Mobile texture compression format choice | ASTC 6×6 (modern iOS/Android) vs ETC2 RGBA (broader Android) depends on minimum device |
| Performance gate F.4 (`design/gdd/models/pudge.md` §11) | "Under 16 ms frame time on mid-tier device" cannot be tested until "mid-tier" is named |
| LOD switch distance tuning | Aggressive LOD3 cutover for low-end vs gentler for high-end |
| Polycount ceiling renegotiation | If we lock low-end, 6,000 LOD0 may need to drop to 4,500 |

### Provisional values (assumed until Q1 is resolved)

Until the decision lands, the spec proceeds on these assumptions and flags
them everywhere they appear:

- **Assumed device class**: Samsung Galaxy A54 / iPhone 12 tier (mid-range
  2020-2023)
- **Assumed frame budget**: 16 ms (60 FPS target)
- **Assumed compression**: ETC2 RGBA (Android baseline) — switch to ASTC if
  iOS-only is locked
- **Assumed mesh polycount**: 6,000 LOD0 ceiling per model spec §2

### Decision deadline

Before **Stage 7** (texture authoring start). Compression format must be
decided to set Godot import presets correctly. If decision slips past Stage
7, textures author in ETC2 by default and re-import later if ASTC is chosen.

### Owners

- `technical-director`: technical decision (which devices to support)
- `producer`: business decision (which markets, which platforms first)

Tracked in §11 open items.

---

## 9. Forward-Axis Verification (✅ RESOLVED — Stage 4 entry, 2026-06-18)

### Status

**✅ RESOLVED — PASS (2026-06-18, Stage 4 entry).** Verified via Blender MCP:
`pudge_v2_remesh` rendered in Front Orthographic (`view_axis FRONT`) shows the
**face** (head with facial features, belly bulging toward viewer, arms out); the
Back view shows the rounded back with no face. **Face visible in front view = mesh
faces -Y in Blender = exports to -Z in Godot natively.** No rotation fix needed.
Transforms confirmed clean at the same time: location (0,0,0), rotation (0,0,0),
scale (1,1,1); world bbox Z = [0.005, 1.399] (feet ≈ Z0, height ≈ 1.4 m). The
`glb_root.rotation.y = PI` hack at `hero_model_builder.gd:74` can therefore be
removed once the new GLB ships (Stage 10), as §2 intends.

The original deferral note (kept for history): per Q2 decision, the axis check on
the `src/assets/models/heroes/anime_pudge.blend` working file was deferred to the
start of Stage 4 (sculpt cleanup).

### What to verify

1. Open `src/assets/models/heroes/anime_pudge.blend` in Blender
2. Switch viewport to **Front Orthographic** (Numpad 1)
3. Observe `pudge_v2_remesh` (the current working mesh)
4. Pass condition: Pudge's **face is visible** in this view
5. Fail condition: Pudge's **back is visible** in this view

### If pass (face visible)

The mesh already faces -Y in Blender front view. No fix needed. Proceed
to Stage 4 sculpt cleanup.

### If fail (back visible)

The mesh was imported facing +Y (wrong direction). Fix sequence:

1. Select `pudge_v2_remesh`
2. Edit Mode → select all vertices
3. Rotate 180° around Z-axis (`R Z 180 Enter`)
4. Object Mode → Apply Rotation (`Ctrl+A` → Rotation)
5. Re-verify in Front Orthographic
6. Save the file

### Why this matters

If skipped, the resulting `pudge.glb` will face +Z in Godot, requiring the
runtime 180° rotation hack at `hero_model_builder.gd:74` to persist
indefinitely. The point of this spec revision is to eliminate that hack
(see §2 implication note). Verifying axis at Stage 4 entry is the cheapest
moment to fix — before any sculpt detail has been baked into the wrong
orientation.

### Owner

`blender-specialist` (verification), `character-artist` (fix if needed).

Tracked in §11 open items and §12 propagation checklist.

---

## 10. Movement Speed Reconciliation (NEW conflict — needs gameplay-programmer)

### The conflict

Two different movement speeds are stated across the docs:

| Source | Speed cited | Context |
|---|---|---|
| Model spec §11 D (clip notes) | walk ~1.4 m/s, run ~3.5 m/s | Reference for "what the character looks like he's moving at" |
| Rig spec §8 (walk clip, run clip) | walk = 8 m/s authoring speed, run = 14 m/s authoring speed | Canonical authoring speed for `AnimationTree.BlendSpace1D` rate scaling |

These are not the same thing, but the rig spec did not flag them as
distinct — it gave 8 m/s without context. The model spec gave 1.4 m/s
without context. Neither is unambiguously the "ship value".

### Likely resolution

These are likely **two different measurements of the same animation**:

- **In-game character velocity**: 1.4 m/s walk, 3.5 m/s run (gameplay
  programmer's `CharacterBody3D.velocity` magnitude). This is what the
  game world sees.
- **Animation authoring foot timing**: 8 m/s walk, 14 m/s run (animator's
  canonical playback speed at clip rate 1.0). This is what the animator
  authored in Blender.

The `AnimationTree.BlendSpace1D` (Stage 8 technical-artist work) scales
clip playback rate based on actual character velocity:

```
playback_rate = character_velocity_magnitude / canonical_authoring_speed
```

If character is moving at 1.4 m/s and walk is authored at 8 m/s canonical:
playback rate = 1.4 / 8 = 0.175 — i.e., the walk clip plays at ~17.5% speed
in-game, making the waddle look heavy and slow (which matches Pudge's design).

### Action required

`gameplay-programmer` must confirm:

1. The canonical character movement speeds (walk + run) from the player
   controller config — what speed does Pudge actually move at in the game?
2. Whether the BlendSpace1D approach (variable clip playback rate) is
   acceptable, or whether the animator should re-author clips at the
   in-game speeds.

### Deadline

Before **Stage 9** (animation authoring starts). The animator needs to know
which speed to author the foot timing at.

### Owner

`gameplay-programmer` (data), `rigging-animator` (consumes), `game-designer`
(arbitrates if conflict).

Tracked in §11 open items.

---

## 11. Open Items Requiring Resolution

At-a-glance roll-up of every unresolved item from this contract. Owners
must close their items by the listed deadline or escalate.

| ID | Item | Source section | Owner | Deadline | Status |
|---|---|---|---|---|---|
| O-1 | Target device tier (Q1) | §8 | technical-director + producer | Before Stage 7 | DEFERRED |
| O-2 | Mesh axis verification (Q2) | §9 | blender-specialist | Stage 4 entry | ✅ RESOLVED 2026-06-18 — PASS, face visible in front ortho, mesh faces -Y, no fix needed |
| O-3 | Movement speed reconciliation | §10 | gameplay-programmer | Stage 9 entry | NEW — needs resolution |
| O-4 | BellyJiggle spring API exists in Godot 4.6? | §4.1 | Step 5 (verified 2026-05-31) | Stage 8 entry | **RESOLVED — NO.** Godot 4.6 has CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK + 4.5's BoneConstraint3D (AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D). **No spring/jiggle modifier exists.** Two paths: (A) write a custom `SkeletonModifier3D` GDScript subclass (~50 lines, evaluates spring physics each frame), or (B) keyframe BellyJiggle in all 10 animation clips. Recommend **(B) for MVP** — eliminates engine-API risk, costs ~20% more animator time. Revisit (A) post-MVP if profiling shows keyframe drift. |
| O-5 | LOD auto-detect by `_lod*` suffix works for pre-authored LODs? | §3 of model spec | Step 5 (verified 2026-05-31) | Stage 10 entry | **RESOLVED — NO.** Godot's `_lod*` suffix detection is a *proposal*, not implemented in 4.6. Godot 4.6 auto-generates LODs from a single source mesh via meshoptimizer, but does **not** group pre-authored separate meshes by suffix. **Correct workflow**: import each LOD as its own `MeshInstance3D`, configure `visibility_range_begin/end` per instance, disable LOD auto-generation in import settings. Model spec §10 must drop the "auto-detect by suffix" claim and document the per-MeshInstance3D `visibility_range_*` setup at Stage 10. |
| O-6 | Texture sharing via `set_instance_shader_parameter` preserves shared materials? | §7 (per-instance tint) | Step 5 (verified 2026-05-31) | Stage 10 entry | **RESOLVED — sampler per-instance NOT supported; scalar/vec per-instance works.** `instance uniform sampler2D` throws "SCOPE_INSTANCE not supported for sampler types". **For Pudge that's fine** — only `team_tint_color` (vec3) needs to vary per instance; samplers stay on the shared ShaderMaterial. 10 instances reference the same Texture2D resource → loaded once in VRAM. Contract §7's tint formula is correct as-written; no change needed. Document the constraint: samplers are per-material, NOT per-instance — don't try to make them per-instance later. |
| O-7 | ETC2 size cost vs ASTC 6×6 for 1024 atlas | §7 / §8 | Step 5 (verified 2026-05-31) | Stage 7 entry | **RESOLVED — ASTC 6×6 is ~2.25× smaller than ETC2 RGBA for the same 1024² atlas.** Per-pixel: ETC2 RGBA = 8 BPP (1 byte/px → 1 MB at 1024²); ASTC 6×6 = 3.56 BPP (~0.45 byte/px → ~0.46 MB at 1024²); ASTC 4×4 = 8 BPP (same as ETC2 but higher quality); BC7 desktop = 8 BPP. Godot 4.6 "Mobile / Low Quality" preset picks ETC2; "Mobile / High Quality" picks ASTC 4×4 (not 6×6). **ASTC 6×6 must be set manually per texture import.** Decision pending O-1 (device tier): if iOS-only or A8+ Android only, use ASTC 6×6 (~55% size reduction); if broader Android baseline, use ETC2 RGBA. **Materials spec §12 VRAM table may be optimistic** — re-check ETC2 RGBA estimates (spec says 0.5 MB/1024², actually ~1 MB/1024²). |
| O-8 | Cross-hero tintmask painting (Vex/Lash/Maw) | §7 | art-director (scope) + texture-artist (work) | Before Pudge ships (or scope to Pudge only) | NEW |
| O-9 | Update `design/gdd/hero-system.md` with Pudge | (Q12.18) | game-designer | Stage 10 | **PARTIAL (Step 9, 2026-05-31)** — Pudge added to roster as item 4 with hook_type=PULL, role tank/disruptor, fantasy + skill profile written. STAT VALUES still TBD (`pudge.tres` has debug placeholders — `hook_damage=99999`, `xp_on_hook_hit=0`, leveling bonuses zero). Real balance pass remains game-designer task before Stage 10. Side-finding: Coil and Flux `.tres` files exist (`CHARGE` and `BEAM` hook types) but neither is documented in hero-system.md — added as new open question in that doc. |
| O-10 | Pudge variation skins (post-MVP scope) | (Q12.23) | art-director | N/A — explicitly post-MVP | OUT OF SCOPE |
| O-11 | Team color full roster for tint validation | (Q12.22) | art-director | Before Stage 7 | OPEN |
| O-12 | Perf baseline measurement on 10-Pudge stress scene | (Step 6) | performance-analyst | After Stage 10 first export | **PARTIAL (Step 6, 2026-05-31)** — dev-machine baseline captured (RTX 5050 / Vulkan, 10 PROTOTYPE Pudges: p95 = 0.34 ms). Measurement scene + workflow live at `src/scenes/perf/pudge_stress_test.tscn` + `tests/performance/README.md`. Mobile target-device measurement still gated on O-1 (device tier) AND Stage 10 (real spec-compliant Pudge GLB). Current baseline is for the prototype primitives-built Pudge — final single-skinned-mesh Pudge will perform differently. |
| O-13 | LOD3 impostor billboard | model spec §2 LOD table | technical-artist | N/A — DEFERRED to post-MVP | RESOLVED — drop from MVP, use LOD2 to infinity (Godot 4.6 has no built-in impostor system; building one is not worth MVP scope) |

### Decision authority

If multiple owners conflict on a single item, escalate:

- Design-side conflicts → `creative-director`
- Technical-side conflicts → `technical-director`
- Scope/timeline conflicts → `producer`

---

## 12. Propagation Checklist

Every file that must be edited to align with this contract. Each item lists
the change required.

### Design documents

- [x] `design/gdd/models/pudge.md` §1 — remove "Conflicts with: rig + materials specs" line; replace with "Implements contract at `design/gdd/contracts/pudge-interface-contract.md`" *(done 2026-06-18)*
- [x] `design/gdd/models/pudge.md` §3 — replace 3-color jiggle_boundary encoding (red/yellow/white) with 2-color (red/white) per §6 of this contract *(done 2026-06-18; §9 influence table "yellow region" also fixed)*
- [x] `design/gdd/models/pudge.md` §5 — remove "BaseColor alpha = tint mask" section; replace with "Tint mask delivered as dedicated `body_tintmask.png` per contract §7" *(done 2026-06-18; shader uniforms/logic, VRAM table, set_instance_shader_parameter note all updated)*
- [x] `design/gdd/models/pudge.md` §7 — replace 5 socket position rows with values from contract §5 (rig-spec coordinates with mixamorig:* parent names) *(done 2026-06-18; world-position verification table updated too)*
- [x] `design/gdd/models/pudge.md` §9 — confirm bone count = 22 MVP (Jaw included, ChainLink excluded), remove the "25 full" line as misleading (chain is post-MVP, full count = 26 with chain) *(done 2026-06-18)*
- [x] `design/gdd/models/pudge.md` §10 — update texture paths to `src/assets/textures/heroes/pudge/` with no `pudge_` prefix on filenames *(done 2026-06-18; §11.C deliverables list updated too)*
- [x] `design/gdd/models/pudge.md` §11 F.4 — rewrite "under 16 ms on mid-tier device" with concrete device once O-1 resolves *(done 2026-06-18; F.4 split into F.4a dev-smoke + F.4b target-device acceptance, device deferred to O-1)*
- [x] `design/gdd/models/pudge.md` §2 LOD table — mark LOD3 impostor row as POST-MVP per O-13; document that LOD2 extends to infinity for MVP *(done in prior session; verified)*
- [x] `design/gdd/models/pudge.md` §10 — drop the "Godot's glTF importer auto-detects `_lod0`/`_lod1`/`_lod2` suffixes" claim per O-5. Add Stage 10 task: configure `visibility_range_begin` + `visibility_range_end` per LOD `MeshInstance3D` in the imported scene; disable Godot's automatic LOD generation in import settings (set "Generate LODs" to false). *(done 2026-06-18)*
- [ ] `design/gdd/rigs/pudge.md` §4.1 — drop the "spring if Godot 4.6 supports it, else keyframe" conditional per O-4; lock to keyframe-only for MVP. Move spring-modifier discussion to a "post-MVP polish" footnote.
- [ ] `design/gdd/rigs/pudge.md` §1 — rewrite bone hierarchy with `mixamorig:` prefix, rename `Chest` → `Spine2`, drop ChainLink1-4 (post-MVP)
- [ ] `design/gdd/rigs/pudge.md` §2 — rewrite bind pose joint angle table for T-pose (LeftArm Z=0, RightArm Z=0, spine Z=0 with no hunch in bind)
- [ ] `design/gdd/rigs/pudge.md` §4.3 — mark ChainLink bones as POST-MVP, deferred
- [ ] `design/gdd/rigs/pudge.md` §7 — update socket parent names from PascalCase to `mixamorig:` form
- [ ] `design/gdd/rigs/pudge.md` §13 — rewrite bone naming table with `mixamorig:` prefix throughout
- [ ] `design/gdd/materials/pudge.md` §13 — confirm path `src/assets/textures/heroes/pudge/` and prefix-free naming (already matches; no change needed)
- [ ] `design/gdd/materials/pudge.md` §14 — confirm shader is custom `ShaderMaterial` with mask-based tint per contract §7 (already matches)
- [x] `design/gdd/hero-system.md` — add Pudge as 4th hero per O-9 *(PARTIAL — roster entry done Step 9; stat balance still TBD before Stage 10)*

### Code

- [ ] `src/gameplay/hero/hero_model_builder.gd:25-46` — rewrite `HERO_SOCKETS` constant with the 5 socket entries from contract §5 (correct parent bones, correct local offsets, correct rotations)
- [ ] `src/gameplay/hero/hero_model_builder.gd:74` — remove the `glb_root.rotation.y = PI` line once the new GLB ships built to contract §2 (faces -Z natively)
- [ ] `res://assets/shaders/hero_body_tint.gdshader` — rewrite from hue-band detection to mask-based per contract §7 shader formula; add `tint_mask_texture` sampler uniform
- [ ] `src/gameplay/hero/hero_model_builder.gd:401-412` (`_apply_hero_tint`) — switch from `set_shader_parameter("tint_color", …)` (per-material) to a **shared** `ShaderMaterial` + per-instance `set_instance_shader_parameter("team_tint_color", color)` on each `MeshInstance3D` (per O-6). Current code mints a fresh `ShaderMaterial` per build and sets the tint per-material; once §7 textures are bound this inflates VRAM ~10× (a unique textured material per instance). Also rename the uniform `tint_color` → `team_tint_color` and drop `tint_strength` to match the §7 shader contract. Stage 10 code task.

### Tools

- [ ] `tools/blender/validate_export.py` — finish partial implementation (Step 4 task)
- [ ] `tools/blender/verify_hook_weights.py` — new script per Step 4 task
- [ ] `tools/blender/heroes/preview_pudge_anims.py` — verify still works with renamed bones (no change expected if Mixamo names preserved)

### Cross-hero impact (from contract §7)

- [ ] `src/assets/textures/heroes/vex/body_tintmask.png` — new deliverable per O-8
- [ ] `src/assets/textures/heroes/lash/body_tintmask.png` — new deliverable per O-8
- [ ] `src/assets/textures/heroes/maw/body_tintmask.png` — new deliverable per O-8

### Verification gates after propagation

- [ ] All three specs (model, rig, materials) re-read end-to-end for residual inconsistencies
- [ ] `/design-review design/gdd/models/pudge.md` re-run → target APPROVED verdict
- [ ] Manual smoke check: load updated `HeroModelBuilder` in Godot editor, instantiate placeholder Pudge, confirm no runtime errors
- [ ] Run `src/scenes/perf/pudge_stress_test.tscn` on the target mobile device (post-Stage 10) and record p95 in `tests/performance/README.md` history table
- [ ] This contract's §11 open items list has zero entries in NEW or OPEN status (DEFERRED, PARTIAL with owner+deadline, and RESOLVED entries are acceptable)

---

*End of Pudge Interface Contract. Status: DRAFT awaiting consumer review.
Next: notify model-spec author, rig-spec author, materials-spec author, and
gameplay-programmer that this contract exists and supersedes the conflicting
sections in their specs (§12 propagation checklist).*
