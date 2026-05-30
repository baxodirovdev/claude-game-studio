# Model Spec — Pudge

> **Status**: ⚠️ **MAJOR REVISION NEEDED** — /design-review 2026-05-30 surfaced 27 BLOCKING items across 6 specialist reviews. **Do NOT proceed to Stage 4 until revisions complete.** See `design/gdd/reviews/pudge-model-review-log.md` for full review record and `production/session-state/active.md` for resume instructions.
> **Hero ID**: `pudge` (separate 4th hero — not in current Vex/Lash/Maw roster; hero-system.md needs updating later)
> **Stage**: 3 of 10 (Model Specification)
> **Date**: 2026-05-30
> **Brief**: `design/characters/pudge-character-brief.md`
> **Concept**: `design/concept-art/pudge.md` — Silhouette B (Coiled Hook Carry) APPROVED 2026-04-28
> **Predecessor spec**: archived to `design/gdd/models/_archive/pudge.md.2026-04-28` (superseded by fresh Stage 3 authoring this session)
> **Engine**: Godot 4.6
> **Conflicts with**: `design/gdd/rigs/pudge.md` and `design/gdd/materials/pudge.md` — cross-doc reconciliation required before any specialist begins implementation

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
    +-- Ring 6 (top, transitioning to torso/chest)        ← 0% jiggle
    +-- Ring 5                                            ← 0% jiggle (transition)
    +-- Ring 4                                            ← 50% jiggle (gradient)
    +-- Ring 3 (EQUATOR — maximum circumference)          ← 100% jiggle
    +-- Ring 2                                            ← 100% jiggle (forward-lower)
    +-- Ring 1 (bottom, transitioning to hip mass)        ← 0% jiggle
    +-- pole cap (hidden inside torso overlap)
