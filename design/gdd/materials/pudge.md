# Pudge — Stage 3 Material / Texture Spec

> **Status**: DRAFT — awaiting texture-artist and technical-artist approval before bake begins
> **Hero ID**: `pudge`
> **Stage**: 3 of 8 (Texture Spec)
> **Date**: 2026-04-28
> **Author**: `texture-artist` agent
>
> **Source documents**
> - Brief (locked): `/design/characters/pudge_brief.md`
> - Concept sheet (approved): `/design/concept-art/pudge.md`
> - Model spec (approved): `/design/gdd/models/pudge.md`
>
> **Consumers**: Blender artist (bake workflow), `technical-artist` (Godot material
> setup, Stage 8), QA (texel density verification)

This document is the written PBR contract. Nothing in this spec may change without
notifying the technical-artist, the painter/baker, and updating this file. Every
texture value, channel assignment, resolution decision, and atlas layout described
here is authoritative for Stages 4 through 8.

---

## 1. Material Count and Target

Two materials. Two draw calls. This matches the hard limit in brief §2.

| Material name | Mesh target | Atlas size | Draw calls |
|---|---|---|---|
| `mat_pudge_body` | `mesh_pudge_body` | 1024 x 1024 px | 1 |
| `mat_pudge_hook` | `mesh_pudge_hook` | 512 x 512 px | 1 |

**Contract restatement**: All body geometry — torso, head, arms, hands, legs,
boots, belt, apron stub, chain links (hand-to-belt portion), and eye spheres —
is covered by `mat_pudge_body` on a single 1024² atlas. The hook J-curve plus its
immediately adjacent 1-2 chain links are covered by `mat_pudge_hook` on a 512²
atlas. Splitting beyond these two materials is not permitted without explicit
approval from `art-director` and `technical-artist` and a renegotiation of the
brief.

---

## 2. Texture Maps per Material

### 2a. mat_pudge_body — 1024 x 1024

| Map | File name | Resolution | Format on disk | Color space | Bit depth | Compression target (Godot import) | Est. VRAM |
|---|---|---|---|---|---|---|---|
| BaseColor | `body_basecolor.png` | 1024² | PNG lossless | sRGB | 8-bit/ch | BasisUniversal UASTC (BC7 on desktop, ETC2 RGBA on mobile) | ~0.67 MB |
| Normal | `body_normal.png` | 1024² | PNG lossless | Linear | 8-bit/ch | BC5 (desktop) / ETC2 RG (mobile) — Godot normal import preset | ~0.50 MB |
| ORM | `body_orm.png` | 1024² | PNG lossless | Linear | 8-bit/ch | BC7 (desktop) / ETC2 RGBA (mobile) | ~0.67 MB |
| Emissive | `body_emissive.png` | 256² | PNG lossless | sRGB | 8-bit/ch | BC7 (desktop) / ETC2 RGBA (mobile) | ~0.04 MB |
| Tint mask | `body_tintmask.png` | 1024² | PNG lossless | Linear | 8-bit/ch (single channel grayscale) | BC4 (desktop) / ETC2 R (mobile) | ~0.17 MB |

**Body subtotal (compressed)**: ~2.05 MB

**Format justification**: PNG lossless is the source format delivered to Godot's
import pipeline. Godot's importer compresses to BasisUniversal (UASTC path) at
import time, producing BC7 on desktop Forward+ renderer and ETC2 on mobile. The
texture artist never ships DDS — that is the engine's output, not the input.
BC5 for normals is the correct Godot 4.6 normal map preset (two-channel R+G,
reconstructs B in shader). BC4 for the tint mask (single grayscale channel) is
the most memory-efficient format for a 1-channel map.

**16-bit note**: No map in this set requires 16-bit precision. The ORM channels
(AO, roughness, metallic) have sufficient fidelity at 8-bit. Normal map banding
risk at 8-bit is mitigated by the tangent-space bake being at 1024² — banding
only becomes visible at resolutions below 512² or with extreme surface curvature
not present on this character.

**Emissive resolution justification**: See Section 8 for full reasoning. The eyes
occupy a small fraction of the atlas. A 256² dedicated emissive map is sufficient
and saves ~0.63 MB of compressed VRAM versus a 1024² emissive.

### 2b. mat_pudge_hook — 512 x 512

| Map | File name | Resolution | Format on disk | Color space | Bit depth | Compression target (Godot import) | Est. VRAM |
|---|---|---|---|---|---|---|---|
| BaseColor | `hook_basecolor.png` | 512² | PNG lossless | sRGB | 8-bit/ch | BasisUniversal UASTC | ~0.17 MB |
| Normal | `hook_normal.png` | 512² | PNG lossless | Linear | 8-bit/ch | BC5 / ETC2 RG | ~0.13 MB |
| ORM | `hook_orm.png` | 512² | PNG lossless | Linear | 8-bit/ch | BC7 / ETC2 RGBA | ~0.17 MB |

**Hook subtotal (compressed)**: ~0.47 MB

No emissive map for the hook material. The hook has no emissive elements per the
concept sheet and brief. No tint mask for the hook — the hook is iron and not
subject to the team skin tint.

---

## 3. Atlas Layout

### 3a. Body atlas — 1024 x 1024

All coordinates below are in pixels from the top-left corner of the atlas
(U=0, V=0 = top-left in Blender/Photoshop convention). Minimum 8 px padding
between all islands is enforced throughout.

