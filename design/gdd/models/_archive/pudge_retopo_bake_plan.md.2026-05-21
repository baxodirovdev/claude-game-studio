# Pudge — Retopo + Bake Plan (Stage 2 Addendum)

> **Status**: DRAFT — pending character-artist sign-off
> **Hero ID**: `pudge`
> **Addendum to**: `design/gdd/models/pudge.md` (Stage 2 Model Spec)
> **Rig spec reference**: `design/gdd/rigs/pudge.md` (Stage 4)
> **Date**: 2026-05-21
> **Working source**: `src/assets/models/heroes/anime_pudge.blend` — object `textured_mesh`

This document is an addendum to the Stage 2 Model Spec. It does NOT restate or
override anything in that spec. It covers only the decisions and procedures that
are specific to this pipeline variant: an AI-generated 40k-tri mesh is the
high-poly bake source instead of a hand sculpt. Every target (polycount, bone
support, UV atlases, naming, orientation) defined in the model spec remains in force.

---

## A. Source Mesh Assessment

### Measured properties of `textured_mesh`

| Property | Measured value |
|---|---|
| Triangle count | 40,000 |
| Vertex count | 27,897 |
| Material slots | 1 — `Material_0` |
| Texture | `Image_0`, 2048 x 2048 px, embedded |
| UV channel | `UVMap` (single channel) |
| Loose parts / islands | 599 disconnected mesh islands |
| Bounding box (Blender units) | ~1.96 W x 1.43 D x 1.96 H |
| Current Z extent | feet near z = −1.0, top near z = +0.96 |
| Import axis | Z-up (glTF default import in Blender) |
| Hook | Fused into body — not a separate object |
| Character style | Chibi / stylized butcher Pudge: pig/boar face, stitched belly, blood splatter |

### Known AI-generation artifacts to expect on this mesh

These are the structural problems a retopologist must navigate. They will NOT
be fixed by remeshing alone.

1. **Island fragmentation** — 599 loose parts is the primary structural problem.
   Interior ear geometry, separate clump islands for hair-like detail, micro-
   islands for buckle studs and chain links. Merging by distance collapses many,
   but some gaps will remain where the AI author intended visible separation (e.g.,
   boot sole crease, belt/torso seam, tooth row).

2. **Non-manifold edges** — AI meshes frequently have coincident faces, zero-area
   triangles, and interior floating faces. Expect these especially at belt/body
   intersection and at the fused hook wrist junction.

3. **Triangle-heavy, deformation-unaware topology** — all 40k tris are raw
   triangles with no edge flow through joints. No concentric loops around eyes,
   mouth, or shoulders. The retopologist gets zero useful topology to inherit;
   treat the AI mesh as a shape reference only.

4. **Fused hook** — the hook is geometrically attached at the wrist. It cannot
   be separated by island selection. See Section C for the reconstruction strategy.

5. **Scale and orientation mismatch** — the mesh is ~2 Blender units tall and
   Z-up. The spec requires 1.4 m (Blender units = meters after Apply Scale) and
   Y-up in the final export. The correction is applied during source prep (Section B),
   NOT during retopo or export.

6. **Inconsistent surface normals** — AI meshes frequently have flipped normals
   inside recessed areas (mouth cavity, eye sockets, boot interior). The high-poly
   bake cage will need increased cage offset in these regions to avoid normal map
   artefacts. Do not recalculate normals on the source; leave it as-is and handle
   via cage expansion.

---

## B. Source Prep Procedure

All steps are performed on `textured_mesh` in `anime_pudge.blend` BEFORE retopo
begins. Do not perform these steps on the retopo mesh. Work on a duplicate of the
source object named `textured_mesh_source_prep` and keep the original untouched.

### B.1 — Axis correction (Z-up to Y-up)

The glTF importer brings the mesh in as Z-up. The spec requires Y-up (forward = -Z).
In Object Mode with `textured_mesh_source_prep` selected:

1. Apply the glTF import rotation: `Object > Apply > All Transforms`. This bakes
   the 90-degree import rotation into the vertex data.
2. Rotate the object −90 degrees around the X-axis in Object Mode so the character
   stands upright in Blender's Y-up convention (feet point down in -Y, top of head
   points in +Y).
