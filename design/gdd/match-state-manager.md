# Match State Manager

> **Status**: Designed
> **Author**: user + game-designer + systems-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 4 (Fast and Mobile-First), Pillar 2 (Play Your Way With Friends)

## Overview

The Match State Manager is the central authority that controls match flow: from lobby
to loading, countdown to gameplay, overtime to results. It tracks the win condition
(first to X kills), manages the match timer, signals all other systems when the match
state changes, and determines the winner. The player doesn't interact with this
system directly — they experience it as "the match started," "30 seconds left," and
"you win." Without it, there's no structure to the game — no start, no end, no winner.

## Player Fantasy

**"Just one more match."** The Match State Manager creates the rhythm of play. Matches
are fast (5-8 minutes), with a clear build-up (countdown), climax (final kills or
overtime), and resolution (results screen). The pacing should make every match feel
complete — not cut short, not dragged out. When a match ends, the player should
immediately want to play again.

This serves Pillar 4 (Fast and Mobile-First): matches must fit in a commute or break.
The timer and kill target ensure matches end within the target window. It also serves
Pillar 2 (Play Your Way With Friends): the flexible lobby feeds into the Match State
Manager — any team configuration starts a valid match.

## Detailed Design

### Core Rules

**Match Flow**

1. The match follows a strict linear flow: Lobby → Loading → Countdown → Playing → Overtime (conditional) → Ended → Results → Return to Lobby
2. Each state has a fixed or conditional duration
3. The Match State Manager emits `match_state_changed(new_state)` on every transition
4. All systems listen to this signal and adjust behavior accordingly

**Win Conditions**

1. **Primary: Kill Target** — first team to reach X kills wins (default: 20 kills)
2. **Secondary: Timer** — if no team reaches the kill target, the team with more kills
   when the timer expires wins
3. **Tiebreaker**: If kills are tied when the timer expires, enter Overtime
4. Kill target and match duration are configurable per lobby

**Overtime**

1. Triggered when match timer expires and kills are tied
2. Overtime has no timer — next kill wins (sudden death)
3. Maximum overtime duration: 60 seconds. If no kill occurs, match ends in a draw
4. Draw is a valid outcome — both teams get partial rewards

**Match Timer**

1. Timer starts when match enters Playing state (after countdown)
2. Timer counts down from `match_duration` (default: 5 minutes)
3. Timer is displayed on HUD
4. At 30 seconds remaining, a "final countdown" warning triggers (audio + visual)
5. Timer pauses for nothing — no pause in multiplayer matches

**Score Tracking Interface**

1. Match State Manager reads kill counts from Score/Kill Tracking system
2. After each kill, Match State Manager checks: has either team reached the kill target?
3. If yes, match immediately transitions to Ended (no delay between final kill and match end)

**Team Configuration**

1. Match State Manager receives team rosters from the Lobby System
2. Valid configurations: any split of players into 2 teams (1v1 up to 5v5, including asymmetric: 1v5, 2v3, etc.)
3. Minimum players to start: 2 (one per team)
4. If a team has 0 living players (all disconnected), the other team wins by forfeit

### States and Transitions

