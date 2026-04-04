## Lobby Screen — host/join UI with hero selection and ready state.
##
## Handles LAN game setup: host creates a game (displays IP), client enters IP to join.
## Both players select heroes and ready up. Match starts when all ready.
## Implements ADR-001 lobby requirements (Sprint 3).
class_name LobbyScreen
extends CanvasLayer

signal match_start_requested(player_configs: Dictionary)

## References set by Main/Menu.
var network_manager: Node  # NetworkManager autoload

## Hero config resources.
var _hero_configs: Dictionary = {}

@onready var main_panel: PanelContainer = $MainPanel
@onready var host_button: Button = $MainPanel/VBox/HostButton
@onready var join_button: Button = $MainPanel/VBox/JoinButton
@onready var ip_input: LineEdit = $MainPanel/VBox/IPInput
@onready var status_label: Label = $MainPanel/VBox/StatusLabel
@onready var back_button: Button = $MainPanel/VBox/BackButton

@onready var lobby_panel: PanelContainer = $LobbyPanel
@onready var ip_display_label: Label = $LobbyPanel/VBox/IPDisplayLabel
@onready var player_list: VBoxContainer = $LobbyPanel/VBox/PlayerList
@onready var hero_select_container: HBoxContainer = $LobbyPanel/VBox/HeroSelect
@onready var vex_button: Button = $LobbyPanel/VBox/HeroSelect/VexButton
@onready var lash_button: Button = $LobbyPanel/VBox/HeroSelect/LashButton
@onready var maw_button: Button = $LobbyPanel/VBox/HeroSelect/MawButton
@onready var ready_button: Button = $LobbyPanel/VBox/ReadyButton
@onready var start_label: Label = $LobbyPanel/VBox/StartLabel
@onready var disconnect_button: Button = $LobbyPanel/VBox/DisconnectButton

var _selected_hero_path: String = "res://data/heroes/pudge.tres"
var _is_ready: bool = false

func _ready() -> void:
	visible = false
	lobby_panel.visible = false

	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	ready_button.pressed.connect(_on_ready_pressed)

	vex_button.pressed.connect(func() -> void: _select_hero("res://data/heroes/pudge.tres"))
	lash_button.pressed.connect(func() -> void: _select_hero("res://data/heroes/lash.tres"))
	maw_button.pressed.connect(func() -> void: _select_hero("res://data/heroes/maw.tres"))

## Show the lobby screen.
func show_lobby() -> void:
	visible = true
	main_panel.visible = true
	lobby_panel.visible = false
	status_label.text = ""
	ip_input.text = ""
	_is_ready = false

func hide_lobby() -> void:
	visible = false

func _on_host_pressed() -> void:
	if network_manager == null:
		status_label.text = "Network manager not available"
		return

	var err := network_manager.host_game()
	if err != OK:
		status_label.text = "Failed to host: error %d" % err
		return

	# Connect network signals
	_connect_network_signals()

	# Show lobby panel
	main_panel.visible = false
	lobby_panel.visible = true
	ip_display_label.text = "Your IP: %s  Port: %d" % [_get_local_ip(), NetworkManager.DEFAULT_PORT]
	start_label.text = "Waiting for player to join..."
	_update_player_list()

func _on_join_pressed() -> void:
	if network_manager == null:
		status_label.text = "Network manager not available"
		return

	var address := ip_input.text.strip_edges()
	if address.is_empty():
		status_label.text = "Enter host IP address"
		return

	status_label.text = "Connecting to %s..." % address
	var err := network_manager.join_game(address)
	if err != OK:
		status_label.text = "Failed to connect: error %d" % err
		return

	_connect_network_signals()

func _on_back_pressed() -> void:
	if network_manager:
		network_manager.disconnect_game()
	visible = false

func _on_disconnect_pressed() -> void:
	if network_manager:
		network_manager.disconnect_game()
	show_lobby()

