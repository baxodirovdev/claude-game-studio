# Camera System

> **Status**: Designed
> **Author**: user + game-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King), Pillar 4 (Fast and Mobile-First)

## Overview

The Camera System provides the isometric viewpoint through which the player sees the
arena. It follows the player's hero, shows enough of the arena to make hook aiming
meaningful, and ensures critical gameplay information (enemies near the gap, hazards,
teammates) is visible without manual camera control. The player never directly
interacts with the camera — it is fully automatic. Without this system, the player
can't see the arena, can't judge distances for hooks, and can't read the spatial
puzzle that makes the game work.

## Player Fantasy

**"I can see everything I need to."** The camera is invisible infrastructure — the
player never thinks about it. They look at the arena, see enemies on the other side
of the gap, judge the distance, and fire a hook. The camera always shows enough to
make informed decisions but never so much that individual heroes become tiny and
unreadable on a mobile screen.

This serves Pillar 1 (Skillshot is King): the camera must show enough range that
players can see potential hook targets and read their movement patterns. If the
camera is too tight, hooks feel like blind guesses. If it's too wide, heroes are
too small to read on mobile. The sweet spot is seeing your half of the arena plus
the gap plus enough of the enemy side to spot targets. It also serves Pillar 4
(Mobile-First): the zoom level must make heroes readable on a 5" phone screen.

## Detailed Design

### Core Rules

**Isometric Projection**

1. The camera uses an orthographic projection at a fixed isometric angle
2. Camera angle: 45° pitch (looking down), 45° yaw rotation (classic isometric)
3. Orthographic projection — no perspective distortion. Objects at all distances
   render at the same scale. This is critical for hook distance readability.
4. Camera rotation is fixed — the player cannot rotate the camera

**Following Behavior**

1. The camera follows the player's hero position every frame
2. Camera target = hero's `global_position` (read from Player Controller)
3. The camera is offset from the hero toward the center of the arena (toward the
   gap). This biases the view to show more of the enemy side and the gap — where
   the action is — rather than the safe spawn area behind the player.
4. Offset direction: toward the gap center, offset distance is tunable
5. Camera position uses smooth following (lerp) with a fast follow speed to prevent
   jarring snaps but maintain responsiveness

**Zoom**

1. Camera zoom is fixed during gameplay — no pinch-to-zoom
2. Zoom level is set per-map based on arena dimensions, tuned so that:
   - The player's hero is clearly visible and readable
   - The central gap is visible
   - At least 60-70% of the enemy's side near the gap is visible
   - Heroes are large enough to distinguish on a 5" mobile screen
3. Zoom level may differ between maps (larger maps = slightly wider zoom)

**Clamping**

1. The camera is clamped to arena bounds — it cannot show beyond the arena edges
2. Clamping uses the arena's `get_arena_bounds()` (from Arena GDD)
3. When the hero is near an arena edge, the camera stops scrolling in that direction
   rather than showing empty space beyond the boundary
4. Clamping is applied after following + offset calculation

**During Pull (Being Hooked)**

1. When the hero is being pulled by an enemy hook, the camera follows the hero's
   pull trajectory smoothly (same lerp behavior)
2. No special camera behavior during pulls — the standard follow handles it
3. The pull is fast enough that the camera transition feels dramatic without being
   disorienting

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Cinematic | Match loading / pre-match | Match countdown begins | Fly-in sweep showing the full arena from above, then zooms to player's spawn |
| Active | Match countdown begins | Match ends OR hero dies | Follows hero with offset toward gap, clamped to arena bounds |
| Death | Hero dies | Respawn completes | Holds position at death location for 1s, then smoothly pans to the killer (if visible) or stays put until respawn |
| Respawn | Respawn timer completes | Hero regains control | Snaps to new spawn position (fast lerp, ~0.3s transition) |
| Frozen | Match ends | Scene unloads | Camera holds position. May slowly zoom out to show more of the arena for post-match display. |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Controller** | Player Controller → Camera | Reads hero's `global_position` every frame as the follow target. |
| **Arena/Map System** | Arena → Camera | Reads `get_arena_bounds()` for clamping. Reads arena dimensions at load time to set zoom level. |
| **Match State Manager** | Match State → Camera | Receives `match_started`, `match_ended` signals to transition between Cinematic/Active/Frozen states. |
| **Health & Damage** | Health → Camera | Receives `hero_died` signal to transition to Death camera behavior. |
| **Respawn System** | Respawn → Camera | Receives `hero_respawned` signal to snap to new spawn position. |
| **Hook Aiming & Physics** | Indirect | No direct interface. Camera follows the hero, which is moved by Hook System during pulls. Camera follows naturally. |

