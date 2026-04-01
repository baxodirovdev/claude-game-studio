# Player Controller

> **Status**: Designed
> **Author**: user + game-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King), Pillar 4 (Fast and Mobile-First)

## Overview

The Player Controller is the system that translates processed input into physical
hero movement and rotation within the arena. It reads movement vectors and facing
angles from the Input System, applies them to the hero's physics body against the
Arena's collision geometry, and exposes the hero's position and facing to all
downstream systems (Hook, Camera, Hero System, Health). The player interacts with
this system every frame — it is the bridge between "my thumb is pushing the
joystick" and "my hero is moving on screen." Without it, input has nowhere to go
and hooks have no origin point.

## Player Fantasy

**"I go exactly where I mean to go."** The player controller is invisible
infrastructure — when it works, the player feels like the hero IS their thumb.
There's zero gap between intent and action. The hero slides smoothly between
walls, pivots instantly to face a new direction, and stops on a dime when the
thumb lifts. The player never fights the controls, never gets stuck on geometry,
never feels like the hero is "on ice" or "in mud."

This serves Pillar 1 (Skillshot is King): since movement IS aiming, imprecise
movement means imprecise hooks. The controller must be pixel-perfect responsive
so that positioning skill translates directly to hook skill. It also serves
Pillar 4 (Mobile-First): movement must feel snappy at mobile frame rates (30-60fps)
with no input lag or smoothing that creates disconnect.

## Detailed Design

### Core Rules

**Movement**

1. Every frame, read `movement_vector` from Input System (normalized Vector2 or zero)
2. If `movement_vector != Vector2.ZERO`, move the hero at `move_speed` in that direction
3. Movement is constant speed — no acceleration, no deceleration. Instant start, instant stop
4. Movement is on the XZ plane (3D arena, isometric view). Y-axis is unused (no jumping)
5. The hero's physics body (CharacterBody3D in Godot) slides along walls using `move_and_slide()`
6. No player-to-player collision — heroes can overlap freely (per Arena GDD)

**Facing / Rotation**

1. Every frame, read `facing_angle` from Input System (float, radians)
2. The hero's visual model rotates to face `facing_angle` instantly — no turn speed, no interpolation
3. Facing is continuous 360° (per Input System GDD)
4. When joystick is released, facing holds at the last angle (Input System preserves this)

**Hook Lock**

1. When the Input System enters Locked state (hook in flight), the Player Controller
   receives `movement_vector = Vector2.ZERO` every frame
2. The hero stops moving but retains position and facing direction
3. No special handling needed — the Input System handles the lock; the controller
   just reads zero input and stays put
4. When a hooked enemy is being pulled, they are moved by the Hook System directly,
   NOT by the Player Controller. The hook overrides the pull target's position.

**Being Hooked (Pull Target)**

1. When this hero is hooked by an enemy, the Hook System takes ownership of this
   hero's position for the duration of the pull
