"""Headless Kenney-style asset generator.

Usage:
    blender -b -P tools/blender/generate.py -- <kind> <output.glb> [--seed N]

Example:
    blender -b -P tools/blender/generate.py -- barrel \
        src/assets/models/environment/generated/barrel.glb

Kinds: barrel, crate, tree, rock
"""

import sys
import argparse
from pathlib import Path

# Make `kenney_gen` importable regardless of how Blender launches this script.
THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

import bpy  # noqa: E402
from kenney_gen import primitives, heroes, export  # noqa: E402

ALL_BUILDERS = {**primitives.BUILDERS, **heroes.HERO_BUILDERS}


def parse_argv():
    # Blender passes its own args; everything after '--' is ours.
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1:]
    else:
        argv = []
    parser = argparse.ArgumentParser(prog="kenney_gen")
    parser.add_argument("kind", choices=sorted(ALL_BUILDERS.keys()))
    parser.add_argument("output", help="Output .glb path")
    parser.add_argument("--seed", type=int, default=0)
    return parser.parse_args(argv)


def main():
    args = parse_argv()

    export.clear_scene()

    builder = ALL_BUILDERS[args.kind]
    if args.kind == "rock":
        builder(seed=args.seed)
    else:
        builder()

    mat = export.setup_material()
    export.assign_material_to_all_meshes(mat)
    export.export_glb(args.output)

    print(f"[kenney_gen] wrote {args.output}")


if __name__ == "__main__":
    main()
