## Game Theme Generator — Brawl Stars-inspired bold, colorful UI theme.
##
## Chunky rounded buttons with thick borders, vibrant colors, large touch targets.
## Dark background with bright accents. Designed for mobile readability.
class_name GameThemeGenerator
extends RefCounted

## --- Color Palette (Brawl Stars inspired) ---
const BG_DARK := Color(0.06, 0.07, 0.14)         # Deep navy
const BG_PANEL := Color(0.1, 0.12, 0.22)          # Dark blue panel
const BG_PANEL_LIGHT := Color(0.14, 0.16, 0.28)   # Lighter panel

# Primary button: bright blue with dark blue border
const BTN_PRIMARY := Color(0.15, 0.55, 0.95)       # Vivid blue
const BTN_PRIMARY_HOVER := Color(0.2, 0.62, 1.0)
const BTN_PRIMARY_PRESSED := Color(0.1, 0.42, 0.78)
const BTN_PRIMARY_BORDER := Color(0.05, 0.3, 0.6)  # Dark blue border

# Secondary button: darker, subdued
const BTN_SECONDARY := Color(0.18, 0.2, 0.34)
const BTN_SECONDARY_HOVER := Color(0.24, 0.26, 0.42)
const BTN_SECONDARY_PRESSED := Color(0.12, 0.14, 0.26)
const BTN_SECONDARY_BORDER := Color(0.1, 0.12, 0.22)

# Disabled
const BTN_DISABLED := Color(0.15, 0.16, 0.22)
const BTN_DISABLED_BORDER := Color(0.1, 0.1, 0.16)

# Text
const TEXT_WHITE := Color(1.0, 1.0, 1.0)
const TEXT_LIGHT := Color(0.85, 0.88, 0.95)
const TEXT_DIM := Color(0.45, 0.48, 0.58)
const TEXT_DISABLED := Color(0.3, 0.32, 0.38)

# Accents
const ACCENT_YELLOW := Color(1.0, 0.82, 0.0)      # Gold/yellow
const ACCENT_GREEN := Color(0.15, 0.85, 0.35)      # Bright green
const ACCENT_RED := Color(0.95, 0.2, 0.25)         # Bright red
const ACCENT_ORANGE := Color(1.0, 0.55, 0.1)       # Orange
const ACCENT_PURPLE := Color(0.6, 0.3, 0.95)       # Purple
const ACCENT_CYAN := Color(0.2, 0.85, 0.95)        # Cyan

# Keep backward compat
const ACCENT_BLUE := BTN_PRIMARY
const ACCENT_GOLD := ACCENT_YELLOW

# Border
const BORDER_LIGHT := Color(0.3, 0.35, 0.5)

static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.set_default_font_size(18)

	# --- Primary Button (Play, Ready, etc.) ---
	var btn_n := _make_brawl_button(BTN_PRIMARY, BTN_PRIMARY_BORDER, 16, 12, 16, 12, 14)
	var btn_h := _make_brawl_button(BTN_PRIMARY_HOVER, BTN_PRIMARY_BORDER, 16, 12, 16, 12, 14)
	var btn_p := _make_brawl_button(BTN_PRIMARY_PRESSED, BTN_PRIMARY_BORDER, 16, 14, 16, 10, 14)
	var btn_d := _make_brawl_button(BTN_DISABLED, BTN_DISABLED_BORDER, 16, 12, 16, 12, 14)
	var btn_f := _make_brawl_button(BTN_PRIMARY, ACCENT_YELLOW, 16, 12, 16, 12, 14)

	theme.set_stylebox("normal", "Button", btn_n)
	theme.set_stylebox("hover", "Button", btn_h)
	theme.set_stylebox("pressed", "Button", btn_p)
	theme.set_stylebox("disabled", "Button", btn_d)
	theme.set_stylebox("focus", "Button", btn_f)
	theme.set_color("font_color", "Button", TEXT_WHITE)
	theme.set_color("font_hover_color", "Button", TEXT_WHITE)
	theme.set_color("font_pressed_color", "Button", Color(0.9, 0.9, 1.0))
	theme.set_color("font_disabled_color", "Button", TEXT_DISABLED)
	theme.set_font_size("font_size", "Button", 20)

	# --- Label ---
	theme.set_color("font_color", "Label", TEXT_LIGHT)
	theme.set_font_size("font_size", "Label", 18)

	# --- PanelContainer ---
	var panel := _make_brawl_panel(BG_PANEL, BORDER_LIGHT, 16, 14, 16, 14, 16)
	theme.set_stylebox("panel", "PanelContainer", panel)

	# --- LineEdit ---
	var le_n := _make_brawl_button(Color(0.08, 0.1, 0.18), BORDER_LIGHT, 14, 10, 14, 10, 10)
	var le_f := _make_brawl_button(Color(0.1, 0.12, 0.22), ACCENT_CYAN, 14, 10, 14, 10, 10)
	theme.set_stylebox("normal", "LineEdit", le_n)
	theme.set_stylebox("focus", "LineEdit", le_f)
	theme.set_color("font_color", "LineEdit", TEXT_WHITE)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
	theme.set_font_size("font_size", "LineEdit", 18)

	# --- HSlider ---
	var sl_bg := StyleBoxFlat.new()
	sl_bg.bg_color = Color(0.12, 0.14, 0.24)
	sl_bg.corner_radius_top_left = 6
	sl_bg.corner_radius_top_right = 6
	sl_bg.corner_radius_bottom_left = 6
	sl_bg.corner_radius_bottom_right = 6
	sl_bg.content_margin_top = 6
	sl_bg.content_margin_bottom = 6
	var sl_fill := StyleBoxFlat.new()
	sl_fill.bg_color = ACCENT_GREEN
	sl_fill.corner_radius_top_left = 6
	sl_fill.corner_radius_top_right = 6
	sl_fill.corner_radius_bottom_left = 6
	sl_fill.corner_radius_bottom_right = 6
	sl_fill.content_margin_top = 6
	sl_fill.content_margin_bottom = 6
	theme.set_stylebox("slider", "HSlider", sl_bg)
	theme.set_stylebox("grabber_area", "HSlider", sl_fill)

	return theme

## Brawl-style button: rounded with thick colored border and slight bottom shadow.
static func _make_brawl_button(bg: Color, border: Color, ml: float, mt: float, mr: float, mb: float, corner: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.content_margin_left = ml
	sb.content_margin_top = mt
	sb.content_margin_right = mr
	sb.content_margin_bottom = mb
	sb.corner_radius_top_left = int(corner)
	sb.corner_radius_top_right = int(corner)
	sb.corner_radius_bottom_left = int(corner)
	sb.corner_radius_bottom_right = int(corner)
	# Thick border — Brawl Stars signature look
	sb.border_color = border
	sb.border_width_top = 3
	sb.border_width_bottom = 4  # Thicker bottom = shadow feel
	sb.border_width_left = 3
	sb.border_width_right = 3
	# Slight shadow
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	return sb

## Brawl-style panel: rounded with subtle border and shadow.
static func _make_brawl_panel(bg: Color, border: Color, ml: float, mt: float, mr: float, mb: float, corner: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.content_margin_left = ml
	sb.content_margin_top = mt
	sb.content_margin_right = mr
	sb.content_margin_bottom = mb
	sb.corner_radius_top_left = int(corner)
	sb.corner_radius_top_right = int(corner)
	sb.corner_radius_bottom_left = int(corner)
	sb.corner_radius_bottom_right = int(corner)
	sb.border_color = border
	sb.border_width_top = 2
	sb.border_width_bottom = 3
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	return sb
