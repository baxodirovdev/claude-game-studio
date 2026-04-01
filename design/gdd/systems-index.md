# Systems Index: Hook Wars

> **Status**: Draft
> **Created**: 2026-03-28
> **Last Updated**: 2026-03-28
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Hook Wars is a mobile PvP arena game where every hero wields a unique physics-based
hook. The mechanical scope centers on skillshot combat, in-match RPG progression, and
flexible friend lobbies. Systems must support 10 concurrent players in a 3D arena on
mobile hardware, with client-server authoritative networking for fair skillshot
resolution. The core loop — aim, launch, dodge, reposition — drives every system
decision: if it doesn't serve the hook, it doesn't belong.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Input System | Core | MVP | Designed | design/gdd/input-system.md | — |
| 2 | Arena/Map System | Core | MVP | Designed | design/gdd/arena-map-system.md | — |
| 3 | Audio System | Audio/VFX | Alpha | Not Started | — | — |
| 4 | Settings System | Meta | Full Vision | Not Started | — | — |
| 5 | Player Controller | Core | MVP | Designed | design/gdd/player-controller.md | Input, Arena/Map |
| 6 | Camera System | Core | MVP | Designed | design/gdd/camera-system.md | Player Controller, Arena/Map |
| 7 | Health & Damage | Gameplay | MVP | Designed | design/gdd/health-and-damage.md | Player Controller |
| 8 | Match State Manager | Core | MVP | Designed | design/gdd/match-state-manager.md | Arena/Map |
| 9 | Hook Aiming & Physics | Gameplay | MVP | Designed | design/gdd/hook-aiming-and-physics.md | Input, Player Controller, Arena/Map |
| 10 | Hero System | Gameplay | MVP | Designed | design/gdd/hero-system.md | Hook Aiming & Physics, Player Controller, Health & Damage |
| 11 | Map Hazards | Gameplay | MVP | Designed | design/gdd/map-hazards.md | Arena/Map, Health & Damage, Hook Aiming & Physics |
| 12 | Respawn System | Gameplay | MVP | Designed | design/gdd/respawn-system.md | Health & Damage, Match State Manager, Arena/Map |
| 13 | Score/Kill Tracking | Meta | MVP | Designed | design/gdd/score-kill-tracking.md | Health & Damage, Match State Manager |
| 14 | In-Match RPG Progression | Progression | Vertical Slice | Not Started | — | Score/Kill Tracking, Hero System |
| 15 | In-Match Economy | Economy | Vertical Slice | Not Started | — | Score/Kill Tracking, Match State Manager |
| 16 | Item Database & Shop | Economy | Vertical Slice | Not Started | — | In-Match Economy, Hero System |
| 17 | VFX/Feedback System | Audio/VFX | Vertical Slice | Not Started | — | Hook Aiming & Physics, Health & Damage |
| 18 | Networking Layer | Networking | Vertical Slice | Not Started | — | Player Controller, Hook Aiming & Physics, Match State Manager |
| 19 | HUD | UI | MVP | Designed | design/gdd/hud.md | Health & Damage, Score/Kill Tracking, In-Match Economy, Match State Manager |
| 20 | Match Results UI | UI | Alpha | Not Started | — | Score/Kill Tracking, Match State Manager |
| 21 | Lobby System | Networking | Vertical Slice | Not Started | — | Networking Layer, Hero System |
| 22 | Main Menu & Navigation | UI | Alpha | Not Started | — | Lobby System, Settings |
| 23 | Tutorial/Onboarding | Meta | Full Vision | Not Started | — | Hook Aiming & Physics, Hero System, HUD, Map Hazards |
| 24 | Profile & Meta Progression | Progression | Full Vision | Not Started | — | Match Results UI, Hero System, Lobby System |
| 25 | Matchmaking | Networking | Full Vision | Not Started | — | Networking Layer, Lobby System, Profile & Meta Progression |
| 26 | (reserved) | — | — | — | — | — |

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Core** | Foundation systems everything depends on | Input, Arena/Map, Player Controller, Camera, Match State Manager |
| **Gameplay** | The systems that make the game fun | Hook Aiming & Physics, Hero System, Map Hazards, Health & Damage, Respawn |
| **Progression** | How the player grows | In-Match RPG, Profile & Meta Progression |
| **Economy** | Resource creation and consumption | In-Match Economy, Item Database & Shop |
| **Networking** | Online play and lobbies | Networking Layer, Lobby System, Matchmaking |
| **UI** | Player-facing information displays | HUD, Match Results UI, Main Menu & Navigation |
| **Audio/VFX** | Sound and visual feedback | Audio System, VFX/Feedback System |
| **Meta** | Systems outside the core game loop | Score/Kill Tracking, Settings, Tutorial/Onboarding |

---

## Priority Tiers

| Tier | Systems | Count | Target Milestone |
|------|---------|-------|------------------|
| **MVP** | Input, Arena/Map, Player Controller, Camera, Health & Damage, Match State Manager, Hook Aiming & Physics, Hero System, Map Hazards, Respawn, Score/Kill Tracking, HUD | 12 | First playable prototype (6-8 weeks) |
| **Vertical Slice** | In-Match RPG, In-Match Economy, Item Database & Shop, Networking Layer, Lobby System, VFX/Feedback System | 6 | Vertical slice / demo (3-4 months) |
| **Alpha** | Audio System, Match Results UI, Main Menu & Navigation | 3 | Alpha milestone (5-7 months) |
| **Full Vision** | Settings, Tutorial/Onboarding, Profile & Meta Progression, Matchmaking | 4 | Beta / Release (9-12 months) |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Input System** — all player interaction flows through this; touch input abstraction for hook aiming
2. **Arena/Map System** — the spatial container; walls, boundaries, spawn points, hazard slots
3. **Audio System** — standalone playback engine, no gameplay dependencies
4. **Settings System** — standalone config store for player preferences