```

- **6 horizontal rings** total
- **8 vertical columns** (8-sided radial topology)
- **96 quads total** on the gut dome = 192 tris (matches budget §2)

**BellyJiggle influence falloff** (painted as `jiggle_boundary` vertex color layer):

- **Red (RGB 1, 0, 0) = 100%**: equator ring (Ring 3) + forward-lower ring (Ring 2)
- **Yellow (RGB 1, 1, 0) ≈ 50%**: transition rings (Ring 4 above, Ring 1 below)
- **White (RGB 1, 1, 1) = 0%**: top rings (5, 6) joining torso + lowest ring joining hip

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

Two materials, two draw calls, four textures per material. Mobile PBR pipeline with
**ORM channel packing** (R=AO, G=Roughness, B=Metallic) — industry-standard for mobile
to halve texture sample count.

### Material List

| Material | Mesh | Atlas | Shader | Tintable? |
|---|---|---|---|---|
| `mat_pudge_body` | `mesh_pudge_body_lod*` | 1024 × 1024 | `hero_body_tint.gdshader` (custom) | **Yes** — team tint via mask channel |
| `mat_pudge_hook` | `mesh_pudge_hook_lod*` | 512 × 512 | Godot StandardMaterial3D | **No** — neutral iron, no team tint |

**Draw call budget**: 2 per Pudge instance. With 10 heroes on screen, total mesh draw
calls = 20 (10 bodies + 10 hooks). Comfortable for mobile renderer.

### Channel Packing — Body Material

| Texture | Resolution | Channels | Content |
|---|---|---|---|
| `pudge_body_basecolor.png` | 1024 × 1024 | RGB + A | RGB = hand-painted base color (un-tinted). **A = tint mask** (1.0 = full tint, 0.0 = no tint, smooth gradient permitted at boundaries). |
| `pudge_body_normal.png` | 1024 × 1024 | RG (B reconstructed) | Tangent-space normal map baked from high-poly. B channel reconstructed at runtime via `sqrt(1 - R² - G²)` to save 1/3 texture size. |
| `pudge_body_orm.png` | 1024 × 1024 | RGB | **R = AO** (baked combined scene), **G = Roughness**, **B = Metallic** |
| `pudge_body_emissive.png` | 256 × 256 | RGB | Sparse texture — eyes only. Cropped to the eye UV sub-island to save memory. Black elsewhere. |

**Why a separate small emissive texture**: the emissive region is ~3% of the body atlas
(eyes only). Allocating a full 1024 emissive map would waste ~1 MB for one tiny feature.
A cropped 256 × 256 holding just the eye island region drops emissive cost to ~64 KB.

**Tint mask painting guide** (alpha channel of `pudge_body_basecolor.png`):

| Surface | Alpha value | Tints to team color? |
|---|---|---|
| Skin (face, body, arms, legs) | 1.0 | Yes — primary identity |
| Leather (belt, boots) | 0.0 | No — natural brown |
| Iron (belt buckle, chain links) | 0.0 | No — neutral metal |
| Stitches | 0.0 | No — black thread |
| Eyes (sclera + pupil) | 0.0 | No — yellow + black |
| Teeth | 0.0 | No — yellowed off-white |
| Mouth interior | 0.0 | No — dark red |
| Apron stub | 0.0 | No — bloodied off-white |
| Blood splatter | 0.0 | No — red |

Texture-artist paints the alpha as 1.0 on all skin regions, 0.0 everywhere else.
Smooth transition (1-2 px ramp) at skin/cloth boundaries to avoid hard tint edges.

### Channel Packing — Hook Material

| Texture | Resolution | Channels | Content |
|---|---|---|---|
| `pudge_hook_basecolor.png` | 512 × 512 | RGB | Hand-painted iron base color + blood spatter on inner curve/tip. No alpha. |
| `pudge_hook_normal.png` | 512 × 512 | RG (B reconstructed) | Tangent-space normal from fresh high-poly bevel pass (NOT from AI mesh). |
| `pudge_hook_orm.png` | 512 × 512 | RGB | R = AO (combined scene bake), G = Roughness, B = Metallic |

No emissive on hook prop. No tint mask (hook is always iron-grey).

### Shader Target — Body

Use the existing `res://assets/shaders/hero_body_tint.gdshader` (already integrated in
`HeroModelBuilder._apply_hero_tint()`). This spec extends it to use the **mask-based
tint** approach instead of the current hue-band detection method.

#### Shader inputs (uniforms)

| Uniform | Type | Source | Default |
|---|---|---|---|
| `tint_color` | vec3 | Per-instance from `HeroConfig.hero_color` | white |
| `tint_strength` | float | Constant or per-team modifier | 1.0 |
| `albedo_texture` | sampler2D | `pudge_body_basecolor.png` | — |
| `normal_texture` | sampler2D | `pudge_body_normal.png` | — |
| `orm_texture` | sampler2D | `pudge_body_orm.png` | — |
| `emissive_texture` | sampler2D | `pudge_body_emissive.png` (256 × 256) | — |
| `emissive_color` | vec3 | Material constant per concept | `(1.0, 0.7, 0.0)` |
| `emissive_energy` | float | Material constant | 3.0 |

#### Shader logic (per-fragment, pseudocode)

```glsl
vec4 albedo_sample = texture(albedo_texture, UV);
vec3 base_rgb = albedo_sample.rgb;
float tint_mask = albedo_sample.a;

// Mix between base color and tinted color by mask
vec3 final_albedo = mix(base_rgb, base_rgb * tint_color, tint_mask * tint_strength);

vec3 normal_ts = decode_normal_rg(texture(normal_texture, UV).rg);

vec3 orm = texture(orm_texture, UV).rgb;
float ao = orm.r;
float roughness = orm.g;
float metallic = orm.b;

vec3 emissive_sample = texture(emissive_texture, eye_subuv).rgb;
vec3 final_emissive = emissive_sample * emissive_color * emissive_energy;

ALBEDO = final_albedo;
NORMAL_MAP = normal_ts;
AO = ao;
ROUGHNESS = roughness;
METALLIC = metallic;
EMISSION = final_emissive;
```

