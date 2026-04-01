# Game Concept: Hook Wars

*Created: 2026-03-28*
*Status: Draft*

---

## Elevator Pitch

> It's a mobile PvP arena game where every hero wields a unique hook — fling
> enemies into hazards, dodge incoming chains, and outplay your friends in fast,
> flexible team matches with in-match RPG progression. Pudge Wars meets Brawl
> Stars.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Action PvP Arena / RPG |
| **Platform** | Mobile (iOS & Android) |
| **Target Audience** | Mid-core mobile gamers who enjoy competitive PvP with friends |
| **Player Count** | Multiplayer: up to 5v5 with flexible team sizes (1v5, 2v3, etc.) |
| **Session Length** | 5-8 minutes per match, 15-30 minute sessions |
| **Monetization** | Cosmetics only (skins, effects, emotes). No pay-to-win. |
| **Estimated Scope** | Medium (3-6 months for full release, 1-3 months for MVP) |
| **Comparable Titles** | Brawl Stars, Dota 2 Pudge Wars, Battlelands Royale |

---

## Core Fantasy

You are a hook master in a chaotic arena. Every kill comes from reading your
opponent, predicting their movement, and landing the perfect skillshot. The
feeling of pulling an enemy across the map into a hazard — or dodging a hook
at the last millisecond — is what keeps you and your friends coming back.

This is the game where YOU are the highlight reel. Every match produces moments
worth screaming about.

---

## Unique Hook

Like Brawl Stars' accessible mobile PvP, **AND ALSO** every hero's primary
weapon is a physics-based hook with unique behavior — chain pull, grapple
swing, magnetic beam, boomerang blade. Combat is entirely about mastering
positional skillshots, not button-mashing abilities.

The flexible team system (choose your own sides: 1v5, 2v3, 4v1) means every
lobby plays differently, true to the Dota custom game spirit.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 3 | Satisfying hook hit feedback, screen shake, slow-mo on long-range hooks |
| **Fantasy** (make-believe, role-playing) | 5 | Each hero has a distinct identity and hook style |
| **Narrative** (drama, story arc) | N/A | No story — pure PvP |
| **Challenge** (obstacle course, mastery) | 1 | Skillshot precision, prediction, outplaying opponents |
| **Fellowship** (social connection) | 2 | Playing with friends, flexible teams, shared laughs |
| **Discovery** (exploration, secrets) | 6 | Learning new hero hook synergies and map tricks |
| **Expression** (self-expression, creativity) | 4 | Hero choice, cosmetics, creative hook plays |
| **Submission** (relaxation, comfort zone) | N/A | This game is active and competitive, not relaxing |

### Key Dynamics (Emergent player behaviors)

- Players predict enemy movement patterns and bait hooks to create openings
- Teams develop positioning strategies around map hazards
- Asymmetric team sizes create underdog narratives (the 1v5 clutch play)
- Players discover hero hook synergies (chain pull into magnetic beam combo)
- Friends develop rivalries and running joke moments from memorable hooks

### Core Mechanics (Systems we build)

1. **Hook aiming and physics** — touch-based aim, projectile travel, collision detection
2. **Hero system** — unique hook types per hero, secondary abilities, in-match leveling
3. **In-match RPG progression** — XP, gold, item shop, ability upgrades within each match
4. **Map hazards** — environmental dangers that hooks interact with (pits, spikes, lava zones)
5. **Flexible lobby system** — custom team composition, friend invites, side-picking

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Hero selection, item builds, team composition, creative hook plays | Supporting |
| **Competence** (mastery, skill growth) | Skillshot accuracy improves over time, rank progression, outplaying opponents | Core |
| **Relatedness** (connection, belonging) | Playing with friends, shared moments, flexible team social dynamics | Core |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — Rank climbing, hero unlocks, mastery badges
- [ ] **Explorers** (discovery, understanding systems) — Minor: discovering hero synergies and map tricks
- [x] **Socializers** (relationships, cooperation, community) — Friends-first design, custom lobbies, asymmetric teams
- [x] **Killers/Competitors** (domination, PvP, leaderboards) — Primary audience. Skillshot mastery, outplaying opponents, climbing ranks

### Flow State Design

