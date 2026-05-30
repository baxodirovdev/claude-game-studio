"""Verify the hook prop mesh is weighted 100% to LeftHand only.

Per `design/gdd/contracts/pudge-interface-contract.md` §3 and rig spec §5,
the hook prop `mesh_pudge_hook_*` must be weighted exclusively to the
`mixamorig:LeftHand` bone. Any non-zero weight on any other vertex group
will cause the hook to deform incorrectly when detached as a projectile
during the `hook_throw` ability.

Run headless from project root:
    blender path/to/asset.blend --background --python tools/blender/verify_hook_weights.py -- --asset pudge

Or via Blender's Scripting workspace — just `exec(open(...).read())`.

Exit 0 = PASS, non-zero = FAIL. Stdout shows offending bones + vertex count.
"""

from __future__ import annotations

import argparse
import sys

import bpy


# Accepted bone names for the hook attachment.
# Blender authoring uses `mixamorig:LeftHand`; the glTF importer in Godot
# sanitizes the colon to underscore. Either form is valid pre-export.
HOOK_BONE_NAMES = {"mixamorig:LeftHand", "mixamorig_LeftHand"}

# Below this weight a vertex is considered effectively zero
# (Blender stores tiny float dust on auto-skin output).
WEIGHT_EPSILON = 1e-4


def check_hook_mesh(obj: bpy.types.Object) -> tuple[list[str], int]:
    """Return (failures, total_verts_checked) for the hook mesh's weighting."""
    failures: list[str] = []
    mesh = obj.data
    total_verts = len(mesh.vertices)

    # Map vertex_group index → group name
    group_names = {g.index: g.name for g in obj.vertex_groups}

    # Track which non-hook groups have any non-zero influence
    bad_group_weight: dict[str, int] = {}

    # And how many verts are unweighted to any hook bone (must be 0)
    verts_missing_hook_weight = 0

    for vert in mesh.vertices:
        has_hook_weight = False
        for ge in vert.groups:
            name = group_names.get(ge.group, f"<idx_{ge.group}>")
            weight = ge.weight
            if weight < WEIGHT_EPSILON:
                continue
            if name in HOOK_BONE_NAMES:
                has_hook_weight = True
            else:
                bad_group_weight[name] = bad_group_weight.get(name, 0) + 1
        if not has_hook_weight:
            verts_missing_hook_weight += 1

    for name, count in sorted(bad_group_weight.items()):
        failures.append(
            f"  ✗ vertex group '{name}' has non-zero weight on {count} verts "
            f"(must be 0 — hook ties only to LeftHand)"
        )
    if verts_missing_hook_weight > 0:
        failures.append(
            f"  ✗ {verts_missing_hook_weight} verts have NO weight to "
            f"mixamorig:LeftHand (must be 100% to LeftHand)"
        )

    return failures, total_verts


def main(asset: str) -> int:
    hook_meshes = [
        f"mesh_{asset}_hook_lod0",
        f"mesh_{asset}_hook_lod1",
        f"mesh_{asset}_hook_lod2",
    ]
    print("=" * 60)
    print(f"HOOK WEIGHT CHECK — {asset.upper()}")
    print("=" * 60)
    print(f"Required: 100% weight to one of {HOOK_BONE_NAMES}, 0% elsewhere")
    print()

    total_failures = 0
    found_any = False

    for name in hook_meshes:
        obj = bpy.data.objects.get(name)
        if obj is None:
            print(f"  – {name}: not present (skip)")
            continue
        if obj.type != 'MESH':
            print(f"  – {name}: not a mesh (skip)")
            continue
        found_any = True
        failures, vert_count = check_hook_mesh(obj)
        if failures:
            print(f"  ✗ {name} ({vert_count} verts) — {len(failures)} issue(s):")
            for line in failures:
                print(line)
            total_failures += len(failures)
        else:
            print(f"  ✓ {name} ({vert_count} verts) — clean")

    if not found_any:
        print("✗ FAIL — no hook mesh objects found")
        return 1

    print()
    if total_failures == 0:
        print("✓ PASS — hook weighting is contract-compliant")
        return 0
    print(f"✗ FAIL — {total_failures} weighting issue(s) across hook LODs")
    return 1


if __name__ == "__main__":
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    parser = argparse.ArgumentParser()
    parser.add_argument("--asset", required=True, help="Asset name (e.g. pudge)")
    args = parser.parse_args(argv)
    sys.exit(main(args.asset))