```
+-------[0]------[256]------[512]------[768]-----[1024]+
[0]   |                           |                          |
      |   FACE ISLAND             |   TORSO FRONT            |
      |   approx 344 x 344 px     |   approx 344 x 280 px    |
      |   Pixels [8,8]-[352,352]  |   Pixels [368,8]-        |
      |                           |   [944, 288]             |
[256] |   Skull sub-island        |   Apron sub-island       |
      |   approx 200 x 120 px     |   approx 128 x 96 px     |
      |   [8, 360]-[208, 480]     |   [368, 296]-[496, 392]  |
      |                           |                          |
[512] +---------------------------+--------------------------+
      |                           |                          |
      |   ARMS + HANDS            |   LEGS + BOOTS + BELT   |
      |   Left arm (hook arm):    |   Boots (mirrored pair): |
      |   approx 180 x 240 px     |   approx 300 x 200 px    |
      |   [8, 520]-[188, 760]     |   [528, 520]-[828, 720]  |
      |                           |                          |
      |   Right arm:              |   Belt band strip:       |
      |   approx 140 x 192 px     |   approx 320 x 48 px     |
      |   [8, 768]-[148, 960]     |   [528, 728]-[848, 776]  |
      |                           |                          |
      |   Left hand:              |   Legs (mirrored):       |
      |   approx 96 x 80 px       |   approx 200 x 120 px    |
      |   [196, 520]-[292, 600]   |   [528, 784]-[728, 904]  |
      |                           |                          |
      |   Right hand:             |   Chain links (body):    |
      |   approx 96 x 80 px       |   approx 300 x 80 px     |
      |   [196, 608]-[292, 688]   |   [528, 912]-[828, 992]  |
      |                           |                          |
[1024]+---------------------------+--------------------------+
```

**Island allocation table**

| Island | Pixel region (approx) | Pixel area | Texel density at 256 px/m | Texel density at 512 px/m |
|---|---|---|---|---|
| Face (asymmetric — no mirror) | 344 x 344 px = 118,336 px² | 344 x 344 | Face panel ~0.30m x 0.30m → 344/0.30 = **1,147 px/m** | Exceeds 512 px/m target |
| Skull sub-island | 200 x 120 px | 24,000 px² | Skull ~0.40m arc → 200/0.40 = 500 px/m | At target |
| Torso front (belly, stitches, chest panel) | 344 x 280 px | 96,320 px² | Torso front ~0.56m wide → 344/0.56 = **614 px/m** | Exceeds 256 px/m target |
| Apron stub (shares belt corner) | 128 x 96 px | 12,288 px² | Apron stub ~0.15m wide → 128/0.15 = **853 px/m** | Exceeds 256 px/m target |
| Left arm (hook arm) | 180 x 240 px | 43,200 px² | Arm length ~0.30m → 240/0.30 = **800 px/m** | Exceeds target |
| Right arm | 140 x 192 px | 26,880 px² | Arm length ~0.28m → 192/0.28 = **686 px/m** | Exceeds target |
| Left hand | 96 x 80 px | 7,680 px² | Hand ~0.10m → 96/0.10 = **960 px/m** | Exceeds target |
| Right hand | 96 x 80 px | 7,680 px² | Same | Exceeds target |
| Boots (mirrored pair, single island) | 300 x 200 px | 60,000 px² | Boot width ~0.12m → 300/0.12 = **2,500 px/m** | Exceeds target |
| Belt band strip | 320 x 48 px | 15,360 px² | Belt circumference unwrapped ~0.56m → 320/0.56 = **571 px/m** | At/above target |
| Legs (mirrored pair, single island) | 200 x 120 px | 24,000 px² | Leg length ~0.20m → 120/0.20 = **600 px/m** | Exceeds 128 px/m target |
| Chain links (body, hand-to-belt) | 300 x 80 px | 24,000 px² | 4 links ~0.12m chain → 300/0.12 = **2,500 px/m** | Exceeds 256 px/m target |

**Sanity check — pixel accounting**

| Category | Pixel area |
|---|---|
| Face + skull | 118,336 + 24,000 = 142,336 |
| Torso front + apron stub | 96,320 + 12,288 = 108,608 |
| Arms (both) + hands (both) | 43,200 + 26,880 + 7,680 + 7,680 = 85,440 |
| Boots + belt + legs + chain | 60,000 + 15,360 + 24,000 + 24,000 = 123,360 |
| **Total island area (approx)** | **459,744 px²** |
| Total atlas area | 1,048,576 px² (1024²) |
| Utilization | ~44% |
| Padding / gutter overhead | ~8 px margins, ~20 islands, ~160 px linear = negligible vs. atlas area |
| Available headroom | ~56% — comfortable for UV packmaster optimization |

44% utilization is intentional for a 1024² atlas at chibi-scale proportions.
The UV packmaster should be run to reclaim headroom by rescaling islands relative
to each other while maintaining the density hierarchy (face and boots highest,
back-of-head and legs lowest). The approximate pixel regions above are layout
intent guides, not absolute UV coordinates — the packmaster output may differ
while still satisfying the density targets in Section 5.

**Note on torso back**: The torso back is not listed as a separate island because
it is intentionally low-priority (camera rarely sees it). It may share unused
space in the bottom-right region after packmaster. It receives 128 px/m — any
leftover pixels after the primary islands are packed will satisfy this
automatically.

### 3b. Hook atlas — 512 x 512

| Element | Pixel region (approx) | Pixel area | Notes |
|---|---|---|---|
| Hook body (J-curve main mass) | [8, 8]–[504, 272] = 496 x 264 px | 130,944 px² | Top 54% of atlas. Primary read element — gets the most pixels. |
| Hook inner curve / tip (blood sub-zone) | Sub-region within hook body island, approx lower 60 px of the hook island | Within hook body | Blood painting is localized here. Painter reference: mask the inner curve tip — approximately the bottom 15% of the hook body island. |
| Chain link 1 (closest to hand) | [8, 280]–[184, 376] = 176 x 96 px | 16,896 px² | Largest link; most visible in idle silhouette. |
| Chain link 2 | [192, 280]–[344, 376] = 152 x 96 px | 14,592 px² | |
| Chain link 3 | [352, 280]–[488, 360] = 136 x 80 px | 10,880 px² | |
| Chain link 4 (nearest belt coil) | [8, 384]–[120, 456] = 112 x 72 px | 8,064 px² | Smallest visible link; partial island acceptable. |

**Hook atlas sanity check**

| Category | Pixel area |
|---|---|
| Hook body | 130,944 |
| All 4 chain links | 16,896 + 14,592 + 10,880 + 8,064 = 50,432 |
| **Total island area** | **181,376 px²** |
| Total atlas area | 262,144 px² (512²) |
| Utilization | ~69% |

