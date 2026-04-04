## Settings Menu — volume and sensitivity sliders with file persistence.
##
## Reads/writes settings to user://settings.cfg using ConfigFile.
## Controls AudioServer bus volumes and exposes sensitivity for InputManager.
## Sprint 4 S4-02.
class_name SettingsMenu
extends Control

signal settings_closed

const SETTINGS_PATH := "user://settings.cfg"

@onready var master_slider: HSlider = $VBox/MasterRow/MasterSlider
@onready var master_label: Label = $VBox/MasterRow/MasterLabel
@onready var sfx_slider: HSlider = $VBox/SFXRow/SFXSlider
@onready var sfx_label: Label = $VBox/SFXRow/SFXLabel
@onready var sensitivity_slider: HSlider = $VBox/SensRow/SensSlider
@onready var sensitivity_label: Label = $VBox/SensRow/SensLabel
@onready var handed_button: Button = $VBox/HandedRow/HandedButton
@onready var back_button: Button = $VBox/BackButton

var _config := ConfigFile.new()

## Current settings values.
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var sensitivity: float = 1.0
## false = right-handed (hook on right), true = left-handed (hook on left).
var left_handed: bool = false

func _ready() -> void:
	_load_settings()
	_apply_settings()

	# Configure sliders
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	master_slider.value = master_volume

	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = sfx_volume

	sensitivity_slider.min_value = 0.2
	sensitivity_slider.max_value = 3.0
	sensitivity_slider.step = 0.1
	sensitivity_slider.value = sensitivity

	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	handed_button.pressed.connect(_on_handed_toggle)
	back_button.pressed.connect(_on_back)

	_update_labels()

func _on_master_changed(value: float) -> void:
	master_volume = value
	_apply_audio()
	_update_labels()

func _on_sfx_changed(value: float) -> void:
	sfx_volume = value
	_apply_audio()
	_update_labels()

func _on_sensitivity_changed(value: float) -> void:
	sensitivity = value
	_update_labels()

func _on_handed_toggle() -> void:
	left_handed = not left_handed
	_update_labels()

func _on_back() -> void:
	_save_settings()
	visible = false
	settings_closed.emit()

func _update_labels() -> void:
	master_label.text = "Master: %d%%" % int(master_volume * 100)
	sfx_label.text = "SFX: %d%%" % int(sfx_volume * 100)
	sensitivity_label.text = "Sensitivity: %.1f" % sensitivity
	handed_button.text = "Left-Handed" if left_handed else "Right-Handed"

func _apply_settings() -> void:
	_apply_audio()

func _apply_audio() -> void:
	# Master bus (index 0)
	var master_db := linear_to_db(master_volume) if master_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(0, master_db)

	# SFX bus — if it exists, otherwise apply to master
	var sfx_idx := AudioServer.get_bus_index(&"SFX")
	if sfx_idx >= 0:
		var sfx_db := linear_to_db(sfx_volume) if sfx_volume > 0.0 else -80.0
		AudioServer.set_bus_volume_db(sfx_idx, sfx_db)

func _load_settings() -> void:
	var err: Error = _config.load(SETTINGS_PATH)
	if err != OK:
		# First run — use defaults
		return
	master_volume = _config.get_value("audio", "master_volume", 1.0)
	sfx_volume = _config.get_value("audio", "sfx_volume", 1.0)
	sensitivity = _config.get_value("input", "sensitivity", 1.0)
	left_handed = _config.get_value("input", "left_handed", false)

func _save_settings() -> void:
	_config.set_value("audio", "master_volume", master_volume)
	_config.set_value("audio", "sfx_volume", sfx_volume)
	_config.set_value("input", "sensitivity", sensitivity)
	_config.set_value("input", "left_handed", left_handed)
	_config.save(SETTINGS_PATH)
