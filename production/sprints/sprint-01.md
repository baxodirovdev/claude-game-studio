# Sprint 1 — 2026-03-31 to 2026-04-13

## Sprint Goal
Build the foundation systems: a player that moves in an arena with a working hook
that can hit targets — the minimum playable vertical slice of the core loop.

## Capacity
- Total days: 14
- Buffer (20%): 3 days reserved for unplanned work
- Available: 11 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S1-01 | ~~**Project Setup**~~ | — | 0.5 | None | ✅ Done — `src/` has core/, gameplay/, ui/ folders. Main scene loads. Mobile renderer configured. |
| S1-02 | ~~**Input System**~~ | input-system.md | 1.5 | S1-01 | ✅ Done — VirtualJoystick + HookButton with touch routing, facing angle, locked state. |
| S1-03 | ~~**Arena/Map System**~~ | arena-map-system.md | 2 | S1-01 | ✅ Done — Arena built from ArenaData resource. Gap, walls, spawn points, hazard markers. |
| S1-04 | ~~**Player Controller**~~ | player-controller.md | 1.5 | S1-02, S1-03 | ✅ Done — CharacterBody3D with INACTIVE/ACTIVE/LOCKED/PULLED/DEAD/FROZEN states. |
| S1-05 | ~~**Camera System**~~ | camera-system.md | 1 | S1-03, S1-04 | ✅ Done — Orthographic fixed-angle camera, smooth follow, gap offset, snap on respawn. |
| S1-06 | ~~**Health & Damage**~~ | health-and-damage.md | 1 | S1-04 | ✅ Done — HP tracking, take_damage, death signal, kill credit window, invulnerability. |
| S1-07 | ~~**Hook Aiming & Physics**~~ | hook-aiming-and-physics.md | 2.5 | S1-02, S1-03, S1-04, S1-06 | ✅ Done — Projectile fire/travel/hit/return, chain visual, pull mechanic, player lock during flight. |
| S1-08 | ~~**Integration Test**~~ | All above | 1 | S1-02 through S1-07 | ✅ Done — Full core loop works: move → aim → fire → hit → pull → kill. Arena signal timing bug fixed. |

### Should Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S1-09 | ~~**Match State Manager (basic)**~~ | match-state-manager.md | 1 | S1-03 | ✅ Done — WAITING→COUNTDOWN→PLAYING→ENDED states, match timer, kill target win condition, input disable/enable. |
| S1-10 | ~~**Respawn System (basic)**~~ | respawn-system.md | 0.5 | S1-06, S1-03 | ✅ Done — 3s death timer, safest spawn selection, health restore, 2s invulnerability, camera snap. |
| S1-11 | ~~**Data-Driven Config**~~ | hero-system.md | 1 | S1-04, S1-07 | ✅ Done — HeroConfig + MatchConfig .tres resources. All gameplay values configurable without code edits. |

### Nice to Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S1-12 | ~~**HUD (minimal)**~~ | hud.md | 1 | S1-06, S1-09 | ✅ Done — Health bar (green/yellow/red + ghost trail), match timer (red pulse at 30s), team scores, countdown, result splash, respawn timer, hook stats, invulnerability indicator. |
| S1-13 | ~~**Map Hazards (basic)**~~ | map-hazards.md | 1 | S1-03, S1-06 | ✅ Done — Gap/pit instant kill, spike zones with per-player cooldown and time-scaled damage. Active only during PLAYING state. |
| S1-14 | ~~**Score/Kill Tracking (basic)**~~ | score-kill-tracking.md | 0.5 | S1-06, S1-09 | ✅ Done — Per-player kills/deaths/streaks, per-team kill totals, kill feed (top-right, 4 entries, 5s fade), score frozen on match end. |

## Carryover from Previous Sprint
N/A — First sprint.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Godot 4.6 CharacterBody3D quirks on mobile | Medium | Medium | Test on device early (day 3-4). Reference engine-reference docs. |
| Hook collision detection feels imprecise | Medium | High | Use slightly forgiving hitbox (per GDD). Tune HOOK_HITBOX_RADIUS in config. |
| Touch input conflicts (joystick vs hook button) | Low | High | Isolate by touch index (per Input GDD). Test multi-touch on real device. |
| Arena left-to-right layout needs camera tuning | Low | Medium | Prototype already validated this layout. Fine-tune ortho_size on device. |
| Scope creep from polish/juice work | Medium | Medium | Defer all VFX, sound, screen shake to Sprint 2. Ship ugly but functional. |

## Dependencies on External Factors
- Godot 4.6 stable release must be available and working on target platforms
- Android/iOS export templates must be functional for device testing

## Definition of Done for this Sprint
- [x] All Must Have tasks (S1-01 through S1-08) completed
- [x] Core loop playable: move → aim → fire → hit → pull → kill
- [x] All tasks pass their acceptance criteria
- [x] No crash bugs in delivered features (arena signal timing bug fixed)
- [x] Code organized in `src/` following project directory structure
- [x] All gameplay values loaded from config files (HeroConfig + MatchConfig .tres)
- [x] Runs on desktop at 60fps (mobile testing is a bonus)
- [ ] Design documents updated for any deviations from GDD (e.g., left-to-right arena)

## Sprint 1 → Sprint 2 Preview
Sprint 2 will focus on:
- Hero System (3 heroes with distinct hook types: pull, grapple, boomerang)
- Score/Kill Tracking + win conditions
- Full Match State Manager (overtime, win/lose)
- HUD completion
- Map Hazards (spikes, pits)
- Audio/VFX feedback (hook sounds, screen shake, hit markers)
