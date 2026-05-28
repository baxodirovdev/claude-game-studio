"""Analyze and preview a user-supplied STL/OBJ/GLB hero model.

Usage:
    blender -b -P tools/blender/analyze_stl.py -- <input> <output_dir>

Reports vertex/triangle count, world bounding box, and renders 4 preview
angles (front / 3-4 / side / back) so we can decide how to integrate the
mesh into the existing Godot pipeline.
"""
import sys
import json
import math
from pathlib import Path

import bpy
import mathutils


def parse_argv():
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1:]
    else:
        argv = []
    if len(argv) < 2:
        raise SystemExit("usage: analyze_stl.py -- <input> <output_dir>")
    return Path(argv[0]), Path(argv[1])


def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def import_any(path):
    p = str(path)
    suffix = path.suffix.lower()
    if suffix == ".stl":
        # Blender 4.x+ uses the unified import_mesh.stl operator;
        # 5.x exposes it as wm.stl_import.
        try:
            bpy.ops.wm.stl_import(filepath=p)
        except AttributeError:
            bpy.ops.import_mesh.stl(filepath=p)
    elif suffix == ".obj":
        bpy.ops.wm.obj_import(filepath=p)
    elif suffix in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=p)
    else:
        raise SystemExit(f"unsupported format: {suffix}")


def compute_stats():
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    total_verts = sum(len(m.data.vertices) for m in meshes)
    total_tris = 0
    for m in meshes:
        m.data.calc_loop_triangles()
        total_tris += len(m.data.loop_triangles)

    # Combined world-space bounding box
    minp = mathutils.Vector((float("inf"),) * 3)
    maxp = mathutils.Vector((float("-inf"),) * 3)
    for m in meshes:
        mw = m.matrix_world
        for corner in m.bound_box:
            wc = mw @ mathutils.Vector(corner)
            for i in range(3):
                minp[i] = min(minp[i], wc[i])
                maxp[i] = max(maxp[i], wc[i])
    size = maxp - minp
    return {
        "object_count": len(meshes),
        "vertices": total_verts,
        "triangles": total_tris,
        "bbox_min": tuple(round(v, 4) for v in minp),
        "bbox_max": tuple(round(v, 4) for v in maxp),
        "size": tuple(round(v, 4) for v in size),
    }


def normalize_to_height(meshes, target_height=1.7):
    """Scale + recenter so feet at z=0 and total height = target_height.
    Auto-detects whether the model's tallest axis is Z (Blender default)
    or Y (common for STL/OBJ exporters from Y-up apps), and rotates if
    needed. Returns (scale, translation, rotation_applied_deg)."""
    minp = mathutils.Vector((float("inf"),) * 3)
    maxp = mathutils.Vector((float("-inf"),) * 3)
    for m in meshes:
        mw = m.matrix_world
        for corner in m.bound_box:
            wc = mw @ mathutils.Vector(corner)
            for i in range(3):
                minp[i] = min(minp[i], wc[i])
                maxp[i] = max(maxp[i], wc[i])
    size = maxp - minp

    # Detect orientation: pick the longest axis as "up".
    axes = ("x", "y", "z")
    longest_axis = axes[max(range(3), key=lambda i: size[i])]
    rotation_deg = (0.0, 0.0, 0.0)
    if longest_axis == "y":
        # Y-up → Z-up: rotate -90° around X (this STL has head at -Y).
        rotation_deg = (-90.0, 0.0, 0.0)
        for m in meshes:
            m.rotation_euler = (math.radians(-90), 0, 0)
    elif longest_axis == "x":
        rotation_deg = (0.0, -90.0, 0.0)
        for m in meshes:
            m.rotation_euler = (0, math.radians(-90), 0)

    # Refresh the depsgraph so bound_box queries reflect the rotation.
    bpy.context.view_layer.update()

    minp = mathutils.Vector((float("inf"),) * 3)
    maxp = mathutils.Vector((float("-inf"),) * 3)
    for m in meshes:
        mw = m.matrix_world
        for corner in m.bound_box:
            wc = mw @ mathutils.Vector(corner)
            for i in range(3):
                minp[i] = min(minp[i], wc[i])
                maxp[i] = max(maxp[i], wc[i])
    size = maxp - minp
    height = size.z if size.z > 1e-6 else 1.0
    scale = target_height / height

    cx = (minp.x + maxp.x) * 0.5
    cy = (minp.y + maxp.y) * 0.5
    for m in meshes:
        m.scale = (scale, scale, scale)
        # m.location applies AFTER scale; after rotation the world-min Z
        # we computed above is already in world space, so the inverse
        # offset is min_z * scale (because location is added in world).
        m.location = (
            -cx * scale,
            -cy * scale,
            -minp.z * scale,
        )

    bpy.context.view_layer.update()
    return scale, (-cx * scale, -cy * scale, -minp.z * scale), rotation_deg


