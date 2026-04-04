## Main Menu — title screen with Play, Settings, and Quit buttons.
##
## Entry point of the game. Navigates to solo play (hero select → game),
## multiplayer (lobby screen), or settings. Uses SceneFlowManager for transitions.
## Sprint 4 S4-01.
class_name MainMenu
extends Control

@onready var title_label: Label = $VBox/TitleLabel
@onready var play_solo_button: Button = $VBox/PlaySoloButton
@onready var play_multi_button: Button = $VBox/PlayMultiButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var settings_panel: Control = $SettingsPanel

func _ready() -> void:
	title_label.text = "HOOK WARS"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", GameThemeGenerator.ACCENT_GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	version_label.text = "v0.4.0-dev"
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	play_solo_button.text = "PLAY SOLO"
	play_multi_button.text = "PLAY MULTIPLAYER"
	settings_button.text = "SETTINGS"
	quit_button.text = "QUIT"

	play_solo_button.pressed.connect(_on_play_solo)
	play_multi_button.pressed.connect(_on_play_multi)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)

	# Hide settings panel initially
	if settings_panel:
		settings_panel.visible = false

	# Wire NetworkManager autoload into LobbyScreen
	var lobby := get_node_or_null("LobbyScreen") as LobbyScreen
	if lobby:
		lobby.network_manager = get_node_or_null("/root/NetworkManager")
		lobby.visible = false

	play_solo_button.grab_focus()

func _on_play_solo() -> void:
	# Go directly to game scene (solo mode with hero select)
	var flow := _get_scene_flow()
	if flow:
		flow.call("go_to_game")

func _on_play_multi() -> void:
	# Show lobby screen overlay
	var lobby := get_node_or_null("LobbyScreen") as LobbyScreen
	if lobby:
		lobby.show_lobby()

func _on_settings() -> void:
	if settings_panel:
		settings_panel.visible = true

func _on_quit() -> void:
	var flow := _get_scene_flow()
	if flow:
		flow.call("quit_game")
	else:
		get_tree().quit()

func _get_scene_flow() -> Node:
	return get_node_or_null("/root/SceneFlowManager")
