"""Kenney-style palette: 16 named RGB colors. Each face is painted with one of
these colors via per-vertex color attributes (not a texture) so we avoid
mipmap / block-compression artifacts on tiny palette images."""

import bpy
from pathlib import Path

PALETTE = [
    ("wood_light",   (0.95, 0.78, 0.50)),
    ("wood",         (0.80, 0.57, 0.33)),
    ("wood_dark",    (0.58, 0.38, 0.22)),
    ("metal",        (0.76, 0.80, 0.84)),
    ("metal_dark",   (0.46, 0.50, 0.54)),
    ("leaf",         (0.52, 0.80, 0.40)),
    ("leaf_dark",    (0.34, 0.60, 0.32)),
    ("stone",        (0.80, 0.80, 0.76)),
    ("stone_dark",   (0.55, 0.55, 0.55)),
    ("dirt",         (0.64, 0.48, 0.32)),
    ("water",        (0.06, 0.22, 0.62)),
    ("red",          (0.92, 0.38, 0.30)),
    ("orange",       (0.98, 0.62, 0.25)),
    ("yellow",       (1.00, 0.88, 0.35)),
    ("bone",         (1.00, 0.94, 0.82)),
    ("black",        (0.20, 0.20, 0.22)),
    # Rocky / basalt tones tuned for the arena's FILMIC tonemap (tonemap_white
    # = 6.0 + ambient + fill light ≈ 1.5× brightness uplift on surfaces).
    ("rock",         (0.38, 0.38, 0.42)),
    ("rock_dark",    (0.22, 0.22, 0.26)),
    ("rock_moss",    (0.30, 0.35, 0.26)),
    # Warm tan beach edge — tuned darker than literal sand so the FILMIC
    # tonemap brightens it back up to a proper sandy color in the arena.
    ("sand",         (0.72, 0.56, 0.32)),
    ("sand_dark",    (0.62, 0.46, 0.24)),
    ("sand_wet",     (0.48, 0.34, 0.18)),
    # Tuned to match arena_data.gd ground_color exactly so the bank's outer
    # vertex-gradient edge is visually identical to the arena grass.
    ("grass_bright", (0.40, 0.68, 0.26)),
    # Hero palette additions — skin tones, cloak / robe / fur colors,
    # accent hues for weapons and energy effects.
    ("skin_peach",   (0.96, 0.78, 0.62)),
    ("skin_pale",    (1.00, 0.88, 0.76)),
    ("hair_brown",   (0.30, 0.18, 0.12)),
    ("purple",       (0.55, 0.28, 0.78)),
    ("cyan",         (0.32, 0.82, 0.95)),
    ("gold",         (0.95, 0.76, 0.20)),
    ("deep_blue",    (0.18, 0.22, 0.50)),
    ("cloak_purple", (0.30, 0.20, 0.45)),
    ("blood",        (0.62, 0.12, 0.10)),
    ("fur_orange",   (0.94, 0.52, 0.12)),
    ("fur_dark",     (0.34, 0.22, 0.14)),
    # Pudge — sickly pallid yellow-green flesh tones (Dota 2 Butcher).
    # Not bright leaf-green; more like rotting cabbage / jaundiced flesh.
    ("pudge_skin",      (0.52, 0.55, 0.34)),
    ("pudge_skin_dark", (0.36, 0.40, 0.24)),
    ("pudge_flesh",     (0.62, 0.50, 0.38)),
]

PALETTE_NAMES = [n for n, _ in PALETTE]
PALETTE_SIZE = len(PALETTE)


def rgb_for_color(name):
    for n, rgb in PALETTE:
        if n == name:
            return rgb
    raise ValueError(
        f"Unknown palette color: {name}. Available: {PALETTE_NAMES}"
    )


def ensure_palette_image(path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        return path

    img = bpy.data.images.new(
        "kenney_palette", width=PALETTE_SIZE, height=1, alpha=False
    )
    pixels = []
    for _, (r, g, b) in PALETTE:
        pixels.extend([r, g, b, 1.0])
    img.pixels = pixels
    img.filepath_raw = str(path)
    img.file_format = 'PNG'
    img.save()
    return path


def uv_for_color(name):
    if name not in PALETTE_NAMES:
        raise ValueError(
            f"Unknown palette color: {name}. Available: {PALETTE_NAMES}"
        )
    idx = PALETTE_NAMES.index(name)
    u = (idx + 0.5) / PALETTE_SIZE
    v = 0.5
    return (u, v)