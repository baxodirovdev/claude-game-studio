## Respawn System — handles death timer, spawn selection, health restore, invulnerability.
##
## One RespawnSystem manages all players. Listens to each player's died signal.
## Coordinates with Arena (spawn points), HealthComponent (restore + invuln),
## PlayerController (reposition + reactivate), Camera (snap), and MatchStateManager
## (block respawns during ENDED).
## Implements GDD: design/gdd/respawn-system.md (basic Sprint 1 subset).
class_name RespawnSystem
extends Node

signal respawn_timer_tick(player: PlayerController, time_remaining: float)
signal player_respawned(player: PlayerController)

## Base respawn wait time in seconds.
@export var base_respawn_time: float = 3.0
## Extra seconds added during overtime.
@export var overtime_penalty: float = 2.0
## Post-respawn invulnerability duration in seconds.
@export var invulnerability_duration: float = 2.0

## References set by Main.
var arena: Arena
var match_state: MatchStateManager
var game_camera: GameCamera

## Active respawn entries: { player: PlayerController, timer: float }
var _pending: Array[Dictionary] = []

func _ready() -> void:
	set_process(false)

## Register a player so their death triggers respawn.
func register_player(player: PlayerController) -> void:
	player.died.connect(_on_player_died)

func _on_player_died(victim: PlayerController, _killer: Node, _damage_type: String) -> void:
	if match_state and match_state.current_state == MatchStateManager.State.ENDED:
		return

	var respawn_time := base_respawn_time
	if match_state and match_state.current_state == MatchStateManager.State.PLAYING:
		# Overtime penalty would apply here when overtime state is added
		pass

	_pending.append({"player": victim, "timer": respawn_time})
	if not is_processing():
		set_process(true)

func _process(delta: float) -> void:
	var i := _pending.size() - 1
	while i >= 0:
		var entry: Dictionary = _pending[i]
		entry["timer"] -= delta
		var player: PlayerController = entry["player"]

		respawn_timer_tick.emit(player, maxf(entry["timer"], 0.0))

		if entry["timer"] <= 0:
			_execute_respawn(player)
			_pending.remove_at(i)
		i -= 1

	if _pending.is_empty():
		set_process(false)

func _execute_respawn(player: PlayerController) -> void:
	if not is_instance_valid(player):
		return

	# Block respawn if match ended while waiting
	if match_state and match_state.current_state == MatchStateManager.State.ENDED:
		return

	# Select spawn point
	var spawn_pos := _select_spawn_point(player.team_id)

	# Reposition
	player.global_position = spawn_pos

	# Restore health
	var health := _find_health(player)
	if health:
		health.restore_full()
		health.grant_invulnerability(invulnerability_duration)

	# Reactivate
	player.activate()

	# Snap camera if this is the followed player
	if game_camera and game_camera.follow_target == player:
		game_camera.snap_to_target()

	player_respawned.emit(player)

func _select_spawn_point(team_id: int) -> Vector3:
	var spawns := arena.get_spawn_points(team_id)
	if spawns.is_empty():
		return Vector3.ZERO

	# Find living enemies to pick safest spawn
	var enemies: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("hookable"):
		if is_instance_valid(node) and node.visible:
			enemies.append(node)

	if enemies.is_empty():
		# No enemies — pick middle spawn
		return spawns[spawns.size() / 2]

	# Pick spawn furthest from nearest enemy
	var best_spawn := spawns[0]
	var best_min_dist := 0.0
	for spawn in spawns:
		var min_dist := INF
		for enemy in enemies:
			var dist := spawn.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
		if min_dist > best_min_dist:
			best_min_dist = min_dist
			best_spawn = spawn

	return best_spawn

func _find_health(node: Node) -> HealthComponent:
	for child in node.get_children():
		if child is HealthComponent:
			return child as HealthComponent
	return null

## Clear a specific player's pending respawn (e.g., disconnect).
func clear_pending_for(player: PlayerController) -> void:
	for i in range(_pending.size() - 1, -1, -1):
		if _pending[i]["player"] == player:
			_pending.remove_at(i)

## --- Networking RPCs ---

## Server notifies all clients of a respawn.
@rpc("authority", "call_local", "reliable")
func sync_respawn(player_path: String, spawn_pos: Vector3) -> void:
	var player := get_node_or_null(player_path) as PlayerController
	if player == null:
		return
	player.global_position = spawn_pos
	var health := _find_health(player)
	if health:
		health.restore_full()
		health.grant_invulnerability(invulnerability_duration)
	player.activate()
	player_respawned.emit(player)
