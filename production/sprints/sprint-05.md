# Sprint 5 — 2026-04-04 to 2026-04-18

## Sprint Goal
Build toward alpha: in-match economy (gold + item shop), a 4th hero, touch input
optimization for mobile testing, and a basic tutorial. By sprint end, the game has
the core economic loop working (earn gold → buy items → get stronger) and is
playable on mobile devices.

## Capacity
- Total days: 14
- Buffer (20%): 3 days reserved for unplanned work
- Available: 11 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S5-01 | **In-Match Economy GDD** — Design gold earn rates, item costs, shop UI flow | — | 1 | None | GDD written with 8 required sections. Gold sources: kills (100g), assists (50g), hook hits (15g), passive (10g/15s). Starting gold: 0. Item budget: 5-8 items max. |
| S5-02 | **Gold System** — Track per-player gold, award on kills/assists/hits/passive | — | 1 | S5-01 | Gold awarded correctly per GDD rates. Gold resets each match. Gold display on HUD. Gold persists through death (no loss on death). |
| S5-03 | **Item Database** — Define 5-6 items with stat effects (damage, speed, health, cooldown) | — | 1 | S5-01 | Items defined as resources. Each has name, cost, stat bonuses, icon color. Items categorized: offensive (2), defensive (2), utility (2). Max 3 items per player. |
| S5-04 | **Item Shop UI** — Quick-buy overlay accessible during gameplay | — | 1.5 | S5-02, S5-03 | Shop opens with button/gesture. Shows available items with costs. Grayed out if can't afford. Buy applies stats immediately. Shows owned items. Closes quickly (<0.3s). |
| S5-05 | **4th Hero — Flux** — Magnetic beam hook type (continuous tether, gradual pull) | hero-system.md | 2 | None | New HeroConfig with BEAM hook type. Beam locks onto target and slowly pulls. Shorter range but auto-aim assist. Unique VFX (magnetic field particles) and audio (electric hum). Balanced vs existing 3. |
| S5-06 | **Touch Input Polish** — Optimize joystick feel, hook button responsiveness, dead zones | input-system.md | 1 | None | Joystick dead zone configurable. Hook button has visual feedback on press. No accidental fires. Responsive at 60fps touch polling. Test on mobile resolution. |

### Should Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S5-07 | **Basic Tutorial** — First-time flow teaching movement, hook fire, hazard awareness | — | 1.5 | None | Triggered on first play. 3 steps: move (joystick prompt), fire hook (target prompt), avoid hazard (warning prompt). Skippable. Completion saved to settings. |
| S5-08 | **Item Stat Application** — Purchased items modify hero stats in real-time | — | 1 | S5-04 | Buying damage item increases hook_damage. Buying speed item increases move_speed. Buying health item increases max_health (and current). Buying cooldown item reduces hook_cooldown. Stats stack. |

### Nice to Have

| ID | Task | Source GDD | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-----------|-------------|-------------------|
| S5-09 | **Gold Popup** — "+100g" floating text on gold earn events | — | 0.5 | S5-02 | Gold amount floats up from event location. Color: gold/yellow. Fades over 0.8s. |
| S5-10 | **Item Purchase VFX** — Brief glow/particle on hero when buying an item | — | 0.5 | S5-04 | Color flash matching item category. Brief particle burst. Readable at play distance. |
| S5-11 | **Hero Preview in Select** — Show hero stats and hook type description in hero select | — | 0.5 | S5-05 | Hero select shows: name, hook type, HP, damage, speed. Brief description of playstyle. |

## Carryover from Previous Sprint
N/A — Sprint 4 completed in full (12/12 tasks).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| In-match economy pacing feels wrong (too fast/slow gold income) | High | Medium | Make all gold values data-driven. Plan for tuning pass in Sprint 6. |
| 4th hero beam mechanic is complex to implement | Medium | High | Start with simplified version: beam = rapid short-range hooks. Polish in Sprint 6. |
| Shop UI interrupts gameplay flow | Medium | Medium | Keep shop minimal: 6 items, one-tap buy. Auto-close after purchase. |
| Touch input feels different on actual devices vs desktop testing | Medium | Medium | Test with mobile resolution viewport. Use input event simulation. |

## Definition of Done for this Sprint
- [ ] All Must Have tasks (S5-01 through S5-06) completed
- [ ] Player can earn gold from kills, assists, and passive income
- [ ] Player can open shop and buy items that modify stats
- [ ] 4th hero (Flux) playable with unique beam hook
- [ ] Touch input polished with configurable dead zones
- [ ] No crash bugs in delivered features

## Sprint 5 → Sprint 6 Preview
Sprint 6 will focus on:
- Online multiplayer (WebSocket relay server)
- Economy tuning pass (balance gold rates and item costs)
- 5th hero
- Matchmaking prototype
- Profile / meta progression (account level, hero mastery)
