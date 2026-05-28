---
name: texture-spec
description: "Generate a PBR texture/material specification covering resolution, channel packing, compression, texel density, and naming. Run before texturing an asset to establish the material contract."
argument-hint: "[asset-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
---

When this skill is invoked, produce a PBR texture specification for the named
asset. The spec is the contract between the texture artist and the engine-side
material setup.

1. **Parse the argument** for the asset name. If unclear, ask for: asset
   category and a link to the model spec.

2. **Read context**:
   - The asset's model spec at `design/gdd/models/[asset].md` (required —
     UV layout and material count come from here)
   - `design/gdd/art-bible.md` for material language callouts
   - Technical budgets in `.claude/docs/technical-preferences.md`
   - Existing texture specs in `design/gdd/materials/` for consistency

3. **Ask clarifying questions** (use `AskUserQuestion`):
   - Resolution per map (512 / 1K / 2K / 4K)
   - Channel packing convention (project default ORM, or custom)
   - Tiling: tileable / unique / hybrid trim sheet?
   - Variants required? (damaged / wet / snow / bloody)
   - Texel density target (if not set in art bible)
   - Compression target (BC7 / BC5 / uncompressed / lossy OGG-equivalent)

4. **Produce the spec** at `design/gdd/materials/[asset-name].md`:

```markdown
# Texture Spec — [Asset Name]

## Overview
- **Model reference**: `design/gdd/models/[asset].md`
- **Material count**: [N] (matches model spec)
- **Texel density target**: [px/m]
- **Total texture memory budget**: [MB]

## Per-Material Specs

### Material 1 — [name]
- **Resolution (Base)**: [1K / 2K / 4K]
- **Resolution (Normal)**: [same or reduced]
- **Resolution (ORM)**: [same or reduced]
- **Maps produced**:
  - `[asset]_[mat]_BC.png` — BaseColor, sRGB, 8-bit RGB(A)
  - `[asset]_[mat]_N.png` — Normal, Linear, 8-bit RG (BC5) or RGB
  - `[asset]_[mat]_ORM.png` — AO/Rough/Metal packed, Linear, 8-bit RGB
  - `[asset]_[mat]_E.png` — Emissive (if needed), sRGB HDR-capable
  - `[asset]_[mat]_M.png` — ID/Mask (if variants needed), Linear
- **Channel packing**: R=AO, G=Roughness, B=Metallic (project default)
- **Compression target (Godot import)**: VRAM Compressed (BC7 for BC/E,
  BC5 for Normal, BC4 for single-channel)
- **sRGB flag**: BaseColor=ON, Normal=OFF, ORM=OFF, Emissive=ON

## Bake Sources (for baked normals/AO)
- High-poly source: [.blend location]
- Cage: [required / auto]
- Bake maps produced: normal, AO, curvature, cavity, position, ID

## PBR Value Ranges
- Albedo: within 30–240 sRGB (physically-correct dielectric range)
- Metal values: 0 or 1 (binary) with roughness 0.1–0.4 for polished,
  0.5–0.9 for weathered
- Dielectric roughness: 0.15 (polished plastic) to 0.95 (rough cloth)

## Tiling / Trim Sheet (if applicable)
- Tile scale: [meters per tile]
- Seamless: horizontal / vertical / both
- Trim strip assignments (if trim sheet):
  | Strip Y-range | Use | Tiling axis |

## Variants
- [list masks and what they swap]

## Memory Budget
| Map | Resolution | Format | Size (approx) |
|-----|-----------|--------|---------------|
| BC | 2K | BC7 | 5.3 MB |
| N | 2K | BC5 | 5.3 MB |
| ORM | 2K | BC7 | 5.3 MB |
| **Total** | | | **~16 MB** |

## Deliverables
- [ ] Source files (.psd / .spp) in `src/assets/textures/source/`
- [ ] Exported PNGs in `src/assets/textures/[category]/`
- [ ] `.tres` material resource in Godot (set up by technical-artist)
- [ ] Texel density verified with checker
- [ ] Memory budget verified against total

## Open Questions
- [list]
```

5. **Update session state** after writing.

6. **Output a summary**: material count, total memory estimate, bake
   requirements, next-step owner.
