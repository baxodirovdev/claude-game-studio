"""Blender → Godot 4.6 export validator.

Run headless from project root:
    blender path/to/asset.blend --background --python tools/blender/validate_export.py -- --asset pudge

Or via MCP / Scripting workspace — just `exec(open(...).read())`.

Validates the current .blend against the interface contract at
`design/gdd/contracts/pudge-interface-contract.md` and the model spec at
`design/gdd/models/pudge.md`:

- Applied transforms (scale 1, loc 0, rot 0) on export objects
- No unapplied modifiers
- No n-gons on deformable meshes
- No non-manifold edges
- UV0 present on every mesh
- Material slots populated
- Armature at origin with unit scale
- Naming convention (snake_case, type prefix)
- Tri counts vs LOD budget from spec
- `jiggle_boundary` vertex color layer on body LODs (contract §6)
- Bone count on armature matches MVP target (contract §3)
- Expected export objects live inside PUDGE_NEW_BUILD collection (spec §10)

Outputs a structured report to stdout. Non-zero exit if any FAIL-level issues.
"""

from __future__ import annotations

import argparse
import re
import sys

import bpy
import bmesh


# Naming convention: lowercase + underscores
NAMING_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")

# Helpers / references / temporary objects we skip in naming check
NAMING_SKIP_PREFIXES = (
    "REF_", "BO_", "pose_helper_", "prop_", "Cube",
    "Camera", "Light", "Chibi", "Untitled",
)

# LOD tri budgets per model spec §2 (hard ceilings).
# Format: { "body_lod0": (working_target, hard_ceiling), ... }
LOD_BUDGETS = {
    "body_lod0": (5400, 6000),
    "body_lod1": (2700, 3000),
    "body_lod2": (1350, 1500),
    "hook_lod0": (600, 600),
    "hook_lod1": (300, 300),
    "hook_lod2": (150, 150),
}

# Per contract §3: MVP bone count = 22 (20 Mixamo humanoid + BellyJiggle + Jaw).
# Allow 21 (no Jaw) or 24 (with twist bones) without failing; 26 (with chain) warns.
MVP_BONE_COUNT = 22
ACCEPTABLE_BONE_RANGE = (21, 26)

# Per spec §10: export objects must live in this collection.
EXPORT_COLLECTION = "PUDGE_NEW_BUILD"

# Per contract §6: vertex color layer name (exact string).
JIGGLE_LAYER_NAME = "jiggle_boundary"


def expected_export_objects(asset: str) -> list[str]:
    """The object names the spec requires in the final export."""
    return [
        f"mesh_{asset}_body_lod0",
        f"mesh_{asset}_body_lod1",
        f"mesh_{asset}_body_lod2",
        f"mesh_{asset}_hook_lod0",
        f"mesh_{asset}_hook_lod1",
        f"mesh_{asset}_hook_lod2",
        f"arm_{asset}",
        asset,  # scene root empty
    ]


def lod_budget_for_name(name: str) -> tuple[int, int] | None:
    """Return (working, ceiling) tri budget for a mesh name, or None if not budgeted."""
    for key, budget in LOD_BUDGETS.items():
        if name.endswith(f"_{key}"):
            return budget
    return None


def object_collections(obj: bpy.types.Object) -> list[str]:
    """Names of all collections an object belongs to."""
    return [c.name for c in obj.users_collection]


def has_jiggle_layer(mesh: bpy.types.Mesh) -> bool:
    """Check if mesh has the jiggle_boundary vertex color layer (any data type)."""
    if hasattr(mesh, "color_attributes"):
        return any(a.name == JIGGLE_LAYER_NAME for a in mesh.color_attributes)
    return any(layer.name == JIGGLE_LAYER_NAME for layer in mesh.vertex_colors)


def count_deform_bones(armature: bpy.types.Object) -> int:
    """Count bones in the armature data-block."""
    if armature.type != 'ARMATURE':
        return 0
    return len(armature.data.bones)


def check_object(obj: bpy.types.Object) -> dict:
    """Run all per-object checks. Returns a dict of issues."""
    issues = {}
    s = tuple(round(c, 4) for c in obj.scale)
    if s != (1.0, 1.0, 1.0):
        issues["scale"] = s
    loc = tuple(round(c, 4) for c in obj.location)
    if loc != (0.0, 0.0, 0.0):
        issues["location"] = loc
    rot = tuple(round(c, 4) for c in obj.rotation_euler)
    if rot != (0.0, 0.0, 0.0):
        issues["rotation"] = rot
    if obj.modifiers:
        issues["modifiers"] = [(m.name, m.type) for m in obj.modifiers]
    return issues


def check_mesh(obj: bpy.types.Object) -> dict:
    """Mesh-specific checks: tri count, n-gons, manifold, UVs."""
    issues = {}
    mesh = obj.data
    if not mesh.uv_layers:
        issues["no_uv0"] = True
    if not obj.material_slots or all(
        s.material is None for s in obj.material_slots
    ):
        issues["no_material"] = True

    bm = bmesh.new()
    bm.from_mesh(mesh)
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    ngons = sum(1 for f in bm.faces if len(f.verts) > 4)
    nm_edges = sum(1 for e in bm.edges if not e.is_manifold)
    bm.free()

    issues["tris"] = tris
    if ngons > 0:
        issues["ngons"] = ngons
    if nm_edges > 0:
        issues["non_manifold_edges"] = nm_edges
    return issues