3. Apply rotation again: `Object > Apply > Rotation`.
4. Verify: the character's belly should face -Z (forward), feet should be at or near
   Y = 0, top of skull should be the highest Y point.

### B.2 — Scale correction to 1.4 m

Current height after axis correction is approximately 1.96 Blender units.
Target height is 1.4 m (1.4 Blender units, since 1 unit = 1 m per spec §6).

Scale factor = 1.4 / 1.96 = **0.7143** (uniform).

1. With the source prep object selected in Object Mode, set Scale to (0.7143, 0.7143,
   0.7143) in the N-panel Item properties, or use `S > 0.7143 > Enter`.
2. Apply scale: `Object > Apply > Scale`.
3. Verify bounding box: the total height in Blender's Y-axis should be approximately
   1.40 Blender units after apply.

### B.3 — Origin and feet plane

After scaling, the feet are unlikely to be exactly at Y = 0. Correct this:

1. In Edit Mode, select all vertices. Check the minimum Y coordinate in the
   mesh statistics or by selecting the lowest boot-sole vertex.
2. Note the offset value (e.g., lowest Y = −0.03).
3. In Object Mode, move the object upward by that offset (e.g., move +0.03 on Y)
   to bring feet to Y = 0.
4. Apply location: `Object > Apply > Location`.
5. Verify: bottom of boot soles = Y 0.000. Top of skull ≈ Y 1.400.

### B.4 — Merge by distance (reduce island count)

The 599 loose islands must be collapsed to a workable count before baking. This
does NOT need to be watertight for retopo reference — it only needs to be watertight
enough for baking (ray casts must not pass through major open gaps).

1. Enter Edit Mode, Select All.
2. `Mesh > Merge > By Distance`, threshold = **0.001 m** (1 mm). This closes
   micro-gaps from the AI generation that were sub-millimeter but still counted as
   separate islands.
3. Check remaining island count with `Mesh > Separate > By Loose Parts` on a
   temporary duplicate — confirm the count has dropped significantly (target: under
   60 islands). Rejoin the temporary split immediately.
4. Remaining multi-island clusters that did not merge are intentional AI separations
   (e.g., the hook area, eye spheres, tooth row). Leave those; they will be handled
   by the bake cage.

### B.5 — Watertight patch for baking

Merge by distance alone will leave open holes (missing faces at the interior of the
mouth, eye sockets, and any micro-mesh that was discarded). These open holes cause
ray leaks in the normal bake.

Strategy: use a Remesh modifier (Voxel mode) on a secondary high-poly bake duplicate
named `textured_mesh_bake_hp` to produce a fully watertight mesh for the normal and
AO bakes. The original `textured_mesh_source_prep` is kept as visual reference and
for base-color projection.

**Voxel remesh settings for `textured_mesh_bake_hp`:**
- Voxel Size: **0.003 m** (3 mm). At 1.4 m total height this gives approximately
  466 voxels of vertical resolution — sufficient to preserve the pig snout, stitches,
  and belly bulge silhouette while closing all interior holes.
