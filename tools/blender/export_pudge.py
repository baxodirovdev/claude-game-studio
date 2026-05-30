"""Canonical export script: produces both `pudge.glb` and `pudge_hook.glb`.

Bridges the gap between the model spec §10 instruction "export from
PUDGE_NEW_BUILD collection only" and Blender's glTF exporter which has no
built-in collection filter. Workflow:

1. Hide everything outside PUDGE_NEW_BUILD.
2. For pudge.glb: select body LODs + armature + scene root empty; export.
3. For pudge_hook.glb: select hook LODs + armature (skinning needs it); export.
4. Restore the original visibility / selection state.

Output paths match the loader contract at `hero_model_builder.gd:15-16`:
    src/assets/models/heroes/pudge.glb
    src/assets/models/heroes/pudge_hook.glb

Run headless from project root:
    blender src/assets/models/heroes/anime_pudge.blend --background \\
        --python tools/blender/export_pudge.py -- --asset pudge

Or via Blender's Scripting workspace — just `exec(open(...).read())`.

Exit 0 = both GLBs written successfully, non-zero = at least one export failed.
"""

from __future__ import annotations

import argparse
import os
import sys

import bpy


EXPORT_COLLECTION = "PUDGE_NEW_BUILD"

# Output paths relative to the project root. The .blend lives at
# src/assets/models/heroes/, so the project root is 4 levels up.
def output_dir() -> str:
    blend_path = bpy.data.filepath
    if not blend_path:
        raise RuntimeError("Save the .blend file first; export needs an anchor path.")
    return os.path.dirname(blend_path)


def expected_objects(asset: str) -> dict[str, list[str]]:
    """Group object names by which GLB they belong to."""
    return {
        "body": [
            asset,  # scene root empty
            f"mesh_{asset}_body_lod0",
            f"mesh_{asset}_body_lod1",
            f"mesh_{asset}_body_lod2",
            f"arm_{asset}",
        ],
        "hook": [
            f"mesh_{asset}_hook_lod0",
            f"mesh_{asset}_hook_lod1",
            f"mesh_{asset}_hook_lod2",
            f"arm_{asset}",  # included so hook keeps skinning info
        ],
    }


def snapshot_state() -> dict:
    """Capture visibility + selection so we can restore after exports."""
    state = {
        "collection_excludes": {},
        "object_hidden": {},
        "object_selected": {},
        "active_object": bpy.context.view_layer.objects.active,
    }
    for layer_col in bpy.context.view_layer.layer_collection.children:
        state["collection_excludes"][layer_col.name] = layer_col.exclude
    for obj in bpy.data.objects:
        state["object_hidden"][obj.name] = obj.hide_get()
        state["object_selected"][obj.name] = obj.select_get()
    return state


def restore_state(state: dict) -> None:
    for name, excl in state["collection_excludes"].items():
        lc = bpy.context.view_layer.layer_collection.children.get(name)
        if lc:
            lc.exclude = excl
    for name, hidden in state["object_hidden"].items():
        obj = bpy.data.objects.get(name)
        if obj:
            try:
                obj.hide_set(hidden)
            except RuntimeError:
                pass  # object may be in an excluded collection — fine
    for name, selected in state["object_selected"].items():
        obj = bpy.data.objects.get(name)
        if obj:
            try:
                obj.select_set(selected)
            except RuntimeError:
                pass
    bpy.context.view_layer.objects.active = state["active_object"]


def isolate_for_export(target_names: list[str]) -> tuple[list[str], list[str]]:
    """Hide everything, then unhide + select only the target objects.

    Returns (selected_names, missing_names).
    """
    # Step 1 — exclude all top-level collections except PUDGE_NEW_BUILD
    for layer_col in bpy.context.view_layer.layer_collection.children:
        layer_col.exclude = (layer_col.name != EXPORT_COLLECTION)

    # Step 2 — within PUDGE_NEW_BUILD, hide everything
    for obj in bpy.data.objects:
        try:
            obj.hide_set(True)
            obj.select_set(False)
        except RuntimeError:
            pass

    # Step 3 — unhide + select target objects
    selected: list[str] = []
    missing: list[str] = []
    for name in target_names:
        obj = bpy.data.objects.get(name)
        if obj is None:
            missing.append(name)
            continue
        try:
            obj.hide_set(False)
            obj.select_set(True)
            selected.append(name)
            bpy.context.view_layer.objects.active = obj
        except RuntimeError:
            missing.append(name)
    return selected, missing