- **Onboarding curve**: Tutorial teaches basic hook aim on stationary targets, then moving targets, then a bot match. 5 minutes to competence.
- **Difficulty scaling**: Skill-based matchmaking for ranked. Casual lobbies with friends are self-balancing (flexible team sizes).
- **Feedback clarity**: Hit markers, damage numbers, kill feed, post-match stats (hook accuracy %, longest hook, saves).
- **Recovery from failure**: Instant respawn (3-5 seconds). Matches are short — a bad game is over in 5 minutes. Try again immediately.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Aim hook -> predict enemy movement -> launch -> hit or miss -> reposition
during cooldown -> dodge incoming hooks -> repeat. The core action is
**aiming a skillshot under time pressure** while simultaneously dodging
enemy skillshots. This is intrinsically satisfying because it combines
precision, prediction, and spatial awareness.

### Short-Term (5-8 minutes)
One match round. Earn gold from hooks/kills, buy items that modify your hook
(longer range, wider hitbox, faster travel, chain bounce). Level up abilities.
Team coordinates to hook enemies into map hazards or set up combos. Match
ends when one team reaches the kill target or time runs out.

### Session-Level (15-30 minutes)
Play 3-5 matches with friends. Try different heroes. Experiment with team
compositions (all play one side, or split up for 2v3). Earn progression
rewards: XP toward hero unlocks, cosmetic drops, seasonal challenge progress.

### Long-Term Progression
- Unlock all heroes (each with a unique hook type to master)
- Climb ranked ladder
- Complete seasonal challenges for exclusive cosmetics
- Master each hero (tracked stats: accuracy, win rate, highlight plays)

### Retention Hooks
- **Curiosity**: New heroes to try, new hook synergies to discover
- **Investment**: Ranked progress, cosmetic collection, hero mastery stats
- **Social**: Friends are playing, custom lobbies waiting, rivalries forming
- **Mastery**: "I can land that cross-map hook now" — visible skill growth

---

## Game Pillars

### Pillar 1: Skillshot is King
Every kill, every play, every clutch moment comes from landing or dodging a
hook. Mechanical skill is the primary differentiator between players.

*Design test*: "Should we add auto-aim assist?" — This pillar says NO.
Hooks must be manually aimed. Skill must be earned.

### Pillar 2: Play Your Way With Friends
Flexible lobbies, asymmetric teams, casual chaos. The game serves friend
groups first, matchmaking second.

*Design test*: "Should we force balanced 3v3 teams?" — This pillar says
let players choose their own sides, even lopsided ones.

### Pillar 3: Every Match is a Fresh Start
In-match RPG progression only. No permanent power advantages. A day-1
player and a veteran have the same power at the start of every match.

*Design test*: "Should we sell stat boosts?" — Absolutely not. Fair play
is non-negotiable.

### Pillar 4: Fast and Mobile-First
Matches are short (5-8 minutes). Controls are designed for touch. UI is
thumb-friendly. No complexity that doesn't serve the hook.

*Design test*: "Should we add a complex item shop with 50 items?" — This
pillar says keep it to 10-15 impactful choices max.

### Anti-Pillars (What This Game Is NOT)

- **NOT a story game**: No campaign, no lore quests. Pure PvP arena.
- **NOT pay-to-win**: Monetization through cosmetics only, never power.
- **NOT a MOBA**: No lanes, no minions, no towers. The hook IS the game.
- **NOT a matchmaking grind**: Friends-first design. Fun doesn't require ranked.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Dota 2 Pudge Wars | Hook-based PvP, divided arena, skillshot combat | Unique hero hooks (not everyone identical), RPG items, mobile-native | Validates the core mechanic is fun for thousands of hours |
| Brawl Stars | Mobile PvP, 3D stylized art, short matches, touch controls | Hook-only combat (not varied weapons), flexible teams, in-match RPG | Proves mobile PvP arena is a massive market (300M+ downloads) |
| Battlelands Royale | Simple mobile PvP, top-down combat, accessible | Deeper RPG layer, team-based, hook-focused mechanic | Shows simple mobile PvP can succeed with focused mechanics |

