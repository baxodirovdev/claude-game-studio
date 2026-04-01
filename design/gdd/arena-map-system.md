# Arena/Map System

> **Status**: Designed
> **Author**: user + game-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King), Pillar 4 (Fast and Mobile-First)

## Overview

The Arena/Map System defines the physical space where all gameplay occurs: a
symmetrical, divided 3D arena viewed from an isometric camera. The arena is split
by a central gap (river/chasm) that players cannot walk across — hooks are the
only way to interact with the other side. Each team spawns on their half, and the
map provides walls, obstacles, and hazard zones that create sightlines, cover, and
positional decisions. The player interacts with this system passively — they move
through it, use its geometry for cover, and exploit its hazards to kill enemies
pulled by hooks. Without this system, there is no space for the hook fantasy to
exist: no gap to hook across, no walls to hide behind, no pits to pull enemies into.

## Player Fantasy

**"My side, your side — come and get me."** The central gap creates a no-man's-land
that turns every hook into a cross-map kidnapping. You're safe on your side, peeking
around walls, jockeying for angle — and then someone lands a hook and drags you
screaming across the chasm into enemy territory. The arena is the stage for a
tug-of-war: you want to pull them to your side while staying safe on yours.

The symmetrical layout means no team has a terrain advantage — the only advantage
is positioning and hook skill. Walls and obstacles create a chess-like quality:
"If I stand here, I can hook through that gap but I'm exposed from the left."
The arena teaches itself through play — after a few matches, players develop
favorite spots, sneaky angles, and hazard traps they set up with hooks.

This serves Pillar 1 (Skillshot is King): the arena geometry IS what makes hooks
skillful. Without walls to block, gaps to cross, and angles to exploit, hooks
would just be "point at enemy, press button." The map creates the spatial puzzle.

## Detailed Design

### Core Rules

**Arena Structure**

1. The arena is a rectangular 3D space viewed from an isometric camera angle
2. The arena is divided into two symmetrical halves by a central gap (river/chasm)
3. Each half is a mirror of the other — identical wall placement, hazard placement, and spawn points
4. The arena is bounded by impassable walls on all four edges (no falling off the sides)
5. All geometry is static during a match — nothing moves, spawns, or despawns

**Central Gap**

1. The gap runs the full width of the arena, dividing it into Team A side and Team B side
2. Players **cannot walk across** the gap — it blocks all ground movement
3. Hooks **can fly across** the gap freely — the gap does not block projectiles
4. A hooked player **is pulled across** the gap to the hooker's side — this is the core mechanic
5. Falling into the gap = instant death. Respawn timer begins immediately
6. The gap has a fixed width (tunable) — narrow enough for all hero hook types to reach across

**Walls and Obstacles**

1. Walls are solid geometry that block both player movement and hook projectiles
2. Walls create sightlines — hooks can only hit what they can reach in a straight line
3. Obstacles come in two sizes:
   - **Full walls**: tall enough to block hooks and line of sight completely
   - **Half walls**: block player movement but hooks fly over them (creates mind-game angles)
4. Walls are placed symmetrically — every wall on Team A's side has a mirror on Team B's side
5. Wall placement creates lanes, choke points, and flanking routes on each side

**Hazard Zones**

1. **Central Gap** (instant kill): Falling in = death. Players pulled by hooks can be dragged into the gap if the hook path crosses it and the pull ends mid-gap
2. **Spike Zones** (heavy damage): Small marked areas near the gap edges on both sides. Stepping on or being pulled into spikes deals a burst of damage (tunable). Does not kill at full health — meant to soften targets
3. **Pits** (instant kill): Holes in the ground on each team's side. Walking into a pit kills you. Pulling an enemy to your side near a pit can drop them in. Smaller than the central gap but equally lethal
4. All hazards are visually distinct — different color, particle effects, and audio cues
5. Hazard zones are placed symmetrically on both halves
6. Hazards affect all players equally — your own team can die to your own side's pits

