# Sprint 3 — 2026-04-03 to 2026-04-17

## Sprint Goal
Enable real PvP playtesting: add networking foundation with LAN lobby, complete
the match results loop, add core VFX/audio feedback, and fill remaining MVP gaps
(assists, post-match stats). By sprint end, two players on the same network can
play a full match and see results.

## Capacity
- Total days: 14
- Buffer (20%): 3 days reserved for unplanned work
- Available: 11 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S3-01 | **Assist Tracking** — Track damage dealers within 5s window, credit assists on kill | score-kill-tracking.md | 1 | S1-14 (score), S1-06 (health) | Assist credited when player dealt damage within 5s of kill but didn't get kill. Max 1 assist per kill. Assists shown in stats. XP awarded (25 per assist). |
| S3-02 | **Match Results Screen** — Post-match stats overlay with K/D/A, hook accuracy, MVP highlight | hud.md, score-kill-tracking.md | 2 | S1-14, S3-01 | Full-screen results after match end. Shows per-player kills, deaths, assists, hook accuracy. MVP highlighted (highest score on winning team). "Play Again" button restarts match. |
| S3-03 | **Networking Architecture Decision** — Evaluate Godot 4.6 multiplayer API, choose LAN P2P approach | — | 0.5 | None | ADR written to docs/architecture/. Decision: ENetMultiplayerPeer for LAN. Server-authoritative for match state. Client-authoritative for movement (trust for LAN). |
| S3-04 | **Multiplayer Foundation** — ENet peer setup, player spawning, basic state sync | — | 2.5 | S3-03 | Host can create game, client can join via IP. Both players spawn in arena on opposite teams. Player positions sync. Hook projectiles visible to both players. |
| S3-05 | **Lobby System (basic)** — Host/join screen, hero selection, ready state, match start | — | 2 | S3-04 | Host sees lobby with IP displayed. Client enters IP to join. Both players select heroes. Both ready → countdown starts. Disconnect returns to lobby. |
| S3-06 | **Networked Match Flow** — Sync match state, kills, scores, respawns across peers | match-state-manager.md | 2 | S3-04, S3-05 | Countdown synced. Timer synced. Kill events replicated. Scores match on both screens. Respawns synced. Match end/results synced. Overtime works in multiplayer. |

### Should Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S3-07 | **Core VFX** — Hook trail particles, hit impact flash, death effect, respawn flash | — | 1.5 | S1-07 (hook), S1-06 (health) | Hook leaves trail particles matching hero color. Hit creates brief flash. Death = brief fade/shrink. Respawn = fade-in + invuln glow. All readable at isometric distance. |
| S3-08 | **Basic Audio** — Hook fire/hit/miss SFX, kill chime, countdown beeps, match start horn | — | 1 | None | Hook fire sound on fire. Impact sound on hit. Whoosh on miss/return. Kill chime. Countdown beep per second. "GO!" horn. Sounds play correctly for both players in multiplayer. |

### Nice to Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S3-09 | **Enemy Health Bars** — World-space health bar above enemy players | hud.md | 0.5 | S3-04 | Health bar visible above enemy. Updates in real-time. Hidden when enemy is dead. Readable at isometric zoom. |
| S3-10 | **Disconnect Handling** — Graceful handling when a player disconnects mid-match | — | 0.5 | S3-06 | Disconnected player removed from game. If team has 0 players, other team wins by forfeit. Remaining player sees "Opponent Disconnected" message. |
| S3-11 | **Balance Tuning Pass** — Adjust hero stats based on testing, ensure 3-4 hits-to-kill | hero-system.md | 0.5 | S3-06 | All hero matchups feel fair. Maw double-hit not overpowered. Lash grapple risk/reward balanced. Kill times between 3-8 seconds in active combat. |

## Carryover from Previous Sprint
N/A — Sprint 2 completed in full (13/13 tasks).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Godot 4.6 ENet API has undocumented changes from 4.3 | Medium | High | Consult docs/engine-reference/ before coding. Test basic connection first. |
| Network latency makes hook hit detection feel unfair on LAN | Low | High | LAN latency is <5ms typically. If needed, add hit confirmation buffer. |
| Syncing hook projectile positions causes jitter | Medium | Medium | Sync fire event + direction, let each client simulate projectile locally. |
| Audio asset creation takes longer than expected | Medium | Low | Use placeholder beep/click sounds. Polish audio in Sprint 4. |
| Results screen UI is complex and time-consuming | Medium | Medium | Keep it simple: text-only stats, no animations. Polish in Sprint 4. |

## Dependencies on External Factors
- Two machines on the same LAN for multiplayer testing
- Godot 4.6 export templates for multi-instance testing

## Definition of Done for this Sprint
- [ ] All Must Have tasks (S3-01 through S3-06) completed
- [ ] Two players can play a full match over LAN
- [ ] Hero selection, match flow, scoring, and results all work in multiplayer
- [ ] Assists tracked and displayed correctly
- [ ] Match results screen shows K/D/A, accuracy, MVP
- [ ] No crash bugs in delivered features
- [ ] All networking code uses server-authoritative match state

## Sprint 3 → Sprint 4 Preview
Sprint 4 will focus on:
- Online multiplayer (relay server or punch-through for non-LAN play)
- Full VFX polish (particles, screen effects, juice)
- Audio polish (per-hero sounds, ambient, music)
- Settings menu (volume, sensitivity, controls)
- Mobile device testing and touch input refinement
- Performance profiling and optimization pass
