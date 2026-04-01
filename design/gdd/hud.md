# HUD

> **Status**: Designed
> **Author**: user + game-designer + ux-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 4 (Fast and Mobile-First)

## Overview

The HUD (Heads-Up Display) is the in-match information overlay that shows the player
everything they need to know during gameplay: their health, the match timer, team
scores, kill feed, cooldown status, hero level, and minimap (future). It reads data
from multiple systems and renders it as a non-interactive screen overlay. The player
reads the HUD constantly but never directly interacts with it (controls are handled by
Input System, not HUD). Without it, the player is blind — no health bar, no score, no
timer, no feedback.

## Player Fantasy

**"I know exactly where I stand."** One glance tells the player everything: "I'm at
half health, my hook is on cooldown for 1 more second, we're winning 15-12, there's
90 seconds left." The HUD never obscures the action, never requires reading, and
never demands attention — it's always there in the periphery, and the information
sinks in without effort.

This serves Pillar 4 (Mobile-First): the HUD must be readable on a 5" screen held
at arm's length. Elements are large, high-contrast, and in thumb-friendly positions.
No tiny text, no dense information panels. Less is more.

## Detailed Design

### Core Rules

**HUD Layout (Landscape Mobile)**

```
┌────────────────────────────────────────────┐
│  [Hero]  [HP Bar]     [Timer]     [Kill    │
│  [Lvl]               [A: 15  B: 12] Feed]  │
│                                    [Kill 1] │
│                                    [Kill 2] │
│                                             │
│           (GAMEPLAY AREA)                   │
│                                             │
│                                             │
│  [Joystick]                    [Hook Btn]   │
│             [K/D/A]                         │
└────────────────────────────────────────────┘
```

1. **Top-left**: Hero portrait/icon, level indicator, XP bar
2. **Top-left (below portrait)**: Health bar (own health)
3. **Top-center**: Match timer (MM:SS), team scores (A: X  B: X)
4. **Top-right**: Kill feed (last 4 kills, slides in/out)
5. **Bottom-left**: Virtual joystick (owned by Input System, HUD renders)
6. **Bottom-right**: Hook button with cooldown indicator (owned by Input System)
7. **Bottom-center**: Personal K/D/A (small, optional)
8. **Center screen**: Reserved for transient messages (kill confirm, level up, countdown, match end)

**Design Constraints**

1. HUD must not obscure the center 60% of the screen (gameplay area)
2. All HUD elements in the corners/edges only
3. No element smaller than 44x44 points (Apple HIG minimum tap target, applies to readability too)
4. All text must be readable at arm's length on a 5" screen
5. High-contrast colors — light text on dark backgrounds, or outlined text
6. HUD fades to 50% opacity when no information is changing (reduces visual noise)
7. HUD is purely informational — no interactive elements (buttons are Input System)

**Health Bar**

1. Displays `current_health / max_health` as a bar with numeric value
2. Green when > 50%, yellow when 25-50%, red when < 25% (pulses at red)
3. Takes damage: bar shrinks with a brief trailing "damage ghost" (white bar showing recent health)
4. Heals: bar fills (only on respawn in MVP)
5. Invulnerability: bar has a shield overlay / glow

**Match Timer**

1. Displays remaining match time as MM:SS
2. Normal: white text
3. Final 30 seconds: red text, pulses
4. Overtime: replaces timer with "OVERTIME" text (red, pulsing)

**Team Scores**

1. Displayed as "A: [kills]  B: [kills]" or team colors with numbers
2. Updates instantly on each kill
3. The player's team is always displayed on the left
4. Brief pulse animation on score change

**Kill Feed**

1. Slides in from the right side
2. Format: `[Killer icon] → [Victim icon]` for kills, `[Victim icon] ☠` for suicides
3. Maximum 4 visible entries
4. Each entry fades out after 5 seconds
5. New entries push old ones up

**Cooldown Indicator**

1. Rendered on the hook button (owned by Input System)
2. Radial fill clockwise from 0% to 100% during cooldown
3. Button grayed out during cooldown and flight
4. Subtle "ready" flash when cooldown completes

**Level and XP**

1. Level displayed as "Lv.1/2/3" next to hero portrait
2. XP bar fills toward next level (thin bar below health or below portrait)
3. Level-up: brief golden flash + "LEVEL UP" center text

**Transient Center Messages**

