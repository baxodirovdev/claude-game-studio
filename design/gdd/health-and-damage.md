# Health & Damage

> **Status**: Designed
> **Author**: user + game-designer + systems-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King), Pillar 3 (Every Match is a Fresh Start)

## Overview

The Health & Damage system tracks every hero's hit points, processes incoming damage
from all sources (hooks, hazards, abilities), determines when a hero dies, and
communicates health state to all systems that need it (HUD, Respawn, Score). The
player interacts with this system passively — they see their health bar shrink when
hit and know they need to play safer or more aggressively based on how much health
they have left. Without this system, hooks have no consequence, hazards have no
teeth, and there is no death or respawn — no game.

## Player Fantasy

**"One more hook and I'm dead."** Health creates tension. A full-health player peeks
boldly over cover, daring enemies to hook them. A low-health player hugs walls,
plays cautious, and prays their hook lands first. The damage numbers and health bar
tell a story every fight: "I can take one more spike hit but not a hook pull." Health
is the currency of risk — spending it by positioning aggressively, conserving it by
playing safe.

This serves Pillar 1 (Skillshot is King): damage comes almost exclusively from hooks
and hazards, both of which require positional skill. There's no passive damage, no
damage-over-time aura, no unavoidable chip. Every point of health lost is traceable
to a specific skillshot or positioning mistake. It also serves Pillar 3 (Fresh Start):
all heroes start every match at full health with the same base HP. No permanent
health upgrades — in-match items may modify HP, but it resets each match.

## Detailed Design

### Core Rules

**Health Pool**

1. Every hero has a `max_health` value defined in their Hero data file
2. `current_health` starts at `max_health` at match start and on each respawn
3. Health is a float (not integer) to support precise damage calculations
4. Health cannot exceed `max_health` (no overheal)
5. Health cannot go below 0 — clamped at 0 on lethal damage
6. There is no health regeneration by default. Health is only restored by:
   - Respawning (full heal)
   - In-match items (Vertical Slice — not in MVP)

**Damage Processing**

1. All damage flows through a single `take_damage(amount, source, damage_type)` function
2. Damage types:
   - `HOOK`: damage from a hook hit (the primary damage source)
   - `HAZARD_SPIKE`: damage from spike zones
   - `HAZARD_INSTANT_KILL`: damage from gap/pit (sets health to 0 regardless of amount)
   - `ABILITY`: damage from hero secondary abilities (future — not in MVP)
3. Damage is applied immediately — no damage delay, no damage queue
4. Minimum damage per hit: 1 HP. Damage cannot be reduced below 1 (except 0 from a miss)
5. Damage source is tracked for kill credit attribution

**Death**

1. When `current_health` reaches 0, the hero dies
2. On death, emit `hero_died(victim, killer, damage_type)` signal
3. The killer is determined by `source` from the last `take_damage` call
4. If `damage_type == HAZARD_INSTANT_KILL` and no hook was involved, death is a
   suicide (no killer credited). If the player was pulled into the hazard by a hook,
   the hooker gets kill credit.
5. After death, the hero enters Dead state (Player Controller handles this)
6. Respawn is handled by the Respawn System — Health & Damage only tracks the death event

**Kill Credit Attribution**

1. If a player dies to a hazard within 3 seconds of being pulled by a hook, the
   hooker gets kill credit (assist window)
2. If a player walks into a hazard on their own, it's a suicide
3. If a player is at low health from spike damage and then hooked, the hooker gets
   the kill (last hit)
4. There are no assists in MVP — only the final damage source gets the kill

**Damage Immunity**

