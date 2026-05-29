# Story EPIC pudge-animation-pipeline / Story-007 — build arm_pudge skeleton + A-pose bind.
# Spec: design/gdd/rigs/pudge.md (§1 hierarchy, §2 bind pose, §3 QA checklist).
# Playbook: design/gdd/rigs/pudge_authoring_playbook.md (§1 — re-fit Y to actual mesh; angles are design intent).
#
# Scope: the 20 standard humanoid bones only. Helpers (Jaw, BellyJiggle, ChainLink1-4)
# are Story-008. NOTE: the spec §1 summary says "22 humanoid" but its own authoritative
# §13 bone-type table tags Jaw/BellyJiggle/ChainLink as Helper -> the humanoid set is 20.
#
# Build is a canonical, symmetric A-pose fitted to the mesh's proportions (height 1.4 m,
# feet plane Z=0), NOT fitted to the asymmetric fused placeholder limbs. Rest pose == bind
# pose == A-pose (no pose-mode rotations), which is the clean convention for glTF export.
#
# Blender space: Z-up, character faces -Y (forward), Left = +X. On glTF "+Y up" export this
# maps to Godot forward -Z / up +Y per rig spec §2.
#
# Run:  blender --background <file>.blend --python tools/blender/heroes/build_pudge_skeleton.py
# or paste the build into a live session via the Blender MCP.

import bpy
from mathutils import Vector

ARMATURE_OBJ = "arm_pudge"
ARMATURE_DATA = "arm_data_pudge"
COLLECTION = "EXPORT_ARMATURE"

# (name, head, tail, parent, use_connect)
BONES = [
    ("Hips",          (0.00, 0.000, 0.300), (0.00, 0.000, 0.420), None,            False),
    ("Spine",         (0.00, 0.000, 0.420), (0.00, -0.030, 0.550), "Hips",         True),
    ("Spine1",        (0.00, -0.030, 0.550), (0.00, -0.060, 0.720), "Spine",       True),
    ("Chest",         (0.00, -0.060, 0.720), (0.00, -0.030, 0.900), "Spine1",      True),
    ("Neck",          (0.00, -0.030, 0.900), (0.00, -0.010, 0.980), "Chest",       True),
    ("Head",          (0.00, -0.010, 0.980), (0.00, 0.000, 1.220), "Neck",         True),
    # left arm (+X)
    ("LeftShoulder",  (0.040, -0.020, 0.800), (0.200, 0.000, 0.740), "Chest",      False),
    ("LeftArm",       (0.200, 0.000, 0.740), (0.300, 0.000, 0.567), "LeftShoulder", True),
    ("LeftForeArm",   (0.300, 0.000, 0.567), (0.390, 0.000, 0.411), "LeftArm",     True),
    ("LeftHand",      (0.390, 0.000, 0.411), (0.440, 0.000, 0.324), "LeftForeArm", True),
    # right arm (-X mirror)
    ("RightShoulder", (-0.040, -0.020, 0.800), (-0.200, 0.000, 0.740), "Chest",    False),
    ("RightArm",      (-0.200, 0.000, 0.740), (-0.300, 0.000, 0.567), "RightShoulder", True),
    ("RightForeArm",  (-0.300, 0.000, 0.567), (-0.390, 0.000, 0.411), "RightArm",  True),
    ("RightHand",     (-0.390, 0.000, 0.411), (-0.440, 0.000, 0.324), "RightForeArm", True),
    # left leg (+X)
    ("LeftUpLeg",     (0.100, 0.000, 0.300), (0.120, 0.000, 0.160), "Hips",        False),
    ("LeftLeg",       (0.120, 0.000, 0.160), (0.120, -0.010, 0.050), "LeftUpLeg",  True),
    ("LeftFoot",      (0.120, -0.010, 0.050), (0.120, -0.180, 0.020), "LeftLeg",   True),
    # right leg (-X mirror)
    ("RightUpLeg",    (-0.100, 0.000, 0.300), (-0.120, 0.000, 0.160), "Hips",      False),
    ("RightLeg",      (-0.120, 0.000, 0.160), (-0.120, -0.010, 0.050), "RightUpLeg", True),
    ("RightFoot",     (-0.120, -0.010, 0.050), (-0.120, -0.180, 0.020), "RightLeg", True),
]


def build():
    assert len(BONES) == 20, f"expected 20 humanoid bones, have {len(BONES)}"

    for ob in [o for o in bpy.data.objects if o.type == "ARMATURE" and o.name == ARMATURE_OBJ]:
        bpy.data.objects.remove(ob, do_unlink=True)
    for ad in [a for a in bpy.data.armatures if a.name == ARMATURE_DATA]:
        bpy.data.armatures.remove(ad)

    coll = bpy.data.collections.get(COLLECTION)
    if not coll:
        coll = bpy.data.collections.new(COLLECTION)
        bpy.context.scene.collection.children.link(coll)

    arm_data = bpy.data.armatures.new(ARMATURE_DATA)
    arm_obj = bpy.data.objects.new(ARMATURE_OBJ, arm_data)
    coll.objects.link(arm_obj)
    arm_obj.location = (0, 0, 0)
    arm_obj.rotation_euler = (0, 0, 0)
    arm_obj.scale = (1, 1, 1)

    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm_data.edit_bones
    made = {}
    for name, head, tail, _parent, _conn in BONES:
        b = eb.new(name)
        b.head = Vector(head)
        b.tail = Vector(tail)
        b.roll = 0.0
        made[name] = b
    for name, _h, _t, parent, conn in BONES:
        if parent:
            made[name].parent = made[parent]
            made[name].use_connect = conn
    bpy.ops.object.mode_set(mode="OBJECT")

    roots = [b.name for b in arm_data.bones if b.parent is None]
    print(f"[build_pudge_skeleton] bones={len(arm_data.bones)} roots={roots} collection={coll.name}")
    assert len(arm_data.bones) == 20
    assert roots == ["Hips"], f"expected single root Hips, got {roots}"
    return arm_obj


if __name__ == "__main__":
    build()
    if bpy.data.filepath:
        bpy.ops.wm.save_mainfile()
        print(f"[build_pudge_skeleton] saved {bpy.data.filepath}")
    else:
        print("[build_pudge_skeleton] WARNING: unsaved file (empty filepath) — not saving")
