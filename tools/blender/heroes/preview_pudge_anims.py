# Open in Blender GUI to PREVIEW the retargeted Pudge animations on arm_pudge.
# Rigs the sculpt + retargets all clips in CLIPS, then leaves Blender open with
# the walk action active so you can scrub / play (Spacebar). Switch clips in the
# Action Editor (walk / death / hook_throw — all kept with fake users).
#
# Saves a throwaway copy to /tmp first, so the source anime_pudge.blend is never
# overwritten (it still holds the high-poly bake source).
#
# Run (GUI, NOT --background):
#   blender src/assets/models/heroes/anime_pudge.blend \
#           --python tools/blender/heroes/preview_pudge_anims.py

import bpy
import os
import sys

HEROES = os.path.dirname(bpy.data.filepath)
TOOLS = os.path.normpath(os.path.join(HEROES, "..", "..", "..", "..", "tools", "blender", "heroes"))
sys.path.insert(0, TOOLS)

# Import the retarget module FIRST so its MIXDIR/HEROES capture the real paths
# before we save-as elsewhere.
import retarget_pudge_mixamo as R  # noqa: E402

# Protect the source: work on a throwaway copy.
bpy.ops.wm.save_as_mainfile(filepath="/tmp/pudge_anim_preview.blend", copy=False)

tgt = R.rig_target()
order = R.bone_order(tgt)
RT_world = {b.name: tgt.matrix_world @ b.bone.matrix_local for b in tgt.pose.bones}

for fbx, name, strip in R.CLIPS:
    path = os.path.join(R.MIXDIR, fbx)
    if not os.path.exists(path):
        print(f"[preview] MISSING {path}")
        continue
    src, new_objs = R.import_fbx(path)
    n = R.retarget_clip(tgt, src, name, strip, order, RT_world)
    print(f"[preview] {name}: {n} frames")
    R.deselect_all()
    for o in new_objs:
        o.select_set(True)
    bpy.ops.object.delete()

# retarget_clip parks clips in NLA tracks; for scrubbing, lift them back to
# selectable actions and make 'walk' the active one.
actions = {}
for t in list(tgt.animation_data.nla_tracks):
    if t.strips:
        actions[t.name] = t.strips[0].action
    tgt.animation_data.nla_tracks.remove(t)

walk = actions.get("walk")
if walk is not None:
    tgt.animation_data.action = walk
    fr = walk.frame_range
    sc = bpy.context.scene
    sc.frame_start = int(fr[0])
    sc.frame_end = int(fr[1])
    sc.frame_current = int(fr[0])

# select the armature and try to set material shading in the viewport
R.deselect_all()
tgt.select_set(True)
bpy.context.view_layer.objects.active = tgt
try:
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            area.spaces[0].shading.type = "MATERIAL"
except Exception as exc:
    print("[preview] shading set skipped:", exc)

print("[preview] ready — Action Editor has walk / death / hook_throw")