- Smooth Shading: enabled on the remesh result.
- Apply the modifier as a permanent mesh step; do NOT leave it live during baking
  (Blender's bake system requires applied modifiers on the high-poly source).

Tri count after voxel remesh at 3 mm will be roughly 80k–120k tris — this is
acceptable for a high-poly bake source. It is NOT the game mesh.

**Verify the watertight result:** In Edit Mode, use `Select > Select All by Trait >
Non-Manifold`. Zero non-manifold elements = bake-ready. If any remain, fill them
manually with `F` (fill face) or use `Mesh > Clean Up > Fill Holes`.

---

## C. Hook Separation Strategy

The AI mesh has the hook fused at the left wrist. There is no clean separation
boundary in the mesh topology. Attempting to lasso-select and separate will
produce an irregular broken stub at the wrist, not a usable prop.

**Decision: model `mesh_pudge_hook` from scratch as a fresh low-poly object.**

Rationale: the AI mesh's hook is a rough sculptural mass with triangulated
cross-sections, not a clean iron J-curve. The spec requires a deliberate 600-tri
hook prop with a distinct chain portion. Extracting the fused geometry and retopologizing
it would cost more time than blocking a fresh hook prop, and the result would be
lower quality (the AI hook does not have a distinct inner curve blood zone or chain
socket geometry that the texture-artist needs).

### Fresh hook modeling procedure

1. In the working file, create a new object named `mesh_pudge_hook` (spec §10).
2. Use the AI mesh's hook silhouette as a reference in orthographic front and side
   views — Overlay the AI mesh at 30% opacity.
3. Block the J-curve from a cylinder (8-sided), bend it into the hook arc using the
   Bend operator or curve-modifier workflow, then clean up to quad topology.
4. Polycount target: **600 tris** (spec §1). Budget breakdown per spec §5:
   - Hook body bar (J-curve): ~300 tris
   - Inner curve / tip (blood zone): ~120 tris — slightly higher density because
     the blood staining UV island sits here
   - Chain link socket stub (1-2 links physically on the prop): ~180 tris
5. UV unwrap to the 512 x 512 hook atlas (spec §5) immediately after modeling,
   before joining into the scene hierarchy.
6. The hook prop does NOT receive a bake from the AI mesh. Its normal map will be
   hand-authored or baked from a simple high-poly bevel pass on the fresh model.
   The AI mesh contributes nothing useful to the hook bake.

### Masking the fused hook on the bake source

The AI mesh's hook region must not contribute to the body bake (it will produce
incorrect normals on the left hand if the hook mass is present during the bake).

On `textured_mesh_bake_hp`, in Edit Mode, select all geometry approximately below the
left wrist joint (roughly Y < 0.38 m on the left arm) and delete it. This creates
a clean truncation at the wrist. The left hand fist geometry is what matters for the
body bake; the hook stub is excluded.

---

## D. Retopology Approach

### Method: Manual retopo in Blender using Snap to Surface + Shrinkwrap

**Rationale for manual over auto (QuadRemesher / Quadriflow):**

Quadriflow and QuadRemesher produce good results for organic surfaces without
hard deformation constraints. However, this asset has the following requirements
that defeat auto-retopo at the target budget:

- Minimum loop counts per joint (4 loops left shoulder, 6 belly rings) that auto
  tools do not respect from a constraint map without extensive post-correction.
- The belly sphere requires a specific concentric ring topology (3 above equator,
  1 at equator, 2 below) that auto retopo randomizes.
- The no-neck hunch geometry (a 4-quad compressed stub, NOT a full neck tube)
  is a hard topological decision that auto tools universally expand into a full
  neck column.
- Eye and mouth loops (5 concentric eyes, 4 concentric mouth) are non-negotiable
  for the rig spec and are topological decisions, not density decisions.
- Budget is 5,500 tris for the body (spec §1) — Quadriflow at this density will
  be topologically reasonable but requires a full retopo correction pass anyway.

For this asset, manual retopo is the correct tool. QuadRemesher may be used for a
reference pass on the boot, arm cylinder, and belt regions only, to save time on
geometrically simple forms. Any auto-retopo output must be hand-corrected to enforce
deformation loops before being accepted.

### Retopo workflow

1. Add a Shrinkwrap modifier (Project mode) to the retopo mesh targeting
   `textured_mesh_bake_hp`. Enable "On Cage" for real-time projection.
2. Begin with the body silhouette landmarks: head mass, belly sphere, hip block,
   leg cylinders, boot boxes. These large forms establish proportional scale
   before any joint topology is placed.
3. Build joint topology in this order (highest deformation risk first):
   - Left shoulder socket: 4 concentric loops around the joint. Verify loops
     are fully closed rings, not open edge fans.
   - Right shoulder socket: 3 loops.
   - Belly sphere: 6 horizontal rings (3 above equator, 1 at equator, 2 below),
     8 vertical columns. This is the `BellyJiggle` influence region.
   - Mouth: 4 concentric quad loops, centered on the mouth opening.
   - Eyes: 5 concentric quad loops each eye. Left eye outermost loop ~15% wider
     diameter than right eye (asymmetry per spec §2 — live in sculpt shape, same
     loop count).
   - Hips: 4 loops spanning the pelvis mass, transitioning into the upper legs.
   - Left elbow, right elbow: 3 loops each.
   - Knees: 3 loops each.
   - Left wrist, right wrist: 2 loops each.
   - Ankles: 2 loops each.
