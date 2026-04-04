## Tutorial System — guided 3-step onboarding for new players.
##
## Step 1: Move (joystick prompt). Step 2: Fire hook (target prompt).
## Step 3: Avoid hazard (warning prompt). Skippable. Completion saved to settings.
## Overlays on top of gameplay with highlight boxes and instruction text.
## Sprint 7 S7-01.
class_name TutorialSystem
extends CanvasLayer

signal tutorial_completed
signal tutorial_skipped

enum Step { MOVE, HOOK, HAZARD, DONE }

const SETTINGS_PATH := "user://settings.cfg"

var _current_step: Step = Step.MOVE
var _step_completed: bool = false

@onready var overlay: ColorRect = $Overlay
@onready var instruction_label: Label = $InstructionPanel/VBox/InstructionLabel
@onready var hint_label: Label = $InstructionPanel/VBox/HintLabel
@onready var skip_button: Button = $InstructionPanel/VBox/SkipButton
@onready var next_button: Button = $InstructionPanel/VBox/NextButton
@onready var instruction_panel: PanelContainer = $InstructionPanel

## References set by Main.
var input_manager: InputManager
var hook_system: HookSystem

func _ready() -> void:
	visible = false
	skip_button.pressed.connect(_on_skip)
	next_button.pressed.connect(_on_next)
	next_button.visible = false

func should_show_tutorial() -> bool:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return true
	return not config.get_value("tutorial", "completed", false)

## Start the tutorial sequence.
func start_tutorial() -> void:
	visible = true
	_current_step = Step.MOVE
	_show_step()

	# Listen to input events for step completion
	if input_manager:
		input_manager.hook_fire_requested.connect(_on_hook_fired)

func _show_step() -> void:
	_step_completed = false
	next_button.visible = false
	overlay.color = Color(0, 0, 0, 0.4)

	match _current_step:
		Step.MOVE:
			instruction_label.text = "MOVE"
			instruction_label.add_theme_font_size_override("font_size", 36)
			hint_label.text = "Drag the LEFT side of the screen to move your hero.\nTry moving around the arena!"
			# Wait for movement input
			if input_manager:
				input_manager.joystick.direction_changed.connect(_on_move_detected, CONNECT_ONE_SHOT)

		Step.HOOK:
			instruction_label.text = "FIRE YOUR HOOK"
			hint_label.text = "Tap the RIGHT side of the screen to fire your hook.\nAim at the orange target!"

		Step.HAZARD:
			instruction_label.text = "WATCH OUT!"
			hint_label.text = "Red zones deal damage! Don't stand in them.\nUse your hook to pull enemies INTO hazards."
			# Auto-advance after reading time
			get_tree().create_timer(4.0).timeout.connect(func() -> void:
				if _current_step == Step.HAZARD:
					_step_completed = true
					next_button.visible = true
					next_button.text = "GOT IT!"
			)

		Step.DONE:
			_finish_tutorial()

func _on_move_detected(_direction: Vector2, _angle: float) -> void:
	if _current_step == Step.MOVE and not _step_completed:
		_step_completed = true
		next_button.visible = true
		next_button.text = "NEXT"
		hint_label.text = "Great! You can move around."

func _on_hook_fired(_facing_angle: float) -> void:
	if _current_step == Step.HOOK and not _step_completed:
		_step_completed = true
		next_button.visible = true
		next_button.text = "NEXT"
		hint_label.text = "Nice shot! Hooks deal damage and pull enemies."

func _on_next() -> void:
	match _current_step:
		Step.MOVE:
			_current_step = Step.HOOK
		Step.HOOK:
			_current_step = Step.HAZARD
		Step.HAZARD:
			_current_step = Step.DONE
	_show_step()

func _on_skip() -> void:
	_save_completion()
	visible = false
	tutorial_skipped.emit()

func _finish_tutorial() -> void:
	_save_completion()
	visible = false

	# Show completion message briefly
	instruction_label.text = "YOU'RE READY!"
	hint_label.text = ""
	skip_button.visible = false
	next_button.visible = false
	overlay.color = Color(0, 0, 0, 0)

	tutorial_completed.emit()

func _save_completion() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)  # Load existing settings
	config.set_value("tutorial", "completed", true)
	config.save(SETTINGS_PATH)