### Shader Target — Hook

Standard Godot `StandardMaterial3D` with:
- Albedo texture: `pudge_hook_basecolor.png`
- Normal texture: `pudge_hook_normal.png` (set normal map flag)
- ORM texture: routed to AO, Roughness, Metallic via Godot's built-in ORM import
- No emissive, no tint, no custom shader needed

### Texture Compression (Godot Import Settings)

| Map | Mobile compression | Memory per map (1024²) | Memory per map (512²) |
|---|---|---|---|
| BaseColor (RGBA) | ASTC 6×6 RGBA | ~340 KB | ~85 KB |
| Normal (RG) | ASTC 6×6 RG | ~170 KB | ~43 KB |
| ORM (RGB) | ASTC 6×6 RGB | ~256 KB | ~64 KB |
| Emissive (RGB, 256²) | ASTC 6×6 RGB | ~16 KB | — |

**Total texture memory per Pudge instance** (shared across instances of same hero):
~782 KB for body atlas + ~192 KB for hook atlas = **~975 KB ≈ 1 MB**.

10 hero instances on screen all share the same body/hook textures (only `tint_color`
uniform differs per instance) — total scene texture cost stays at **~1 MB**, not 10 MB.

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

| Socket name | Bone parent (sanitized) | Local Position (m) | Local Rotation (deg) | Purpose |
|---|---|---|---|---|
| `socket_hook_hand` | `mixamorig_LeftHand` | (0.05, 0.00, 0.00) | (0, 0, 0) | Hook prop attachment point. The `mesh_pudge_hook` is parented here. Detached at runtime during `hook_throw` animation. |
| `socket_offhand` | `mixamorig_RightHand` | (0.04, 0.00, 0.00) | (0, 0, 0) | Optional cleaver / secondary attack prop spawn point. |
| `socket_chain_origin` | `mixamorig_Spine2` | (-0.08, 0.05, 0.00) | (0, 0, 0) | Chain VFX anchor when the hook is offscreen during `hook_throw`. Offset to character's left where the chain visually exits the body. |
| `socket_hit_center` | `mixamorig_Spine1` | (0.00, 0.00, -0.28) | (0, 0, 0) | Damage VFX origin + hit-react impulse reference point. Placed at forward-most belly equator (Pudge's largest screen-filling part at top-down cam). |
| `socket_head_top` | `mixamorig_Head` | (0.00, 0.18, 0.00) | (0, 0, 0) | Status effect icon mount (stun halo, level-up burst, CC indicator). Floats above skull dome. |

**Local position interpretation**: positions are in **bone local space**, where the
bone's +Y axis points along the bone (head → tail). +X and +Z are perpendicular axes
following Mixamo's bone roll convention.

### Per-Socket World Position at T-Pose Rest (for verification)

The character-artist verifies sockets by checking world-space positions when the
mesh is in T-pose bind. Expected values:

| Socket | World position at T-pose rest (m) | Verification region in mesh |
|---|---|---|
| `socket_hook_hand` | (+0.55, +0.95, +0.05) | At the left palm center, slightly forward (toward -Z when facing -Z) |
| `socket_offhand` | (-0.55, +0.95, +0.04) | At the right palm center, slightly forward |
| `socket_chain_origin` | (-0.08, +0.95, +0.00) | Upper chest, left-of-center (concept's chain exit point) |
| `socket_hit_center` | (+0.00, +0.58, -0.28) | Forward belly equator (most protruding point) |
| `socket_head_top` | (+0.00, +1.40, +0.00) | Top of skull dome |

The rigger places the bones such that these world positions match the visual
landmarks. Once bones are placed, sockets' local offsets stay small and stable.

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

At LOD3 (impostor billboard), sockets are not used — visual effects spawn at the
billboard's world position with no bone targeting.

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

**Total bones: 20-25** depending on optional features (BellyJiggle required, Jaw +
chain bones optional). All bones use Mixamo naming convention.

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
        │       │   │       └── mixamorig:Jaw (OPTIONAL)
        │       │   ├── mixamorig:LeftShoulder
        │       │   │   └── mixamorig:LeftArm
        │       │   │       └── mixamorig:LeftForeArm
        │       │   │           └── mixamorig:LeftHand
        │       │   │               └── (chain bones if used — see below)
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

| Bone | Required? | Parent | Role |
|---|---|---|---|
| `mixamorig:BellyJiggle` | **YES** | `mixamorig:Spine1` | Drives gut bounce in idle, walk, run, death. Spring-driven via Godot 4.6 `SkeletonModification3D` if available, else keyframed. Influence painted via `jiggle_boundary` vertex color (§3). |
| `mixamorig:Jaw` | Optional | `mixamorig:Head` | Drives mouth open for `taunt` and `death` (gape). Cut if `taunt` is descoped from MVP. |
| `mixamorig:ChainLink1` | Optional | `mixamorig:LeftHand` | First belt-chain link. |
| `mixamorig:ChainLink2` | Optional | `mixamorig:ChainLink1` | Second link. |
| `mixamorig:ChainLink3` | Optional | `mixamorig:ChainLink2` | Third link. |
| `mixamorig:ChainLink4` | Optional | `mixamorig:ChainLink3` | Fourth link (closest to belt). Spring-driven for organic sway if Godot's `SkeletonModification3D` supports it. |

#### Total bone count summary

| Configuration | Bones | When to use |
|---|---|---|
| **Minimum** (no Jaw, no chain) | **21** (20 Mixamo + BellyJiggle) | If Jaw and chain sway are descoped. Most lean. |
| **MVP** (Jaw, no chain) | **22** | MVP shipping target. Jaw enables taunt and death gape. |
| **Full** (Jaw + chain bones) | **25** | Best visual fidelity. Chain sway enriches idle. |

**Recommended for MVP**: 22 bones (minimum + BellyJiggle + Jaw). Chain bones added
post-MVP if profiling allows.

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
| Belly transitions | `BellyJiggle` (40%) | `Spine1` (60%) | `jiggle_boundary` yellow region |
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

**LOD suffix is mandatory.** Godot's glTF importer auto-detects `_lod0`, `_lod1`,
`_lod2` suffixes and configures LOD switching automatically. Missing suffix = no LOD
detected = manual import setup required.

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

Path: `src/assets/models/heroes/textures/`

| File | Resolution | Material slot |
|---|---|---|
| `pudge_body_basecolor.png` | 1024×1024 RGBA | `mat_pudge_body` albedo (RGB) + tint mask (A) |
| `pudge_body_normal.png` | 1024×1024 RG | `mat_pudge_body` normal (RG, B reconstructed) |
| `pudge_body_orm.png` | 1024×1024 RGB | `mat_pudge_body` AO+roughness+metallic |
| `pudge_body_emissive.png` | 256×256 RGB | `mat_pudge_body` emissive (eyes only, cropped) |
| `pudge_hook_basecolor.png` | 512×512 RGB | `mat_pudge_hook` albedo |
| `pudge_hook_normal.png` | 512×512 RG | `mat_pudge_hook` normal |
| `pudge_hook_orm.png` | 512×512 RGB | `mat_pudge_hook` AO+roughness+metallic |
| `pudge_body_basecolor_ai_projection.png` | 1024×1024 RGB | **Reference only** — AI mesh's projected colors. NOT FINAL. Labeled clearly in handoff. |

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
  - [ ] Contains armature (`arm_pudge`) with all 22 MVP bones (or 21/25 if Jaw/chain config differs)
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

Path: `src/assets/models/heroes/textures/`

#### C.1 Final body atlas (1024 × 1024)

- [ ] `pudge_body_basecolor.png` (RGBA — RGB = hand-painted base, A = tint mask)
- [ ] `pudge_body_normal.png` (RG — tangent-space normal, baked from `textured_mesh_bake_hp`)
- [ ] `pudge_body_orm.png` (RGB — R=AO baked in combined-scene, G=Roughness, B=Metallic)

#### C.2 Final eye emissive (256 × 256, cropped)

- [ ] `pudge_body_emissive.png` (RGB — black except eye sclera region per concept material table)

#### C.3 Final hook atlas (512 × 512)

- [ ] `pudge_hook_basecolor.png` (RGB)
- [ ] `pudge_hook_normal.png` (RG)
- [ ] `pudge_hook_orm.png` (RGB — combined-scene AO bake)

#### C.4 Reference (NOT FINAL)

- [ ] `pudge_body_basecolor_ai_projection.png` (RGB) — AI-mesh projected color, labeled in handoff notes as "REFERENCE ONLY — DO NOT SHIP"

#### C.5 Texture validation

- [ ] Each PNG passes UV-checker visualization (no stretched / missing islands)
- [ ] Body atlas passes 3-tint validation (green/red/blue uniform produces coherent Pudge — §5)
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

- [ ] `pudge.glb` imports with no ERROR rows in Godot Output panel. Warnings reviewed against the approved-warnings list at `production/qa/godot-acceptable-warnings.md` (created at Stage 10 first import; any new warning type added to the list requires technical-artist sign-off)
- [ ] `pudge_hook.glb` imports with same warning-review standard as above
- [ ] Skeleton bones present and named `mixamorig_*` (sanitized from `mixamorig:` per contract §3)
- [ ] **Per contract O-5**: LOD auto-detection by `_lod*` suffix does NOT work in Godot 4.6 for pre-authored LODs. Verify each LOD `MeshInstance3D` has correct `visibility_range_begin` and `visibility_range_end` configured manually per the Stage 10 import setup. Orbit the editor camera and confirm LOD swap happens at the spec §2 distances

#### F.3 In-game runtime test

- [ ] Loaded by `HeroModelBuilder` without warnings (no `push_warning` or `push_error` calls during `build_model`)
- [ ] Pudge faces movement direction at runtime (no 180° flip needed; `hero_model_builder.gd:74` `glb_root.rotation.y = PI` line removed per contract §2 + §12)
- [ ] All 5 sockets resolve to `BoneAttachment3D` (not Marker3D fallback) — check via `print(socket.get_class())` in a smoke test, must print `BoneAttachment3D` for all 5 socket names from contract §5
- [ ] Hook prop attached to `socket_hook_hand` at runtime (hook mesh parented to the socket node in the scene tree)
- [ ] Team tint shader applies correctly: render the same Pudge instance 3 times with `hero_color` = `Color(0.5, 0.8, 0.2)` (green), `Color(0.9, 0.2, 0.2)` (red), `Color(0.2, 0.4, 0.9)` (blue). All three produce visually coherent Pudge with the skin tinted to the team color and non-skin surfaces (eyes, belt, boots, hook) unchanged. Screenshots saved to `production/qa/evidence/pudge-tint-{green,red,blue}.png`
- [ ] **Silhouette readability (objective measurement)**: In the Godot editor scene view at game-cam distance (5-8 m, top-down 30° pitch), the hook prop tip extends outside the body silhouette bounding box by at least 20% of character height (≥0.28 m for the 1.40 m Pudge). Measure via the editor's selection gizmo (select hook mesh, read bounding box extents) vs body mesh bounds. Screenshot saved to `production/qa/evidence/pudge-silhouette-game-cam.png`
- [ ] **Face readability at menu cam (objective measurement)**: At menu cam distance (1.5-2 m, eye-level), screenshot to `production/qa/evidence/pudge-face-menu-cam.png` must show: (a) asymmetric eyes — the larger left eye is visibly bigger than the right when measured in pixels (~15% larger sclera diameter per concept); (b) each pupil readable as a distinct dark spot (≥3 px wide at 1080p capture); (c) stitch lines resolve as ≥2 px wide painted dark seams across the belly front

#### F.4 Performance baseline

- [ ] **Stress scene** at `src/scenes/perf/pudge_stress_test.tscn` — 10 instances of `pudge.glb` at LOD0, no terrain, no VFX, all in camera frustum, shadows OFF, vsync OFF. Test apparatus + workflow documented at `tests/performance/README.md`.
- [ ] **Target-device p95** ≤ 16 ms (60 FPS budget). Device named in contract O-1 (deferred until tech-director + producer decide). FAIL = p95 > 16 ms → spec renegotiation: drop body atlas to 512, drop LOD0 ceiling to 4,500 tris, or both. Result recorded in `tests/performance/README.md` baseline history table per the Step 6 measurement framework.
- [ ] **Texture memory budget**: total scene texture cost ≤ 8 MB (with mips, ETC2 RGBA compression). This budgets ~5.5-7.3 MB for one Pudge's shared atlases (5 body maps at 1024² + 3 hook maps at 512²) — updated per contract O-7 verification. The previous "≤ 2 MB" criterion was authored before ETC2 RGBA's actual ~1 MB/1024² per-map cost was verified; that target is impossible without dropping atlas sizes. If 2 MB is required (e.g. low-end Android), apply contingency trims from materials spec §12 (drop tintmask to 512², drop body normal to 512²) and re-measure.
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
- [ ] All §12 open questions either marked RESOLVED with decision text in this spec, OR migrated to `design/gdd/contracts/pudge-interface-contract.md` §11 with owner + deadline + status (DEFERRED / PARTIAL / RESOLVED acceptable; OPEN / NEW require resolution before F-gate runs)

### Acceptance Criteria

Pudge is "shipped per this spec" only when:

1. ✅ All A-H sections checked complete
2. ✅ F.1, F.2, F.3 gate runs all PASS
3. ✅ Spec status changed from "DRAFT — section-by-section authoring in progress" to "APPROVED — production ready"
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

#### Q12.4 — Tint shader: rewrite to mask-based or extend existing hue-based?

The existing `res://assets/shaders/hero_body_tint.gdshader` detects skin via
hue band (yellow-green hue range). This spec §5 prescribes a mask-based approach
(alpha channel of base color = tint mask). Two paths:

- **Option A**: Rewrite shader to mask-based. Cleaner, more controllable. Requires
  every existing hero's base color to be re-authored with alpha mask.
- **Option B**: Keep hue-based for current heroes, paint Pudge's base color to fit
  the existing detection. Limits skin base palette.

**Decision needed before Stage 7 texture painting starts.** Owner: art-director +
gameplay-programmer.

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

#### Q12.8 — BellyJiggle bone: spring or keyframe?

§9 says "spring-driven via `SkeletonModification3D` if available, else keyframed."
Godot 4.6 restored skeleton modifications — confirm the spring modifier works for
secondary motion on a single bone driven by the parent's velocity. If it works,
spring is preferred (zero animator keyframe work). If not, all 10 animation clips
need belly bounce keyframed manually.

**Test in Stage 8 before authoring animation clips.**

#### Q12.9 — Chain bone count: include in MVP or post-MVP?

§9 lists `ChainLink1-4` as optional. If included, idle/walk gain organic chain sway
but skeleton grows to 25 bones. If excluded, chain is a static painted strip on the
body atlas (no sway).

- **MVP recommendation**: exclude (keep at 22 bones)
- **Polish phase**: add the chain bones + spring sim

**Decision before Stage 8 starts** so the rigger knows the skeleton scope.

#### Q12.10 — Jaw bone: required for MVP or cut with taunt?

§9 lists Jaw as optional. Jaw is needed for `taunt` clip (mouth open) and `death`
clip (gape). If taunt is descoped from MVP, Jaw can be cut, saving 1 bone.

**Open question**: is `taunt` in MVP or post-MVP? Owner: game-designer.

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

#### Q12.13 — Export orientation: built right the first time?

§6 mandates Pudge faces -Y in Blender so exports face -Z in Godot. The current
`pudge_v2_remesh` (Stage 2 scaffolding) was imported from Hunyuan3D — direction
not verified.

**Stage 4 (sculpt cleanup) must verify the mesh faces -Y in Blender front view**
before sculpting begins. If it faces +Y, rotate 180° around Z axis and apply
rotation. Catching this early avoids the cascading 180°-flip-on-loader bug.

#### Q12.14 — LOD object naming for Godot's auto-detect

§10 specifies `mesh_pudge_body_lod0` / `_lod1` / `_lod2` for Godot's automatic LOD
detection. Verify this auto-detect actually works in Godot 4.6 (versus needing
manual import settings). If auto-detect fails:

- **Workaround A**: Use Godot import dock to manually configure LODs
- **Workaround B**: Switch to `MeshInstance3D.set_visibility_range` programmatically
  at runtime in `HeroModelBuilder`

Test during first export to Godot.

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

#### Q12.18 — Update `design/gdd/hero-system.md` to include Pudge as 4th hero

User confirmed Pudge is a "separate 4th hero" (not Vex's visual identity).
`hero-system.md` currently lists 3 heroes: Vex, Lash, Maw. Pudge needs to be added
to the roster with his own data file (`data/heroes/pudge.tres` already exists from
prior work) and statline.

**Owner**: game-designer. **Deadline**: Stage 10 — when Pudge ships, the hero
system must know about him.

#### Q12.19 — Concept doc title update

`design/concept-art/pudge.md` was authored for "Vex's visual identity" (or some
historical context where the hero_id and visual identity were intertwined).
Now that Pudge is a separate hero, the concept doc should be reviewed for stale
references. Owner: narrative-director / concept-artist.

#### Q12.20 — Performance target device

§11 specifies "Mid-tier mobile target device." What is the actual target?

- Samsung Galaxy A54 (mid-range 2023)?
- iPhone 12 (mid-range 2020-2023)?
- Both?

The 6,000-tri LOD0 + 1024 atlas assumes mid-range mobile. If the actual target is
high-end mobile only (iPhone 14 Pro+, S23+), budgets can grow. If low-end is
included (sub-$300 Android), budgets must shrink.

**Owner**: technical-director + producer. **Deadline**: before Stage 7 texture
authoring (different compression for different tiers).

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

| ID | Question | Owner | Deadline | Status |
|---|---|---|---|---|
| Q12.1 | Delete OLD scaffolding now | character-artist | Start of Stage 5 | Recommendation: defer to Stage 5 |
| Q12.2 | Apron stub yes/no | art-director | Stage 4 | Recommendation: yes |
| Q12.4 | Tint shader rewrite | art-director + gameplay-prog | Stage 7 | Recommendation: rewrite to mask-based |
| Q12.5 | Eye emissive separate vs packed | texture-artist | Stage 7 | Recommendation: separate |
| Q12.8 | BellyJiggle spring vs keyframe | rigging-animator | Stage 8 | Test spring first |
| Q12.9 | Chain bones in MVP | rigging-animator | Stage 8 | Recommendation: exclude (post-MVP) |
| Q12.10 | Jaw bone in MVP | game-designer | Stage 8 | Tied to taunt scope decision |
| Q12.13 | Mesh orientation verified | blender-specialist | Stage 4 | Action: verify before sculpt |
| Q12.14 | LOD auto-detect works | blender-specialist | Stage 10 | Action: test during first export |
| Q12.18 | Update hero-system.md | game-designer | Stage 10 | Action item carried forward |
| Q12.20 | Mid-tier device target | technical-director | Stage 7 | Decision needed |

---

*End of Pudge Model Spec — Stage 3.*
*Sections 1-12 authored 2026-05-30. Status: DRAFT awaiting full review.*
*Next: review all sections together, then mark APPROVED and begin Stage 4 (sculpt cleanup).*
