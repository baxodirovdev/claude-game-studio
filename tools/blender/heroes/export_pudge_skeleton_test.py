# Story-007 verification — export a THROWAWAY skinned test GLB to validate the
# skeleton round-trip into Godot 4.6 (bone names, A-pose rest, orientation, height).
#
# This does NOT modify the authoritative .blend: it parents the body to arm_pudge with
# automatic weights IN MEMORY and exports, then exits without saving. The auto-weight
# quality is irrelevant here (Story-009 does real weights) — the skin only exists so the
# glTF carries a Skeleton3D + skinned mesh for Godot to import.
#
# Run: blender --background src/assets/models/heroes/anime_pudge.blend \
#              --python tools/blender/heroes/export_pudge_skeleton_test.py
# Output: tools/blender/heroes/pudge_skeleton_test.glb

import bpy
import os

OUT = os.path.join(os.path.dirname(bpy.data.filepath),
                   "..", "..", "..", "..", "tools", "blender", "heroes",
                   "pudge_skeleton_test.glb")
OUT = os.path.normpath(OUT)

arm = bpy.data.objects["arm_pudge"]
body = bpy.data.objects["mesh_pudge_body_lod0"]

# throwaway automatic-weight bind (in memory only)
bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
print(f"[export] body vertex groups after auto-weight: {len(body.vertex_groups)}")

# export only the rig + body
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
arm.select_set(True)

bpy.ops.export_scene.gltf(
    filepath=OUT,
    export_format="GLB",
    use_selection=True,
    export_yup=True,
    export_apply=True,
    export_animations=False,
    export_skins=True,
    export_def_bones=False,
)
print(f"[export] wrote {OUT}  ({os.path.getsize(OUT)} bytes)")
print("[export] NOTE: .blend intentionally NOT saved (throwaway skin)")
