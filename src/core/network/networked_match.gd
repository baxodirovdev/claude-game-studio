## Networked Match — coordinates multiplayer game flow on top of existing systems.
##
## Sits between NetworkManager and the gameplay systems (MatchState, Score, Respawn,
## Hook). On the server, it processes authoritative game events and broadcasts via RPCs.
## On clients, it receives state updates and applies them locally.
## Implements ADR-001 networked match flow (Sprint 3 S3-06).
class_name NetworkedMatch
extends Node

signal player_disconnected(peer_id: int, forfeit: bool)
signal opponent_disconnected_display(message: String)

## References set by the scene that owns this node.
var network_manager: NetworkManager
var match_state: MatchStateManager
var score_system: ScoreSystem
var respawn_system: RespawnSystem
var game_session: GameSession

var _sync_timer: float = 0.0
const STATE_SYNC_INTERVAL: float = 1.0

func _ready() -> void:
	set_process(false)

## Start networked match processing. Call after all systems are wired.
func activate() -> void:
	if network_manager == null or match_state == null:
		return

	# Server-side: intercept match events and broadcast
	if network_manager.is_server():
		match_state.countdown_tick.connect(_on_server_countdown_tick)
		match_state.match_ended.connect(_on_server_match_ended)
		match_state.match_state_changed.connect(_on_server_state_changed)

		if score_system:
			score_system.kill_occurred.connect(_on_server_kill_occurred)

		if respawn_system:
			respawn_system.player_respawned.connect(_on_server_player_respawned)

	# Handle disconnects
	network_manager.player_left.connect(_on_player_disconnected)
	network_manager.server_disconnected.connect(_on_server_disconnected)

	set_process(true)

func _process(delta: float) -> void:
	if not network_manager or not network_manager.is_server():
		return

	# Periodic state sync to prevent drift
	_sync_timer += delta
	if _sync_timer >= STATE_SYNC_INTERVAL:
		_sync_timer = 0.0
		_broadcast_state_sync()

## --- Server Event Handlers ---

func _on_server_countdown_tick(seconds_left: int) -> void:
	match_state.sync_countdown.rpc(seconds_left)

func _on_server_match_ended(winner_team: int, reason: String) -> void:
	match_state.sync_match_ended.rpc(winner_team, reason)

func _on_server_state_changed(new_state: MatchStateManager.State) -> void:
	match_state.sync_match_state.rpc(
		new_state as int,
		match_state.match_time_remaining,
		[score_system.team_kills[0], score_system.team_kills[1]] if score_system else [0, 0]
	)

func _on_server_kill_occurred(killer_team: int, team_kills: Array[int]) -> void:
	# The kill was already processed locally on server. Broadcast to clients.
	# Clients receive via score_system.sync_kill RPC
	pass

func _on_server_player_respawned(player: PlayerController) -> void:
	if player == null or not is_instance_valid(player):
		return
	respawn_system.sync_respawn.rpc(
		str(player.get_path()),
		player.global_position
	)

## --- State Sync ---

func _broadcast_state_sync() -> void:
	if match_state == null or score_system == null:
		return
	match_state.sync_match_state.rpc(
		match_state.current_state as int,
		match_state.match_time_remaining,
		[score_system.team_kills[0], score_system.team_kills[1]]
	)

## --- Server-Authoritative Kill Processing ---

## Called when a player dies in networked mode. Server processes and broadcasts.
func server_process_kill(victim: PlayerController, killer: Node, damage_type: String) -> void:
	if not network_manager.is_server():
		return

	# Process locally on server
	score_system.record_kill(victim, killer, damage_type)

	# Broadcast to clients
	var killer_name := killer.name if killer else ""
	var killer_team := -1
	if killer is PlayerController:
		killer_team = (killer as PlayerController).team_id

	score_system.sync_kill.rpc(
		victim.name,
		killer_name,
		damage_type,
		killer_team,
		[score_system.team_kills[0], score_system.team_kills[1]]
	)

## --- Server-Authoritative Hook Hit Processing ---

## Called when a hook hits in networked mode. Server validates and broadcasts.
func server_process_hook_hit(hooker: PlayerController, target: Node3D,
		hook_system_ref: HookSystem) -> void:
	if not network_manager.is_server():
		return
	# Hit was already processed by HookSystem on server.
	# Broadcast the hit result to clients.
	hook_system_ref.notify_hit.rpc(str(target.get_path()))

## --- Disconnect Handling (S3-10) ---

func _on_player_disconnected(peer_id: int) -> void:
	if game_session == null:
		return

	# Remove the disconnected player's node
	var disconnected_player := game_session.get_player(peer_id)
	if disconnected_player != null:
		# Clear any pending respawns
		if respawn_system:
			respawn_system.clear_pending_for(disconnected_player)
		game_session.remove_player(peer_id)

	# Check if any team has 0 players → forfeit
	if network_manager.is_server() and match_state != null:
		if match_state.current_state == MatchStateManager.State.PLAYING or \
				match_state.current_state == MatchStateManager.State.OVERTIME:
			var remaining_players := game_session.get_all_players()
			if remaining_players.is_empty():
				return

			# Find which teams still have players
			var teams_alive: Dictionary = {}
			for p: PlayerController in remaining_players:
				teams_alive[p.team_id] = true

			# If only one team remains, they win by forfeit
			if teams_alive.size() == 1:
				var winner_team: int = teams_alive.keys()[0] as int
				match_state._end_match(winner_team, "forfeit")

	opponent_disconnected_display.emit("Opponent Disconnected")
	player_disconnected.emit(peer_id, true)

func _on_server_disconnected() -> void:
	# Client lost connection to host — match is over
	if match_state:
		match_state._transition_to(MatchStateManager.State.ENDED)
	opponent_disconnected_display.emit("Host Disconnected")