2. The Player Controller is suspended — input is ignored, physics movement is paused
3. The hero is moved along the pull trajectory by the Hook System (linear interpolation
   from current position to hooker's position)
4. After the pull completes (hero arrives at destination), the Player Controller
   resumes and the hero can move/act normally
5. If the pull path crosses a hazard (gap, pit), the Arena/Hazard system handles
   the kill — the Player Controller is not involved

**Spawn and Initialization**

1. On match start, the Player Controller places the hero at the assigned spawn point
   (position + rotation from Arena's `get_spawn_points(team_id)`)
2. On respawn, the Respawn System sets the hero's position to the chosen spawn point;
   the Player Controller resumes from there
3. Default facing direction at spawn: toward the central gap (toward the enemy side)

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Inactive | Hero not yet spawned / match not started | Match starts OR respawn completes | No movement, no input processing. Hero entity exists but is dormant. |
| Active | Match starts / respawn completes | Hook in flight OR being pulled OR dead OR match ends | Reads input every frame, applies movement and rotation, collides with arena geometry. |
| Locked | Hook enters flight state (own hook) | Hook returns | Position frozen, facing preserved. Input reads zero. Hero cannot move. |
| Pulled | Hit by enemy hook, pull begins | Pull completes (arrives at destination) OR pull interrupted (hooker dies) | Position controlled by Hook System. Input ignored. Player Controller suspended. |
| Dead | Health reaches zero OR fell into hazard | Respawn timer completes | Hero entity hidden/disabled. No movement, no collision. Awaiting respawn. |
| Frozen | Match ends | Scene unloads | Hero stops in place. Input disabled. Visual model remains for post-match display. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Input System** | Input → Player Controller | Reads `movement_vector: Vector2` and `facing_angle: float` every frame. Per Input GDD: normalized direction, binary speed, 360° facing. |
| **Arena/Map System** | Arena → Player Controller | Hero's CharacterBody3D collides with arena's static colliders (walls, boundaries, gap edges). Uses `move_and_slide()` against arena geometry. |
| **Hook Aiming & Physics** | Hook → Player Controller | Hook System reads hero's `global_position` and `facing_angle` as the hook origin and direction. When this hero is pulled, Hook System writes to hero's position directly. |
| **Camera System** | Player Controller → Camera | Camera reads hero's `global_position` every frame to follow the player. |
| **Health & Damage** | Health → Player Controller | On death (`health_reached_zero` signal), Player Controller transitions to Dead state. On respawn, transitions back to Active. |
| **Hero System** | Hero → Player Controller | Hero System provides `move_speed` value (per-hero stat). Player Controller reads it but doesn't own it. |
| **Respawn System** | Respawn → Player Controller | On respawn, Respawn System sets hero position to spawn point and signals Player Controller to transition from Dead → Active. |
| **Networking Layer** | Player Controller ↔ Network | In networked play, Player Controller sends position/facing to server for replication. Server-authoritative: server validates movement against arena collision. |

## Formulas

### Movement Calculation

```
velocity = movement_vector * move_speed
final_position = move_and_slide(velocity * delta)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| movement_vector | Vector2 | (0,0) or unit length | Input System | Direction of movement |
| move_speed | float | 5-15 units/s | Hero data file | Per-hero movement speed |
| delta | float | 0.016-0.033 s | Engine | Frame delta time |
| velocity | Vector3 | 0 to move_speed | calculated | Applied velocity this frame (XZ plane) |

**Note**: `move_and_slide()` handles wall collision and sliding automatically.
No custom collision response needed.

### Facing Rotation

```
hero_model.rotation.y = facing_angle
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| facing_angle | float | -π to π | Input System | Current facing direction |

No interpolation. Instant rotation. The joystick IS the facing — any smoothing
creates disconnect between thumb position and hero facing.

### Pull Movement (when hooked by enemy)

```
pull_progress += pull_speed * delta
hero_position = lerp(pull_start, hooker_position, pull_progress)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| pull_start | Vector3 | arena bounds | captured at hook hit | Hero position when hooked |
| hooker_position | Vector3 | arena bounds | Hook System | Position of the player who hooked us |
| pull_speed | float | 0.5-2.0 (normalized/s) | Hero data file | How fast the pull completes (1.0 = 1 second) |
| pull_progress | float | 0.0-1.0 | calculated | Lerp parameter |

**Owned by Hook System**, not Player Controller. Listed here for interface clarity.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player is moving when hook is fired (transitions to Locked) | Hero stops instantly at current position. No momentum carry. | Binary movement — instant start/stop. No sliding or drift. |
| Player is pulled into a wall | Pull path is NOT blocked by walls. The pulled player passes through walls during the pull. | Hooks pull through geometry — otherwise every wall would break the hook mechanic. Walls block hooks, not pulls. |
| Player is pulled but hooker dies before pull completes | Pull is cancelled. Pulled player stops at their current mid-pull position. Player Controller resumes Active state. | Dead players can't hold hooks. Fair counterplay: kill the hooker to save your teammate. |
| Two enemy hooks hit the same player simultaneously | First hook to connect wins. Second hook is rejected (target already in Pulled state). | Prevents tug-of-war physics bugs. Clean ownership: one hook, one pull. |
| Player spawns inside another player | Both overlap. No collision between players (per Arena GDD). Neither is displaced. | No player-player collision means spawn overlaps are harmless. |
| Movement input arrives while in Dead state | Ignored. Player Controller is dormant in Dead state. | Dead heroes don't move. Clean state separation. |
| Hero is at arena boundary and joystick pushes toward the wall | `move_and_slide()` handles this — hero slides along the wall if there's a parallel component, or stops if pushing directly into it. | Standard physics behavior. No custom edge case handling needed. |
| move_speed is modified mid-frame (by item or ability) | New speed applies next frame. Current frame completes at old speed. | Prevents mid-frame inconsistencies. Speed changes are frame-boundary events. |
| Pull completes and hero lands on a hazard | Hazard system triggers normally (spike damage or pit/gap death). Player Controller transitions to Active, then immediately to Dead if hazard kills. | Pull destination is the hooker's position — if the hooker is standing near a hazard, that's a valid play. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Input System** | Upstream (depends on) | Hard — no movement without input | Reads `movement_vector` and `facing_angle` every frame |
| **Arena/Map System** | Upstream (depends on) | Hard — no collision without arena | CharacterBody3D collides with arena static colliders |
| **Hook Aiming & Physics** | Downstream (depends on Player Controller) | Hard — hook needs origin position and facing | Reads `global_position` and `facing_angle`; writes position during pull |
| **Camera System** | Downstream | Hard — camera needs a target to follow | Reads `global_position` every frame |
| **Health & Damage** | Downstream | Hard — needs an entity to take damage | Reads hero's collider for hit detection; signals death/respawn |
| **Hero System** | Upstream (soft) | Soft — provides `move_speed`, but controller works with a default | Reads per-hero `move_speed` from Hero data |
| **Respawn System** | Bidirectional | Hard — respawn sets position, controller resumes movement | Respawn writes spawn position; Player Controller transitions Dead → Active |
| **Networking Layer** | Bidirectional | Hard (in multiplayer) | Sends position/facing for replication; receives authoritative corrections |

**Cross-reference with Input System GDD**: Input emits `movement_vector` (Vector2, normalized)
and `facing_angle` (float, radians). Confirmed consistent — Player Controller reads
exactly these values.

**Cross-reference with Arena/Map GDD**: Arena provides static colliders, no player-player
collision. Confirmed consistent — Player Controller uses `move_and_slide()` against
arena geometry only.

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `move_speed` | 10 units/s | 5-15 units/s | Hero covers ground faster, easier to dodge hooks, harder to aim while moving | Slower hero, easier to land hooks on, more deliberate positioning |
| `pull_speed` | 1.0 (completes in 1s) | 0.5-2.0 | Faster pull — less time for teammates to react/save | Slower pull — more counterplay window, more dramatic visual |
| `spawn_facing_offset` | 0° (toward gap) | any angle | Changes which direction hero faces on spawn | — |

**Knob interactions**:
- `move_speed` is per-hero (owned by Hero System data). Player Controller reads it but
  doesn't define it. The tuning knob here is the base/default; Hero System overrides per hero.
- `move_speed` interacts with arena size — faster heroes in a small arena feel cramped.
  See Arena GDD `area_per_player` guideline.
- `pull_speed` interacts with gap width — wider gap + slow pull = longer dramatic pull
  across the chasm.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Hero moving | Footstep dust particles, subtle run animation | Light footstep sounds (surface-dependent: stone, dirt) | Medium |
| Hero stops | Idle animation blend (0.1s transition) | Footsteps stop | Low |
| Hero changes direction | Instant rotation, no turn animation | None | High (must feel instant) |
| Hero locked (hook in flight) | Hero plays "bracing" or "throwing" animation (owned by Hook System visuals) | None from Player Controller | Low |
| Hero being pulled | Hero ragdoll-slides toward hooker, trail effect behind them | Whoosh/sliding sound, increasing in pitch as speed increases | High |
| Pull completes (hero arrives) | Landing impact particles at destination | Thud/impact on arrival | High |
| Hero spawns | Fade-in or teleport flash at spawn point | Subtle spawn chime | Medium |
| Hero dies | Death animation (knockback/ragdoll), then fade out | Death sound (per hero) | High |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Hero position indicator | Arrow at screen edge if hero is off-screen (unlikely in isometric but safety net) | Every frame | Only if hero somehow exits camera view |
| Movement speed buff/debuff indicator | Small icon near hero feet | On speed change | Only when `move_speed` is modified by items/abilities |

**Notes**: The Player Controller has minimal direct UI. The hero's position on screen
IS the feedback — the isometric camera follows them. HUD elements (health bar, name)
are owned by HUD system and positioned relative to the hero's `global_position`.

## Acceptance Criteria

- [ ] Hero moves in the direction of joystick input at constant speed
- [ ] Hero stops instantly when joystick is released (no momentum, no sliding)
- [ ] Hero rotates to face joystick direction instantly (no turn speed)
- [ ] Hero collides with arena walls and slides along them via `move_and_slide()`
- [ ] Hero cannot walk across the central gap
- [ ] Hero cannot walk through arena boundary walls
- [ ] Heroes can overlap with each other (no player-player collision)
- [ ] Hero freezes in place when hook is in flight (Locked state)
- [ ] Hero is moved by Hook System when pulled (Pulled state)
- [ ] Pulled hero passes through walls during pull
- [ ] Pull is cancelled if hooker dies mid-pull
- [ ] Hero transitions to Dead state when health reaches zero
- [ ] Hero respawns at correct spawn point facing the gap
- [ ] Hero cannot move during Dead, Inactive, or Frozen states
- [ ] `move_speed` is read from Hero data (not hardcoded)
- [ ] `global_position` and `facing_angle` are readable by Hook, Camera, and other systems
- [ ] Performance: Player Controller update completes within 0.5ms per frame per player (10 players = 5ms max)
- [ ] Movement feels identical at 30fps and 60fps (delta-time correct)

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should there be a brief movement speed boost after respawn (to get back to the action faster)? | game-designer | Before prototype | Defer to playtesting. If respawn feels slow, add a 2s speed boost post-spawn. |
| Should pulled heroes have any agency during the pull (e.g., slight wiggle, ability use)? | game-designer | Before Hero System GDD | Current design: fully suspended. May revisit if pulls feel too punishing with zero counterplay. |
| Does `move_speed` ever change during a match (items, abilities, terrain)? | game-designer | Before In-Match RPG GDD | Likely yes — items may grant speed boosts. Player Controller must support runtime `move_speed` changes. |
| Should there be a visual "ghost" showing your last position when you start being pulled? | technical-artist | Before Alpha | Nice-to-have polish. Low priority for MVP. |
