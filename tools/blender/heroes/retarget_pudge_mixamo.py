# Epic pudge-animation-pipeline — Stage 2: build a fitted skeleton for the Pudge
# sculpt, retarget Mixamo clips onto it, and export an animated pudge.glb.
#
# WHY a fitted skeleton: the sculpt is an extreme chibi (huge head/belly, tiny
# legs, arms bent at the belly sides) holding props. A generic A-pose skeleton
# does not sit inside those limbs, so binding smears the mesh. build_fitted_rig()
# instead rebuilds arm_pudge's 20 bones at joint positions measured from the
# sculpt geometry, so bind pose == the sculpt's own pose and weights track the
# real limbs. (The small floating hook crescent has been deleted from the mesh.)
#
# Retarget method: each target bone takes the source bone's ABSOLUTE world
# orientation (rest-agnostic — reproduces the Mixamo pose directly). The spine
# chain is DAMPED toward rest (DAMP) so Mixamo's tall-figure torso lean does not
# tip the short, big-headed chibi over. Hips horizontal translation is stripped
# per-clip (walk = in place).
#
# Bone names use the Mixamo "mixamorig:" form in Blender; Godot sanitizes ":" to
# "_" on import (the loader sockets use mixamorig_, epic story-001).
#
# Run:
#   blender --background src/assets/models/heroes/anime_pudge.blend \
#           --python tools/blender/heroes/retarget_pudge_mixamo.py
# Output: src/assets/models/heroes/pudge.glb. .blend untouched (not saved).

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

# Joint head positions (world m) measured from the sculpt. Character LEFT = -X.
JOINTS = {
    "Hips": (0.00, 0.10, 0.30), "Spine": (0.00, 0.06, 0.45), "Spine1": (0.00, 0.00, 0.60),
    "Spine2": (0.00, -0.10, 0.74), "Neck": (0.00, -0.10, 0.90), "Head": (0.00, -0.03, 0.97),
    "LeftShoulder": (-0.10, -0.08, 0.86), "LeftArm": (-0.42, -0.10, 0.81),
    "LeftForeArm": (-0.54, -0.07, 0.63), "LeftHand": (-0.60, -0.05, 0.50),
    "RightShoulder": (0.10, -0.08, 0.86), "RightArm": (0.42, -0.10, 0.81),
    "RightForeArm": (0.54, 0.10, 0.63), "RightHand": (0.60, 0.11, 0.49),
    "LeftUpLeg": (-0.18, 0.00, 0.32), "LeftLeg": (-0.30, -0.03, 0.17), "LeftFoot": (-0.40, -0.05, 0.06),
    "RightUpLeg": (0.18, 0.00, 0.32), "RightLeg": (0.28, -0.03, 0.17), "RightFoot": (0.34, -0.05, 0.06),
}
PARENT = {
    "Spine": "Hips", "Spine1": "Spine", "Spine2": "Spine1", "Neck": "Spine2", "Head": "Neck",
    "LeftShoulder": "Spine2", "LeftArm": "LeftShoulder", "LeftForeArm": "LeftArm", "LeftHand": "LeftForeArm",
    "RightShoulder": "Spine2", "RightArm": "RightShoulder", "RightForeArm": "RightArm", "RightHand": "RightForeArm",
    "LeftUpLeg": "Hips", "LeftLeg": "LeftUpLeg", "LeftFoot": "LeftLeg",
    "RightUpLeg": "Hips", "RightLeg": "RightUpLeg", "RightFoot": "RightLeg",
}
TAIL = {  # explicit tails for leaf bones
    "Head": (0.00, 0.06, 1.32), "LeftHand": (-0.62, -0.05, 0.40), "RightHand": (0.62, 0.11, 0.40),
    "LeftFoot": (-0.42, -0.16, 0.04), "RightFoot": (0.36, -0.16, 0.04),
}
TAIL_TOWARD = {  # non-leaf tails point at this child's head
    "Hips": "Spine", "Spine": "Spine1", "Spine1": "Spine2", "Spine2": "Neck", "Neck": "Head",
    "LeftShoulder": "LeftArm", "LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand",
    "RightShoulder": "RightArm", "RightArm": "RightForeArm", "RightForeArm": "RightHand",
    "LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "RightUpLeg": "RightLeg", "RightLeg": "RightFoot",
}
# Spine chain damped toward rest so the chibi stays upright (1.0 = full motion).
DAMP = {
    "mixamorig:Hips": 0.5, "mixamorig:Spine": 0.45, "mixamorig:Spine1": 0.45,
    "mixamorig:Spine2": 0.5, "mixamorig:Neck": 0.6, "mixamorig:Head": 0.6,
}


def deselect_all():
    for o in bpy.data.objects:
        o.select_set(False)


def rig_target():
    """Rebuild arm_pudge fitted to the sculpt, bind + smooth weights."""
    arm = bpy.data.objects["arm_pudge"]
    body = bpy.data.objects["mesh_pudge_body_lod0"]

    bpy.ops.object.mode_set(mode="OBJECT")
    deselect_all()
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    for b in list(eb):
        eb.remove(b)
    made = {}
    for name, head in JOINTS.items():
        e = eb.new("mixamorig:" + name)
        e.head = Vector(head)
        e.tail = Vector(TAIL[name]) if name in TAIL else Vector(JOINTS[TAIL_TOWARD[name]])
        if (e.tail - e.head).length < 0.02:
            e.tail = e.head + Vector((0, 0, 0.05))
        made[name] = e
    for name, par in PARENT.items():
        made[name].parent = made[par]
    bpy.ops.object.mode_set(mode="OBJECT")

    # bind
    deselect_all()
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    if body.parent is not None:
        bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    body.vertex_groups.clear()
    deselect_all()
    body.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")

    # smooth weights to reduce smearing across joints
    deselect_all()
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    bpy.ops.object.vertex_group_smooth(group_select_mode="ALL", factor=0.5, repeat=4)
    bpy.ops.object.mode_set(mode="OBJECT")

    print("[rig] fitted skeleton built and bound")
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
            src_rot = MS[n].to_3x3().normalized()
            damp = DAMP.get(n, 1.0)
            if damp < 1.0:
                rest_q = RT_world[n].to_3x3().normalized().to_quaternion()
                world_rot = rest_q.slerp(src_rot.to_quaternion(), damp).to_matrix().to_4x4()
            else:
                world_rot = src_rot.to_4x4()
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
