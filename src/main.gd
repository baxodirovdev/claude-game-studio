## Main game scene — wires all systems together.
##
## Owns the game loop and coordinates communication between systems.
## Each system is a child node referenced here. Main handles setup and signal routing.
class_name Main
extends Node3D

@onready var input_manager: InputManager = $InputManager
@onready var arena: Arena = $Arena
@onready var game_camera: GameCamera = $GameCamera
@onready var player: PlayerController = $Player
@onready var hook_system: HookSystem = $Player/HookSystem
@onready var light: DirectionalLight3D = $DirectionalLight
@onready var match_state: MatchStateManager = $MatchStateManager
@onready var respawn_system: RespawnSystem = $RespawnSystem
@onready var hazard_system: HazardSystem = $HazardSystem
@onready var score_system: ScoreSystem = $ScoreSystem
@onready var hero_level: HeroLevelSystem = $HeroLevelSystem
@onready var hud: GameHUD = $GameHUD
@onready var hero_select: HeroSelect = $HeroSelect
@onready var match_results: MatchResults = $MatchResults
@onready var vfx_system: VFXSystem = $VFXSystem
@onready var audio_system: AudioSystem = $AudioSystem

## Hero config resource — all per-hero tuning values.
@export var hero_config: HeroConfig
## Match config resource — all match-level tuning values.
@export var match_config: MatchConfig

# Dummy targets for testing (replaced by real players in multiplayer)
var _targets: Array[Node3D] = []
var _kill_streak: int = 0

func _ready() -> void:
	# Load default configs if not assigned in editor
	if hero_config == null:
		hero_config = preload("res://data/heroes/vex.tres")
	if match_config == null:
		match_config = preload("res://data/config/default_match.tres")

	arena.arena_ready.connect(_on_arena_ready)
	input_manager.hook_fire_requested.connect(_on_hook_fire_requested)

	# Apply hero config to player
	player.move_speed = hero_config.move_speed
	var player_health: HealthComponent = player.get_node("HealthComponent")
	player_health.max_health = hero_config.max_health
	player_health.current_health = hero_config.max_health

	# Apply hero color
	var player_mesh: MeshInstance3D = player.get_node("MeshInstance3D")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hero_config.hero_color
	player_mesh.material_override = mat

	# Wire hook system and apply hero config
	hook_system.player = player
	hook_system.input_manager = input_manager
	hook_system.arena = arena
	hook_system.hook_speed = hero_config.hook_speed
	hook_system.hook_return_speed = hero_config.hook_return_speed
	hook_system.hook_range = hero_config.hook_range
	hook_system.hook_damage = hero_config.hook_damage
	hook_system.hook_cooldown = hero_config.hook_cooldown
	hook_system.hook_hitbox_radius = hero_config.hook_hitbox_radius
	hook_system.pull_duration = hero_config.pull_duration
	hook_system.hero_config = hero_config

	# Wire player
	player.input_manager = input_manager

	# Wire input cooldown from config
	input_manager.set_hook_cooldown(hero_config.hook_cooldown)

	# Wire hero level system
	hero_level.hero_config = hero_config
	hero_level.level_up.connect(_on_level_up)

	# Connect hook events for HUD stats, XP, and VFX
	hook_system.hook_hit.connect(_on_hook_hit)
	hook_system.hook_missed.connect(func() -> void:
		hud.update_hook_stats()
		if audio_system:
			audio_system.play_hook_miss(hero_config.hook_type)
	)
	hook_system.hook_fired.connect(_on_hook_fired)
	hook_system.target_killed.connect(_on_target_killed)

	# Wire match state manager and apply match config
	match_state.input_manager = input_manager
	match_state.players = [player]
	match_state.countdown_duration = match_config.countdown_duration
	match_state.match_duration = match_config.match_duration
	match_state.ended_display_duration = match_config.ended_display_duration
	match_state.kill_target = match_config.kill_target
	match_state.countdown_tick.connect(_on_countdown_tick)
	match_state.match_timer_updated.connect(_on_match_timer_updated)
	match_state.match_state_changed.connect(_on_match_state_changed)
	match_state.match_ended.connect(_on_match_ended)

	# Wire respawn system and apply match config
	respawn_system.arena = arena
	respawn_system.match_state = match_state
	respawn_system.game_camera = game_camera
	respawn_system.base_respawn_time = match_config.base_respawn_time
	respawn_system.overtime_penalty = match_config.overtime_penalty
	respawn_system.invulnerability_duration = match_config.invulnerability_duration
	respawn_system.register_player(player)
	respawn_system.respawn_timer_tick.connect(_on_respawn_timer_tick)
	respawn_system.player_respawned.connect(_on_player_respawned)

	# Wire score system
	score_system.register_player(player)
	score_system.kill_occurred.connect(_on_kill_occurred)
	score_system.kill_feed_updated.connect(_on_kill_feed_updated)
	score_system.assist_awarded.connect(_on_assist_awarded)

	# Wire hazard system and apply match config
	hazard_system.arena = arena
	hazard_system.match_state = match_state
	hazard_system.spike_base_damage = match_config.spike_base_damage
	hazard_system.spike_cooldown_duration = match_config.spike_cooldown_duration
	hazard_system.spike_scaling_per_minute = match_config.spike_scaling_per_minute
	hazard_system.register_player(player)

	# Wire HUD
	hud.health_component = player_health
	hud.match_state = match_state
	hud.hook_system = hook_system
	hud.score_system = score_system
	hud.hero_level = hero_level
	hud.hero_config = hero_config
	hud.player = player
	hud.setup_hero_display()

	# Wire match results screen
	match_results.score_system = score_system
	match_results.hook_system = hook_system
	match_results.hero_config = hero_config
	match_results.player = player
	match_results.match_config = match_config
	match_results.play_again_requested.connect(_on_play_again)