def export_glb(filepath: str, include_animations: bool) -> bool:
    """Run the glTF export with our standard settings. Returns True on success."""
    try:
        bpy.ops.export_scene.gltf(
            filepath=filepath,
            export_format='GLB',
            use_selection=True,
            export_apply=True,            # apply modifiers
            export_yup=True,              # Y up for Godot
            export_animations=include_animations,
            export_nla_strips=include_animations,
            export_skins=True,
            export_morph=True,
            export_lights=False,
            export_cameras=False,
            export_extras=False,
        )
        return True
    except Exception as exc:
        print(f"  ✗ export FAILED: {exc}")
        return False


def main(asset: str, out_dir_override: str | None = None, dry_run: bool = False) -> int:
    if EXPORT_COLLECTION not in bpy.data.collections:
        print(f"✗ FAIL — collection '{EXPORT_COLLECTION}' not found in scene")
        print(f"  Per model spec §10, exports must come from {EXPORT_COLLECTION}.")
        return 1

    targets = expected_objects(asset)
    out_dir = out_dir_override or output_dir()
    body_glb = os.path.join(out_dir, f"{asset}.glb")
    hook_glb = os.path.join(out_dir, f"{asset}_hook.glb")

    print("=" * 60)
    print(f"PUDGE EXPORT — {asset.upper()}{' (DRY RUN)' if dry_run else ''}")
    print("=" * 60)
    print(f"Output dir: {out_dir}")
    print(f"Body GLB:   {body_glb}")
    print(f"Hook GLB:   {hook_glb}")
    print()

    state = snapshot_state()
    all_failures: list[str] = []

    try:
        # Body export
        print(f"--- Body GLB ({len(targets['body'])} objects expected) ---")
        selected, missing = isolate_for_export(targets["body"])
        if missing:
            all_failures.append(f"body export missing: {missing}")
            print(f"  ⚠ missing: {missing}")
        if not selected:
            all_failures.append("body export skipped — no objects to export")
            print(f"  ✗ skipped (no objects)")
        elif dry_run:
            print(f"  Selected: {selected}")
            print(f"  [DRY RUN] would write {body_glb}")
        else:
            print(f"  Selected: {selected}")
            if export_glb(body_glb, include_animations=True):
                size_kb = os.path.getsize(body_glb) / 1024
                print(f"  ✓ wrote {body_glb} ({size_kb:.1f} KB)")
            else:
                all_failures.append("body export failed")

        # Hook export
        print()
        print(f"--- Hook GLB ({len(targets['hook'])} objects expected) ---")
        selected, missing = isolate_for_export(targets["hook"])
        if missing:
            all_failures.append(f"hook export missing: {missing}")
            print(f"  ⚠ missing: {missing}")
        if not selected:
            all_failures.append("hook export skipped — no objects to export")
            print(f"  ✗ skipped (no objects)")
        elif dry_run:
            print(f"  Selected: {selected}")
            print(f"  [DRY RUN] would write {hook_glb}")
        else:
            print(f"  Selected: {selected}")
            if export_glb(hook_glb, include_animations=False):
                size_kb = os.path.getsize(hook_glb) / 1024
                print(f"  ✓ wrote {hook_glb} ({size_kb:.1f} KB)")
            else:
                all_failures.append("hook export failed")

    finally:
        restore_state(state)

    print()
    if all_failures:
        print(f"✗ FAIL — {len(all_failures)} issue(s):")
        for f in all_failures:
            print(f"  - {f}")
        return 1
    print("✓ PASS — both GLBs exported" + (" (dry run)" if dry_run else ""))
    return 0


if __name__ == "__main__":
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    parser = argparse.ArgumentParser()
    parser.add_argument("--asset", required=True, help="Asset name (e.g. pudge)")
    parser.add_argument("--out-dir", help="Override output directory (default: alongside .blend)")
    parser.add_argument("--dry-run", action="store_true", help="Print what would be exported, don't write GLBs")
    args = parser.parse_args(argv)
    sys.exit(main(args.asset, args.out_dir, args.dry_run))
