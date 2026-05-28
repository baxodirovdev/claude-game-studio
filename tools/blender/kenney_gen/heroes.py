"""Procedural Kenney-style chibi hero models.

Each hero is a single Blender scene (one root Empty plus mesh children)
exported as one GLB. Heroes are designed for top-down/isometric play:
chibi proportions (oversized head, short legs), distinct silhouettes,
flat per-vertex colors. No rigging — heroes are static meshes.

Conventions:
- Pivot at feet (Z=0 in Blender → Y=0 in Godot after Y-up export).
- Forward direction = +Y in Blender → -Z in Godot (matches glTF default).
- Total height ~1.55–1.7 m so it lines up with the player capsule.
"""

import bpy
import bmesh
from mathutils import Vector

from kenney_gen import palette


# --- low-level mesh helpers --------------------------------------------------

def _new_obj(name, mesh):
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def _empty_root(name):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    return root


def _apply_color(mesh, color_name):
    rgb = palette.rgb_for_color(color_name)
    rgba = (rgb[0], rgb[1], rgb[2], 1.0)
    attr = mesh.color_attributes.new(
        name="Col", type='FLOAT_COLOR', domain='CORNER'
    )
    for loop in attr.data:
        loop.color = rgba


def _sphere(name, scale, color, location=(0, 0, 0),
            segments=10, rings=8):
    """Non-uniformly scaled UV sphere — the workhorse for organic body parts."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(
        bm, u_segments=segments, v_segments=rings, radius=0.5,
    )
    for v in bm.verts:
        v.co.x *= scale[0]
        v.co.y *= scale[1]
        v.co.z *= scale[2]
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_color(mesh, color)
    obj = _new_obj(name, mesh)
    obj.location = Vector(location)
    return obj


def _box(name, size, color, location=(0, 0, 0), rotation=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z *= size[2]
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_color(mesh, color)
    obj = _new_obj(name, mesh)
    obj.location = Vector(location)
    obj.rotation_euler = Vector(rotation)
    return obj


def _cone(name, radius_bottom, radius_top, height, color,
          segments=12, location=(0, 0, 0), rotation=(0, 0, 0)):
    """Cone or truncated cone — cape skirts, mage hat tips, robes."""
    bm = bmesh.new()
    bmesh.ops.create_cone(
        bm, cap_ends=True, segments=segments,
        radius1=radius_bottom, radius2=radius_top, depth=height,
    )
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_color(mesh, color)
    obj = _new_obj(name, mesh)
    obj.location = Vector(location)
    obj.rotation_euler = Vector(rotation)
    return obj


def _cylinder(name, radius, height, color,
              segments=12, location=(0, 0, 0), rotation=(0, 0, 0)):
    return _cone(
        name, radius, radius, height, color,
        segments=segments, location=location, rotation=rotation,
    )


# --- ORGANIC mesh helpers (metaballs / skin modifier / subsurf) ---
# These produce smooth fused geometry instead of stacked primitives.

def _select_only(obj):
    """Make obj the active+only-selected object (required for many bpy ops)."""
    for o in bpy.context.scene.objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def _apply_all_modifiers(obj):
    _select_only(obj)
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)


def _shade_smooth(obj):
    _select_only(obj)
    bpy.ops.object.shade_smooth()


def _organic_blob(name, blobs, color_name, resolution=0.05):
    """Build a fused organic body from a list of metaball blobs.

    blobs: list of dicts with 'co' (xyz tuple) and 'radius' (float).
    The metaballs merge into a single smooth mesh on conversion.
    """
    mball = bpy.data.metaballs.new(name + "_mball")
    mball.resolution = resolution
    mball.render_resolution = resolution
    # Default threshold (0.6) shrinks the visible surface to ~0.47×radius;
    # 0.1 makes the mesh form at ~0.88×radius, so radii match real size.
    mball.threshold = 0.1
    obj = bpy.data.objects.new(name, mball)
    bpy.context.collection.objects.link(obj)
    for blob in blobs:
        elem = mball.elements.new(type='BALL')
        elem.co = Vector(blob["co"])
        elem.radius = blob["radius"]
    _select_only(obj)
    bpy.ops.object.convert(target='MESH')
    # In Blender 5.x, convert() removes the metaball object and produces a
    # new mesh object — fetch it from the active context. Then rename so the
    # caller can find it by the original `name`.
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name + "_mesh"
    _apply_color(obj.data, color_name)
    _shade_smooth(obj)
    return obj


def _skin_limb(name, joints, color_name, subsurf_levels=2):
    """Smooth tapered limb via Skin modifier on a vertex chain.

    joints: list of (xyz tuple, radius) — first is root, last is tip.
    """
    verts = [Vector(j[0]) for j in joints]
    edges = [(i, i + 1) for i in range(len(verts) - 1)]
    mesh = bpy.data.meshes.new(name + "_mesh")
    mesh.from_pydata(verts, edges, [])
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    obj.modifiers.new(name="Skin", type='SKIN')
    skin_data = mesh.skin_vertices[0].data
    for i, (_co, r) in enumerate(joints):
        skin_data[i].radius = (r, r)
    skin_data[0].use_root = True

    if subsurf_levels > 0:
        sub = obj.modifiers.new(name="Subsurf", type='SUBSURF')
        sub.levels = subsurf_levels
        sub.render_levels = subsurf_levels

    _apply_all_modifiers(obj)
    _apply_color(obj.data, color_name)
    _shade_smooth(obj)
    return obj


def _smooth_sphere(name, radius, color_name, location=(0, 0, 0),
                   scale=(1.0, 1.0, 1.0), segments=24, rings=16,
                   subsurf_levels=1):
    """Subsurfed UV sphere with smooth shading — for hands, nose, ears, etc."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(
        bm, u_segments=segments, v_segments=rings, radius=radius,
    )
    for v in bm.verts:
        v.co.x *= scale[0]
        v.co.y *= scale[1]
        v.co.z *= scale[2]
    mesh = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = Vector(location)
    if subsurf_levels > 0:
        sub = obj.modifiers.new(name="Subsurf", type='SUBSURF')
        sub.levels = subsurf_levels
        sub.render_levels = subsurf_levels
        _apply_all_modifiers(obj)
    _apply_color(obj.data, color_name)
    _shade_smooth(obj)
    return obj


def _smooth_torus(name, major_radius, minor_radius, color_name,
                  location=(0, 0, 0), major_seg=24, minor_seg=12):
    """Smooth-shaded torus — used for the leather belt."""
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_radius,
        minor_radius=minor_radius,
        major_segments=major_seg,
        minor_segments=minor_seg,
        location=location,
    )
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name + "_mesh"
    _apply_color(obj.data, color_name)
    _shade_smooth(obj)
    return obj


def _eye_pair(parent, name_prefix, head_z, head_front_y, scale, color,
              spread=0.10, pupil_color="black"):
    """Two small spheres + black pupils on the front of the head."""
    for sx_label, sx in (("l", -spread), ("r", spread)):
        white = _sphere(
            f"{name_prefix}_eye_{sx_label}",
            scale=(scale, scale * 0.6, scale),
            color=color,
            location=(sx, head_front_y, head_z),
        )
        white.parent = parent
        pupil = _sphere(
            f"{name_prefix}_pupil_{sx_label}",
            scale=(scale * 0.45, scale * 0.45, scale * 0.45),
            color=pupil_color,
            location=(sx, head_front_y + scale * 0.3, head_z),
        )
        pupil.parent = parent