## Formulas

### Camera Follow Position

```
target_position = hero_position + gap_offset_direction * gap_offset_distance
clamped_target = clamp_to_arena_bounds(target_position, arena_bounds, viewport_half_size)
camera_position = lerp(camera_position, clamped_target, follow_speed * delta)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| hero_position | Vector3 | arena bounds | Player Controller | Hero's current world position |
| gap_offset_direction | Vector3 | unit vector | calculated at load | Direction from hero's side toward the gap center |
| gap_offset_distance | float | 3-10 units | tuning knob | How far ahead the camera looks toward the gap |
| arena_bounds | AABB | per map | Arena System | Min/max corners of the playable area |
| viewport_half_size | Vector2 | device-dependent | calculated | Half the viewport in world units (for clamping) |
| follow_speed | float | 5-15 | tuning knob | Lerp speed (higher = snappier, lower = smoother) |
| delta | float | 0.016-0.033 s | Engine | Frame delta time |

### Orthographic Zoom Sizing

```
ortho_size = arena_half_depth * zoom_coverage_ratio
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| arena_half_depth | float | 22-30 units | Arena data | Depth of one team's half |
| zoom_coverage_ratio | float | 0.8-1.2 | tuning knob | What fraction of the half to show. 1.0 = see your entire half. |
| ortho_size | float | 18-36 | calculated | Godot camera `size` parameter |

**Design intent**: At `zoom_coverage_ratio = 1.0`, the player sees their full half
plus the gap. Increasing shows more of the enemy side. Decreasing zooms in closer
to the hero.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Hero is at the far spawn edge (camera would show beyond arena boundary) | Camera clamps — stops scrolling, shows the arena edge. No empty void visible. | Clean presentation. Players should never see "outside" the arena. |
| Hero is being pulled rapidly across the gap | Camera lerp follows smoothly. May lag slightly behind during fast pulls, catching up after pull completes. | Slight camera lag during pulls creates a dramatic "whoosh" feeling without disorienting. |
| Hero dies at the exact edge of the arena | Death camera holds at death position, clamped to bounds. Does not scroll beyond arena. | Same clamping rules always apply. |
| Two heroes on same team are far apart (splitscreen not supported) | Each player has their own camera following their own hero. No splitscreen. In spectator mode (future), camera follows the spectated player. | Mobile screen is too small for splitscreen. Each client renders their own view. |
| Match starts with Cinematic sweep but player taps impatiently | Cinematic cannot be skipped during countdown (countdown is fixed duration). Camera completes sweep and lands on player's hero by countdown end. | Countdown serves as load buffer + cinematic time. Consistent experience. |
| Hero respawns while camera is in Death state (showing killer) | Camera immediately transitions to Respawn state — fast lerp to spawn position. | Respawn takes priority. Player needs to see where they are, not where they died. |
| Device has a very wide aspect ratio (21:9 ultrawide phone) | Orthographic size stays the same (vertical). Wider screen shows more horizontal arena. This is a slight advantage but acceptable. | Orthographic projection scales naturally. Wide screens see more sides, not more depth. Minimal gameplay impact. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Player Controller** | Upstream (depends on) | Hard — camera needs a target | Reads `global_position` every frame |
| **Arena/Map System** | Upstream (depends on) | Hard — needs bounds for clamping and zoom | Reads `get_arena_bounds()` and arena dimensions at load |
| **Match State Manager** | Upstream | Hard — camera states tied to match states | Receives match state change signals |
| **Health & Damage** | Upstream | Soft — death camera is nice-to-have | Receives `hero_died` signal for death cam behavior |
| **Respawn System** | Upstream | Soft — snap-to-spawn is nice-to-have | Receives `hero_respawned` signal |

