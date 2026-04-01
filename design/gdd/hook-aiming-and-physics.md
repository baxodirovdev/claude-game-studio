# Hook Aiming & Physics

> **Status**: Designed
> **Author**: user + game-designer + systems-designer + gameplay-programmer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King)

## Overview

The Hook Aiming & Physics system is THE core mechanic of Hook Wars. It handles
everything from the moment the player presses the hook button to the moment the
hooked enemy arrives at the player's feet: projectile creation, travel simulation,
collision detection against heroes and arena geometry, pull execution, and hook
return. Every kill in the game flows through this system. The player actively engages
with it every few seconds — aiming via joystick facing, firing with the hook button,
and watching the projectile fly. Without this system, there is no game — it IS the
game.

## Player Fantasy

**"I called that hook before you even moved."** The hook is a prediction weapon. The
player reads enemy movement, leads the target, commits by pressing the button (which
roots them in place), and watches the hook fly. The 0.5-1 second travel time is where
the magic lives — that's when the player holds their breath, waiting to see if their
prediction was right. A hit is euphoric. A miss is punishing (rooted, on cooldown,
exposed). The asymmetry between risk and reward is what makes the hook the most
satisfying mechanic in the game.

Landing a cross-gap hook — pulling an enemy from their safe side to yours — is the
ultimate highlight play. The victim ragdoll-slides across the chasm, lands at your
feet, and your team finishes them. That moment is why players keep playing.

This is Pillar 1 incarnate: **Skillshot is King**. No auto-aim, no homing, no
lock-on. The hook goes exactly where you're facing. Skill is the only variable.

## Detailed Design

### Core Rules

**Hook Projectile**

1. When the player taps the hook button (Input System: Ready state), a hook
   projectile spawns at the hero's position
2. The projectile travels in a straight line in the hero's `facing_angle` direction
3. Projectile speed is constant during flight (no acceleration, no arc, no gravity)
4. The projectile is a physics body with a small collision shape (sphere/capsule)
5. The hook has a maximum range — if it reaches max range without hitting anything,
   it stops and returns
6. Only one hook can be active per hero at a time (enforced by Input System state)

**Collision Detection**

1. The hook projectile checks collision every physics frame against:
   - Enemy hero hitboxes (success — hook hit)
   - Arena full walls (blocked — hook returns)
   - Arena boundary (blocked — hook returns)
2. The hook does NOT collide with:
   - Friendly heroes (passes through teammates)
   - Half walls (flies over them, per Arena GDD)
   - The central gap (flies across freely, per Arena GDD)
   - Other hook projectiles (hooks pass through each other)
3. First valid collision wins — the hook stops and processes the hit
4. Collision uses a raycast + area check hybrid: raycast for walls, area overlap
   for hero hitboxes (slightly forgiving hitbox to compensate for mobile precision)

**On Hit (Enemy Hero)**

1. Deal `hook_damage` to the target (calls Health & Damage `take_damage`)
2. If the target is invulnerable, the hook bounces off — no damage, no pull (per
   Health & Damage GDD)
3. If the target is alive after damage, begin the pull
4. If the target dies from the hook damage, no pull — target enters Death state
   at their current position. Hook returns.

**Pull Mechanic**

1. The pull moves the hooked enemy from their current position to the hooker's
   position along a straight line
2. Pull duration is fixed (tunable, ~0.5s default) — not dependent on distance
3. During the pull:
   - The victim cannot move, attack, or use abilities (Player Controller: Pulled state)
   - The victim passes through walls (per Player Controller GDD)
   - The victim CAN pass through/over hazards — if the pull path crosses a gap or
     pit, the victim falls in and dies (hooker gets kill credit)
   - The hooker remains rooted (still in Locked state until hook returns)
4. Pull completes when the victim reaches the hooker's position
5. After pull completes, the victim is placed at the hooker's position and regains
   control (Player Controller → Active)

**Hook Return**

1. After any outcome (hit + pull complete, hit + target died, miss/wall hit, max
   range), the hook returns to the hero
2. Return travel is instant (no return animation — hook just disappears)
3. On return, the Input System transitions from In Flight → Cooldown
4. The hero is unlocked (can move again) when the hook returns

**Hook Chain of Events (Complete)**