| State | Duration | Entry Condition | Exit Condition | Behavior |
|-------|----------|----------------|----------------|----------|
| Lobby | Unlimited | Players in lobby | Host starts match | Players select heroes, pick teams. Match State Manager is idle. |
| Loading | 3-10s | Host starts match | All clients report ready + arena loaded | Arena scene loads. Loading screen shown. Match State Manager sends `load_map`. |
| Countdown | 3s (fixed) | All clients ready | Timer reaches 0 | Players see the arena but cannot move (Input disabled). "3... 2... 1... GO!" |
| Playing | `match_duration` (default 300s) | Countdown ends | Kill target reached OR timer expires with non-tied score OR timer expires with tied score (→ Overtime) | Full gameplay. All systems active. Timer counting down. Score updating. |
| Overtime | Max 60s | Timer expired with tied score | Any kill occurs OR 60s elapsed | Sudden death. "OVERTIME" banner. Next kill wins. If 60s pass, draw. |
| Ended | 3s (fixed) | Win condition met OR draw | Timer elapses | All gameplay frozen. Winner announcement. Input disabled. "VICTORY" / "DEFEAT" / "DRAW" splash. |
| Results | 10-15s | Ended timer elapses | Player dismisses OR timer elapses | Post-match stats screen. MVP player highlight. Score breakdown. |
| Returning | 2s | Results dismissed | Lobby scene loaded | Transition back to lobby. Clean up match data. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Arena/Map System** | Match State → Arena | Sends `load_map(map_id)` during Loading. Sends `match_started` and `match_ended` signals. Arena transitions its own states in response. |
| **Input System** | Match State → Input | Sends `match_state_changed`. Input disables during Countdown, Ended, Results. Enables during Playing and Overtime. |
| **Player Controller** | Match State → Player Controller (indirect via Input) | Player Controller reads Input, which obeys match state. No direct connection needed. |
| **Health & Damage** | Match State → Health | During Ended/Results, damage processing stops (Arena GDD: hazards stop dealing damage in Frozen state). |
| **Score/Kill Tracking** | Score → Match State | Match State reads `get_team_kills(team_id)` after each kill event to check win condition. Score System emits `kill_occurred` signal. |
| **Camera System** | Match State → Camera | Sends `match_started` (Camera → Active), `match_ended` (Camera → Frozen). |
| **Respawn System** | Match State → Respawn | During Overtime, respawn timer may be shortened (tunable). During Ended, no respawns. |
| **HUD** | Match State → HUD | HUD reads `match_time_remaining`, `team_kills`, `kill_target`, and current state to render timer, score, and state banners. |
| **Lobby System** | Lobby → Match State | Provides team rosters, selected map, and match settings (kill target, duration). |
| **Networking Layer** | Match State ↔ Network | Match state is server-authoritative. Server runs the timer and win condition checks. State transitions replicated to all clients. |

## Formulas

### Match Duration

```
match_time_remaining = match_duration - elapsed_time
is_expired = match_time_remaining <= 0
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| match_duration | float | 180-480 s | lobby settings | Total match time (default 300s = 5 min) |
| elapsed_time | float | 0 to match_duration | tracked by timer | Time since Playing state began |
| match_time_remaining | float | 0+ | calculated | Displayed on HUD |

### Win Condition Check

```
team_a_wins = team_a_kills >= kill_target
team_b_wins = team_b_kills >= kill_target
timer_expired = match_time_remaining <= 0

if team_a_wins or team_b_wins:
    winner = team with more kills (or first to reach target)
elif timer_expired and team_a_kills != team_b_kills:
    winner = team with more kills
elif timer_expired and team_a_kills == team_b_kills:
    enter overtime
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| kill_target | int | 10-30 | lobby settings | Kills needed to win (default 20) |
| team_a_kills | int | 0+ | Score System | Team A's total kills |
| team_b_kills | int | 0+ | Score System | Team B's total kills |

### Overtime Duration