**No downstream dependents.** The camera is a leaf system — nothing depends on it.
It reads from others but no system reads from the camera.

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `camera_angle_pitch` | 45° | 30-60° | More top-down view, better spatial overview, heroes more foreshortened | More side-on view, heroes taller on screen, less spatial overview |
| `camera_angle_yaw` | 45° | 0-90° | Rotates the isometric angle. 0° = side-on, 45° = classic iso, 90° = other side-on | — |
| `ortho_size` | 25 | 18-36 | Wider view, more arena visible, heroes smaller on screen | Tighter view, heroes larger, less arena visible |
| `gap_offset_distance` | 5 units | 0-10 units | Camera looks further ahead toward the gap, showing more enemy territory | Camera centered on hero, balanced view of both directions |
| `follow_speed` | 8.0 | 3-15 | Snappier follow, camera sticks tightly to hero | Smoother/lazier follow, slight drift. Below 5 feels sluggish on mobile. |
| `death_hold_duration` | 1.0 s | 0.5-2.0 s | Longer pause on death position before panning | Faster transition away from death |
| `respawn_snap_speed` | 15.0 | 10-20 | Near-instant snap to spawn | Slower pan to spawn position |
| `zoom_coverage_ratio` | 1.0 | 0.8-1.2 | Shows more of the arena (heroes smaller) | Shows less (heroes bigger, more zoomed in) |

**Knob interactions**:
- `ortho_size` and device screen size interact — test on smallest target device (5" phone)
  to ensure heroes are still readable at the chosen zoom
- `gap_offset_distance` and `ortho_size` interact — large offset with tight zoom may
  push the hero to the screen edge
- `follow_speed` and `pull_speed` (Player Controller) interact — if pull is fast and
  follow is slow, camera lags dramatically during pulls

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Cinematic fly-in | Smooth camera sweep from above, zooming to player spawn | Arena theme music fade-in during sweep | Medium |
| Camera shake (hook hit) | Brief screen shake when hero's hook hits an enemy (owned by VFX System, applied to camera) | None from camera directly | High |
| Death camera | Slow zoom or hold on death position, then pan | Death sound from Health/Audio system | Low |
| Respawn snap | Quick smooth transition to new position | None | Low |

**Notes**: The camera itself has minimal VFX. Screen shake is applied by the VFX/Feedback
System directly to the camera node. The camera provides the node; VFX owns the shake.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Off-screen enemy indicator | Arrows at screen edges pointing toward enemies not currently visible | Every 0.5s | When enemies are beyond the camera viewport |
| Off-screen teammate indicator | Smaller arrows at screen edges (different color from enemy) | Every 0.5s | When teammates are beyond the camera viewport |

**Notes**: These indicators are owned by HUD, not Camera. Camera provides the viewport
bounds; HUD checks which heroes are outside those bounds and renders indicators.

## Acceptance Criteria

- [ ] Camera renders the arena from a fixed isometric angle (45° pitch, 45° yaw)
- [ ] Camera uses orthographic projection (no perspective distortion)
- [ ] Camera follows the player's hero smoothly every frame
- [ ] Camera is offset toward the gap (shows more enemy territory than spawn area)
- [ ] Camera clamps to arena bounds — no void/empty space visible beyond arena edges
- [ ] Camera cannot be rotated, zoomed, or panned by the player
- [ ] Zoom level makes heroes clearly readable on a 5" mobile screen
- [ ] Cinematic sweep plays during pre-match, transitions to follow by countdown
- [ ] Death camera holds at death position, then transitions on respawn
- [ ] Camera follows hero smoothly during hook pull without disorienting snaps
- [ ] Camera behavior is frame-rate independent (lerp uses delta time)
- [ ] Performance: Camera update completes within 0.1ms per frame
- [ ] All camera parameters loaded from config — no hardcoded values

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should the camera zoom out slightly when the hero fires a hook (to show where the hook is going)? | game-designer + ux-designer | Before prototype | Could help readability of cross-gap hooks. Test without first — the offset toward the gap may be enough. |
| Should the camera show a brief wide shot when a teammate is hooked (awareness cue)? | game-designer | Before Vertical Slice | Could improve team awareness. Risk: disorienting mid-combat. Defer to playtest. |
| Exact isometric angle (45° is placeholder) — what reads best for this specific arena layout? | technical-artist + game-designer | Before prototype | Prototype with 45° and test 30°/60° variants. Depends on wall height and hazard readability. |
| Should spectator mode (future) have free camera control? | game-designer | Before Full Vision | Not in MVP. Defer entirely. |
