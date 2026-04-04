# Sprint 7 — 2026-04-04 to 2026-04-18

## Sprint Goal
Beta readiness: tutorial/onboarding, matchmaking prototype, profile UI, arena
selection, and final polish pass. By sprint end, a new player can pick up the
game, learn the basics, find a match, and see their progression.

## Capacity
- Total days: 14
- Buffer (20%): 3 days reserved
- Available: 11 days

## Tasks

### Must Have

| ID | Task | Est. Days | Acceptance Criteria |
|----|------|-----------|-------------------|
| S7-01 | **Tutorial System** — 3-step guided onboarding (move, hook, hazard) | 2 | Step-by-step prompts with highlights. Skippable. Completion saved. Triggered on first play. |
| S7-02 | **Arena Selection UI** — Choose arena before match from lobby/menu | 0.5 | Dropdown/buttons for 3 arenas + Random. Selection loads correct ArenaData. Works in solo and multiplayer. |
| S7-03 | **Profile Screen** — View stats, level, hero mastery from main menu | 1.5 | Shows account level + XP bar, lifetime K/D/A, win rate, matches played. Per-hero mastery section with tier badges. |
| S7-04 | **Post-Match Profile Integration** — Record stats and show progress after match | 1 | Results screen shows +XP, level progress. Profile updated on match end. Hero mastery incremented. |
| S7-05 | **Matchmaking Prototype** — Auto-match via relay server queue | 1.5 | "Find Match" button in menu. Connects to relay, enters queue. Auto-paired when 2 players queue. Falls back to "no players found" after 30s. |
| S7-06 | **Final Balance Pass** — Tune all 5 heroes, items, economy for beta | 1 | All matchups 3-8s kill time. Coil charge feels rewarding. Flux beam not overpowered. Item builds feel distinct. Document changes. |

### Should Have

| ID | Task | Est. Days | Acceptance Criteria |
|----|------|-----------|-------------------|
| S7-07 | **Loading Screen** — Show tips/art during scene transitions | 0.5 | Random gameplay tip displayed during fade. "Hook Wars" branding. |
| S7-08 | **Kill Cam / Death Recap** — Brief info on what killed you during respawn | 1 | During respawn timer, show: "Killed by [Hero] with [damage type]". Shows killer's hero color. |
| S7-09 | **Spectator Mode** — Watch after death in multiplayer | 0.5 | Camera follows random alive teammate after death. Toggle between players. |

### Nice to Have

| ID | Task | Est. Days | Acceptance Criteria |
|----|------|-----------|-------------------|
| S7-10 | **Daily Challenge** — One challenge per day for bonus XP | 0.5 | "Get 5 kills" or "Win 2 matches" type challenges. Tracks progress. Awards bonus XP. Resets daily. |
| S7-11 | **Hero Stat Comparison** — Side-by-side hero stats in select screen | 0.5 | Shows radar chart or bar comparison of HP/Damage/Speed/Range/Cooldown. |

## Definition of Done
- [ ] New player can complete tutorial and understand core gameplay
- [ ] Players can auto-match online via queue
- [ ] Profile shows progression and hero mastery
- [ ] All heroes balanced for beta
- [ ] Arena selectable before match
