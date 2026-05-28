"""Kenney-style primitive mesh generators. Each builder creates one or more
bpy objects parented under a root and returns the root. All meshes carry a
single UV layer mapping each face to one palette cell."""

import random

import bpy
import bmesh
from mathutils import Vector

from kenney_gen import palette


def _apply_flat_color(mesh, color_name):
    rgb = palette.rgb_for_color(color_name)
    rgba = (rgb[0], rgb[1], rgb[2], 1.0)
    attr = None
    for a in mesh.color_attributes:
        if a.name == "Col":
            attr = a
            break
    if attr is None:
        attr = mesh.color_attributes.new(
            name="Col", type='FLOAT_COLOR', domain='CORNER'
        )
    for loop_data in attr.data:
        loop_data.color = rgba


def _new_object(name, mesh):
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def _cylinder(name, radius, height, segments, color):
    bm = bmesh.new()
    bmesh.ops.create_cone(
        bm, cap_ends=True, segments=segments,
        radius1=radius, radius2=radius, depth=height,
    )
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_flat_color(mesh, color)
    return _new_object(name, mesh)


def _cone(name, radius_bottom, radius_top, height, segments, color):
    bm = bmesh.new()
    bmesh.ops.create_cone(
        bm, cap_ends=True, segments=segments,
        radius1=radius_bottom, radius2=radius_top, depth=height,
    )
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_flat_color(mesh, color)
    return _new_object(name, mesh)


def _cube(name, size, color):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=size)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_flat_color(mesh, color)
    return _new_object(name, mesh)


def make_barrel(name="barrel", radius=0.45, height=0.9, segments=10,
                wood_color="wood", band_color="metal_dark"):
    """Short cylinder body + two thin darker bands near top and bottom."""
    body = _cylinder(f"{name}_body", radius, height, segments, wood_color)

    band_h = 0.08
    band_r = radius * 1.04
    band_offset = height * 0.22

    upper = _cylinder(
        f"{name}_band_upper", band_r, band_h, segments, band_color
    )
    upper.location.z = band_offset
    upper.parent = body

    lower = _cylinder(
        f"{name}_band_lower", band_r, band_h, segments, band_color
    )
    lower.location.z = -band_offset
    lower.parent = body

    body.location.z = height / 2.0
    body.name = name
    return body


def make_crate(name="crate", size=0.9, color="wood_light"):
    """Clean low-poly cube crate sitting on origin."""
    crate = _cube(name, size, color)
    crate.location.z = size / 2.0
    return crate


def make_tree(name="tree", trunk_r=0.14, trunk_h=0.8,
              foliage_r=0.75, foliage_h=1.5,
              trunk_color="wood_dark", leaf_color="leaf"):
    """Cylinder trunk + cone foliage — classic Kenney tree silhouette."""
    trunk = _cylinder(f"{name}_trunk", trunk_r, trunk_h, 8, trunk_color)
    trunk.location.z = trunk_h / 2.0

    foliage = _cone(
        f"{name}_foliage", foliage_r, 0.0, foliage_h, 8, leaf_color
    )
    foliage.location.z = trunk_h + foliage_h / 2.0 - 0.15
    foliage.parent = trunk

    trunk.name = name
    return trunk


def make_rock(name="rock", radius=0.5, seed=0, color="stone"):
    """Icosphere with seeded vertex jitter and flattened base."""
    rng = random.Random(seed)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=radius)

    for v in bm.verts:
        v.co += Vector((
            rng.uniform(-0.15, 0.15),
            rng.uniform(-0.15, 0.15),
            rng.uniform(-0.10, 0.10),
        )) * radius

    base_z = -radius * 0.25
    for v in bm.verts:
        if v.co.z < base_z:
            v.co.z = base_z

    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_flat_color(mesh, color)
    obj = _new_object(name, mesh)
    obj.location.z = -base_z
    return obj


# --- River kit: modular 2m x 2m tiles that snap on the same grid as the
# existing Kenney nature-kit ground_river* pieces. Flow convention:
# straight = flow along +X, corner = enters from -X, exits through +Y. ---

TILE = 2.0
GROUND_H = 0.2
WATER_H = 0.05
WATER_RECESS = 0.09  # water surface sits 9 cm below bank top so it reads clearly
BED_H = GROUND_H - WATER_RECESS - WATER_H  # dirt bed under water (0.06m)
CHANNEL_W = 0.8
BANK_W = (TILE - CHANNEL_W) / 2.0  # 0.6m