func _on_arena_ready() -> void:
	# Place player at middle Team A spawn
	var spawns := arena.get_spawn_points(0)
	if spawns.size() > 0:
		player.global_position = spawns[2]

	# Initialize camera
	game_camera.follow_target = player
	game_camera.initialize()

	# Connect player death to respawn flow, score tracking, VFX, and audio
	player.get_node("HealthComponent").died.connect(
		func(victim: Node, killer: Node, dtype: String) -> void:
			if vfx_system:
				vfx_system.spawn_death_effect(player.global_position, hero_config.hero_color)
			if audio_system:
				audio_system.play_death()
			score_system.record_kill(victim, killer, dtype)
			player.kill(killer, dtype)
	)

	# Activate player (visible but input controlled by match state)
	player.activate()

	# Spawn dummy targets on the enemy side
	_spawn_dummy_targets()

	# Show hero selection — match starts after pick
	hero_select.hero_selected.connect(_on_hero_selected)
	hero_select.show_selection()

func _on_hero_selected(config: HeroConfig) -> void:
	_apply_hero_config(config)
	match_state.start_match()

func _apply_hero_config(config: HeroConfig) -> void:
	hero_config = config

	# Apply to player
	player.move_speed = config.move_speed
	var health: HealthComponent = player.get_node("HealthComponent")
	health.max_health = config.max_health
	health.current_health = config.max_health

	# Apply hero color
	var player_mesh: MeshInstance3D = player.get_node("MeshInstance3D")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = config.hero_color
	player_mesh.material_override = mat

	# Apply to hook system
	hook_system.hook_speed = config.hook_speed
	hook_system.hook_return_speed = config.hook_return_speed
	hook_system.hook_range = config.hook_range
	hook_system.hook_damage = config.hook_damage
	hook_system.hook_cooldown = config.hook_cooldown
	hook_system.hook_hitbox_radius = config.hook_hitbox_radius
	hook_system.pull_duration = config.pull_duration
	hook_system.hero_config = config

	# Apply to input
	input_manager.set_hook_cooldown(config.hook_cooldown)

	# Apply to hero level system
	hero_level.hero_config = config
	hero_level.reset()

	# Update HUD and results
	hud.health_component = health
	hud.hero_config = config
	hud.setup_hero_display()
	match_results.hero_config = config

