## Matchmaking — auto-match queue via WebSocket relay server.
##
## "Find Match" connects to relay, enters queue. Server pairs two queued players
## into a room. Falls back to "no players found" after timeout.
## Sprint 7 S7-05.
class_name Matchmaking
extends Node

signal match_found(room_code: String, is_host: bool)
signal match_search_failed(reason: String)
signal search_status_updated(message: String)

## Relay server address (configurable).
var relay_address: String = "127.0.0.1"
var relay_port: int = 9998

var _searching: bool = false
var _search_timer: float = 0.0
var _timeout: float = 30.0
var _peer: WebSocketMultiplayerPeer

func _ready() -> void:
	set_process(false)

## Start searching for a match.
func find_match(timeout: float = 30.0) -> void:
	if _searching:
		return

	_timeout = timeout
	_search_timer = 0.0
	_searching = true

	search_status_updated.emit("Connecting to matchmaking server...")

	_peer = WebSocketMultiplayerPeer.new()
	var url := "ws://%s:%d" % [relay_address, relay_port]
	var err: Error = _peer.create_client(url)
	if err != OK:
		_fail("Failed to connect to matchmaking server")
		return

	multiplayer.multiplayer_peer = _peer
	multiplayer.connected_to_server.connect(_on_connected, CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(_on_connection_failed, CONNECT_ONE_SHOT)

	set_process(true)

## Cancel the search.
func cancel_search() -> void:
	_searching = false
	set_process(false)
	if _peer:
		multiplayer.multiplayer_peer = null
		_peer = null
	search_status_updated.emit("Search cancelled")

func _process(delta: float) -> void:
	if not _searching:
		return
	_search_timer += delta
	var remaining := ceili(_timeout - _search_timer)
	search_status_updated.emit("Searching for opponent... (%ds)" % remaining)

	if _search_timer >= _timeout:
		_fail("No opponent found. Try again later.")

func _on_connected() -> void:
	search_status_updated.emit("Connected! Entering queue...")
	# Request to enter matchmaking queue
	request_queue.rpc_id(1)

func _on_connection_failed() -> void:
	_fail("Could not connect to matchmaking server")

## Request to join the matchmaking queue (sent to relay server).
@rpc("any_peer", "reliable")
func request_queue() -> void:
	# Server-side: handled by relay server's matchmaking extension
	pass

## Server notifies client that a match was found.
@rpc("authority", "reliable")
func queue_match_found(room_code: String, as_host: bool) -> void:
	_searching = false
	set_process(false)
	search_status_updated.emit("Match found!")
	match_found.emit(room_code, as_host)

## Server notifies client that queue failed.
@rpc("authority", "reliable")
func queue_failed(reason: String) -> void:
	_fail(reason)

func _fail(reason: String) -> void:
	_searching = false
	set_process(false)
	if _peer:
		multiplayer.multiplayer_peer = null
		_peer = null
	match_search_failed.emit(reason)
	search_status_updated.emit(reason)
