# Map Hazards

> **Status**: Designed
> **Author**: user + game-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King)

## Overview

The Map Hazards system manages the gameplay logic for environmental dangers in the
arena: the central gap, spike zones, and pits. It detects when players enter hazard
zones, applies damage or instant kills, tracks cooldowns on repeating hazards, and
attributes kills to the correct source (suicide vs. hook-assisted). The player
interacts with hazards passively — by avoiding them and actively — by hooking enemies
into them. Without hazards, the arena is just flat ground and hooks are the only way
to die. Hazards add positional stakes: where you stand matters as much as where you aim.

## Player Fantasy

**"Get over here — into the pit."** Hazards are the hook's best friend. The central
gap makes every hook a kidnapping. The pits let skilled players set traps — stand near
a pit, hook an enemy to your side, they land in the hole. Spikes punish careless
positioning near the gap edge. The arena is a minefield that rewards players who
memorize hazard positions and use them as weapons.

This serves Pillar 1 (Skillshot is King): hazards multiply the value of hook accuracy.
A hook that pulls someone into a gap is an instant kill regardless of health. A hook
near spikes deals bonus damage. Positional mastery IS skill.

## Detailed Design

### Core Rules

**Hazard Types**

1. **Central Gap** — instant kill zone
   - Runs the full width of the arena between the two halves
   - Any player whose position enters the gap area dies immediately
   - Triggers on: walking into the edge, being pulled through/into by a hook
   - Kill type: `HAZARD_INSTANT_KILL`
   - No cooldown — always lethal

2. **Pits** — instant kill zones
   - Small holes in the ground on each team's side (symmetrical placement)
   - Any player whose position enters a pit area dies immediately
   - Triggers on: walking in, being pulled in by a hook
   - Kill type: `HAZARD_INSTANT_KILL`
   - No cooldown — always lethal
   - Smaller than the gap but equally deadly

3. **Spike Zones** — heavy damage zones
   - Marked areas near the gap edges on both sides (symmetrical)
   - Players entering a spike zone take burst damage
   - Triggers on: walking in, being pulled through/into
   - Kill type: `HAZARD_SPIKE`
   - Has a per-player cooldown between damage triggers
   - Non-lethal at full health (deals ~25-30% max HP)

**Hazard Detection**

1. Each hazard zone has a collision area (Area3D in Godot) that detects player overlap
2. Detection runs every physics frame
3. When a player's position overlaps a hazard zone:
   - Instant kill hazards (gap, pit): call `Health.take_damage(999999, null, HAZARD_INSTANT_KILL)` immediately
   - Spike zones: call `Health.take_damage(spike_damage, null, HAZARD_SPIKE)` if not on cooldown for this player
4. Hazard zones are static — positions defined by Arena, never move during a match

**Kill Attribution**

1. If a player walks into a hazard on their own: suicide (no killer credited)
2. If a player is hooked and the pull path enters a hazard: hooker gets kill credit
   (via Health & Damage kill credit window — 3s per Health GDD)
3. If a player is damaged by spikes from a hook pull and later dies to spikes while
   walking: hooker only gets credit if within the 3s window
4. Kill attribution is owned by Health & Damage system, not Map Hazards. Map Hazards
   only produces the damage event.

**Hazard Lifecycle**

1. Hazard zones are created during arena loading (Arena System owns placement)
2. Hazard gameplay logic activates when match enters Playing state
3. Hazards stop dealing damage when match enters Frozen state (post-match)
4. Hazard visuals remain active in Frozen state (particles continue, no gameplay effect)

### States and Transitions

**Per Hazard Instance**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Inactive | Arena loading / match not started | Match enters Playing state | Visuals active (particles, glow). No damage on contact. |
| Active | Match enters Playing | Match enters Frozen/Ended | Full damage on player contact. Spike cooldowns tracked. |
| Frozen | Match ends | Arena unloads | Visuals continue. No damage. Cooldowns cleared. |