4. Fill remaining body panels (torso back, upper leg cylinders, boot sides)
   with quads flowing from the established joint loops.
5. Apply the no-neck hunch: 4-quad compressed ring, 1 vertical segment only.
   Force a UV seam at the base of the skull if needed; do NOT add neck height.
   See spec §2 for the explicit constraint on this region.
6. Teeth row: a single 8-quad-wide, 1-quad-tall strip per jaw edge, upper and
   lower (32 tris total per spec §2). This is a geometry strip, not sculpted
   individual teeth.
7. Eye spheres: two 6-sided sphere cap objects, merged into body mesh last.
   Scale left sphere ~15% larger in X and Y before merge.
8. Remove Shrinkwrap modifier (or apply it) when retopo mesh is complete.
9. Confirm quad-only on all deforming surfaces. Tris permitted only at:
   - Pole caps at the top of the gut sphere (hidden inside torso overlap)
   - Boot sole interior (fully occluded)
   - Mouth cavity interior (dark / occluded at game camera)

### Expected AI-mesh topology problems during retopo

These will interfere with surface snapping and must be navigated:

- **No edge flow at joints**: the AI mesh has random triangle borders at every
  joint. The retopo artist will see no surface crease to follow. Use the silhouette
  and the spec's joint positions as guides; ignore the underlying AI triangle structure.
- **Surface noise at stitches and blood splatter**: the AI mesh has slight geometry
  bumps at the belly stitches. These will read as the retopo mesh snapping to
  micro-bumps. This is fine — the normal bake will capture this as texture detail.
- **Inconsistent eye socket depth**: the AI eye sockets may be shallow or inconsistent.
  Model the eye concentric loops to spec; do not try to match the AI mesh's socket
  depth exactly if it contradicts the spec's proportions.
- **Hook wrist stub (after masking)**: the wrist area of the bake source will be
  flat-capped where the hook was deleted. The retopo wrist geometry should follow
  the fist shape from the adjacent forearm topology, not the flat cap.

---

## E. UV Plan

The AI mesh UV (`UVMap`) is NOT reused. It is the source texture's native layout,
tightly packed for AI rendering efficiency, and has no relationship to the spec's
atlas layout or texel density requirements.

**Both `mesh_pudge_body` and `mesh_pudge_hook` are fully re-unwrapped after retopo.**

### Body atlas — 1024 x 1024 (`mat_pudge_body`)

Follow spec §4 exactly:

| Quadrant | Content | Texel density |
|---|---|---|
| Top-left | Face island (35%) + skull sub-island (10%) | 512 px/m (face), 256 px/m (skull) |
| Top-right | Torso front (25%) + apron stub sub-island | 256 px/m |
| Bottom-left | Arms + hands (left arm taller island than right) | 256 px/m |
| Bottom-right | Legs + boots + belt strip + chain link strip | 128 px/m legs, 256 px/m boots/belt |

Mirroring rules (spec §4):
- Legs: mirrored UV, one island.
- Boots: mirrored UV, one island.
- Arms: NOT mirrored (hook arm is visibly chunkier).
- Torso left/right: NOT mirrored (stitch layout is asymmetric).
- Face: NOT mirrored (eye asymmetry).

Seam placement:
- Head: seam at back-of-skull center (hidden from top-down camera).
- Torso: seam along the center-back spine column.
- Arms: seam along the inner arm (axilla / underarm — facing body, not camera).
- Legs: seam along the inner thigh (occluded by gut overhang).
- Boots: seam at boot back (rear-facing at camera).
- Belt: seam at back-center of belt band.

Run Blender's UV Pack Islands with **8 px margin** at 1024 resolution before
handoff to texture-artist. Verify no island bleeds at MIP level 2 (256 x 256).

### Hook atlas — 512 x 512 (`mat_pudge_hook`)

Fresh model, fresh unwrap. Follow spec §5 layout:
- Hook body bar: top half of atlas (~60%).
- Inner curve / tip (blood zone sub-region): within hook body island.
- Chain link 1 (hand-adjacent): bottom-left quadrant.
- Chain link 2: bottom-center-left.
- Chain link 3: bottom-center-right.
- Chain link 4 (belt-coil end): bottom-right.

---