def _join_descendants_into(root_empty, joined_name, target_tris=None):
    """Join every mesh descendant of root_empty into a single mesh object.

    Required for Mixamo auto-rig (single skinnable mesh per upload).
    The resulting mesh keeps per-vertex colors and is parented back to
    nothing (root mesh in scene). The original Empty is removed.

    If target_tris is given, applies a Decimate (Collapse) modifier sized
    to hit roughly that triangle count. Decimate is applied (not left as
    a modifier) so the GLB export carries the simplified mesh.

    Returns the joined mesh object.
    """
    meshes = [c for c in root_empty.children_recursive if c.type == 'MESH']
    if not meshes:
        return None
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    joined = bpy.context.active_object
    joined.parent = None
    joined.name = joined_name
    joined.data.name = joined_name + "_mesh"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.data.objects.remove(root_empty, do_unlink=True)

    if target_tris is not None:
        current_tris = sum(
            len(p.vertices) - 2 for p in joined.data.polygons
        )
        if current_tris > target_tris:
            ratio = max(target_tris / current_tris, 0.005)
            mod = joined.modifiers.new(name="Decimate", type='DECIMATE')
            mod.decimate_type = 'COLLAPSE'
            mod.ratio = ratio
            mod.use_collapse_triangulate = True
            _select_only(joined)
            bpy.ops.object.modifier_apply(modifier=mod.name)

    return joined


# --- HERO 1: PUDGE (PULL — Dota 2 chibi butcher) ----------------------------

