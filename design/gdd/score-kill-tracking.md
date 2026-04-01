# Score/Kill Tracking

> **Status**: Designed
> **Author**: user + game-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King)

## Overview

The Score/Kill Tracking system records every kill, death, and assist during a match,
maintains per-player and per-team statistics, feeds kill counts to the Match State
Manager for win condition checks, and compiles post-match stats. The player sees this
system through the kill feed, score display, and post-match results screen. Without it,
kills have no meaning, there's no win condition, and there's no way to measure skill.

## Player Fantasy

**"I'm carrying this team."** The score board tells the story of the match. The player
who lands the most hooks, gets the most kills, and dies the least is visibly the MVP.
Stats validate skill — hook accuracy percentage, longest hook kill, kills-per-minute.
The kill feed creates real-time narrative: "Vex just got a triple kill."

This serves Pillar 1 (Skillshot is King): stats prove that skillshots matter.
Hook accuracy, kill streaks, and cross-gap kills are all trackable, visible measures
of mechanical skill.

## Detailed Design

### Core Rules

**Kill Recording**

1. Listen to `hero_died(victim, killer, damage_type)` from Health & Damage
2. For each death event, record:
   - Victim (player + hero)
   - Killer (player + hero, or null for suicide)
   - Damage type (HOOK, HAZARD_SPIKE, HAZARD_INSTANT_KILL)
   - Timestamp
   - Kill distance (distance between killer and victim at time of hook fire, if applicable)
3. Increment team kill count for the killer's team
4. Increment player kill count for the killer
5. Increment death count for the victim
6. Emit `kill_occurred(team_id, team_kills)` signal for Match State Manager

**Assist Tracking**

1. An assist is credited when a player dealt damage to the victim within 5 seconds
   of the killing blow, but did NOT get the kill
2. Only one assist per kill (the most recent damage dealer besides the killer)
3. Assists count toward the assisting player's stats but NOT toward team kill count

**XP Distribution**

1. On kill: emit `xp_gained(killer, xp_on_kill)` to Hero System
2. On assist: emit `xp_gained(assister, xp_on_assist)` to Hero System
3. On hook hit (non-lethal): emit `xp_gained(hooker, xp_on_hook_hit)` to Hero System
4. XP values defined in Hero System GDD

**Per-Match Statistics Tracked**

| Stat | Per-Player | Per-Team | Description |
|------|-----------|----------|-------------|
| Kills | Yes | Yes (sum) | Total kills |
| Deaths | Yes | No | Total deaths |
| Assists | Yes | No | Total assists |
| KDA | Yes | No | (Kills + Assists) / max(Deaths, 1) |
| Hook Hits | Yes | No | Hooks that connected with an enemy |
| Hook Fires | Yes | No | Total hooks fired |
| Hook Accuracy | Yes | No | Hook Hits / Hook Fires (percentage) |
| Damage Dealt | Yes | No | Total HP damage dealt |
| Longest Hook Kill | Yes | No | Furthest distance kill via hook |
| Cross-Gap Kills | Yes | No | Kills where hook crossed the central gap |
| Hazard Kills | Yes | No | Kills where victim died to a hazard after being hooked |
| Kill Streak | Yes | No | Maximum consecutive kills without dying |
| MVP | Yes | No | Boolean — highest kills on winning team |

**Kill Feed**

1. Each kill generates a kill feed entry: `[Killer hero icon] → [Victim hero icon]`
2. Suicides show: `[Victim hero icon] ☠` (no killer)
3. Kill feed entries display for 5 seconds, then fade
4. Maximum 4 entries visible at once (oldest removed first)

### States and Transitions

The Score/Kill Tracking system has no complex state machine — it's always active
during a match and always recording.

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Inactive | Pre-match / lobby | Match enters Playing state | No tracking. Counters at zero. |
| Recording | Match enters Playing/Overtime | Match enters Ended state | All events recorded. Kill feed active. Stats updating. |
| Frozen | Match enters Ended | Results screen dismissed | No new events recorded. Final stats locked. |
| Compiled | Results screen opens | Arena unloads | Stats compiled into post-match summary. MVP calculated. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Health & Damage** | Health → Score | Listens to `hero_died(victim, killer, damage_type)` and `damage_dealt(target, amount, source)` signals. |
| **Match State Manager** | Score → Match State | Emits `kill_occurred(team_id, team_kills)`. Match State reads team kill counts for win condition. |
| **Hero System** | Score → Hero | Emits `xp_gained(player, amount)` for kills, assists, and hook hits. |
| **Hook Aiming & Physics** | Hook → Score | Listens to `hook_hit(hooker, target, distance)` and `hook_fired(player)` for accuracy tracking. |
| **HUD** | Score → HUD | Exposes kill feed entries, team scores, and per-player stats for display. |
| **Match Results UI** | Score → Results | Provides compiled match stats for the results screen. |

## Formulas

### KDA Ratio

```
kda = (kills + assists) / max(deaths, 1)
```

### Hook Accuracy

```
hook_accuracy = (hook_hits / max(hook_fires, 1)) * 100
```

### MVP Determination

