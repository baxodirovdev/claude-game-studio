# Input System

> **Status**: Designed
> **Author**: user + game-designer
> **Last Updated**: 2026-03-28
> **Implements Pillar**: Pillar 1 (Skillshot is King), Pillar 4 (Fast and Mobile-First)

## Overview

The Input System is the foundational abstraction layer that translates mobile touch
input into game actions: movement, hook aiming, hook firing, ability activation, and
UI interaction. The player never "sees" this system — they experience it as responsive,
precise controls that feel natural under their thumbs. It exists to decouple raw touch
events from gameplay logic, allowing the hook aiming system and player controller to
read clean, processed input without caring whether the player is using a virtual
joystick, drag-and-release, or tap-to-target. Without this layer, every gameplay
system would implement its own touch handling, creating inconsistent feel and making
control scheme changes impossible to test.

## Player Fantasy

**"Point and rip."** The player's left thumb owns the joystick — it moves the
hero and points them where to look. The right thumb owns the hook button — one
tap launches the hook in whatever direction the joystick is facing. There is no
separate aiming step. Movement IS aiming. This creates a constant tension: to
aim your hook at an enemy, you have to walk toward them (or at least face them),
which means putting yourself in range of their hook too. The fantasy is a
gunslinger's duel — you're always positioning, always exposed, always one
thumb-press away from a kill or a death.

This serves Pillar 1 (Skillshot is King): skill lives in *positioning* and
*timing*, not in a complex aim UI. The best players aren't the ones with
the steadiest aim — they're the ones who read movement, face the right angle
at the right moment, and press the button. It also serves Pillar 4 (Mobile-First):
two thumbs, two actions, zero learning curve.

## Detailed Design

### Core Rules

**Controls Layout**

1. The screen is divided into two zones: left half (movement) and right half (action)
2. A fixed virtual joystick sits in the bottom-left corner of the screen
3. A single hook button sits in the bottom-right corner of the screen
4. No other gameplay buttons exist during a match (shop/menu accessed via separate UI overlay)

**Movement & Facing**

1. Dragging the joystick moves the hero in that direction at their movement speed
2. The hero's facing direction always matches the joystick direction — there is no independent look/move
3. Releasing the joystick stops movement; the hero retains their last facing direction
4. Facing direction is continuous (360°), not snapped to cardinal/8-directional
5. Joystick input is normalized — pushing harder doesn't move faster (full speed or stopped)

**Hook Firing**

1. Tapping the hook button fires the hook in the hero's current facing direction
2. If the joystick is neutral (released), the hook fires in the hero's last facing direction
3. While the hook is in flight, the player **cannot move** — the hero is rooted until the hook returns
4. The hook button is disabled (grayed out) while the hook is in flight and during cooldown
5. After the hook returns, there is a brief cooldown before it can be fired again (tunable per hero)

**Input Priority**

1. UI interactions (shop, pause, menu) take priority over gameplay input — if a UI panel is open, touch events go to UI, not to the joystick/hook button
2. The joystick and hook button can be used simultaneously (left thumb + right thumb)
3. Multi-touch beyond the two primary zones is ignored (prevents ghost inputs)

### States and Transitions

The Input System tracks two independent state machines: joystick state and hook
button state.

**Joystick States**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Idle | Default / thumb lifted | Thumb touches joystick zone | No movement input; facing direction holds at last value |
| Active | Thumb touches joystick zone | Thumb lifted OR hook in flight | Emits movement vector + facing direction every frame |
| Locked | Hook enters flight state | Hook returns to hero | Joystick visually dimmed; touch input on joystick is ignored |

**Hook Button States**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Ready | Cooldown expires | Button tapped | Button fully lit; accepts tap input |
| Firing | Button tapped while Ready | Hook projectile spawned (instant) | Sends fire event with current facing direction; transitions immediately |
| In Flight | Hook projectile spawned | Hook returns (hit, miss, or max range) | Button grayed out; taps ignored |
| Cooldown | Hook returns | Cooldown timer expires | Button grayed out with cooldown indicator; taps ignored |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Player Controller** | Input → Player Controller | Emits `movement_vector: Vector2` (normalized direction) and `facing_angle: float` (radians, 0-2π) every frame. Player Controller reads these to move and rotate the hero. |
| **Hook Aiming & Physics** | Input → Hook System | Emits `hook_fire` signal with `facing_angle: float` when hook button is tapped in Ready state. Hook system owns everything after firing — projectile creation, travel, collision. |
| **Hook Aiming & Physics** | Hook System → Input | Receives `hook_state_changed` signal (in_flight / returned). Input uses this to lock/unlock the joystick and cycle the hook button state. |
| **HUD** | Input → HUD | HUD reads hook button state to render the cooldown indicator. Input does not push to HUD — HUD polls the button state. |
| **Match State Manager** | Match State → Input | Receives `match_state_changed` signal. Input disables all gameplay controls during countdown, match end, and pause states. |
| **UI System** | UI → Input | When a UI panel (shop, pause menu) is active, Input yields all touch events to UI. Input checks a global `ui_has_focus` flag before processing gameplay touches. |

