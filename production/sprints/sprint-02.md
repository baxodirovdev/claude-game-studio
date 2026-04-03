# Sprint 2 — 2026-04-02 to 2026-04-16

## Sprint Goal
Add hero diversity (3 distinct heroes with unique hook types) and game feel
(audio/VFX feedback, complete match flow with overtime) — transforming the
prototype into a game with player expression and polish.

## Capacity
- Total days: 14
- Buffer (20%): 3 days reserved for unplanned work
- Available: 11 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S2-01 | ~~**Hero Data System**~~ | hero-system.md | 1.5 | S1-11 | ✅ Done — HeroConfig with HookType enum, per-hero .tres files, identity/leveling/grapple/boomerang fields, get_effective_stat(). |
| S2-02 | ~~**Vex — Chain Puller**~~ | hero-system.md | 0.5 | S2-01 | ✅ Done — Existing pull behavior wrapped in hero identity. Blue capsule, 100 HP, speed 10, dmg 30. |
| S2-03 | ~~**Lash — Grapple Swinger**~~ | hero-system.md | 2 | S2-01 | ✅ Done — Reverse pull (player → target). Hazard detection during grapple travel. Green capsule, 80 HP, speed 13. |
| S2-04 | ~~**Maw — Boomerang Blader**~~ | hero-system.md | 2 | S2-01 | ✅ Done — Spinning disc, hits outward + return, no pull, wider return hitbox. Orange disc, 130 HP, speed 7, 40+30 dmg. |
| S2-05 | ~~**Hero Leveling (basic)**~~ | hero-system.md | 1.5 | S2-01, S1-14 | ✅ Done — HeroLevelSystem: XP from hits/kills, 3 levels, stat bonuses applied live. HUD shows name/level/XP bar. |
| S2-06 | ~~**Overtime**~~ | match-state-manager.md | 1 | S1-09 | ✅ Done — OVERTIME state on tied score, next kill wins, 60s max then draw. "OVERTIME" + "NEXT KILL WINS" on HUD. |
| S2-07 | ~~**Integration & Balance Test**~~ | All above | 1.5 | S2-02 through S2-06 | ✅ Done — All 3 heroes implemented with distinct mechanics. Hero selection UI. All systems wired. |

### Should Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S2-08 | ~~**HUD — Hero & Level Display**~~ | hud.md | 1 | S2-05 | ✅ Done — Hero name, "Lv.X", XP progress bar, "LEVEL UP" center text on level gain. |
| S2-09 | ~~**Hero Selection UI (basic)**~~ | hero-system.md | 1 | S2-01 | ✅ Done — 3-button hero picker shown before countdown. Selection applies all stats. |
| S2-10 | ~~**Hook VFX Differentiation**~~ | hook-aiming-and-physics.md | 0.5 | S2-02, S2-03, S2-04 | ✅ Done — Projectile color matches hero color. Maw = spinning disc (no chain). |

### Nice to Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S2-11 | ~~**Screen Shake**~~ | camera-system.md | 0.5 | S1-05 | ✅ Done — Hook hit = 0.15 intensity, kill = 0.3 intensity. Decays smoothly. |
| S2-12 | ~~**Hit Markers**~~ | hud.md | 0.5 | S1-12 | ✅ Done — "HOOKED!" center-screen for 0.8s on hook hit. |
| S2-13 | ~~**Kill Streak Display**~~ | score-kill-tracking.md | 0.5 | S1-14 | ✅ Done — "STREAK xN!" at 3+ consecutive kills. |

## Carryover from Previous Sprint
N/A — Sprint 1 completed in full (14/14 tasks).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Lash grapple feels disorienting (camera snap to new position) | Medium | High | Use camera.snap_to_target() on arrival. Test with smooth vs instant transition. |
| Maw boomerang return-hit detection feels inconsistent | Medium | High | Use generous hitbox on return pass. Clear visual telegraph (spinning disc). |
| Hero balance feels off without real PvP testing (only dummy targets) | High | Medium | Tune conservatively. All values in config. Plan balance-focused playtesting in Sprint 3. |
| XP leveling too fast or too slow with dummy targets | Medium | Low | Use kill_target config to simulate match pacing. Adjust XP thresholds in config. |
| Overtime sudden death feels anticlimactic without audio/VFX | Medium | Medium | Overtime banner + HUD red styling covers minimum feedback. Audio deferred to Sprint 3. |

## Dependencies on External Factors
- No external dependencies — all work is code and config changes

## Definition of Done for this Sprint
- [x] All Must Have tasks (S2-01 through S2-07) completed
- [x] All 3 heroes playable with distinct hook mechanics
- [x] Hero leveling awards stat bonuses at correct thresholds
- [x] Overtime triggers on tied score, resolves correctly
- [x] No crash bugs in delivered features
- [x] All hero stats and match values in .tres config files
- [x] Runs on desktop at 60fps
- [ ] Design documents updated for any deviations from GDD

## Sprint 2 → Sprint 3 Preview
Sprint 3 will focus on:
- Audio system (hook sounds per hero, level-up chime, ambient arena)
- Advanced VFX (particles for hooks, hazards, deaths, respawn flash)
- Networking foundation (lobby, P2P or server-authoritative architecture decision)
- Hero balance pass with real PvP playtesting
- Assist tracking and full post-match stats screen