1. Kill confirmation: hero icon + "HOOKED!" (1s, fades)
2. Kill streak: "STREAK x3!" (1.5s, fades)
3. Cross-gap kill: "CROSS GAP!" bonus text (1s, fades)
4. Level up: "LEVEL 2" / "LEVEL 3" with stat change preview (2s, fades)
5. Countdown: "3" "2" "1" "GO!" (1s each)
6. Match end: "VICTORY" / "DEFEAT" / "DRAW" (3s)
7. Overtime: "OVERTIME — NEXT KILL WINS" (2s, then persistent small text)
8. Center messages stack/queue — never overlap. Newest takes priority.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Hidden | Pre-match loading | Countdown begins | HUD not visible |
| Countdown | Match state = Countdown | Match state = Playing | Timer visible, countdown numbers center. Scores at 0-0. |
| Active | Match state = Playing | Match state = Overtime or Ended | Full HUD visible. All elements updating. |
| Overtime | Match state = Overtime | Match state = Ended | Timer replaced with "OVERTIME". Scores prominent. Tension styling. |
| Match End | Match state = Ended | Results screen opens | Victory/Defeat splash. HUD elements freeze. |
| Hidden | Results screen / lobby | Next match countdown | HUD hidden. Results UI takes over. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Health & Damage** | Health → HUD | Reads `current_health`, `max_health`, `is_invulnerable` for health bar. |
| **Input System** | Input → HUD | Reads `hook_button_state` and `cooldown_progress` for button rendering. Joystick and button are Input's visual elements positioned by HUD layout. |
| **Match State Manager** | Match State → HUD | Reads `match_time_remaining`, `current_state` for timer and state banners. |
| **Score/Kill Tracking** | Score → HUD | Reads `team_kills`, `kill_feed_entries`, `player_stats` for scores, kill feed, K/D/A. |
| **Hero System** | Hero → HUD | Reads `current_level`, `xp_progress`, `hero_id` for portrait, level, XP bar. |
| **Camera System** | Indirect | HUD is a screen-space overlay, not world-space. Camera position doesn't affect HUD. |

## Formulas

### Health Bar Width