func _on_ready_pressed() -> void:
	_is_ready = not _is_ready
	ready_button.text = "UNREADY" if _is_ready else "READY"

	if network_manager:
		network_manager.set_player_ready.rpc(network_manager.local_peer_id, _is_ready)
		network_manager.set_player_hero.rpc(network_manager.local_peer_id, _selected_hero_path)

	_update_player_list()
	_check_all_ready()

func _select_hero(config_path: String) -> void:
	_selected_hero_path = config_path

	# Highlight selected button
	vex_button.modulate = Color.WHITE
	lash_button.modulate = Color.WHITE
	maw_button.modulate = Color.WHITE
	match config_path:
		"res://data/heroes/pudge.tres":
			vex_button.modulate = Color(0.5, 1.0, 0.5)
		"res://data/heroes/lash.tres":
			lash_button.modulate = Color(0.5, 1.0, 0.5)
		"res://data/heroes/maw.tres":
			maw_button.modulate = Color(0.5, 1.0, 0.5)

	# Sync to all peers
	if network_manager:
		network_manager.set_player_hero.rpc(network_manager.local_peer_id, config_path)

func _connect_network_signals() -> void:
	if network_manager.player_joined.is_connected(_on_player_joined):
		return
	network_manager.player_joined.connect(_on_player_joined)
	network_manager.player_left.connect(_on_player_left)
	network_manager.connection_succeeded.connect(_on_connection_succeeded)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.server_disconnected.connect(_on_server_disconnected)

func _on_player_joined(_peer_id: int) -> void:
	start_label.text = "Player joined! Select heroes and ready up."
	_update_player_list()

func _on_player_left(_peer_id: int) -> void:
	start_label.text = "Player disconnected. Waiting for player..."
	_is_ready = false
	ready_button.text = "READY"
	_update_player_list()

func _on_connection_succeeded() -> void:
	main_panel.visible = false
	lobby_panel.visible = true
	ip_display_label.text = "Connected to host"
	start_label.text = "Select hero and ready up."
	_update_player_list()

func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Check IP and try again."

func _on_server_disconnected() -> void:
	show_lobby()
	status_label.text = "Host disconnected."

func _update_player_list() -> void:
	for child in player_list.get_children():
		child.queue_free()

	if network_manager == null:
		return

	for pid: int in network_manager.player_info:
		var info: Dictionary = network_manager.player_info[pid]
		var label := Label.new()
		var team_name: String = "Team A" if (info.get("team_id", 0) as int) == 0 else "Team B"
		var ready_text: String = " [READY]" if info.get("ready", false) else ""
		var hero_name: String = _hero_path_to_name(info.get("hero_config_path", "") as String)
		var is_local := " (You)" if pid == network_manager.local_peer_id else ""
		label.text = "Player %d%s — %s — %s%s" % [pid, is_local, team_name, hero_name, ready_text]
		label.add_theme_font_size_override("font_size", 16)
		player_list.add_child(label)

func _check_all_ready() -> void:
	if network_manager == null:
		return
	if not network_manager.is_server():
		return  # Only host starts the match
	if not network_manager.all_players_ready():
		return

	# All ready — start countdown
	start_label.text = "Starting match..."
	var configs: Dictionary = {}
	for pid: int in network_manager.player_info:
		var info: Dictionary = network_manager.player_info[pid]
		configs[pid] = {
			"hero_config_path": info.get("hero_config_path", "res://data/heroes/pudge.tres"),
			"team_id": info.get("team_id", 0),
		}

	# Brief delay then start
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		lobby_panel.visible = false
		visible = false
		match_start_requested.emit(configs)
	)

func _hero_path_to_name(path: String) -> String:
	match path:
		"res://data/heroes/pudge.tres":
			return "Pudge"
		_:
			return "Pudge"

func _get_local_ip() -> String:
	var addresses := IP.get_local_addresses()
	for addr: String in addresses:
		# Filter to LAN IPv4 addresses
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	if addresses.size() > 0:
		return addresses[0]
	return "127.0.0.1"