## F. Bake Plan

### Bake target files (spec §10 naming)

| File | Resolution | Bake type | Source → Target |
|---|---|---|---|
| `pudge_body_normal.png` | 1024 x 1024 | Tangent-space normal | `textured_mesh_bake_hp` → `mesh_pudge_body` |
| `pudge_body_basecolor.png` | 1024 x 1024 | Diffuse (emit mode) | `textured_mesh_source_prep` texture projected → `mesh_pudge_body` |
| `pudge_body_orm.png` | 1024 x 1024 | AO (R channel) + hand-paint R/M (G/B channels) | `textured_mesh_bake_hp` + both meshes for AO |
| `pudge_hook_normal.png` | 512 x 512 | Tangent-space normal | Fresh high-poly bevel pass → `mesh_pudge_hook` |
| `pudge_hook_basecolor.png` | 512 x 512 | Hand-painted | N/A — no AI source for hook |
| `pudge_hook_orm.png` | 512 x 512 | AO (R channel) + hand-paint R/M | Combined scene bake |

### Bake scene setup

1. In the working file, keep `mesh_pudge_body` (retopo, LOD0 only), and
   `textured_mesh_bake_hp` (watertight voxel remesh source).
2. Disable all modifiers on `mesh_pudge_body` before bake (Shrinkwrap must be
   off or applied; subdivision if any must be applied).
3. Blender cycles bake mode: **Selected to Active**. `textured_mesh_bake_hp` is
   the high-poly source; `mesh_pudge_body` is the active low-poly target.
4. Ensure both meshes are overlapping in the same world position (they should be,
   since the retopo was shrink-wrapped onto the source).

### Cage settings

The voxel remesh introduces slight surface inflation over the original AI mesh.
A cage is required to prevent ray misses on concave areas.

- **Cage object**: create a cage by duplicating `mesh_pudge_body`, then uniformly
  pushing all vertices outward by **0.02 m** (2 cm) along normals using
  `Mesh > Transform > Shrink/Fatten > 0.02`. Name it `mesh_pudge_body_cage`.
- **Concave regions** (eye sockets, mouth interior, armpit): the 2 cm offset is
  usually sufficient. If any of these areas still show ray leaks (dark spots or
  incorrect normals), locally increase the cage offset to **0.04 m** by
  proportionally editing those vertices in the cage.
- **Ray distance**: set to **0.06 m** (6 cm) in the Bake settings. This is generous
  enough to capture the belly stitch bumps and boot sole raised edges from the AI
  mesh without picking up opposite-side faces.
- **Extrusion fallback**: if the cage object method produces artefacts, switch to
  Blender's built-in Extrusion value in the Bake panel (set to 0.02, Max Ray
  Distance to 0.06). The cage object method is preferred for this asset because the
  AI mesh's inconsistent normals make the auto-extrusion unreliable at deep cavities.

### Normal bake quality notes

**What will bake cleanly:**
- Belly stitch bumps and stitch holes — the AI mesh has clear geometry bumps here
  that will transfer well to the low-poly belly plane.
- Pig/boar snout wrinkles and nostril recesses.
- Boot sole raised ridges and wear creases.
- Belt buckle surface bevel.
- Blood splatter surface relief (minimal — mostly a diffuse detail).

**What requires hand-correction after baking:**
- Eye socket transition — the AI eye geo is inconsistent in depth. Expect a soft
  transition in the normal map at the eye socket rim. The texture-artist may need
  to paint-correct the eye socket normal in Substance Painter or equivalent to
  match the spec's emissive eye region.
- Mouth interior — the watertight remesh will fill the mouth cavity with a
  smooth dome. The resulting normal bake at the tooth row strip will be a flat
  surface normal, not a tooth-row detail. Tooth detail is painted (per spec §2,
  teeth are not geometry-authored — this is confirmed and intentional).
- Wrist / hook area — the truncated bake source at the wrist will produce a flat
  cap normal at the fist base. This region is mostly occluded by the hook prop
  geometry at game camera distance. Acceptable; no correction needed.
- Back torso panel — the AI mesh has no surface detail on the back. The normal
  bake will be nearly flat. The texture-artist should treat the back as a
  paint-only region with no normal-map contribution from the bake.

### Base color projection