def _box(name, size, color, location=(0.0, 0.0, 0.0)):
    sx, sy, sz = size
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= sx
        v.co.y *= sy
        v.co.z *= sz
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_flat_color(mesh, color)
    obj = _new_object(name, mesh)
    obj.location = Vector(location)
    return obj


def _box_two_tone(name, size, side_color, top_color, location=(0.0, 0.0, 0.0)):
    """Box with one color on the +Z face (top) and another on the other five
    faces. Used for rocky banks where the top reads brighter/lit and the
    side faces read as deep shadow."""
    sx, sy, sz = size
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= sx
        v.co.y *= sy
        v.co.z *= sz
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    attr = mesh.color_attributes.new(
        name="Col", type='FLOAT_COLOR', domain='CORNER'
    )
    side_rgba = (*palette.rgb_for_color(side_color), 1.0)
    top_rgba = (*palette.rgb_for_color(top_color), 1.0)
    for poly in mesh.polygons:
        rgba = top_rgba if poly.normal.z > 0.9 else side_rgba
        for loop_idx in poly.loop_indices:
            attr.data[loop_idx].color = rgba

    obj = _new_object(name, mesh)
    obj.location = Vector(location)
    return obj


def _empty_root(name):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    return root


def _small_rock(name, radius=0.15, seed=0, color="stone"):
    """Icosphere rock, flattened base, pivot at z=0 (sits on surface)."""
    rng = random.Random(seed)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=radius)
    for v in bm.verts:
        v.co += Vector((
            rng.uniform(-0.08, 0.08),
            rng.uniform(-0.08, 0.08),
            rng.uniform(-0.05, 0.05),
        )) * radius
    base_z = -radius * 0.3
    for v in bm.verts:
        if v.co.z < base_z:
            v.co.z = base_z
    min_z = min(v.co.z for v in bm.verts)
    for v in bm.verts:
        v.co.z -= min_z
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    _apply_flat_color(mesh, color)
    return _new_object(name, mesh)


def _straight_channel_parts(prefix):
    """4 boxes for a straight river along +X: left bank, right bank, bed, water."""
    bank_cy = (CHANNEL_W + BANK_W) / 2.0
    return [
        _box(f"{prefix}_grass_left",
             (TILE, BANK_W, GROUND_H), "leaf",
             (0, -bank_cy, GROUND_H / 2.0)),
        _box(f"{prefix}_grass_right",
             (TILE, BANK_W, GROUND_H), "leaf",
             (0, bank_cy, GROUND_H / 2.0)),
        _box(f"{prefix}_bed",
             (TILE, CHANNEL_W, BED_H), "dirt",
             (0, 0, BED_H / 2.0)),
        _box(f"{prefix}_water",
             (TILE, CHANNEL_W, WATER_H), "water",
             (0, 0, BED_H + WATER_H / 2.0)),
    ]


def make_river_straight(name="river_straight"):
    root = _empty_root(name)
    for obj in _straight_channel_parts(name):
        obj.parent = root
    return root


def make_river_end(name="river_end"):
    """Water enters from -X, grass caps the +X end."""
    root = _empty_root(name)
    bank_cy = (CHANNEL_W + BANK_W) / 2.0
    half = TILE / 2.0

    for suffix, y in (("grass_left", -bank_cy), ("grass_right", +bank_cy)):
        _box(f"{name}_{suffix}",
             (TILE, BANK_W, GROUND_H), "leaf",
             (0, y, GROUND_H / 2.0)).parent = root

    cap_x_size = 0.8
    cap_cx = half - cap_x_size / 2.0
    _box(f"{name}_grass_end",
         (cap_x_size, CHANNEL_W, GROUND_H), "leaf",
         (cap_cx, 0, GROUND_H / 2.0)).parent = root

    water_x_size = TILE - cap_x_size
    water_cx = -half + water_x_size / 2.0
    _box(f"{name}_bed",
         (water_x_size, CHANNEL_W, BED_H), "dirt",
         (water_cx, 0, BED_H / 2.0)).parent = root
    _box(f"{name}_water",
         (water_x_size, CHANNEL_W, WATER_H), "water",
         (water_cx, 0, BED_H + WATER_H / 2.0)).parent = root
    return root