func _on_hook_fire_requested(facing_angle: float) -> void:
	hook_system.fire(facing_angle)

func _on_hook_fired() -> void:
	# Attach per-hero trail particles to active projectile
	if hook_system._active_projectile and vfx_system:
		vfx_system.attach_hero_hook_trail(hook_system._active_projectile, hero_config)
	if audio_system:
		audio_system.play_hook_fire(hero_config.hook_type)

func _on_hook_hit(_target: Node3D) -> void:
	hud.update_hook_stats()
	hud.show_hit_marker()
	hero_level.add_xp(hero_config.xp_on_hook_hit)
	game_camera.shake(0.15)
	# Per-hero hit flash + sound
	if vfx_system:
		vfx_system.spawn_hero_hit_flash(_target.global_position, hero_config)
	if audio_system:
		audio_system.play_hook_hit(hero_config.hook_type)

func _on_level_up(new_level: int) -> void:
	# Apply new stats from level bonuses
	player.move_speed = hero_level.get_effective_stat("move_speed")
	hook_system.hook_damage = hero_level.get_effective_stat("hook_damage")
	hook_system.hook_range = hero_level.get_effective_stat("hook_range")
	hud.show_level_up(new_level)

func _on_target_killed(target: Node3D, _damage_type: String) -> void:
	# XP for kill and streak
	hero_level.add_xp(hero_config.xp_on_kill)
	game_camera.shake(0.3)
	_kill_streak += 1
	hud.show_kill_announcement(_kill_streak)
	if audio_system:
		audio_system.play_kill(hud._multi_kill_count)
		if _kill_streak >= 3:
			audio_system.play_streak(_kill_streak)
	if vfx_system:
		vfx_system.spawn_death_effect(target.global_position, Color.ORANGE)

	# Route kill through score system
	score_system.record_target_kill(player.team_id)
	score_system._add_feed_entry(player, target, _damage_type)
	hud.update_scores()

	# Hide target, respawn after 3 seconds (only if match still playing)
	target.visible = false
	var col := target.get_node_or_null("CollisionShape3D")
	if col:
		col.disabled = true
	var t := target
	var ms := match_state
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(t) and ms.current_state == MatchStateManager.State.PLAYING:
			t.visible = true
			t.global_position = t.get_meta("spawn_pos")
			var c := t.get_node_or_null("CollisionShape3D")
			if c:
				c.disabled = false
	)

func _spawn_dummy_targets() -> void:
	var positions := [
		Vector3(12, 0.8, -6),
		Vector3(15, 0.8, 0),
		Vector3(12, 0.8, 6),
	]
	for i in range(positions.size()):
		var target := _create_target(positions[i])
		target.name = "Target_%d" % i
		target.set_meta("spawn_pos", positions[i])
		target.add_to_group("hookable")
		add_child(target)
		target.global_position = positions[i]
		_targets.append(target)

func _on_countdown_tick(seconds_left: int) -> void:
	hud.show_countdown(seconds_left)
	if audio_system:
		audio_system.play_countdown_beep()

func _on_match_state_changed(new_state: MatchStateManager.State) -> void:
	hud.on_match_state_changed(new_state)
	match new_state:
		MatchStateManager.State.PLAYING:
			hazard_system.activate()
			if audio_system:
				audio_system.play_match_start()
				audio_system.start_ambient()
		MatchStateManager.State.OVERTIME:
			if audio_system:
				audio_system.set_overtime_ambient()
		MatchStateManager.State.ENDED:
			hazard_system.deactivate()
			if audio_system:
				audio_system.stop_ambient()

func _on_match_timer_updated(time_remaining: float) -> void:
	# Sync score system kills to match state for timer-based win check
	match_state.team_kills = score_system.team_kills
	hud.update_timer(time_remaining)
	hud.update_scores()

func _on_respawn_timer_tick(respawn_player: PlayerController, time_remaining: float) -> void:
	if respawn_player == player:
		hud.show_respawn_timer(time_remaining)

