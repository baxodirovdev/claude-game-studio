# Hook Wars (a.k.a. Pudge Wars)
**Updated:** 2026-04-16
**Status:** In Development — Sprint 7 (Beta Balance Pass)
**Engine:** Godot 4.6 (GDScript)
**Path:** `../../Claude-Code-Game-Studios`

## Overview
Mobile PvP arena game where every hero wields a unique physics-based hook.
"Pudge Wars meets Brawl Stars" — skillshot combat, in-match RPG progression,
flexible friend lobbies. Up to 5v5 with asymmetric team sizes (1v5, 2v3, etc.).
Matches: 5–8 minutes. Monetization: cosmetics only, no pay-to-win.

## Genre & Platform
- **Genre:** Action PvP Arena / RPG
- **Platform:** Mobile (iOS & Android)
- **Comparable Titles:** Brawl Stars, Dota 2 Pudge Wars, Battlelands Royale
- **Art Style:** 3D stylized / low-poly (Brawl Stars aesthetic)

## Core Pillars
1. **Skillshot is King** — no auto-aim, mechanical skill is the differentiator
2. **Play Your Way With Friends** — flexible lobbies, asymmetric teams, casual chaos
3. **Every Match is a Fresh Start** — in-match RPG only, no permanent power gaps
4. **Fast and Mobile-First** — 5–8 min matches, thumb-friendly controls, touch-native

## Heroes (Sprint 7 Final Balance)

| Hero | HP | Damage | Range | CD | Hook Mechanic | Identity |
|------|----|--------|-------|----|---------------|----------|
| Vex | 100 | 30 | 20 | 2.0s | Pull target to you | Balanced baseline |
| Lash | 80 | 25 | 25 | 2.5s | Grapple swing to target | Glass cannon mobility |
| Maw | 130 | 35+25/pass | 15 | 2.5s | Boomerang hits twice | Tanky burst |
| Flux | 90 | 30 DPS×1.5s | 14 | 3.0s | Beam tether + pull | Sustained control |
| Coil | 95 | 20–50 | 12–24 | 2.5s | Charge shot for power | High skill ceiling |

Kill time target: **3–8 seconds** across all matchups vs 100 HP baseline.

## Architecture

### Source Structure (`src/`)
```
core/
  arena/          — map system, boundaries, spawn points, hazard slots
  camera/         — game_camera.gd — follow cam with arena bounds
  environment/    — lighting, atmosphere
  input/          — touch input abstraction for hook aiming
  network/        — networking layer (client-server authoritative)
  scene_flow/     — scene transitions, match lifecycle
  audio/          — audio bus management

gameplay/
  hero/           — hero_model_builder, stats, hook type definitions
  hook/           — physics projectile, hit detection, chain pull logic
  health/         — damage, death events
  hazards/        — pits, spikes, lava zones
  respawn/        — respawn timer, spawn point selection
  match/          — match state manager, win conditions
  player/         — player controller (movement, dodge)
  score/          — kill tracking, scoreboard data
  economy/        — in-match gold, item shop
  vfx/            — hit feedback, screen shake, slow-mo
```

### Key Systems (26 total)

| Priority | System | Status |
|----------|--------|--------|
| MVP | Input, Arena/Map, Player Controller, Camera | Designed + Implemented |
| MVP | Health & Damage, Match State Manager | Designed + Implemented |
| MVP | Hook Aiming & Physics | Designed + Implemented |
| MVP | Hero System (5 heroes) | Designed + Implemented |
| MVP | Map Hazards, Respawn, Score/Kill Tracking, HUD | Designed + Implemented |
| Vertical Slice | In-Match Economy | Designed |
| Vertical Slice | Networking Layer, Lobby System, VFX | Not Started |
| Alpha+ | Audio, Match Results UI, Matchmaking | Not Started |

### Networking
- Client-server authoritative (prevents hook cheating)
- LAN/P2P for MVP; dedicated relay servers deferred to Vertical Slice
- Lag compensation required for skillshot hit detection at 100–200ms mobile latency

## Arena Map
- Mirrored symmetry (left/right balanced)
- River gap dividing the arena
- Trees and props as cover
- Hazards: pits, walls, lava zones (hooks interact with hazards)

## In-Match Economy (Sprint 6 Design)
- Gold earned from kills and hook hits
- Spent in quick mid-match item shop
- Items modify hook: longer range, wider hitbox, faster travel, chain bounce
- Max ~15 items to keep mobile UI fast

## Design Documents (`design/gdd/`)
| Document | System |
|----------|--------|
| game-concept.md | Full game concept, MDA framework, pillars |
| systems-index.md | All 26 systems, dependencies, priority tiers |
| input-system.md | Touch input abstraction |
| arena-map-system.md | Map layout, hazard placement |
| player-controller.md | Movement, dodge |
| camera-system.md | Follow cam, arena bounds |
| health-and-damage.md | HP, damage events, death |
| match-state-manager.md | Match lifecycle, win conditions |
| hook-aiming-and-physics.md | Projectile physics, hit detection |
| hero-system.md | Hero stats, hook types, ability framework |
| map-hazards.md | Pit/spike/lava mechanics |
| respawn-system.md | Timer, spawn selection |
| score-kill-tracking.md | Kill feed, scoreboard |
| hud.md | In-match HUD (Brawl Stars style) |
| in-match-economy.md | Gold, items, shop |

## Balance History
| Sprint | Key Changes |
|--------|-------------|
| Sprint 3 | Initial tuning pass |
| Sprint 6 | Economy balance — gold income, item cost curves |
| Sprint 7 | Flux beam_dps 25→30, hook_cd 3.5→3.0s; Coil hook_cd 2.0→2.5s |

## MVP Scope
1 arena map + 3 heroes + touch hook aiming + LAN multiplayer + basic leveling + kill-target win condition.

## Scope Tiers
| Tier | Content | Timeline |
|------|---------|----------|
| MVP | 1 map, 3 heroes | 6–8 weeks |
| Vertical Slice | 1 map, 5 heroes, 15 items, online lobbies | 3–4 months |
| Alpha | 3 maps, 8 heroes, 25 items, ranked, cosmetics | 5–7 months |
| Full Vision | 5 maps, 12 heroes, 30+ items, spectator, replay | 9–12 months |

## Key Technical Risks
- Touch hook aiming precision on mobile — prototype 3 control variants
- Authoritative skillshot hit detection at mobile latency (lag compensation)
- 10 concurrent players with 3D effects on low-end Android
- Godot 4.6 mobile networking at scale (relatively unproven)