**Spawn Points**

1. Each team has 5 spawn points on their half (one per max player)
2. Spawn points are located at the far edge of each side (away from the gap) — safe zone
3. Respawning players have brief invulnerability (owned by Respawn System, not Arena)
4. Spawn points are never placed near hazards

**Arena Dimensions (MVP map)**

1. Total arena size: rectangular, roughly 80×50 game units (tunable)
2. Central gap width: ~6 game units (tunable — must be crossable by all hook types)
3. Each team's half: ~80×22 game units of playable space
4. Designed for 10 players (5v5) — enough space to maneuver but small enough that hooks can reach threats

### States and Transitions

The Arena itself is static — it doesn't change state during gameplay. However,
the Arena System tracks match-level spatial state:

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Loading | Match State Manager requests map load | All geometry spawned, collision ready, spawn points registered | Loads arena scene, builds navigation mesh, registers hazard zones and spawn points with relevant systems |
| Active | Match State Manager signals match start | Match State Manager signals match end | All collision active, hazard zones dealing damage, spawn points available. No changes to geometry. |
| Frozen | Match ends (final kill / timer) | Results screen dismissed, transition to lobby | Collision remains but hazards stop dealing damage. Arena is cosmetic only — players can't die post-match. |
| Unloading | Lobby transition begins | Scene fully freed from memory | Arena scene is removed, all references cleared. Next map can load. |

**Hazard zone states** (per hazard instance):

