## Hook fire button that tracks cooldown and hook flight state.
##
## Emits [signal hook_pressed] when tapped while in Ready state.
## Manages its own state machine: Ready → In Flight → Cooldown → Ready.
class_name HookButton
extends Control

## Emitted when the button is tapped and the hook is ready to fire.
signal hook_pressed

## Emitted every frame with the current cooldown progress (0.0 to 1.0).
signal cooldown_updated(progress: float)

enum State { READY, IN_FLIGHT, COOLDOWN }

@onready var _base: ColorRect = $Base
@onready var _label: Label = $Label
@onready var _cooldown_label: Label = $CooldownLabel

var _state: State = State.READY
var _touch_index: int = -1
var _cooldown_timer: float = 0.0
var _cooldown_duration: float = 2.0

## Returns the current button state.
func get_state() -> State:
	return _state

## Returns cooldown progress from 0.0 (just started) to 1.0 (ready).
func get_cooldown_progress() -> float:
	if _state != State.COOLDOWN or _cooldown_duration <= 0:
		return 1.0
	return 1.0 - (_cooldown_timer / _cooldown_duration)

## Set the cooldown duration (called by Hero System with per-hero values).
func set_cooldown_duration(duration: float) -> void:
	_cooldown_duration = duration

## Called by Hook System when the hook is fired.
func on_hook_fired() -> void:
	_state = State.IN_FLIGHT
	_update_visual()

## Called by Hook System when the hook returns to the player.
func on_hook_returned() -> void:
	_state = State.COOLDOWN
	_cooldown_timer = _cooldown_duration
	_update_visual()

## Call from the parent's _input to route touch events here.
func handle_touch(event: InputEventScreenTouch) -> bool:
	if event.pressed:
		if _state == State.READY:
			_touch_index = event.index
			hook_pressed.emit()
			# Visual press feedback: brief scale pulse
			_show_press_feedback()
			return true
	else:
		if event.index == _touch_index:
			_touch_index = -1
			return true
	return false

func _show_press_feedback() -> void:
	if _base == null:
		return
	var original_scale := _base.scale
	_base.scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.tween_property(_base, "scale", Vector2(1.1, 1.1), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(_base, "scale", original_scale, 0.1).set_ease(Tween.EASE_IN)

func _process(delta: float) -> void:
	if _state == State.COOLDOWN:
		_cooldown_timer -= delta
		cooldown_updated.emit(get_cooldown_progress())
		if _cooldown_timer <= 0:
			_cooldown_timer = 0
			_state = State.READY
			_update_visual()

func _update_visual() -> void:
	if not _base:
		return
	match _state:
		State.READY:
			_base.color = Color(0.8, 0.2, 0.2, 0.6)
			if _cooldown_label:
				_cooldown_label.visible = false
		State.IN_FLIGHT:
			_base.color = Color(0.4, 0.4, 0.4, 0.5)
			if _cooldown_label:
				_cooldown_label.visible = false
		State.COOLDOWN:
			_base.color = Color(0.6, 0.3, 0.3, 0.5)
			if _cooldown_label:
				_cooldown_label.visible = true
				_cooldown_label.text = "%.1f" % _cooldown_timer
