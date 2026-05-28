---
name: model-spec
description: "Generate a production-ready 3D model specification covering polycount, topology, UVs, LODs, pivot, sockets, collision, and naming. Run before any modeling work begins to establish the technical contract."
argument-hint: "[asset-name or brief]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
---

When this skill is invoked, produce a detailed model specification for the
named asset. The spec is the technical contract between modeling and
downstream consumers (texturing, rigging, engine).

1. **Parse the argument** for the asset name or brief. If ambiguous, ask
   for: asset category (prop / character / environment kit piece / vehicle),
   approximate size in meters, and gameplay function.

2. **Read context**:
   - `design/gdd/art-bible.md` (if it exists) for style and budgets
   - Existing concept sheet in `design/concept-art/` if present
   - Technical budgets in `.claude/docs/technical-preferences.md`
   - Similar existing specs in `design/gdd/models/` for consistency

3. **Route to the right agent mindset**:
   - Prop / weapon / vehicle → `3d-modeler` conventions
   - Character / creature → `character-artist` conventions
   - Environment kit piece → `environment-artist` conventions

4. **Ask clarifying questions** (use `AskUserQuestion` for multi-choice):
   - Target platform tier (Low/Mid/High) — drives polycount
   - Distance to camera (hero / mid / background) — drives LOD count
   - Deformable? (rigged / static)
   - UV strategy (unique / overlapping / UDIM)
   - Material count budget
   - Needs collision? (convex / trimesh / primitive)
   - Sockets/attachments needed?

5. **Produce the spec** at `design/gdd/models/[asset-name].md` using this
   structure:

```markdown
# Model Spec — [Asset Name]

## Overview
- **Category**: [prop / character / env-kit / vehicle]
- **Gameplay function**: [one line]
- **Concept reference**: [link to concept sheet]
- **Target platform tier**: [Low / Mid / High]
- **Distance class**: [Hero / Mid / Background]

## Geometry Budget
| LOD | Tri Budget | Vert Budget | Use Distance |
|-----|------------|-------------|--------------|
| LOD0 | | | 0-10m |
| LOD1 | | | 10-25m |
| LOD2 | | | 25m+ |
| LOD3 | | | (impostor/cull) |

## Topology Requirements
- Quad dominance: [required / allowed-with-approval]
- Edge loops: [specific requirements]
- Symmetry: [mirror axis, cleanup required]
- Smoothing groups / custom normals: [approach]

## UV Layout
- Strategy: [unique / UDIM / overlapping-tiled]
- UV0: [purpose]
- UV1: [purpose — lightmap / detail / none]
- Texel density: [px/m target]
- Atlas grouping: [which other assets share this atlas, if any]

## Materials
- Count: [N]
- Per-material: [which geometry sections use which material]
- Shader target: [standard PBR / custom]

## Pivot & Transform
- Pivot location: [e.g., base center, grip point]
- Orientation: [forward axis]
- Scale: applied (1,1,1)
- Position: applied (0,0,0)

## Sockets / Attachment Points
| Name | Local Position | Local Rotation | Purpose |
|------|---------------|----------------|---------|
| | | | |

## Collision
- Type: [convex hull / trimesh / primitive box/sphere/capsule]
- Source: [auto-generated from LOD1 / hand-authored collision mesh]

## Deformation (rigged assets only)
- Rig requirements: [bone count estimate, IK chains]
- Blendshapes: [list]
- Critical edge loops: [deformation zones]

## Deliverables
- [ ] `.blend` source in `src/assets/models/[category]/[asset].blend`
- [ ] Exported `.glb` or direct `.blend` import (per project convention)
- [ ] LOD0–LODn in the same file as collections
- [ ] UV checker validation pass
- [ ] Polycount verification pass
- [ ] Handoff to texture-artist (UVs finalized)

## Open Questions
- [list]
```

6. **Update session state** at `production/session-state/active.md` with
   the spec creation entry.

7. **Output a summary**: asset name, tri budget, material count, next-step
   owner (texture-artist after UVs, rigging-animator if deformable).