The AI mesh has a baked 2048 x 2048 texture (`Image_0`). This carries the original
AI author's material coloring: pig skin tones, blood splatter, stitches, metal chain.
Project this to the new UV layout to provide the texture-artist a starting point
(not a final deliverable — final base color is hand-painted per spec).

**Projection method**: Multi-resolution bake from `textured_mesh_source_prep`
(with its original `UVMap` and `Material_0` texture active) to `mesh_pudge_body`
(with the new UV layout and a blank target image). Use Blender's **Emit** bake
mode with the source material's `Image_0` connected to an Emission shader node.
This projects the AI texture onto the new UVs via ray-cast, giving a rough color
guide that the texture-artist will repaint to match the concept material table.

Deliver this as `pudge_body_basecolor_ai_projection.png` (1024 x 1024) alongside
the spec-named `pudge_body_basecolor.png` (which the texture-artist will produce
as the final hand-painted version). Do not rename the AI projection to the spec
filename — it is reference only.

### AO bake — combined scene requirement

This carries forward the requirement from spec §5 (open question 5 for texture-
artist). AO for both `mat_pudge_body` and `mat_pudge_hook` must be baked in the
same Blender scene with both mesh objects present and in their correct relative
positions (hook prop at the left hand). The hand-to-hook contact zone will have
incorrect AO shadow if baked separately.

AO samples: 64 minimum. AO distance: 0.3 m (matches the belly equator radius —
keeps AO from darkening the back unnecessarily). Bake AO into the R channel of
`pudge_body_orm.png` and `pudge_hook_orm.png`.

---

## G. jiggle_boundary Vertex Color Annotation

This annotation is **Blocker A** for the rigging-animator (rig spec §14, Blocker A).
The retopo artist must paint this before UV unwrap handoff.

### Specification

- **Layer name**: `jiggle_boundary` (exact string — rig spec §4.1 is authoritative).
- **Color encoding**:
  - Red (RGB 1.0, 0.0, 0.0) = 100% BellyJiggle influence. Paint this on:
    - The belly equator ring (the 1 ring at maximum circumference, spec §2).
    - The 2 forward-facing lower rings below the equator.
  - White (RGB 1.0, 1.0, 1.0) = 0% BellyJiggle influence. Paint this on:
    - The 3 rings above the equator (transitioning to torso).
    - The hip-pelvis join rings at the bottom of the belly sphere.
  - Interpolate smoothly across the 1-ring transition bands between 100% and 0%.
    Use the Blur tool in Vertex Paint mode at low strength to smooth the gradient.
- **Scope**: paint on `mesh_pudge_body` only. The hook prop has no jiggle boundary.
- **Timing**: paint after retopo geometry is finalized, before UV unwrap. The vertex
  color layer survives UV unwrap and Join operations and will be present in the
  delivered blend file.

### Delivery verification

In the handoff file, the rigger can verify the layer exists by:
`Properties > Object Data Properties > Color Attributes` — confirm `jiggle_boundary`
appears in the list with Domain = Vertex, Data Type = Byte Color or Float Color.

The rigger reads this layer and maps it directly to the BellyJiggle bone weight:
maximum BellyJiggle influence is 80% (not 100%), with Spine1 at 20% minimum
on the equator ring — the rigger applies this scaling; the character-artist paints
the raw gradient to full red/white without the 80% cap applied.

---

## H. LOD Generation

LOD0 is the retopo result from Section D. LOD1 and LOD2 are derived from LOD0,
not from the AI source.

### LOD1 — target ~3,050 tris

Generated by:
1. Applying a Decimate modifier (Planar mode, Angle Limit 5 degrees) on a duplicate
   of `mesh_pudge_body_lod0` to remove flat-panel redundancy on the torso back,
   arm cylinders, and boot sides.
2. Manual collapse of the features listed in spec §7:
   - Chain links: collapse 4 toroids to a single twisted quad strip (~40 tris).
   - Teeth row: replace the geometry strip with a single recessed quad.
   - Boot lace stubs: delete the quad strips.
   - Eye spheres: replace 6-sided caps with flat discs (24 tris total).
   - Belt buckle: collapse geometry box to a flat painted quad on the belt strip.
   - Apron stub: delete; edge on belt strip receives the painted apron at this LOD.
