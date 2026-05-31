# Hero System

> **Status**: Designed
> **Author**: user + game-designer + systems-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King), Pillar 2 (Play Your Way With Friends)

## Overview

The Hero System defines the roster of playable characters, each with a unique hook
type and stat profile. It manages hero selection, provides per-hero data (health,
speed, hook stats) to all gameplay systems, and handles in-match leveling (simplified
for MVP: 3 levels per match that upgrade the hook). The player engages with this
system during hero selection and passively through their hero's unique feel during
gameplay. Without it, every player is identical — no variety, no expression, no reason
to master different playstyles.

## Player Fantasy

**"This hero is MY hero."** Each hero's hook feels fundamentally different. The Chain
Puller drags enemies in a straight line. The Grapple Swinger flings a tether that
arcs. The Boomerang Blader throws a returning disc that hits on the way out AND back.
Players find "their" hero — the one whose hook matches their brain — and master it.
The variety means every lobby composition plays differently.

This serves Pillar 1 (Skillshot is King): different hook types create different skill
expression. Mastering one hero doesn't mean you've mastered them all. It serves
Pillar 2 (Play Your Way): hero choice is the primary expression of playstyle.

## Detailed Design

### Core Rules

**Hero Roster (MVP: 4 Heroes)**

1. **Vex — The Chain Puller** (Baseline/beginner)
   - Hook type: Classic straight-line chain pull
   - Fantasy: The Pudge. Point, shoot, drag them to you.
   - Stats: Balanced — medium speed, medium health, medium damage, medium range
   - Skill floor: Low. Skill ceiling: Medium.

2. **Lash — The Grapple Swinger** (Mobility/aggressive)
   - Hook type: Tether that pulls the HOOKER to the TARGET (reverse pull)
   - Fantasy: Spider-Man meets Scorpion. You fling yourself across the gap to the enemy.
   - Stats: Fast, low health, low damage, long range
   - Skill floor: Medium. Skill ceiling: High.
   - Special: Lash is pulled TO the target, not the other way around. This inverts
     the risk — you're launching yourself into enemy territory.

3. **Maw — The Boomerang Blader** (Area denial/zoner)
   - Hook type: Throws a spinning blade that travels to max range and returns.
     Hits enemies on the way OUT and on the way BACK.
   - Fantasy: The trapper. Control space. Make them afraid to move.
   - Stats: Slow, high health, high damage, short range
   - Skill floor: Medium. Skill ceiling: High.
   - Special: The blade hits on return travel too. If it misses going out, it might
     hit coming back. No pull — pure damage on both passes.