def make_hero_pudge(name="hero_pudge"):
    """Organic chibi Dota-2 Pudge. Body and head are single fused metaball
    meshes (no Lego look), limbs are skin-modifier tapered tubes, all
    smooth-shaded. Hard accessories (cleaver, hook chain, scars, eyes,
    mouth stitches) stay as crisp primitives so they read sharply."""
    root = _empty_root(name)
    skin = "pudge_skin"
    skin_dark = "pudge_skin_dark"
    leather = "wood_dark"
    iron = "metal_dark"
    stitch = "wood_dark"

    # === ORGANIC BODY (one fused metaball mesh) =================
    # Belly + chest + hips + shoulders + neck all blend into one blob.
    # Belly mass is pushed strongly forward (+Y) for the signature Pudge
    # bulge. Love handles are dialed back so they don't read as wings.
    _organic_blob(f"{name}_body", [
        # Lower belly bulge (huge, far forward)
        {"co": (0,    0.30, 0.78), "radius": 0.55},
        # Upper belly bulge (forward, slightly higher)
        {"co": (0,    0.22, 0.96), "radius": 0.45},
        # Pelvis / hip core (sits back, narrower)
        {"co": (0,   -0.05, 0.50), "radius": 0.36},
        # Mid-back support (so the back is filled in behind the belly)
        {"co": (0,   -0.18, 0.82), "radius": 0.35},
        # Side love-handles (smaller, pulled in)
        {"co": (-0.36, 0.05, 0.85), "radius": 0.20},
        {"co": ( 0.36, 0.05, 0.85), "radius": 0.20},
        # Upper torso / chest (sits above & behind the belly)
        {"co": (0,    0.0,  1.16), "radius": 0.40},
        # Sagging man-pecs (forward, on top of belly bulge)
        {"co": (-0.18, 0.30, 1.06), "radius": 0.15},
        {"co": ( 0.18, 0.30, 1.06), "radius": 0.15},
        # Massive shoulder bulges
        {"co": (-0.40, 0.0,  1.22), "radius": 0.22},
        {"co": ( 0.40, 0.0,  1.22), "radius": 0.22},
        # Stub neck
        {"co": (0,   -0.02, 1.40), "radius": 0.14},
    ], color_name=skin, resolution=0.035).parent = root

    # === ORGANIC HEAD (separate fused metaball mesh) =============
    # Wider-than-tall (Pudge has a flat, squashed cranium) with the jaw
    # protruding well past the upper face.
    _organic_blob(f"{name}_head_blob", [
        # Main cranium — wider than tall (Pudge silhouette)
        {"co": (0,    0.0,  1.66), "radius": 0.28},
        # Side bulges to widen the head
        {"co": (-0.18, 0.0,  1.66), "radius": 0.18},
        {"co": ( 0.18, 0.0,  1.66), "radius": 0.18},
        # Cranial lump on back-left (deformed skull)
        {"co": (-0.22, -0.10, 1.68), "radius": 0.12},
        # Protruding underbite jaw — pushed FURTHER forward & down
        {"co": (0,    0.30, 1.40), "radius": 0.22},
        # Fleshy chin lobe (still further forward, lower)
        {"co": (0,    0.38, 1.32), "radius": 0.12},
        # Cheek bulges
        {"co": (-0.22, 0.20, 1.50), "radius": 0.13},
        {"co": ( 0.22, 0.20, 1.50), "radius": 0.13},
    ], color_name=skin, resolution=0.025).parent = root

    # === ARMS via Skin modifier (smooth tapered tubes) ===========
    # Three joints: shoulder → elbow → wrist with tapering radii.
    _skin_limb(f"{name}_arm_l", [
        ((-0.45,  0.0,  1.18), 0.18),   # shoulder
        ((-0.62,  0.06, 0.86), 0.20),   # elbow (forearm bulges out)
        ((-0.70,  0.14, 0.50), 0.16),   # wrist
    ], color_name=skin).parent = root
    _skin_limb(f"{name}_arm_r", [
        (( 0.45,  0.0,  1.18), 0.18),   # shoulder
        (( 0.62,  0.06, 0.86), 0.20),   # elbow
        (( 0.70,  0.20, 0.50), 0.16),   # wrist (forward to hold cleaver)
    ], color_name=skin).parent = root

    # === HANDS (smooth subsurfed spheres) =======================
    _smooth_sphere(f"{name}_hand_l", radius=0.13, color_name=skin,
                   location=(-0.72, 0.16, 0.42),
                   scale=(1.0, 1.1, 0.85)).parent = root
    _smooth_sphere(f"{name}_hand_r", radius=0.13, color_name=skin,
                   location=( 0.72, 0.22, 0.42),
                   scale=(1.0, 1.1, 0.85)).parent = root

    # === LEGS via Skin modifier (smooth pant tubes) =============
    _skin_limb(f"{name}_leg_l", [
        ((-0.22, 0.0,  0.46), 0.20),   # hip
        ((-0.22, 0.02, 0.22), 0.17),   # knee
        ((-0.22, 0.04, 0.10), 0.14),   # ankle
    ], color_name=leather).parent = root
    _skin_limb(f"{name}_leg_r", [
        (( 0.22, 0.0,  0.46), 0.20),
        (( 0.22, 0.02, 0.22), 0.17),
        (( 0.22, 0.04, 0.10), 0.14),
    ], color_name=leather).parent = root

    # === HEAVY BOOTS (kept primitive, hard edges) ===============
    _box(f"{name}_boot_l", (0.28, 0.38, 0.14), "rock_dark",
         location=(-0.22, 0.08, 0.07)).parent = root
    _box(f"{name}_boot_r", (0.28, 0.38, 0.14), "rock_dark",
         location=( 0.22, 0.08, 0.07)).parent = root
    for sx in (-0.22, 0.22):
        _box(f"{name}_boot_band_{int(sx*100)}", (0.29, 0.05, 0.06),
             iron, location=(sx, 0.16, 0.10)).parent = root

    # === BELT (smooth torus) + SKULL BUCKLE =====================
    _smooth_torus(f"{name}_belt", major_radius=0.62, minor_radius=0.07,
                  color_name=leather,
                  location=(0, 0, 0.46)).parent = root
    # Skull buckle (smooth)
    _smooth_sphere(f"{name}_buckle_skull", radius=0.10, color_name="bone",
                   location=(0, 0.50, 0.48),
                   scale=(1.0, 0.7, 1.0)).parent = root
    # Skull eye sockets
    _sphere(f"{name}_buckle_eye_l", (0.025, 0.025, 0.025), "black",
            location=(-0.040, 0.55, 0.49),
            segments=6, rings=6).parent = root
    _sphere(f"{name}_buckle_eye_r", (0.025, 0.025, 0.025), "black",
            location=( 0.040, 0.55, 0.49),
            segments=6, rings=6).parent = root
    _box(f"{name}_buckle_nose", (0.022, 0.022, 0.030), "black",
         location=(0, 0.55, 0.45)).parent = root
    # Belt rivets
    for i in range(5):
        x = -0.30 + i * 0.15
        if abs(x) < 0.10:
            continue
        _smooth_sphere(f"{name}_belt_rivet_{i}", radius=0.020,
                       color_name=iron,
                       location=(x, 0.45, 0.46)).parent = root

    # === BLOODY APRON (single curved sheet) =====================
    # Smooth-shaded squashed sphere draped just in front of the belly.
    # Sized to cover lower belly + belt only, leaving upper belly
    # visible so the X-stitch scar reads as Pudge's signature feature.
    _smooth_sphere(f"{name}_apron", radius=0.42, color_name="blood",
                   location=(0, 0.92, 0.74),
                   scale=(1.30, 0.20, 0.85)).parent = root
    # Apron stains (sit on the apron front at y~1.05)
    _smooth_sphere(f"{name}_apron_stain_a", radius=0.06,
                   color_name=leather,
                   location=(-0.14, 1.06, 0.85),
                   scale=(1.4, 0.3, 0.9)).parent = root
    _smooth_sphere(f"{name}_apron_stain_b", radius=0.05,
                   color_name=leather,
                   location=( 0.18, 1.06, 0.95),
                   scale=(1.0, 0.3, 1.6)).parent = root
    _smooth_sphere(f"{name}_apron_drip", radius=0.030,
                   color_name="blood",
                   location=(-0.06, 1.07, 0.58),
                   scale=(0.8, 0.5, 2.0)).parent = root
    # Neck strap (over chest, in front of body)
    _box(f"{name}_apron_strap", (0.06, 0.06, 0.36), "blood",
         location=(0, 0.42, 1.28)).parent = root

    # === HOOK ON CHAIN at right hip =============================
    chain_xs = 0.40
    for i in range(5):
        cz = 0.42 - i * 0.05
        _smooth_sphere(f"{name}_chain_{i}", radius=0.030, color_name=iron,
                       location=(chain_xs, 0.36, cz)).parent = root
    # Hook curve (quarter-arc)
    for i in range(5):
        ang = i / 4.0
        cx = chain_xs - 0.07 * ang
        cy = 0.36 + 0.06 * ang
        cz = 0.10 - 0.05 * (1 - (1 - ang) ** 2)
        _smooth_sphere(f"{name}_hook_curve_{i}", radius=0.034,
                       color_name=iron,
                       location=(cx, cy, cz)).parent = root
    # Hook tip
    _cone(f"{name}_hook_tip", radius_bottom=0.028, radius_top=0.001,
          height=0.09, color=iron,
          location=(chain_xs - 0.10, 0.44, 0.16),
          rotation=(0, 0.5, 0)).parent = root
    # Rust spot
    _smooth_sphere(f"{name}_hook_rust", radius=0.024, color_name="fur_orange",
                   location=(chain_xs, 0.36, 0.08),
                   scale=(1.0, 1.0, 0.7)).parent = root

    # === RUSTY CLEAVER in right hand ============================
    _box(f"{name}_cleaver_blade", (0.04, 0.34, 0.36), iron,
         location=(0.78, 0.26, 0.62), rotation=(0, 0, 0.25)).parent = root
    _box(f"{name}_cleaver_edge", (0.018, 0.32, 0.34), "metal",
         location=(0.84, 0.26, 0.62), rotation=(0, 0, 0.25)).parent = root
    _smooth_sphere(f"{name}_cleaver_rust_a", radius=0.04,
                   color_name="fur_orange",
                   location=(0.80, 0.24, 0.72),
                   scale=(0.3, 1.0, 1.0)).parent = root
    _smooth_sphere(f"{name}_cleaver_rust_b", radius=0.04,
                   color_name="fur_orange",
                   location=(0.80, 0.24, 0.52),
                   scale=(0.3, 1.0, 1.2)).parent = root
    _smooth_sphere(f"{name}_cleaver_blood", radius=0.03,
                   color_name="blood",
                   location=(0.85, 0.24, 0.55),
                   scale=(0.4, 1.0, 2.0)).parent = root
    _cylinder(f"{name}_cleaver_handle", radius=0.040, height=0.18,
              color=leather,
              location=(0.72, 0.26, 0.40),
              rotation=(0, 0, 0.25)).parent = root
    _smooth_sphere(f"{name}_cleaver_pommel", radius=0.045, color_name=iron,
                   location=(0.68, 0.26, 0.32)).parent = root

    # === EYES on head (asymmetric) ==============================
    # Left — squinty black slit
    _box(f"{name}_eye_l", (0.08, 0.04, 0.014), "black",
         location=(-0.13, 0.34, 1.62)).parent = root
    _box(f"{name}_brow_l", (0.10, 0.04, 0.020), stitch,
         location=(-0.13, 0.36, 1.69),
         rotation=(0, 0, 0.2)).parent = root
    # Right — bulging yellow with pupil
    _smooth_sphere(f"{name}_eye_r_white", radius=0.060, color_name="bone",
                   location=( 0.13, 0.34, 1.62),
                   scale=(1.0, 0.7, 1.0)).parent = root
    _smooth_sphere(f"{name}_eye_r_iris", radius=0.035, color_name="yellow",
                   location=( 0.13, 0.38, 1.62),
                   scale=(1.0, 0.6, 1.0)).parent = root
    _smooth_sphere(f"{name}_eye_r_pupil", radius=0.018, color_name="black",
                   location=( 0.13, 0.40, 1.62),
                   scale=(1.0, 0.6, 1.0)).parent = root
    _box(f"{name}_brow_r", (0.13, 0.04, 0.024), stitch,
         location=( 0.13, 0.36, 1.70),
         rotation=(0, 0, -0.25)).parent = root

    # === SEWN-SHUT MOUTH on the protruding jaw ==================
    _box(f"{name}_mouth_line", (0.30, 0.04, 0.030), "black",
         location=(0, 0.42, 1.36)).parent = root
    for i in range(11):
        x = -0.14 + i * 0.028
        _box(f"{name}_mouth_st_{i}", (0.010, 0.025, 0.07), stitch,
             location=(x, 0.44, 1.36)).parent = root
    # Big tusk poking out at corner
    _cone(f"{name}_tusk", radius_bottom=0.024, radius_top=0.001,
          height=0.10, color="bone",
          location=(0.11, 0.44, 1.32),
          rotation=(0.7, 0, -0.1)).parent = root
    # Small tooth on opposite corner
    _cone(f"{name}_tooth_l", radius_bottom=0.015, radius_top=0.001,
          height=0.05, color="bone",
          location=(-0.09, 0.46, 1.36),
          rotation=(-0.4, 0, 0.1)).parent = root
    # Drool drip
    _smooth_sphere(f"{name}_drool", radius=0.020, color_name="bone",
                   location=(0.11, 0.46, 1.26),
                   scale=(0.8, 0.8, 1.6)).parent = root

    # === NOSE (lumpy, broken) ====================================
    _smooth_sphere(f"{name}_nose", radius=0.08, color_name=skin_dark,
                   location=(0, 0.44, 1.52),
                   scale=(0.9, 1.4, 0.9)).parent = root
    _smooth_sphere(f"{name}_nose_tip", radius=0.05, color_name=skin_dark,
                   location=(0, 0.50, 1.48)).parent = root

    # === EARS (cauliflower lumps) ===============================
    _smooth_sphere(f"{name}_ear_l", radius=0.08, color_name=skin,
                   location=(-0.36, 0.04, 1.58),
                   scale=(0.5, 0.7, 1.4)).parent = root
    _smooth_sphere(f"{name}_ear_r", radius=0.08, color_name=skin,
                   location=( 0.36, 0.04, 1.58),
                   scale=(0.5, 0.7, 1.4)).parent = root

    # === HEAD SCARS / STITCHES ==================================
    # Big slanted scar across forehead
    _box(f"{name}_scar_forehead", (0.30, 0.04, 0.025), stitch,
         location=(0, 0.34, 1.74), rotation=(0, 0, -0.15)).parent = root
    for i in range(7):
        x = -0.13 + i * 0.045
        _box(f"{name}_scar_forehead_st_{i}", (0.012, 0.04, 0.05), stitch,
             location=(x, 0.36, 1.74 + x * 0.15)).parent = root
    # Cheek scar
    _box(f"{name}_scar_cheek", (0.04, 0.04, 0.12), stitch,
         location=(0.24, 0.30, 1.50), rotation=(0, 0.3, 0)).parent = root
    # Temple gash
    _box(f"{name}_scar_temple", (0.08, 0.04, 0.06), stitch,
         location=(-0.32, 0.20, 1.62),
         rotation=(0, 0, 0.4)).parent = root

    # === UPPER-BELLY X-STITCH (visible above apron line) ========
    # Belly surface front sits at ~y=0.78. Stitches sit just in front
    # at y=0.80, in the visible band above the apron's top (z>=1.10).
    # Vertical surgical scar
    _box(f"{name}_stitch_main_v", (0.04, 0.06, 0.30), stitch,
         location=(0, 0.80, 1.20)).parent = root
    for i in range(7):
        z = 1.08 + i * 0.05
        _box(f"{name}_suture_{i}", (0.10, 0.04, 0.014), stitch,
             location=(0, 0.81, z)).parent = root
    # Crooked horizontal scar (off to the right)
    _box(f"{name}_scar_h", (0.18, 0.04, 0.025), stitch,
         location=(0.12, 0.80, 1.30), rotation=(0, 0, -0.2)).parent = root
    for i in range(4):
        x = 0.04 + i * 0.04
        _box(f"{name}_scar_h_stitch_{i}", (0.012, 0.04, 0.05), stitch,
             location=(x, 0.81, 1.30)).parent = root

    return root


