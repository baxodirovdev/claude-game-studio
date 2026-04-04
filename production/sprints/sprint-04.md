# Sprint 4 — 2026-04-03 to 2026-04-17

## Sprint Goal
Polish the game into a presentable vertical slice: settings menu, main menu with
navigation flow, per-hero audio/VFX differentiation, second arena map, and a
performance profiling pass. By sprint end, the game has a complete front-to-back
flow (menu → lobby/hero select → match → results → menu) and feels polished enough
to demo.

## Capacity
- Total days: 14
- Buffer (20%): 3 days reserved for unplanned work
- Available: 11 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S4-01 | **Main Menu** — Title screen with Play (→ lobby/solo), Settings, Quit buttons | — | 1.5 | None | Menu scene loads on app start. Play → lobby screen (multiplayer) or hero select (solo). Settings → settings screen. Quit exits app. Clean transitions between screens. |
| S4-02 | **Settings Menu** — Volume (master/SFX), sensitivity sliders, save/load prefs | — | 1 | S4-01 | Master and SFX volume sliders that affect AudioServer bus volumes. Sensitivity slider affects input. Settings persist to file between sessions. Back button returns to main menu. |
| S4-03 | **Scene Flow Manager** — Centralized scene transitions (menu → lobby → game → results → menu) | — | 1 | S4-01 | SceneFlowManager autoload handles all scene changes. Supports transition animations (fade). Play Again goes back to hero select. Return to Menu from results. No orphaned scenes. |
| S4-04 | **Per-Hero VFX** — Unique hook trail colors/shapes, distinct hit/death effects per hero | — | 1.5 | None | Vex: blue electric trail + blue flash. Lash: green energy trail + green slash effect. Maw: orange spinning disc trail + orange explosion. Each hero visually distinct at play distance. |
| S4-05 | **Per-Hero Audio** — Distinct hook fire/hit/miss sounds per hero type | — | 1 | None | Pull heroes: chain rattle sound. Grapple: zipline whoosh. Boomerang: spinning blade hum. Each hero sounds different on fire, hit, and miss. Uses procedural tones (different frequencies/envelopes). |
| S4-06 | **Second Arena Map** — New arena with different layout, hazard placement, and feel | arena-map-system.md | 2 | None | New arena resource with different dimensions, gap pattern, pit layout, and spawn positions. Selectable from lobby or menu. Both arenas playable in solo and multiplayer. At least one unique hazard arrangement. |

### Should Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S4-07 | **Screen Transitions** — Fade-in/out between scenes, countdown polish | — | 0.5 | S4-03 | Black fade on scene change (~0.3s). Countdown numbers scale/pulse. "GO!" has brief zoom effect. Match end has dramatic slow-mo or freeze-frame feel. |
| S4-08 | **HUD Polish** — Assist notification, team color coding, improved kill feed | hud.md | 1 | None | "+ASSIST" text appears on assist. Team A blue / Team B red color coding on scores and kill feed. Kill feed shows hero names with team colors. Personal K/D/A visible during match (small text or tab overlay). |
| S4-09 | **Performance Profiling Pass** — Measure frame times, identify bottlenecks, optimize | — | 1 | None | Profile main gameplay loop. Document frame time breakdown. Identify top 3 bottlenecks. Fix any that exceed 2ms per system. Ensure 60fps on desktop. Document results in docs/architecture/. |

### Nice to Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S4-10 | **Kill Streak Announcements** — Audio + visual for multi-kills and streaks | score-kill-tracking.md | 0.5 | S4-05 | "Double Kill", "Triple Kill" text + escalating sound at 2, 3+ rapid kills. Streak counter (3+) shows with distinct sound. |
| S4-11 | **Ambient Audio** — Background arena atmosphere, low music loop | — | 0.5 | S4-05 | Subtle ambient hum during match. Intensifies during overtime. Quiet during menu. Does not overpower SFX. |
| S4-12 | **Controls Rebinding** — Let player remap hook fire and movement inputs | input-system.md | 0.5 | S4-02 | Settings screen shows current bindings. Player can change hook fire button. Saved to settings file. |

## Carryover from Previous Sprint
N/A — Sprint 3 completed in full (11/11 tasks).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Scene transition system is complex with multiple entry points | Medium | Medium | Keep it simple: one SceneFlowManager with explicit transition methods per flow. |
| Per-hero VFX differentiation is subtle at isometric distance | Medium | Medium | Use bold color differences and distinct particle shapes. Test at actual zoom level. |
| Second arena design takes longer due to lack of level design tools | Low | Medium | Use code-based arena like first one. Keep layout simple. |
| Settings persistence across sessions has edge cases | Low | Low | Use ConfigFile with sane defaults. Validate on load. |

## Definition of Done for this Sprint
- [ ] All Must Have tasks (S4-01 through S4-06) completed
- [ ] Complete flow: Main Menu → Play → Hero Select → Match → Results → Menu
- [ ] Settings persist between sessions
- [ ] Each hero has distinct visual and audio identity
- [ ] Two playable arena maps
- [ ] No crash bugs in delivered features
- [ ] Performance profiled and documented (if S4-09 completed)

## Sprint 4 → Sprint 5 Preview
Sprint 5 will focus on:
- Online multiplayer (WebSocket relay or NAT punch-through)
- In-match economy (gold from kills, basic item shop)
- Touch input optimization for mobile
- Tutorial / onboarding flow
- Additional heroes (1-2 new hook types)