**Non-game inspirations**: The social energy of playing Dota custom games
with friends on voice chat — the laughing, the trash talk, the "oh my god
did you SEE that hook" moments. That feeling is the north star.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16-30 |
| **Gaming experience** | Mid-core (plays Brawl Stars, PUBG Mobile, Dota/LoL on PC) |
| **Time availability** | 15-30 minute sessions during commute, breaks, or evenings |
| **Platform preference** | Mobile primary, always has phone available |
| **Current games they play** | Brawl Stars, PUBG Mobile, Dota 2, Among Us |
| **What they're looking for** | Competitive skill-based PvP they can play with friends anywhere |
| **What would turn them away** | Pay-to-win, long match times, complex onboarding, solo-only experience |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.6 — free, open source, solid 3D + mobile support, built-in multiplayer, no licensing costs |
| **Key Technical Challenges** | Touch-based hook aiming UX, networked skillshot hit detection, mobile performance with 10 players + effects |
| **Art Style** | 3D stylized / low-poly (Brawl Stars aesthetic). Vibrant colors, readable silhouettes. |
| **Art Pipeline Complexity** | High for solo dev — consider low-poly models + stylized shaders to reduce per-asset cost. Asset store for early prototype. |
| **Audio Needs** | Moderate — satisfying hook SFX are critical (launch, travel, hit, miss), ambient arena music, UI feedback |
| **Networking** | Client-Server authoritative (prevents hook cheating). Relay servers or P2P with host authority for friend lobbies. |
| **Content Volume** | MVP: 1 arena map, 3 heroes, ~15 items. Full: 4-5 maps, 8-12 heroes, ~30 items |
| **Procedural Systems** | None initially. Map hazard placement could be semi-random in future. |

---

## Risks and Open Questions

### Design Risks
- Hook aiming on touchscreen may not feel precise enough — needs early prototype validation
- In-match RPG progression (items/levels) may slow down the action if shop UI is clunky
- Asymmetric teams (1v5) may be unfun for the solo player — needs balancing or handicap system

### Technical Risks
- Networked skillshot hit detection at mobile latency (100-200ms) — lag compensation is critical
- 10 concurrent players with 3D effects on low-end mobile devices — performance budgeting needed early
- Godot 4.6 mobile 3D networking at scale is relatively unproven — may hit edge cases

### Market Risks
- Competing with Brawl Stars (massive incumbent) in mobile PvP arena space
- Player acquisition for multiplayer-only game requires critical mass of users
- Friends-first design limits solo player appeal — could hurt retention

### Scope Risks
- 3D art pipeline as a solo developer is the biggest time sink
- Networking code for authoritative skillshots is complex for a first game
- Hero balancing with asymmetric hook types requires extensive playtesting

### Open Questions
- What's the optimal touch control scheme for hook aiming? (Prototype with 3 variants: joystick aim, drag-and-release, tap-target)
- Should asymmetric teams have a handicap system (bonus stats for outnumbered side)? (Playtest to find out)
- Can Godot 4.6 handle 10 players with 3D on low-end Android? (Performance prototype needed)
- What's the win condition? Kill target? Timer? Capture zones? (Prototype all three)

---

## MVP Definition

**Core hypothesis**: "Hook-based PvP combat on mobile touchscreen is fun and
satisfying enough to sustain repeated 5-minute matches with friends."

**Required for MVP**:
1. One arena map with hazards (pits, walls)
2. Three heroes with distinct hook types (pull, swing, boomerang)
3. Touch-based hook aiming that feels good
4. Local/LAN multiplayer (2-6 players) — skip server infrastructure for MVP
5. Basic in-match leveling (3 levels per match, each upgrades your hook)
6. Match win condition (first to X kills)

**Explicitly NOT in MVP** (defer to later):
- Online matchmaking and dedicated servers
- Full item shop (simplified stat upgrades only in MVP)
- Cosmetics and monetization
- Ranked mode
- More than 3 heroes
- Multiple maps
- Spectator mode

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 map, 3 heroes | Core hook combat, LAN multiplayer, basic leveling | 6-8 weeks |
| **Vertical Slice** | 1 map, 5 heroes, 15 items | Full item shop, online lobbies, friend invites | 3-4 months |
| **Alpha** | 3 maps, 8 heroes, 25 items | Ranked mode, cosmetics, seasonal framework | 5-7 months |
| **Full Vision** | 5 maps, 12 heroes, 30+ items | Full monetization, spectator, replay system | 9-12 months |

---

## Next Steps

- [ ] Get concept approval from creative-director
- [ ] Configure engine: `/setup-engine godot 4.6`
- [ ] Validate concept completeness: `/design-review design/gdd/game-concept.md`
- [ ] Decompose into systems: `/map-systems` — map dependencies, assign priorities, create systems index
- [ ] Author per-system GDDs: `/design-system` — guided, section-by-section
- [ ] Create first architecture decision: `/architecture-decision`
- [ ] Prototype core hook mechanic: `/prototype hook-aiming`
- [ ] Playtest the prototype: `/playtest-report`
- [ ] Plan first sprint: `/sprint-plan new`
