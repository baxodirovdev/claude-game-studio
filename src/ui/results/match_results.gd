## Match Results Screen — post-match stats overlay with K/D/A, hook accuracy, MVP.
##
## Shown after match ends. Displays per-player stats from ScoreSystem and HookSystem.
## "Play Again" restarts the match via hero select. Purely display — no game logic.
## Implements GDD: design/gdd/score-kill-tracking.md (results screen subset).
class_name MatchResults
extends CanvasLayer

signal play_again_requested
signal return_to_menu_requested

## References set by Main.
var score_system: ScoreSystem
var hook_system: HookSystem
var hero_config: HeroConfig
var player: PlayerController
var match_config: Resource
var player_profile: PlayerProfile

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stats_container: VBoxContainer = $Panel/VBox/StatsContainer
@onready var mvp_label: Label = $Panel/VBox/MVPLabel
@onready var play_again_button: Button = $Panel/VBox/PlayAgainButton

@onready var menu_button: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	visible = false
	play_again_button.pressed.connect(func() -> void:
		visible = false
		play_again_requested.emit()
	)
	if menu_button:
		menu_button.pressed.connect(func() -> void:
			visible = false
			return_to_menu_requested.emit()
		)

## Show results for the completed match.
func show_results(winner_team: int, player_team: int) -> void:
	_set_title(winner_team, player_team)
	_populate_stats()
	_show_mvp(winner_team)
	_record_profile(winner_team, player_team)
	visible = true
	play_again_button.grab_focus()

## Record match stats to persistent profile and show XP gain.
func _record_profile(winner_team: int, player_team: int) -> void:
	if player_profile == null or score_system == null or player == null:
		return

	var pid := player.get_instance_id()
	var stats: Dictionary = score_system.player_stats.get(pid, {})
	var kills: int = stats.get("kills", 0)
	var deaths: int = stats.get("deaths", 0)
	var assists: int = stats.get("assists", 0)
	var won := winner_team == player_team

	# Calculate match XP: kills*10 + assists*5 + win bonus 50
	var xp_earned := kills * 10 + assists * 5
	if won:
		xp_earned += 50

	var old_level := player_profile.get_level()
	player_profile.record_match(
		hero_config.hero_id if hero_config else "unknown",
		won, kills, deaths, assists, xp_earned
	)
	var new_level := player_profile.get_level()

	# Add XP info to stats display
	var xp_label := Label.new()
	xp_label.text = "+%d XP" % xp_earned
	xp_label.add_theme_font_size_override("font_size", 20)
	xp_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(xp_label)

	if new_level > old_level:
		var lvl_label := Label.new()
		lvl_label.text = "LEVEL UP! → %d" % new_level
		lvl_label.add_theme_font_size_override("font_size", 22)
		lvl_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(lvl_label)

func _set_title(winner_team: int, player_team: int) -> void:
	if winner_team == player_team:
		title_label.text = "VICTORY"
		title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	elif winner_team < 0:
		title_label.text = "DRAW"
		title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		title_label.text = "DEFEAT"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

func _populate_stats() -> void:
	# Clear previous entries
	for child in stats_container.get_children():
		child.queue_free()

	if score_system == null or player == null:
		return

	var pid := player.get_instance_id()
	var stats: Dictionary = score_system.player_stats.get(pid, {})

	var kills: int = stats.get("kills", 0)
	var deaths: int = stats.get("deaths", 0)
	var assists: int = stats.get("assists", 0)
	var best_streak: int = stats.get("best_streak", 0)

	# Hook accuracy
	var hook_acc := 0.0
	if hook_system and hook_system.hooks_fired > 0:
		hook_acc = float(hook_system.hooks_hit) / float(hook_system.hooks_fired) * 100.0

	# KDA ratio
	var kda := float(kills + assists) / maxf(deaths, 1)

	var lines: Array[Dictionary] = [
		{"label": "Kills", "value": str(kills)},
		{"label": "Deaths", "value": str(deaths)},
		{"label": "Assists", "value": str(assists)},
		{"label": "KDA", "value": "%.1f" % kda},
		{"label": "Best Streak", "value": str(best_streak)},
		{"label": "Hook Accuracy", "value": "%.0f%%" % hook_acc},
		{"label": "Hooks Landed", "value": "%d / %d" % [
			hook_system.hooks_hit if hook_system else 0,
			hook_system.hooks_fired if hook_system else 0,
		]},
	]

	for line_data: Dictionary in lines:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)

		var name_label := Label.new()
		name_label.text = line_data["label"]
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)

		var value_label := Label.new()
		value_label.text = line_data["value"]
		value_label.add_theme_font_size_override("font_size", 18)
		value_label.add_theme_color_override("font_color", Color.WHITE)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(value_label)

		stats_container.add_child(hbox)

func _show_mvp(winner_team: int) -> void:
	if score_system == null:
		mvp_label.visible = false
		return

	# Calculate MVP: highest mvp_score on winning team (or all players if draw)
	var best_score := -999
	var best_name := ""
	for pid: int in score_system.player_stats:
		var stats: Dictionary = score_system.player_stats[pid]
		if winner_team >= 0 and stats.get("team_id", -1) != winner_team:
			continue
		var kills: int = stats.get("kills", 0)
		var assists: int = stats.get("assists", 0)
		var deaths: int = stats.get("deaths", 0)
		var mvp_score: int = kills * 3 + assists * 1 - deaths * 1
		if mvp_score > best_score:
			best_score = mvp_score
			var node := stats.get("node", null) as Node
			best_name = node.name if node != null and is_instance_valid(node) else "Unknown"

	if best_name != "":
		mvp_label.text = "MVP: %s" % best_name
		mvp_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		mvp_label.add_theme_font_size_override("font_size", 22)
		mvp_label.visible = true
	else:
		mvp_label.visible = false