69% hook atlas utilization is healthy. The 31% remainder is padding and mip-safe
gutter space. At 512² with 8 px island padding, this is the expected range for a
clean packing.

---

## 4. Texel Density Verification Table

All density figures are calculated at the UV island areas from Section 3 and the
real-world surface dimensions from the model spec (Pudge total height 1.4 m,
belly sphere radius ~0.28 m, head height 0.42 m).

| Surface | Delivered density (px/m) | Target (px/m) | Status | Trade-off note |
|---|---|---|---|---|
| Face panel (front face plane) | ~1,147 px/m | 512 px/m | PASS — 2.2x over target | Face island is the atlas anchor; excess density reserved for asymmetric eye and tooth detail |
| Eye sclera + pupil (sub-region of face) | ~1,147 px/m (inherits face island density) | 512 px/m | PASS | Eyes share the face island — no separate unwrap needed |
| Skull (back + top) | ~500 px/m | 256 px/m | PASS — 1.95x over target | Skull sub-island slightly exceeds target; acceptable |
| Torso front (belly, stitches) | ~614 px/m | 256 px/m | PASS — 2.4x over target | Stitch detail is the primary torso read; extra density is appropriate |
| Apron stub | ~853 px/m | 256 px/m | PASS — 3.3x over target | Stub is small in world-space; even at this density the island is only ~128x96 px — painter note: check blood legibility at this size (see Section 11 Open Questions) |
| Torso back | ~128 px/m | 128 px/m | PASS — at target | Back is rarely visible; minimal density is the intentional budget decision from model spec |
| Left arm (hook arm) | ~800 px/m | 256 px/m | PASS | Larger arm island due to chunkier geometry |
| Right arm | ~686 px/m | 256 px/m | PASS | |
| Hands (both) | ~960 px/m | 256 px/m | PASS | Hands are compact world-space; small absolute island still provides high density |
| Boots (mirrored pair) | ~2,500 px/m | 256 px/m | PASS — significantly over | Boots are small in world-space (~0.12 m width) and a personality element; extra density appropriate for scuff and lace detail |
| Belt band | ~571 px/m | 256 px/m | PASS | |
| Legs (mirrored pair) | ~600 px/m | 128 px/m | PASS | Legs are mostly hidden under gut; 128 px/m target is easily met |
| Chain links (body, hand-to-belt) | ~2,500 px/m | 256 px/m | PASS | Each link is ~0.03 m per link world-space; even at this density the link island resolves to ~8-12 px per link — matches concept note requirement |
| Hook body (iron J-curve) | Hook atlas: 496px across ~0.30m hook = ~1,653 px/m | 256 px/m | PASS | Hook is the hero prop; high-density is warranted |
| Chain links (hook-adjacent) | ~4 links in ~160px = ~1,333 px/m | 256 px/m | PASS | |

**No surface misses its density target.** The chibi proportions (compact
world-space dimensions) combined with a 1024² atlas means density overshoots are
the norm. The atlas packmaster should not be instructed to reduce face density —
the overshoot is intentional headroom that will be absorbed by mip compression at
gameplay camera distances.

---

## 5. PBR Value Table — Painter Reference Card

Source: concept sheet Material Callouts table, extended with atlas painting notes.
All roughness and metallic values reference channels in the ORM map
(G = Roughness, B = Metallic). AO (R channel) is baked, not hand-painted.

| Surface | Base Color Hex | Roughness G value | Metallic B value | Atlas region | Painting notes |
|---|---|---|---|---|---|
| Skin (base) | `#8A8A7A` | 0.75 | 0.05 | Face island (primary), arms, hands, torso front | Desaturated warm grey. Zero green in base — tint shader provides green. Shadow and cavity variants below darken this value. |
| Skin (shadow/cavity) | `#6B6B5E` | 0.70 | 0.08 | Underside of belly, armpits, neck fold, ear shadow | Paint into cavities: undersides of belly equator, inside the no-neck fold, axilla region. Warm shift toward `#7A6A5E` to fake SSS — warmer shadows, not cooler. |
| Skin (highlight/lit) | `#9E9E8E` | 0.80 | 0.05 | Belly front, forehead dome, shoulder top | Belly front is the single largest lit highlight. Lighten baked AO-bright regions to `#9E9E8E`. Do NOT lighten eyes — eyes are emissive, not highlight-lit. |
| Scar / stitch thread | `#332519` | 0.90 | 0.00 | Torso front island, vertical + horizontal seam lines | Near-black brown. Paint as single-pixel to 2-pixel wide lines following the vertical chest seam and horizontal belly bands from the concept turnaround. Thread lines must be visible at 256 px/m density — at 614 px/m torso density, each thread can be 2-3 px wide at LOD0. |
| Stitch hole / wound edge | `#5C1A1A` | 0.85 | 0.00 | Within 2-3 px of each thread line, torso front | Deep red-brown halo around each stitch point. Paint as small oval 2-3 px radius around the thread intersection points. |
| Teeth | `#C8B87A` | 0.80 | 0.00 | Face island, mouth interior strip | Yellowed off-white row across the tooth strip geometry. Paint individual tooth gaps as `#1A0E0E` dark vertical slits. Paint 1-2 teeth slightly brighter (`#D4C68A`) for a snaggle-tooth read. One gap should be ~4-5 px wider (missing tooth). |
| Eye sclera | `#F5E870` | 0.20 | 0.00 | Face island, eye sub-regions | Yellow-white per brief. Low roughness (0.20) for wet/bulging read. Left eye island is ~15% larger in UV to match the larger geometry. Emissive layer sits on top — see Section 8. |
| Eye emissive | `#FFB800` | — | — | Emissive map (256²), eye sclera sub-regions only | Emissive only. Intensity multiplier 3.0 applied in Godot material. Applied to sclera area only — do NOT extend to pupil. See Section 8 for full emissive map plan. |
| Eye pupil | `#1A0A0A` | 0.90 | 0.00 | Face island, center of each eye sub-region | Near-black, matte. No emissive. Left pupil slightly larger than right (mirrors the geometry asymmetry). |
| Belt leather | `#59330F` | 0.70 | 0.15 | Bottom-right quadrant, belt band strip | Mid brown. Scuff highlights `#7A4E1F` painted on top and side edges — use a dry-brush stroke technique. |
| Belt buckle (metal) | `#726E6A` | 0.35 | 0.70 | Within belt band island, center front | Iron/steel, moderate specular. Roughness drops to 0.35 — reads as polished metal vs. leather. Paint scratch streaks `#9A9590` horizontally. Metallic value 0.70 in B channel — mark clearly in ORM. |
| Boot leather | `#4A2E0A` | 0.75 | 0.10 | Bottom-right quadrant, boots island | Darker than belt. Boot toe area: paint slight crease/bulge to suggest too-small fit. Lace area: near-black `#1A1008` painted lace strands. |
| Boot sole | `#1A1510` | 0.90 | 0.00 | Within boots island, sole strip | Near-black, fully matte. Paint crack lines slightly darker. Heel area receives extra wear marks. |
| Apron stub (bloodied) | See blood spec (Section 11) | 0.85 | 0.00 | Torso front / belt corner sub-island | Off-white or cream `#D4C8A0` for the clean fabric; paint blood per Section 11 over this. The apron is described as "bloodied" — majority of the apron face should show blood staining. |
| Chain links (body, iron) | `#4A4844` | 0.45 | 0.65 | Bottom-left quadrant, chain strip | Dark iron. HAND-PAINT upper-face highlight `#7A7672` on each link's top face — do NOT rely on normal map alone at mobile renderer (concept Open Note #3). Metallic 0.65 in B channel. |
| Hook body (iron) | `#3E3C38` | 0.40 | 0.70 | Hook atlas, top 54% | Darker than chain. Slightly higher metallic (0.70) for denser iron read. Paint edge highlight on outer curve: `#6A6864` thin line along the convex outer face. |
| Hook tip / blood | `#8A1A1A` (dried) / `#C02020` (fresh streak) | 0.80 / 0.60 | 0.10 | Hook atlas, inner curve + tip sub-region | See Section 11 for complete blood placement spec. Dried blood is the primary value; fresh streak is accent only. |

