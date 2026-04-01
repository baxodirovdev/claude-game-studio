## Virtual joystick that emits a normalized movement direction and facing angle.
##
## Attach to a Control node. The joystick area is the Control's rect.
## Emits [signal direction_changed] every frame the joystick is active.
class_name VirtualJoystick
extends Control

## Emitted every frame the joystick is held, and once on release (with Vector2.ZERO).
signal direction_changed(direction: Vector2, angle: float)

## Radius in pixels the thumb can travel from center.
@export var joystick_radius: float = 100.0
## Dead zone radius — input below this is treated as zero.
@export var dead_zone_radius: float = 10.0

@onready var _base: ColorRect = $Base
@onready var _thumb: ColorRect = $Thumb

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _current_direction: Vector2 = Vector2.ZERO
var _current_angle: float = 0.0
var _is_active: bool = false
## When true, joystick ignores all input (hook in flight).
var locked: bool = false:
	set(value):
		locked = value
		if locked:
			_release()
		_update_visual()

func _ready() -> void:
	_center = size / 2.0
	_reset_thumb()

## Returns the current normalized direction (or Vector2.ZERO if idle).
func get_direction() -> Vector2:
	return _current_direction

## Returns the current facing angle in radians.
func get_facing_angle() -> float:
	return _current_angle

## Returns true if the joystick is currently being held.
func is_active() -> bool:
	return _is_active

## Call from the parent's _input to route touch events here.
func handle_touch(event: InputEventScreenTouch) -> bool:
	if locked:
		return false
	if event.pressed:
		if _touch_index != -1:
			return false  # Already tracking a touch
		_touch_index = event.index
		_is_active = true
		_center = global_position + size / 2.0
		_process_touch(event.position)
		return true
	else:
		if event.index == _touch_index:
			_release()
			return true
	return false

## Call from the parent's _input to route drag events here.
func handle_drag(event: InputEventScreenDrag) -> bool:
	if event.index != _touch_index:
		return false
	_process_touch(event.position)
	return true

func _process_touch(touch_pos: Vector2) -> void:
	var offset := touch_pos - _center
	if offset.length() > joystick_radius:
		offset = offset.normalized() * joystick_radius

	if offset.length() < dead_zone_radius:
		_current_direction = Vector2.ZERO
		_reset_thumb()
		direction_changed.emit(Vector2.ZERO, _current_angle)
		return

	_current_direction = offset.normalized()
	_current_angle = atan2(-offset.y, offset.x)

	# Position thumb visual (thumb is centered in joystick when idle)
	var thumb_size := _thumb.size
	_thumb.position = (size / 2.0 - thumb_size / 2.0) + offset

	direction_changed.emit(_current_direction, _current_angle)

func _release() -> void:
	_touch_index = -1
	_is_active = false
	_current_direction = Vector2.ZERO
	_reset_thumb()
	direction_changed.emit(Vector2.ZERO, _current_angle)

func _reset_thumb() -> void:
	if _thumb:
		var thumb_size := _thumb.size
		_thumb.position = size / 2.0 - thumb_size / 2.0

func _update_visual() -> void:
	if _base:
		_base.modulate.a = 0.2 if locked else 0.4