**Per-Player Spike Cooldown**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Vulnerable | Default / cooldown expired | Player enters spike zone | Player can take spike damage |
| On Cooldown | Spike damage dealt to this player | Cooldown timer expires | This player is immune to THIS spike zone. Other spike zones can still damage. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Arena/Map System** | Arena → Hazards | Arena provides hazard zone data: `get_hazard_zones()` → `[{position, size, type, collision_shape}]`. Hazards system creates Area3D nodes from this data. |
| **Health & Damage** | Hazards → Health | Calls `take_damage(amount, null, HAZARD_SPIKE)` or `take_damage(999999, null, HAZARD_INSTANT_KILL)` on player contact. |
| **Player Controller** | Indirect | Player Controller moves the hero; if hero position enters hazard zone, Hazard system detects overlap. No direct API call. |
| **Hook Aiming & Physics** | Indirect | During pull, victim's interpolated position may enter hazard zones. Hazard system detects this through normal overlap detection — no special hook interface needed. |
| **Match State Manager** | Match State → Hazards | Receives `match_started` (activate), `match_ended` (freeze). |
| **VFX/Feedback System** | Hazards → VFX | Emits `hazard_triggered(type, position, victim)` for visual/audio responses. |

## Formulas

### Spike Damage

```
spike_damage = spike_base_damage * (1.0 + spike_scaling_per_minute * match_time_minutes)
```

Referenced from Arena/Map GDD. Values:

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| spike_base_damage | float | 20-40 HP | arena data | Base damage per trigger (default: 30) |
| spike_scaling_per_minute | float | 0.0-0.1 | arena data | Per-minute scaling (default: 0.05) |
| match_time_minutes | float | 0-8 | Match State Manager | Elapsed match time |

**Example**: At match start (0 min), spike damage = 30. At 4 min, spike damage = 30 * 1.2 = 36. At max match time, spike damage = 30 * 1.4 = 42.

### Spike Cooldown