---

## 6. Hero Color Tint Shader Contract

### Which regions receive the tint

The skin tint multiplier applies ONLY to regions painted with skin base values
(`#8A8A7A`, shadow `#6B6B5E`, highlight `#9E9E8E`). Specifically:

**Tints (mask value = 1.0)**:
- Face panel (skin areas only, excluding eyes, teeth, pupils)
- Skull (back of head)
- Torso front (skin strip above belt, excluding stitch lines)
- Arms (both)
- Hands

**Does NOT tint (mask value = 0.0)**:
- Eye sclera and pupils
- Teeth
- Scar / stitch thread lines
- Belt leather, belt buckle
- Boot leather, boot sole
- Apron stub (including blood)
- Chain links (body and hook)
- Hook body

The mask boundary must be hard-edged at non-skin-to-material transitions (skin
to belt edge, skin to boot top edge) and may be soft-edged (1-3 px feather) at
skin-to-stitch transitions to prevent a harsh white halo around scars under
certain tint colors.

### Tint mask delivery method

The tint mask is delivered as a **dedicated single-channel 8-bit grayscale PNG**:
`body_tintmask.png`, 1024 x 1024, linear color space.

This is the 5th map for `mat_pudge_body`. Within the implicit 4-map limit from
the brief, this requires justification:

**Justification for a 5th map over alternative packing approaches**:

Option A (considered and rejected): Pack the tint mask into the alpha channel of
`body_basecolor.png`. Godot 4.6's BC7 / UASTC compression handles RGBA, so the
alpha channel would be preserved. However, the BC color compression interacts with
alpha — presence of alpha forces BC7 RGBA path at higher cost than BC7 RGB, and
some Godot import presets do not expose the A channel of the base color for shader
reads without a custom shader. This creates a coupling between the base color
import setting and shader code that `technical-artist` would need to handle
carefully.

Option B (considered and rejected): Pack the tint mask into the ORM's unused
W channel. ORM uses R, G, B — there is no W channel in a 3-channel texture.
The ORM is authored as RGB PNG, not RGBA.

Option C (chosen): Dedicated `body_tintmask.png` at BC4 / ETC2 R compression
(single-channel, ~0.17 MB compressed). This is the cleanest separation of
concerns. The technical-artist reads it as a standalone texture in the shader
with a dedicated sampler. The painter's workflow is unambiguous — one map, one
purpose. The 0.17 MB cost is within the hero VRAM budget (see Section 13).

The brief §7 states the tint is "implemented via shader uniform on body material"
without specifying map count. A 5th map is the cleanest implementation. If the
`technical-artist` overrides this decision during Stage 8, the fallback is
Option A (alpha channel of BaseColor).

### Tint multiplication formula

```
final_color = base_color * lerp(vec3(1.0, 1.0, 1.0), team_tint_color, tint_mask)
```

Where:
- `base_color` = sampled from `body_basecolor.png` at UV
- `team_tint_color` = vec3 shader uniform, default `Color(0.5, 0.8, 0.2)` (Pudge green)
- `tint_mask` = float sampled from `body_tintmask.png` at UV, range 0.0-1.0
- `lerp(white, tint, mask)` = at mask 0.0, no tint (base color unchanged); at mask 1.0, full tint multiply

When `team_tint_color` = `Color(1.0, 1.0, 1.0)` (white), the result is the
unmodified base color — this confirms the formula does not alter untinted
materials when the uniform is set to white.

### Test palette for painter validation

Paint the base color map with the skin values from the PBR table. Before
finalizing, verify the material reads correctly under all three tints by checking
the Blender material node or the Godot preview:

