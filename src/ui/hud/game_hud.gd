## Game HUD — in-match information overlay.
##
## Reads from Health, MatchStateManager, HookSystem, and MatchConfig.
## Purely visual — no gameplay logic, no sounds. Updates every frame for health bar,
## every second for timer, instantly for kills and state changes.
## Implements GDD: design/gdd/hud.md (basic Sprint 1 subset).
class_name GameHUD
extends CanvasLayer

## Health bar color thresholds.
const HEALTH_GREEN := Color(0.2, 0.8, 0.2)
const HEALTH_YELLOW := Color(0.9, 0.8, 0.1)
const HEALTH_RED := Color(0.9, 0.15, 0.15)
const GHOST_DECAY_SPEED := 3.0
const LOW_HEALTH_THRESHOLD := 0.25
const FINAL_COUNTDOWN_THRESHOLD := 30.0

@onready var hero_name_label: Label = $TopLeft/HeroNameLabel
@onready var level_label: Label = $TopLeft/LevelLabel
@onready var xp_bar_fill: ColorRect = $TopLeft/XpBar/Fill
@onready var level_up_label: Label = $Center/LevelUpLabel
@onready var health_bar: ColorRect = $TopLeft/HealthBar/Fill
@onready var health_ghost: ColorRect = $TopLeft/HealthBar/Ghost
@onready var health_bar_bg: ColorRect = $TopLeft/HealthBar/Background
@onready var health_label: Label = $TopLeft/HealthLabel
@onready var invuln_label: Label = $TopLeft/InvulnLabel

@onready var timer_label: Label = $TopCenter/TimerLabel
@onready var score_label: Label = $TopCenter/ScoreLabel
@onready var kill_target_label: Label = $TopCenter/KillTargetLabel

@onready var countdown_label: Label = $Center/CountdownLabel
@onready var result_label: Label = $Center/ResultLabel
@onready var respawn_label: Label = $Center/RespawnLabel

@onready var stats_label: Label = $TopLeft/StatsLabel
@onready var kill_feed_container: VBoxContainer = $TopRight/KillFeed

## References set by Main.
var health_component: HealthComponent
var match_state: MatchStateManager
var hook_system: HookSystem
var score_system: ScoreSystem
var hero_level: HeroLevelSystem
var hero_config: HeroConfig
var player: PlayerController

var _ghost_fill: float = 1.0
var _health_bar_max_width: float = 200.0
var _xp_bar_max_width: float = 200.0
var _timer_pulse_time: float = 0.0
var _low_health_pulse_time: float = 0.0

func _ready() -> void:
	countdown_label.text = ""
	result_label.visible = false
	respawn_label.visible = false
	invuln_label.visible = false
	level_up_label.visible = false
	timer_label.text = ""
	score_label.text = ""
	kill_target_label.text = ""
	stats_label.text = ""
	hero_name_label.text = ""
	level_label.text = "Lv.1"
	xp_bar_fill.size.x = 0

func _process(delta: float) -> void:
	_update_health_bar(delta)
	_update_timer_pulse(delta)
	_update_xp_bar()

## --- Health Bar ---

func _update_health_bar(delta: float) -> void:
	if health_component == null:
		return

	var ratio := health_component.current_health / maxf(health_component.max_health, 1.0)

	# Ghost bar decays toward real health
	_ghost_fill = lerpf(_ghost_fill, ratio, GHOST_DECAY_SPEED * delta)

	# Bar widths
	health_bar.size.x = ratio * _health_bar_max_width
	health_ghost.size.x = _ghost_fill * _health_bar_max_width

	# Color coding
	var bar_color: Color
	if ratio > 0.5:
		bar_color = HEALTH_GREEN
	elif ratio > LOW_HEALTH_THRESHOLD:
		bar_color = HEALTH_YELLOW
	else:
		bar_color = HEALTH_RED
		# Pulse at low health
		_low_health_pulse_time += delta * 4.0
		bar_color.a = 0.7 + 0.3 * sin(_low_health_pulse_time)

	health_bar.color = bar_color

	# Numeric display
	health_label.text = "%d / %d" % [ceili(health_component.current_health), ceili(health_component.max_health)]

	# Invulnerability indicator
	invuln_label.visible = health_component.is_invulnerable

func reset_ghost() -> void:
	_ghost_fill = 1.0

## --- Match Timer ---

func update_timer(time_remaining: float) -> void:
	if match_state == null:
		return
	timer_label.text = match_state.get_time_display()

	# Final countdown styling
	if time_remaining <= FINAL_COUNTDOWN_THRESHOLD and time_remaining > 0:
		timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		timer_label.remove_theme_color_override("font_color")