1. Respawning heroes have brief invulnerability (duration owned by Respawn System)
2. During invulnerability, `take_damage` is rejected — returns 0 damage dealt
3. No other sources of damage immunity in MVP

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Full Health | Spawn / respawn | Takes any damage | `current_health == max_health`. Health bar hidden or full. |
| Damaged | Takes damage while alive | Health reaches 0 OR healed to full | `0 < current_health < max_health`. Health bar visible with current value. |
| Dead | `current_health` reaches 0 | Respawn System restores health | All damage rejected. `hero_died` signal emitted. Awaiting respawn. |
| Invulnerable | Respawn System grants immunity | Immunity timer expires | All damage rejected. Visual indicator (flashing/glow). Can move and act normally. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Controller** | Health → Player Controller | Emits `hero_died` signal. Player Controller transitions to Dead state. |
| **Hook Aiming & Physics** | Hook → Health | Hook System calls `take_damage(hook_damage, hooker, HOOK)` when a hook hits a hero. |
| **Map Hazards** | Hazards → Health | Spike zones call `take_damage(spike_damage, null, HAZARD_SPIKE)`. Gap/pits call `take_damage(999999, null, HAZARD_INSTANT_KILL)`. |
| **Hero System** | Hero → Health | Provides `max_health` per hero. May provide damage modifiers from items (Vertical Slice). |
| **Score/Kill Tracking** | Health → Score | Emits `hero_died(victim, killer, damage_type)`. Score System records the kill/death. |
| **Respawn System** | Respawn → Health | On respawn, calls `restore_health(max_health)` and `set_invulnerable(duration)`. |
| **HUD** | Health → HUD | HUD reads `current_health`, `max_health`, and `invulnerable` state to render health bar. |
| **Camera System** | Health → Camera | Emits `hero_died` signal. Camera transitions to death camera behavior. |
| **Networking Layer** | Health ↔ Network | Server-authoritative: damage is validated server-side. Health state replicated to all clients. |

## Formulas

### Hook Damage

```
hook_damage = hero_base_hook_damage * (1.0 + item_damage_modifier)
final_damage = max(1, hook_damage - target_damage_reduction)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| hero_base_hook_damage | float | 20-50 HP | Hero data file | Base damage per hero's hook type |
| item_damage_modifier | float | 0.0-1.0 | Item System (VS) | Sum of damage boost items. 0 in MVP. |
| target_damage_reduction | float | 0.0-20.0 | Item System (VS) | Sum of armor/reduction items. 0 in MVP. |
| final_damage | float | 1+ | calculated | Actual HP removed. Minimum 1. |

**MVP simplification**: With no items, `hook_damage = hero_base_hook_damage`. Clean
and simple. Item modifiers layer on in Vertical Slice without changing the formula.

### Hits to Kill

```
hits_to_kill = ceil(target_max_health / hook_damage)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| target_max_health | float | 80-150 HP | Hero data file | Target hero's max HP |
| hook_damage | float | 20-50 HP | calculated above | Attacker's hook damage |
| hits_to_kill | int | 2-6 | calculated | How many clean hooks to kill from full HP |

**Design target**: Most matchups should require 3-4 hooks to kill. 2-hit kills feel
unfair. 6+ hit kills make hooks feel weak. Tune `max_health` and `base_hook_damage`
to land in the 3-4 range.

### Spike Zone Damage

```
spike_damage = spike_base_damage * (1.0 + spike_scaling_per_minute * match_time_minutes)
```

Referenced from Arena/Map GDD. Spikes should deal ~25-30% of `max_health` per trigger.

### Kill Credit Window