def make_river_corner(name="river_corner"):
    """Water enters from -X edge, exits through +Y edge. L-shaped channel."""
    root = _empty_root(name)
    half = TILE / 2.0
    half_ch = CHANNEL_W / 2.0

    # Grass: 3 regions complementing the L-channel
    _box(f"{name}_grass_bottom",
         (TILE, BANK_W, GROUND_H), "leaf",
         (0, -(half_ch + BANK_W / 2.0), GROUND_H / 2.0)).parent = root
    _box(f"{name}_grass_tl",
         (BANK_W, BANK_W, GROUND_H), "leaf",
         (-(half_ch + BANK_W / 2.0), half_ch + BANK_W / 2.0, GROUND_H / 2.0)).parent = root
    right_y_size = half + half_ch
    right_cy = half - right_y_size / 2.0
    _box(f"{name}_grass_right",
         (BANK_W, right_y_size, GROUND_H), "leaf",
         (half_ch + BANK_W / 2.0, right_cy, GROUND_H / 2.0)).parent = root

    # Horizontal arm (x ∈ [-1, 0.4], y ∈ [-0.4, 0.4])
    h_x_size = half + half_ch
    h_cx = -half + h_x_size / 2.0
    _box(f"{name}_bed_h",
         (h_x_size, CHANNEL_W, BED_H), "dirt",
         (h_cx, 0, BED_H / 2.0)).parent = root
    _box(f"{name}_water_h",
         (h_x_size, CHANNEL_W, WATER_H), "water",
         (h_cx, 0, BED_H + WATER_H / 2.0)).parent = root
    # Vertical arm (x ∈ [-0.4, 0.4], y ∈ [-0.4, 1])
    v_y_size = half + half_ch
    v_cy = half - v_y_size / 2.0
    _box(f"{name}_bed_v",
         (CHANNEL_W, v_y_size, BED_H), "dirt",
         (0, v_cy, BED_H / 2.0)).parent = root
    _box(f"{name}_water_v",
         (CHANNEL_W, v_y_size, WATER_H), "water",
         (0, v_cy, BED_H + WATER_H / 2.0)).parent = root
    return root


def make_river_rocks(name="river_rocks"):
    """Straight river with three rocks breaking the water surface."""
    root = _empty_root(name)
    for obj in _straight_channel_parts(name):
        obj.parent = root
    water_top = BED_H + WATER_H
    rng = random.Random(11)
    for i, x_frac in enumerate((-0.35, 0.0, 0.38)):
        rock = _small_rock(
            f"{name}_rock_{i}",
            radius=0.14 + rng.uniform(-0.02, 0.04),
            seed=i * 7 + 3,
        )
        rock.location = Vector((x_frac * TILE, rng.uniform(-0.18, 0.18), water_top))
        rock.parent = root
    return root


def make_river_bridge(name="river_bridge"):
    """Straight river with a 5-plank wooden bridge and 4 corner posts."""
    root = _empty_root(name)
    for obj in _straight_channel_parts(name):
        obj.parent = root

    deck_z = GROUND_H + 0.02
    plank_w = 0.15
    plank_l = CHANNEL_W + 0.2
    plank_h = 0.05
    spacing = plank_w * 1.35
    for i in range(5):
        x = (i - 2) * spacing
        _box(f"{name}_plank_{i}",
             (plank_w, plank_l, plank_h), "wood_light",
             (x, 0, deck_z + plank_h / 2.0)).parent = root

    post_size = 0.12
    post_h = 0.42
    deck_edge_x = 2 * spacing + plank_w / 2.0
    for sx in (-deck_edge_x, +deck_edge_x):
        for sy in (-plank_l / 2.0 + post_size / 2.0,
                   +plank_l / 2.0 - post_size / 2.0):
            _box(f"{name}_post",
                 (post_size, post_size, post_h), "wood_dark",
                 (sx, sy, GROUND_H + post_h / 2.0)).parent = root
    return root


# --- Modular river composition pieces. Tile these in a grid to make rivers
# of any width or length. Tile at origin: base z=0, center x=0 y=0. ---


def make_river_water(name="river_water"):
    """All-water tile: dirt bed + water surface, no banks. Use for wide
    river interiors, lake bodies, or to extend flow past the map edge."""
    root = _empty_root(name)
    _box(f"{name}_bed",
         (TILE, TILE, BED_H), "dirt",
         (0, 0, BED_H / 2.0)).parent = root
    _box(f"{name}_water",
         (TILE, TILE, WATER_H), "water",
         (0, 0, BED_H + WATER_H / 2.0)).parent = root
    return root


