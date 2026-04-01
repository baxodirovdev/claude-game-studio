## Hazard System — detects player overlap with arena hazard zones and applies damage.
##
## Checks all registered players against arena hazard data each physics frame.
## Gap/pit = instant kill. Spikes = burst damage with per-player cooldown.
## Active only during PLAYING match state.
## Implements GDD: design/gdd/map-hazards.md (basic Sprint 1 subset).
class_name HazardSystem
extends Node

signal hazard_triggered(type: String, position: Vector3, victim: Node)

## Spike damage tuning.
@export var spike_base_damage: float = 30.0
@export var spike_cooldown_duration: float = 1.0
@export var spike_scaling_per_minute: float = 0.05

## References set by Main.
var arena: Arena
var match_state: MatchStateManager
var players: Array[PlayerController] = []

## Per-player spike cooldown tracking: { player_instance_id: float (timestamp) }
var _spike_cooldowns: Dictionary = {}

func _ready() -> void:
	set_physics_process(false)

## Register a player for hazard detection.
func register_player(player: PlayerController) -> void:
	players.append(player)

## Start hazard detection (called when match enters PLAYING).
func activate() -> void:
	set_physics_process(true)

## Stop hazard detection (called when match ends).
func deactivate() -> void:
	set_physics_process(false)
	_spike_cooldowns.clear()

func _physics_process(_delta: float) -> void:
	if match_state == null:
		return
	if match_state.current_state != MatchStateManager.State.PLAYING:
		return
	if arena == null:
		return

	var current_time := Time.get_ticks_msec() / 1000.0

	for player in players:
		if not is_instance_valid(player):
			continue
		if player.state == PlayerController.State.DEAD or player.state == PlayerController.State.INACTIVE:
			continue

		var pos := player.global_position
		_check_gap(player, pos)
		_check_pits(player, pos)
		_check_spikes(player, pos, current_time)

func _check_gap(player: PlayerController, pos: Vector3) -> void:
	if arena.is_in_gap(pos):
		var health := _find_health(player)
		if health and not health.is_dead:
			health.take_damage(999999, null, "HAZARD_INSTANT_KILL")
			hazard_triggered.emit("gap", pos, player)

func _check_pits(player: PlayerController, pos: Vector3) -> void:
	if arena.is_in_pit(pos):
		var health := _find_health(player)
		if health and not health.is_dead:
			health.take_damage(999999, null, "HAZARD_INSTANT_KILL")
			hazard_triggered.emit("pit", pos, player)

func _check_spikes(player: PlayerController, pos: Vector3, current_time: float) -> void:
	var spike_pos: Variant = arena.get_spike_zone_at(pos)
	if spike_pos == null:
		return

	var health := _find_health(player)
	if health == null or health.is_dead:
		return

	# Per-player cooldown check
	var pid := player.get_instance_id()
	if _spike_cooldowns.has(pid):
		if current_time - _spike_cooldowns[pid] < spike_cooldown_duration:
			return

	# Calculate scaled spike damage
	var damage := _get_spike_damage()

	health.take_damage(damage, null, "HAZARD_SPIKE")
	_spike_cooldowns[pid] = current_time
	hazard_triggered.emit("spike", spike_pos, player)

func _get_spike_damage() -> float:
	if match_state == null:
		return spike_base_damage
	var elapsed := match_state.match_duration - match_state.match_time_remaining
	var minutes := elapsed / 60.0
	return spike_base_damage * (1.0 + spike_scaling_per_minute * minutes)

## Clear cooldown for a player (called on respawn).
func clear_cooldowns_for(player: PlayerController) -> void:
	var pid := player.get_instance_id()
	_spike_cooldowns.erase(pid)

func _find_health(node: Node) -> HealthComponent:
	for child in node.get_children():
		if child is HealthComponent:
			return child as HealthComponent
	return null