def setup_lighting():
    sun = bpy.data.lights.new("Sun", type='SUN')
    sun.energy = 3.0
    sun_obj = bpy.data.objects.new("Sun", sun)
    bpy.context.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(45), math.radians(30),
                              math.radians(20))
    area = bpy.data.lights.new("Fill", type='AREA')
    area.energy = 200.0
    area.size = 5.0
    area_obj = bpy.data.objects.new("Fill", area)
    bpy.context.collection.objects.link(area_obj)
    area_obj.location = (-2.0, -3.0, 2.5)
    area_obj.rotation_euler = (math.radians(60), 0, math.radians(-30))
    world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.55, 0.70, 0.85, 1.0)
        bg.inputs[1].default_value = 1.0


def setup_camera(target_z=0.85, distance=3.5, yaw_deg=180.0, pitch_deg=8.0):
    for o in list(bpy.data.objects):
        if o.type == 'CAMERA':
            bpy.data.objects.remove(o, do_unlink=True)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 70.0
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.collection.objects.link(cam)
    yaw = math.radians(yaw_deg)
    pitch = math.radians(pitch_deg)
    cam.location = (
        math.sin(yaw) * distance * math.cos(pitch),
        -math.cos(yaw) * distance * math.cos(pitch),
        target_z + math.sin(pitch) * distance,
    )
    direction = mathutils.Vector((
        -cam.location[0],
        -cam.location[1],
        target_z - cam.location[2],
    ))
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    bpy.context.scene.camera = cam


def render_to(filepath):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 720
    scene.render.resolution_y = 960
    scene.render.filepath = str(filepath)
    scene.render.image_settings.file_format = 'PNG'
    bpy.ops.render.render(write_still=True)


def main():
    in_path, out_dir = parse_argv()
    out_dir.mkdir(parents=True, exist_ok=True)

    clear_scene()
    import_any(in_path)
    raw_stats = compute_stats()
    print("[analyze] RAW:", json.dumps(raw_stats, indent=2))

    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    scale, translation, rotation_deg = normalize_to_height(
        meshes, target_height=1.7
    )
    print(f"[analyze] normalized: scale={scale:.4f} "
          f"translation={translation} rotation_deg={rotation_deg}")

    norm_stats = compute_stats()
    print("[analyze] NORMALIZED:", json.dumps(norm_stats, indent=2))

    # Apply a default neutral material (since STL has no materials)
    mat = bpy.data.materials.new("preview_mat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.55, 0.6, 0.4, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.7
    for m in meshes:
        if m.data.materials:
            m.data.materials[0] = mat
        else:
            m.data.materials.append(mat)

    setup_lighting()

    # Aim camera at the model's actual world-space center after norm.
    target_z = 0.85
    # Render from all 4 cardinal angles so we can determine which way
    # the model is facing in this STL (the +Y convention may be flipped).
    views = [
        ("yaw_000",  0.0, 5.0),
        ("yaw_090",  90.0, 5.0),
        ("yaw_180",  180.0, 5.0),
        ("yaw_270",  270.0, 5.0),
        ("three_quarter", 145.0, 12.0),
    ]
    for name, yaw, pitch in views:
        setup_camera(target_z=target_z, yaw_deg=yaw, pitch_deg=pitch,
                     distance=3.0)
        render_to(out_dir / f"stl_{name}.png")
        print(f"[analyze] wrote {out_dir / f'stl_{name}.png'}")

    summary = {
        "raw": raw_stats,
        "normalized": norm_stats,
        "normalize_scale": scale,
        "normalize_translation": translation,
        "rotation_deg": rotation_deg,
    }
    (out_dir / "analysis.json").write_text(json.dumps(summary, indent=2))
    print(f"[analyze] wrote {out_dir / 'analysis.json'}")


if __name__ == "__main__":
    main()