## Formulas

### Joystick Vector Normalization

```
raw_offset = touch_position - joystick_center
clamped_offset = raw_offset.clamped(joystick_radius)
movement_vector = clamped_offset.normalized()  # always unit length or zero
facing_angle = atan2(clamped_offset.y, clamped_offset.x)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| touch_position | Vector2 | screen coords | OS touch event | Where the thumb currently is |
| joystick_center | Vector2 | screen coords | fixed layout | Center of the joystick widget |
| joystick_radius | float | 80-120 px | tuning knob | Max distance thumb can drag from center |
| raw_offset | Vector2 | unlimited | calculated | Raw distance from center |
| clamped_offset | Vector2 | 0 to joystick_radius | calculated | Offset capped to joystick bounds |
| movement_vector | Vector2 | (0,0) or unit length | calculated | Direction for Player Controller |
| facing_angle | float | -π to π | calculated | Angle for hook firing direction |

**Dead zone**: If `clamped_offset.length() < dead_zone_radius`, output
`movement_vector = Vector2.ZERO` and do not update `facing_angle`. This prevents
drift from imprecise thumb placement.

### Hook Cooldown Timer

```
remaining_cooldown = max(0, cooldown_duration - (current_time - hook_return_time))
cooldown_progress = 1.0 - (remaining_cooldown / cooldown_duration)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| cooldown_duration | float | 0.5-3.0 s | Hero data file | Per-hero cooldown after hook returns |
| hook_return_time | float | timestamp | Hook System signal | When the hook returned |
| cooldown_progress | float | 0.0-1.0 | calculated | For HUD cooldown fill indicator |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player taps hook button with joystick in dead zone (no direction set yet, game just started) | Fire hook in the hero's default facing direction (forward/right, 0°) | Must always have a valid facing angle — never fire into void |
| Player lifts thumb from joystick mid-hook-flight | Hero remains rooted (already locked). When hook returns, joystick unlocks in Idle state with last facing direction preserved | Lifting thumb during flight is natural — don't punish it |
| Player taps hook button rapidly during cooldown | All taps ignored. No input buffering — the button is visually disabled | Buffered inputs would fire hooks the player didn't intend. What you see is what you get |
| Player touches both halves of the screen simultaneously at match start | Joystick activates on left touch, hook button activates on right touch. Both process independently | Multi-touch is the normal play state — both thumbs active |
| Player drags thumb from joystick zone into hook button zone without lifting | Joystick keeps tracking the original touch (by touch ID). The drag does not trigger the hook button | Prevents accidental hook fires from sloppy thumb movement |
| Player's thumb drifts outside joystick radius | Input is clamped to max radius. Direction stays valid, magnitude stays at 1.0 | Players overshoot under stress — clamp, don't break |
| UI panel opens while joystick is held | Joystick immediately enters Idle state (releases). Movement stops | UI focus must instantly override gameplay input — no "stuck walking" behind menus |
| Match ends while hook is in flight | Hook is force-returned. Input transitions to fully disabled state | Match State Manager owns the end — input obeys immediately |
| Device orientation changes mid-match | Not supported. Lock to landscape orientation at match start | Rotation would destroy joystick position and muscle memory |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Player Controller** | Downstream (depends on Input) | Hard — cannot move without input | Reads `movement_vector` and `facing_angle` every frame |
| **Hook Aiming & Physics** | Downstream (depends on Input) | Hard — cannot fire without input | Receives `hook_fire` signal with `facing_angle` |
| **Hook Aiming & Physics** | Upstream (Input reads from Hook) | Hard — lock/unlock depends on hook state | Sends `hook_state_changed` signal to toggle joystick lock |
| **HUD** | Downstream (depends on Input) | Soft — HUD works without it but can't show cooldown | Polls `hook_button_state` and `cooldown_progress` |
| **Match State Manager** | Upstream (Input reads from Match) | Hard — input must obey match state | Sends `match_state_changed` to enable/disable all input |
| **UI System** | Upstream (Input reads from UI) | Hard — input must yield to UI focus | Input checks `ui_has_focus` flag before processing gameplay touches |

**No upstream gameplay dependencies.** This is a foundation system — it reads from
OS touch events and two control signals (hook state, match state). Everything else
is downstream.

## Tuning Knobs

