# Respawn System

> **Status**: Designed
> **Author**: user + game-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 4 (Fast and Mobile-First)

## Overview

The Respawn System handles what happens after a hero dies: the death timer, spawn
point selection, health restoration, invulnerability window, and re-entry into
gameplay. The player experiences this as a brief pause (3-5 seconds) followed by
reappearing at their team's spawn area. The system must be fast and frictionless —
death is frequent in Hook Wars, and every second spent dead is a second not playing.
Without this system, death would be permanent and matches would empty out.

## Player Fantasy

**"I'm back. And this time I'm aiming better."** Death is a brief timeout, not a
punishment. The respawn timer is just long enough to process what happened ("that
hook came from the left, I need to watch that angle") and short enough that the
player never puts their phone down. The spawn is safe, the invulnerability gives
breathing room, and within 5 seconds of dying, the player is back in the action.

This serves Pillar 4 (Fast and Mobile-First): 5-minute matches with 3-5s respawns
mean a player dying 5 times loses only 15-25 seconds total. Death is cheap.
Learning is fast. The game never stops.

## Detailed Design

### Core Rules

**Respawn Timer**

1. On hero death, a respawn timer begins (default: 3 seconds)
2. Timer is displayed to the dead player on their screen
3. Timer cannot be shortened by player action (no "tap to respawn faster")
4. During Overtime, respawn timer may be increased (tunable — adds pressure)
5. Timer does not start until the death animation completes (~0.5s)

**Spawn Point Selection**

1. Read available spawn points from Arena via `get_spawn_points(team_id)`
2. Select the spawn point furthest from all living enemy players
3. If multiple points are equidistant, pick randomly among them
4. Never spawn a player at a point occupied by a living teammate (if avoidable)
5. If all spawn points have teammates, pick the one with the fewest nearby

**Respawn Execution**

1. When timer expires:
   - Set hero position to selected spawn point (Player Controller)
   - Restore health to `max_health` (Health & Damage)
   - Grant invulnerability for `invulnerability_duration` (default: 2s)
   - Transition Player Controller from Dead → Active
   - Signal Camera to snap to new position
2. Hero appears at spawn with a brief visual effect (fade-in/flash)
3. Hero can move and act immediately (input enabled)
4. Hook is ready (no cooldown carried over from death)

**Invulnerability**

1. Post-respawn invulnerability lasts `invulnerability_duration` (default: 2s)
2. During invulnerability: all hook damage blocked, spike damage blocked, hook
   pulls blocked (hook bounces off)
3. Invulnerability does NOT protect from instant-kill hazards (gap/pit) per
   Health & Damage GDD
4. Hero can attack during invulnerability (fire hooks, deal damage)
5. Invulnerability has a clear visual indicator (flashing/glow)
6. Invulnerability expires naturally — no early cancellation

**No Respawn Conditions**

1. During Ended/Frozen match states, no respawns occur
2. Dead players at match end remain dead for the results screen

### States and Transitions

**Per-Player Respawn State**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Alive | Respawn completes | Hero dies | Not managed by Respawn System — other systems handle alive gameplay |
| Death Animation | `hero_died` signal received | Animation completes (~0.5s) | Death VFX plays. Player sees their death. Timer hasn't started yet. |
| Waiting | Death animation completes | Respawn timer expires | Timer counting down. Player sees death screen / spectates killer briefly. |
| Spawning | Timer expires | Hero placed at spawn, invulnerability granted | Instant transition. Hero appears at spawn. |
| Invulnerable | Spawning completes | Invulnerability timer expires | Hero can move and act. Protected from hooks/spikes. Visual indicator active. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Health & Damage** | Health → Respawn | Listens to `hero_died` signal to start respawn timer. Calls `restore_health(max_health)` and `set_invulnerable(duration)` on respawn. |
| **Player Controller** | Respawn → Player Controller | Sets hero position to spawn point. Signals transition from Dead → Active. |
| **Arena/Map System** | Arena → Respawn | Reads `get_spawn_points(team_id)` for spawn point selection. |
| **Camera System** | Respawn → Camera | Signals `hero_respawned` for camera snap to new position. |
| **Input System** | Indirect (via Player Controller) | Input re-enables when Player Controller enters Active state. |
| **Match State Manager** | Match State → Respawn | During Ended state, respawns are blocked. During Overtime, respawn timer may increase. |
| **HUD** | Respawn → HUD | HUD reads respawn timer countdown for display. |
| **Score/Kill Tracking** | Indirect | Death count already tracked by Score via Health. Respawn doesn't interact with Score. |

## Formulas

### Respawn Timer

```
respawn_time = base_respawn_time + (overtime_penalty if in_overtime else 0)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_respawn_time | float | 2-5 s | tuning knob | Default respawn duration (default: 3s) |
| overtime_penalty | float | 0-3 s | tuning knob | Extra time added during overtime (default: 2s) |
| respawn_time | float | 2-8 s | calculated | Actual wait time |

### Spawn Point Selection

```
for each spawn_point in team_spawn_points:
    min_enemy_distance = min(distance(spawn_point, enemy) for enemy in living_enemies)
    score = min_enemy_distance - (teammate_nearby_penalty if teammate_within_3_units else 0)
selected_spawn = spawn_point with highest score
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| team_spawn_points | Array | 5 points | Arena System | Available spawn positions for this team |
| living_enemies | Array | 0-5 | game state | Enemies currently alive |
| teammate_nearby_penalty | float | 2-5 units | tuning knob | Penalty for spawning near a teammate (default: 3) |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player dies during Overtime | Respawn with overtime penalty timer. Higher stakes — each death costs more time. | Overtime should feel tense. Longer respawn = more pressure. |
| Player dies at exact moment match ends | No respawn. Player stays dead for results screen. | Match is over. No gameplay after Ended state. |
| All spawn points have teammates on them | Pick the spawn point with the fewest nearby teammates. Overlap is fine (no player-player collision). | Per Arena/Player Controller GDD: players can overlap. Spawn overlap is harmless. |
| All enemies are dead when selecting spawn point | Pick any spawn point randomly. No enemy threat to optimize against. | Edge case in casual play. Random is fine. |
| Player disconnects and reconnects during respawn timer | Timer continues from where it was. Reconnect doesn't reset or skip the timer. | Fair play. Reconnect shouldn't grant advantage. |
| Player dies to gap while invulnerable (post-respawn) | Player dies. Respawn timer starts again. New spawn will use different point selection. | Instant-kill hazards override invulnerability. Dying twice quickly is the player's fault (walking into gap). |
| Two players on the same team die simultaneously | Both get independent respawn timers and independent spawn point selection. | Each respawn is independent. No batching or group spawn. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Health & Damage** | Upstream | Hard — needs death event to trigger | Listens to `hero_died` signal. Calls `restore_health`, `set_invulnerable`. |
| **Player Controller** | Downstream | Hard — sets spawn position, triggers state change | Writes position, signals Dead → Active |
| **Arena/Map System** | Upstream | Hard — needs spawn point positions | Reads `get_spawn_points(team_id)` |
| **Camera System** | Downstream | Soft — snap to spawn is nice-to-have | Signals `hero_respawned` |
| **Match State Manager** | Upstream | Hard — must respect match end (no respawns) | Reads current match state |
| **HUD** | Downstream | Soft — timer display | Exposes `respawn_time_remaining` |

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `base_respawn_time` | 3.0 s | 2-5 s | Longer death penalty, each death costs more | Faster re-entry, death feels cheap |
| `overtime_penalty` | 2.0 s | 0-3 s | Higher overtime stakes, longer vulnerability | Overtime feels like normal play |
| `invulnerability_duration` | 2.0 s | 1-4 s | Safer respawn, harder to spawn camp | Riskier respawn, possible spawn kills |
| `death_animation_duration` | 0.5 s | 0.3-1.0 s | Longer death lingering, more dramatic | Faster transition to timer |
| `teammate_nearby_penalty` | 3.0 units | 0-5 units | Avoids clustering spawns | Allows spawning near teammates |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Death (start of respawn) | Death animation, screen briefly desaturates | Death sound (per hero) | High |
| Respawn timer counting | Timer number displayed center-screen, ticking down | Subtle tick per second | Medium |
| Respawn (appearing) | Hero fades in / teleport flash at spawn point. Brief invulnerability glow. | Spawn chime (hopeful, brief) | High |
| Invulnerability active | Hero model flashes white/gold, shield particle ring | Faint shimmer hum | Medium |
| Invulnerability expiring | Flash fades, brief "shield down" particle pop | Shield-down chime | Medium |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Respawn timer | Center screen (large, countdown) | Every 0.1s | While dead, waiting to respawn |
| "YOU DIED" text | Center screen, above timer | On death | While dead |
| Killer info | Below "YOU DIED" ("[Hero name] killed you") | On death | While dead, shows who killed you |
| Invulnerability indicator | Small shield icon on health bar | While invulnerable | Post-respawn |

## Acceptance Criteria

- [ ] Respawn timer starts after death animation completes
- [ ] Timer counts down correctly and displays to the dead player
- [ ] Hero respawns at the safest available spawn point (furthest from enemies)
- [ ] Health restored to `max_health` on respawn
- [ ] Invulnerability granted for correct duration post-respawn
- [ ] Invulnerability blocks hook damage and spike damage
- [ ] Invulnerability does NOT block instant-kill hazards (gap/pit)
- [ ] Hero can move and attack during invulnerability
- [ ] Hook cooldown reset on respawn (hook ready immediately)
- [ ] No respawns during Ended/Frozen match states
- [ ] Overtime penalty increases respawn timer correctly
- [ ] Camera snaps to spawn position on respawn
- [ ] Multiple simultaneous deaths on same team handled independently
- [ ] All respawn values loaded from config — no hardcoded values

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should dead players be able to spectate teammates while waiting? | ux-designer | Before Vertical Slice | Nice feature but not MVP. During the 3s timer, show killer briefly then fade to spawn. |
| Should respawn timer scale with match time (longer respawns later)? | game-designer | Before prototype | Start with flat timer. If late-game feels too fast-paced, add scaling. |
| Should invulnerability end early if the player fires a hook? | game-designer | Before prototype | Could prevent "invulnerable aggression." Start without — test if invulnerable hook-spam is a problem. |