3. Name the result `mesh_pudge_body_lod1` (spec §11, blender-specialist note 3).
4. Verify the `jiggle_boundary` vertex color layer is present on LOD1 — it should
   survive the Decimate + manual collapse, but check after each collapse operation.

### LOD2 — target ~1,500 tris

Generated by:
1. Start from `mesh_pudge_body_lod1`.
2. Apply a stronger Decimate pass (Collapse mode, Ratio 0.5 applied iteratively
   with visual check after each pass — do not apply a single 50% reduction blindly).
3. Manual reductions per spec §7:
   - Collapse hook arm asymmetry — both arms use identical polygon count.
   - Boot toe splay → simple rounded rectangular prism.
   - Belly rings: reduce from 6 to 3 (delete 3 rings, bridge the gaps).
   - Shoulder loops: reduce to 2 per shoulder.
   - Face loops: reduce to 3 eye, 3 mouth.
4. **Critical**: after reducing belly rings to 3, repaint the `jiggle_boundary`
   vertex color layer on LOD2. The equator ring is now at a different ring index.
   The gradient must be re-established on the 3-ring layout (1 ring at equator at
   100%, 0.5 ring above and below at 50%, outermost rings at 0%).
5. Name `mesh_pudge_body_lod2`.

### LOD3 — impostor billboard

Not produced by the character-artist. Per spec §7: the technical-artist generates
the impostor sprite sheet from a LOD2 render in Stage 8. No action required here.

### Hook prop LODs

- `mesh_pudge_hook_lod0`: 600 tris (fresh model, Section C).
- `mesh_pudge_hook_lod1`: ~300 tris — remove inner curve bevel, reduce chain link
  count to 2. Apply Decimate on a duplicate.
- `mesh_pudge_hook_lod2`: ~150 tris — box + single arc representing the J-curve,
  no chain detail.

---

## I. Open Risks and Blockers Specific to AI-Source Retopo

### Risk 1 — Belly topology mismatch with AI surface

The AI mesh's belly is a rough bulge, not a mathematically clean sphere. The
6-ring concentric layout required by the spec will not perfectly follow the AI
surface contour in places. The retopo artist must prioritize spec compliance
over surface conformance: where the spec's loop layout conflicts with the AI surface
shape, follow the spec. The bake will capture the AI surface detail via normal map
regardless of the retopo loop layout.

Severity: LOW. Expected outcome: minor normal map waviness in the belly-to-hip
transition region. Acceptable at game camera distance. Flag to texture-artist
if any belly stitch island shows Z-fighting in the bake.

### Risk 2 — Fused hook geometry in bake source causes wrist artefacts

The wrist region of `textured_mesh_bake_hp` was truncated (Section B.5 / C).
The truncation cap may produce an incorrect normal at the fist base if the cap
faces are pointing inward. After truncating and before baking:

Check the wrist cap normals in `textured_mesh_bake_hp`. If they face inward
(shown as dark blue in face orientation overlay), flip them. Then add a small
outward extrusion on the cap edge (2 mm) to round the truncation and prevent
a hard normal seam on the baked fist.

Severity: MEDIUM. If missed, the left hand base will have a visible normal map
seam that the texture-artist cannot paint over. Must be resolved before the normal
bake pass.

### Risk 3 — 599-island source means unpredictable ray-cast behaviour

Even after Merge by Distance and voxel remesh, some internal faces from the AI
mesh may remain inside `textured_mesh_bake_hp` (the remesh closes the surface but
may entrap interior geometry). Interior faces cause random dark spots in the AO bake.

Verify before baking: select all in `textured_mesh_bake_hp`, then `Select > All by
Trait > Interior Faces`. If any are selected, delete them. This is a manual step
that cannot be automated by the remesh.

Severity: MEDIUM. Interior faces are common in AI-generated meshes. Expect to spend
15-30 minutes on cleanup. This is not optional — interior face AO contamination
cannot be fixed in the texture-paint stage.

### Risk 4 — Base color projection quality

The AI texture (`Image_0`) was authored for the AI mesh's UV layout and may have
seam burn-in, resolution loss at island boundaries, and AI-generation compression
artifacts. The projection onto the new UV layout (Section F, base color projection)
will re-introduce seams along the new island boundaries.