| State | Behavior |
|-------|----------|
| Idle | Hazard is visually active (particles, glow) but no player is in the zone |
| Triggered | A player entered the zone — deal damage (spikes) or kill (gap/pit). Visual intensity spikes. Audio sting plays. |
| Cooldown (spikes only) | After dealing damage, spikes have a brief cooldown before they can damage the same player again. Prevents instant re-triggering if player is stuck on spikes. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Controller** | Arena → Player Controller | Provides collision geometry — walls, boundaries, gap edges. Player Controller uses physics body against arena's static colliders to prevent walking through walls or into the gap. |
| **Camera System** | Arena → Camera | Provides arena bounds for camera clamping. Camera reads arena dimensions to set zoom level and prevent showing beyond arena edges. |
| **Match State Manager** | Match State → Arena | Sends `load_map(map_id)`, `match_started`, `match_ended` signals. Arena transitions between Loading/Active/Frozen states accordingly. |
| **Hook Aiming & Physics** | Arena → Hook System | Provides wall colliders for hook projectile collision. Full walls block hooks; half walls do not. Hook raycasts against arena geometry to detect hits vs. misses. |
| **Map Hazards** | Arena → Map Hazards | Arena owns hazard zone placement (position, size, type). Map Hazards system owns the gameplay logic (damage, kill, cooldown). Arena provides `get_hazard_zones()` returning a list of `{position, size, type}`. |
| **Respawn System** | Arena → Respawn | Provides spawn point positions via `get_spawn_points(team_id)`. Respawn System picks which spawn point to use. Arena guarantees spawn points are safe (far from hazards, on the correct team's side). |
| **Health & Damage** | Arena → Health (indirect via Map Hazards) | Hazard zones produce damage events. Arena defines where hazards are; Map Hazards + Health & Damage handle the actual damage/kill. |

## Formulas

### Arena Sizing Validation

```
max_hook_range = max(hero_hook_ranges[])  # longest hook in the game
min_gap_crossing = max_hook_range >= gap_width  # must be true for all heroes
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| gap_width | float | 4-10 units | arena data file | Width of the central gap |
| hero_hook_ranges[] | float[] | per hero | Hero System data | Each hero's maximum hook range |
| max_hook_range | float | derived | calculated | Longest hook in the roster |

**Constraint**: `gap_width < min(hero_hook_ranges[])` — every hero must be able
to hook across the gap. If a new hero is added whose hook can't cross, either
increase their range or narrow the gap.

### Spike Zone Damage

```
spike_damage = spike_base_damage * (1.0 + spike_scaling_per_minute * match_time_minutes)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| spike_base_damage | float | 20-40 HP | arena data file | Damage dealt on first contact |
| spike_scaling_per_minute | float | 0.0-0.1 | arena data file | Optional scaling to make spikes more dangerous as match progresses |
| match_time_minutes | float | 0-8 | Match State Manager | Current match elapsed time |
| spike_damage | float | 20-80 HP | calculated | Actual damage per trigger |

**Design intent**: Spikes should deal ~25-30% of a hero's max HP at match start.
They soften targets, they don't one-shot. Scaling is optional — set
`spike_scaling_per_minute = 0` for flat damage.

### Playable Area Per Player

```
playable_area = (arena_width * half_depth) - hazard_area_total
area_per_player = playable_area / max_players_per_team
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| arena_width | float | 60-100 units | arena data file | Total width |
| half_depth | float | 15-30 units | arena data file | Depth of one team's half |
| hazard_area_total | float | calculated | arena data file | Sum of all hazard zone areas on one half |
| max_players_per_team | int | 1-5 | match config | Max players on one side |
| area_per_player | float | target: 150-300 sq units | calculated | Breathing room per player |

**Guideline**: If `area_per_player < 100`, the map feels cramped and hook dodging
becomes impossible. If `area_per_player > 400`, players can't find each other and
matches drag.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player is pulled by hook and the pull path ends exactly over the gap | Player falls into gap and dies. The pull does not "snap" to the nearest safe ground. | The gap is lethal — if the hook trajectory puts you in the gap, you die. This is a core skill play. |
| Player is pulled by hook into a pit on the enemy's side | Player falls into pit and dies. Kill credit goes to the hooker. | Pulling enemies into hazards is an intended strategy. |
| Player is pulled by hook into spike zone | Player takes spike damage and lands in the spike zone. They can walk out if alive. | Spikes soften, they don't trap. Being pulled into spikes is bad but survivable at full HP. |
| Player walks into their own team's pit | Player dies. Kill credit = suicide (no enemy credited). | Hazards affect all players — no team immunity. Punishes careless positioning. |
| Two players occupy the same narrow space between walls | Both players can overlap. No player-to-player collision blocking. | Player-blocking would create griefing (teammates block you into hazards). Overlap is the lesser evil. |
| Hook hits a full wall mid-flight | Hook stops and returns. No damage, no pull. The wall ate it. | Walls are the primary counterplay to hooks — positioning behind cover is how you survive. |
| Hook flies over a half wall | Hook continues past the half wall and can hit players on the other side. | Half walls create the mind-game: "Am I safe here or not?" They block movement but not hooks. |
| All 5 spawn points occupied by living players when a 6th needs to respawn | Cannot happen — max 5 players per team, one spawn per player. If a player is alive on a spawn point, another dead player uses a different spawn. Respawn System picks the least contested point. | Spawn points = max team size. Always enough. |
| Map loads but match hasn't started yet (countdown phase) | Arena is in Active state but players can't move (Input System disables during countdown). Hazards are visually active but deal no damage until match starts. | Prevents pre-match deaths from spawning near hazards (shouldn't happen by design, but defense in depth). |
| Player disconnects while standing on a hazard | Player entity is removed. No death event — disconnects are handled by networking, not by arena hazards. | Clean separation: arena handles spatial gameplay, networking handles connection state. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Player Controller** | Downstream (depends on Arena) | Hard — needs collision geometry to move | Reads static colliders for wall/boundary collision |
| **Camera System** | Downstream (depends on Arena) | Hard — needs bounds for clamping and zoom | Reads `get_arena_bounds()` returning `{min, max, center}` |
| **Match State Manager** | Upstream (Arena reads from Match) | Hard — arena lifecycle controlled by match state | Receives `load_map`, `match_started`, `match_ended` signals |
| **Hook Aiming & Physics** | Downstream (depends on Arena) | Hard — needs wall colliders for projectile raycast | Hook raycasts against arena collision layers. Full walls = blocking layer. Half walls = separate non-blocking layer. |
| **Map Hazards** | Downstream (depends on Arena) | Hard — needs hazard zone positions and types | Reads `get_hazard_zones()` → `[{position, size, type, collision_shape}]` |
| **Respawn System** | Downstream (depends on Arena) | Hard — needs spawn point positions | Reads `get_spawn_points(team_id)` → `[{position, rotation}]` |
| **Health & Damage** | Indirect (via Map Hazards) | Soft — arena doesn't call Health directly | Map Hazards translates hazard contact into damage events for Health & Damage |

**No upstream gameplay dependencies.** This is a foundation system. Match State
Manager controls its lifecycle, but the arena itself depends on nothing to define
its geometry. It is the most depended-upon system in the game (6 direct dependents).

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `arena_width` | 80 units | 60-100 units | More flanking routes, harder to find enemies, longer matches | Tighter, more chaotic, more accidental hook hits |
| `half_depth` | 22 units | 15-30 units | More room to retreat from gap, safer positioning, slower pace | Less retreat space, more aggressive play, hooks reach spawn |
| `gap_width` | 6 units | 4-10 units | Harder to hook across (requires long-range heroes), more tension | Easier to hook across, faster kills, less positional play |
| `spike_base_damage` | 30 HP | 20-40 HP | Spikes become more punishing, pulling into spikes is near-lethal | Spikes are ignorable, no reason to avoid them |
| `spike_scaling_per_minute` | 0.05 | 0.0-0.1 | Late-game spikes become deadly, forces aggressive play to end matches | Spikes stay flat, no late-game pressure |
| `spike_cooldown` | 1.0 s | 0.5-2.0 s | Player can escape spikes between hits | Spikes rapidly re-trigger, standing on them is near-instant death |
| `spike_zone_radius` | 3 units | 2-5 units | Larger danger area, harder to avoid when pulled | Smaller, more precise hazard — rewards accurate hook placement |
| `pit_radius` | 2 units | 1.5-3 units | Easier to pull enemies into, but also more dangerous for your own team | Requires very precise hook placement to pit someone |
| `full_wall_count_per_half` | 4 | 2-8 | More cover, more complex sightlines, harder to land hooks | Open arena, hooks fly freely, less strategic depth |
| `half_wall_count_per_half` | 3 | 0-6 | More mind-game angles (safe from movement, not from hooks) | Fewer surprises, what you see is what you get |

**Knob interactions**:
- `gap_width` and hero hook ranges interact — gap must always be crossable by every hero
- `arena_width` and `full_wall_count` interact — too many walls in a small arena creates a maze, too few in a large arena creates an empty field
- `spike_base_damage` and hero max HP interact — spikes should deal 25-30% of max HP at match start

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Arena load complete | Fly-in camera sweep showing both sides of the arena | Arena ambient music begins (per-map theme) | High |
| Central gap (ambient) | Swirling void/mist particles, faint glow at edges | Low rumble or wind sound, continuous ambient | High |
| Player falls into gap | Player ragdolls downward, disappears into mist | Falling scream + impact thud (muffled) | High |
| Spike zone (ambient) | Glowing spike geometry, pulsing red/orange particles | Faint crackling/sizzling loop | Medium |
| Spike zone triggered | Spike flash brightens, blood/spark burst on player | Sharp metallic impact sting | High |
| Pit (ambient) | Dark hole with faint downward particle drift | Faint wind whistle | Medium |
| Pit triggered | Player ragdolls downward into darkness | Falling scream (shorter than gap fall) | High |
| Full wall | Solid, opaque geometry — clearly reads as "you can't go through or hook through this" | None (static) | High |
| Half wall | Translucent top half or broken/low geometry — clearly reads as "hooks fly over" | None (static) | High |
| Match frozen (post-end) | Hazard particles slow down, colors desaturate slightly | Ambient audio fades to 50% volume | Low |

**Art direction notes**:
- Hazards must be instantly readable at isometric zoom — distinct colors (gap = dark blue/void, spikes = red/orange, pits = black)
- Full walls vs half walls must be visually unambiguous — half walls should be obviously shorter/broken
- Low-poly stylized aesthetic (Brawl Stars reference) — clean silhouettes over realistic detail

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Team side indicator | Brief flash at match start ("You are Team A / Blue Side") | Once at match start | First 3 seconds of match |
| Hazard warning | On-screen icon when player is near a hazard edge | When player is within warning radius | During gameplay, proximity-based |
| Minimap (future) | Top-right corner, shows arena layout + player dots | Every 0.5s | Not in MVP — defer to Vertical Slice |

**Layout notes**:
- The arena itself IS the primary visual — UI should be minimal and not block the isometric view
- Hazard zones must be self-documenting through art, not through UI labels
- No in-world floating text on hazards — rely on visual/audio design for readability

## Acceptance Criteria

- [ ] Arena loads from scene file with all geometry, colliders, and hazard zones in correct positions
- [ ] Central gap blocks player movement (cannot walk across)
- [ ] Hooks fly across the central gap without obstruction
- [ ] Hooked players are pulled across the gap to the hooker's side
- [ ] Falling into the central gap kills the player instantly
- [ ] Full walls block both player movement and hook projectiles
- [ ] Half walls block player movement but allow hooks to pass over
- [ ] Spike zones deal correct damage on contact with cooldown between triggers
- [ ] Pits kill players instantly on contact (walk-in or pulled-in)
- [ ] All hazards affect all players regardless of team
- [ ] Arena is perfectly symmetrical — mirrored geometry, hazards, and spawn points
- [ ] Spawn points are on the far edge of each side, away from all hazards
- [ ] Arena bounds prevent players from leaving the playable area
- [ ] `get_hazard_zones()` returns correct data for Map Hazards system
- [ ] `get_spawn_points(team_id)` returns correct positions for Respawn System
- [ ] `get_arena_bounds()` returns correct bounds for Camera System
- [ ] Arena transitions correctly through Loading → Active → Frozen → Unloading states
- [ ] Hazards stop dealing damage in Frozen state (post-match)
- [ ] No player-to-player collision blocking (players can overlap)
- [ ] Performance: Arena scene renders within frame budget on target mobile devices (10 players + effects)
- [ ] All dimension and damage values loaded from data files — no hardcoded values

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the gap have bridges or crossing points that unlock mid-match (e.g., after 3 minutes)? Would add strategic depth but complicates the "hooks only cross" rule. | game-designer | Before Vertical Slice | Start without bridges for MVP. Playtest whether pure hook-only crossing is fun enough. |
| What's the exact isometric camera angle? 45°? 30°? Affects how much of the arena is visible and how wall heights read. | game-designer + technical-artist | Before prototype | Prototype with 45° (classic iso) and adjust based on feel. |
| Should hazard placement vary between matches on the same map (semi-random) or be 100% fixed? | game-designer | Before Alpha (multiple maps) | Fixed for MVP — players learn the map. Consider semi-random for future maps to add replayability. |
| How do asymmetric team sizes (1v5, 2v3) affect arena feel? Does the solo player need more cover on their side? | game-designer + level-designer | Before Vertical Slice | Playtest with symmetric arena first. If asymmetric teams feel unfair spatially, consider dynamic wall placement per team size. |
| What's the visual theme for the MVP map? Floating island? Underground cavern? Colosseum? | art-director | Before art production | Defer to art direction. Gameplay-neutral — theme is cosmetic. |
