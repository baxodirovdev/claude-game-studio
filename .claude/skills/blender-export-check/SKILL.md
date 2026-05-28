---
name: blender-export-check
description: "Pre-export validation checklist for Blender → Godot 4.6 assets. Catches the common failure modes (wrong scale, unapplied transforms, broken normals, bad UVs, missing LODs) before they hit the engine."
argument-hint: "[path to .blend or asset name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

When this skill is invoked, produce a pre-export validation checklist for
the target asset. If a `.blend` path is given and Blender is installed, run
the validation via a headless Blender script; otherwise emit a manual
checklist the user runs in Blender's Scripting workspace.

1. **Parse the argument** for the asset name or `.blend` path. If ambiguous,
   list recent `.blend` files under `src/assets/models/`.

2. **Read context**:
   - The asset's model spec at `design/gdd/models/[asset].md` (for budgets
     to check against)
   - The Blender specialist's conventions at
     `.claude/agents/blender-specialist.md`
   - Project engine reference at `docs/engine-reference/godot/VERSION.md`
     (confirm Godot 4.6 import rules)

3. **Attempt automated validation**: if `blender --version` succeeds,
   offer to run a validation script. Otherwise, emit the manual checklist.

### Automated Validation Script

Write `tools/blender/validate_export.py` (if not already present) with
checks below, then run:

```bash
blender "<asset>.blend" --background --python tools/blender/validate_export.py
```

Checks performed:

- [ ] **Scale**: all objects have scale (1.0, 1.0, 1.0). Report any with
      non-unit scale.
- [ ] **Transforms**: location and rotation applied (0,0,0 / 0,0,0) unless
      intentionally placed (report deviations).
- [ ] **Modifiers**: list unapplied modifiers per object. Flag modifiers
      that Godot's importer won't evaluate.
- [ ] **Mesh integrity**: no loose vertices, no non-manifold edges on
      visible faces, no zero-area faces.
- [ ] **N-gons**: count faces with >4 verts. Fail if any on deformable
      meshes; warn for props.
- [ ] **Normals**: check for flipped normals (inside-out faces).
- [ ] **UVs**: every mesh has at least UV0. Warn if UV1 missing when the
      model spec expected lightmap UV2.
- [ ] **UV overlaps**: detect overlapping UV islands (warn, since some are
      intentional).
- [ ] **Materials**: material slot count matches model spec.
- [ ] **Tri count**: compute and compare to LOD budget in model spec.
- [ ] **Armature (if present)**: root bone at origin, scale 1, no non-uniform
      scale on any bone.
- [ ] **Animation data (if present)**: every action has at least one keyframe;
      no broken F-curve modifiers.
- [ ] **Naming**: object/mesh/material/armature names follow project
      conventions (lowercase, underscores, matching asset name).
- [ ] **Collections**: if project uses collection-based LOD grouping,
      verify LOD0/LOD1/LOD2 collections present.
- [ ] **Custom properties**: if project tags assets with metadata custom
      props, verify presence.

### Manual Checklist (if automation unavailable)

Output a copy-paste checklist for the user to run in Blender:

```
[ ] Select all → Object → Apply → All Transforms
[ ] Edit Mode → Mesh → Clean Up → Delete Loose
[ ] Edit Mode → Select All → Mesh → Normals → Recalculate Outside
[ ] Edit Mode → Select → All by Trait → Faces by Sides (> 4) — should select 0
[ ] N panel → Item → Dimensions match spec (within 5%)
[ ] Object Data Properties → UV Maps → UV0 present (and UV1 if spec requires)
[ ] Material Properties → material count matches spec
[ ] Statistics overlay (top-right) → tri count ≤ LOD0 budget
[ ] Armature: Object mode → scale 1, rotation 0; Pose mode → rest pose valid
[ ] Dope Sheet → Action Editor → every expected action present
[ ] File → External Data → Report missing files
```

4. **Produce the validation report** at
   `production/session-logs/export-check-[asset]-[date].md`:

```markdown
# Blender Export Check — [Asset] — [Date]

## Summary
- **Asset**: [name]
- **Blender version**: [version]
- **Target**: Godot 4.6 direct .blend import
- **Status**: [PASS / WARNINGS / FAIL]

## Checks

### ✅ Passed
- [list]

### ⚠️ Warnings
- [issue + recommendation]

### ❌ Failed
- [issue + required fix]

## Next Steps
- [ ] Fix failed checks
- [ ] Re-run validation
- [ ] Hand off to Godot import (technical-artist)
```

5. **Update session state** with the validation result.

6. **Output a summary** with PASS/FAIL count and the blocking issues (if
   any). If PASS, confirm the asset is ready for Godot import.