# --- HERO 2: LASH (GRAPPLE — agile hooded ninja) ----------------------------

def make_hero_lash(name="hero_lash"):
    """Lean green-clad assassin with hood, mask and grapple-whip."""
    root = _empty_root(name)
    skin = "leaf_dark"
    suit = "leaf"
    accent = "black"

    # Slim legs in dark trousers
    _sphere(f"{name}_leg_l", (0.13, 0.13, 0.36), "rock_dark",
            location=(-0.13, 0, 0.38)).parent = root
    _sphere(f"{name}_leg_r", (0.13, 0.13, 0.36), "rock_dark",
            location=(0.13, 0, 0.38)).parent = root
    _box(f"{name}_foot_l", (0.16, 0.28, 0.08), accent,
         location=(-0.13, 0.05, 0.04)).parent = root
    _box(f"{name}_foot_r", (0.16, 0.28, 0.08), accent,
         location=(0.13, 0.05, 0.04)).parent = root

    # Belt with throwing-pouch
    _box(f"{name}_belt", (0.62, 0.42, 0.08), accent,
         location=(0, 0, 0.78)).parent = root
    _box(f"{name}_pouch", (0.10, 0.06, 0.10), "wood_dark",
         location=(0.22, 0.22, 0.78)).parent = root

    # Slim torso
    _sphere(f"{name}_torso", (0.30, 0.22, 0.34), suit,
            location=(0, 0, 1.04)).parent = root
    # Chest harness X-strap
    _box(f"{name}_strap_l", (0.06, 0.04, 0.40), accent,
         location=(-0.10, 0.20, 1.05),
         rotation=(0, 0.4, 0)).parent = root
    _box(f"{name}_strap_r", (0.06, 0.04, 0.40), accent,
         location=(0.10, 0.20, 1.05),
         rotation=(0, -0.4, 0)).parent = root

    # Head + hood
    _sphere(f"{name}_head", (0.22, 0.22, 0.24), skin,
            location=(0, 0, 1.42)).parent = root
    # Hood — cone over head
    _cone(f"{name}_hood", radius_bottom=0.30, radius_top=0.16,
          height=0.30, color=suit,
          location=(0, -0.04, 1.50)).parent = root
    # Lower face mask (covers nose/mouth)
    _box(f"{name}_mask", (0.20, 0.10, 0.10), accent,
         location=(0, 0.14, 1.36)).parent = root
    # Eyes — narrow glowing slits
    _box(f"{name}_eye_l", (0.06, 0.04, 0.02), "yellow",
         location=(-0.07, 0.21, 1.48)).parent = root
    _box(f"{name}_eye_r", (0.06, 0.04, 0.02), "yellow",
         location=(0.07, 0.21, 1.48)).parent = root

    # Arms — slim, slightly raised at sides
    _sphere(f"{name}_arm_l", (0.10, 0.10, 0.28), suit,
            location=(-0.36, 0, 0.95)).parent = root
    _sphere(f"{name}_arm_r", (0.10, 0.10, 0.28), suit,
            location=(0.36, 0, 0.95)).parent = root
    # Bracers
    _cylinder(f"{name}_bracer_l", radius=0.12, height=0.10, color=accent,
              location=(-0.36, 0, 0.78),
              rotation=(0, 0, 0)).parent = root
    _cylinder(f"{name}_bracer_r", radius=0.12, height=0.10, color=accent,
              location=(0.36, 0, 0.78),
              rotation=(0, 0, 0)).parent = root
    _sphere(f"{name}_hand_l", (0.10, 0.10, 0.10), skin,
            location=(-0.40, 0, 0.62)).parent = root
    _sphere(f"{name}_hand_r", (0.10, 0.10, 0.10), skin,
            location=(0.40, 0, 0.62)).parent = root

    # Grapple-whip coiled at right hip (visible accessory)
    _cylinder(f"{name}_whip_coil", radius=0.10, height=0.04,
              color="wood_dark", location=(0.34, 0.18, 0.78)).parent = root

    return root


# --- HERO 3: MAW (BOOMERANG — orange beast/predator) ------------------------