```
mvp_score = kills * 3 + assists * 1 + cross_gap_kills * 2 - deaths * 1
mvp = player with highest mvp_score on winning team
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| kills | int | 0+ | tracked | Player's kill count |
| assists | int | 0+ | tracked | Player's assist count |
| cross_gap_kills | int | 0+ | tracked | Kills where hook crossed the gap |
| deaths | int | 0+ | tracked | Player's death count |

**If draw**: MVP is the player with the highest `mvp_score` across all players.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player kills themselves (suicide) | Death count incremented. No kill credited to anyone. Team kill count unchanged. | Suicides don't count as team kills. |
| Player gets a kill during Overtime | Kill is recorded. `kill_occurred` signal triggers match end (sudden death). | Overtime kills are normal kills — they just also end the match. |
| Player disconnects with the highest kill count | Stats preserved for the disconnected player. They can still be MVP if their team wins. | Stats belong to the match, not the connection. |
| Hook hits a target but deals 0 damage (invulnerable) | Hook hit NOT counted (bounced off). Hook fire IS counted. Accuracy is not penalized differently — it's still a fire without a hit. | Bouncing off invulnerability is a miss in terms of gameplay effect. |
| Two players on the same team hook the same enemy (one hits, one was in flight) | First hook hits and gets the kill. Second hook passes through (target dead/pulled). Only the first hooker gets credit. | Per Hook GDD: first hit wins. Clean attribution. |
| Kill streak spans across death and respawn | Kill streak resets on death. New streak starts from 0 after respawn. | Streak = consecutive kills without dying. Death breaks it. |
| Player gets exactly 0 kills, 0 deaths, 0 assists | Valid stat line. Player participated but had no impact. KDA = 0. | AFK or very cautious player. Stats reflect reality. |
| Last kill of the match triggers at the same frame as timer expiry | Kill takes priority over timer. Kill is recorded. Win condition checked normally. | Kill processing happens before timer check in frame order. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Health & Damage** | Upstream | Hard — primary data source for kills/deaths | Listens to `hero_died`, `damage_dealt` signals |
| **Match State Manager** | Downstream | Hard — win condition depends on team kills | Emits `kill_occurred(team_id, team_kills)` |
| **Hero System** | Downstream | Soft — provides XP for leveling | Emits `xp_gained` signals |
| **Hook Aiming & Physics** | Upstream | Soft — provides hook fire/hit data for accuracy | Listens to `hook_fired`, `hook_hit` signals |
| **HUD** | Downstream | Soft — provides kill feed and score data | Exposes current stats for display |
| **Match Results UI** | Downstream | Soft — provides compiled post-match stats | Provides full stat compilation on match end |

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `assist_window` | 5.0 s | 3-10 s | More generous assist credit | Stricter — only recent damage counts |
| `kill_feed_duration` | 5.0 s | 3-8 s | Kill feed entries stay longer | Faster turnover |
| `kill_feed_max_entries` | 4 | 3-6 | More history visible | Cleaner screen, less clutter |
| `mvp_kill_weight` | 3 | 1-5 | Kills matter more for MVP | Kills matter less |
| `mvp_assist_weight` | 1 | 1-3 | Assists matter more for MVP | Assists less relevant |
| `mvp_death_penalty` | 1 | 0-3 | Deaths penalize MVP score more | Deaths don't matter for MVP |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Kill (for killer) | Kill confirmation icon center-screen, "+50 XP" float | Kill confirmation chime (satisfying ding) | High |
| Kill (kill feed) | Kill feed entry slides in from right | None (kill feed is silent) | High |
| Assist (for assister) | "+25 XP" float, small assist tag | Subtle assist chime (quieter than kill) | Medium |
| Kill streak (3+) | "STREAK x3" banner above hero | Escalating streak sound | Medium |
| Cross-gap kill | Special kill feed icon (gap symbol), "+CROSS GAP" bonus text | Enhanced kill sound (more dramatic) | High |
| MVP announcement (results) | Spotlight on MVP hero, stats card highlight, crown icon | MVP fanfare | High |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Team scores | Top-center HUD, flanking timer | On each kill | During gameplay |
| Kill feed | Top-right corner | On each kill/death | During gameplay, max 4 entries |
| Kill target progress | Below team scores ("First to 20") | Static | During gameplay |
| Personal stats (K/D/A) | Small text bottom-center or Tab overlay | On each kill/death/assist | During gameplay |
| Post-match stat cards | Full results screen | On match end | Results state |
| MVP highlight | Center of results screen | On results compile | Results state |
| Hook accuracy | Results screen stat card | On results compile | Results state |
| Longest hook kill | Results screen stat card | On results compile | Results state |

## Acceptance Criteria

- [ ] Kills correctly attributed to killer with correct damage type
- [ ] Suicides recorded with no killer credited
- [ ] Team kill counts increment correctly and trigger `kill_occurred` signal
- [ ] Assists credited within the assist window (5s)
- [ ] XP signals emitted for kills, assists, and hook hits
- [ ] Hook accuracy tracked correctly (fires vs. hits)
- [ ] Kill feed displays correct killer/victim with hero icons
- [ ] Kill feed respects max entry limit and fade timing
- [ ] Stats frozen when match enters Ended state
- [ ] MVP correctly calculated using weighted formula
- [ ] Cross-gap kills identified and tracked
- [ ] Kill streaks tracked and reset on death
- [ ] Post-match stats compilation includes all tracked metrics
- [ ] All weight/timing values loaded from config — no hardcoded values

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should there be a "first blood" bonus (extra XP/announcement for first kill of the match)? | game-designer | Before prototype | Fun moment. Low effort. Probably yes — add it. |
| Should post-match stats include a "highlight play" replay? | game-designer | Before Full Vision | Replay system is complex. Defer to Full Vision. |
| Should assists count toward team kill total? | game-designer | Before prototype | No — team kills = actual kills only. Assists are personal stats. |