```
is_hook_kill = (time_since_last_hook_pull <= kill_credit_window)
killer = is_hook_kill ? last_hooker : null  # null = suicide
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| kill_credit_window | float | 2-5 s | tuning knob | Seconds after a pull during which hazard kills credit the hooker |
| time_since_last_hook_pull | float | 0+ | tracked per player | Time since this player was last pulled by an enemy hook |
| last_hooker | Player | — | tracked per player | Who last pulled this player |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Two damage sources hit the same frame (hook + spike) | Both apply in order processed. If first kills, second is ignored (target already dead). Kill credit goes to first source. | Frame-order determinism. No double-kill-credit. |
| Player at 1 HP hit by spike (30 damage) | Player dies. Overkill damage is ignored — health clamps to 0. | No negative health. Clean death at 0. |
| Player falls into gap while invulnerable (post-respawn) | Instant kill overrides invulnerability. Player dies. | Gap/pit kills are absolute — invulnerability protects from hooks and spikes, not from falling into the void. Prevents spawn-camping exploits near gaps. |
| Hook hits an invulnerable player | Damage is rejected (0 dealt). Hook still connects visually but no pull occurs. | Invulnerability is full immunity. No "hit but no damage" confusion — the hook visually bounces off. |
| Player is hooked, pulled into spikes, survives, then walks into the gap 2.5s later | Hooker gets kill credit (within 3s kill credit window). | The hook put the player in danger — hooker deserves credit for the chain of events. |
| Player is hooked, pulled into spikes, survives, walks safely for 4s, then falls into a gap | Suicide. Kill credit window expired. | 3s is generous enough. After that, the death is the player's own fault. |
| `max_health` is modified by an item mid-combat | `max_health` increases. `current_health` stays the same (no free heal from buying health items). | Prevents "buy health item at low HP for instant heal" exploit. Health items increase the ceiling, not current value. |
| All heroes on a team die simultaneously | Each death is processed individually. All emit `hero_died` signals. Score tracks each kill separately. | No special "team wipe" logic needed. Each death is independent. |
| Damage source is a disconnected player | Damage source = null. If it's a hazard kill, it's a suicide. If it's a hook that was in flight when the hooker disconnected, the hook disappears (Hook System handles this) and no damage occurs. | Clean handling of disconnects. No ghost damage. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Player Controller** | Downstream | Hard — needs death signal to stop movement | Emits `hero_died` signal |
| **Hook Aiming & Physics** | Upstream | Hard — primary damage source | Calls `take_damage(amount, source, HOOK)` |
| **Map Hazards** | Upstream | Hard — environmental damage source | Calls `take_damage(amount, source, HAZARD_*)` |
| **Hero System** | Upstream | Hard — provides `max_health` | Reads per-hero `max_health` from Hero data |
| **Score/Kill Tracking** | Downstream | Hard — needs death events for scoring | Reads `hero_died(victim, killer, damage_type)` signal |
| **Respawn System** | Bidirectional | Hard — restores health on respawn | Calls `restore_health()` and `set_invulnerable()` |
| **HUD** | Downstream | Soft — HUD can exist without it but health bar needs data | HUD reads `current_health`, `max_health`, `is_invulnerable` |
| **Camera System** | Downstream | Soft — death cam is nice-to-have | Reads `hero_died` signal |

**Cross-reference with Arena/Map GDD**: Spike damage formula matches (`spike_base_damage *
scaling`). Gap/pit = instant kill. Confirmed consistent.

**Cross-reference with Player Controller GDD**: Player Controller transitions to Dead
state on `hero_died` signal. Confirmed consistent.

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `max_health` (per hero) | 100 HP | 80-150 HP | Tankier heroes, more hooks to kill, longer fights | Squishier heroes, fewer hooks to kill, faster kills |
| `base_hook_damage` (per hero) | 30 HP | 20-50 HP | Fewer hooks to kill, faster pace, more punishing | More hooks to kill, more forgiving, longer engagements |
| `kill_credit_window` | 3.0 s | 2-5 s | Hookers get credit for delayed hazard kills more often | Only immediate hazard kills credit the hooker |
| `invulnerability_duration` | 2.0 s | 1-4 s | Longer spawn protection, safer respawn | Shorter protection, riskier respawn, possible spawn camping |
| `minimum_damage` | 1 HP | 1 HP | Fixed — should not be changed | — |

**Knob interactions**:
- `max_health` / `base_hook_damage` ratio determines hits-to-kill. Target: 3-4 hits.
  Changing one without the other shifts the kill speed.
- `invulnerability_duration` and spawn point placement (Arena GDD) interact — short
  immunity is fine if spawns are far from combat, dangerous if spawns are close.
- `spike_base_damage` (Arena GDD) and `max_health` interact — spikes should deal
  25-30% of max HP. If max HP changes, spike damage may need retuning.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Take damage (hook) | Hero flashes red, brief knockback animation, floating damage number | Impact hit sound (meaty thud), hero pain grunt | High |
| Take damage (spikes) | Hero flashes orange, spark particles, floating damage number | Sharp metallic sting | High |
| Death (hook kill) | Death animation (ragdoll/knockback away from killer), fade out | Death cry + kill confirmation sound for the killer | High |
| Death (gap/pit) | Falling animation into void (per Arena GDD) | Falling scream | High |
| Death (suicide — walked into hazard) | Same as hazard death but no kill sound for anyone | Same falling/spike sound, no kill confirmation | Medium |
| Low health warning | Health bar pulses red when below 25% HP, vignette at screen edges | Heartbeat sound loop at low health | High |
| Invulnerability active | Hero model flashes/glows white, subtle shield particle effect | Faint hum/shimmer | Medium |
| Invulnerability expires | Flash fades, brief "shield down" particle pop | Shield-down chime | Medium |
| Health restored (respawn) | Health bar fills instantly on respawn | None (respawn has its own sound) | Low |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Own health bar | Top-left of screen (HUD) or above hero's head | Every frame when damaged | Always visible when `current_health < max_health` |
| Enemy health bars | Above enemy hero models (world-space) | Every frame | Visible when enemy is in camera viewport |
| Teammate health bars | Above teammate hero models (world-space) | Every frame | Visible when teammate is in camera viewport |
| Floating damage numbers | At hero position, drift upward and fade | On each damage event | Pop up on damage, fade after 1s |
| Kill feed | Top-right corner of screen | On each kill | Shows "[Killer hero icon] → [Victim hero icon]" for 5s |
| Low health warning | Screen edges (vignette) + health bar pulse | When below 25% HP | Persistent until healed or dead |
| Invulnerability indicator | Glow on hero model + small shield icon on health bar | While invulnerable | Active during post-respawn immunity |

## Acceptance Criteria

- [ ] Heroes spawn with full health (`current_health == max_health`)
- [ ] Hook damage reduces health by the correct amount (per hero data)
- [ ] Spike damage reduces health by the correct amount with scaling
- [ ] Gap and pit contact kills instantly regardless of health
- [ ] Health cannot go below 0 or above `max_health`
- [ ] Minimum damage per hit is 1 HP (never 0 from a valid hit)
- [ ] `hero_died` signal emits with correct victim, killer, and damage type
- [ ] Kill credit attributed to hooker when target dies to hazard within credit window
- [ ] Suicide correctly attributed when no enemy involvement
- [ ] Invulnerability blocks all damage except instant-kill hazards
- [ ] Invulnerability blocks hook pulls (hook bounces off)
- [ ] Health restored to full on respawn
- [ ] Floating damage numbers display correct values
- [ ] Health bars update in real-time for self, teammates, and enemies
- [ ] Low health warning triggers at 25% HP
- [ ] All health and damage values loaded from data files — no hardcoded values
- [ ] Performance: damage processing completes within 0.1ms per event
- [ ] Damage processing is deterministic (same inputs = same outputs regardless of frame order)

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should there be any health regeneration? (e.g., slow regen when out of combat for 5s) | game-designer | Before prototype | Start without regen. If matches feel too attrition-based (everyone limping at low HP), add slow out-of-combat regen. |
| Should hooks deal different damage based on distance? (Long-range hooks deal more = reward skillshots) | systems-designer | Before Hero System GDD | Interesting design space. Could make cross-gap hooks more rewarding. Defer to prototype testing. |
| Should there be a "last hit" vs "most damage" kill credit option? | game-designer | Before Score/Kill Tracking GDD | MVP uses last hit. May revisit if players complain about kill stealing. |
| Should damage numbers show as integers (rounded) even though health is a float internally? | ux-designer | Before HUD implementation | Probably yes — players don't need decimal precision. Show rounded integers. |