```
Button press → Projectile spawns → Hero locked (can't move)
  → Projectile travels in facing direction
  → OUTCOME A: Hit enemy → Deal damage → Pull (if alive) → Pull completes → Hook returns → Cooldown → Ready
  → OUTCOME B: Hit enemy → Deal damage → Target dies → Hook returns → Cooldown → Ready
  → OUTCOME C: Hit enemy (invulnerable) → Bounce off → Hook returns → Cooldown → Ready
  → OUTCOME D: Hit wall → Hook returns → Cooldown → Ready
  → OUTCOME E: Max range → Hook returns → Cooldown → Ready
```

### States and Transitions

**Hook Projectile States**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Spawning | Hook button pressed (Input: Firing) | Projectile instantiated (instant) | Create projectile at hero position with facing direction. Transition immediately. |
| Traveling | Projectile instantiated | Collision detected OR max range reached | Move projectile forward at `hook_speed` every physics frame. Check collisions. |
| Hit | Collision with enemy hero | Damage dealt + pull started OR target died | Apply damage. If target alive and not invulnerable, begin pull. If dead or invulnerable, return. |
| Pulling | Pull started | Victim reaches hooker position OR hooker dies OR victim hits lethal hazard | Move victim toward hooker via lerp. Check hazard collision on pull path. |
| Returning | Pull complete OR miss OR wall hit OR max range OR target died | Hook despawned | Despawn projectile. Signal Input System: hook returned. Unlock hero. |

**Per-Hero Hook Instance**

| State | Meaning |
|-------|---------|
| Ready | No hook active. Button enabled. Hero can move. |
| Active | Hook is in one of the projectile states above. Hero locked. Button disabled. |
| Cooldown | Hook returned. Waiting for cooldown. Hero can move. Button disabled. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Input System** | Input → Hook | Receives `hook_fire` signal with `facing_angle`. Sends `hook_state_changed(in_flight / returned)` back to Input for button/joystick state management. |
| **Player Controller** | Hook ↔ Player Controller | Reads hooker's `global_position` as projectile origin and pull destination. Writes to victim's position during pull (overrides Player Controller). Signals `pull_started` and `pull_completed` for state transitions. |
| **Arena/Map System** | Arena → Hook | Hook raycasts against arena collision layers. Full walls block (collision layer). Half walls don't block (separate layer). Gap has no collision for projectiles. |
| **Health & Damage** | Hook → Health | On hit, calls `take_damage(hook_damage, hooker, HOOK)`. Reads invulnerability state to determine if pull occurs. |
| **Hero System** | Hero → Hook | Provides per-hero hook stats: `hook_speed`, `hook_range`, `hook_damage`, `hook_cooldown`, `hook_hitbox_size`. Different heroes have different hook behaviors. |
| **Map Hazards** | Hook → Hazards (indirect) | During pull, if victim's interpolated position enters a hazard zone, hazard triggers. Hook doesn't call hazards directly — the hazard area detection handles it. |
| **Camera System** | Indirect | Camera follows the hero (Player Controller), which is locked during hook. No direct hook-camera interface. |
| **VFX/Feedback System** | Hook → VFX | Emits signals for visual/audio events: `hook_launched`, `hook_hit(target)`, `hook_missed`, `hook_pull_started`, `hook_pull_completed`. VFX system renders chain, particles, screen shake. |
| **Score/Kill Tracking** | Indirect via Health | Hook kills flow through Health & Damage → Score. No direct connection. |
| **Networking Layer** | Hook ↔ Network | Hook fire event is client-predicted, server-validated. Hit detection is server-authoritative. Pull is server-driven, replicated to clients. Lag compensation on hit detection. |

## Formulas

### Hook Travel

```
projectile_position += hook_direction * hook_speed * delta
distance_traveled += hook_speed * delta
is_max_range = distance_traveled >= hook_range
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| hook_direction | Vector3 | unit vector | from `facing_angle` at fire time | Direction the hook travels (fixed at fire, doesn't change) |
| hook_speed | float | 20-40 units/s | Hero data file | How fast the projectile moves |
| hook_range | float | 15-30 units | Hero data file | Maximum distance before auto-return |
| distance_traveled | float | 0 to hook_range | tracked | Running total of distance |
| delta | float | physics frame delta | Engine | Physics step time |

### Time to Target

```
time_to_target = distance_to_target / hook_speed
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| distance_to_target | float | 0 to hook_range | calculated | Distance between hooker and target at fire time |
| time_to_target | float | 0-1.5 s | calculated | How long the hook takes to reach the target |

**Design intent**: Cross-gap hooks (distance ~6-12 units at hook_speed 30) take
0.2-0.4s. This is the prediction window — fast enough to feel responsive, slow
enough that the target can dodge if they react.