def main(asset: str) -> int:
    expected = expected_export_objects(asset)
    present = {o.name: o for o in bpy.data.objects}

    expected_present = [n for n in expected if n in present]
    expected_missing = [n for n in expected if n not in present]

    failures: list[str] = []
    warnings: list[str] = []

    # Per-object checks on existing expected objects
    for name in expected_present:
        obj = present[name]
        obj_issues = check_object(obj)
        if obj_issues.get("scale"):
            failures.append(f"{name}: scale {obj_issues['scale']} (must be 1,1,1)")
        if obj_issues.get("location"):
            failures.append(
                f"{name}: location {obj_issues['location']} (must be 0,0,0)"
            )
        if obj_issues.get("rotation"):
            failures.append(
                f"{name}: rotation {obj_issues['rotation']} (must be 0,0,0)"
            )
        if obj_issues.get("modifiers"):
            failures.append(
                f"{name}: unapplied modifiers {obj_issues['modifiers']}"
            )

        # Collection placement check (spec §10) — only enforced if PUDGE_NEW_BUILD exists.
        if EXPORT_COLLECTION in bpy.data.collections:
            cols = object_collections(obj)
            if EXPORT_COLLECTION not in cols:
                failures.append(
                    f"{name}: not in {EXPORT_COLLECTION} collection "
                    f"(found in: {cols or ['<none>']})"
                )

        if obj.type == 'MESH':
            mesh_issues = check_mesh(obj)
            if mesh_issues.get("no_uv0"):
                failures.append(f"{name}: missing UV0")
            if mesh_issues.get("no_material"):
                warnings.append(f"{name}: no material assigned")
            if mesh_issues.get("ngons"):
                failures.append(
                    f"{name}: {mesh_issues['ngons']} n-gons (>4 vert faces)"
                )
            if mesh_issues.get("non_manifold_edges"):
                warnings.append(
                    f"{name}: {mesh_issues['non_manifold_edges']} non-manifold edges"
                )

            # LOD tri budget check (model spec §2)
            budget = lod_budget_for_name(name)
            if budget is not None:
                tris = mesh_issues["tris"]
                working, ceiling = budget
                if tris > ceiling:
                    failures.append(
                        f"{name}: {tris} tris exceeds hard ceiling {ceiling} "
                        f"(working target {working})"
                    )
                elif tris > working:
                    warnings.append(
                        f"{name}: {tris} tris over working target {working} "
                        f"(ceiling {ceiling}, within budget)"
                    )

            # jiggle_boundary layer check on body LODs only (contract §6)
            if "_body_lod" in name and not has_jiggle_layer(obj.data):
                failures.append(
                    f"{name}: missing vertex color layer '{JIGGLE_LAYER_NAME}' "
                    f"(required by contract §6 for BellyJiggle weight derivation)"
                )

        if obj.type == 'ARMATURE':
            bone_count = count_deform_bones(obj)
            lo, hi = ACCEPTABLE_BONE_RANGE
            if bone_count < lo or bone_count > hi:
                failures.append(
                    f"{name}: {bone_count} bones outside acceptable range "
                    f"{lo}-{hi} (MVP target {MVP_BONE_COUNT}, contract §3)"
                )
            elif bone_count != MVP_BONE_COUNT:
                warnings.append(
                    f"{name}: {bone_count} bones differs from MVP target "
                    f"{MVP_BONE_COUNT} (acceptable but flag if unintentional)"
                )

    # Naming check across all non-helper objects
    for obj in bpy.data.objects:
        if any(obj.name.startswith(p) for p in NAMING_SKIP_PREFIXES):
            continue
        if not NAMING_PATTERN.match(obj.name):
            warnings.append(f"naming: {obj.name} does not match snake_case")

    # Export collection itself must exist (spec §10)
    if EXPORT_COLLECTION not in bpy.data.collections:
        warnings.append(
            f"collection: '{EXPORT_COLLECTION}' not found in scene "
            f"(spec §10 requires it; export will fall back to whole-scene mode)"
        )

    # Missing export objects
    for name in expected_missing:
        failures.append(f"missing expected export object: {name}")

    # Print report
    print("=" * 60)
    print(f"BLENDER EXPORT CHECK — {asset.upper()}")
    print("=" * 60)
    print(f"Blender: {bpy.app.version_string}")
    print(f"Expected export objects present: {len(expected_present)}/{len(expected)}")
    print(f"Failures: {len(failures)}    Warnings: {len(warnings)}")
    print()

    if failures:
        print("--- FAILURES ---")
        for f in failures:
            print(f"  ✗ {f}")
        print()
    if warnings:
        print("--- WARNINGS ---")
        for w in warnings:
            print(f"  ⚠ {w}")
        print()

    if not failures:
        print("✓ PASS — ready for export")
        return 0
    print("✗ FAIL — fix failures before export")
    return 1


if __name__ == "__main__":
    # Strip Blender's own args before --
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    parser = argparse.ArgumentParser()
    parser.add_argument("--asset", required=True, help="Asset name (e.g. pudge)")
    args = parser.parse_args(argv)
    sys.exit(main(args.asset))