func _update_timer_pulse(delta: float) -> void:
	if match_state == null:
		return
	if match_state.current_state != MatchStateManager.State.PLAYING:
		return
	if match_state.match_time_remaining <= FINAL_COUNTDOWN_THRESHOLD and match_state.match_time_remaining > 0:
		_timer_pulse_time += delta * 3.0
		timer_label.modulate.a = 0.7 + 0.3 * sin(_timer_pulse_time)
	else:
		timer_label.modulate.a = 1.0
		_timer_pulse_time = 0.0

## --- Scores ---

func update_scores() -> void:
	var kills: Array[int]
	if score_system:
		kills = score_system.team_kills
	elif match_state:
		kills = match_state.team_kills
	else:
		return
	score_label.text = "A: %d    B: %d" % [kills[0], kills[1]]

## --- Countdown ---

func show_countdown(seconds_left: int) -> void:
	countdown_label.text = str(seconds_left)

func show_go() -> void:
	countdown_label.text = "GO!"
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		countdown_label.text = ""
	)

func hide_countdown() -> void:
	countdown_label.text = ""

## --- Match State ---

func on_match_state_changed(new_state: MatchStateManager.State) -> void:
	match new_state:
		MatchStateManager.State.PLAYING:
			show_go()
			if match_state:
				kill_target_label.text = "First to %d" % match_state.kill_target
		MatchStateManager.State.OVERTIME:
			hide_countdown()
			timer_label.text = "OVERTIME"
			timer_label.add_theme_color_override("font_color", Color.RED)
			kill_target_label.text = "NEXT KILL WINS"
			kill_target_label.add_theme_color_override("font_color", Color.RED)
		MatchStateManager.State.ENDED:
			hide_countdown()
			timer_label.text = ""
			timer_label.modulate.a = 1.0
			kill_target_label.text = ""

func show_match_result(winner_team: int, player_team: int) -> void:
	result_label.visible = true
	if winner_team == player_team:
		result_label.text = "VICTORY"
		result_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	elif winner_team < 0:
		result_label.text = "DRAW"
		result_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

## --- Respawn ---

func show_respawn_timer(time_remaining: float) -> void:
	respawn_label.visible = true
	respawn_label.text = "Respawn in %.1f" % time_remaining

func hide_respawn() -> void:
	respawn_label.visible = false

## --- Kill Feed ---

func update_kill_feed(entries: Array[Dictionary]) -> void:
	# Clear existing labels
	for child in kill_feed_container.get_children():
		child.queue_free()

	# Add entries (newest at top)
	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_font_size_override("font_size", 14)

		if entry["is_suicide"]:
			label.text = "%s died" % entry["victim_name"]
			label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		else:
			label.text = "%s > %s" % [entry["killer_name"], entry["victim_name"]]
			label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

		kill_feed_container.add_child(label)

## --- Kill Streak ---

func show_kill_streak(streak: int) -> void:
	if streak >= 3:
		countdown_label.text = "STREAK x%d!" % streak
		countdown_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			if countdown_label.text.begins_with("STREAK"):
				countdown_label.text = ""
				countdown_label.remove_theme_color_override("font_color")
		)

## --- Hit Marker ---

func show_hit_marker() -> void:
	countdown_label.text = "HOOKED!"
	countdown_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		if countdown_label.text == "HOOKED!":
			countdown_label.text = ""
			countdown_label.remove_theme_color_override("font_color")
	)

## --- Hero Info ---

func setup_hero_display() -> void:
	if hero_config:
		hero_name_label.text = hero_config.display_name
	update_level_display()

func update_level_display() -> void:
	if hero_level:
		level_label.text = "Lv.%d" % hero_level.current_level

func _update_xp_bar() -> void:
	if hero_level == null:
		return
	xp_bar_fill.size.x = hero_level.get_xp_progress() * _xp_bar_max_width

func show_level_up(new_level: int) -> void:
	update_level_display()
	level_up_label.text = "LEVEL %d" % new_level
	level_up_label.visible = true
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		level_up_label.visible = false
	)

## --- Hook Stats ---

func update_hook_stats() -> void:
	if hook_system == null:
		return
	var acc := "%.0f" % (float(hook_system.hooks_hit) / maxf(hook_system.hooks_fired, 1) * 100)
	stats_label.text = "Fired: %d | Hit: %d | Miss: %d | Acc: %s%%" % [
		hook_system.hooks_fired, hook_system.hooks_hit, hook_system.hooks_missed, acc
	]