### Hook Hitbox Scaling

```
effective_hitbox = base_hero_hitbox + hook_hitbox_bonus
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base_hero_hitbox | float | 0.5-0.8 units radius | Hero data | Standard hero collision radius |
| hook_hitbox_bonus | float | 0.1-0.3 units | tuning knob | Extra radius for hook collision (forgiveness) |
| effective_hitbox | float | 0.6-1.1 units | calculated | Actual hook-vs-hero collision radius |

**Design intent**: Hook hitbox is slightly larger than the visual hero model. This
compensates for mobile touch imprecision without feeling like auto-aim. The hook
should feel "fair" — hits that look like they should hit DO hit, and near-misses
that look like they should miss DO miss.

### Pull Duration

```
pull_progress += (1.0 / pull_duration) * delta
victim_position = lerp(pull_start, hooker_position, clamp(pull_progress, 0, 1))
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| pull_duration | float | 0.3-1.0 s | Hero data file | Fixed time for pull to complete (not distance-dependent) |
| pull_start | Vector3 | arena bounds | captured at hit | Victim's position when hooked |
| hooker_position | Vector3 | arena bounds | Player Controller | Where the victim is pulled TO |
| pull_progress | float | 0.0-1.0 | calculated | Lerp parameter |

### Hook Damage

```
hook_damage = hero_base_hook_damage
```

Referenced from Health & Damage GDD. In MVP, hook damage is flat per hero. Items
(Vertical Slice) may add modifiers.

### Cooldown

