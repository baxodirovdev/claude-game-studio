## Hero Selection UI — simple pre-match hero picker with 3 buttons.
##
## Shown before countdown. Player taps a hero button to select.
## Emits hero_selected with the chosen HeroConfig. Default = Vex.
class_name HeroSelect
extends CanvasLayer

signal hero_selected(config: HeroConfig)

var _vex_config: HeroConfig = preload("res://data/heroes/vex.tres")
var _lash_config: HeroConfig = preload("res://data/heroes/lash.tres")
var _maw_config: HeroConfig = preload("res://data/heroes/maw.tres")

@onready var vex_button: Button = $Panel/VBox/VexButton
@onready var lash_button: Button = $Panel/VBox/LashButton
@onready var maw_button: Button = $Panel/VBox/MawButton
@onready var panel: PanelContainer = $Panel

func _ready() -> void:
	vex_button.pressed.connect(func() -> void: _select(_vex_config))
	lash_button.pressed.connect(func() -> void: _select(_lash_config))
	maw_button.pressed.connect(func() -> void: _select(_maw_config))

func show_selection() -> void:
	visible = true

func hide_selection() -> void:
	visible = false

func _select(config: HeroConfig) -> void:
	hero_selected.emit(config)
	hide_selection()
