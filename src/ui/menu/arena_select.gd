## Arena Selection — dropdown for choosing arena before match.
##
## Shows all available arenas plus "Random" option. Emits selected ArenaData.
## Used in both solo menu and multiplayer lobby.
## Sprint 7 S7-02.
class_name ArenaSelect
extends Control

signal arena_selected(arena_data: ArenaData)

var _arenas: Array[Dictionary] = []
var _selected_index: int = 0

@onready var arena_button: Button = $VBox/ArenaButton
@onready var arena_name_label: Label = $VBox/ArenaNameLabel
@onready var arena_info_label: Label = $VBox/ArenaInfoLabel

func _ready() -> void:
	_arenas = [
		{
			"name": "Random",
			"data": null,
			"info": "A random arena will be chosen",
		},
		{
			"name": "MVP Arena",
			"data": preload("res://data/arenas/mvp_arena.tres"),
			"info": "46x40 — Classic layout, 4 spikes, 4 pits",
		},
		{
			"name": "The Crucible",
			"data": preload("res://data/arenas/crucible_arena.tres"),
			"info": "36x30 — Tight, 6 spikes, 2 pits, narrow gap",
		},
		{
			"name": "The Abyss",
			"data": preload("res://data/arenas/abyss_arena.tres"),
			"info": "56x45 — Large, 8 spikes, 6 pits, wide gap",
		},
	]

	arena_button.pressed.connect(_cycle_arena)
	_update_display()

## Get the currently selected ArenaData (null = random).
func get_selected_arena() -> ArenaData:
	if _selected_index == 0:
		# Random — pick one
		var choices: Array[ArenaData] = []
		for i in range(1, _arenas.size()):
			choices.append(_arenas[i]["data"] as ArenaData)
		return choices[randi() % choices.size()]
	return _arenas[_selected_index]["data"] as ArenaData

func _cycle_arena() -> void:
	_selected_index = (_selected_index + 1) % _arenas.size()
	_update_display()
	arena_selected.emit(get_selected_arena())

func _update_display() -> void:
	var arena: Dictionary = _arenas[_selected_index]
	arena_button.text = "Arena: %s" % arena["name"]
	if arena_name_label:
		arena_name_label.text = arena["name"]
	if arena_info_label:
		arena_info_label.text = arena["info"]
		arena_info_label.add_theme_font_size_override("font_size", 12)
		arena_info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