| Tint name | team_tint_color value | Expected skin result |
|---|---|---|
| Green (Pudge default) | `Color(0.5, 0.8, 0.2)` | Skin reads as muted olive-green. Matches brief §1 hero color. |
| Red (team B) | `Color(0.85, 0.3, 0.25)` | Skin reads as desaturated red-brown. Should not look orange — base desaturation prevents orange. |
| Blue (team C) | `Color(0.3, 0.5, 0.85)` | Skin reads as cool blue-grey. Check that the face details (scars, eyes) still read against blue skin. |

Acceptance check: under all three tints, eyes, belt, and boots must retain their
original colors without tinting. If any of these shift under a tint swap, the
tint mask boundary has leaked — repaint the boundary before delivery.

---

## 7. Emissive Map Plan

### Resolution decision

`body_emissive.png` is authored at **256 x 256 px**.

At 1024² body atlas, the eye sclera islands occupy approximately 8,000-10,000 px²
total (both eyes combined, subset of the face island which is ~118,000 px²). The
face island is ~35% of the 1024² atlas, meaning the eye sub-regions within it are
approximately 11% of the face island = ~0.11 x 118,000 = ~13,000 px².

At 256² (65,536 px²), the emissive map still provides more than enough resolution
for the eye regions: each eye sclera maps to roughly 40-50 px diameter circle in
the emissive map at this resolution, which is sufficient to drive a clean emissive
glow. The emissive map is used purely for the intensity contribution to Godot's
StandardMaterial3D emissive channel — it does not need to carry color detail at
sub-pixel level, only the sclera vs. non-sclera boundary.

Authoring a 1024² emissive map to carry ~13,000 px² of actual content wastes
~630,000 px² of compressed VRAM with solid black. At BC7 compression,
1024² emissive = ~0.67 MB vs. 256² = ~0.04 MB — a 0.63 MB savings for zero
visual difference.

### UV mapping for 256² emissive

The emissive map uses the **same UV coordinates as the 1024² body atlas** but is
sampled at 256² resolution. The Godot importer handles the resolution mismatch;
the shader samples from UV space, not pixel space. The painter must paint the
256² emissive at corresponding UV positions — the face island at 256² will be
approximately 344/4 = 86 px for the full face area, and the eye sclera circles
within it will be approximately 40-50 px diameter per eye.

### Emissive content

- Eye sclera sub-regions only (left and right). Color: `#FFB800` (emissive orange-yellow).
- All other pixels: pure black `#000000` — zero emission.
- Pupil area: black. Do NOT paint emissive into the pupil.
- The inner rim of each sclera receives the full emissive color. If an iris ring
  is present in the concept, it also receives emissive. The pupil dark spot is
  strictly excluded.

### Intensity

Emissive intensity multiplier: **3.0** — applied as the `emission_energy` or
equivalent multiplier in the Godot StandardMaterial3D emissive energy slot (Stage
8, `technical-artist` sets this in the .tres). The painter bakes the raw
`#FFB800` color at full luminance into the emissive map; the 3.0 multiplier is
a runtime scale, not baked into the texture values. This keeps the source texture
HDR-safe and allows runtime tuning without re-baking.

---

## 8. Normal Map Plan

### Convention

Tangent-space normal map, **OpenGL convention** (Y-up in texture space, green
channel pointing upward). This is the Godot 4.6 standard. Do not author a DirectX
convention normal map (inverted green) — Godot does not invert the green channel
by default.

Verify: in the baked normal map, concave areas (stitch holes, belly fold cavities)
should appear with a darker green lower area and lighter green upper area when
viewed in the texture. If the normal map looks "inverted" (concavities appear as
bumps), the green channel is flipped.

### Bake source

Baked from high-poly sculpt (`tools/blender/pudge.blend` working file) using
Blender's Cycles bake pipeline:

| Feature baked | Notes |
|---|---|
| Belly stitches (raised thread lines) | Primary surface detail. Stitch thread elevation above belly surface: ~2-3 mm in sculpt. |
| Stitch hole depressions | Small concave dents at stitch pierce points. |
| Belly fold surface | Subtle undulation where belly droops — enhances gut-weight read. |
| Boot wear / crease geometry | Toe crease, heel scuff area, sole edge. |
| Belt leather surface grain | Subtle leather pore-like surface from sculpt. |
| Shoulder/arm skin tension | Light topology stress lines under raised hook arm. |
| Hook curvature (hook atlas) | Full J-curve surface normal; hammer-forged facet language on flat faces. |
| Hand-to-hook contact shadowing | Not a normal feature — this is an AO bake requirement (see Section 10). |

### Hand-painted normal additions (post-bake)

These features are too small or planar for sculpt-based baking and must be
hand-painted into the normal map using a paint-over in Substance Painter, Krita,
or Blender's texture paint mode:

- Tooth ridge microdetail on the tooth strip (1-2 px horizontal normal variation
  to suggest rounded teeth, not flat quads)