def make_hero_maw(name="hero_maw"):
    """Hunched orange-furred predator with fangs and twin dark stripes."""
    root = _empty_root(name)

    # Crouched short legs
    _sphere(f"{name}_leg_l", (0.18, 0.20, 0.24), "fur_orange",
            location=(-0.20, -0.04, 0.28)).parent = root
    _sphere(f"{name}_leg_r", (0.18, 0.20, 0.24), "fur_orange",
            location=(0.20, -0.04, 0.28)).parent = root
    # Big paws / claws
    _box(f"{name}_paw_l", (0.22, 0.32, 0.10), "fur_dark",
         location=(-0.20, 0.10, 0.06)).parent = root
    _box(f"{name}_paw_r", (0.22, 0.32, 0.10), "fur_dark",
         location=(0.20, 0.10, 0.06)).parent = root
    # Claw spikes on each paw
    for px, label in ((-0.20, "l"), (0.20, "r")):
        for cx_off, c_label in ((-0.06, "a"), (0.0, "b"), (0.06, "c")):
            _cone(f"{name}_claw_{label}_{c_label}",
                  radius_bottom=0.02, radius_top=0.001, height=0.06,
                  color="bone",
                  location=(px + cx_off, 0.26, 0.04)).parent = root

    # Bulky torso (lower)
    _sphere(f"{name}_torso", (0.42, 0.36, 0.38), "fur_orange",
            location=(0, -0.05, 0.78)).parent = root
    # Dark stripes on back/torso
    _box(f"{name}_stripe_a", (0.50, 0.04, 0.04), "fur_dark",
         location=(0, -0.34, 0.85),
         rotation=(0, 0, 0.3)).parent = root
    _box(f"{name}_stripe_b", (0.50, 0.04, 0.04), "fur_dark",
         location=(0, -0.34, 0.70),
         rotation=(0, 0, -0.3)).parent = root

    # Hunched shoulders
    _sphere(f"{name}_shoulder_l", (0.18, 0.16, 0.18), "fur_orange",
            location=(-0.34, -0.10, 1.04)).parent = root
    _sphere(f"{name}_shoulder_r", (0.18, 0.16, 0.18), "fur_orange",
            location=(0.34, -0.10, 1.04)).parent = root

    # Head — tilted forward slightly (lowered position)
    _sphere(f"{name}_head", (0.30, 0.32, 0.26), "fur_orange",
            location=(0, 0.08, 1.18)).parent = root
    # Snout — pushes forward
    _sphere(f"{name}_snout", (0.16, 0.18, 0.14), "fur_orange",
            location=(0, 0.34, 1.12)).parent = root
    # Nose
    _sphere(f"{name}_nose", (0.05, 0.05, 0.04), "black",
            location=(0, 0.50, 1.16)).parent = root
    # Fangs — two cones pointing down
    _cone(f"{name}_fang_l", radius_bottom=0.025, radius_top=0.001, height=0.10,
          color="bone", location=(-0.05, 0.42, 1.02),
          rotation=(3.14159, 0, 0)).parent = root
    _cone(f"{name}_fang_r", radius_bottom=0.025, radius_top=0.001, height=0.10,
          color="bone", location=(0.05, 0.42, 1.02),
          rotation=(3.14159, 0, 0)).parent = root
    # Glowing red eyes
    _box(f"{name}_eye_l", (0.06, 0.03, 0.04), "blood",
         location=(-0.10, 0.26, 1.26)).parent = root
    _box(f"{name}_eye_r", (0.06, 0.03, 0.04), "blood",
         location=(0.10, 0.26, 1.26)).parent = root
    # Ears — pointy
    _cone(f"{name}_ear_l", radius_bottom=0.08, radius_top=0.001, height=0.12,
          color="fur_dark", location=(-0.18, 0, 1.36)).parent = root
    _cone(f"{name}_ear_r", radius_bottom=0.08, radius_top=0.001, height=0.12,
          color="fur_dark", location=(0.18, 0, 1.36)).parent = root

    # Arms hanging forward (predator stance)
    _sphere(f"{name}_arm_l", (0.13, 0.14, 0.30), "fur_orange",
            location=(-0.42, 0.08, 0.86)).parent = root
    _sphere(f"{name}_arm_r", (0.13, 0.14, 0.30), "fur_orange",
            location=(0.42, 0.08, 0.86)).parent = root
    _sphere(f"{name}_paw_arm_l", (0.13, 0.13, 0.13), "fur_dark",
            location=(-0.46, 0.18, 0.55)).parent = root
    _sphere(f"{name}_paw_arm_r", (0.13, 0.13, 0.13), "fur_dark",
            location=(0.46, 0.18, 0.55)).parent = root

    return root


# --- HERO 4: FLUX (BEAM — robed mage) ---------------------------------------

def make_hero_flux(name="hero_flux"):
    """Tall mystic in purple robe holding a glowing cyan orb."""
    root = _empty_root(name)

    # Robe — tall cone, no visible legs
    _cone(f"{name}_robe", radius_bottom=0.42, radius_top=0.20,
          height=1.20, color="cloak_purple",
          location=(0, 0, 0.60)).parent = root
    # Trim at robe bottom (cyan band)
    _cone(f"{name}_robe_trim", radius_bottom=0.43, radius_top=0.41,
          height=0.05, color="cyan",
          location=(0, 0, 0.045)).parent = root

    # Belt with cyan gem
    _cylinder(f"{name}_belt", radius=0.34, height=0.06, color="black",
              location=(0, 0, 0.92)).parent = root
    _box(f"{name}_gem", (0.10, 0.04, 0.10), "cyan",
         location=(0, 0.30, 0.92),
         rotation=(0, 0, 0.785)).parent = root  # diamond shape via rotation

    # Upper body — under-robe
    _sphere(f"{name}_chest", (0.24, 0.20, 0.26), "purple",
            location=(0, 0, 1.30)).parent = root

    # Head
    _sphere(f"{name}_head", (0.22, 0.22, 0.24), "skin_pale",
            location=(0, 0, 1.62)).parent = root
    # Beard (white cone hanging from chin)
    _cone(f"{name}_beard", radius_bottom=0.16, radius_top=0.08,
          height=0.16, color="bone",
          location=(0, 0.10, 1.50)).parent = root
    # Eyes (closed wisdom — small horizontal lines)
    _box(f"{name}_eye_l", (0.06, 0.02, 0.012), "black",
         location=(-0.08, 0.20, 1.62)).parent = root
    _box(f"{name}_eye_r", (0.06, 0.02, 0.012), "black",
         location=(0.08, 0.20, 1.62)).parent = root

    # Pointy mage hat
    _cone(f"{name}_hat_brim", radius_bottom=0.30, radius_top=0.28,
          height=0.04, color="cloak_purple",
          location=(0, 0, 1.84)).parent = root
    _cone(f"{name}_hat_cone", radius_bottom=0.28, radius_top=0.02,
          height=0.40, color="cloak_purple",
          location=(0, -0.02, 2.06)).parent = root
    # Hat star (cyan)
    _box(f"{name}_hat_star", (0.06, 0.04, 0.06), "cyan",
         location=(0, 0.20, 1.96),
         rotation=(0, 0, 0.785)).parent = root

    # Sleeves (visible at sides as they emerge from cone)
    _sphere(f"{name}_sleeve_l", (0.10, 0.10, 0.18), "cloak_purple",
            location=(-0.32, 0, 1.10)).parent = root
    _sphere(f"{name}_sleeve_r", (0.10, 0.10, 0.18), "cloak_purple",
            location=(0.32, 0, 1.10)).parent = root
    # Pale hands
    _sphere(f"{name}_hand_l", (0.09, 0.09, 0.09), "skin_pale",
            location=(-0.34, 0, 0.92)).parent = root
    _sphere(f"{name}_hand_r", (0.09, 0.09, 0.09), "skin_pale",
            location=(0.40, 0.18, 1.05)).parent = root  # right hand forward

    # Glowing cyan orb in right hand
    _sphere(f"{name}_orb", (0.14, 0.14, 0.14), "cyan",
            location=(0.46, 0.30, 1.12)).parent = root
    # Inner brighter orb glow (smaller, paler)
    _sphere(f"{name}_orb_glow", (0.08, 0.08, 0.08), "bone",
            location=(0.46, 0.30, 1.12)).parent = root

    return root


# --- HERO 5: COIL (CHARGE — armored knight) ---------------------------------