4. **Pudge — The Butcher** (Tank/disruptor)
   - Hook type: PULL (same family as Vex's chain pull, different stat profile)
   - Fantasy: Grotesque jovial butcher. Slow, tanky, low skillshot speed but
     enormous reward on connect. Where Vex is the "balanced beginner pull",
     Pudge is the "high-HP punisher pull" — you survive bad positioning long
     enough to land one game-changing hook.
   - Stats (target profile, NEEDS GAME-DESIGNER BALANCE PASS):
     Slow speed, very high health (~150 HP target), high damage on connect,
     long cooldown (~3 s), slightly larger hitbox. Distinct from Vex by
     trading mobility/agility for survivability.
   - Skill floor: Low. Skill ceiling: Medium.
   - Special: Hook prop is a separate detachable mesh per Stage 10 spec
     (`design/gdd/models/pudge.md`) — visually distinct from Vex's
     procedural chain. Asset pipeline tracked at `design/gdd/contracts/pudge-interface-contract.md`.

> **⚠ STAT BALANCE GAP** (contract O-9 — `design/gdd/contracts/pudge-interface-contract.md` §11):
> `src/data/heroes/pudge.tres` currently contains debug placeholder values
> (`hook_damage = 99999`, `xp_on_hook_hit = 0`, leveling bonuses zeroed).
> Real Pudge stats need to come from the same hits-to-kill matrix analysis
> applied to Vex/Lash/Maw below (target: 3-5 hooks to kill Pudge with most
> heroes, given tank role). Game-designer task before Stage 10 ships.

**Hero Data Structure**

Each hero is defined by a data file containing:

```
hero_id: string
display_name: string
max_health: float
move_speed: float
hook_speed: float
hook_range: float
hook_damage: float
hook_cooldown: float
hook_type: enum (PULL, GRAPPLE, BOOMERANG, CHARGE, BEAM)
hook_hitbox_size: float
pull_duration: float       # only for PULL type
grapple_duration: float    # only for GRAPPLE type
boomerang_return_damage: float  # only for BOOMERANG type
level_upgrades: array[3]   # stat bonuses per level
```

**Hero Selection**

1. Hero selection occurs in the lobby before match starts
2. No duplicate hero restriction — multiple players can pick the same hero
3. Hero selection is visible to all players in the lobby
4. A random hero is assigned if the player doesn't pick before the timer

**In-Match Leveling (MVP — Simplified)**

1. Heroes start each match at Level 1
2. Earn XP from: landing hooks (hit, not kill), getting kills, and assists
3. Level up at XP thresholds: Level 2 at 100 XP, Level 3 at 300 XP
4. Each level grants a pre-defined stat bonus from the hero's `level_upgrades` array:
   - Level 2: +10% hook damage, +5% move speed
   - Level 3: +15% hook damage, +10% move speed, +10% hook range
5. Level-up is immediate — no menu, no choice. Stats apply instantly.
6. Levels reset at match end (Pillar 3: Fresh Start)

**Hook Type Behaviors**

Each hook type modifies how the Hook Aiming & Physics system operates:

| Hook Type | Projectile | On Hit | Special |
|-----------|-----------|--------|---------|
| PULL (Vex) | Straight line, constant speed | Target is pulled TO hooker. Standard pull mechanic per Hook GDD. | None — this is the baseline. |
| GRAPPLE (Lash) | Straight line, faster speed | Hooker is pulled TO target. Hooker leaves their safe side. | Reversed pull direction. Hooker is the one moving. High risk, high reward. |
| BOOMERANG (Maw) | Travels to max range, then returns to hero | Damage on hit (outward). Damage on return pass too. No pull on either hit. | Two hit chances per throw. No pull — pure damage. Blade has wider hitbox on return. |

### States and Transitions

**Per-Hero Match State**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Selected | Player picks hero in lobby | Match loading begins | Hero data loaded, visual model assigned |
| Level 1 | Match starts | XP reaches Level 2 threshold | Base stats active. No upgrades. |
| Level 2 | XP threshold reached | XP reaches Level 3 threshold | Level 2 upgrades applied. Brief level-up VFX. |
| Level 3 (Max) | XP threshold reached | Match ends | Level 3 upgrades applied. Max level — excess XP ignored. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Controller** | Hero → Player Controller | Provides `move_speed` (base + level bonuses). Player Controller reads this each frame. |
| **Hook Aiming & Physics** | Hero → Hook | Provides all hook stats: `hook_speed`, `hook_range`, `hook_damage`, `hook_cooldown`, `hook_hitbox_size`, `hook_type`. Hook system reads type to determine pull/grapple/boomerang behavior. |
| **Health & Damage** | Hero → Health | Provides `max_health` (base + level bonuses). Health system reads this on spawn and level-up. |
| **Score/Kill Tracking** | Score → Hero | Score system sends XP events (hook hit, kill, assist). Hero System processes XP and checks level thresholds. |
| **HUD** | Hero → HUD | HUD reads hero stats, current level, XP progress for display. |
| **Lobby System** | Lobby → Hero | Lobby provides selected hero ID. Hero System loads the corresponding data file. |
| **In-Match RPG Progression** | Hero → RPG (VS) | In Vertical Slice, RPG system replaces simplified leveling with full item shop. Hero System provides base stats; items modify them. |

## Formulas

### XP Gain

```
xp_on_hook_hit = 15
xp_on_kill = 50
xp_on_assist = 25  # assist = dealt damage to target within 5s of kill
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| xp_on_hook_hit | int | fixed | hero config | XP for landing a hook (hit, not kill) |
| xp_on_kill | int | fixed | hero config | XP for getting the killing blow |
| xp_on_assist | int | fixed | hero config | XP for damaging a target someone else killed |

### Level Thresholds

```
level_2_threshold = 100 XP  # ~3-4 hook hits + 1 kill
level_3_threshold = 300 XP  # ~6-8 hook hits + 3-4 kills
```

**Design intent**: Most players should reach Level 2 by mid-match (~2-3 min) and
Level 3 by late-match (~4 min). A player who lands zero hooks stays Level 1 all
match — rewarding skill with power growth.

### Stat Scaling Per Level

```
effective_stat = base_stat * (1.0 + sum(level_bonus_percentages))
```

| Hero | Stat | Base | Level 2 Bonus | Level 3 Bonus | Max Effective |
|------|------|------|--------------|--------------|--------------|
| Vex | max_health | 100 | +0% | +0% | 100 |
| Vex | move_speed | 10 | +5% | +10% | 11.5 |
| Vex | hook_damage | 30 | +10% | +25% | 37.5 |
| Vex | hook_range | 20 | +0% | +10% | 22 |
| Lash | max_health | 80 | +0% | +0% | 80 |
| Lash | move_speed | 13 | +5% | +10% | 14.95 |
| Lash | hook_damage | 20 | +10% | +25% | 25 |
| Lash | hook_range | 25 | +0% | +10% | 27.5 |
| Maw | max_health | 130 | +0% | +0% | 130 |
| Maw | move_speed | 7 | +5% | +10% | 8.05 |
| Maw | hook_damage | 40 | +10% | +25% | 50 |
| Maw | hook_range | 15 | +0% | +10% | 16.5 |

### Hits-to-Kill Matrix (Level 1 vs Level 1)

| Attacker → Target ↓ | Vex (30 dmg) | Lash (20 dmg) | Maw (40 dmg, x2 passes) |
|---------------------|-------------|---------------|------------------------|
| Vex (100 HP) | 4 hooks | 5 hooks | 2 throws (if both passes hit) or 3 |
| Lash (80 HP) | 3 hooks | 4 hooks | 1 throw (both passes) or 2 |
| Maw (130 HP) | 5 hooks | 7 hooks | 2 throws (both passes) or 4 |

**Design intent**: Vex is the baseline (3-4 hooks to kill most targets). Lash is
fragile but mobile. Maw hits hard but is slow and short-ranged — rewards precision.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Lash (GRAPPLE) hooks an enemy standing on a pit | Lash is pulled TO the enemy (near the pit). Lash does not fall in unless their arrival position is inside the pit. | Grapple pull destination is the target's position, not past them. Lash arrives at the target, not into the hazard behind them. |
| Lash grapples across the gap | Lash flies across the gap to the enemy side. Lash is now on enemy territory — high risk. | This is Lash's core fantasy. Flying into danger. |
| Lash grapples an enemy, but the enemy dies from the hook damage before pull | No pull occurs (target is dead). Lash stays where they are. | Per Hook GDD: if target dies from damage, no pull. For Lash, this means a lethal hit keeps them safe. |
| Maw's boomerang hits on the way out AND the way back to the same target | Both hits deal damage. Target takes `hook_damage + boomerang_return_damage`. | Intentional — double-hit is Maw's signature. Standing still against Maw is punished. |
| Maw's boomerang hits different targets on out vs. return | Both targets take damage independently. No pull on either. | Boomerang can hit multiple targets — one per pass direction. |
| Player doesn't pick a hero before timer | Random hero assigned from the full roster. | Must start the match. Random prevents indefinite stalling. |
| Multiple players pick the same hero | Allowed. No restriction. | Pillar 2: play your way. Mirror matches are valid. |
| Level-up occurs mid-hook-flight | New stats apply to the current hook (damage is calculated at hit time, not fire time). | Stats are always read live. Level-up damage boost applies to hooks already in flight. |
| Player is Level 3 and earns more XP | XP is ignored. No overflow. No benefit. | Max level is max level. Clean cap. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Player Controller** | Downstream | Hard — reads `move_speed` | Player Controller reads `get_effective_stat("move_speed")` |
| **Hook Aiming & Physics** | Downstream | Hard — reads all hook stats + hook type | Hook system reads `get_hook_config()` returning full hook data struct |
| **Health & Damage** | Downstream | Hard — reads `max_health` | Health system reads `get_effective_stat("max_health")` on spawn/level-up |
| **Score/Kill Tracking** | Upstream | Soft — provides XP events | Listens to `xp_gained(amount, source)` signals |
| **HUD** | Downstream | Soft — reads hero display data | HUD reads hero name, icon, level, XP bar, stats |
| **Lobby System** | Upstream | Hard — provides selected hero ID | Receives `hero_selected(hero_id)` |

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `max_health` (per hero) | 80-130 | 60-200 | Tankier, longer fights | Squishier, faster kills |
| `move_speed` (per hero) | 7-13 | 5-15 | Faster, more evasive, harder to hit | Slower, easier target |
| `hook_speed` (per hero) | 25-35 | 20-40 | Less dodge time for targets | More dodge time |
| `hook_range` (per hero) | 15-25 | 10-30 | Safer positioning, longer reach | Must get closer to engage |
| `hook_damage` (per hero) | 20-40 | 15-50 | Fewer hooks to kill | More hooks to kill |
| `hook_cooldown` (per hero) | 1.5-3.0 s | 1.0-4.0 s | Less hook spam, each hook matters | More frequent hooks |
| `xp_on_hook_hit` | 15 | 5-30 | Faster leveling from combat | Slower leveling, kills matter more |
| `xp_on_kill` | 50 | 20-100 | Faster leveling from kills | Slower leveling |
| `level_2_threshold` | 100 | 50-200 | Slower level-up timing | Faster power spike |
| `level_3_threshold` | 300 | 150-500 | Slower max level | Faster max level |
| `boomerang_return_damage` (Maw) | 30 | 15-40 | Higher reward for double-hit | Weaker return pass |

**Knob interactions**:
- Hero stats are the master tuning layer — every gameplay system reads from hero data.
  Changing hero stats has cascading effects on hits-to-kill, movement feel, hook feel.
- `hook_damage` and `max_health` must be tuned as a pair (hits-to-kill target: 3-4)
- `move_speed` and `hook_speed` must be tuned as a pair (dodgeability)
- XP thresholds and match duration (Match State GDD: 300s) determine the leveling curve

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Hero selected in lobby | Hero model spotlight, idle animation, name card | Hero-specific selection voice line or sound | Medium |
| Level up (2 or 3) | Golden flash on hero, brief "LEVEL UP" text above head, stat change indicators | Level-up chime (triumphant, brief) | High |
| Vex hook (chain) | Metal chain with hook tip, industrial/dark aesthetic | Heavy metallic chain sounds | Critical |
| Lash hook (grapple) | Energy tether, glowing line, sleek/fast aesthetic | Electric zap + whoosh | Critical |
| Maw hook (boomerang) | Spinning blade disc, sawblade visual, brutal aesthetic | Spinning saw buzz + wind cutting | Critical |
| Boomerang return hit | Second impact flash, different color from outward hit | Second distinct impact sound (reversed pitch) | High |
| Grapple self-pull | Lash slides/flies toward target, wind trail | Rushing wind + zipline sound | Critical |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Hero portrait + name | Top-left HUD corner | Static per match | Always during gameplay |
| Current level | Next to hero portrait (Level 1/2/3) | On level change | Always during gameplay |
| XP progress bar | Below hero portrait, small bar | On XP gain | During gameplay, fills toward next level |
| Level-up notification | Center screen, brief | On level-up | 2s display, fades |
| Hero selection grid | Center of lobby screen | On lobby enter | During lobby/hero select |
| Hero stat preview | Side panel in hero select | On hero hover/tap | During hero selection |

## Acceptance Criteria

- [ ] Three heroes playable: Vex (pull), Lash (grapple), Maw (boomerang)
- [ ] Each hero has distinct stats loaded from data files
- [ ] Vex hook: standard pull mechanic (target pulled to hooker)
- [ ] Lash hook: reverse pull (hooker pulled to target)
- [ ] Maw hook: boomerang travels out and returns, hitting on both passes, no pull
- [ ] Hero selection works in lobby with no duplicate restriction
- [ ] Random hero assigned if player doesn't pick
- [ ] XP gained from hook hits, kills, and assists
- [ ] Level-up triggers at correct XP thresholds
- [ ] Level-up bonuses apply immediately to all stats
- [ ] Stats reset at match end (Pillar 3: Fresh Start)
- [ ] Hits-to-kill is 3-4 for most matchups at Level 1
- [ ] Each hero visually and audibly distinct (hook type, model, sounds)
- [ ] All hero stats and XP values loaded from config — no hardcoded values
- [ ] Performance: hero stat lookups are O(1) (cached, not computed per frame)

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should Lash take damage on grapple arrival (self-damage for aggression)? | game-designer | Before prototype | Start without. Lash is already risky (flying into enemy territory). If too strong, add self-damage. |
| Should Maw's boomerang have a wider hitbox on return (reward prediction)? | systems-designer | Before prototype | Start with same hitbox both ways. Test wider return in prototype. |
| Should level-up choices exist (pick between 2 upgrades) or be fixed? | game-designer | Before Vertical Slice | Fixed for MVP (simpler). Choices add depth but slow down mobile gameplay. Revisit for item shop integration in VS. |
| What are the hero unlock mechanics for the full roster? | game-designer + economy-designer | Before Alpha | MVP: all 3 heroes free. Full vision: unlock via gameplay currency (no pay-to-win per Pillar 3). |
| Should heroes have a secondary ability? Concept doc mentions it. | game-designer | Before Vertical Slice | Not in MVP. Focus on hook identity first. Add secondaries in VS if hook-only feels limiting. |
| Pudge stat balance pass — `pudge.tres` currently has debug values | game-designer | Before Stage 10 ships | Apply same hits-to-kill matrix logic used for Vex/Lash/Maw above. Aim for tank role: 3-5 hooks to kill Pudge with most heroes; Pudge needs 4-5 hooks to kill Vex (higher than Vex baseline because slower windup). |
| Coil and Flux hero data files exist (`src/data/heroes/coil.tres`, `flux.tres` with `hook_type = CHARGE` and `BEAM` respectively) but neither is documented in this GDD roster | game-designer | Before Polish phase | Either author full hero entries for both — including stats, fantasy, hook behavior table rows, hits-to-kill matrix entries — OR remove the data files if they're prototype-only experiments. The HookType enum in `src/data/config/hero_config.gd` lists PULL/GRAPPLE/BOOMERANG/CHARGE/BEAM, so the type slots are reserved either way. |