- Buckle stamped-edge detail (subtle normal-raised border on the belt buckle quad)
- Chain link edge chamfer (if the sculpt did not model a chamfer, add it as a
  hand-painted normal edge to each link's silhouette side)

### Strength

Normal map strength: **1.0** in the Godot StandardMaterial3D `normal_scale`
parameter (Stage 8). The bake should be authored at full strength — do not pre-
bake at 50% and expect runtime boost. If the normals read too strong in Godot
(stitches look like geometry spikes), the `technical-artist` reduces `normal_scale`
to 0.8–0.9 as a tuning step. Start at 1.0.

---

## 9. ORM Channel Packing

### Channel assignments

```
R channel = Ambient Occlusion (AO)     — baked from high-poly
G channel = Roughness                  — hand-painted per PBR value table
B channel = Metallic                   — hand-painted per PBR value table
```

This matches brief §7 and the project's ORM convention. The ORM is a single
grayscale-per-channel linear PNG. Do not apply sRGB gamma to the ORM map — it
is linear data only.

### R channel — AO bake requirements

**Critical workflow requirement (concept Open Note #5, model spec §5 AO note)**:

The AO for BOTH `mat_pudge_body` and `mat_pudge_hook` must be baked in a
**single combined Blender scene** containing both `mesh_pudge_body` and
`mesh_pudge_hook` simultaneously. This is a hard requirement, not a suggestion.

Rationale: the hook hand contact zone — where the hook handle meets the left
palm — receives shadowing from the hook geometry that falls on the hand surface.
If the body is baked in isolation, the hand socket area will show a uniformly
bright AO where the hook would shadow it. This produces an incorrect
"unworn" appearance: the hook looks like it has never been held against the palm.
Baking with both meshes present ensures the hook casts correct ambient occlusion
onto the hand.

Bake settings:
- Samples: minimum 512 (1024 recommended for final bake)
- Ray distance: 0.05 m (5 cm) — appropriate for chibi proportions
- Ground plane: excluded from bake scene
- Only `mesh_pudge_body` + `mesh_pudge_hook` in the bake scene

The baked AO map is packed into the R channel of `body_orm.png` and `hook_orm.png`
respectively. No manual painting of the R channel — AO is always baked.

**Exception**: if the high-poly sculpt is not yet available when the texture artist
needs to start (stage ordering issue), paint a placeholder flat-grey R channel
(value 0.8) and flag to the blender-specialist that the AO bake pass is pending.
The final delivery must contain the baked AO — a flat grey AO is not acceptable
for delivery.

### G channel — Roughness painting guide

Paint roughness values per the PBR value table in Section 5. Remapped to
8-bit greyscale (0 = smooth/specular, 255 = fully matte):

| Value | Greyscale 8-bit | Surface |
|---|---|---|
| 0.20 | 51 | Eye sclera (wet, glossy) |
| 0.35 | 89 | Belt buckle (polished metal) |
| 0.40 | 102 | Hook body (heavy iron) |
| 0.45 | 115 | Chain links (iron) |
| 0.60 | 153 | Fresh blood streak on hook tip |
| 0.70 | 178 | Belt leather, skin shadow |
| 0.75 | 191 | Skin base, boot leather |
| 0.80 | 204 | Skin highlight, teeth |
| 0.85 | 217 | Stitch holes, boot sole, apron fabric |
| 0.90 | 229 | Stitch thread, boot sole, pupil |

Transitions between roughness zones (e.g., belt leather → buckle) should be
hard-edged, matching the material boundary in the base color. No roughness
gradient blending across material zones — chibi style reads material types as
distinct.

### B channel — Metallic painting guide

The majority of the body atlas is metallic 0.00 (organic materials). Only mark
these regions with non-zero metallic:

| Region | Metallic B value | Greyscale 8-bit | Notes |
|---|---|---|---|
| Belt buckle | 0.70 | 178 | High metallic for iron/steel read |
| Boot leather (minor) | 0.10 | 26 | Slight metallic for worn leather sheen — optional, may set to 0 if it reads fine without it |
| Belt leather (minor) | 0.15 | 38 | Same — worn leather minor sheen |
| Chain links (body) | 0.65 | 166 | Iron chain — significantly metallic |
| Hook body | 0.70 | 178 | Hook iron — highest metallic in body atlas |
| Skin (all) | 0.05 | 13 | Near-zero; slight metallic prevents overly flat specular. Acceptable range 0.00-0.08. |

All other surfaces: B channel = 0.00 (greyscale 0, pure black).

---

## 10. Blood Placement Spec

Source: concept Open Note #4 and brief §3 (hook: "blood-stained").

### Placement — hook tip only

Blood belongs on the **hook inner curve and tip only** — specifically the last
30-40% of the J-curve's inner face, concentrated at the tip point.

**What to paint**:

1. **Dried blood base layer** (`#8A1A1A`, roughness 0.80, metallic 0.10):
   - Primary blood color covering approximately 30-35% of the hook body island's
     lower region (the inner curve arc ending at the tip).
   - Opacity: solid coverage at the tip, feathering out 15-20 px up the inner
     curve face as the blood thins toward the shank.
   - Roughness note: 0.80 in G channel for dried blood (matte, desiccated
     surface) vs. surrounding iron 0.40 — the roughness contrast makes the blood
     read as a different material even at small sizes.

2. **Fresh blood accent streak** (`#C02020`, roughness 0.60):
   - A single narrow streak (2-4 px wide at 512² hook atlas resolution)
     running approximately 20-30 px from the tip upward along the inner curve.
   - This is an accent, not a fill. It reads as the "most recent" blood —
     brighter, slightly glossier.
   - Do NOT flood-fill the fresh blood — one streak only.

### What NOT to paint blood on

- Chain links: NO blood. Brief calls them "iron links." Material clarity requires
  the chain to read as iron, not gore. A bloody chain is a different design
  decision not in this brief.
- Hook shank / outer curve: NO blood. The hook is used for pulling; the outer
  face does not contact flesh.
- Apron stub: The apron stub on the body atlas is described as "bloodied" in the
  concept (resolved decision §6 of the brief), but this is general apron soiling
  (old dried stains, work-soiled fabric) — NOT the same fresh/dried hook blood.
  Use `#8A1A1A` for apron blood stains but paint them as spread fabric stains
  rather than impact spatter.

---

## 11. LOD Texture Strategy

| LOD | Body textures | Hook textures | Notes |
|---|---|---|---|
| LOD0 | Full 1024² set (BC + N + ORM + Emissive + TintMask) | Full 512² set (BC + N + ORM) | All maps active. Full mip chain generated by Godot importer. |
| LOD1 | Same 1024² maps — no separate downscaled atlas needed | Same 512² maps | Godot's mipmap system handles effective resolution reduction automatically. LOD1 at 15-30m will sample at mip level 2-3 of the 1024² map (~256²-512² effective) — this matches the visual complexity reduction of the LOD1 mesh. No manual downscaled atlas needed. |
| LOD2 | Same maps, deeper mip sampling | Same maps, deeper mip sampling | At 30-50m, mip level 4+ (~64²-128² effective). Chain link and stitch detail dissolves via mip — correct behavior. |
| LOD3 impostor | **256 x 256 flat-color + alpha billboard texture** | N/A (hook is painted into impostor) | Separate authored texture. NOT derived from the body atlas. Author as 8-rotation sprite sheet: 256² per frame x 8 frames = 512x256 px sheet or 1024x128 px strip. Color must represent flat-shaded Pudge at the dominant game lighting angle. Emissive yellow eyes must be hand-painted into the impostor directly — they will not glow in the billboard (no emissive on billboard is acceptable at impostor distances ~50m+). |

**Confirmation**: No separate downscaled atlas is needed for LOD1 or LOD2.
Godot's mipmap system is the LOD texture mechanism for all intermediate LODs.
The texture artist's deliverable is one set of source PNG files; the engine
handles all lower-resolution derivatives automatically.

**Impostor billboard (LOD3)**: The technical-artist generates this from the LOD2
render in Stage 8, per model spec §7. The texture-artist is not responsible for
impostor generation. However, if hand-authoring is requested, the impostor
should show the silhouette B (coiled hook carry) pose, include the eye emissive
color baked directly into the sprite's pixels, and use a 1-bit alpha mask (fully
opaque body, fully transparent background) for performance at billboard distances.

---

## 12. VRAM Budget

All estimates assume Godot 4.6 Forward+ renderer on desktop (BC7 / BC5) with
mip chains enabled. Mip chain adds approximately 33% overhead to each map
(geometric series sum). Values shown are full map + mips.

| Map | Compressed format | Resolution | Base size | + Mips (x1.33) | Notes |
|---|---|---|---|---|---|
| `body_basecolor.png` | BC7 (1 byte/px) | 1024² | 1,048,576 B | ~1.33 MB | RGBA BC7 path due to tint mask separate; BC7 RGB is 0.5 byte/px — estimate ~0.67 MB |
| `body_normal.png` | BC5 (1 byte/px for 2ch) | 1024² | 1,048,576 B | ~0.67 MB | BC5 is 0.5 byte/px |
| `body_orm.png` | BC7 RGB (0.5 byte/px) | 1024² | 524,288 B | ~0.67 MB | |
| `body_emissive.png` | BC7 (0.5 byte/px) | 256² | 32,768 B | ~0.04 MB | |
| `body_tintmask.png` | BC4 (0.5 byte/px) | 1024² | 524,288 B | ~0.22 MB | Single channel |
| `hook_basecolor.png` | BC7 RGB | 512² | 131,072 B | ~0.17 MB | |
| `hook_normal.png` | BC5 | 512² | 131,072 B | ~0.13 MB | |
| `hook_orm.png` | BC7 | 512² | 131,072 B | ~0.17 MB | |
| **LOD3 impostor billboard** | BC7 | 1024 x 128 (8 frames) | ~0.06 MB | ~0.08 MB | Generated in Stage 8 |
| **TOTAL** | | | | **~3.15 MB** | |

**Mobile ETC2 comparison**: On mobile (ETC2), individual map costs are similar
(ETC2 RGBA = 1 byte/px, ETC2 RGB = 0.5 byte/px). The total mobile VRAM
footprint is approximately **3.4-3.8 MB** with mips — within the 4 MB per-hero
target stated in the spec instructions, and significantly under the 4 MB ceiling.

**Budget compliance**: PASS. Total estimated VRAM ~3.15 MB (desktop) / ~3.5 MB
(mobile), under the 4 MB target. If the project requires the stricter 2 MB
target, options to reduce:

1. Drop the tint mask to 512² (saves ~0.16 MB)
2. Drop body normal to 512² (saves ~0.50 MB) — acceptable at chibi read distances
3. Drop hook atlas to 256² (saves ~0.25 MB) — acceptable at game camera distance

These are contingency trims. The base spec ships at the sizes described.

---

## 13. File Output Paths and Naming

All source textures delivered to:
`src/assets/textures/heroes/pudge/`

| File | Resolution | Map type |
|---|---|---|
| `body_basecolor.png` | 1024 x 1024 | BaseColor / Albedo (sRGB) |
| `body_normal.png` | 1024 x 1024 | Tangent-space normal (linear) |
| `body_orm.png` | 1024 x 1024 | ORM packed: R=AO, G=Rough, B=Metal (linear) |
| `body_emissive.png` | 256 x 256 | Emissive — eyes only (sRGB) |
| `body_tintmask.png` | 1024 x 1024 | Tint mask — skin regions (linear, single-channel greyscale) |
| `hook_basecolor.png` | 512 x 512 | Hook BaseColor (sRGB) |
| `hook_normal.png` | 512 x 512 | Hook normal (linear) |
| `hook_orm.png` | 512 x 512 | Hook ORM packed (linear) |

**Note on model spec naming**: The model spec (section 10) lists filenames as
`pudge_body_basecolor.png` with the `pudge_` prefix. This spec drops the
`pudge_` prefix because the files live in
`src/assets/textures/heroes/pudge/` — the directory provides the hero namespace.
Shorter names reduce redundancy. If the project-wide naming convention requires
the full `pudge_body_basecolor.png` form (e.g., for a flat textures directory),
defer to `technical-artist`'s preference and rename accordingly. Both forms are
acceptable; pick one and document it in the integration .tres file.

**Godot import configuration** (Stage 8, `technical-artist`):
- `body_basecolor.png` → sRGB, BasisUniversal, generate mipmaps
- `body_normal.png` → Normal Map preset (linear, BC5/ETC2 RG, generate mipmaps)
- `body_orm.png` → Linear, BasisUniversal, generate mipmaps
- `body_emissive.png` → sRGB, BasisUniversal, generate mipmaps
- `body_tintmask.png` → Linear, Grayscale BC4/ETC2 R, generate mipmaps
- Hook maps → same pattern as body maps (sRGB for BC, normal preset for N, linear for ORM)

---

## 14. Material Resource (.tres) Plan — Stage 8 Specification

This section specifies what the `technical-artist` must author in Stage 8.
The texture artist does not write Godot resources — this section is a handoff note.

### mat_pudge_body.tres

| Property | Value | Notes |
|---|---|---|
| Shader type | `ShaderMaterial` (custom shader) | StandardMaterial3D cannot expose a tint mask sampler directly as a multiply operation without a custom shader. Delegate to `godot-shader-specialist` for the shader source. |
| `albedo_texture` | `body_basecolor.png` (imported) | |
| `normal_texture` | `body_normal.png` (imported, normal preset) | |
| `orm_texture` | `body_orm.png` (imported, ORM slot) | |
| `emission_texture` | `body_emissive.png` (imported) | |
| Custom uniform: `tint_mask_texture` | `body_tintmask.png` (imported) | Sampler2D in shader |
| Custom uniform: `team_tint_color` | `Color(0.5, 0.8, 0.2)` (default — Pudge green) | vec3/Color uniform, set at runtime per team assignment |
| `emission_energy` | 3.0 | Per brief §7 |
| `normal_scale` | 1.0 | Start here; tune to 0.8-0.9 if normals read too strong |
| Cull mode | Back-face cull (default) | Apron stub is one-sided geo |

**Shader requirement**: The body material requires a custom shader that implements
the tint multiply formula from Section 6. This is outside the texture-artist's
scope — flag to `godot-shader-specialist` with the formula:
`final = base_color * lerp(vec3(1.0), team_tint_color, tint_mask)`.

### mat_pudge_hook.tres

| Property | Value | Notes |
|---|---|---|
| Shader type | `StandardMaterial3D` | Hook has no tint — StandardMaterial3D is sufficient. |
| `albedo_texture` | `hook_basecolor.png` | |
| `normal_texture` | `hook_normal.png` | |
| `orm_texture` | `hook_orm.png` | |
| `emission_enabled` | false | No emissive on hook |
| `normal_scale` | 1.0 | |
| Cull mode | Back-face cull | |

---

## 15. Open Questions and Blockers

### For the painter / bake artist

1. **Apron blood legibility**: The apron stub island is approximately 128 x 96 px
   in the 1024² body atlas (see Section 3a). The apron face width is approximately
   0.10-0.12 m world-space. At 853 px/m delivered density, the actual apron face
   occupies roughly 85-100 px across. Blood stain detail at 8 px minimum feature
   size is achievable, but the painter should verify that the blood reads as fabric
   staining (spread, soaked) rather than a solid color block. If it collapses to a
   flat blob at the game camera distance, raise this before delivering — it may be
   more effective to paint the apron as uniformly stained rather than detailed.

2. **Combined AO bake scene**: Do not begin the AO bake until both
   `mesh_pudge_body` and `mesh_pudge_hook` are finalized and joined into a single
   Blender scene. Starting AO bake with only one mesh present is a hard workflow
   error per Section 10. Coordinate with the character-artist and blender-specialist
   to confirm the combined `.blend` file is available at `tools/blender/pudge.blend`
   before the bake begins.

3. **Tint mask validation order**: Paint the tint mask before finalizing the base
   color. Run all three test tints (green, red, blue) in Blender material nodes or
   Godot before submitting. If the base skin reads incorrectly under any tint
   (e.g., turns orange under red tint, suggesting the base color already has warmth),
   correct the base color at `#8A8A7A` and re-verify. The tint validation pass is
   not optional — it is an acceptance criterion (brief §10 item 11).

4. **Stitch resolution check**: After the base color first-pass, zoom to the torso
   front island in the paint application at 1:1 pixel view. Each stitch line should
   be 2-3 px wide. If the stitch lines are barely 1 px at 1024² atlas resolution,
   raise this to the model spec owner — the torso front UV island may need
   rescaling. Do not attempt to fake unresolvable stitch detail with noise.

5. **Normal map convention verification**: Before delivering the normal map, sample
   a pixel on a concave surface (stitch hole depression) and confirm the green
   channel value is less than 128 (darker = surface faces down = OpenGL convention).
   If concavities show green > 128, the Y axis is inverted — flip the green channel.

### For the technical-artist (Stage 8)

1. **Custom shader authoring required**: `mat_pudge_body` requires a custom
   ShaderMaterial implementing the tint multiply from Section 6. Delegate the
   GLSL/Godot shader to `godot-shader-specialist` with the formula and the list of
   sampler inputs. This is a Stage 8 blocker — the body material cannot be set up
   as StandardMaterial3D.

2. **Import preset for tint mask**: The `body_tintmask.png` must be imported as
   a Texture2D with linear color space and Compress Mode = VRAM Compressed (BC4
   on desktop). Confirm Godot 4.6's importer exposes BC4 as a selectable format
   for single-channel textures. If BC4 is not directly selectable, use
   BasisUniversal with the Grayscale hint, or pack the tint mask into a BC7
   single-component RGB (R=mask, GB=0,0) as a fallback.

3. **Emissive energy**: Set `emission_energy` to 3.0 on the body material. The
   emissive map bakes raw `#FFB800` at full brightness; the 3.0 multiplier is
   applied only in the material resource, not in the texture values.

4. **ORM texture slot**: In StandardMaterial3D, the ORM texture uses the
   "Ambient Occlusion / Roughness / Metallic" combined texture slot introduced
   in Godot 4.x. Confirm the slot name in Godot 4.6 and verify the channel
   mapping (R=AO, G=Rough, B=Metal) matches the engine's expected channel order.
   If the order has changed in 4.6 (post-knowledge-cutoff version), verify against
   the official Godot 4.6 docs before wiring.

5. **Texture path resolution**: Source textures are at
   `src/assets/textures/heroes/pudge/`. When creating .tres material resources in
   Godot, use `res://src/assets/textures/heroes/pudge/body_basecolor.png` as the
   resource path format. Confirm this matches the Godot project structure at
   `src/project.godot`.

6. **LOD impostor generation**: LOD3 impostor billboard generation is the
   technical-artist's responsibility in Stage 8 per the model spec. The impostor
   output is `src/assets/textures/heroes/pudge/body_impostor.png` (1024 x 128 px
   or 512 x 256 px, 8-frame sprite sheet). This file is NOT in the texture-artist's
   deliverable for Stage 4.

---

*End of Pudge Stage 3 Material / Texture Spec. Requires texture-artist review and
technical-artist sign-off before Stage 4 bake begins.*
