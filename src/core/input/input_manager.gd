## Central input manager that routes touch events to joystick and hook button.
##
## Attach to a CanvasLayer containing the VirtualJoystick and HookButton controls.
## Downstream systems read input state via the public API methods.
class_name InputManager
extends CanvasLayer

## Emitted when the hook button is pressed (hook is ready).
signal hook_fire_requested(facing_angle: float)

@onready var joystick: VirtualJoystick = $VirtualJoystick
@onready var hook_button: HookButton = $HookButton

var _enabled: bool = true
## When true, hook is on left side, joystick on right (left-handed mode).
var left_handed: bool = false

## Returns the current movement direction (normalized or zero).
func get_movement_vector() -> Vector2:
	if not _enabled:
		return Vector2.ZERO
	return joystick.get_direction()

## Returns the current facing angle in radians.
func get_facing_angle() -> float:
	return joystick.get_facing_angle()

## Returns true if the joystick is actively being held.
func is_joystick_active() -> bool:
	return joystick.is_active()

## Lock the joystick (during hook flight). Joystick ignores input.
func lock_joystick() -> void:
	joystick.locked = true

## Unlock the joystick (hook returned).
func unlock_joystick() -> void:
	joystick.locked = false

## Notify that hook was fired (updates button state).
func notify_hook_fired() -> void:
	hook_button.on_hook_fired()

## Notify that hook returned (starts cooldown).
func notify_hook_returned() -> void:
	hook_button.on_hook_returned()

## Set the hook cooldown duration from hero data.
func set_hook_cooldown(duration: float) -> void:
	hook_button.set_cooldown_duration(duration)

## Enable or disable all gameplay input (for match state transitions).
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	joystick.locked = not enabled
	if not enabled:
		hook_button._state = HookButton.State.READY
	_update_visibility()

func _ready() -> void:
	hook_button.hook_pressed.connect(_on_hook_pressed)

func _input(event: InputEvent) -> void:
	if not _enabled:
		return

	if event is InputEventScreenTouch:
		_route_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_route_drag(event as InputEventScreenDrag)

func _route_touch(event: InputEventScreenTouch) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var half_x := screen_size.x / 2.0

	if event.pressed:
		# Left-handed: hook on left, joystick on right
		# Right-handed (default): joystick on left, hook on right
		var is_left_side := event.position.x < half_x
		var is_joystick_side := is_left_side != left_handed
		if is_joystick_side:
			joystick.handle_touch(event)
		else:
			hook_button.handle_touch(event)
	else:
		# On release, try both — only the one tracking this index will handle it
		joystick.handle_touch(event)
		hook_button.handle_touch(event)

func _route_drag(event: InputEventScreenDrag) -> void:
	joystick.handle_drag(event)

func _on_hook_pressed() -> void:
	hook_fire_requested.emit(joystick.get_facing_angle())

## Set the joystick dead zone radius (from settings).
func set_dead_zone(radius: float) -> void:
	joystick.dead_zone_radius = radius

## Set the joystick sensitivity multiplier.
func set_sensitivity(multiplier: float) -> void:
	joystick.joystick_radius = 100.0 / maxf(multiplier, 0.1)

func _update_visibility() -> void:
	visible = _enabled
