# Epic pudge-animation-pipeline — Stage 2: retarget Mixamo clips onto arm_pudge
# and export an ANIMATED pudge.glb for Godot.
#
# Prereq: run Stage 1 logic is included here (rig is rebuilt in-memory), and the
# Mixamo .fbx clips must already be in tools/mixamo/pudge/ (download off any
# default Mixamo character — no auto-rig upload needed; they carry the standard
# 65-bone "mixamorig:" skeleton). Edit CLIPS below to add/rename clips.
#
# Method: for every frame, set each target bone's ABSOLUTE world orientation to
# the matching source bone's (matched by name — arm_pudge bones are renamed to
# the Mixamo standard first). This reproduces the source pose directly and is
# rest-agnostic, so it does NOT double-count the Mixamo T-pose vs arm_pudge
# A-pose difference (a rest-relative delta does, and crumples the mesh). Hips
# translation is scaled to Pudge's height; horizontal is stripped per-clip
# (walk = in-place so gameplay drives position).
#
# NOTE: auto-weights are test-quality (story-009 does real weight paint) and the
# fused hook prop deforms poorly — motion is recognizable, not shipping quality.
# NOTE: Godot sanitizes bone ":" -> "_" on import; the loader sockets use the
# "mixamorig_" form (hero_model_builder.gd, epic story-001).
#
# Run:
#   blender --background src/assets/models/heroes/anime_pudge.blend \
#           --python tools/blender/heroes/retarget_pudge_mixamo.py
# Output: src/assets/models/heroes/pudge.glb (skin + named actions). .blend untouched.

import bpy
import os
from mathutils import Matrix, Vector

HEROES = os.path.dirname(bpy.data.filepath)
MIXDIR = os.path.normpath(os.path.join(HEROES, "..", "..", "..", "..", "tools", "mixamo", "pudge"))
OUT = os.path.join(HEROES, "pudge.glb")

# (fbx filename, exported action name, strip horizontal hips translation?)
CLIPS = [
    ("Walking.fbx",            "walk",       True),
    ("Falling Back Death.fbx", "death",      False),
    ("Throwing.fbx",           "hook_throw", False),
]

REMAP = {"Chest": "Spine2"}  # arm_pudge "Chest" == Mixamo "Spine2"


def deselect_all():
    for o in bpy.data.objects:
        o.select_set(False)


def rig_target():
    arm = bpy.data.objects["arm_pudge"]
    body = bpy.data.objects["mesh_pudge_body_lod0"]
    bpy.ops.object.mode_set(mode="OBJECT")
    deselect_all()
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for eb in list(arm.data.edit_bones):
        eb.name = "mixamorig:" + REMAP.get(eb.name, eb.name)
    bpy.ops.object.mode_set(mode="OBJECT")
    deselect_all()
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    if body.parent is not None:
        bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    deselect_all()
    body.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    return arm


def bone_order(arm):
    order, seen = [], set()

    def visit(pb):
        if pb.name in seen:
            return
        if pb.parent:
            visit(pb.parent)
        seen.add(pb.name)
        order.append(pb.name)

    for pb in arm.pose.bones:
        visit(pb)
    return order


def import_fbx(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    return next(o for o in new if o.type == "ARMATURE"), new


def retarget_clip(tgt, src, name, strip_horiz, order, RT_world):
    f0, f1 = (int(round(v)) for v in src.animation_data.action.frame_range)
    RS_world = {b.name: src.matrix_world @ b.bone.matrix_local for b in src.pose.bones}
    tgt_hips_rest = RT_world["mixamorig:Hips"].to_translation()
    src_hips_rest = RS_world["mixamorig:Hips"].to_translation()
    k = tgt_hips_rest.z / src_hips_rest.z if src_hips_rest.z else 1.0

    tgt.animation_data_create()
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    tgt.animation_data.action = act

    common = [n for n in order if n in src.pose.bones]
    for f in range(f0, f1 + 1):
        bpy.context.scene.frame_set(f)
        bpy.context.view_layer.update()
        MS = {n: src.matrix_world @ src.pose.bones[n].matrix for n in common}
        for n in common:
            tpb = tgt.pose.bones[n]
            world_rot = MS[n].to_3x3().normalized().to_4x4()
            if n == "mixamorig:Hips":
                disp = MS[n].to_translation() - RS_world[n].to_translation()
                head = tgt_hips_rest + Vector((0, 0, disp.z) if strip_horiz else disp) * k
            else:
                par = tpb.parent
                offset = (RT_world[par.name].inverted() @ RT_world[n]).to_translation()
                head = (par.matrix @ Matrix.Translation(offset)).to_translation()
            tpb.matrix = Matrix.Translation(head) @ world_rot
            bpy.context.view_layer.update()
            tpb.rotation_mode = "QUATERNION"
            tpb.keyframe_insert("rotation_quaternion", frame=f)
            if n == "mixamorig:Hips":
                tpb.keyframe_insert("location", frame=f)

    track = tgt.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, f0, act)
    tgt.animation_data.action = None
    return f1 - f0 + 1


def main():
    tgt = rig_target()
    order = bone_order(tgt)
    RT_world = {b.name: tgt.matrix_world @ b.bone.matrix_local for b in tgt.pose.bones}

    for fbx, name, strip in CLIPS:
        path = os.path.join(MIXDIR, fbx)
        if not os.path.exists(path):
            print(f"[retarget] MISSING {path}")
            continue
        src, new_objs = import_fbx(path)
        n = retarget_clip(tgt, src, name, strip, order, RT_world)
        print(f"[retarget] {name}: {n} frames from {fbx}")
        deselect_all()
        for o in new_objs:
            o.select_set(True)
        bpy.ops.object.delete()

    bpy.context.scene.frame_set(1)
    body = bpy.data.objects["mesh_pudge_body_lod0"]
    deselect_all()
    body.select_set(True)
    tgt.select_set(True)
    bpy.context.view_layer.objects.active = tgt
    bpy.ops.export_scene.gltf(
        filepath=OUT, export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_animations=True,
        export_skins=True, export_def_bones=False, export_materials="EXPORT",
        export_animation_mode="NLA_TRACKS",
    )
    print(f"[retarget] wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
    main()