```
can_damage = (current_time - last_spike_damage_time[player_id]) >= spike_cooldown_duration
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| spike_cooldown_duration | float | 0.5-2.0 s | tuning knob | Time between spike triggers per player (default: 1.0s) |
| last_spike_damage_time | dict | per player per spike zone | tracked | Timestamp of last damage to each player |

### Hazard Kill Validation

```
is_suicide = (last_hooker == null) or (time_since_last_pull > kill_credit_window)
killer = is_suicide ? null : last_hooker
```

Owned by Health & Damage system. Map Hazards passes `source = null` in all
`take_damage` calls. Health & Damage handles attribution via its kill credit window.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player is pulled across the gap and the pull path only clips the gap edge | If player's position enters the gap collision at any point during pull, they die. No "close calls" — the gap has hard boundaries. | Gap is instant kill. Even partial overlap is lethal. Clear, simple rule. |
| Player is pushed out of a spike zone by... nothing (there's no knockback) | Player walks out voluntarily. Spike cooldown protects them for 1s. If they walk back in after cooldown, they take damage again. | No knockback in this game. Players walk out or die. |
| Two spike zones overlap in placement | Player takes damage from whichever zone they entered first. Second zone's cooldown is independent. In practice, overlapping spikes shouldn't exist — arena design prevents this. | Zones are independent. But arena should never have overlapping hazards. |
| Player dies on spikes, respawns, walks back to same spikes | Fresh cooldown state on respawn. Player takes damage normally. | Respawn clears all per-player cooldown tracking. Clean slate. |
| Spike zone damages a player to exactly 0 HP | Player dies. Death type: HAZARD_SPIKE. Normal death processing. | Spikes CAN kill — they deal burst damage that can finish a low-HP player. |
| Player is invulnerable (post-respawn) and walks through gap | Player dies. Instant-kill hazards override invulnerability (per Health & Damage GDD). | Gap/pit kills are absolute. Invulnerability only protects from hooks and spikes. |
| Player is invulnerable and walks on spikes | No damage. Invulnerability blocks HAZARD_SPIKE damage. | Per Health & Damage GDD: invulnerability blocks all damage except instant-kill hazards. |
| Hazard visual particles obscure gameplay | Particles must be low-opacity, ground-level only. Never obscure hero models or hook projectiles. | Readability first. Hazards are marked zones, not visual clutter. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Arena/Map System** | Upstream | Hard — provides hazard positions and types | Reads `get_hazard_zones()` at arena load |
| **Health & Damage** | Downstream | Hard — hazards deal damage through Health | Calls `take_damage(amount, null, type)` |
| **Match State Manager** | Upstream | Hard — hazard activation tied to match state | Receives `match_started`, `match_ended` |
| **Hook Aiming & Physics** | Indirect | Soft — pull path may cross hazards, but no direct API | Hazard overlap detection handles pull-through naturally |
| **VFX/Feedback System** | Downstream | Soft — emits events for visual/audio | Emits `hazard_triggered` signal |

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `spike_base_damage` | 30 HP | 20-40 HP | Spikes more punishing, hook-into-spikes more valuable | Spikes ignorable, less positional consequence |
| `spike_scaling_per_minute` | 0.05 | 0.0-0.1 | Late-game spikes scarier, forces action | Flat damage throughout match |
| `spike_cooldown_duration` | 1.0 s | 0.5-2.0 s | Player has time to escape between hits | Rapid re-triggers, standing on spikes is devastating |
| `spike_zone_radius` | 3 units | 2-5 units | Larger danger area, harder to avoid | Smaller, more precise |
| `pit_radius` | 2 units | 1.5-3 units | Easier to fall in / pull into | Requires precise hook placement |
| `gap_width` | 6 units | 4-10 units | Wider gap, more dramatic pulls, harder to hook across | Narrower, easier cross-gap hooks |

**Knob interactions**:
- `spike_base_damage` and `max_health` (Hero GDD) — spikes should deal 25-30% of average max HP
- `pit_radius` and `hook_range` — pits should be hookable-into from meaningful distance
- `gap_width` and `min(hero_hook_ranges)` — gap must be crossable by all heroes

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Gap (ambient) | Swirling void/mist particles, faint edge glow | Low rumble/wind, continuous | High |
| Gap kill | Player falls, disappears into mist | Falling scream + muffled impact | Critical |
| Spike zone (ambient) | Glowing spike geometry, pulsing red/orange particles | Faint crackling loop | Medium |
| Spike triggered | Flash intensifies, spark burst on player | Sharp metallic impact | High |
| Spike cooldown active | Brief dim of spike glow (subtle) | None | Low |
| Pit (ambient) | Dark hole, faint downward particle drift | Faint wind whistle | Medium |
| Pit kill | Player falls into darkness | Short falling scream | Critical |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Hazard damage number | Floating above player (world-space) | On spike damage | Shows spike damage value |
| Spike zone indicator | Ground-level glow in arena (world-space, not HUD) | Static | Always visible — part of arena art |

**Notes**: Hazards are communicated through world-space art and VFX, not HUD elements.
The arena teaches hazard locations through visual design.

## Acceptance Criteria

- [ ] Central gap kills any player whose position enters the gap area
- [ ] Pits kill any player whose position enters the pit area
- [ ] Spike zones deal correct damage with scaling on player contact
- [ ] Spike per-player cooldown prevents rapid re-triggers
- [ ] Hazards affect all players regardless of team
- [ ] Invulnerability blocks spike damage but not gap/pit kills
- [ ] Hazard zones activate on match start, freeze on match end
- [ ] Hazard positions match Arena System's `get_hazard_zones()` data
- [ ] Kill credit correctly attributed (suicide vs. hook-assisted via Health GDD window)
- [ ] Pull path through hazards triggers hazard on the victim
- [ ] Hazard visuals are distinct and readable at isometric zoom on mobile
- [ ] No hazard particle effects obscure hero models or hooks
- [ ] All hazard values loaded from data files — no hardcoded values
- [ ] Performance: hazard overlap detection within 0.2ms per frame for all zones

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should hazards scale in danger over match time (spikes grow, pits widen)? | game-designer | Before Vertical Slice | Spike damage scales. Physical size stays fixed for MVP. Dynamic hazards could add excitement in future maps. |
| Should there be a warning indicator when being pulled toward a hazard? | ux-designer | Before prototype | Pro: gives feedback. Con: reduces "surprise" factor of hazard kills. Test without, add if frustrating. |
| Should gap have narrow bridge points on some maps (future)? | level-designer | Before Alpha (multi-map) | Not in MVP map. Future maps could introduce bridges as a design variant. |
