# Epic pudge-animation-pipeline — Stage 1: skin the sculpt LOD0 to arm_pudge and
# export a RIGGED (but un-animated) pudge.glb for Godot.
#
# What it does (in-memory, the .blend is NOT saved):
#   1. Renames arm_pudge's 20 bones to the Mixamo standard ("mixamorig:" prefix,
#      and Chest -> Spine2) so they match the runtime socket contract in
#      src/gameplay/hero/hero_model_builder.gd:23-44 (HERO_SOCKETS expects
#      mixamorig:LeftHand / RightHand / Spine2 / Spine1 / Head) and so Stage 2
#      can retarget Mixamo clips by direct bone-name mapping.
#   2. Detaches mesh_pudge_body_lod0 from its empty parent (keep transform) and
#      binds it to arm_pudge with automatic weights. NOTE: auto-weights are
#      test-quality — proper weight paint is epic Story-009.
#   3. Exports src/assets/models/heroes/pudge.glb with skinning, no animations.
#
# Run:
#   blender --background src/assets/models/heroes/anime_pudge.blend \
#           --python tools/blender/heroes/rig_pudge_lod0.py
#
# Output: src/assets/models/heroes/pudge.glb (overwrites). .blend left untouched.
# Re-run this after any sculpt edit to refresh the rigged base before Stage 2.

import bpy
import os
import sys

OUT = os.path.normpath(os.path.join(os.path.dirname(bpy.data.filepath), "pudge.glb"))

# arm_pudge "Chest" sits where Mixamo's standard skeleton has "Spine2"; everything
# else maps 1:1 once the "mixamorig:" prefix is added.
BONE_REMAP = {"Chest": "Spine2"}


def deselect_all() -> None:
    for o in bpy.data.objects:
        o.select_set(False)


def main() -> None:
    arm = bpy.data.objects.get("arm_pudge")
    body = bpy.data.objects.get("mesh_pudge_body_lod0")
    if arm is None or body is None:
        print("[rig] ERROR: need both arm_pudge and mesh_pudge_body_lod0 in the .blend")
        sys.exit(1)

    bpy.ops.object.mode_set(mode="OBJECT")

    # 1) Rename bones BEFORE skinning so the generated vertex groups carry the
    #    final mixamorig: names (renaming after auto-weight would orphan groups).
    deselect_all()
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for eb in list(arm.data.edit_bones):
        eb.name = "mixamorig:" + BONE_REMAP.get(eb.name, eb.name)
    bpy.ops.object.mode_set(mode="OBJECT")
    print("[rig] bones:", [b.name for b in arm.data.bones])

    # 2) Detach body from its empty parent (keep world transform), auto-weight bind.
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
    print("[rig] body vertex groups after auto-weight:", len(body.vertex_groups))

    # 3) Export rig + skinned mesh, no animations.
    deselect_all()
    body.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.gltf(
        filepath=OUT,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=False,
        export_animations=False,
        export_skins=True,
        export_def_bones=False,
        export_materials="EXPORT",
    )
    print(f"[rig] wrote {OUT} ({os.path.getsize(OUT)} bytes)")
    print("[rig] .blend NOT saved")


if __name__ == "__main__":
    main()