```
cooldown_remaining = hook_cooldown - (current_time - hook_return_time)
is_ready = cooldown_remaining <= 0
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| hook_cooldown | float | 1.0-4.0 s | Hero data file | Per-hero cooldown duration |
| hook_return_time | float | timestamp | tracked | When the hook returned |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Hook hits two enemies overlapping at the same position | First enemy in collision check order is hit. Second is ignored. One hook = one target. | Prevents multi-hit exploits. Clean single-target mechanic. |
| Hook hits an enemy at the exact frame they die from another source | Hook passes through (target is already Dead). Hook continues traveling. | Dead entities have no hitbox. Clean state — dead is dead. |
| Hooker dies while hook is in flight (before hit) | Hook despawns immediately. No hit, no damage, no pull. | Dead players can't hook. Killing the hooker is valid counterplay. |
| Hooker dies while pulling a victim | Pull is cancelled. Victim stops at their current mid-pull position. Victim regains control. | Per Player Controller GDD. Dead hookers release their victims. |
| Hook is in flight when match enters Ended state | Hook despawns immediately. No hit processing. | Match is over. No post-match interactions. |
| Victim is pulled across the gap and the path crosses a pit on the hooker's side | Victim falls into the pit and dies. Hooker gets kill credit. | Pull path hazard detection is intentional gameplay — pulling enemies into your hazards is a skill play. |
| Victim is pulled but hooker is standing on spikes | Victim arrives at hooker's position (on spikes). Victim takes spike damage on arrival. | Pull destination is the hooker's exact position. If the hooker is on spikes, that's where you land. |
| Hook fired at exact max range to an enemy standing still | Hook reaches enemy at max range and hits. The edge is inclusive (<=, not <). | Max range is the maximum distance the hook CAN hit, not the distance it falls short at. |
| Two hooks from different players hit the same target on the same frame | First hook processed wins (deterministic order). Second hook passes through (target in Pulled state). | Per Player Controller GDD: first hook wins, no tug-of-war. |
| Hook direction is set but hero is at the arena edge facing outward | Hook fires, hits the arena boundary wall immediately, returns. Wasted hook. | Walls block hooks. Firing into a wall is a player mistake. No safety net. |
| Hero fires hook while standing at the gap edge | Hook flies across the gap normally. If it misses, it continues until max range or wall. | Gap doesn't block projectiles. Firing from the edge is a valid aggressive position. |
| Hook projectile is exactly at max range and hits a wall on the same frame | Wall hit takes priority over max range. Hook returns as a wall-blocked miss. | Collision checks happen before range checks. |
| Invulnerable target is hit | Hook visually bounces off. No damage, no pull. Hook returns. | Per Health & Damage GDD. Invulnerability is full immunity. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Input System** | Upstream | Hard — hook fires on input signal | Receives `hook_fire(facing_angle)`. Sends `hook_state_changed`. |
| **Player Controller** | Upstream + Downstream | Hard — needs position for origin; writes position during pull | Reads `global_position`. Writes victim position during pull. |
| **Arena/Map System** | Upstream | Hard — needs collision geometry for wall detection | Raycasts against arena collision layers (full walls block, half walls don't). |
| **Health & Damage** | Downstream | Hard — hook is the primary damage source | Calls `take_damage(hook_damage, hooker, HOOK)`. Reads invulnerability. |
| **Hero System** | Upstream | Hard — needs per-hero hook stats | Reads `hook_speed`, `hook_range`, `hook_damage`, `hook_cooldown`, `hook_hitbox_size` from Hero data. |
| **Map Hazards** | Indirect | Soft — pull path triggers hazards but Hook doesn't call Hazards directly | Victim's position during pull enters hazard collision zones. Hazard system detects overlap. |
| **VFX/Feedback System** | Downstream | Soft — hook works without VFX but feels terrible | Emits event signals for chain rendering, particles, screen shake, sound. |
| **Networking Layer** | Bidirectional | Hard (in multiplayer) | Client predicts fire, server validates hit, server drives pull. |

**Cross-references verified**:
- Input System: `hook_fire` signal with `facing_angle` ✓
- Input System: `hook_state_changed(in_flight / returned)` ✓
- Player Controller: Pulled state, pull cancelled if hooker dies ✓
- Player Controller: pulled hero passes through walls ✓
- Arena/Map: full walls block, half walls don't, gap doesn't block ✓
- Health & Damage: `take_damage(amount, source, HOOK)`, invulnerability bounces ✓

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `hook_speed` (per hero) | 30 units/s | 20-40 units/s | Faster hook, less dodge time, easier to hit, less prediction needed | Slower hook, more dodge time, more prediction required, higher skill ceiling |
| `hook_range` (per hero) | 20 units | 15-30 units | Longer reach, can hook from safer positions, cross-gap hooks easier | Shorter reach, must play aggressively to hook, less safe |
| `hook_damage` (per hero) | 30 HP | 20-50 HP | Fewer hooks to kill, more punishing, faster kills | More hooks to kill, more forgiving, longer fights |
| `hook_cooldown` (per hero) | 2.0 s | 1.0-4.0 s | More downtime between hooks, each hook matters more, more movement time | Spam hooks faster, less consequence per miss, more chaotic |
| `hook_hitbox_bonus` | 0.2 units | 0.0-0.4 units | More forgiving hits (feels generous), lower skill floor | Stricter hits (pixel-perfect), higher skill floor, frustrating on mobile |
| `pull_duration` | 0.5 s | 0.3-1.0 s | Slower pull — more dramatic, more time for teammates to react | Faster pull — more snappy, less counterplay window |

**Knob interactions**:
- `hook_speed` and `hook_range` together determine flight time at max range (`hook_range / hook_speed`). Target: 0.5-1.0s max flight time.
- `hook_speed` and `move_speed` (Player Controller) determine dodgeability. If `move_speed / hook_speed > 0.5`, hooks are very dodgeable. If < 0.3, hooks are nearly unavoidable at close range.
- `hook_damage` and `max_health` (Health GDD) determine hits-to-kill. Target: 3-4 hooks.
- `hook_cooldown` and `pull_duration` together determine total lockout time per hook. Hooker is locked for: flight time + pull duration + cooldown. Target: 3-5s total cycle.
- `hook_hitbox_bonus` is the most sensitive tuning knob. Too high = hooks feel cheap ("that didn't hit me!"). Too low = hooks feel broken ("that clearly hit!"). Must be playtested extensively.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Hook launched | Chain/rope extends from hero in hook direction. Muzzle flash at hero. | Metallic chain launch sound (whoosh + clink) | Critical |
| Hook traveling | Chain stretches from hero to projectile tip, links visible. Trail particles. | Subtle whoosh/whistle during flight | Critical |
| Hook hit (enemy) | Impact flash on target. Chain goes taut. Brief slow-mo (100ms) on long-range hits. | Meaty impact thud + chain snap tight. Kill confirm chime if lethal. | Critical |
| Hook miss (max range) | Chain extends to max, hook tip sparks, retracts | Chain rattle + disappointed whiff sound | High |
| Hook blocked (wall) | Spark particles on wall impact point. Chain retracts. | Metallic clang on wall | High |
| Hook bounce (invulnerable) | Shield flash on target. Hook deflects upward briefly. | Shield bounce sound (bright, metallic) | Medium |
| Pull in progress | Victim slides toward hooker with dust trail. Chain reeling in animation. | Reeling/winch sound + victim slide sound | Critical |
| Pull completes | Victim arrives with impact dust. Chain disappears. | Thud on arrival | High |
| Pull across gap | Camera may shake slightly. Dramatic visual — victim flies across the chasm. | Wind whoosh during gap crossing + landing thud | Critical |
| Hook on cooldown (button pressed) | Button flashes red (Input System VFX) | Dull blocked thud (Input System audio) | Medium |

**Art direction notes**:
- The hook chain must be the most visually readable element on screen. High contrast,
  bright color per hero, thick enough to see at isometric zoom on mobile.
- Long-range hit slow-mo (100ms) is a key "highlight reel" moment. Only triggers on
  hooks that travel >70% of max range. Should feel like a reward for skilled shots.
- Each hero's hook should look distinct (chain, rope, beam, blade) — this is a Hero
  System concern but affects visual rendering here.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Hook chain visual | World-space, from hero to projectile/target | Every frame during flight/pull | While hook is active |
| Hook range indicator (optional) | Faint circle around hero showing max range | Static while aiming | Consider for tutorial only — may clutter in real gameplay |
| Hook hit marker | On target, center of screen (small crosshair flash) | On hit | Brief flash on successful hit |
| Kill confirmation | Center screen (skull icon or "HOOKED!" text) | On kill via hook | 1s display |

**Notes**: The hook is primarily a world-space visual (the chain), not a UI element.
HUD involvement is minimal — just hit markers and kill confirmations.

## Acceptance Criteria

- [ ] Hook projectile spawns at hero position in facing direction on button press
- [ ] Projectile travels in a straight line at constant speed
- [ ] Hook collides with enemy heroes (deals damage, initiates pull if alive)
- [ ] Hook collides with full walls (blocks and returns)
- [ ] Hook flies over half walls without collision
- [ ] Hook flies across the central gap without collision
- [ ] Hook passes through friendly heroes without collision
- [ ] Hook passes through other hook projectiles
- [ ] Hook returns after reaching max range with no collision
- [ ] Only one hook active per hero at a time
- [ ] Pull moves victim from their position to hooker's position
- [ ] Pull duration is fixed (not distance-dependent)
- [ ] Victim passes through walls during pull
- [ ] Victim dies if pull path crosses gap or pit (hooker gets kill credit)
- [ ] Pull cancelled if hooker dies mid-pull
- [ ] First hook wins when two hooks hit the same target simultaneously
- [ ] Hook bounces off invulnerable targets (no damage, no pull)
- [ ] Hook despawns if hooker dies during flight
- [ ] Hook despawns on match end
- [ ] Cooldown begins after hook returns (not after fire)
- [ ] Per-hero hook stats loaded from data files (speed, range, damage, cooldown)
- [ ] Hook hitbox is slightly larger than visual model (tunable forgiveness)
- [ ] Slow-mo triggers on long-range hits (>70% max range)
- [ ] Chain visual renders correctly from hero to projectile during flight
- [ ] Chain visual renders correctly from hero to victim during pull
- [ ] All hook events emit signals for VFX/audio system
- [ ] Performance: hook physics update within 0.5ms per active hook per frame
- [ ] Hit detection is deterministic (same inputs = same result)

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should hooks have a slight arc (parabolic trajectory) or always be perfectly straight? | game-designer | Before prototype | Start with straight. Arc adds visual flair but complicates aiming on mobile. Prototype both. |
| Should the chain be breakable? (e.g., a teammate hooks the chain to cut it mid-pull) | game-designer | Before Vertical Slice | Not in MVP. Would add counterplay depth but is mechanically complex. Revisit for hero abilities. |
| Should there be a "hook clash" when two hooks collide mid-air? | game-designer | Before Vertical Slice | Cool moment but rare and complex. Hooks pass through each other for MVP. Revisit. |
| How does lag compensation work for hit detection? (Client sees hit, server disagrees) | network-programmer | Before Networking GDD | Critical for multiplayer. Server-authoritative with client-side prediction and rollback. Detail in Networking GDD. |
| Should hook damage scale with distance? (Longer hooks deal more damage as a skill reward) | systems-designer | Before prototype | Interesting design. Rewards cross-gap hooks. Risk: makes close-range hooks feel weak. Prototype flat damage first, test scaling variant. |
| Should there be a visual/audio telegraph before the hook fires? (Brief windup animation) | game-designer + ux-designer | Before prototype | Pro: gives dodge window, raises skill ceiling. Con: adds input delay, feels less responsive on mobile. Test both. |