```
overtime_remaining = overtime_max_duration - overtime_elapsed
is_draw = overtime_remaining <= 0 and team_a_kills == team_b_kills
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| overtime_max_duration | float | 30-120 s | tuning knob | Maximum overtime length (default 60s) |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Both teams reach kill target on the same frame (simultaneous kills) | First kill processed wins. Processing order is deterministic (lower team ID first). | No ties at kill target. Frame-order determinism prevents ambiguity. |
| Player disconnects during Countdown | Match still starts if both teams have at least 1 player. If a team is empty, match is cancelled, return to lobby. | Don't punish the remaining players. Minimum 1v1 to play. |
| All players on one team disconnect during Playing | Remaining team wins by forfeit. Match immediately transitions to Ended. | No point continuing a one-sided match. |
| Kill occurs during Ended state (damage was in flight) | Kill is not counted. Score is frozen at the moment of Ended transition. | Match is over. No post-match kills affecting the score. |
| Host disconnects in a P2P match | Host migration (if supported) or match ends with current score. Server-authoritative matches are unaffected (server persists). | Host migration is complex — defer to Networking GDD. For MVP (LAN), host disconnect = match ends. |
| Match duration set to 0 (instant timer) | Invalid setting. Minimum match duration enforced (60s). | Prevents degenerate lobbies. |
| Kill target set to 1 | Valid. "First blood" mode — first kill wins. Fast match. | Pillar 2: play your way. Unusual but valid configuration. |
| Overtime sudden death: both players hook each other simultaneously and both die | First death processed wins for the other team. Same deterministic rule as simultaneous kills. | Must have a winner in sudden death. Frame-order determinism. |
| Player joins mid-match (late join) | Not supported in MVP. Matches are closed once Loading begins. | Late join adds complexity (score catch-up, hero selection mid-match). Defer to Vertical Slice. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Arena/Map System** | Downstream | Hard — arena lifecycle controlled by match state | Sends `load_map`, `match_started`, `match_ended` |
| **Input System** | Downstream | Hard — input enable/disable controlled by match state | Sends `match_state_changed` |
| **Score/Kill Tracking** | Upstream | Hard — needs kill counts to check win condition | Reads `get_team_kills(team_id)`, listens to `kill_occurred` |
| **Camera System** | Downstream | Soft — camera state follows match state | Sends `match_started`, `match_ended` |
| **Respawn System** | Downstream | Soft — respawn behavior may change in overtime | Sends match state for overtime respawn rules |
| **HUD** | Downstream | Soft — HUD reads match state for timer/score display | Exposes `match_time_remaining`, `current_state`, `team_kills` |
| **Lobby System** | Upstream | Hard — lobby provides match configuration | Receives team rosters, map selection, match settings |
| **Health & Damage** | Downstream (indirect) | Soft — damage stops in Frozen state via Arena | No direct connection; Arena handles freeze |
| **Networking Layer** | Bidirectional | Hard (in multiplayer) — state transitions must be server-authoritative | Server runs timer and win checks; replicates to clients |

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `match_duration` | 300 s (5 min) | 180-480 s | Longer matches, more time for comebacks, may drag on mobile | Shorter, punchier matches, less time for RPG progression to matter |
| `kill_target` | 20 | 10-30 | Longer matches (more kills needed), higher-scoring games | Faster matches, fewer total engagements, each kill matters more |
| `countdown_duration` | 3 s | 2-5 s | More anticipation, players have time to look around | Faster start, less waiting |
| `overtime_max_duration` | 60 s | 30-120 s | More time for overtime to resolve naturally | Faster forced resolution, more draws |
| `ended_display_duration` | 3 s | 2-5 s | Longer victory/defeat splash | Faster transition to results |
| `results_screen_duration` | 15 s | 10-30 s | More time to review stats | Faster return to lobby |
| `min_match_duration` | 60 s | 30-120 s | Higher floor for match length | Allows very short custom matches |
| `final_countdown_threshold` | 30 s | 15-60 s | Earlier warning, more tension buildup | Later warning, more surprise endings |

**Knob interactions**:
- `match_duration` and `kill_target` together determine average match length. If
  kill target is easily reached before timer, timer is irrelevant. If kill target is
  too high, matches always end by timer.
- Target: most matches should end by kill target with 1-2 minutes remaining on the
  timer. Timer is the safety net, not the norm.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Countdown (3, 2, 1) | Large centered numbers, dramatic scale-in animation | Countdown beeps (increasing pitch), final "GO!" horn/sting | High |
| Match start (GO!) | "GO!" text burst, brief screen flash | Energetic horn or bell, arena music kicks to full volume | High |
| Kill target approaching (team at 80%+) | Score display pulses, subtle screen border glow in leading team's color | Tension music layer fades in | Medium |
| Final countdown (30s) | Timer turns red, pulses. "FINAL 30 SECONDS" banner | Urgency music layer, ticking clock sound | High |
| Timer expires | Timer flashes and disappears | Buzzer/horn sound | High |
| Overtime begins | "OVERTIME — NEXT KILL WINS" banner, screen border pulses | Dramatic sting, overtime music loop (intense) | High |
| Match ended — Victory | "VICTORY" splash with team color, confetti particles | Victory fanfare, cheering | High |
| Match ended — Defeat | "DEFEAT" splash, desaturated screen | Defeat sting, muted tone | High |
| Match ended — Draw | "DRAW" splash, neutral tone | Neutral resolution sound | Medium |
| Results screen | Stat cards animate in, MVP player highlighted | Results music (calmer than gameplay) | Medium |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Match timer | Top-center of screen | Every second (displays MM:SS) | During Playing and Overtime states |
| Team scores | Top-center, flanking the timer (Team A left, Team B right) | On each kill | During Playing and Overtime |
| Kill target | Small text below scores ("First to 20") | Static | During Playing |
| Countdown numbers | Center screen, large | Each second during Countdown | Countdown state only |
| "GO!" text | Center screen, large, fades out | Once at match start | Transition from Countdown to Playing |
| Overtime banner | Center-top, persistent | On overtime start | During Overtime |
| Final countdown warning | Timer turns red + banner | At threshold (30s) | Last 30s of Playing |
| Victory/Defeat/Draw splash | Full center screen, large | On match end | Ended state (3s) |
| Results screen | Full screen overlay | On results transition | Results state |
| MVP highlight | Center of results screen | On results transition | Results state — player with most kills |

## Acceptance Criteria

- [ ] Match flows through all states in correct order: Lobby → Loading → Countdown → Playing → (Overtime) → Ended → Results → Returning
- [ ] `match_state_changed` signal emits on every state transition
- [ ] Countdown displays 3, 2, 1, GO! with correct timing
- [ ] Match timer counts down accurately and displays on HUD
- [ ] Match ends immediately when a team reaches the kill target
- [ ] Match ends by timer when no team reaches kill target (higher score wins)
- [ ] Overtime triggers when timer expires with tied score
- [ ] Overtime ends on first kill (winning team) or after max duration (draw)
- [ ] Draw is a valid outcome with correct UI display
- [ ] All input disabled during Countdown, Ended, and Results states
- [ ] No kills counted after match enters Ended state
- [ ] Final countdown warning triggers at 30s remaining
- [ ] Results screen shows correct kill counts, MVP, and match duration
- [ ] Forfeit triggered when a team has 0 connected players
- [ ] Minimum match duration enforced (lobby can't set below 60s)
- [ ] Kill target of 1 is valid ("first blood" mode)
- [ ] All timing and threshold values loaded from config — no hardcoded values
- [ ] Performance: state checks complete within 0.1ms per frame

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should there be a "mercy rule" (auto-end if one team is ahead by X kills)? | game-designer | Before prototype | Start without. If blowout matches feel bad, add mercy rule (e.g., 10-kill lead = auto-win). |
| Should overtime have modified gameplay (e.g., smaller arena, faster hooks, more damage)? | game-designer | Before Vertical Slice | Start with pure sudden death. Modified overtime is interesting but complex — defer. |
| Should the results screen show a "play again" button that keeps the same lobby? | ux-designer | Before Lobby System GDD | Almost certainly yes. Core to the "one more match" loop. Specify in Lobby System GDD. |
| Should match settings be saved per-lobby (remember last kill target, duration)? | ux-designer | Before Lobby System GDD | Nice quality-of-life. Low priority for MVP. |
| How does the "flexible team size" interact with kill target? Should 1v5 have a lower kill target? | game-designer + systems-designer | Before prototype | Prototype with fixed kill target first. If asymmetric feels unfair, scale kill target by team size ratio. |
