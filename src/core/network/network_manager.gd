## Network Manager — manages multiplayer peer lifecycle, connections, and session info.
##
## Autoload singleton. Handles ENet (LAN) and WebSocket (online) peer creation.
## Tracks connected players and emits signals for lobby and game systems.
## Implements ADR-001.
## Registered as autoload — no class_name to avoid singleton name conflict.
extends Node

signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal connection_succeeded
signal connection_failed
signal server_disconnected
signal room_code_received(code: String)

enum Mode { OFFLINE, LAN, ONLINE }

## Default port for LAN games.
const DEFAULT_PORT: int = 9999
## Default relay server port.
const RELAY_PORT: int = 9998
## Maximum players (2 for now — expandable later).
const MAX_PLAYERS: int = 2

## Current connection mode.
var mode: Mode = Mode.OFFLINE
## Room code for online mode.
var room_code: String = ""

## Local peer ID (1 = server, >1 = client).
var local_peer_id: int = 0
## Connected peer IDs (does NOT include local peer).
var connected_peers: Array[int] = []
## True if this instance is hosting.
var is_hosting: bool = false

## Player info per peer: { peer_id: { "hero_config_path": String, "team_id": int, "ready": bool } }
var player_info: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Host a LAN game on the given port. Returns OK or error.
func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_hosting = true
	local_peer_id = 1
	mode = Mode.LAN
	player_info[1] = {"hero_config_path": "", "team_id": 0, "ready": false}
	return OK

## Join a LAN game at the given address and port.
func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_hosting = false
	mode = Mode.LAN
	return OK

## Host an online game via WebSocket relay. Connects to relay and creates a room.
func host_online(relay_address: String, relay_port: int = RELAY_PORT) -> Error:
	var peer := WebSocketMultiplayerPeer.new()
	var url := "ws://%s:%d" % [relay_address, relay_port]
	var err := peer.create_client(url)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_hosting = true
	mode = Mode.ONLINE
	# Room creation happens after connection succeeds
	return OK

## Join an online game via WebSocket relay with a room code.
func join_online(relay_address: String, code: String, relay_port: int = RELAY_PORT) -> Error:
	var peer := WebSocketMultiplayerPeer.new()
	var url := "ws://%s:%d" % [relay_address, relay_port]
	var err := peer.create_client(url)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_hosting = false
	mode = Mode.ONLINE
	room_code = code
	# Join request happens after connection succeeds
	return OK

## Disconnect and reset to offline state.
func disconnect_game() -> void:
	multiplayer.multiplayer_peer = null
	is_hosting = false
	local_peer_id = 0
	mode = Mode.OFFLINE
	room_code = ""
	connected_peers.clear()
	player_info.clear()

## Check if we are the server (host).
func is_server() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()

## Get all peer IDs including local.
func get_all_peer_ids() -> Array[int]:
	var all: Array[int] = [local_peer_id]
	all.append_array(connected_peers)
	return all

## Get the total player count.
func get_player_count() -> int:
	if multiplayer.multiplayer_peer == null:
		return 1  # Single player
	return connected_peers.size() + 1

## Set local player's hero config path and sync to all peers.
@rpc("any_peer", "call_local", "reliable")
func set_player_hero(peer_id: int, config_path: String) -> void:
	if player_info.has(peer_id):
		player_info[peer_id]["hero_config_path"] = config_path

## Set local player's ready state and sync.
@rpc("any_peer", "call_local", "reliable")
func set_player_ready(peer_id: int, ready: bool) -> void:
	if player_info.has(peer_id):
		player_info[peer_id]["ready"] = ready

## Check if all players are ready.
func all_players_ready() -> bool:
	for pid: int in player_info:
		if not player_info[pid].get("ready", false):
			return false
	return player_info.size() >= 2

func _on_peer_connected(id: int) -> void:
	connected_peers.append(id)
	# Assign team: host = team 0, first client = team 1
	var team: int = 1 if connected_peers.size() == 1 else connected_peers.size() % 2
	player_info[id] = {"hero_config_path": "", "team_id": team, "ready": false}
	player_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)
	player_info.erase(id)
	player_left.emit(id)

func _on_connected_to_server() -> void:
	local_peer_id = multiplayer.get_unique_id()
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	is_hosting = false
	connected_peers.clear()
	player_info.clear()
	server_disconnected.emit()
