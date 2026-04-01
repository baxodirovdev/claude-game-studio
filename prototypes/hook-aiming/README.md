# Hook Aiming Prototype

**PROTOTYPE — NOT FOR PRODUCTION**

## Core Question
Does hook-based combat with "joystick = movement AND aiming" feel satisfying on
mobile touchscreen?

## How to Run
1. Open this folder as a Godot 4.6 project
2. Run the main scene (`main.tscn`)
3. On desktop: mouse simulates touch (left click = touch)
4. On mobile: export to Android/iOS and test with real touch

## Controls
- **Left thumb (left half of screen)**: Virtual joystick — move and aim
- **Right thumb (right half of screen)**: Tap anywhere to fire hook

## What to Test
1. **Does aiming via movement feel natural?** Can you point at targets intuitively?
2. **Does the "locked while hook flies" feel OK?** Or does it feel punishing?
3. **Is hook speed right?** Can targets be hit at ~20 unit range?
4. **Is the hitbox forgiveness right?** Do near-misses feel fair?
5. **Does the cross-gap hook feel dramatic?** Pulling targets across the gap?

## What to Measure
- Hook accuracy (displayed on screen: fired / hit / miss)
- Subjective feel: responsive? sluggish? too fast? too slow?
- Time to feel competent with the controls

## Tuning Knobs (hardcoded in main.gd)
- `MOVE_SPEED`: 10
- `HOOK_SPEED`: 30
- `HOOK_RANGE`: 25
- `HOOK_COOLDOWN`: 2.0
- `HOOK_HITBOX_RADIUS`: 1.0
- `PULL_DURATION`: 0.5