def make_river_bank(name="river_bank", bank_color="leaf"):
    """Bank on -Y edge, water on the remaining +Y 1.4m. Rotate 0/90/180/270°
    in-engine to put the bank on any cardinal edge. Use bank_color='stone'
    or 'stone_dark' for a rocky variant."""
    root = _empty_root(name)
    _box(f"{name}_bank",
         (TILE, BANK_W, GROUND_H), bank_color,
         (0, -(TILE - BANK_W) / 2.0, GROUND_H / 2.0)).parent = root

    water_y_size = TILE - BANK_W
    water_cy = TILE / 2.0 - water_y_size / 2.0
    _box(f"{name}_bed",
         (TILE, water_y_size, BED_H), "dirt",
         (0, water_cy, BED_H / 2.0)).parent = root
    _box(f"{name}_water",
         (TILE, water_y_size, WATER_H), "water",
         (0, water_cy, BED_H + WATER_H / 2.0)).parent = root
    return root


def _make_beveled_bank(name, bank_color, bed_color="dirt",
                       bevel_offset=0.045, bevel_segments=1,
                       full_bevel=False):
    """Shared builder for bank variants: beveled slab on the -Y edge,
    bed + water on the +Y side. `bank_color` and `bed_color` are palette
    names. When `full_bevel` is True every edge of the bank box is
    chamfered (top + bottom + vertical) for a 3D rounded-rectangle
    profile; otherwise only the top edges are beveled. Tiles seamlessly
    because the base footprint is constant."""
    root = _empty_root(name)
    bank_y_center = -(TILE - BANK_W) / 2.0

    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= TILE
        v.co.y *= BANK_W
        v.co.z *= GROUND_H

    if full_bevel:
        bevel_edges = list(bm.edges)
    else:
        bevel_edges = [
            e for e in bm.edges
            if e.verts[0].co.z > 0.01 and e.verts[1].co.z > 0.01
        ]
    bmesh.ops.bevel(
        bm,
        geom=bevel_edges,
        offset=bevel_offset,
        segments=bevel_segments,
        profile=0.5,
        affect='EDGES',
    )

    mesh = bpy.data.meshes.new(f"{name}_bank")
    bm.to_mesh(mesh)
    bm.free()
    _apply_flat_color(mesh, bank_color)

    bank_obj = _new_object(f"{name}_bank", mesh)
    bank_obj.location = Vector((0, bank_y_center, GROUND_H / 2.0))
    bank_obj.parent = root

    water_y_size = TILE - BANK_W
    water_cy = TILE / 2.0 - water_y_size / 2.0
    _box(f"{name}_bed",
         (TILE, water_y_size, BED_H), bed_color,
         (0, water_cy, BED_H / 2.0)).parent = root
    _box(f"{name}_water",
         (TILE, water_y_size, WATER_H), "water",
         (0, water_cy, BED_H + WATER_H / 2.0)).parent = root
    return root


def make_river_bank_sand(name="river_bank_sand",
                         bevel_offset=0.045, bevel_segments=1):
    """Sandy-beach river bank with a beveled top edge, uniform sand color.

    Earlier iterations tried 2-tone speckle on the top face, but the dark
    patches landed near the water edge and read as black dashes; plus a
    'wet sand rim' strip that caused z-fighting with the bank top. Both
    have been removed — clean uniform sand reads best."""
    return _make_beveled_bank(
        name, bank_color="sand", bed_color="sand",
        bevel_offset=bevel_offset, bevel_segments=bevel_segments,
    )


