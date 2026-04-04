## Hero Selection UI — Pudge-only mode.
##
## Auto-selects Pudge and starts the match immediately.
## No other heroes are selectable or spawnable.
class_name HeroSelect
extends CanvasLayer

signal hero_selected(config: HeroConfig)

var _pudge_config: HeroConfig = preload("res://data/heroes/pudge.tres")

@onready var panel: PanelContainer = $Panel

func _ready() -> void:
	pass

func show_selection() -> void:
	# Pudge-only mode: auto-select and start immediately
	visible = false
	_select(_pudge_config)

func hide_selection() -> void:
	visible = false

func _select(config: HeroConfig) -> void:
	hero_selected.emit(config)
	hide_selection()