### Core Layer (depends on foundation)

1. **Player Controller** — depends on: Input, Arena/Map
2. **Camera System** — depends on: Player Controller, Arena/Map
3. **Health & Damage** — depends on: Player Controller
4. **Match State Manager** — depends on: Arena/Map

### Feature Layer (depends on core)

1. **Hook Aiming & Physics** — depends on: Input, Player Controller, Arena/Map
2. **Hero System** — depends on: Hook Aiming & Physics, Player Controller, Health & Damage
3. **Map Hazards** — depends on: Arena/Map, Health & Damage, Hook Aiming & Physics
4. **Respawn System** — depends on: Health & Damage, Match State Manager, Arena/Map
5. **Score/Kill Tracking** — depends on: Health & Damage, Match State Manager
6. **In-Match RPG Progression** — depends on: Score/Kill Tracking, Hero System
7. **In-Match Economy** — depends on: Score/Kill Tracking, Match State Manager
8. **Item Database & Shop** — depends on: In-Match Economy, Hero System
9. **VFX/Feedback System** — depends on: Hook Aiming & Physics, Health & Damage
10. **Networking Layer** — depends on: Player Controller, Hook Aiming & Physics, Match State Manager

### Presentation Layer (depends on features)

1. **HUD** — depends on: Health & Damage, Score/Kill Tracking, In-Match Economy, Match State Manager
2. **Match Results UI** — depends on: Score/Kill Tracking, Match State Manager
3. **Lobby System** — depends on: Networking Layer, Hero System
4. **Main Menu & Navigation** — depends on: Lobby System, Settings

### Polish Layer (depends on everything)

1. **Tutorial/Onboarding** — depends on: Hook Aiming & Physics, Hero System, HUD, Map Hazards
2. **Profile & Meta Progression** — depends on: Match Results UI, Hero System, Lobby System
3. **Matchmaking** — depends on: Networking Layer, Lobby System, Profile & Meta Progression

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Input System | MVP | Foundation | game-designer, godot-specialist | S |
| 2 | Arena/Map System | MVP | Foundation | game-designer, level-designer | M |
| 3 | Player Controller | MVP | Core | game-designer, gameplay-programmer | M |
| 4 | Camera System | MVP | Core | game-designer, godot-specialist | S |
| 5 | Health & Damage | MVP | Core | systems-designer | M |
| 6 | Match State Manager | MVP | Core | systems-designer | M |
| 7 | Hook Aiming & Physics | MVP | Feature | game-designer, systems-designer, gameplay-programmer | L |
| 8 | Hero System | MVP | Feature | game-designer, systems-designer | L |
| 9 | Map Hazards | MVP | Feature | game-designer, level-designer | M |
| 10 | Respawn System | MVP | Feature | game-designer | S |
| 11 | Score/Kill Tracking | MVP | Feature | systems-designer | S |
| 12 | HUD | MVP | Presentation | ux-designer, ui-programmer | M |
| 13 | In-Match Economy | VS | Feature | economy-designer | M |
| 14 | In-Match RPG Progression | VS | Feature | systems-designer | M |
| 15 | Item Database & Shop | VS | Feature | economy-designer, systems-designer | M |
| 16 | VFX/Feedback System | VS | Feature | technical-artist, sound-designer | M |
| 17 | Networking Layer | VS | Feature | network-programmer | L |
| 18 | Lobby System | VS | Presentation | game-designer, network-programmer | M |
| 19 | Audio System | Alpha | Foundation | audio-director, sound-designer | M |
| 20 | Match Results UI | Alpha | Presentation | ux-designer, ui-programmer | S |
| 21 | Main Menu & Navigation | Alpha | Presentation | ux-designer, ui-programmer | M |
| 22 | Settings System | Full | Foundation | ui-programmer | S |
| 23 | Tutorial/Onboarding | Full | Polish | game-designer, ux-designer | M |
| 24 | Profile & Meta Progression | Full | Polish | systems-designer, economy-designer | L |
| 25 | Matchmaking | Full | Polish | network-programmer, systems-designer | L |

---

## Circular Dependencies

None found. The dependency graph is acyclic — each layer strictly depends on
layers above it.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Hook Aiming & Physics | Technical + Design | Core mechanic. Touch aiming may not feel precise enough. Highest bottleneck (8 dependents). | Prototype 3 control variants early (`/prototype hook-aiming`). Test on low-end devices. |
| Networking Layer | Technical | Authoritative skillshot hit detection at mobile latency (100-200ms). Lag compensation is complex. | Research Godot 4.6 multiplayer API. Prototype LAN first, defer online. |
| Hero System | Design + Scope | Asymmetric hook types (pull, swing, boomerang) must all feel fair and fun. Balancing is open-ended. | Start with 3 heroes only. Playtest extensively before adding more. |
| In-Match Economy | Design | Item shop mid-match could slow down action. UI must be fast on mobile. | Keep items to 10-15 max. Quick-buy UI. Playtest pacing. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 25 |
| Design docs started | 12 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 12/12 |
| Vertical Slice systems designed | 0/6 |

---

## Next Steps

- [ ] Design MVP-tier systems in order (use `/design-system [system-name]`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Prototype Hook Aiming & Physics early (`/prototype hook-aiming`)
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Plan first implementation sprint with `/sprint-plan new`