def make_river_bank_sand_long(name="river_bank_sand_long", length=44.0,
                              bevel_offset=0.045):
    """One continuous sand bank slab matching the look of the per-tile
    `river_bank_sand` (beveled top edge for a soft Kenney shoulder), but
    spanning the full arena river length in one mesh — so the visible
    silhouette has the same gentle chamfer as the tile variant without
    introducing tile seams along its length. Vertex colors carry a
    sand→grass gradient across the bank's width: inner edge (water-
    facing) reads as sand, outer edge (grass-facing) is exactly arena
    grass color."""
    root = _empty_root(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= length
        v.co.y *= BANK_W
        v.co.z *= GROUND_H

    # Match river_bank_sand: 4.5 cm bevel on the four top edges.
    top_edges = [
        e for e in bm.edges
        if e.verts[0].co.z > 0.05 and e.verts[1].co.z > 0.05
    ]
    bmesh.ops.bevel(
        bm, geom=top_edges,
        offset=bevel_offset, segments=1, profile=0.5, affect='EDGES',
    )

    mesh = bpy.data.meshes.new(f"{name}_bank")
    bm.to_mesh(mesh)
    bm.free()

    grass_rgb = palette.rgb_for_color("grass_bright")
    sand_rgb = palette.rgb_for_color("sand")
    half_w = BANK_W / 2.0

    attr = mesh.color_attributes.new(
        name="Col", type='FLOAT_COLOR', domain='CORNER'
    )
    for poly in mesh.polygons:
        for loop_idx in poly.loop_indices:
            v_idx = mesh.loops[loop_idx].vertex_index
            y = mesh.vertices[v_idx].co.y
            t = (y + half_w) / (2.0 * half_w)
            t = max(0.0, min(1.0, t))
            r = grass_rgb[0] * (1.0 - t) + sand_rgb[0] * t
            g = grass_rgb[1] * (1.0 - t) + sand_rgb[1] * t
            b = grass_rgb[2] * (1.0 - t) + sand_rgb[2] * t
            attr.data[loop_idx].color = (r, g, b, 1.0)

    bank_obj = _new_object(f"{name}_bank", mesh)
    bank_obj.location = Vector((0, -(TILE - BANK_W) / 2.0, GROUND_H / 2.0))
    bank_obj.parent = root
    return root


def make_river_bank_rock(name="river_bank_rock",
                         bevel_offset=0.08, bevel_segments=3):
    """Sandy-tan river bank with a rounded top edge (multi-segment bevel)
    on the top edges only. Constant base footprint so tiles still join
    seamlessly."""
    return _make_beveled_bank(
        name, bank_color="sand", bed_color="dirt",
        bevel_offset=bevel_offset, bevel_segments=bevel_segments,
        full_bevel=False,
    )


def make_river_bank_corner(name="river_bank_corner"):
    """L-shaped bank covering -X and -Y edges; water fills the +X +Y
    complement (1.4m x 1.4m). Rotate for any of the four corners."""
    root = _empty_root(name)
    # Bank along -Y edge (full width)
    _box(f"{name}_bank_y",
         (TILE, BANK_W, GROUND_H), "leaf",
         (0, -(TILE - BANK_W) / 2.0, GROUND_H / 2.0)).parent = root
    # Bank along -X edge (excludes -Y overlap)
    bx_y_size = TILE - BANK_W
    bx_cy = TILE / 2.0 - bx_y_size / 2.0
    _box(f"{name}_bank_x",
         (BANK_W, bx_y_size, GROUND_H), "leaf",
         (-(TILE - BANK_W) / 2.0, bx_cy, GROUND_H / 2.0)).parent = root
    # Water in the +X +Y complement
    w_size = TILE - BANK_W
    w_c = TILE / 2.0 - w_size / 2.0
    _box(f"{name}_bed",
         (w_size, w_size, BED_H), "dirt",
         (w_c, w_c, BED_H / 2.0)).parent = root
    _box(f"{name}_water",
         (w_size, w_size, WATER_H), "water",
         (w_c, w_c, BED_H + WATER_H / 2.0)).parent = root
    return root


def make_river_source(name="river_source"):
    """Open-water tile with a rock spring cluster at +X edge. Use as the
    natural beginning (or end) of a river where water continues rather than
    ending in grass."""
    root = _empty_root(name)
    _box(f"{name}_bed",
         (TILE, TILE, BED_H), "dirt",
         (0, 0, BED_H / 2.0)).parent = root
    _box(f"{name}_water",
         (TILE, TILE, WATER_H), "water",
         (0, 0, BED_H + WATER_H / 2.0)).parent = root

    water_top = BED_H + WATER_H
    rocks = [
        (0.75,  0.00, 0.32, 11),
        (0.55, -0.40, 0.22, 12),
        (0.55,  0.40, 0.22, 13),
        (0.90,  0.22, 0.18, 14),
        (0.90, -0.22, 0.18, 15),
    ]
    for i, (rx, ry, radius, seed) in enumerate(rocks):
        rock = _small_rock(f"{name}_rock_{i}", radius=radius, seed=seed)
        rock.location = Vector((rx, ry, water_top))
        rock.parent = root
    return root


BUILDERS = {
    "barrel": make_barrel,
    "crate": make_crate,
    "tree": make_tree,
    "rock": make_rock,
    "river_straight": make_river_straight,
    "river_corner": make_river_corner,
    "river_end": make_river_end,
    "river_rocks": make_river_rocks,
    "river_bridge": make_river_bridge,
    "river_water": make_river_water,
    "river_bank": make_river_bank,
    "river_bank_rock": make_river_bank_rock,
    "river_bank_sand": make_river_bank_sand,
    "river_bank_sand_long": make_river_bank_sand_long,
    "river_bank_corner": make_river_bank_corner,
    "river_source": make_river_source,
}