Expectation: the projected base color is a ROUGH GUIDE only. The texture-artist must
repaint it, not use it directly. Communicate this clearly in the texture handoff notes.
Do not describe the projection as a finished texture.

Severity: LOW for pipeline (expected), HIGH for texture-artist time if they assume
the projection is usable without repainting.

### Risk 5 — Corrective blendshape for left shoulder (Blocker B from rig spec)

The rig spec §14 Blocker B is contingent: if QA pose QA1 (left arm raised 45 degrees)
reveals pinching at the 4-loop left shoulder, the character-artist must deliver a
corrective blendshape named `correct_leftarm_raised` on `mesh_pudge_body`. Since the
AI mesh has no deformation-aware topology in the shoulder, the retopo artist should
build the 4-loop shoulder with extra care and test the shoulder raise at 45 degrees
immediately after skinning a rough bind (even a Blender Automatic Weights bind is
sufficient for a topology stress test). If pinching is found:

1. Sculpt the corrective shape in the raised-arm position.
2. Store it as a Shape Key named `correct_leftarm_raised`.
3. Confirm to the rigging-animator so they can drive it from the LeftArm Z-axis
   rotation per rig spec §14 Blocker B.

Severity: MEDIUM. The 4-loop count should hold for a chibi-proportioned arm, but
the AI source's shoulder mass may be wider or more irregular than a clean sculpt,
requiring the retopo artist to make judgment calls about loop placement.

### Blocker for rigging-animator: `jiggle_boundary` layer

This addendum confirms the delivery commitment: the `jiggle_boundary` vertex color
layer will be present on `mesh_pudge_body` in the handoff blend file. The rigger
must not begin belly weight painting until they have confirmed the layer is present
(Section G, delivery verification). This is Blocker A from rig spec §14.

---

## J. Handoff Checklist

Before handing to rigging-animator, verify all of the following:

- [ ] `textured_mesh_bake_hp` exists in the blend file and is watertight (zero non-manifold)
- [ ] `mesh_pudge_body` (LOD0) tri count is at or under 5,500 (body, without hook)
- [ ] `mesh_pudge_hook` tri count is at or under 600 tris
- [ ] `mesh_pudge_body_lod1`, `mesh_pudge_body_lod1`, `mesh_pudge_body_lod2` all exist and named per spec §10 blender-specialist note 3
- [ ] All mesh objects have Scale (1, 1, 1), Rotation (0, 0, 0), Location (0, 0, 0)
- [ ] Boot sole minimum Y = 0.000
- [ ] Skull top maximum Y ≈ 1.400
- [ ] Forward axis = -Z (belly of Pudge faces -Z in world space)
- [ ] `jiggle_boundary` vertex color layer present on `mesh_pudge_body` LOD0, LOD1, and LOD2
- [ ] `jiggle_boundary` equator ring painted red, transition rings interpolated, torso/hip rings white
- [ ] `mesh_pudge_hook` UV is unwrapped to the 512 x 512 hook atlas layout (spec §5)
- [ ] `mesh_pudge_body` UV is unwrapped to the 1024 x 1024 body atlas layout (spec §4) with 8 px island padding
- [ ] `pudge_body_normal.png` — normal bake completed and verified (no obvious seams or cage leaks on belly / shoulder / eye socket regions)
- [ ] `pudge_body_orm.png` R channel — AO baked in combined scene (both body and hook present)
- [ ] `pudge_hook_normal.png` — baked from fresh high-poly bevel pass
- [ ] `pudge_hook_orm.png` R channel — AO baked in combined scene
- [ ] `pudge_body_basecolor_ai_projection.png` — delivered as reference; clearly labeled NOT FINAL in the file handoff notes
- [ ] No corrective blendshapes authored speculatively — only `correct_leftarm_raised` if QA1 pinch confirmed
- [ ] Working blend file saved to `src/assets/models/heroes/anime_pudge.blend` (source) and canonical working file at `tools/blender/pudge.blend`

---

*End of Pudge Stage 2 Addendum — Retopo + Bake Plan.*
*Changes to the bake strategy, LOD targets, or `jiggle_boundary` encoding must be
propagated to rigging-animator and texture-artist before retopo work begins.*