def make_hero_coil(name="hero_coil"):
    """Stocky armored knight with gold plates and visored helmet."""
    root = _empty_root(name)

    # Greaves (lower legs)
    _cylinder(f"{name}_leg_l", radius=0.16, height=0.36, color="metal_dark",
              location=(-0.18, 0, 0.32)).parent = root
    _cylinder(f"{name}_leg_r", radius=0.16, height=0.36, color="metal_dark",
              location=(0.18, 0, 0.32)).parent = root
    _box(f"{name}_boot_l", (0.22, 0.32, 0.10), "metal_dark",
         location=(-0.18, 0.05, 0.05)).parent = root
    _box(f"{name}_boot_r", (0.22, 0.32, 0.10), "metal_dark",
         location=(0.18, 0.05, 0.05)).parent = root
    # Knee plates (gold)
    _box(f"{name}_knee_l", (0.18, 0.16, 0.06), "gold",
         location=(-0.18, 0.10, 0.50)).parent = root
    _box(f"{name}_knee_r", (0.18, 0.16, 0.06), "gold",
         location=(0.18, 0.10, 0.50)).parent = root

    # Skirt of armor plates
    _cone(f"{name}_skirt", radius_bottom=0.40, radius_top=0.36,
          height=0.16, color="gold",
          location=(0, 0, 0.66)).parent = root

    # Belt
    _cylinder(f"{name}_belt", radius=0.38, height=0.06, color="wood_dark",
              location=(0, 0, 0.78)).parent = root
    _box(f"{name}_buckle", (0.14, 0.04, 0.08), "gold",
         location=(0, 0.34, 0.78)).parent = root

    # Chest plate (large rounded)
    _sphere(f"{name}_chest", (0.40, 0.34, 0.30), "gold",
            location=(0, 0, 1.04)).parent = root
    # Pauldrons (shoulder pads)
    _sphere(f"{name}_pauldron_l", (0.22, 0.20, 0.14), "gold",
            location=(-0.40, 0, 1.20)).parent = root
    _sphere(f"{name}_pauldron_r", (0.22, 0.20, 0.14), "gold",
            location=(0.40, 0, 1.20)).parent = root
    # Chest emblem (small cross)
    _box(f"{name}_emblem_v", (0.04, 0.02, 0.16), "metal",
         location=(0, 0.34, 1.04)).parent = root
    _box(f"{name}_emblem_h", (0.14, 0.02, 0.04), "metal",
         location=(0, 0.34, 1.04)).parent = root

    # Helmet — sphere with visor
    _sphere(f"{name}_helmet", (0.28, 0.30, 0.30), "metal_dark",
            location=(0, 0, 1.42)).parent = root
    # Helmet plume crest
    _box(f"{name}_crest", (0.06, 0.18, 0.20), "blood",
         location=(0, 0, 1.62)).parent = root
    # Visor slit (yellow eye glow)
    _box(f"{name}_visor", (0.20, 0.04, 0.04), "yellow",
         location=(0, 0.28, 1.42)).parent = root

    # Arms — armored, slightly out
    _cylinder(f"{name}_arm_l", radius=0.14, height=0.32, color="metal_dark",
              location=(-0.46, 0, 0.96)).parent = root
    _cylinder(f"{name}_arm_r", radius=0.14, height=0.32, color="metal_dark",
              location=(0.46, 0, 0.96)).parent = root
    # Gauntlets
    _sphere(f"{name}_gauntlet_l", (0.16, 0.16, 0.16), "gold",
            location=(-0.48, 0, 0.62)).parent = root
    _sphere(f"{name}_gauntlet_r", (0.16, 0.16, 0.16), "gold",
            location=(0.48, 0, 0.62)).parent = root

    return root


# --- HERO 6: VEX (PULL — shadow / cloaked mystic) ---------------------------

def make_hero_vex(name="hero_vex"):
    """Tall hooded shadow figure — only glowing blue eyes visible inside hood."""
    root = _empty_root(name)

    # Cloak — large cone covering most of the body
    _cone(f"{name}_cloak", radius_bottom=0.46, radius_top=0.18,
          height=1.40, color="deep_blue",
          location=(0, 0, 0.70)).parent = root
    # Cloak inner darker shadow at front (creates depth)
    _cone(f"{name}_cloak_inner", radius_bottom=0.32, radius_top=0.14,
          height=1.20, color="rock_dark",
          location=(0, 0.08, 0.66)).parent = root

    # Lower trim — slightly lighter blue
    _cylinder(f"{name}_trim", radius=0.46, height=0.04, color="cyan",
              location=(0, 0, 0.02)).parent = root

    # Belt with cyan gem
    _cylinder(f"{name}_belt", radius=0.36, height=0.06, color="black",
              location=(0, 0, 0.84)).parent = root
    _sphere(f"{name}_belt_gem", (0.06, 0.04, 0.06), "cyan",
            location=(0, 0.32, 0.84)).parent = root

    # Hood — wider at top to suggest a hood, dark inside
    _sphere(f"{name}_hood", (0.30, 0.30, 0.32), "deep_blue",
            location=(0, -0.04, 1.50)).parent = root
    # Hood interior shadow (in front, very dark)
    _sphere(f"{name}_hood_shadow", (0.18, 0.06, 0.20), "black",
            location=(0, 0.20, 1.46)).parent = root
    # Glowing cyan eyes inside the hood
    _box(f"{name}_eye_l", (0.04, 0.02, 0.05), "cyan",
         location=(-0.06, 0.28, 1.50)).parent = root
    _box(f"{name}_eye_r", (0.04, 0.02, 0.05), "cyan",
         location=(0.06, 0.28, 1.50)).parent = root

    # Sleeves emerging from cloak (cloak_purple-tinged blue)
    _sphere(f"{name}_sleeve_l", (0.12, 0.12, 0.20), "deep_blue",
            location=(-0.34, 0, 1.10)).parent = root
    _sphere(f"{name}_sleeve_r", (0.12, 0.12, 0.20), "deep_blue",
            location=(0.34, 0, 1.10)).parent = root
    # Skeletal hands (pale)
    _sphere(f"{name}_hand_l", (0.08, 0.08, 0.10), "bone",
            location=(-0.36, 0, 0.92)).parent = root
    _sphere(f"{name}_hand_r", (0.08, 0.08, 0.10), "bone",
            location=(0.36, 0, 0.92)).parent = root

    # Floating spectral hook (cyan, hovers near right hand)
    _sphere(f"{name}_wisp", (0.10, 0.10, 0.10), "cyan",
            location=(0.42, 0.18, 1.00)).parent = root

    return root


# --- HERO 7: PUDGE A-POSE (Mixamo-prep, joined single mesh) -----------------
#
# This is the bind-pose / Mixamo-upload variant of Pudge. Differences from
# make_hero_pudge:
#   - Arms in A-pose (~30° outward from vertical) instead of hanging — Mixamo
#     auto-rig works cleanly only on T-pose or A-pose meshes.
#   - Left arm radii increased by 18% (hook-arm chunk per brief §3).
#   - Crooked-teeth grin replaces the sewn-shut mouth (locked decision #1).
#   - Ratty boots with toe-splay replace the plain box boots (locked decision #2).
#   - Apron stub kept (locked decision #6).
#   - Chain hook is NOT included on the body — exported separately via
#     make_hero_pudge_hook so it can be socket-attached after rigging.
#   - All body parts are JOINED into a single mesh named `pudge_body` at the
#     end. This is what gets uploaded to Mixamo.

