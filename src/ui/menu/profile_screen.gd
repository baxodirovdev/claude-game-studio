## Profile Screen — displays account stats, level, and hero mastery.
##
## Accessible from main menu. Reads from PlayerProfile.
## Shows level bar, lifetime K/D/A, win rate, and per-hero mastery badges.
## Sprint 7 S7-03.
class_name ProfileScreen
extends Control

signal back_pressed

var player_profile: PlayerProfile

@onready var level_label: Label = $VBox/LevelLabel
@onready var xp_bar_bg: ColorRect = $VBox/XPBar/Background
@onready var xp_bar_fill: ColorRect = $VBox/XPBar/Fill
@onready var stats_container: VBoxContainer = $VBox/StatsContainer
@onready var hero_mastery_container: VBoxContainer = $VBox/HeroMasteryContainer
@onready var back_button: Button = $VBox/BackButton

const XP_BAR_WIDTH: float = 300.0
const MASTERY_NAMES: Array[String] = ["—", "Bronze", "Silver", "Gold"]
const MASTERY_COLORS: Array[Color] = [
	Color(0.5, 0.5, 0.5),
	Color(0.8, 0.5, 0.2),
	Color(0.7, 0.7, 0.8),
	Color(1.0, 0.85, 0.2),
]

func _ready() -> void:
	visible = false
	back_button.pressed.connect(func() -> void:
		visible = false
		back_pressed.emit()
	)

## Show the profile screen with current data.
func show_profile() -> void:
	if player_profile == null:
		return
	_populate_stats()
	_populate_hero_mastery()
	visible = true

func _populate_stats() -> void:
	# Level display
	level_label.text = "Level %d" % player_profile.get_level()
	level_label.add_theme_font_size_override("font_size", 28)
	level_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))

	# XP bar
	if xp_bar_fill:
		xp_bar_fill.size.x = player_profile.get_level_progress() * XP_BAR_WIDTH

	# Clear previous stats
	for child in stats_container.get_children():
		child.queue_free()

	var stats: Array[Dictionary] = [
		{"label": "Matches Played", "value": str(player_profile.matches_played)},
		{"label": "Wins", "value": str(player_profile.total_wins)},
		{"label": "Win Rate", "value": "%.1f%%" % player_profile.get_win_rate()},
		{"label": "Total Kills", "value": str(player_profile.total_kills)},
		{"label": "Total Deaths", "value": str(player_profile.total_deaths)},
		{"label": "Total Assists", "value": str(player_profile.total_assists)},
		{"label": "Total XP", "value": str(player_profile.total_xp)},
	]

	for stat: Dictionary in stats:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)

		var name_lbl := Label.new()
		name_lbl.text = stat["label"]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		var val_lbl := Label.new()
		val_lbl.text = stat["value"]
		val_lbl.add_theme_font_size_override("font_size", 16)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(val_lbl)

		stats_container.add_child(hbox)

func _populate_hero_mastery() -> void:
	for child in hero_mastery_container.get_children():
		child.queue_free()

	var heroes: Array[String] = ["vex", "lash", "maw", "flux", "coil"]
	var hero_names: Dictionary = {
		"vex": "Vex", "lash": "Lash", "maw": "Maw",
		"flux": "Flux", "coil": "Coil",
	}

	for hero_id: String in heroes:
		var tier := player_profile.get_hero_mastery_tier(hero_id)
		var games: int = 0
		if player_profile.hero_mastery.has(hero_id):
			games = player_profile.hero_mastery[hero_id].get("games", 0)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var name_lbl := Label.new()
		name_lbl.text = hero_names.get(hero_id, hero_id)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		var games_lbl := Label.new()
		games_lbl.text = "%d games" % games
		games_lbl.add_theme_font_size_override("font_size", 14)
		games_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hbox.add_child(games_lbl)

		var tier_lbl := Label.new()
		tier_lbl.text = MASTERY_NAMES[tier]
		tier_lbl.add_theme_font_size_override("font_size", 14)
		tier_lbl.add_theme_color_override("font_color", MASTERY_COLORS[tier])
		hbox.add_child(tier_lbl)

		hero_mastery_container.add_child(hbox)
