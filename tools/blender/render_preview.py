"""Headless preview render of a GLB file.

Usage:
    blender -b -P tools/blender/render_preview.py -- <input.glb> <output_dir>

Renders three views (front, 3/4, side) to PNG so you can sanity-check a
hero model without launching Godot.
"""
import sys
from pathlib import Path

import bpy
import math


def parse_argv():
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1:]
    else:
        argv = []
    if len(argv) < 2:
        raise SystemExit("usage: render_preview.py -- <input.glb> <output_dir>")
    return Path(argv[0]), Path(argv[1])


def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def setup_lighting():
    # Sun light (key)
    sun = bpy.data.lights.new("Sun", type='SUN')
    sun.energy = 3.0
    sun_obj = bpy.data.objects.new("Sun", sun)
    bpy.context.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(45), math.radians(30), math.radians(20))
    # Fill area light
    area = bpy.data.lights.new("Fill", type='AREA')
    area.energy = 200.0
    area.size = 5.0
    area_obj = bpy.data.objects.new("Fill", area)
    bpy.context.collection.objects.link(area_obj)
    area_obj.location = (-2.0, -3.0, 2.5)
    area_obj.rotation_euler = (math.radians(60), 0, math.radians(-30))
    # Sky-blue world background
    world = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.55, 0.70, 0.85, 1.0)
        bg.inputs[1].default_value = 1.0


def setup_camera(target_z=0.95, distance=3.5, yaw_deg=0.0, pitch_deg=10.0):
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
    # Aim at the target z point above origin
    direction = (
        -cam.location[0],
        -cam.location[1],
        target_z - cam.location[2],
    )
    # Compute rotation to look at target
    import mathutils
    track = mathutils.Vector(direction)
    rot = track.to_track_quat('-Z', 'Y').to_euler()
    cam.rotation_euler = rot
    bpy.context.scene.camera = cam
    return cam


def render_to(filepath):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 720
    scene.render.resolution_y = 960
    scene.render.resolution_percentage = 100
    scene.render.filepath = str(filepath)
    scene.render.image_settings.file_format = 'PNG'
    bpy.ops.render.render(write_still=True)


def main():
    glb_path, out_dir = parse_argv()
    out_dir.mkdir(parents=True, exist_ok=True)

    clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(glb_path))

    setup_lighting()

    # Pudge faces +Y in Blender (heroes.py convention). Camera at +Y looks
    # back to -Y and sees his face. yaw=180 = front, 145 = front-3/4,
    # 90 = right side.
    views = [
        ("front", 180.0, 5.0),
        ("three_quarter", 145.0, 8.0),
        ("side", 90.0, 8.0),
    ]
    for name, yaw, pitch in views:
        # Remove old camera if any
        for o in list(bpy.data.objects):
            if o.type == 'CAMERA':
                bpy.data.objects.remove(o, do_unlink=True)
        setup_camera(yaw_deg=yaw, pitch_deg=pitch)
        render_to(out_dir / f"pudge_{name}.png")
        print(f"[preview] wrote {out_dir / f'pudge_{name}.png'}")


if __name__ == "__main__":
    main()
