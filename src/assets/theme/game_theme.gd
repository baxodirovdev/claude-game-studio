## Game Theme Generator — creates the Hook Wars UI theme programmatically.
##
## Call create_theme() to get a Theme resource with consistent styling.
## Applied to root viewport or individual scenes.
class_name GameThemeGenerator
extends RefCounted

## Color palette.
const BG_DARK := Color(0.08, 0.08, 0.12)
const BG_PANEL := Color(0.12, 0.12, 0.18)
const BG_BUTTON := Color(0.18, 0.18, 0.26)
const BG_BUTTON_HOVER := Color(0.24, 0.24, 0.34)
const BG_BUTTON_PRESSED := Color(0.14, 0.14, 0.22)
const BG_BUTTON_DISABLED := Color(0.1, 0.1, 0.14)

const TEXT_PRIMARY := Color(0.92, 0.92, 0.95)
const TEXT_SECONDARY := Color(0.6, 0.6, 0.68)
const TEXT_DISABLED := Color(0.35, 0.35, 0.4)

const ACCENT_BLUE := Color(0.3, 0.6, 1.0)
const ACCENT_GREEN := Color(0.3, 0.9, 0.4)
const ACCENT_RED := Color(1.0, 0.3, 0.3)
const ACCENT_GOLD := Color(1.0, 0.85, 0.2)

const BORDER_COLOR := Color(0.25, 0.25, 0.35)

static func create_theme() -> Theme:
	var theme := Theme.new()

	# Default font size
	theme.set_default_font_size(16)

	# --- Button ---
	var btn_normal := _make_stylebox(BG_BUTTON, 8, 6, 8, 6, 4)
	var btn_hover := _make_stylebox(BG_BUTTON_HOVER, 8, 6, 8, 6, 4)
	var btn_pressed := _make_stylebox(BG_BUTTON_PRESSED, 8, 6, 8, 6, 4)
	var btn_disabled := _make_stylebox(BG_BUTTON_DISABLED, 8, 6, 8, 6, 4)
	var btn_focus := _make_stylebox(BG_BUTTON, 8, 6, 8, 6, 4)
	btn_focus.border_color = ACCENT_BLUE
	btn_focus.border_width_bottom = 2
	btn_focus.border_width_top = 2
	btn_focus.border_width_left = 2
	btn_focus.border_width_right = 2

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_focus)
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", ACCENT_BLUE)
	theme.set_color("font_disabled_color", "Button", TEXT_DISABLED)

	# --- Label ---
	theme.set_color("font_color", "Label", TEXT_PRIMARY)

	# --- PanelContainer ---
	var panel_style := _make_stylebox(BG_PANEL, 12, 12, 12, 12, 6)
	panel_style.border_color = BORDER_COLOR
	panel_style.border_width_bottom = 1
	panel_style.border_width_top = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# --- LineEdit ---
	var lineedit_normal := _make_stylebox(Color(0.1, 0.1, 0.16), 8, 4, 8, 4, 4)
	lineedit_normal.border_color = BORDER_COLOR
	lineedit_normal.border_width_bottom = 1
	lineedit_normal.border_width_top = 1
	lineedit_normal.border_width_left = 1
	lineedit_normal.border_width_right = 1
	var lineedit_focus := lineedit_normal.duplicate()
	lineedit_focus.border_color = ACCENT_BLUE
	theme.set_stylebox("normal", "LineEdit", lineedit_normal)
	theme.set_stylebox("focus", "LineEdit", lineedit_focus)
	theme.set_color("font_color", "LineEdit", TEXT_PRIMARY)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_SECONDARY)

	# --- HSlider ---
	var slider_bg := _make_stylebox(Color(0.15, 0.15, 0.2), 0, 4, 0, 4, 4)
	var slider_fill := _make_stylebox(ACCENT_BLUE, 0, 4, 0, 4, 4)
	theme.set_stylebox("slider", "HSlider", slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)

	return theme

static func _make_stylebox(color: Color, ml: float, mt: float, mr: float, mb: float, corner: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.content_margin_left = ml
	sb.content_margin_top = mt
	sb.content_margin_right = mr
	sb.content_margin_bottom = mb
	sb.corner_radius_top_left = int(corner)
	sb.corner_radius_top_right = int(corner)
	sb.corner_radius_bottom_left = int(corner)
	sb.corner_radius_bottom_right = int(corner)
	return sb