def make_hero_pudge_apose(name="pudge_body"):
    """A-pose joined Pudge body, ready for Mixamo auto-rig upload."""
    root = _empty_root(name + "_root")
    skin = "pudge_skin"
    skin_dark = "pudge_skin_dark"
    leather = "wood_dark"
    iron = "metal_dark"
    stitch = "wood_dark"

    # === ORGANIC BODY (one fused metaball mesh) =================
    _organic_blob(f"{name}_body", [
        {"co": (0,    0.30, 0.78), "radius": 0.55},
        {"co": (0,    0.22, 0.96), "radius": 0.45},
        {"co": (0,   -0.05, 0.50), "radius": 0.36},
        {"co": (0,   -0.18, 0.82), "radius": 0.35},
        {"co": (-0.36, 0.05, 0.85), "radius": 0.20},
        {"co": ( 0.36, 0.05, 0.85), "radius": 0.20},
        {"co": (0,    0.0,  1.16), "radius": 0.40},
        {"co": (-0.18, 0.30, 1.06), "radius": 0.15},
        {"co": ( 0.18, 0.30, 1.06), "radius": 0.15},
        {"co": (-0.40, 0.0,  1.22), "radius": 0.22},
        {"co": ( 0.40, 0.0,  1.22), "radius": 0.22},
        {"co": (0,   -0.02, 1.40), "radius": 0.14},
    ], color_name=skin, resolution=0.035).parent = root

    # === ORGANIC HEAD ============================================
    _organic_blob(f"{name}_head_blob", [
        {"co": (0,    0.0,  1.66), "radius": 0.28},
        {"co": (-0.18, 0.0,  1.66), "radius": 0.18},
        {"co": ( 0.18, 0.0,  1.66), "radius": 0.18},
        {"co": (-0.22, -0.10, 1.68), "radius": 0.12},
        {"co": (0,    0.30, 1.40), "radius": 0.22},
        {"co": (0,    0.38, 1.32), "radius": 0.12},
        {"co": (-0.22, 0.20, 1.50), "radius": 0.13},
        {"co": ( 0.22, 0.20, 1.50), "radius": 0.13},
    ], color_name=skin, resolution=0.025).parent = root

    # === ARMS in A-POSE (~30° outward from vertical) ============
    # Left arm — hook arm, radii × 1.18 per brief §3.
    _skin_limb(f"{name}_arm_l", [
        ((-0.45,  0.0,  1.18), 0.21),   # shoulder (chunky)
        ((-0.62,  0.04, 0.88), 0.24),   # elbow
        ((-0.80,  0.08, 0.58), 0.19),   # wrist (out + slightly forward)
    ], color_name=skin).parent = root
    # Right arm — standard radii.
    _skin_limb(f"{name}_arm_r", [
        (( 0.45,  0.0,  1.18), 0.18),
        (( 0.62,  0.04, 0.88), 0.20),
        (( 0.80,  0.08, 0.58), 0.16),
    ], color_name=skin).parent = root

    # === HANDS — left chunkier, fingers face down (A-pose) =====
    _smooth_sphere(f"{name}_hand_l", radius=0.15, color_name=skin,
                   location=(-0.84, 0.10, 0.50),
                   scale=(1.0, 1.1, 0.85)).parent = root
    _smooth_sphere(f"{name}_hand_r", radius=0.13, color_name=skin,
                   location=( 0.84, 0.10, 0.50),
                   scale=(1.0, 1.1, 0.85)).parent = root

    # === LEGS via Skin modifier =================================
    _skin_limb(f"{name}_leg_l", [
        ((-0.22, 0.0,  0.46), 0.20),
        ((-0.22, 0.02, 0.22), 0.17),
        ((-0.22, 0.04, 0.10), 0.14),
    ], color_name=leather).parent = root
    _skin_limb(f"{name}_leg_r", [
        (( 0.22, 0.0,  0.46), 0.20),
        (( 0.22, 0.02, 0.22), 0.17),
        (( 0.22, 0.04, 0.10), 0.14),
    ], color_name=leather).parent = root

    # === RATTY BOOTS with toe-splay =============================
    # Main boot box (rounded smooth sphere, scaled to boot proportions)
    for sx, label in ((-0.22, "l"), (0.22, "r")):
        _smooth_sphere(f"{name}_boot_{label}", radius=0.16,
                       color_name="rock_dark",
                       location=(sx, 0.08, 0.07),
                       scale=(0.9, 1.3, 0.45)).parent = root
        # Toe bulge — front of boot, slightly outward (toes splaying)
        _smooth_sphere(f"{name}_boot_{label}_toe", radius=0.08,
                       color_name="rock_dark",
                       location=(sx + (0.04 if label == "l" else -0.04),
                                 0.24, 0.06),
                       scale=(0.8, 0.6, 0.5)).parent = root
        # Worn lace area (darker patch on top)
        _box(f"{name}_boot_{label}_laces", (0.08, 0.18, 0.03), "black",
             location=(sx, 0.06, 0.16)).parent = root
        # Sole (darker base)
        _box(f"{name}_boot_{label}_sole", (0.30, 0.40, 0.025), "black",
             location=(sx, 0.08, 0.02)).parent = root
        # Worn band
        _box(f"{name}_boot_{label}_band", (0.30, 0.05, 0.05),
             iron, location=(sx, 0.16, 0.10)).parent = root

    # === BELT + SKULL BUCKLE ====================================
    _smooth_torus(f"{name}_belt", major_radius=0.62, minor_radius=0.07,
                  color_name=leather,
                  location=(0, 0, 0.46)).parent = root
    _smooth_sphere(f"{name}_buckle_skull", radius=0.10, color_name="bone",
                   location=(0, 0.50, 0.48),
                   scale=(1.0, 0.7, 1.0)).parent = root
    _sphere(f"{name}_buckle_eye_l", (0.025, 0.025, 0.025), "black",
            location=(-0.040, 0.55, 0.49),
            segments=6, rings=6).parent = root
    _sphere(f"{name}_buckle_eye_r", (0.025, 0.025, 0.025), "black",
            location=( 0.040, 0.55, 0.49),
            segments=6, rings=6).parent = root
    _box(f"{name}_buckle_nose", (0.022, 0.022, 0.030), "black",
         location=(0, 0.55, 0.45)).parent = root
    for i in range(5):
        x = -0.30 + i * 0.15
        if abs(x) < 0.10:
            continue
        _smooth_sphere(f"{name}_belt_rivet_{i}", radius=0.020,
                       color_name=iron,
                       location=(x, 0.45, 0.46)).parent = root

    # === BLOODY APRON STUB (locked decision #6) =================
    _smooth_sphere(f"{name}_apron", radius=0.42, color_name="blood",
                   location=(0, 0.92, 0.74),
                   scale=(1.30, 0.20, 0.85)).parent = root
    _smooth_sphere(f"{name}_apron_stain_a", radius=0.06,
                   color_name=leather,
                   location=(-0.14, 1.06, 0.85),
                   scale=(1.4, 0.3, 0.9)).parent = root
    _smooth_sphere(f"{name}_apron_stain_b", radius=0.05,
                   color_name=leather,
                   location=( 0.18, 1.06, 0.95),
                   scale=(1.0, 0.3, 1.6)).parent = root
    _smooth_sphere(f"{name}_apron_drip", radius=0.030,
                   color_name="blood",
                   location=(-0.06, 1.07, 0.58),
                   scale=(0.8, 0.5, 2.0)).parent = root
    _box(f"{name}_apron_strap", (0.06, 0.06, 0.36), "blood",
         location=(0, 0.42, 1.28)).parent = root

    # === EYES on head (asymmetric, deranged) ===================
    # Left — squinty black slit
    _box(f"{name}_eye_l", (0.08, 0.04, 0.014), "black",
         location=(-0.13, 0.34, 1.62)).parent = root
    _box(f"{name}_brow_l", (0.10, 0.04, 0.020), stitch,
         location=(-0.13, 0.36, 1.69),
         rotation=(0, 0, 0.2)).parent = root
    # Right — bulging yellow with pupil (the bigger deranged one)
    _smooth_sphere(f"{name}_eye_r_white", radius=0.060, color_name="bone",
                   location=( 0.13, 0.34, 1.62),
                   scale=(1.0, 0.7, 1.0)).parent = root
    _smooth_sphere(f"{name}_eye_r_iris", radius=0.035, color_name="yellow",
                   location=( 0.13, 0.38, 1.62),
                   scale=(1.0, 0.6, 1.0)).parent = root
    _smooth_sphere(f"{name}_eye_r_pupil", radius=0.018, color_name="black",
                   location=( 0.13, 0.40, 1.62),
                   scale=(1.0, 0.6, 1.0)).parent = root
    _box(f"{name}_brow_r", (0.13, 0.04, 0.024), stitch,
         location=( 0.13, 0.36, 1.70),
         rotation=(0, 0, -0.25)).parent = root

    # === CROOKED TEETH GRIN (locked decision #1) ================
    # Mouth opening — recessed dark interior box
    _box(f"{name}_mouth_cavity", (0.30, 0.06, 0.090), "black",
         location=(0, 0.42, 1.36)).parent = root
    # Upper tooth row — 5 teeth, varied widths, asymmetric
    teeth_specs = [
        # (x_offset, width_mult, height_mult, color, missing)
        (-0.12, 1.2, 1.0, "bone", False),    # left incisor
        (-0.06, 0.9, 0.8, "bone", False),    # left smaller
        ( 0.00, 0.0, 0.0, "black", True),    # gap (missing tooth)
        ( 0.06, 1.0, 1.1, "bone", False),    # right incisor
        ( 0.12, 1.4, 1.2, "bone", False),    # right canine (sharp)
    ]
    for i, (xo, w, h, col, missing) in enumerate(teeth_specs):
        if missing:
            continue
        _box(f"{name}_tooth_upper_{i}",
             (0.020 * w, 0.030, 0.045 * h), col,
             location=(xo, 0.45, 1.39)).parent = root
    # Lower tooth row — 4 teeth (one missing for asymmetry)
    lower_teeth = [
        (-0.10, 1.0, 0.7, "bone", False),
        (-0.03, 0.8, 0.6, "bone", False),
        ( 0.04, 1.1, 0.9, "bone", False),
        ( 0.11, 0.9, 0.8, "bone", False),
    ]
    for i, (xo, w, h, col, _) in enumerate(lower_teeth):
        _box(f"{name}_tooth_lower_{i}",
             (0.020 * w, 0.030, 0.040 * h), col,
             location=(xo, 0.45, 1.34)).parent = root
    # Tusk poking out at right corner
    _cone(f"{name}_tusk", radius_bottom=0.024, radius_top=0.001,
          height=0.10, color="bone",
          location=(0.14, 0.45, 1.32),
          rotation=(0.7, 0, -0.1)).parent = root
    # Drool drip
    _smooth_sphere(f"{name}_drool", radius=0.018, color_name="bone",
                   location=(0.14, 0.46, 1.26),
                   scale=(0.8, 0.8, 1.6)).parent = root

    # === NOSE (lumpy, broken) ====================================
    _smooth_sphere(f"{name}_nose", radius=0.08, color_name=skin_dark,
                   location=(0, 0.44, 1.52),
                   scale=(0.9, 1.4, 0.9)).parent = root
    _smooth_sphere(f"{name}_nose_tip", radius=0.05, color_name=skin_dark,
                   location=(0, 0.50, 1.48)).parent = root

    # === EARS (cauliflower lumps) ===============================
    _smooth_sphere(f"{name}_ear_l", radius=0.08, color_name=skin,
                   location=(-0.36, 0.04, 1.58),
                   scale=(0.5, 0.7, 1.4)).parent = root
    _smooth_sphere(f"{name}_ear_r", radius=0.08, color_name=skin,
                   location=( 0.36, 0.04, 1.58),
                   scale=(0.5, 0.7, 1.4)).parent = root

    # === HEAD SCARS / STITCHES ==================================
    _box(f"{name}_scar_forehead", (0.30, 0.04, 0.025), stitch,
         location=(0, 0.34, 1.74), rotation=(0, 0, -0.15)).parent = root
    for i in range(7):
        x = -0.13 + i * 0.045
        _box(f"{name}_scar_forehead_st_{i}", (0.012, 0.04, 0.05), stitch,
             location=(x, 0.36, 1.74 + x * 0.15)).parent = root
    _box(f"{name}_scar_cheek", (0.04, 0.04, 0.12), stitch,
         location=(0.24, 0.30, 1.50), rotation=(0, 0.3, 0)).parent = root
    _box(f"{name}_scar_temple", (0.08, 0.04, 0.06), stitch,
         location=(-0.32, 0.20, 1.62),
         rotation=(0, 0, 0.4)).parent = root

    # === UPPER-BELLY X-STITCH (visible above apron line) ========
    _box(f"{name}_stitch_main_v", (0.04, 0.06, 0.30), stitch,
         location=(0, 0.80, 1.20)).parent = root
    for i in range(7):
        z = 1.08 + i * 0.05
        _box(f"{name}_suture_{i}", (0.10, 0.04, 0.014), stitch,
             location=(0, 0.81, z)).parent = root
    _box(f"{name}_scar_h", (0.18, 0.04, 0.025), stitch,
         location=(0.12, 0.80, 1.30), rotation=(0, 0, -0.2)).parent = root
    for i in range(4):
        x = 0.04 + i * 0.04
        _box(f"{name}_scar_h_stitch_{i}", (0.012, 0.04, 0.05), stitch,
             location=(x, 0.81, 1.30)).parent = root

    # Join everything into a single mesh for Mixamo upload. We deliberately
    # do NOT decimate here — aggressive decimation crushes the small face
    # details (eyes, teeth, scars) that Mixamo needs to identify front/back
    # for auto-rig. Mixamo's limit is well above 100k tris. Final in-game
    # decimation happens post-rigging in Stage 8 with skin-weight preservation.
    return _join_descendants_into(root, name, target_tris=None)