| Parameter | Default Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `joystick_radius` | 100 px | 60-150 px | Larger thumb travel for more precision, but slower direction changes | Twitchier aim, less precision, faster direction swaps |
| `dead_zone_radius` | 10 px | 5-25 px | More forgiving center (less accidental drift), but less responsive at small movements | More responsive, but thumb resting on joystick may cause micro-drift |
| `joystick_position_x` | 120 px from left edge | 80-200 px | Joystick moves toward center — better for small hands, may overlap content | Joystick sits in corner — natural for large hands, cramped for small |
| `joystick_position_y` | 120 px from bottom edge | 80-200 px | Joystick rises — may conflict with other UI | Joystick drops toward edge — natural thumb resting position |
| `hook_button_radius` | 60 px | 40-90 px | Easier to tap, but takes more screen space | Harder to hit under stress, but less visual clutter |
| `hook_button_position_x` | 120 px from right edge | 80-200 px | Button moves toward center | Button sits in corner |
| `hook_button_position_y` | 120 px from bottom edge | 80-200 px | Button rises | Button drops toward edge |
| `input_process_priority` | 0 (highest) | 0-10 | Lower priority — other systems process first (adds latency feel) | Higher priority — input is always first (responsive but may read stale game state) |

**Knob interactions**: `joystick_radius` and `dead_zone_radius` interact — if
dead zone is more than ~25% of joystick radius, the usable range feels tiny.
Maintain ratio: `dead_zone_radius < joystick_radius * 0.2`.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Joystick touch start | Joystick base brightens, thumb indicator appears | Soft click (subtle) | Medium |
| Joystick drag | Thumb indicator follows touch position smoothly | None — silence during continuous drag | High |
| Joystick release | Thumb indicator snaps back to center, base dims | None | Low |
| Joystick locked (hook in flight) | Joystick base dims to 50% opacity, thumb indicator disappears | None | High |
| Hook button tap (Ready state) | Button press animation (scale down briefly) | Punchy "fire" click — must feel impactful | High |
| Hook button tap (disabled — In Flight/Cooldown) | Button flashes red briefly (rejected input) | Dull "blocked" thud | Medium |
| Cooldown filling | Radial fill animation on hook button (clockwise, matches `cooldown_progress`) | Subtle tick when cooldown completes (ready again) | High |
| All input disabled (match countdown/end) | Both controls fade to 30% opacity | None | Medium |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Virtual joystick (base + thumb indicator) | Fixed, bottom-left corner | Every frame while touched | Always visible during gameplay |
| Hook button | Fixed, bottom-right corner | Every frame (state-dependent appearance) | Always visible during gameplay |
| Cooldown radial fill | Overlaid on hook button | Every frame during cooldown | Visible only during Cooldown state |
| Hook button state indicator | Hook button color/opacity | On state change | Ready = full bright; In Flight = grayed; Cooldown = grayed + fill |
| Input disabled overlay | Both controls dim to 30% | On match state change | During countdown, match end, pause |

**Layout constraints**:
- Joystick and hook button must not overlap with HUD elements (health bar, kill count, timer)
- Both controls must be reachable by thumbs in landscape grip — bottom 30% of screen
- Minimum 200px horizontal gap between joystick edge and hook button edge to prevent mis-taps
- Controls must scale proportionally on different screen sizes (use viewport-relative positioning, not absolute pixels)

## Acceptance Criteria

- [ ] Virtual joystick renders at fixed position and tracks touch input correctly
- [ ] Hero moves in the direction the joystick is dragged, at constant speed
- [ ] Hero faces the joystick direction continuously (360°, no snapping)
- [ ] Releasing joystick stops movement but preserves last facing direction
- [ ] Hook button fires hook in current facing direction on tap
- [ ] Hook button fires in last facing direction when joystick is neutral
- [ ] Joystick locks (no movement) while hook is in flight
- [ ] Hook button disables during flight and cooldown, with visual feedback
- [ ] Cooldown progress value is readable by HUD (0.0-1.0)
- [ ] Dead zone prevents micro-drift when thumb rests on joystick center
- [ ] Dragging thumb across screen zones does not trigger the wrong control (touch ID isolation)
- [ ] UI panels override gameplay input — no movement/firing behind open menus
- [ ] All input disabled during match countdown and match end states
- [ ] Screen orientation locked to landscape
- [ ] Performance: Input processing completes within 1ms per frame on target devices
- [ ] All position/radius values loaded from config — no hardcoded pixel values

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should joystick input have analog speed (push gently = walk, push fully = run) instead of binary (full speed or stopped)? | game-designer | Before prototype | Current design says binary. Prototype both and playtest. |
| Do we need a "hook aim preview" line showing the direction before firing, or is the hero's facing direction enough feedback? | game-designer + ux-designer | Before prototype | Could add a subtle dotted line from hero in facing direction. May clutter screen. Test without first. |
| Should the hero system add a secondary ability button later? The concept mentions "secondary abilities" but current input has only one button. | game-designer | Before Hero System GDD | Defer until Hero System design. May add a second button on the right side if needed. |
| What's the minimum supported screen size? Controls layout depends on this. | producer | Before UI implementation | Assume 5" minimum (iPhone SE class). Validate during prototype. |
