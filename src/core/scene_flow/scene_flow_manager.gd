## Scene Flow Manager — centralized scene transitions with fade effects.
##
## Autoload singleton. Manages all scene changes in the game:
## Main Menu → Lobby/Hero Select → Game → Results → Main Menu.
## Provides fade-in/out transitions and prevents duplicate transitions.
## Sprint 4 S4-03.
class_name SceneFlowManager
extends CanvasLayer

signal transition_started
signal transition_finished

const FADE_DURATION: float = 0.3

## Scene paths — all navigation flows through these.
const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_GAME := "res://scenes/main.tscn"

var _is_transitioning: bool = false
var _fade_rect: ColorRect
var _current_scene_path: String = ""

func _ready() -> void:
	layer = 100  # Above everything
	_create_fade_overlay()

## Transition to main menu.
func go_to_main_menu() -> void:
	_transition_to(SCENE_MAIN_MENU)

## Transition to game scene (solo or after lobby).
func go_to_game() -> void:
	_transition_to(SCENE_GAME)

## Transition to an arbitrary scene by path.
func go_to_scene(scene_path: String) -> void:
	_transition_to(scene_path)

## Reload the current scene.
func reload_current() -> void:
	if _current_scene_path != "":
		_transition_to(_current_scene_path)
	else:
		get_tree().reload_current_scene()

## Quit the application.
func quit_game() -> void:
	get_tree().quit()

## Fade in from black (call at scene start).
func fade_in() -> void:
	if _fade_rect == null:
		return
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.visible = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	tween.tween_callback(func() -> void:
		_fade_rect.visible = false
	)

func _transition_to(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_current_scene_path = scene_path
	transition_started.emit()

	# Fade out
	_fade_rect.visible = true
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input during transition

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(func() -> void:
		# Change scene
		get_tree().change_scene_to_file(scene_path)
		# Fade back in after a brief frame delay
		get_tree().process_frame.connect(_on_scene_loaded, CONNECT_ONE_SHOT)
	)

func _on_scene_loaded() -> void:
	fade_in()
	_is_transitioning = false
	transition_finished.emit()

func _create_fade_overlay() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.visible = false
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Full screen coverage
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)