# --- PUDGE HOOK PROP (separate, attaches via socket post-rig) --------------

def make_hero_pudge_hook(name="pudge_hook"):
    """Standalone meat hook + chain prop. Imported separately, attached to
    the LeftHand bone in Godot via `socket_hook_hand` after Mixamo rigging.
    Pivot is at the chain anchor end (where it grips the hand)."""
    root = _empty_root(name + "_root")
    iron = "metal_dark"

    # Chain — 6 spheres descending from hand
    for i in range(6):
        cz = -i * 0.06  # negative Z = below the pivot/hand
        _smooth_sphere(f"{name}_chain_{i}", radius=0.030, color_name=iron,
                       location=(0, 0, cz)).parent = root
    # Hook curve — quarter arc swinging forward
    for i in range(6):
        ang = i / 5.0
        cx = 0.0 + 0.05 * ang
        cy = 0.04 * ang
        cz = -0.40 - 0.04 * (1 - (1 - ang) ** 2)
        _smooth_sphere(f"{name}_hook_curve_{i}", radius=0.034,
                       color_name=iron,
                       location=(cx, cy, cz)).parent = root
    # Hook tip cone
    _cone(f"{name}_hook_tip", radius_bottom=0.028, radius_top=0.001,
          height=0.10, color=iron,
          location=(0.05, 0.06, -0.50),
          rotation=(0, 0.5, 0)).parent = root
    # Rust spot near elbow of hook
    _smooth_sphere(f"{name}_hook_rust", radius=0.024, color_name="fur_orange",
                   location=(0.02, 0.03, -0.43),
                   scale=(1.0, 1.0, 0.7)).parent = root
    # Blood on inside of hook
    _smooth_sphere(f"{name}_hook_blood", radius=0.020, color_name="blood",
                   location=(0.01, 0.04, -0.46),
                   scale=(0.7, 1.0, 1.5)).parent = root

    # Hook prop kept at full source detail; will be decimated in Stage 8.
    return _join_descendants_into(root, name, target_tris=None)


# --- export registry --------------------------------------------------------

HERO_BUILDERS = {
    "hero_pudge": make_hero_pudge,
    "hero_pudge_apose": make_hero_pudge_apose,
    "hero_pudge_hook": make_hero_pudge_hook,
    "hero_lash": make_hero_lash,
    "hero_maw": make_hero_maw,
    "hero_flux": make_hero_flux,
    "hero_coil": make_hero_coil,
    "hero_vex": make_hero_vex,
}