```
health_bar_fill = current_health / max_health
damage_ghost_fill = lerp(damage_ghost_fill, health_bar_fill, ghost_decay_speed * delta)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| health_bar_fill | float | 0-1 | calculated | Current fill percentage |
| damage_ghost_fill | float | 0-1 | calculated | Trailing "ghost" bar (shows recent damage) |
| ghost_decay_speed | float | 2-5 | tuning knob | How fast the ghost catches up to real health |

### XP Bar Fill

```
xp_bar_fill = (current_xp - current_level_threshold) / (next_level_threshold - current_level_threshold)
```

At max level (3), XP bar is full and static.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Screen resolution is unusually wide (21:9) | HUD elements stay anchored to corners. Center gameplay area gets wider. HUD does not stretch. | HUD uses anchor-based positioning, not absolute coordinates. |
| Screen resolution is very small (4" phone) | HUD elements scale down proportionally but respect minimum size (44pt). If elements would overlap, lower-priority elements hide. | Readability on small screens is non-negotiable. |
| Kill feed receives 5+ kills in rapid succession | 5th kill pushes oldest entry out early. Max 4 visible at once. | Feed has a hard limit. Fast kills don't break the layout. |
| Multiple center messages trigger simultaneously (kill + level up) | Kill message displays first (higher priority). Level-up queues and displays after kill fades. | Center messages never overlap. Priority queue prevents clutter. |
| Player takes damage and heals (respawn) on the same frame | Health bar jumps to full. No ghost bar. Ghost resets on respawn. | Respawn is a clean reset. No lingering damage ghost. |
| HUD elements overlap with joystick/hook button | Must not happen. Input controls are in the bottom 20%. HUD info is in the top 20% and edges. Minimum 40% vertical gap. | Layout is fixed and tested. No overlap by design. |
| Match timer reaches 0 during gameplay | Timer displays "0:00" for one frame, then transitions to either Overtime text or match end splash. | Clean transition. No negative timer. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Health & Damage** | Upstream | Hard — health bar needs health data | Reads `current_health`, `max_health`, `is_invulnerable` |
| **Input System** | Upstream | Soft — HUD renders Input's visual elements | Reads button states and cooldown progress |
| **Match State Manager** | Upstream | Hard — timer and state needed | Reads `match_time_remaining`, `current_state` |
| **Score/Kill Tracking** | Upstream | Hard — scores and kill feed | Reads team kills, kill feed entries, player K/D/A |
| **Hero System** | Upstream | Soft — portrait and level display | Reads hero ID, level, XP progress |

**No downstream dependents.** HUD is a leaf system — it reads from everything,
nothing reads from it.

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `hud_opacity_active` | 1.0 | 0.7-1.0 | Fully visible, potentially distracting | More transparent, less screen clutter |
| `hud_opacity_idle` | 0.5 | 0.3-0.8 | More visible when idle | Fades more, cleaner look |
| `health_bar_width` | 200 px | 150-300 px | Larger, more readable | Smaller, less screen space |
| `kill_feed_duration` | 5.0 s | 3-8 s | Entries stay longer | Faster turnover, cleaner screen |
| `center_message_duration` | 1.5 s | 1-3 s | Messages stay longer | Faster, less obstructive |
| `ghost_decay_speed` | 3.0 | 1-5 | Ghost bar catches up faster | Ghost lingers longer (shows damage history) |
| `low_health_threshold` | 0.25 | 0.15-0.35 | Red warning triggers earlier | Red warning only at very low HP |
| `min_element_size` | 44 pt | 36-56 pt | Larger touch targets and text | Smaller elements, more screen space |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Health bar damage | Bar shrinks, ghost trails behind, flash red on hit | None (hit sound from Health system) | High |
| Health bar low | Bar pulses red, screen edge vignette | Heartbeat loop | High |
| Score change | Score number pulses, brief color flash | None (kill sound handles this) | Medium |
| Kill feed entry | Slides in from right, fades out after duration | None | Medium |
| Center message (kill) | "HOOKED!" scales in, fades out | Kill chime (from Score system) | High |
| Center message (level up) | "LEVEL UP" gold text, stat changes listed briefly | Level-up chime (from Hero system) | High |
| Center message (countdown) | Large numbers scale in, pulse | Countdown beeps (from Match State) | Critical |
| Cooldown complete | Hook button flashes bright, radial fill completes | Ready tick (from Input system) | High |

**Note**: HUD plays NO sounds of its own. All audio is owned by the source systems.
HUD is purely visual.

## UI Requirements

This section IS the HUD — it's a UI system by definition. Key specs:

| Element | Position | Size | Update Rate | Data Source |
|---------|----------|------|-------------|-------------|
| Hero portrait | Top-left, 8px margin | 48x48 pt | Static | Hero System |
| Level badge | Bottom-right of portrait | 20x20 pt | On level change | Hero System |
| Health bar | Below portrait, left-aligned | 200x16 pt | Every frame | Health & Damage |
| XP bar | Below health bar | 200x4 pt | On XP gain | Hero System |
| Match timer | Top-center | 60pt font | Every second | Match State Manager |
| Team scores | Flanking timer | 36pt font each | On kill | Score/Kill Tracking |
| Kill target | Below scores | 14pt font | Static | Match State Manager |
| Kill feed | Top-right, 8px margin | 180x32 pt per entry | On kill | Score/Kill Tracking |
| K/D/A | Bottom-center | 14pt font | On K/D/A change | Score/Kill Tracking |
| Center messages | Center screen | 72pt font | On event | Various |

**Rendering order** (back to front): Background tint → Health/XP bars → Text → Icons → Center messages

## Acceptance Criteria

- [ ] Health bar displays current/max health accurately with color coding
- [ ] Health bar ghost trail shows recent damage and decays smoothly
- [ ] Low health warning (pulse + vignette) triggers at 25% HP
- [ ] Invulnerability indicator visible on health bar
- [ ] Match timer counts down correctly in MM:SS format
- [ ] Timer turns red and pulses at 30s remaining
- [ ] Team scores update instantly on kills
- [ ] Kill feed displays correct killer/victim icons, respects max entries
- [ ] Kill feed entries fade out after configured duration
- [ ] Cooldown indicator fills radially on hook button
- [ ] Level and XP bar update on XP gain and level-up
- [ ] Center messages display in priority order, never overlap
- [ ] Countdown (3-2-1-GO) displays correctly during Countdown state
- [ ] Victory/Defeat/Draw splash displays during Ended state
- [ ] Overtime banner displays during Overtime state
- [ ] HUD fades to idle opacity when no updates occurring
- [ ] All elements readable on a 5" screen at arm's length
- [ ] No HUD element overlaps the center 60% gameplay area
- [ ] No HUD element overlaps the joystick or hook button zones
- [ ] HUD adapts to different aspect ratios via anchor positioning
- [ ] All sizes, durations, and thresholds loaded from config — no hardcoded values
- [ ] Performance: HUD rendering within 1ms per frame

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should enemy health bars be world-space (above their head) or HUD-space (on-screen indicator)? | ux-designer | Before prototype | World-space is more intuitive for isometric view. Test both. |
| Should there be a minimap? | ux-designer + game-designer | Before Vertical Slice | Not in MVP. Arena is small enough that the isometric view shows most of it. Add for larger maps. |
| Should the HUD support colorblind modes? | accessibility-specialist | Before Alpha | Yes, eventually. Use shape + position cues in addition to color. Defer implementation to Alpha. |
| Should players be able to customize HUD element positions? | ux-designer | Before Full Vision | Nice-to-have. Not in MVP or VS. Standard layout first. |
