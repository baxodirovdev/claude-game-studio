# Sprint 6 — 2026-04-04 to 2026-04-18

## Sprint Goal
Push toward beta: online multiplayer via WebSocket relay, 5th hero, economy tuning,
basic player profiles, and a third arena. By sprint end, players can connect online
(not just LAN), the economy feels balanced, and there's persistent progression.

## Capacity
- Total days: 14
- Buffer (20%): 3 days reserved for unplanned work
- Available: 11 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-------------------|
| S6-01 | **WebSocket Relay Server** — Simple relay for non-LAN play | 2 | ADR-001 | GDScript or external relay accepts connections, forwards packets between 2 peers. Players connect via room code. Works across networks. |
| S6-02 | **Online Multiplayer Integration** — Swap ENet for WebSocket peer in NetworkManager | 1.5 | S6-01 | NetworkManager supports both LAN (ENet) and Online (WebSocket) modes. Lobby shows "LAN" or "Online" option. Room code display/entry for online. |
| S6-03 | **5th Hero — Coil** — Spring-loaded hook (charge to increase range/damage) | 2 | None | New CHARGE hook type. Hold fire to charge (0.5-2s), release to fire. Longer charge = more range + damage. Unique VFX (coiling energy) + audio (spring tension). |
| S6-04 | **Economy Tuning Pass** — Adjust gold rates and item costs based on match flow analysis | 0.5 | None | Review GPM curves vs match duration. Adjust if first item takes >2min or full build <3min. Document changes. |
| S6-05 | **Player Profile System** — Persistent account with level, wins, hero mastery | 1.5 | None | Profile saves to user://. Tracks: total wins, total kills, matches played, per-hero games played. Account level from total XP. Loads on startup. |
| S6-06 | **Third Arena — The Abyss** — Large arena with multiple gaps and complex hazard layout | 1 | None | 50x45 arena, two parallel gaps, 8 spike zones, 6 pits. Dark color theme. Playable in all modes. |

### Should Have

| ID | Task | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-------------------|
| S6-07 | **Arena Selection UI** — Choose arena from lobby/menu before match | 0.5 | S6-06 | Dropdown or button list showing all arenas. Selection applies to match. Default = random. |
| S6-08 | **Post-Match Profile Update** — Award XP/wins after match, show progress | 1 | S6-05 | Match results show XP gained, level progress bar. Win increments win counter. Per-hero mastery tracks games played. |

### Nice to Have

| ID | Task | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-------------------|
| S6-09 | **Room Code System** — 4-letter codes for easy online lobby joining | 0.5 | S6-01 | Host gets a code like "ABCD". Client enters code instead of IP. Relay maps code to connection. |
| S6-10 | **Gold Popup VFX** — "+100g" floating text on gold earn | 0.5 | None | Gold amount floats up, yellow color, fades in 0.8s. Shows on kills, assists, passive ticks. |
| S6-11 | **Hero Mastery Badges** — Visual indicator of hero experience in select screen | 0.5 | S6-05, S6-08 | Bronze/Silver/Gold badge next to hero name based on games played (10/25/50). |

## Definition of Done
- [ ] Players can connect online via WebSocket relay with room codes
- [ ] 5th hero (Coil) playable with charge mechanic
- [ ] Economy feels balanced (first item ~1-2min, full build ~4min)
- [ ] Player profile persists between sessions
- [ ] Three arena maps available
- [ ] No crash bugs
