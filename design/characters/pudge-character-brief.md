# Pudge — Character Brief

Stage 1 deliverable. This is the contract every later stage must respect.

## Identity

- **Hero:** Pudge
- **Role:** Tank / melee disruptor (MOBA)
- **Signature ability:** Hook throw — single-target ranged grab that pulls an enemy in
- **Fantasy:** Grotesque, jovial butcher. Players should feel both intimidated and amused by him.

## Visual Style

- **Style direction:** Chibi (mobile MOBA — Brawl Stars / Vainglory readability tier)
- **Proportions:** 3 heads tall
- **Total height:** 1.4 m world units (corrected from 1.5m to match Godot loader contract)
- **Head height:** ~0.42 m (30% of total per chibi 3-head ratio)
- **Torso block:** ~0.55 m → 0.95 m
- **Hip / leg block:** 0.00 m → ~0.30 m
- **T-pose arm span:** 1.10 m (shoulder at ±0.05 → hand at ±0.55)
- **Foot stance width:** ±0.15 m

## Silhouette Priorities

In a top-down mobile camera, the player must read the character in under a second. Therefore:

1. **The hook is the silhouette.** Must be large, dark, and never visually muddled.
2. **The belly is the body.** Pudge's mass IS his silhouette — exaggerate it.
3. **Tiny legs are a feature.** Visual contrast with belly = chibi appeal.
4. **Head reads angry but not scary.** Mobile MOBA = appeals to wide audience.

## Technical Targets

- **Pose:** T-pose (arms straight out — clean Mixamo retargeting)
- **Pivot:** Floor center, between feet (world origin)
- **Forward axis:** **-Z** (Godot world convention — corrected from -Y)
- **Up axis:** +Y (Godot world convention — corrected from +Z)
- **Blender → Godot export:** Y Forward, -Z Up in the GLTF exporter (so Blender's +Z up = Godot's +Y up)
- **Camera distance in-game:** ~5-8 m, ~30° top-down angle
- **Camera distance in menu/select:** ~1.5-2 m, ~eye-level

## What This Brief Does NOT Decide

These are deferred to later stages and must be locked there:

- Polycount budget → Stage 3 (model spec)
- Texel density and texture sizes → Stage 3 (model spec)
- Material breakdown (how many materials, channel packing) → Stage 3 + 7
- Skeleton specifics (bone count, IK chains) → Stage 8
- Animation list and root motion → Stage 9

## Approval

- [x] Style: chibi — confirmed
- [x] Use case: mobile MOBA — confirmed
- [x] Camera: mid-range — confirmed
- [x] Pose: T-pose — confirmed
- [ ] Proportions confirmed visually in Blender reference rig — Stage 2
