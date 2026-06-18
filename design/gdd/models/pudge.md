# Model Spec — Pudge

> **Status**: ✅ **APPROVED — Stage 3 model spec complete (2026-06-18)** — body text aligned to the interface contract; `/design-review` re-run (lean) verdict APPROVED. Cleared to begin Stage 4 (sculpt cleanup). Prior review (2026-05-31) verdict was NEEDS REVISION (15 BLOCKING, root cause: contract decisions not propagated into this spec's body). See `design/gdd/reviews/pudge-model-review-log.md` for review history and `production/session-state/active.md` for resume instructions.
> **Hero ID**: `pudge` (separate 4th hero — not in current Vex/Lash/Maw roster; hero-system.md needs updating later)
> **Stage**: 3 of 10 (Model Specification)
> **Date**: 2026-05-30
> **Brief**: `design/characters/pudge-character-brief.md`
> **Concept**: `design/concept-art/pudge.md` — Silhouette B (Coiled Hook Carry) APPROVED 2026-04-28
> **Predecessor spec**: archived to `design/gdd/models/_archive/pudge.md.2026-04-28` (superseded by fresh Stage 3 authoring this session)
> **Engine**: Godot 4.6
> **Implements contract**: `design/gdd/contracts/pudge-interface-contract.md` — the single source of truth for bone names, socket transforms, jiggle encoding, tint-mask delivery, bind pose, axes, and bone count. Where this spec and the contract disagree, **the contract wins** and this spec is the document to fix. Cross-doc reconciliation with `design/gdd/rigs/pudge.md` and `design/gdd/materials/pudge.md` is resolved through that contract.

This document is the written contract between modeling and all downstream consumers
(texture-artist, rigging-animator, blender-specialist, technical-artist, gameplay-programmer).
Nothing in this spec may change without notifying those consumers and updating this file.

---

## 1. Overview

| Field | Value |
|---|---|
| **Asset category** | Character — playable hero (MOBA) |
| **Hero ID** | `pudge` |
| **Role** | Tank / melee disruptor |
| **Signature ability** | Hook throw — single-target ranged grab that pulls an enemy in |
| **Gameplay fantasy** | Grotesque jovial butcher. Intimidating + amusing simultaneously. |
| **Concept reference** | `design/concept-art/pudge.md` — Silhouette B ("Coiled Hook Carry") APPROVED 2026-04-28 |
| **Target platform tier** | **Mobile Mid** — modern mobile MOBA (Brawl Stars / Vainglory tier) |
| **Distance class** | **Mid** — primary view at 5-8 m gameplay camera, close-up at 1.5-2 m menu/select |
| **Style direction** | Chibi (3 heads tall, exaggerated proportions, simplified anatomy) |
| **Total height** | 1.4 m world units (Godot world scale, 1 unit = 1 m) |
| **Bind pose** | T-pose (clean Mixamo retargeting). Silhouette B "raised hook arm" rest is driven by the idle animation layer, NOT baked into bind. |
| **LOD strategy** | 4 levels (LOD0 / LOD1 / LOD2 / Impostor billboard) |
| **Hook prop** | Separate object — detachable as projectile during `hook_throw` ability. 2 materials, 2 draw calls. |

### Pipeline source

This model is being built from a Hunyuan3D AI-generated base mesh (`textured_mesh` in `src/assets/models/heroes/anime_pudge.blend`). The AI mesh is used as **silhouette + bake reference only** — the final game-ready mesh is hand-retopologized (Stage 5). The original concept art (Silhouette B) remains the authoritative design target; the AI mesh approximates it but does not replace concept review.

### Downstream consumers

This spec is the contract for the following agents/stages:

- **Stage 4** (Sculpt cleanup) — character-artist consumes the topology and silhouette targets.
- **Stage 5** (Retopo) — character-artist consumes geometry budget, topology requirements, mirror strategy.
- **Stage 6** (UV) — character-artist + texture-artist consume UV layout and texel density targets.
- **Stage 7** (Texturing) — texture-artist consumes materials, channel packing, atlas sizes.
- **Stage 8** (Rigging) — rigging-animator consumes deformation loops, skeleton bone list, sockets.
- **Stage 9** (Animation) — rigging-animator consumes bind pose, sockets, jiggle bone reference.
- **Stage 10** (Godot export) — blender-specialist + gameplay-programmer consume naming, pivot, orientation, material/draw-call budget.

### Why this spec exists

Before any geometry work begins, every downstream stage must agree on the numbers. If retopo finishes at 9k tris and the spec said 6k, texture-artist's budget plan is broken. If UV islands are 1024 packed but spec said 512, mobile memory budget breaks. The spec eliminates those late-stage surprises.

---

## 2. Geometry Budget

Mobile Mid tier. Hard ceiling and working targets below — modeler aims for working,
hard ceiling is the renegotiate-or-cut threshold.

### LOD Table

| LOD | Body tris (working) | Body tris (hard ceiling) | Hook tris | Combined LOD total | Use distance |
|---|---|---|---|---|---|
| **LOD0** | 5,400 | 6,000 | 600 | **6,000** working / **6,600** ceiling | 0 – 12 m (close + game cam) |
| **LOD1** | 2,700 (50%) | 3,000 | 300 | **3,000** working / **3,300** ceiling | 12 – 25 m |
| **LOD2** | 1,350 (25%) | 1,500 | 150 | **1,500** working / **1,650** ceiling | 25 m+ (LOD3 deferred to post-MVP per contract O-13) |
| **LOD3** | ~~impostor sprite~~ | — | — | ~~8 frames @ 128×128 px (1024×128 horizontal strip)~~ | ~~50 m+~~ — **DEFERRED to post-MVP** per contract O-13; **LOD2 extends to infinity for MVP** |

**Total geometry memory budget across all LODs** (body + hook): ~10,800 tris working.
At ~20 bytes/vert × ~7k verts/LOD avg ≈ 140 KB mesh data per character — well inside
mobile budget for 10 hero instances on screen.

**LOD switch distances** are recommended starting values. Technical-artist tunes in
Stage 10 based on actual draw-call profiling on target hardware.

### Per-Region Tri Allocation (LOD0 body — 5,400 working target)

| Region | Tris | Notes |
|---|---|---|
| **Head + face + jaw** | 720 | Skull dome + face plane + jaw block. Mouth cavity recessed. |
| **Teeth strip (upper + lower)** | 80 | Single quad-strip per jaw edge, 8 quads × 1 quad tall × 2 rows. Individual teeth painted, not modeled. |
| **Eyes (both)** | 100 | 2 × low-poly sphere caps (5-sided). Left ~15% larger per concept asymmetry. |
| **Torso + belly sphere** | 950 | 8 vertical columns × 6 horizontal rings on belly (96 quads = 192 tris) + chest panel + back panel. Forward density higher for stitch geometry. |
| **Apron stub** | 80 | Merged into torso geometry. 4-6 quad strip hanging from belt line. |
| **Hips / pelvis mass** | 280 | Connects belly to upper legs. Bears 4 deformation loops. |
| **Left arm (hook arm — chunkier)** | 520 | Upper arm + forearm. ~20% denser radius than right arm. |
| **Right arm** | 420 | Upper arm + forearm. Standard radius. |
| **Left hand (hook grip)** | 200 | Simplified fist — no individual fingers. Hosts hook attach socket. |
| **Right hand (cleaver/offhand)** | 160 | Simplified fist. |
| **Legs (both)** | 480 | Stubby thigh + shin per leg, 240 each. Mirrored UVs. |
| **Boots (both)** | 560 | Boot box with toe splay + sole + lace stub geometry. Mirrored UVs. |
| **Belt band** | 100 | Thin ring around waist (8 quads horizontal × 2 vert). |
| **Belt buckle** | 40 | Flat box on belt front center. First-cut candidate. |
| **Belt chain links (3-4 visible)** | 240 | 80 tris per oval-toroid link, 3 links visible from belt back/side. |
| **Safety margin reserve** | 470 | Reserved for: belly extra ring if jiggle needs more density, shoulder corrective loop on hook arm side, hip extra loop. |
| **LOD0 body total** | **5,420** | Inside 5,400 working target (+20 tris within margin). Hard ceiling 6,000 leaves 580 tris of headroom. |

### Hook Prop Allocation (LOD0 — 600 tris)

| Region | Tris | Notes |
|---|---|---|
| Hook body (J-curve iron bar) | 280 | 8-sided cylinder bent into J. The silhouette priority — densest part. |
| Inner curve / tip (blood zone) | 140 | Higher density for normal map detail (blood relief). UV island for blood spatter sits here. |
| Chain link stubs (1-2 physically welded to hook) | 180 | Adjacent to hook body. These ride with the hook when projectile-spawned. |
| **Hook total** | **600** | Exact budget. |

### Where to Cut if Forced Under Budget

In strict priority order — character-artist drops these in this sequence if profiling
shows we're over draw-call or vertex-buffer budget:

1. **Belt buckle box** → painted quad on belt strip (-40 tris)
2. **Boot lace stubs** → painted into boot base color (-80 tris)
3. **Belt chain links** → reduce 3 visible to 2 (-80 tris)
4. **Teeth strip** → halve from 80 → 40 tris (-40)
5. **Eye spheres** → flat discs (-40 tris)
6. **Apron stub** → paint apron edge onto belt strip (-80 tris)
7. **Hook prop chain links** → remove the 1-2 welded links (-180 tris)

Total recoverable: ~540 tris. After all cuts: ~4,880 body + 420 hook = 5,300 total.
This is the floor — below this, silhouette degrades unacceptably for the mobile MOBA read.

### LOD1 Collapse Plan (3,000 tris ceiling)

Features that disappear or simplify at LOD1:

| Feature | LOD0 | LOD1 |
|---|---|---|
| Belt chain links | 3 separate toroids | Single twisted quad strip (~40 tris) |
| Teeth strip | Geometry strip (80) | Painted dark gash (1 quad) |
| Boot lace stubs | Quad strips (~60) | Removed, painted |
| Eye spheres | Sphere caps (100) | Flat discs (24) |
| Belt buckle | Box (40) | Painted quad on belt |
| Hook arm asymmetry | Preserved (20% denser) | Preserved (silhouette-critical) |
| Apron stub | 80 tris | Removed, painted |
| Hook prop | 600 tris | 300 tris (no inner-curve bevel, 1 chain link stub) |

### LOD2 Collapse Plan (1,500 tris ceiling)

Further reductions on top of LOD1:

| Feature | LOD1 | LOD2 |
|---|---|---|
| Hook arm asymmetry | Preserved | **Collapsed** — both arms same density |
| Boot toe splay | Reduced | Removed — boot becomes rounded prism |
| Belly rings | 6 horizontal | 3 horizontal (still drives jiggle, just coarser) |
| Stitch micro-geometry | Reduced | Removed — paint only |
| Shoulder loops | 4 L / 3 R | 2 / 2 |
| Mouth loops | 4 concentric | 3 concentric |
| Eye loops | 5 concentric | 3 concentric |
| Hook prop | 300 tris | 150 tris (box + single arc, no chain) |

### LOD3 Impostor — DEFERRED to post-MVP

Per contract O-13 (`design/gdd/contracts/pudge-interface-contract.md` §11):

**LOD3 impostor billboard is dropped from MVP scope.** LOD2 extends to
infinity instead — Pudge renders at LOD2 (1,500 tris) for all distances
beyond ~25 m.

Reasoning:
- Godot 4.6 ships no built-in impostor system.
- Building a custom impostor pipeline (8-angle camera bake + sprite-sheet
  packing + custom shader for billboard orientation + LOD swap logic) is
  multi-day work for one hero — does not fit MVP budget.
- LOD2 at 1,500 tris × 10 instances × distance > 25 m is well within mobile
  mid-tier draw budget; no measurable savings from going lower.

#### Post-MVP design (preserved for reference)

When impostor work is revisited, the original design intent:

- Pre-rendered sprite billboard. 8 rotation angles (every 45°).
- Rendered from top-down 30° pitch camera matching game camera angle.
- 128×128 px per frame, packed as a 1024×128 horizontal strip OR a
  512×256 grid (2 rows × 4).
- South-facing (camera-facing) frame must show the **raised hook arm
  silhouette** (Silhouette B's signature) to sell the hook hero identity
  at glance-distance.
- Generation script lives in `tools/blender/` (not yet written).

---

## 3. Topology Requirements

Topology is non-negotiable on deforming surfaces. Loop counts below are MINIMUMS —
modeler may add within budget. Drop below these only with explicit character-artist
and rigging-animator approval.

### Deformation Loops Per Joint

Every joint that moves under animation needs concentric edge loops perpendicular to
the joint's primary rotation axis. Loops must be CLOSED RINGS, not open edge fans.

| Joint / Region | Min loops | Reason |
|---|---|---|
| **Left shoulder socket** | **4** | Hook arm raises to ~45° above horizontal in idle (Silhouette B pose driven by anim). 4 loops prevent pinching at the raise extreme. **Asymmetric** — only left needs 4. |
| **Right shoulder socket** | **3** | Right arm has limited raise range (cleaver swing for `attack_basic` only). 3 loops sufficient. |
| **Left elbow** | **3** | Hook arm bends during `hook_throw` wind-up. |
| **Right elbow** | **3** | Cleaver swing during `attack_basic`. |
| **Left wrist** | **2** | Wrist rotation for hook release frame. |
| **Right wrist** | **2** | Cleaver swing rotation. |
| **Hips** | **4** | Walk/run waddle + death fall backward. Highest deformation stress after the shoulder. |
| **Left knee** | **3** | Stubby chibi leg; knee bend shallow in walk, active in death stagger. |
| **Right knee** | **3** | Mirror of left. |
| **Left ankle** | **2** | Boot sole stays near Z=0 in locomotion. |
| **Right ankle** | **2** | Mirror. |
| **Mouth** | **4 concentric** | Jaw bone drives lower half. Death and taunt require full open. |
| **Eyes (each)** | **5 concentric** | Both eyes use same loop count. Asymmetry (left eye ~15% larger) lives in sculpt sphere scale, NOT in loop count or density. |
| **Neck base** | **Special — 2 loops only** | No-neck hunch (see below). |

### Belly Topology — BellyJiggle Bone Domain

The belly is Pudge's defining silhouette feature AND drives the `BellyJiggle` secondary
motion bone. Topology must support both.

**Ring layout** (concentric horizontal rings on the gut sphere, centered on the forward
protrusion point — NOT the anatomical waist):

```
   Z (up)
    |
    +-- Ring 6 (top, transitioning to torso/chest)        ← 0% jiggle (white)
    +-- Ring 5                                            ← gradient (pink)
    +-- Ring 4                                            ← gradient (pink)
    +-- Ring 3 (EQUATOR — maximum circumference)          ← 100% jiggle (red)
    +-- Ring 2                                            ← 100% jiggle (red, forward-lower)
    +-- Ring 1 (bottom, transitioning to hip mass)        ← 0% jiggle (white)
    +-- pole cap (hidden inside torso overlap)
```

- **6 horizontal rings** total
- **8 vertical columns** (8-sided radial topology)
- **96 quads total** on the gut dome = 192 tris (matches budget §2)

**BellyJiggle influence falloff** (painted as `jiggle_boundary` vertex color layer — **2-color encoding per contract §6**):

- **Red (RGB 1, 0, 0) = 100%**: equator ring (Ring 3) + forward-lower ring (Ring 2)
- **White (RGB 1, 1, 1) = 0%**: top rings (5, 6) joining torso + lowest ring (1) joining hip
- **Pink gradient between**: the painter does NOT hand-paint a discrete 50% middle band. Blender's vertex-paint gradient/smear tool produces the linear interpolation between the red equator rings and the white join rings. This is simpler for the painter and gives the rigger continuous-domain weights. **The previously-authored 3-color (red/yellow/white) encoding is superseded.**

The rigger reads `jiggle_boundary` directly to assign BellyJiggle weights (capped at
80% per rig spec — character-artist paints raw 0-100% gradient, rigger applies the cap).

### No-Neck Hunch (Trapezius / Skull Join)

Per concept Silhouette B: "head sunk into hunched shoulders, no visible neck." Topology
must respect this — the trapezius/shoulder mass merges directly into the base of the
skull with at most **1-2 cm of visible neck column** (0.01-0.02 m at 1 unit = 1 m).

**Implementation**:

- The neck column is a **single 1-segment stub**, 4 quads wide × 2 loops.
- NOT a full neck tube with 6-8 vertical segments.
- The trapezius shoulder geometry fans out radially from this stub in both directions.
- The `Neck` bone deforms this region but has **near-zero useful rotation range** —
  rigger constrains to ±5° max per axis (rig spec §14).
- Head rotation is driven by the `Head` bone, NOT `Neck`.

**Retopo discipline**: the retopologist must resist the temptation to add neck height
for ergonomic UV unwrapping. Force the UV seam at the base-of-skull instead. Adding
neck geometry breaks the silhouette.

### Quad Rule Enforcement

**Quads only on all deforming surfaces**: body, arms, legs, face, belly, hands, boots.

**Tris permitted** ONLY in these specific hidden / non-deforming locations:

- **Pole caps inside boot sole** — fully hidden from camera at all angles
- **Mouth cavity interior** — fully occluded at game camera distance
- **Top of gut sphere → torso merge seam** — inside torso overlap, never visible
- **Hook prop interior cap** — inside the J-curve where ray-cast won't see

**5-poles and 3-poles** (edge-flow terminators) must be placed on **flat stable surfaces**:

- Center of the **back torso panel** (between the shoulder blades, hidden from top-down cam)
- Center of the **back of the head skull** (occluded at top-down 30° pitch)
- Inside the **mouth cavity**

**Never place poles** on or within 2 edge loops of a deforming joint. A pole at the
shoulder joint causes shearing during arm rotation.

### Symmetry and Mirror Axis

- **Mirror axis**: X-axis (left/right of character)
- **Build half then mirror**: standard workflow — model left half (-X side from character
  POV = -X in world), apply Mirror modifier with Clipping enabled, apply at LOD0.
- **Break symmetry AFTER mirroring** for these intentional asymmetries:
  - **Left arm chunkier** (~20% wider radius): scale arm geometry on +X side after mirror apply.
  - **Left eye larger** (~15%): scale eye sphere on +X side after mirror apply.
  - **Belt chain links**: positioned asymmetrically (left hip coil per concept) — built post-mirror.

### Smoothing Groups / Custom Normals

- **Smooth shading** enabled on all body and hook geometry.
- **Sharp edges** (Mark Sharp) at: boot sole edge, belt buckle outer edge, hook tip,
  apron stub edge.
- **Custom normals NOT required at this scale** — Pudge is too small and too chibi for
  normal-driven seam control to matter. Standard auto-smooth at 30° angle threshold
  is sufficient.
- **Auto-smooth angle**: 30°.

---

## 4. UV Layout

Two atlases: 1024×1024 body, 512×512 hook prop. Single UV channel per mesh (no UV1 —
lightmap/detail maps not needed at this tier). Pack with 8 px minimum padding at the
authoring resolution.

### Body Atlas — 1024 × 1024 (`mat_pudge_body`)

Conceptual quadrant layout. Island placement below is by quadrant + approximate
occupancy. The packer (Blender's built-in Pack Islands or UV Packmaster) will
optimize within these constraints.

```
+---------------------------+---------------------------+
| TOP-LEFT (~35% of atlas)  | TOP-RIGHT (~25%)          |
|                           |                           |
|   FACE ISLAND             |   TORSO FRONT             |
|                           |                           |
|   - Face (~25%)           |   - Belly sphere front    |
|   - Skull wrap (~10%)     |   - Chest panel           |
|   - Eye sclera + pupil    |   - Stitches (painted)    |
|     sub-island            |   - Apron stub sub-island |
|                           |     (bottom-right corner) |
+---------------------------+---------------------------+
| BOTTOM-LEFT (~25%)        | BOTTOM-RIGHT (~15%)       |
|                           |                           |
|   ARMS + HANDS            |   LEGS + BOOTS + BELT     |
|                           |                           |
|   - Left arm (taller)     |   - Both legs mirrored    |
|   - Right arm (below)     |     (one strip)           |
|   - Left hand             |   - Both boots mirrored   |
|   - Right hand            |     (one strip)           |
|   - Chain links edge      |   - Belt band (thin       |
|     strip                 |     horizontal strip)     |
|                           |   - Torso back panel      |
+---------------------------+---------------------------+
```

Unused / padding accounts for ~5% of atlas.

#### Body Texel Density Targets

| Region | Density (px/m) | Why this density |
|---|---|---|
| **Face (eyes, mouth, asymmetric features)** | **512** | Highest density region. Mobile MOBA portraits zoom face — must hold up at menu close-up (~1.5 m). |
| Head (back, skull) | 256 | Back of head not readable at top-down game cam — standard density fine. |
| Torso front (belly + stitches + chest) | 256 | Stitches must resolve at game cam — 256 px/m gives ~3 px stitch width. |
| Torso back | **128** | Half density. Back is rarely visible at top-down 30° pitch. |
| Arms (both) | 256 | Hook arm slightly more visible but doesn't justify higher density. |
| Hands | 256 | Fist detail reads via silhouette, not texture. Standard. |
| Legs | **128** | Mostly hidden under gut overhang. Minimal density. |
| Boots | 256 | Personality element when Pudge walks. Scuff + lace detail need 256. |
| Belt + buckle | 256 | Metallic buckle highlight needs to resolve. |
| Apron stub | 256 | Blood staining must be legible. |
| Belt chain links | 256 | ~8-12 px per link at game cam — sufficient with painted highlights. |

#### Body UV Seam Placement

Seams hidden from primary camera angle (top-down 30° pitch):

- **Head**: seam at back-of-skull center vertical
- **Torso**: seam along center-back spine column (vertical)
- **Arms**: seam along inner arm (axilla — facing body, not camera)
- **Legs**: seam along inner thigh (occluded by gut overhang)
- **Boots**: seam at back of boot (rear-facing at gameplay cam)
- **Belt**: seam at back-center of belt band
- **Apron stub**: seam at attachment edge under the belt

### Hook Atlas — 512 × 512 (`mat_pudge_hook`)

Independent atlas + material for the detachable hook prop. Layout:

```
+---------------------------+---------------------------+
| HOOK BODY TOP HALF (~60%) |
|                           |
|   J-curve iron bar +      |
|   inner curve sub-region  |
|   (blood zone — painted   |
|   only on inner curve     |
|   and tip)                |
+---------------------------+---------------------------+
| Chain link 1  | Chain link 2  | Chain link 3 | Chain link 4 |
| (largest,     | (slightly     | (smaller)    | (smallest    |
|  closest to   |  smaller)     |              |  / partial   |
|  hand)        |               |              |  island)     |
+---------------+---------------+--------------+--------------+
```

**Important hook chain distinction**:
- Chain links that drape from hand to belt (the visible silhouette chain) → modeled
  as part of `mesh_pudge_body`, on the BODY atlas.
- Chain links physically welded to the hook prop (1-2 links exiting hook spine) → on
  the HOOK atlas. These ride with the hook as a projectile.

#### Hook Texel Density Targets

| Region | Density (px/m) | Why |
|---|---|---|
| Hook body bar (J-curve) | 512 | Hook is silhouette priority — densest part. |
| Inner curve / tip (blood zone) | 512 | Blood spatter painting needs resolution. |
| Chain link stubs (on hook) | 256 | Smaller features; 8-12 px per link at game cam. |

### Mirroring Strategy

Mirror these regions to reclaim ~30% of UV space:

- **Both legs**: mirrored — one UV island shared. Legs are nearly identical and
  barely visible. No asymmetric leg detail planned.
- **Both boots**: mirrored — one UV island. Boot wear/scuff is symmetric.
  The concept's "split seam on left boot" can be added by texture-artist using
  emissive/roughness channel variation, NOT by breaking UV symmetry.

**NOT mirrored** (asymmetric details required):

- **Left/right arms**: hook arm is visibly chunkier (~20% denser radius). Each gets
  its own UV island. Texture-artist may add hook-side wear details.
- **Torso left/right**: stitches, stitch holes, and front-centered belt buckle
  require asymmetric painting capability.
- **Face**: left eye is larger; asymmetric eye emissive intensity may differ.
  Full asymmetric UV coverage required.
- **Belt chain coil**: positioned on character's left hip per concept Silhouette B.

### Padding and Pack Verification

- **Minimum 8 px padding** between all islands at 1024 authoring resolution.
- Run Pack Islands with `margin=0.0078` (≈ 8 px / 1024).
- **MIP test**: verify at MIP level 2 (256 × 256) — no island bleeds into adjacent
  islands. If bleeds appear, increase padding to 12 px on the affected islands and
  re-pack.

### Why No UV1

UV1 channels are needed for:
- Lightmaps (baked global illumination) — not used at mobile MOBA scale; dynamic
  lighting only.
- Detail/decal maps — out of scope for chibi style at 1024 atlas density.
- Tint mask channel — already handled by vertex color or single-channel mask map
  (see Materials §5).

Single UV channel keeps mesh data lean and import simple.

---

## 5. Materials

Two materials, two draw calls. **5 maps for the body, 3 for the hook.** Mobile PBR
pipeline with **ORM channel packing** (R=AO, G=Roughness, B=Metallic) — industry-standard
for mobile to halve texture sample count. The team-tint mask is delivered as a **dedicated
5th body map (`body_tintmask.png`)** per contract §7 — **not** packed into the BaseColor
alpha as earlier drafts of this spec assumed.

### Material List

| Material | Mesh | Atlas | Shader | Tintable? |
|---|---|---|---|---|
| `mat_pudge_body` | `mesh_pudge_body_lod*` | 1024 × 1024 | `hero_body_tint.gdshader` (custom `ShaderMaterial`) | **Yes** — team tint via dedicated `body_tintmask.png` |
| `mat_pudge_hook` | `mesh_pudge_hook_lod*` | 512 × 512 | Godot StandardMaterial3D | **No** — neutral iron, no team tint |

**Draw call budget**: 2 per Pudge instance. With 10 heroes on screen, total mesh draw
calls = 20 (10 bodies + 10 hooks). Comfortable for mobile renderer.

### Channel Packing — Body Material (5 maps)

Per contract §7 the body uses **5 maps**. The tint mask is its own single-channel map,
**not** the BaseColor alpha. BaseColor stays pure RGB.

| Texture | Resolution | Channels | Content |
|---|---|---|---|
| `body_basecolor.png` | 1024 × 1024 | RGB | Hand-painted base color (un-tinted). **No alpha** — tint lives in `body_tintmask.png`. |
| `body_normal.png` | 1024 × 1024 | RG (B reconstructed) | Tangent-space normal map baked from high-poly. B channel reconstructed at runtime via `sqrt(1 - R² - G²)` to save 1/3 texture size. |
| `body_orm.png` | 1024 × 1024 | RGB | **R = AO** (baked combined scene), **G = Roughness**, **B = Metallic** |
| `body_emissive.png` | 256 × 256 | RGB | Sparse texture — eyes only. Cropped to the eye UV sub-island to save memory. Black elsewhere. |
| `body_tintmask.png` | 1024 × 1024 | single-channel grayscale (R) | **Team-tint mask** (1.0 = full tint, 0.0 = no tint, soft 1-3 px feather permitted at boundaries). Compresses to BC4 (desktop) / ETC2 R (mobile). |

**Why a dedicated tint-mask map instead of BaseColor alpha** (per contract §7): cleaner
separation of concerns (BaseColor stays pure RGB), cheaper per-pixel cost (BC4
single-channel at 0.5 byte/px beats the RGBA BC7 the alpha would force), no coupling
between BaseColor import settings and shader code, and an unambiguous one-map/one-purpose
painter workflow. Cost: +~0.17 MB compressed VRAM per hero.

**Why a separate small emissive texture**: the emissive region is ~3% of the body atlas
(eyes only). Allocating a full 1024 emissive map would waste ~1 MB for one tiny feature.
A cropped 256 × 256 holding just the eye island region drops emissive cost to ~64 KB.

**Tint mask painting guide** (`body_tintmask.png`, single-channel grayscale):

| Surface | Mask value | Tints to team color? |
|---|---|---|
| Skin (face, body, arms, legs) | 1.0 (white) | Yes — primary identity |
| Leather (belt, boots) | 0.0 (black) | No — natural brown |
| Iron (belt buckle, chain links) | 0.0 | No — neutral metal |
| Stitches | 0.0 | No — black thread |
| Eyes (sclera + pupil) | 0.0 | No — yellow + black |
| Teeth | 0.0 | No — yellowed off-white |
| Mouth interior | 0.0 | No — dark red |
| Apron stub | 0.0 | No — bloodied off-white |
| Blood splatter | 0.0 | No — red |

Texture-artist paints the mask as 1.0 on all skin regions, 0.0 everywhere else.
Soft feather (1-3 px ramp) at skin/cloth boundaries to avoid hard tint edges;
hard-edged at all non-skin material boundaries.

### Channel Packing — Hook Material

| Texture | Resolution | Channels | Content |
|---|---|---|---|
| `hook_basecolor.png` | 512 × 512 | RGB | Hand-painted iron base color + blood spatter on inner curve/tip. No alpha. |
| `hook_normal.png` | 512 × 512 | RG (B reconstructed) | Tangent-space normal from fresh high-poly bevel pass (NOT from AI mesh). |
| `hook_orm.png` | 512 × 512 | RGB | R = AO (combined scene bake), G = Roughness, B = Metallic |

No emissive on hook prop. No tint mask (hook is always iron-grey).

### Shader Target — Body

The shader at `res://assets/shaders/hero_body_tint.gdshader` (integrated in
`HeroModelBuilder._apply_hero_tint()`) is currently **hue-band based** (detects skin by
hue range; no tint-mask sampler). Per contract §7 it must be **rewritten to mask-based**,
sampling a dedicated `tint_mask_texture`. This is a shared-shader rewrite affecting all
heroes — see "Cross-hero impact" note below.

#### Shader inputs (uniforms — per contract §7)

| Uniform | Type | Per-instance? | Source | Default |
|---|---|---|---|---|
| `albedo_texture` | sampler2D | **No** — per-material | `body_basecolor.png` | — |
| `normal_texture` | sampler2D | No — per-material | `body_normal.png` | — |
| `orm_texture` | sampler2D | No — per-material | `body_orm.png` | — |
| `emission_texture` | sampler2D | No — per-material | `body_emissive.png` (256 × 256) | — |
| `tint_mask_texture` | sampler2D | No — per-material | `body_tintmask.png` | — |
| `team_tint_color` | vec3 (Color) | **Yes** — `instance uniform` | Per-instance via `HeroConfig.hero_color` | `Color(0.5, 0.8, 0.2)` (Pudge green) |
| `emission_color` | vec3 (Color) | No — material constant | per concept | `Color(1.0, 0.7, 0.0)` (eye yellow) |
| `emission_energy` | float | No — material constant | per concept | 3.0 |

**Godot 4.6 per-instance constraint (contract O-6):** only `team_tint_color` (a vec3)
is `instance uniform`; **all `sampler2D` uniforms stay per-material.** Godot 4.6 rejects
`instance uniform sampler2D` at compile (`SCOPE_INSTANCE not supported for sampler
types`). The 10 on-screen Pudge instances share one `ShaderMaterial` and reference the
same `Texture2D` resources (loaded into VRAM once); only the tint color varies per
instance. **Do not attempt to make the samplers per-instance later — it will not compile.**

**Per-instance set call:** the runtime must set the tint via
`set_instance_shader_parameter("team_tint_color", color)` — **not**
`set_shader_parameter()`. `set_shader_parameter()` mutates the shared material and would
either tint every instance the same color or force a unique material per instance
(inflating VRAM ~10×). This corrects the current `_apply_hero_tint` at
`hero_model_builder.gd:401-412`, which uses `set_shader_parameter` (filed as a Stage 10
code task — see §11.H and the separate code task).

#### Shader logic (per-fragment, pseudocode)

```glsl
// tint mask is its own single-channel map, NOT the basecolor alpha
vec3  base_rgb   = texture(albedo_texture, UV).rgb;
float tint_mask  = texture(tint_mask_texture, UV).r;

// mix toward team color by the mask; team_tint_color == vec3(1.0) → no tint
vec3 final_albedo = base_rgb * mix(vec3(1.0), team_tint_color, tint_mask);

vec3 normal_ts = decode_normal_rg(texture(normal_texture, UV).rg);

vec3 orm = texture(orm_texture, UV).rgb;
float ao = orm.r;
float roughness = orm.g;
float metallic = orm.b;

vec3 emission_sample = texture(emission_texture, UV).rgb;
vec3 final_emission  = emission_sample * emission_color * emission_energy;

ALBEDO = final_albedo;
NORMAL_MAP = normal_ts;
AO = ao;
ROUGHNESS = roughness;
METALLIC = metallic;
EMISSION = final_emission;
```

#### Cross-hero impact

Rewriting the shared `hero_body_tint.gdshader` to mask-based means **every existing hero
(Vex, Lash, Maw) also needs a `body_tintmask.png`** painted to its geometry, or it will
render untinted. This is a project-wide texture-artist task tracked in contract O-8, not
a Pudge-only deliverable. Shader-rewrite owner: `godot-shader-specialist`; cross-hero
tintmask owner: `texture-artist`.

### Shader Target — Hook

Standard Godot `StandardMaterial3D` with:
- Albedo texture: `hook_basecolor.png`
- Normal texture: `hook_normal.png` (set normal map flag)
- ORM texture: routed to AO, Roughness, Metallic via Godot's built-in ORM import
- No emissive, no tint, no custom shader needed

### Texture Compression (Godot Import Settings)

**Compression format is gated on contract O-1 (device tier).** The table below uses the
**ETC2 RGBA baseline** (broad Android) because it is the conservative, larger figure —
per contract O-7, the earlier ASTC-6×6 numbers in this spec were ~2.25× too optimistic
and ASTC 6×6 must be set manually per-texture. If O-1 locks iOS-only / A8+ Android,
switch to ASTC 6×6 for ~55% savings. VRAM figures below match contract §7's table.

| Map | Resolution | ETC2 baseline (compressed) | With mips (×1.33) |
|---|---|---|---|
| `body_basecolor.png` | 1024² | 0.50 MB | 0.67 MB |
| `body_normal.png` | 1024² | 0.50 MB | 0.67 MB |
| `body_orm.png` | 1024² | 0.50 MB | 0.67 MB |
| `body_emissive.png` | 256² | 0.03 MB | 0.04 MB |
| `body_tintmask.png` | 1024² (BC4 / ETC2 R) | 0.13 MB | 0.17 MB |
| `hook_basecolor.png` | 512² | 0.13 MB | 0.17 MB |
| `hook_normal.png` | 512² | 0.13 MB | 0.17 MB |
| `hook_orm.png` | 512² | 0.13 MB | 0.17 MB |
| **Total per hero (textures shared across instances)** | | **~2.05 MB** | **~2.73 MB** |

10 hero instances on screen all share the same body/hook textures (only the
`team_tint_color` instance uniform differs) — total scene texture cost stays at
**~2.7 MB**, not ~27 MB. See §11 F.4b for the enforced ≤ 8 MB budget gate and contingency
trims if a 2 MB ceiling is imposed post-O-1.

### Material Property Tables (Concept-Locked Values)

Reference values from `design/concept-art/pudge.md` material table. The texture-artist
must paint these into base color, roughness, and metallic channels:

| Surface | BaseColor (hex) | Roughness (G) | Metallic (B) |
|---|---|---|---|
| Skin (base) | `#8A8A7A` | 0.75 | 0.05 |
| Skin (shadow) | `#6B6B5E` | 0.70 | 0.08 |
| Skin (highlight) | `#9E9E8E` | 0.80 | 0.05 |
| Stitch thread | `#332519` | 0.90 | 0.00 |
| Stitch hole / wound | `#5C1A1A` | 0.85 | 0.00 |
| Teeth | `#C8B87A` | 0.80 | 0.00 |
| Eye sclera | `#F5E870` | 0.20 | 0.00 |
| Eye pupil | `#1A0A0A` | 0.90 | 0.00 |
| Belt leather | `#59330F` | 0.70 | 0.15 |
| Belt buckle | `#726E6A` | 0.35 | 0.70 |
| Boot leather | `#4A2E0A` | 0.75 | 0.10 |
| Boot sole | `#1A1510` | 0.90 | 0.00 |
| Chain (iron) | `#4A4844` | 0.45 | 0.65 |
| Hook body (iron) | `#3E3C38` | 0.40 | 0.70 |
| Hook tip / blood | `#8A1A1A` | 0.80 | 0.10 |

Skin base values are **desaturated neutral** — the tint shader applies team color on
top. **Do not bake green/red/blue into the skin base** — that would fight the tint.

### Tint Validation (Texture-Artist Verification Step)

Before finalizing the body texture, render the model with three team tint values:

- Green: `Color(0.5, 0.8, 0.2)`
- Red: `Color(0.9, 0.2, 0.2)`
- Blue: `Color(0.2, 0.4, 0.9)`

All three must produce visually coherent Pudge — same character, different team color
on skin. If any tint fights the base color or produces muddy results, the skin base is
wrong (too saturated, wrong hue) and needs repainting.

---

## 6. Pivot & Transform

The transform contract must match the Godot loader's expectations exactly. Any
mismatch produces tilted, floating, or backwards Pudge in-game. Already a known
issue today — see Section 12 (Open Questions) for the existing 180° runtime rotation
that this spec eliminates.

### World Origin and Feet Plane

- **Mesh object origin**: world (0, 0, 0) in Blender.
- **Feet plane**: the bottom of both boot soles must sit at **Y = 0 in Godot**
  (which equals **Z = 0 in Blender** before export — Blender uses Z-up).
- **Skull top (highest point)**: approximately **Y = 1.4 in Godot** (Z = 1.4 in Blender).
- **Armature root bone** (`Hips`): sits at the character's anatomical hip height,
  approximately Y = 0.30 in Godot.

#### Why pivot at floor between feet

The `HeroModelBuilder` (`src/gameplay/hero/hero_model_builder.gd:67`) instantiates
the GLB root directly as a child of the player's `CharacterBody3D` without any
position offset. The `CharacterBody3D`'s position is the floor point — the capsule
collider sits above it. Pudge's mesh origin MUST match the floor point or he will
float or sink relative to the collider.

### Forward and Up Axis (Godot World Convention)

- **Forward axis in Godot world**: **-Z** (negative Z is "facing direction")
- **Up axis in Godot world**: **+Y**
- **Right axis in Godot world**: **+X**

These are the Godot 4.6 conventions used throughout the codebase, including
`player_controller.gd` facing logic and the camera setup.

### Blender → Godot Export Orientation

Pudge is built in Blender, which uses **Z-up, +Y forward**. The GLTF exporter must
remap axes to Godot world convention:

| Blender (authoring) | GLTF export setting | Godot (runtime) |
|---|---|---|
| +X right | (passthrough) | +X right |
| +Z up | "Y Up" | +Y up |
| -Y forward (character faces -Y in Blender front view) | "-Z Forward" | -Z forward |

#### How to build correctly in Blender

The character must be authored so that **his face points along the -Y axis in
Blender** (so the front view of Blender shows Pudge's face). This is the natural
default — you look at a character from the front, that's -Y in Blender.

When exported with **"+Y Up, -Z Forward"** glTF settings (Godot 4 defaults), this
transforms to: Pudge faces -Z in Godot, exactly matching `player_controller.gd`
expectations.

#### Existing pudge.glb has a 180° rotation bug — this spec fixes it

The current shipped `src/assets/models/heroes/pudge.glb` was exported with the
character facing the **wrong direction** (+Z in Godot instead of -Z). The
`HeroModelBuilder` compensates by rotating the GLB root 180° at instantiation
(`hero_model_builder.gd:74`):

```gdscript
# GLB exports with the character facing +Z; Godot's forward is
# -Z (the convention player_controller's facing logic assumes),
# so flip 180° about Y so the model faces its movement/aim.
glb_root.rotation.y = PI
```

**This spec requires the new export to face -Z natively** so the runtime rotation
becomes unnecessary. The character-artist must build Pudge with face pointing -Y in
Blender; the blender-specialist must verify -Z forward in Godot import before
acceptance. After the new GLB lands, the `glb_root.rotation.y = PI` line must be
**removed** from `HeroModelBuilder` (Stage 10 cleanup item).

### Scale — 1 Unit = 1 Meter

- **1 Blender unit = 1 meter** (Blender's default scene scale).
- **1 Godot unit = 1 meter** (Godot default).
- **Apply scale** (Ctrl+A → Scale, or `Object > Apply > Scale`) on **every mesh
  object and the armature** before export. Non-unity scale baked into the object
  causes incorrect physics, broken Mixamo retargeting, and unreliable socket positions.

Pudge total height (chibi 3-head-tall):
- Total height: **1.40 m** (feet at Y=0, skull top at Y≈1.4)
- Head height: **0.42 m** (30% per chibi ratio — feet of head at chin level ≈ Y 0.98)
- Belly equator center: approximately **Y = 0.58** with belly radius ~0.28 m
- Boot top: approximately **Y = 0.10** under gut overhang

The character-artist may adjust ±5% on these values for visual appeal provided the
3-head-tall read is preserved and feet remain at Y = 0.

### Applied Transforms Checklist

Before export, every object in the Blender scene must satisfy:

| Object | Location | Rotation | Scale |
|---|---|---|---|
| `mesh_pudge_body_lod0` | (0, 0, 0) | (0, 0, 0) | (1, 1, 1) |
| `mesh_pudge_body_lod1` | (0, 0, 0) | (0, 0, 0) | (1, 1, 1) |
| `mesh_pudge_body_lod2` | (0, 0, 0) | (0, 0, 0) | (1, 1, 1) |
| `mesh_pudge_hook_lod0` | (0, 0, 0) | (0, 0, 0) | (1, 1, 1) |
| `mesh_pudge_hook_lod1` | (0, 0, 0) | (0, 0, 0) | (1, 1, 1) |
| `mesh_pudge_hook_lod2` | (0, 0, 0) | (0, 0, 0) | (1, 1, 1) |
| `arm_pudge` (armature) | (0, 0, 0) | (0, 0, 0) | (1, 1, 1) |
| `pudge` (scene root empty) | (0, 0, 0) | (0, 0, 0) | (1, 1, 1) |

**Verification**: the `blender-export-check` skill at `/tools/blender/` will flag
any non-unity transforms as blockers. Run it before every export.

#### What can go wrong

| Symptom in Godot | Likely cause |
|---|---|
| Pudge floats above the floor | Body mesh feet not at Z=0 in Blender — apply origin to floor center, re-export |
| Pudge sinks into floor | Same — feet are above Z=0; lower the mesh in edit mode before export |
| Pudge faces backwards (away from movement direction) | Built with face pointing +Y instead of -Y in Blender — flip in edit mode, re-export |
| Pudge is huge or tiny | Non-unity object scale baked into export. Apply Scale. |
| Pudge is tilted (head down) | Rotation not applied. Apply Rotation. |
| Hook prop misaligned with hand | Hook prop object not at (0,0,0) before export. Apply Location. |

---

## 7. Sockets / Attachment Points

Sockets are implemented as `BoneAttachment3D` nodes in Godot, parented to specific
bones in the imported skeleton. The character-artist's responsibility is to ensure
the **mesh geometry is positioned correctly relative to each bone origin** so socket
offsets stay small (ideally zero) — large offsets indicate misaligned bone placement
that animation will reveal.

### Bone Naming — Mixamo Convention

This spec uses Mixamo bone names because:

1. The existing `HeroModelBuilder` (`src/gameplay/hero/hero_model_builder.gd:25-46`)
   already references `mixamorig_*` bone names — no code change required if Pudge's
   skeleton follows the same convention.
2. Mixamo provides a free animation library (walk, run, idle, death) compatible with
   this skeleton — see Stage 9 (Animation).
3. Godot's glTF importer **sanitizes the colon** in `mixamorig:Name` to underscore at
   import. So Blender bones authored as `mixamorig:LeftHand` become `mixamorig_LeftHand`
   in the runtime skeleton. Match the sanitized form in code (already correct).

### Five Sockets

Values below are propagated verbatim from **contract §5** (rig-spec coordinates with
`mixamorig:` parent names). The earlier model-spec offsets (`(0.05, 0, 0)` along +X,
`socket_hit_center` at `(0, 0, -0.28)`) were authored against a non-standard roll
convention and are **superseded**.

| Socket name | Bone parent (sanitized) | Local Position (m) | Local Rotation (deg) | Purpose |
|---|---|---|---|---|
| `socket_hook_hand` | `mixamorig_LeftHand` | (0.00, 0.00, -0.05) | (-15, 0, 0) | Hook prop attachment point. The `mesh_pudge_hook` is parented here, weighted 100% to LeftHand. 5 cm along LeftHand's -Z (palm → fingertip grip); the -15° X tilt orients the hook tip forward-down at bind so it reads forward-outward at the raised-arm idle pose. Detached at runtime during `hook_throw`. |
| `socket_offhand` | `mixamorig_RightHand` | (0.00, 0.00, -0.04) | (0, 0, 0) | Cleaver / secondary attack prop spawn point. 4 cm along RightHand's -Z. Cleaver orientation lives in the prop's own transform. |
| `socket_chain_origin` | `mixamorig_Spine2` | (-0.08, 0.05, 0.00) | (0, 0, 0) | Chain VFX anchor when the hook is offscreen during `hook_throw`. 8 cm to character's left of Spine2, 5 cm above — the concept's visible chain exit on the upper-left chest. |
| `socket_hit_center` | `mixamorig_Spine1` | (0.00, 0.00, +0.12) | (0, 0, 0) | Damage VFX origin + hit-react impulse reference. 12 cm forward of Spine1 (toward face direction) — the belly equator's most-protruding screen-filling point at top-down camera. (The belly equator sits *below* Spine1, not 0.28 m in front of it, hence the smaller +0.12.) |
| `socket_head_top` | `mixamorig_Head` | (0.00, 0.18, 0.00) | (0, 0, 0) | Status effect icon mount (stun halo, level-up burst, CC indicator). 18 cm above Head bone origin — reaches the top of the 0.42 m skull dome. |

**Local position interpretation**: positions are in **bone local space** following
Mixamo's bone-roll convention — +Y along the bone (head → tail), +Z the bone's roll
"forward" (faces -Z world when the bone is vertical at T-pose), +X = Y × Z. This is the
same convention the rig spec uses; see contract §5.

### Per-Socket World Position at T-Pose Rest (for verification)

The character-artist verifies sockets by checking world-space positions when the
mesh is in T-pose bind. Expected values:

| Socket | World position at T-pose rest (m) | Verification region in mesh |
|---|---|---|
| `socket_hook_hand` | (+0.55, +0.95, ±0.05) | At the left palm center, slightly toward fingertip |
| `socket_offhand` | (-0.55, +0.95, ±0.04) | At the right palm center |
| `socket_chain_origin` | (-0.08, +0.78, +0.00) | Upper chest, left-of-center (concept's chain exit point) |
| `socket_hit_center` | (+0.00, +0.55, -0.12) | Forward belly equator (most protruding point) |
| `socket_head_top` | (+0.00, +1.40, +0.00) | Top of skull dome |

The rigger places the bones such that these world positions match the visual
landmarks. Once bones are placed, sockets' local offsets stay small and stable. Per
contract §5: if a socket resolves >5 cm off its visual landmark, the **bone** is
misplaced, not the socket.

### Hook Prop Behavior — Detail

`mesh_pudge_hook` is parented to `socket_hook_hand` at rest. During the
`hook_throw` animation:

1. Animation clip drives the LeftHand bone through a throwing motion (wind-up,
   release frame, recover).
2. At the **release frame** (Animation Track Event named `hook_release`), gameplay
   code in `HookSystem.gd` detaches the hook prop from the socket and spawns it as
   a `RigidBody3D` projectile in world space.
3. After the projectile mission (hit/miss/return), gameplay code re-parents the
   hook back to `socket_hook_hand` for the next throw.

The rigger must ensure `mesh_pudge_hook` has **100% weight to `mixamorig_LeftHand`**
and 0% to all other bones — otherwise the hook will deform incorrectly when detached.

### Idle Animation Pose vs Bind Pose (Silhouette B Implementation)

At T-pose bind, the left hand is at world (+0.55, +0.95, +0.05) — straight out to
the side. The concept's Silhouette B requires the hook arm to rest at **45° above
horizontal** (the "Coiled Hook Carry" pose).

This signature pose is delivered by the **idle animation clip**, not the bind pose.
In idle:

- LeftShoulder rotates ~30° upward (raising shoulder)
- LeftArm bone rotates ~15° additional (bicep flex)
- LeftHand world position at idle pose: approximately (+0.50, +1.20, +0.10) — hand
  raised, hook tip pointing forward-left
- Hook prop local rotation at idle pose: approximately (-15°, 0°, 0°) in bone local
  space — hook tip tilts slightly forward (animator detail)

This pose is **baked into the idle clip**, not the rest skeleton. The bind pose
stays clean T-pose for Mixamo retargeting cleanliness.

### Socket Implementation in Godot

The existing loader (`hero_model_builder.gd:423-446`) handles socket setup:

```gdscript
static func _setup_hero_sockets(root: Node3D, hero_id: String) -> void:
    var skeleton: Skeleton3D = _find_first_skeleton(root)
    for socket_name in HERO_SOCKETS.keys():
        var spec: Dictionary = HERO_SOCKETS[socket_name]
        # If skeleton present: BoneAttachment3D bound to spec["bone"]
        # If no skeleton: Marker3D fallback at spec["position"]
```

The `HERO_SOCKETS` const at `hero_model_builder.gd:25` must be **updated** with the
new positions above. Existing values are for the OLD 1.88 m Pudge and do not match
the new 1.4 m bind. Stage 10 work item.

### Sockets and LODs

Sockets attach to bones, not to specific mesh LODs. As LOD swaps from LOD0 → LOD1 →
LOD2, the skeleton stays the same — sockets remain attached to bones, no per-LOD
socket adjustment needed.

LOD3 (impostor billboard) is **deferred to post-MVP** (contract O-13); for MVP, LOD2
extends to infinity and the skeleton — hence all 5 sockets — remains valid at every
distance. If a LOD3 impostor is added later, sockets would not be used at that level
(effects spawn at the billboard's world position with no bone targeting).

### Future Sockets (Out of Scope This Spec)

These may be added later but are NOT part of the Stage 5 deliverable:

- `socket_foot_L` / `socket_foot_R` — for footstep VFX origin. Currently footsteps
  use the player's CharacterBody3D world position, which is good enough.
- `socket_mouth` — for "spit teeth" emote (post-MVP).
- `socket_belt_coil` — alternate chain anchor if `socket_chain_origin` proves
  visually wrong post-animation.

---

## 8. Collision

**No collision geometry on the visual Pudge mesh.** All character collision is
handled by the existing `CapsuleShape3D` on the `Player`'s `CharacterBody3D` node
(`src/main.tscn` line 50-51). The visual mesh purely renders — collision is the
gameplay layer's responsibility.

### Body Mesh — No Collision Proxy

The character-artist must NOT:

- Author any `CollisionShape3D` or trimesh collision on `mesh_pudge_body_*`
- Parent collision geometry under the GLB hierarchy
- Add `-col` / `-colonly` / `-convcol` suffix nodes (Godot import collision hints) to the body mesh
- Add physics body wrappers

The Godot importer will leave the imported `MeshInstance3D` purely visual, which
matches the loader's expectations at `hero_model_builder.gd:67-79`.

### Existing Player Collision (Reference Only — Not Part of This Spec)

Documented here so the character-artist knows the collision context:

| Property | Value |
|---|---|
| Collision shape | `CapsuleShape3D` |
| Radius | 0.40 m |
| Height | 1.60 m |
| Attached to | `Player/CollisionShape3D` (`main.tscn`) |
| Capsule pivot | matches `CharacterBody3D` origin |

The capsule is slightly **taller** than Pudge's 1.4 m mesh — this is intentional and
matches Brawl Stars-style "padded" collision for forgiving gameplay feel. Pudge's
visual silhouette ends at 1.4 m; the capsule extends to 1.6 m to give buffer for
hit detection.

### Hook Prop — Separate Collision Concern

`mesh_pudge_hook` (the attached prop) has **no collision** while attached to the
socket. The hook is purely visual on the character.

When the hook is **detached as a projectile** during `hook_throw`, the gameplay
system (`HookSystem.gd`) wraps the hook mesh in a `RigidBody3D` or `Area3D` with
its OWN collision shape — typically a small `CapsuleShape3D` or `SphereShape3D`
covering the hook's J-curve. That collision shape is gameplay state, NOT part of
the model export.

The character-artist's deliverable is just the visual mesh. The gameplay-programmer
adds projectile collision at runtime.

### LOD Collision

No LOD-specific collision. Same null collision contract applies to LOD0, LOD1,
LOD2, and the impostor billboard. Player collision capsule is constant regardless
of which mesh LOD is active.

### Why This Is Important

Authoring trimesh collision from a 6,000-tri character would add:
- 6,000-tri physics shape (expensive — Bullet/Jolt prefer convex hulls or primitives)
- Per-instance collision baking on import
- Confusing collision in editor

The capsule approach gives **predictable, performant, gameplay-feel-tunable** collision.
Trimesh-on-character is an antipattern at this scale.

---

## 9. Deformation (Rigged Asset)

The modeling-stage view of the rig. The full rigging specification (weight painting
strategy, IK chains, animation constraints) belongs to Stage 8 (`design/gdd/rigs/pudge.md`).
Here we lock the **bone count** and **deformation-critical topology** so retopo
(Stage 5) builds the right edge flow for the rig that follows.

### Skeleton — Mixamo-Compatible

**MVP bone count: 22** (20 Mixamo humanoid + BellyJiggle + Jaw), locked by **contract
§3**. BellyJiggle and Jaw are both **included** in MVP; the 4 ChainLink bones are
**deferred to post-MVP** (full count = 26 with chain). All bones use Mixamo naming
convention.

**In Blender authoring**: bones named `mixamorig:BoneName` (with colon).
**After Godot glTF import**: sanitized to `mixamorig_BoneName` (underscore).

#### Bone hierarchy (required)

```
pudge (scene root empty — not a bone)
└── arm_pudge (armature object)
    └── mixamorig:Hips                      [root bone]
        ├── mixamorig:Spine                 [lower spine]
        │   └── mixamorig:Spine1            [upper spine / belly anchor]
        │       ├── mixamorig:Spine2        [chest]
        │       │   ├── mixamorig:Neck      [compressed neck stub — see §3]
        │       │   │   └── mixamorig:Head  [skull]
        │       │   │       └── mixamorig:Jaw   [INCLUDED in MVP per contract §4.2 / Q4]
        │       │   ├── mixamorig:LeftShoulder
        │       │   │   └── mixamorig:LeftArm
        │       │   │       └── mixamorig:LeftForeArm
        │       │   │           └── mixamorig:LeftHand
        │       │   │               └── (ChainLink1-4 — POST-MVP only, see below)
        │       │   └── mixamorig:RightShoulder
        │       │       └── mixamorig:RightArm
        │       │           └── mixamorig:RightForeArm
        │       │               └── mixamorig:RightHand
        │       └── mixamorig:BellyJiggle   [REQUIRED — secondary motion]
        ├── mixamorig:LeftUpLeg
        │   └── mixamorig:LeftLeg
        │       └── mixamorig:LeftFoot
        └── mixamorig:RightUpLeg
            └── mixamorig:RightLeg
                └── mixamorig:RightFoot
```

#### Standard Mixamo bones (20 required)

| Bone | Role | Notes |
|---|---|---|
| `mixamorig:Hips` | Pelvis root | Armature root bone. Always at world (0, ~0.30, 0) in T-pose. |
| `mixamorig:Spine` | Lower spine | Connects hips to belly. |
| `mixamorig:Spine1` | Upper spine / belly anchor | **`BellyJiggle` parent.** Weight-paint origin for the gut. |
| `mixamorig:Spine2` | Chest | `socket_chain_origin` target. |
| `mixamorig:Neck` | Compressed neck stub | **Constrained to ±5° max rotation** per §3 (no-neck hunch). |
| `mixamorig:Head` | Skull | Drives head rotation. `socket_head_top` target. |
| `mixamorig:LeftShoulder` | Hook arm clavicle | Reaches into deltoid mass (positioned at ±0.30 X per Stage 2 work). |
| `mixamorig:LeftArm` | Hook arm upper | Rotates ~30° upward in idle (Silhouette B). |
| `mixamorig:LeftForeArm` | Hook arm lower | Bends during `hook_throw` wind-up. |
| `mixamorig:LeftHand` | Hook hand | `socket_hook_hand` target. Holds the hook prop. |
| `mixamorig:RightShoulder` | Cleaver arm clavicle | Reaches into right deltoid. |
| `mixamorig:RightArm` | Right upper arm | Standard motion. |
| `mixamorig:RightForeArm` | Right forearm | Drives `attack_basic` swing. |
| `mixamorig:RightHand` | Right hand | `socket_offhand` target. |
| `mixamorig:LeftUpLeg` | Left thigh | |
| `mixamorig:LeftLeg` | Left shin | |
| `mixamorig:LeftFoot` | Left foot / boot | Footstep timing reference. |
| `mixamorig:RightUpLeg` | Right thigh | |
| `mixamorig:RightLeg` | Right shin | |
| `mixamorig:RightFoot` | Right foot / boot | |

#### Custom Pudge bones

| Bone | MVP? | Parent | Role |
|---|---|---|---|
| `mixamorig:BellyJiggle` | **YES** | `mixamorig:Spine1` | Drives gut bounce in idle, walk, run, death. **Keyframed in all 10 clips by the animator** — Godot 4.6 ships no spring/jiggle SkeletonModifier3D (contract O-4), so the runtime-spring path is post-MVP. Influence painted via `jiggle_boundary` vertex color (§3, 2-color encoding). |
| `mixamorig:Jaw` | **YES** | `mixamorig:Head` | Mouth open for `death` (gape) and `victory` (laugh cadence). **Included in MVP per contract §4.2 / Q4** — non-optional; avoids a corrective `mouth_open_taunt` blendshape. |
| `mixamorig:ChainLink1` | **POST-MVP** | `mixamorig:LeftHand` | First belt-chain link — deferred (contract §3). |
| `mixamorig:ChainLink2` | **POST-MVP** | `mixamorig:ChainLink1` | Second link — deferred. |
| `mixamorig:ChainLink3` | **POST-MVP** | `mixamorig:ChainLink2` | Third link — deferred. |
| `mixamorig:ChainLink4` | **POST-MVP** | `mixamorig:ChainLink3` | Fourth link (closest to belt) — deferred. For MVP the hand→belt chain drape is **static painted geometry** on the body atlas (no sway). |

#### Total bone count summary

| Configuration | Bones | When to use |
|---|---|---|
| **Minimum** (no Jaw, no chain) | **21** (20 Mixamo + BellyJiggle) | Only if scope tightens further. Cuts Jaw. |
| **MVP** (Jaw included, no chain) | **22** | **Locked shipping target** (contract §3). Jaw enables death + victory gape; chain drape is static painted geometry. |
| **Full** (Jaw + 4 ChainLink) | **26** | Post-MVP polish. Chain sway enriches idle if profiling shows headroom. |

**Locked for MVP**: **22 bones** (20 Mixamo + BellyJiggle + Jaw) per contract §3. The 4
ChainLink bones are post-MVP. (Earlier "25 full" was a miscount — full with all 4 chain
links is 26.)

### Blendshapes / Shape Keys

**MVP target: zero blendshapes.** The chibi style and bone-driven animation cover
all required deformation. Blendshapes are added ONLY if rigging Stage 8 reveals
unfixable joint deformation.

#### Conditional blendshapes (added IF needed)

| Shape Key | Trigger condition | Driver |
|---|---|---|
| `correct_leftarm_raised` | If 4-loop left shoulder pinches at the Silhouette B 45° raise (test in Stage 8 QA pose QA1) | Driven by `mixamorig:LeftArm` Z-axis rotation, blends in 0 → 1 as arm raises 0° → 45° |
| `eye_blink_L`, `eye_blink_R` | If eye blink polish is added at Polish phase | Per-eye blink animation curve in idle clip |
| `mouth_open_taunt` | If `Jaw` bone alone is insufficient for the taunt gape | Driven by `taunt` animation clip directly |

**Decision rule for the character-artist**: do NOT speculatively author blendshapes.
Wait until the rigger flags pinching. Authoring blendshapes "just in case" adds
mesh data overhead (each shape duplicates vertex positions) for features that may
never trigger.

### Critical Edge Loop Placement

Reference §3 for loop COUNT. This section locks LOOP POSITION relative to bone joints.

**Rule**: every deformation loop must be **perpendicular to the bone's primary
rotation axis** at the joint. A loop angled relative to the rotation axis pinches
or shears on rotation.

#### Per-joint placement targets

| Joint | Bone rotation axis | Loop orientation | Placement Z (T-pose) |
|---|---|---|---|
| **Left shoulder** | Around Z (raise/lower) | Vertical loops perpendicular to bone direction | 0.92-0.98 m (4 loops span 6 cm) |
| **Right shoulder** | Around Z (limited raise) | Vertical loops | 0.92-0.98 m (3 loops) |
| **Left elbow** | Around Z (bend) | Loops perpendicular to upper-arm direction | 0.75-0.82 m (3 loops span 7 cm) |
| **Right elbow** | Around Z (bend) | Same | 0.75-0.82 m (3 loops) |
| **Wrists** | Around bone Y (twist) | Loops perpendicular to forearm | 0.60-0.65 m (2 loops) |
| **Hips** | Around X (forward/back) + Z (sway) | Loops around pelvis circumference | 0.27-0.33 m (4 loops span 6 cm) |
| **Knees** | Around X (bend) | Loops perpendicular to thigh direction | 0.12-0.18 m (3 loops) |
| **Ankles** | Around X (toe lift) | Loops at ankle pivot point | 0.05-0.10 m (2 loops) |
| **Mouth** | Around X (jaw open) | Concentric loops around mouth opening | At mouth center, expanding outward |
| **Eyes** | (cosmetic only — no bone rotation) | Concentric loops around eye center | At each eye center |

#### What "perpendicular to rotation axis" means in practice

For a typical arm bone running roughly along world-X in T-pose (Pudge's arm horizontal):
- Bone rotates around world-Z (raise/lower) and world-Y (rotation along arm length)
- Deformation loops at the joint should be **rings around world-X** — i.e. vertical
  rings circling the arm
- A loop oriented IN the world-XZ plane would NOT deform correctly — it would shear

The retopologist must visualize the bone direction and place loops as rings around it.

### Skinning Method (Stage 8 Reference)

The rigging-animator's job; included here for retopo context:

- **Method**: Voxel Heat Diffusion (Mixamo Auto-Skin) for initial pass, manual weight
  paint cleanup for shoulder + belly regions
- **Max influences per vertex**: 4 (Godot 4.6 mobile renderer limit)
- **BellyJiggle weight cap**: 80% (rigger applies cap on top of vertex color paint;
  remaining 20% goes to Spine1)
- **Hook prop**: 100% to `mixamorig:LeftHand`, 0% to all other bones (clean detach)

The retopologist's deliverable to the rigger:

- [ ] Mesh with quad-dominant topology meeting §3 loop counts
- [ ] `jiggle_boundary` vertex color layer painted per §3 specification
- [ ] T-pose bind position validated against §6 transform contract
- [ ] No skeleton present yet — rigging-animator builds the armature in Stage 8

### Bone Influence Boundaries

Critical bone-to-mesh mapping (rigger uses as starting point):

| Mesh region | Primary bone | Secondary bone | Vertex group hint |
|---|---|---|---|
| Head + face | `Head` | `Neck` (5%) | `head_only` |
| Neck stub | `Neck` | `Spine2` (50%) — bidirectional blend | (boundary loop) |
| Belly equator | `BellyJiggle` (80%) | `Spine1` (20%) | `jiggle_boundary` red region |
| Belly transitions | `BellyJiggle` (~40%, follows gradient) | `Spine1` (~60%) | `jiggle_boundary` pink-gradient region |
| Belly upper / lower seam | `Spine1` (100%) | — | `jiggle_boundary` white region |
| Hook arm shoulder | `LeftShoulder` | `LeftArm` (35%), `Spine2` (15%) | (deltoid region) |
| Hook arm bicep | `LeftArm` | `LeftShoulder` (20%), `LeftForeArm` (10%) | |
| Hook arm forearm | `LeftForeArm` | `LeftArm` (15%), `LeftHand` (10%) | |
| Hook hand | `LeftHand` | `LeftForeArm` (10%) | |
| Right arm (mirror) | mirror of left | | |
| Hips region | `Hips` | `Spine` (25%), `LeftUpLeg` (15%), `RightUpLeg` (15%) | |
| Legs | `*UpLeg` → `*Leg` → `*Foot` chain | | standard |

These are **starting weights** — the rigger refines via paint mode based on
deformation testing in Stage 8.

---

## 10. Mesh Layout / Object Hierarchy

### Decision: Two skinned meshes + scene root empty

**3 objects in the Blender scene at LOD0** (plus LOD1, LOD2 duplicates):

```
pudge                                (Empty — scene root, no mesh)
├── mesh_pudge_body_lod0             (Skinned mesh: torso, head, arms, hands, legs,
│                                     boots, belt, apron, chain links, eyes — ALL joined)
├── mesh_pudge_hook_lod0             (Skinned mesh: hook prop + 1-2 welded chain links)
└── arm_pudge                        (Armature — skeleton)
    ├── mixamorig:Hips
    └── ... (full bone tree per §9)
```

### Why one body mesh and a separate hook

| Component | Decision | Rationale |
|---|---|---|
| Body (torso/head/arms/legs/boots/belt/chain/eyes) | **Joined into single mesh** | Single draw call. Single material (`mat_pudge_body`). All share the 1024 atlas. |
| Hook prop | **Separate mesh** | Needs to be DETACHABLE during `hook_throw` (per §7). Own material (`mat_pudge_hook`) and own 512 atlas. |
| Eyes | **MERGED into body mesh** | Cost of separation: extra draw call + separate material. Cost of merging: zero. Emissive eye region painted on the body atlas's emissive map sub-region. |
| Belt chain (hand → hip drape) | **MERGED into body mesh** | Skinned to chain bones (if enabled). Shares body atlas. |
| Hook-adjacent chain (1-2 links welded to hook) | **MERGED into hook mesh** | These travel with the hook as projectile — must be part of hook mesh. |

**Total draw calls per Pudge instance**: 2 (body + hook).

### Why NOT separate eye spheres

Tempting decision avoided. Separating eyes would require:

- ❌ Third material slot → third draw call (10 heroes × 3 = 30 draw calls just for characters)
- ❌ Separate eye atlas (or compete for body atlas space)
- ❌ Extra parenting logic to keep eyes glued to face during animation

Keeping eyes merged with `mesh_pudge_body_lod0`:

- ✅ Eyes ride with the head bone (weighted to `mixamorig_Head` 100%)
- ✅ Emissive painted on the body atlas's emissive sub-region (256x256 cropped)
- ✅ 1 draw call, 1 material

Eye asymmetry (left ~15% larger) is **baked into the sculpt geometry** before joining
to body, not handled via separate objects.

### Why NOT submesh-split for masking

Some pipelines split character into "head", "body", "limbs" submeshes for mix-and-match
customization. Pudge has no customization (single hero, single look) — splitting adds
draw calls with no gameplay benefit.

### Naming Convention — Authoritative

ALL Blender object, data-block, material, and file names must follow these patterns.
Downstream tools (Godot importer, `HeroModelBuilder` loader, `blender-export-check`
script) match on these exact names. Spelling matters.

#### Blender Objects

| Object type | Blender object name | Notes |
|---|---|---|
| Scene root | `pudge` | Empty. Parent of all hierarchy. |
| Body mesh LOD0 | `mesh_pudge_body_lod0` | All body geometry joined. |
| Body mesh LOD1 | `mesh_pudge_body_lod1` | Reduced topology per §2. |
| Body mesh LOD2 | `mesh_pudge_body_lod2` | Further reduced per §2. |
| Hook mesh LOD0 | `mesh_pudge_hook_lod0` | Hook + 1-2 welded chain links. |
| Hook mesh LOD1 | `mesh_pudge_hook_lod1` | |
| Hook mesh LOD2 | `mesh_pudge_hook_lod2` | |
| Armature | `arm_pudge` | Skeleton. |
| LOD0 collection (optional) | `pudge_lod0` | If LODs grouped by collection. |
| LOD1 collection (optional) | `pudge_lod1` | |
| LOD2 collection (optional) | `pudge_lod2` | |

**LOD suffix is mandatory** for naming clarity and tooling — but **it does NOT trigger
automatic LOD switching.** Per contract O-5, Godot 4.6's `_lod*` suffix auto-detect is a
*proposal*, not implemented: Godot auto-generates LODs from a single source mesh via
meshoptimizer but does **not** group pre-authored separate meshes by suffix. The correct
Stage 10 workflow is to import each LOD as its own `MeshInstance3D`, configure
`visibility_range_begin` / `visibility_range_end` per instance at the §2 distances, and
**disable Godot's automatic LOD generation** in import settings ("Generate LODs" → false).
See §11 F.2 for the verification gate.

#### Mesh Data-Blocks

Mesh data-blocks (internal Blender mesh data) follow the same name as the object,
just with `_data` appended where they aren't auto-generated:

| Object | Mesh data-block name |
|---|---|
| `mesh_pudge_body_lod0` | `mesh_data_pudge_body_lod0` |
| `mesh_pudge_body_lod1` | `mesh_data_pudge_body_lod1` |
| `mesh_pudge_body_lod2` | `mesh_data_pudge_body_lod2` |
| `mesh_pudge_hook_lod0` | `mesh_data_pudge_hook_lod0` |
| `mesh_pudge_hook_lod1` | `mesh_data_pudge_hook_lod1` |
| `mesh_pudge_hook_lod2` | `mesh_data_pudge_hook_lod2` |
| `arm_pudge` | `arm_data_pudge` |

Rename mesh data-blocks after final Join operation in Blender. Auto-generated names
like `Mesh.001` are blockers — fail the export check.

#### Materials

| Material | Name | Atlas | Notes |
|---|---|---|---|
| Body | `mat_pudge_body` | 1024×1024 | Custom tint shader. Applied to `mesh_pudge_body_*`. |
| Hook | `mat_pudge_hook` | 512×512 | Standard PBR. Applied to `mesh_pudge_hook_*`. |

#### Textures (output for texture-artist)

Path: `src/assets/textures/heroes/pudge/` (per contract §7 / §13 — the directory provides
the hero namespace, so **filenames carry no `pudge_` prefix**). The old
`src/assets/models/heroes/textures/` path with prefixed names is superseded on both axes.

| File | Resolution | Material slot |
|---|---|---|
| `body_basecolor.png` | 1024×1024 RGB | `mat_pudge_body` albedo (pure RGB — no alpha) |
| `body_normal.png` | 1024×1024 RG | `mat_pudge_body` normal (RG, B reconstructed) |
| `body_orm.png` | 1024×1024 RGB | `mat_pudge_body` AO+roughness+metallic |
| `body_emissive.png` | 256×256 RGB | `mat_pudge_body` emissive (eyes only, cropped) |
| `body_tintmask.png` | 1024×1024 R | `mat_pudge_body` team-tint mask (single channel) — **dedicated 5th map per contract §7** |
| `hook_basecolor.png` | 512×512 RGB | `mat_pudge_hook` albedo |
| `hook_normal.png` | 512×512 RG | `mat_pudge_hook` normal |
| `hook_orm.png` | 512×512 RGB | `mat_pudge_hook` AO+roughness+metallic |
| `body_basecolor_ai_projection.png` | 1024×1024 RGB | **Reference only** — AI mesh's projected colors. NOT FINAL. Labeled clearly in handoff. |

#### Output GLB Files (Stage 10)

| File | Path | Purpose |
|---|---|---|
| Body + skeleton | `src/assets/models/heroes/pudge.glb` | Loaded by `HeroModelBuilder` as `<hero_id>.glb` |
| Hook prop | `src/assets/models/heroes/pudge_hook.glb` | Loaded by `HeroModelBuilder` as `<hero_id>_hook.glb` |

**Loader path constants** (already exist in `hero_model_builder.gd:15-16`):

```gdscript
const HERO_GLB_PATH      := "res://assets/models/heroes/%s.glb"
const HERO_HOOK_GLB_PATH := "res://assets/models/heroes/%s_hook.glb"
```

For hero_id `pudge`, these resolve to the two paths above. No code change needed
for the new exports — only ensure the file names match.

#### Working .blend File

| File | Path | Purpose |
|---|---|---|
| Working .blend | `src/assets/models/heroes/anime_pudge.blend` | Current authoring file (continue using during Stages 4-9) |
| Canonical .blend (optional) | `tools/blender/pudge.blend` | If we want a separate "clean handoff" copy with all WIP collections removed. Decision at Stage 10. |

### Collections in Blender (Organization)

The Blender .blend file should organize objects into collections for clarity:

```
Scene Collection
├── PUDGE_NEW_BUILD (current work — exports from here)
│   ├── pudge (scene root empty)
│   ├── mesh_pudge_body_lod0
│   ├── mesh_pudge_body_lod1
│   ├── mesh_pudge_body_lod2
│   ├── mesh_pudge_hook_lod0
│   ├── mesh_pudge_hook_lod1
│   ├── mesh_pudge_hook_lod2
│   └── arm_pudge
├── PUDGE_REFERENCE (hidden — bake source + props snapshots)
│   ├── textured_mesh_bake_hp (high-poly bake target)
│   ├── prop_hook_snapshot (red — Stage 2 reference)
│   └── prop_blade_snapshot (blue — Stage 2 reference)
└── PUDGE_OLD_REFERENCE (hidden — preserved historical attempts)
    └── [previous textured_mesh, OLD mesh_pudge_body_lod0, OLD arm_pudge]
```

Only `PUDGE_NEW_BUILD` is exported. The export script must filter to this collection.

### What Else NOT to Export

Confirmed excluded from final `.glb`:

- ❌ Reference markers (`REF_*` objects from Stage 2 reference rig)
- ❌ Helper armatures (`pose_helper_armature` — already deleted in Stage 2)
- ❌ Backup meshes (`pudge_v2_basemesh`, `pudge_v2_remesh` — bake source only)
- ❌ High-poly bake source (`textured_mesh_bake_hp` — Stage 7 input, not shipped)
- ❌ Snapshot props (`prop_hook_snapshot`, `prop_blade_snapshot` — Stage 2 reference)
- ❌ Cameras and lights from the Blender scene (Godot has its own)

---

## 11. Deliverables

Everything that must exist before Pudge is considered "shipped" for this spec.
This is the **acceptance checklist** for the character-artist's handoff.

### A. Working File

- [ ] `src/assets/models/heroes/anime_pudge.blend` saved with:
  - [ ] `PUDGE_NEW_BUILD` collection contains all 8 export objects (3 body LODs, 3 hook LODs, armature, scene root empty)
  - [ ] `PUDGE_REFERENCE` collection contains the high-poly bake source (`textured_mesh_bake_hp`) and snapshot props
  - [ ] `PUDGE_OLD_REFERENCE` collection contains preserved historical attempts (read-only — don't touch)
  - [ ] All blend file external dependencies packed (`File > External Data > Pack All Into Blend`)
  - [ ] File size under 200 MB

### B. Export Files (.glb)

- [ ] `src/assets/models/heroes/pudge.glb` — body + skeleton + animations
  - [ ] Contains 3 body LODs (`mesh_pudge_body_lod0`, `_lod1`, `_lod2`)
  - [ ] Contains armature (`arm_pudge`) with all 22 MVP bones (21 if Jaw cut; 26 if all 4 ChainLink added post-MVP)
  - [ ] Contains AnimationLibrary with 10 clips (see §C.4 below)
  - [ ] Forward axis = -Z in Godot (Pudge faces movement direction natively, no runtime rotation needed)
  - [ ] Feet at Y = 0
  - [ ] Total height ≈ 1.40 m
  - [ ] Scale (1, 1, 1) on all objects and bones
  - [ ] File size under 5 MB
- [ ] `src/assets/models/heroes/pudge_hook.glb` — detachable hook prop
  - [ ] Contains 3 hook LODs (`mesh_pudge_hook_lod0`, `_lod1`, `_lod2`)
  - [ ] 100% weighted to `mixamorig:LeftHand` bone (in skeleton inherited from body GLB)
  - [ ] File size under 1 MB

### C. Texture Files

Path: `src/assets/textures/heroes/pudge/` (no `pudge_` filename prefix — per contract §7)

#### C.1 Final body atlas (1024 × 1024)

- [ ] `body_basecolor.png` (RGB — pure hand-painted base, no alpha)
- [ ] `body_normal.png` (RG — tangent-space normal, baked from `textured_mesh_bake_hp`)
- [ ] `body_orm.png` (RGB — R=AO baked in combined-scene, G=Roughness, B=Metallic)
- [ ] `body_tintmask.png` (single-channel R — dedicated team-tint mask per contract §7; 1.0 on skin, 0.0 elsewhere)

#### C.2 Final eye emissive (256 × 256, cropped)

- [ ] `body_emissive.png` (RGB — black except eye sclera region per concept material table)

#### C.3 Final hook atlas (512 × 512)

- [ ] `hook_basecolor.png` (RGB)
- [ ] `hook_normal.png` (RG)
- [ ] `hook_orm.png` (RGB — combined-scene AO bake)

#### C.4 Reference (NOT FINAL)

- [ ] `body_basecolor_ai_projection.png` (RGB) — AI-mesh projected color, labeled in handoff notes as "REFERENCE ONLY — DO NOT SHIP"

#### C.5 Texture validation

- [ ] Each PNG passes UV-checker visualization (no stretched / missing islands)
- [ ] Body atlas passes 3-tint validation (green/red/blue produces coherent Pudge — §5), driven through `body_tintmask.png` + the rewritten mask-based shader
- [ ] Normal maps verified in Godot at LOD0 distance — no obvious cage leaks at belly, shoulder, eye socket
- [ ] Emissive map painted only on eye sclera (not pupil, not surrounding skin)

### D. Animation Library (Stage 9 output — listed here for completeness)

Required clips in the `pudge.glb` AnimationLibrary, named exactly:

- [ ] `idle` — Silhouette B raised-hook-arm rest pose, belly jiggle, subtle breathing
- [ ] `walk` — chibi waddle, ~1.4 m/s reference speed
- [ ] `run` — faster waddle with more belly bounce, ~3.5 m/s
- [ ] `turn_in_place` — root-stationary rotation
- [ ] `hook_throw` — wind-up + release frame with `hook_release` animation event marker
- [ ] `hook_recover` — return-to-idle blend
- [ ] `attack_basic` — cleaver swing with right arm
- [ ] `hit_react` — flinch + recoil
- [ ] `death` — fall backward with gut deflate (last)
- [ ] `victory` — pose with raised hook + grunt

These clip names match `HeroModelBuilder` expectations and the AnimationTree state
machine (Stage 10).

### E. Vertex Color Layers

Layer name: `jiggle_boundary` (exact string). **Encoding per contract §6 — 2-color (red/white) with linear gradient between, NOT the 3-color (red/yellow/white) form authored previously.**

- [ ] Layer present on `mesh_pudge_body_lod0`
- [ ] Layer present on `mesh_pudge_body_lod1`
- [ ] Layer present on `mesh_pudge_body_lod2` (re-painted post-decimate per §3)
- [ ] Color domain = Vertex
- [ ] Data type = Byte Color or Float Color
- [ ] Red (R=1, G=0, B=0) on belly equator and forward-lower ring
- [ ] White (R=1, G=1, B=1) on torso-join and hip-join rings
- [ ] Transition rings show pink gradient (linear interpolation between red and white), produced by Blender's vertex paint gradient/smear tool — NOT a discrete yellow band

### F. Validation Passes (Gates)

The asset cannot be marked complete until each of these gates passes:

#### F.1 Blender export check (`tools/blender/validate_export.py`)

- [ ] `--asset pudge` → PASS status (no failures, warnings reviewed)
- [ ] All 8 expected export objects present in `PUDGE_NEW_BUILD` collection (spec §10 + script-enforced)
- [ ] All transforms applied (scale 1, location 0, rotation 0)
- [ ] No unapplied modifiers on export objects
- [ ] LOD0 body within 6,000 tri ceiling, hook within 600 tri budget
- [ ] LOD1 within 3,000 / 300 budgets, LOD2 within 1,500 / 150
- [ ] `jiggle_boundary` vertex color layer present on all 3 body LODs (contract §6 + script-enforced)
- [ ] Armature bone count within 21-26, MVP target 22 (contract §3 + script-enforced)

#### F.1b Hook weighting check (`tools/blender/verify_hook_weights.py`)

- [ ] `--asset pudge` → PASS status
- [ ] Hook mesh weights 100% to `mixamorig:LeftHand` (or sanitized `mixamorig_LeftHand`); 0% on all other vertex groups

#### F.2 Godot import sanity

- [ ] `pudge.glb` imports with no ERROR rows in Godot Output panel. Warnings reviewed against the approved-warnings list at `production/qa/godot-acceptable-warnings.md` — **this file already exists as a versioned stub** (bootstrapped 2026-06-18, initially empty); the reviewer adds each observed warning type to it with a justification, and any warning type *not* on the list blocks the gate until technical-artist signs off on adding it. (No circular dependency: the list pre-exists; F.2 populates it, it is not created by F.2.)
- [ ] `pudge_hook.glb` imports with same warning-review standard as above
- [ ] Skeleton bones present and named `mixamorig_*` (sanitized from `mixamorig:` per contract §3)
- [ ] **Per contract O-5**: LOD auto-detection by `_lod*` suffix does NOT work in Godot 4.6 for pre-authored LODs. Verify each LOD `MeshInstance3D` has correct `visibility_range_begin` and `visibility_range_end` configured manually per the Stage 10 import setup. Orbit the editor camera and confirm LOD swap happens at the spec §2 distances

#### F.3 In-game runtime test

- [ ] Loaded by `HeroModelBuilder` without warnings (no `push_warning` or `push_error` calls during `build_model`)
- [ ] Pudge faces movement direction at runtime (no 180° flip needed; `hero_model_builder.gd:74` `glb_root.rotation.y = PI` line removed per contract §2 + §12)
- [ ] All 5 sockets resolve to `BoneAttachment3D` (not Marker3D fallback) — check via `print(socket.get_class())` in a smoke test, must print `BoneAttachment3D` for all 5 socket names from contract §5
- [ ] Hook prop attached to `socket_hook_hand` at runtime (hook mesh parented to the socket node in the scene tree)
- [ ] Team tint shader applies correctly: render the same Pudge instance 3 times with `hero_color` = `Color(0.5, 0.8, 0.2)` (green), `Color(0.9, 0.2, 0.2)` (red), `Color(0.2, 0.4, 0.9)` (blue). All three produce visually coherent Pudge with the skin tinted to the team color and non-skin surfaces (eyes, belt, boots, hook) unchanged. Screenshots saved to `production/qa/evidence/pudge-tint-{green,red,blue}.png`
- [ ] **Silhouette readability (objective measurement)**: In the Godot editor scene view at game-cam distance (5-8 m, top-down 30° pitch), the hook prop tip extends outside the body silhouette bounding box by at least 20% of character height (≥0.28 m for the 1.40 m Pudge). This is a **world-space** measurement (DPI-independent): read the hook mesh's AABB extents vs the body mesh AABB via the editor selection gizmo. Screenshot saved to `production/qa/evidence/pudge-silhouette-game-cam.png`.
- [ ] **Face readability at menu cam (objective measurement)**: Capture **at a pinned 1920×1080 viewport with HiDPI/display-scaling disabled** (set window override to 1920×1080, `display/window/dpi/allow_hidpi=false` for the capture) so pixel counts are reproducible across displays. At menu cam distance (1.5-2 m, eye-level), screenshot `production/qa/evidence/pudge-face-menu-cam.png` must show: (a) asymmetric eyes — the larger left eye sclera diameter is ≥15% greater than the right (measure in captured pixels); (b) each pupil readable as a distinct dark spot (≥3 px wide); (c) stitch lines resolve as ≥2 px wide painted dark seams across the belly front. Pixel thresholds are valid **only** at the pinned 1920×1080 capture; re-derive proportionally if the capture resolution changes.

#### F.4 Performance baseline

The performance gate is split because the asset under test differs by stage. **F.4a uses
whatever build currently exists (prototype primitives) and is informational only; F.4b is
the binding acceptance gate and requires the Stage 10 final spec-compliant `pudge.glb` on
the named target device.** Do not pass F.4b against the prototype build.

##### F.4a — Dev-machine smoke (informational, any build)

- [ ] **Stress scene** at `src/scenes/perf/pudge_stress_test.tscn` — 10 instances at LOD0, no terrain, no VFX, all in camera frustum, shadows OFF, vsync OFF. Apparatus + workflow at `tests/performance/README.md`.
- [ ] Run on the dev machine with the **current** build and record p95 in the `tests/performance/README.md` history table, **explicitly labeling which build was measured** (e.g. "prototype primitives" vs "Stage 10 GLB"). This is a regression tripwire, **not** an acceptance gate — a dev-machine pass does not satisfy F.4b.

##### F.4b — Target-device acceptance (binding, Stage 10 final GLB only)

- [ ] The stress scene must reference the **Stage 10 final, spec-compliant `pudge.glb`** (single skinned body mesh + hook, real atlases, 22-bone skeleton) — **not** the prototype primitives build. Confirm the asset under test is the shipped GLB before recording a verdict.
- [ ] **Target-device p95** ≤ 16 ms (60 FPS budget). Device named in contract O-1 (deferred until tech-director + producer decide; gate cannot pass until O-1 names the device). FAIL = p95 > 16 ms → spec renegotiation: drop body atlas to 512, drop LOD0 ceiling to 4,500 tris, or both. Result recorded in the `tests/performance/README.md` baseline history table per the Step 6 measurement framework.
- [ ] **Texture memory budget**: total scene texture cost ≤ 8 MB (with mips, ETC2 RGBA). One Pudge's shared atlases measure **~2.05 MB (~2.73 MB with mips)** per contract §7 — comfortably inside 8 MB. The previous "≤ 2 MB" criterion was authored before ETC2 RGBA's actual ~1 MB/1024² per-map cost was verified (contract O-7); 8 MB is the realistic ceiling. If a hard 2 MB cap is imposed (e.g. low-end Android), apply contingency trims from materials spec §12 (drop tintmask to 512², drop body normal to 512²) and re-measure.
- [ ] **Draw call count** = 20 (2 per instance × 10 = 20 mesh draw calls for characters)

### G. Handoff Documentation

- [ ] This spec (`design/gdd/models/pudge.md`) marked COMPLETE (not DRAFT)
- [ ] Rig spec (`design/gdd/rigs/pudge.md`) created and matches this model spec — Stage 8 deliverable
- [ ] Animation list (`design/gdd/animations/pudge.md`) created — Stage 9 deliverable
- [ ] Handoff notes file (`production/handoffs/pudge-character-art-to-tech-art.md`) documenting:
  - Known issues / deferred items
  - Where to find each deliverable
  - Validation log proving each gate passed
  - Anything the next consumer needs to know that's NOT in the spec

### H. Cleanup / Archive

- [ ] Old `pudge.glb` (placeholder primitive version) archived as `_archive/pudge-primitives-2026-05.glb`
- [ ] Old `mesh_pudge_body_lod0` (with stale Retopo_Shrinkwrap modifier) removed from `PUDGE_OLD_REFERENCE`
- [ ] Existing `Untitled.blend` files in `src/assets/models/heroes/` cleaned up or moved to `_archive/`
- [ ] `Cube` (default cube from initial scene) deleted from `PUDGE_OLD_REFERENCE` collection
- [ ] `HeroModelBuilder.HERO_SOCKETS` constant updated with §7 positions (per contract §5)
- [ ] `HeroModelBuilder.build_model` line `glb_root.rotation.y = PI` REMOVED (no longer needed when GLB faces -Z natively per contract §2)
- [ ] `HeroModelBuilder._apply_hero_tint` (`hero_model_builder.gd:401-412`) switched from `set_shader_parameter` (per-material) to `set_instance_shader_parameter("team_tint_color", color)` (per-instance) — per §5 and contract O-6. Using the per-material call against the rewritten mask shader would either tint all instances identically or force a unique material per instance (≈10× VRAM). Tracked as a separate code task (see handoff notes).
- [ ] All §12 open questions either marked RESOLVED with decision text in this spec, OR migrated to `design/gdd/contracts/pudge-interface-contract.md` §11 with owner + deadline + status (DEFERRED / PARTIAL / RESOLVED acceptable; OPEN / NEW require resolution before F-gate runs)

### Acceptance Criteria

Pudge is "shipped per this spec" only when:

1. ✅ All A-H sections checked complete
2. ✅ F.1, F.1b, F.2, F.3 gate runs all PASS; **F.4a** recorded (informational); **F.4b** PASS once contract O-1 names the target device (until then F.4b is blocked-on-O-1, not failed)
3. ✅ Spec status changed to "APPROVED — production ready"
4. ✅ Sign-off recorded in handoff notes by character-artist and accepted by technical-artist

If any gate fails, the asset returns to character-artist with specific failure
notes. No partial acceptance — Pudge is either shipped per spec or not.

---

## 12. Open Questions

Questions captured during spec authoring that need resolution before or during
specific downstream stages. Each question has an owner (the agent responsible for
resolving it) and a deadline (which stage can't start until it's resolved).

### For character-artist (Stage 4-5)

#### Q12.1 — Delete OLD scaffolding NOW or at start of Stage 5?

The `PUDGE_OLD_REFERENCE` collection contains the previous attempt's
`mesh_pudge_body_lod0` (with stale `Retopo_Shrinkwrap` modifier) and the OLD
`arm_pudge` Mixamo-rigged armature. These were preserved during Stage 2 in case
we needed reference, but they're now confirmed obsolete.

- **Option A**: Delete now — cleaner scene, smaller .blend file size
- **Option B**: Defer to start of Stage 5 retopo — slightly less risk of accidentally needing them

**Recommendation**: B. Carry them through Stage 4 sculpt cleanup as visual reference
for "what NOT to do this time." Delete when Stage 5 retopo begins.

#### Q12.2 — Apron stub: yes or no?

Concept Silhouette B approved "small bloodied stub tucked under belt." Brief did
not specify. This spec assumes YES (80 tris allocated). Reconfirm with art-director
at Stage 4 if visual reference shows the apron breaks the silhouette read.

#### Q12.3 — Boot toe splay sculpt detail

Concept calls for "boots slightly too small, toes pressing against front." At
LOD0 budget this is sculpt detail (~20-30 tris). Confirm sculptor delivers this
or it's purely a painted detail.

### For texture-artist (Stage 7)

#### Q12.4 — Tint shader: rewrite to mask-based or extend existing hue-based? — ✅ RESOLVED

**RESOLVED (contract §7): Option A — rewrite to mask-based**, with the tint mask
delivered as a **dedicated `body_tintmask.png`** single-channel map (NOT BaseColor alpha,
which earlier drafts assumed). The shared `hero_body_tint.gdshader` is rewritten to sample
`tint_mask_texture`; `team_tint_color` is a per-instance `instance uniform` set via
`set_instance_shader_parameter` (samplers stay per-material — contract O-6). Consequence
tracked in contract O-8: every existing hero (Vex/Lash/Maw) needs a `body_tintmask.png`,
or scope the rewrite to Pudge only. Shader-rewrite owner: `godot-shader-specialist`;
cross-hero tintmask owner: `texture-artist`.

#### Q12.5 — Eye emissive: separate 256² texture or pack into ORM alpha?

§5 specifies a separate 256x256 emissive texture. Alternative is packing emissive
intensity into the alpha channel of the ORM texture (no separate file). The
separate texture is simpler to author; the packed approach saves 16 KB at runtime.

**Recommendation**: separate texture. The 16 KB savings is negligible vs the
authoring complexity of pack-and-unpack.

#### Q12.6 — Apron blood density at 256 px/m

The apron stub UV island will be small (probably 32-48 px square in the atlas).
Confirm blood spatter is legible at this size before painting. If not, increase
density on the apron specifically OR accept blood is a painted hint, not detailed.

#### Q12.7 — Stitch geometry vs painted stitches

§3 currently treats stitches as painted detail at 256 px/m on torso front. If
the texture-artist finds 256 px/m insufficient at game cam distance, flag before
final unwrap — we may need to either bump face density or add stitch decal geometry
(adds tris to the LOD0 budget).

### For rigging-animator (Stage 8)

#### Q12.8 — BellyJiggle bone: spring or keyframe? — ✅ RESOLVED

**RESOLVED (contract O-4): keyframe in all 10 clips for MVP.** Godot 4.6 ships **no**
spring/jiggle SkeletonModifier3D — the available modifiers are CCDIK, FABRIK, Jacobian
IK, Spline IK, TwoBoneIK plus 4.5's BoneConstraint3D set, none physics-driven. The
animator hand-keyframes the belly bounce per clip (~20% extra animation time). A custom
GDScript `SkeletonModifier3D` spring (~50 lines) is post-MVP polish if profiling shows
keyframe drift across clip blends. Owner: `rigging-animator`.

#### Q12.9 — Chain bone count: include in MVP or post-MVP? — ✅ RESOLVED

**RESOLVED (contract §3): exclude — post-MVP.** MVP skeleton stays at **22 bones**; the
hand→belt chain drape is **static painted geometry** on the body atlas (no sway). The 4
`ChainLink1-4` bones (full = 26) are added post-launch if profiling shows headroom. Owner:
`rigging-animator`.

#### Q12.10 — Jaw bone: required for MVP or cut with taunt? — ✅ RESOLVED

**RESOLVED (contract §4.2 / Q4): Jaw is INCLUDED in MVP** (non-optional). It drives the
`death` gape and `victory` laugh cadence and avoids a corrective `mouth_open_taunt`
blendshape. Cost: 1 bone, zero animation overhead on the 8 clips that ignore it. Owner:
`game-designer` (decision made).

#### Q12.11 — Hook prop weight constraint verification

Hook must be 100% weighted to `mixamorig:LeftHand`. The rigger must verify this
manually — if Mixamo auto-skin assigns any other bone influence to the hook geometry,
the hook will deform incorrectly when detached as projectile.

**Stage 8 pre-export check** — automated check would be great here, but a manual
"select hook verts, inspect vertex group weights" verification is sufficient.

#### Q12.12 — Left shoulder 4-loop deformation test (corrective blendshape)

The 4-loop left shoulder must hold cleanly at the Silhouette B 45° raise. The rigger
tests this in Stage 8 by posing LeftArm to the idle position and inspecting for
pinching.

- If clean: no action needed
- If pinching: rigger flags to character-artist to author `correct_leftarm_raised`
  blendshape (§9)

### For blender-specialist (Stage 10)

#### Q12.13 — Export orientation: built right the first time? — ✅ RESOLVED (Stage 4 entry, 2026-06-18)

**✅ RESOLVED — PASS (contract O-2 / §9).** Verified at Stage 4 entry via Blender MCP:
`pudge_v2_remesh` in Front Orthographic shows the **face** (back view shows no face), so
the mesh already faces **-Y in Blender** → exports to **-Z in Godot** natively, no 180°
fix needed. Transforms confirmed clean at the same check (loc 0, rot 0, scale 1; feet ≈
Z0, height ≈ 1.4 m). Catching this before sculpt detail bakes in eliminates the
cascading 180°-flip-on-loader bug; the `glb_root.rotation.y = PI` hack is removed at
Stage 10 per contract §2.

#### Q12.14 — LOD object naming for Godot's auto-detect — ✅ RESOLVED

**RESOLVED (contract O-5): auto-detect by `_lod*` suffix does NOT work in Godot 4.6 for
pre-authored LODs.** It is a proposal, not implemented — Godot auto-generates LODs from a
single source mesh via meshoptimizer but does not group separate suffixed meshes. The
`_lod*` suffix is kept for naming clarity only. Correct workflow (Stage 10): import each
LOD as its own `MeshInstance3D`, set `visibility_range_begin` / `visibility_range_end` per
instance at the §2 distances, and **disable** "Generate LODs" in import settings. Owner:
`blender-specialist` (export) + `technical-artist` (import setup).

#### Q12.15 — Working .blend file location

Current authoring file: `src/assets/models/heroes/anime_pudge.blend`. Spec §10
mentions an optional canonical handoff copy at `tools/blender/pudge.blend`. Do we
need that second copy, or is the source .blend sufficient as both authoring AND
handoff artifact?

**Recommendation**: keep one .blend (in `src/`). Simpler.

### For gameplay-programmer (Stage 10)

#### Q12.16 — Update HERO_SOCKETS constant

`hero_model_builder.gd:25-46` has socket positions hardcoded for the OLD 1.88 m
Pudge. New values from §7 must replace them when the new GLB is ready. This is a
single-edit code change but easy to forget.

#### Q12.17 — Delete glb_root.rotation.y = PI hack

`hero_model_builder.gd:74` rotates the loaded GLB 180° to compensate for the
existing pudge.glb's wrong-direction export. When the new pudge.glb ships
correctly facing -Z, this line MUST be deleted — otherwise the new Pudge faces
backwards.

This is the highest-risk code change. Easy to forget. Flag it in handoff notes.

### For game-designer / producer (strategic)

#### Q12.18 — Update `design/gdd/hero-system.md` to include Pudge as 4th hero — 🔶 PARTIAL

**PARTIAL (contract O-9, Step 9 2026-05-31).** Pudge is added to `hero-system.md` as the
4th hero (Tank/disruptor, `hook_type=PULL`, fantasy + skill profile written). **Stat
values still TBD** — `src/data/heroes/pudge.tres` carries debug placeholders
(`hook_damage=99999`, `xp_on_hook_hit=0`); a real balance pass remains a `game-designer`
task before Stage 10. Side-finding: `coil.tres` (CHARGE) and `flux.tres` (BEAM) exist but
are undocumented — logged as a new open question in `hero-system.md`. **Owner**:
game-designer. **Deadline**: Stage 10.

#### Q12.19 — Concept doc title update

`design/concept-art/pudge.md` was authored for "Vex's visual identity" (or some
historical context where the hero_id and visual identity were intertwined).
Now that Pudge is a separate hero, the concept doc should be reviewed for stale
references. Owner: narrative-director / concept-artist.

#### Q12.20 — Performance target device — ⏸ DEFERRED (contract O-1)

**DEFERRED (contract O-1, owners: `technical-director` + `producer`, deadline: before
Stage 7).** Target tier is not yet named. Provisional assumptions until it lands: Samsung
Galaxy A54 / iPhone 12 tier, 16 ms (60 FPS) budget, ETC2 RGBA compression, 6,000-tri LOD0
ceiling. This gates the F.4b performance gate (cannot pass until the device is named), the
mobile compression format (ETC2 vs ASTC 6×6, contract O-7), and LOD-switch tuning. If
decision slips past Stage 7, textures author in ETC2 by default and re-import later if
ASTC is chosen.

### For QA (Stage 8+)

#### Q12.21 — Acceptance test poses

Stage 8 rigger should test these specific poses before signing off:

- **QA1**: LeftArm raised 45° (Silhouette B idle) — check for shoulder pinch
- **QA2**: RightArm raised 90° (attack swing) — check for shoulder pinch
- **QA3**: Hips rotated 60° (death sway) — check belly + hip deformation
- **QA4**: Head rotated 30° (looking around) — check no-neck hunch holds
- **QA5**: Jaw open 25° (taunt/death) — check mouth loop deformation

Each pose passes when geometry holds without pinching, no Z-fighting, no inverted
faces.

### For art-director (project-wide)

#### Q12.22 — Tint range validation for chibi style

The mask-based tint shader (§5) needs to support the full team color range. With
8 possible team colors (assume Brawl Stars 5v5 has 2-3 team colors max per match,
total roster ~6-8), all must produce coherent Pudge.

**Provide the full team color list** to texture-artist before painting begins.
Currently only "green/red/blue" mentioned as examples — what's the actual roster?

#### Q12.23 — Pudge variation skins (post-MVP scope)

Will Pudge have skins (alternate colors / outfits) post-MVP? If yes, this affects
UV layout (need skin-swap-friendly islands), material design (alternate textures),
and storage. If no, current single-skin design is sufficient.

### Decision Status Table

Open questions roll up here for at-a-glance status:

Statuses below reflect the 2026-06-18 contract-propagation pass. Items resolved at the
contract level link to their contract ID; items still open carry an owner + deadline.

| ID | Question | Owner | Deadline | Status |
|---|---|---|---|---|
| Q12.1 | Delete OLD scaffolding now | character-artist | Start of Stage 5 | Recommendation: defer to Stage 5 |
| Q12.2 | Apron stub yes/no | art-director | Stage 4 | Recommendation: yes |
| Q12.4 | Tint shader rewrite | godot-shader-specialist + texture-artist | Stage 7 | ✅ RESOLVED — mask-based, dedicated `body_tintmask.png` (contract §7 / O-8) |
| Q12.5 | Eye emissive separate vs packed | texture-artist | Stage 7 | Recommendation: separate |
| Q12.8 | BellyJiggle spring vs keyframe | rigging-animator | Stage 8 | ✅ RESOLVED — keyframe in all clips (contract O-4) |
| Q12.9 | Chain bones in MVP | rigging-animator | Stage 8 | ✅ RESOLVED — exclude, post-MVP (contract §3) |
| Q12.10 | Jaw bone in MVP | game-designer | Stage 8 | ✅ RESOLVED — included in MVP (contract §4.2 / Q4) |
| Q12.13 | Mesh orientation verified | blender-specialist | Stage 4 entry | ✅ RESOLVED 2026-06-18 — PASS, faces -Y, no fix (contract O-2) |
| Q12.14 | LOD auto-detect works | blender-specialist | Stage 10 | ✅ RESOLVED — does NOT work; manual `visibility_range` (contract O-5) |
| Q12.18 | Update hero-system.md | game-designer | Stage 10 | 🔶 PARTIAL — roster updated, stat balance TBD (contract O-9) |
| Q12.20 | Mid-tier device target | technical-director + producer | Stage 7 | ⏸ DEFERRED (contract O-1) |

---

*End of Pudge Model Spec — Stage 3.*
*Sections 1-12 authored 2026-05-30; contract-propagation pass 2026-06-18 (body text aligned to `design/gdd/contracts/pudge-interface-contract.md`).*
*Next: re-run `/design-review design/gdd/models/pudge.md` → target APPROVED, then begin Stage 4 (sculpt cleanup).*