func _on_player_respawned(respawn_player: PlayerController) -> void:
	if respawn_player == player:
		hud.hide_respawn()
		hud.reset_ghost()
	hazard_system.clear_cooldowns_for(respawn_player)
	if audio_system:
		audio_system.play_respawn()
	# Respawn VFX
	if vfx_system:
		vfx_system.spawn_respawn_effect(respawn_player, hero_config.hero_color)
		vfx_system.start_invuln_glow(respawn_player, hero_config.hero_color,
			match_config.invulnerability_duration)

func _on_kill_occurred(killer_team: int, team_kills_arr: Array[int]) -> void:
	# Forward to match state for win condition check (handles both PLAYING and OVERTIME)
	match_state.team_kills = team_kills_arr
	if match_state.current_state == MatchStateManager.State.OVERTIME:
		# In overtime, any kill creating a lead ends the match
		if team_kills_arr[0] != team_kills_arr[1]:
			var winner := 0 if team_kills_arr[0] > team_kills_arr[1] else 1
			match_state._end_match(winner, "overtime")
	elif match_state.kill_target > 0 and team_kills_arr[killer_team] >= match_state.kill_target:
		match_state._end_match(killer_team, "kill_target")
	hud.update_scores()

func _on_assist_awarded(assister: Node) -> void:
	if assister == player:
		hero_level.add_xp(hero_config.xp_on_assist)
		hud.show_assist()

func _on_kill_feed_updated(entries: Array[Dictionary]) -> void:
	hud.update_kill_feed(entries)

func _on_match_ended(winner_team: int, _reason: String) -> void:
	hud.show_match_result(winner_team, player.team_id)
	score_system.freeze()
	# Show full results after brief delay for the victory/defeat text
	get_tree().create_timer(match_config.ended_display_duration).timeout.connect(func() -> void:
		hud.result_label.visible = false
		match_results.show_results(winner_team, player.team_id)
	)

func _on_play_again() -> void:
	# Reset score system
	score_system._frozen = false
	score_system.team_kills = [0, 0]
	for pid: int in score_system.player_stats:
		var stats: Dictionary = score_system.player_stats[pid]
		stats["kills"] = 0
		stats["deaths"] = 0
		stats["assists"] = 0
		stats["streak"] = 0
		stats["best_streak"] = 0

	# Reset hook stats
	hook_system.hooks_fired = 0
	hook_system.hooks_hit = 0
	hook_system.hooks_missed = 0

	# Reset match state
	match_state.team_kills = [0, 0]

	# Reset player
	var health: HealthComponent = player.get_node("HealthComponent")
	health.restore_full()
	player.activate()
	_kill_streak = 0

	# Reset HUD
	hud.update_scores()
	hud.update_hook_stats()
	hud.result_label.visible = false

	# Reset dummy targets
	for target: Node3D in _targets:
		if is_instance_valid(target):
			target.visible = true
			target.global_position = target.get_meta("spawn_pos")
			var col := target.get_node_or_null("CollisionShape3D")
			if col:
				col.disabled = false
			var target_health: HealthComponent = target.get_node_or_null("HealthComponent")
			if target_health:
				target_health.restore_full()

	# Show hero select to start new match
	hero_select.show_selection()

func _create_target(pos: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()

	# Collision
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	col.shape = capsule
	body.add_child(col)

	# Visual
	var mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.4
	capsule_mesh.height = 1.6
	mesh.mesh = capsule_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.ORANGE
	mesh.material_override = mat
	body.add_child(mesh)

	# Health component (so hooks can damage them)
	var health := HealthComponent.new()
	health.max_health = hero_config.max_health
	health.name = "HealthComponent"
	body.add_child(health)

	# Connect death
	health.died.connect(func(victim: Node, killer: Node, dtype: String) -> void:
		hook_system.target_killed.emit(victim, dtype)
	)

	# Enemy health bar
	var health_bar := EnemyHealthBar.new()
	health_bar.health_component = health
	body.add_child(health_bar)

	return body
