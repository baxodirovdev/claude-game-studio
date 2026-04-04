## Main Menu — Brawl Stars-inspired bold title screen.
##
## Big colorful buttons, vibrant layout, touch-friendly.
class_name MainMenu
extends Control

@onready var title_label: Label = $VBox/TitleLabel
@onready var play_solo_button: Button = $VBox/PlaySoloButton
@onready var play_multi_button: Button = $VBox/PlayMultiButton
@onready var settings_button: Button = $VBox/BottomRow/SettingsButton
@onready var quit_button: Button = $VBox/BottomRow/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var settings_panel: Control = $SettingsPanel

func _ready() -> void:
	# Title styling — big, bold, yellow like Brawl Stars
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", GameThemeGenerator.ACCENT_YELLOW)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Subtitle color
	version_label.add_theme_font_size_override("font_size", 13)
	version_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))

	# Color-code the main buttons
	_style_button(play_solo_button, GameThemeGenerator.ACCENT_GREEN, Color(0.05, 0.5, 0.15))
	_style_button(play_multi_button, GameThemeGenerator.BTN_PRIMARY, GameThemeGenerator.BTN_PRIMARY_BORDER)
	_style_button(settings_button, GameThemeGenerator.BTN_SECONDARY, GameThemeGenerator.BTN_SECONDARY_BORDER)
	_style_button(quit_button, Color(0.5, 0.18, 0.2), Color(0.35, 0.1, 0.12))

	play_solo_button.add_theme_font_size_override("font_size", 24)
	play_multi_button.add_theme_font_size_override("font_size", 22)
	settings_button.add_theme_font_size_override("font_size", 18)
	quit_button.add_theme_font_size_override("font_size", 18)

	play_solo_button.pressed.connect(_on_play_solo)
	play_multi_button.pressed.connect(_on_play_multi)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)

	if settings_panel:
		settings_panel.visible = false

	var lobby := get_node_or_null("LobbyScreen") as LobbyScreen
	if lobby:
		lobby.network_manager = get_node_or_null("/root/NetworkManager")
		lobby.visible = false

	play_solo_button.grab_focus()

func _style_button(btn: Button, bg_color: Color, border_color: Color) -> void:
	var style := GameThemeGenerator._make_brawl_button(bg_color, border_color, 20, 14, 20, 14, 16)
	var hover := GameThemeGenerator._make_brawl_button(bg_color.lightened(0.1), border_color, 20, 14, 20, 14, 16)
	var pressed := GameThemeGenerator._make_brawl_button(bg_color.darkened(0.15), border_color, 20, 16, 20, 12, 16)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _on_play_solo() -> void:
	var flow := _get_scene_flow()
	if flow:
		flow.call("go_to_game")

func _on_play_multi() -> void:
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
