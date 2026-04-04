## WebSocket Relay Server — forwards packets between paired clients.
##
## Run as a standalone Godot scene (tools/relay/relay_server.tscn).
## Clients connect, create or join rooms via room codes, and all packets
## are forwarded to the other peer(s) in the same room.
## Implements ADR-001 online multiplayer path.
class_name RelayServer
extends Node

const DEFAULT_PORT: int = 9998
const ROOM_CODE_LENGTH: int = 4
const MAX_ROOMS: int = 100

var _server: WebSocketMultiplayerPeer
var _tcp_server: TCPServer

## Room storage: { code: { "host_id": int, "clients": Array[int] } }
var _rooms: Dictionary = {}
## Peer-to-room mapping: { peer_id: room_code }
var _peer_rooms: Dictionary = {}

@onready var status_label: Label = $StatusLabel
@onready var log_label: RichTextLabel = $LogLabel

func _ready() -> void:
	_start_server()

func _start_server() -> void:
	_server = WebSocketMultiplayerPeer.new()
	var err := _server.create_server(DEFAULT_PORT)
	if err != OK:
		_log("Failed to start relay server on port %d: %s" % [DEFAULT_PORT, error_string(err)])
		return

	multiplayer.multiplayer_peer = _server
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	_log("Relay server started on port %d" % DEFAULT_PORT)
	if status_label:
		status_label.text = "Relay: ONLINE (port %d)" % DEFAULT_PORT

func _on_peer_connected(id: int) -> void:
	_log("Peer %d connected" % id)

func _on_peer_disconnected(id: int) -> void:
	_log("Peer %d disconnected" % id)
	_queue.erase(id)
	_remove_peer_from_room(id)

## --- Room Management RPCs ---

## Client requests to create a room. Server responds with room code.
@rpc("any_peer", "reliable")
func request_create_room() -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	if _rooms.size() >= MAX_ROOMS:
		room_created.rpc_id(peer_id, "")
		return

	var code := _generate_room_code()
	_rooms[code] = {"host_id": peer_id, "clients": []}
	_peer_rooms[peer_id] = code
	_log("Room %s created by peer %d" % [code, peer_id])
	room_created.rpc_id(peer_id, code)

## Client requests to join a room by code.
@rpc("any_peer", "reliable")
func request_join_room(code: String) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	if not _rooms.has(code):
		join_result.rpc_id(peer_id, false, "Room not found")
		return

	var room: Dictionary = _rooms[code]
	if room["clients"].size() >= 1:  # 2-player max (host + 1 client)
		join_result.rpc_id(peer_id, false, "Room full")
		return

	room["clients"].append(peer_id)
	_peer_rooms[peer_id] = code
	_log("Peer %d joined room %s" % [peer_id, code])

	# Notify both peers
	join_result.rpc_id(peer_id, true, "")
	peer_joined_room.rpc_id(room["host_id"], peer_id)

## Client sends a game packet to forward to room peers.
@rpc("any_peer", "reliable")
func relay_packet(data: PackedByteArray) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	var code: String = _peer_rooms.get(sender_id, "")
	if code == "" or not _rooms.has(code):
		return

	var room: Dictionary = _rooms[code]
	# Forward to all peers in the room except sender
	if sender_id == room["host_id"]:
		for client_id: int in room["clients"]:
			relay_receive.rpc_id(client_id, data, sender_id)
	else:
		relay_receive.rpc_id(room["host_id"], data, sender_id)
		for client_id: int in room["clients"]:
			if client_id != sender_id:
				relay_receive.rpc_id(client_id, data, sender_id)

## Unreliable relay for position updates.
@rpc("any_peer", "unreliable")
func relay_packet_unreliable(data: PackedByteArray) -> void:
	relay_packet(data)

## --- Matchmaking Queue ---

var _queue: Array[int] = []

## Client requests to enter matchmaking queue.
@rpc("any_peer", "reliable")
func request_queue_match() -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id in _queue:
		return
	_queue.append(peer_id)
	_log("Peer %d entered matchmaking queue (size: %d)" % [peer_id, _queue.size()])

	# Try to match
	if _queue.size() >= 2:
		var host_id := _queue.pop_front()
		var client_id := _queue.pop_front()

		# Create room for them
		var code := _generate_room_code()
		_rooms[code] = {"host_id": host_id, "clients": [client_id]}
		_peer_rooms[host_id] = code
		_peer_rooms[client_id] = code

		_log("Matchmaking: paired %d (host) + %d (client) in room %s" % [host_id, client_id, code])

		# Notify both peers
		queue_match_found.rpc_id(host_id, code, true)
		queue_match_found.rpc_id(client_id, code, false)

## Notify client of match found (sent by server).
@rpc("authority", "reliable")
func queue_match_found(_code: String, _as_host: bool) -> void:
	pass  # Client-side handler

## --- Client-side RPCs (called by server on clients) ---

@rpc("authority", "reliable")
func room_created(_code: String) -> void:
	pass  # Client-side handler

@rpc("authority", "reliable")
func join_result(_success: bool, _message: String) -> void:
	pass  # Client-side handler

@rpc("authority", "reliable")
func peer_joined_room(_peer_id: int) -> void:
	pass  # Client-side handler

@rpc("authority", "reliable")
func relay_receive(_data: PackedByteArray, _from_peer: int) -> void:
	pass  # Client-side handler

@rpc("authority", "reliable")
func peer_left_room(_peer_id: int) -> void:
	pass  # Client-side handler

## --- Internal ---

func _remove_peer_from_room(peer_id: int) -> void:
	var code: String = _peer_rooms.get(peer_id, "")
	if code == "" or not _rooms.has(code):
		_peer_rooms.erase(peer_id)
		return

	var room: Dictionary = _rooms[code]
	if room["host_id"] == peer_id:
		# Host left — notify all clients and destroy room
		for client_id: int in room["clients"]:
			peer_left_room.rpc_id(client_id, peer_id)
			_peer_rooms.erase(client_id)
		_rooms.erase(code)
		_log("Room %s closed (host left)" % code)
	else:
		room["clients"].erase(peer_id)
		peer_left_room.rpc_id(room["host_id"], peer_id)
		_log("Peer %d left room %s" % [peer_id, code])

	_peer_rooms.erase(peer_id)

func _generate_room_code() -> String:
	var chars := "ABCDEFGHJKLMNPQRSTUVWXYZ"  # No I or O (confusion with 1 and 0)
	var code := ""
	for i in range(ROOM_CODE_LENGTH):
		code += chars[randi() % chars.length()]
	# Ensure unique
	while _rooms.has(code):
		code = ""
		for i in range(ROOM_CODE_LENGTH):
			code += chars[randi() % chars.length()]
	return code

func _log(msg: String) -> void:
	print("[Relay] %s" % msg)
	if log_label:
		log_label.append_text(msg + "\n")
