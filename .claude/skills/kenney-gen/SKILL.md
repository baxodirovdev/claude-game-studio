---
name: kenney-gen
description: "Generate Kenney-style low-poly .glb assets via headless Blender (bpy). Procedurally builds primitive props (barrel, crate, tree, rock) and a modular river kit (straight, corner, end, rocks, bridge, water, bank, bank_corner, source) with a flat palette material. Godot-ready output. No hand modeling required."
argument-hint: "[kind] [output-path] [--seed N]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

When this skill is invoked, procedurally generate a Kenney-style 3D asset
using the headless Blender pipeline at `tools/blender/`.

## Prerequisites (verify first)

1. **Blender installed**: the pipeline assumes the macOS path
   `/Applications/Blender.app/Contents/MacOS/Blender`. On first use, verify
   with `--version`. If absent, emit a clear error with install instructions.
2. **Generator present**: `tools/blender/generate.py` exists.

## Invocation

Parse the argument. The authoritative list of supported kinds is the
`BUILDERS` dict at the bottom of
`tools/blender/kenney_gen/primitives.py` — read it if the user asks what
is available. Current kinds: props (`barrel`, `crate`, `tree`, `rock`) and
river kit (`river_straight`, `river_corner`, `river_end`, `river_rocks`,
`river_bridge`, `river_water`, `river_bank`, `river_bank_corner`,
`river_source`).

If the kind is missing or invalid, list available kinds and ask for a
choice. If the output path is missing, default to
`src/assets/models/environment/generated/<kind>.glb`.

## River Composition Cheat-Sheet

All river tiles are 2m × 2m and snap to a 2m grid.

- **Narrow river (1 tile wide)**: chain `river_straight` along +X.
  Use `river_corner` for 90° turns (rotate 0/90/180/270° for other
  orientations). `river_end` caps with grass; `river_source` caps with
  open water + rock spring.
- **Wide river (N tiles wide)**: bracket the middle with bank rows —
  `river_bank` (rotated 180° for north, as-is for south) — and fill the
  interior rows with `river_water`.
- **Corner of a wide river (land meets water on two sides)**: use
  `river_bank_corner` in the four outer corners.
- **Beginning/end continues as water**: use `river_water` at the map
  edge, or `river_source` for a stylized spring cluster. Do NOT use
  `river_end` if you want the river to flow off-map.

Flow convention (for straight/corner):
- `river_straight` flows along +X
- `river_corner` enters from -X edge, exits through +Y edge
- `river_end` flow enters from -X, terminates at +X in grass
- `river_source` water fills the tile; rock spring is at +X edge

## Run

Execute:

```bash
/Applications/Blender.app/Contents/MacOS/Blender \
    --background \
    --python tools/blender/generate.py \
    -- <kind> <output.glb> [--seed N]
```

The command should complete in under 10 seconds. Blender prints a lot of
startup noise; the important line is `[kenney_gen] wrote <path>`.

## Validate

After the command returns:
- Confirm the `.glb` file exists and is between 1 KB and 200 KB (Kenney
  props are typically 5–50 KB).
- Godot will auto-import on its next scene load; a `.glb.import` sidecar
  will appear.

## Extending

To add a new primitive (e.g., `fence`, `bottle`, `chest`):
1. Add a `make_<kind>()` builder to
   `tools/blender/kenney_gen/primitives.py`
2. Register it in the `BUILDERS` dict at the bottom of that file
3. Re-run this skill with the new kind name

The palette is defined in `tools/blender/kenney_gen/palette.py` — add new
named colors there if a new kind needs them.

## What This Skill Does NOT Do

- Does not produce characters, creatures, or rigged/animated assets
  (procedural generation of Kenney-style is intentionally limited to
  primitive-based props).
- Does not upgrade assets with PBR maps, LODs, or lightmap UV2 (those
  uplifts belong to `texture-artist` and `technical-artist`).
- Does not replace the `team-3d-asset` pipeline for bespoke work — this
  is a fast path for Kenney-style filler props.

## Output Summary

Emit a one-line confirmation with kind, output path, and file size.
