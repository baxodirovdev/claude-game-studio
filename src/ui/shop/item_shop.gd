## Item Shop — compact quick-buy overlay for in-match item purchases.
##
## Opens over gameplay (does NOT pause). Shows 6 items in a grid with costs,
## affordability, and owned state. One-tap buy, auto-close after purchase.
## Implements GDD: design/gdd/in-match-economy.md.
class_name ItemShop
extends CanvasLayer

signal item_purchased(item: ItemData)

## References set by Main.
var gold_system: GoldSystem
var player: PlayerController

## All available items (loaded from resources).
var _items: Array[ItemData] = []

var _panel: PanelContainer
var _grid: GridContainer
var _gold_label: Label
var _close_button: Button
var _item_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	_load_items()
	_build_ui()

func _load_items() -> void:
	_items = [
		preload("res://data/items/swift_boots.tres"),
		preload("res://data/items/sharpened_hook.tres"),
		preload("res://data/items/iron_plating.tres"),
		preload("res://data/items/quick_reel.tres"),
		preload("res://data/items/barbed_chain.tres"),
		preload("res://data/items/thick_hide.tres"),
	]

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(400, 300)
	_panel.position = Vector2(-200, -150)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# Header
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 20)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	header.add_child(_gold_label)
	vbox.add_child(header)

	# Item grid (3 columns)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)

	for item: ItemData in _items:
		var btn := _create_item_button(item)
		_grid.add_child(btn)
		_item_buttons.append(btn)

	vbox.add_child(_grid)

	# Close button
	_close_button = Button.new()
	_close_button.text = "CLOSE"
	_close_button.pressed.connect(close_shop)
	vbox.add_child(_close_button)

	_panel.add_child(vbox)
	add_child(_panel)

func _create_item_button(item: ItemData) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 80)
	btn.text = "%s\n%dg\n%s" % [item.display_name, item.cost, item.description]
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func() -> void: _on_item_pressed(item))
	return btn

## Open the shop overlay.
func open_shop() -> void:
	_refresh_ui()
	visible = true

## Close the shop overlay.
func close_shop() -> void:
	visible = false

## Toggle shop visibility.
func toggle_shop() -> void:
	if visible:
		close_shop()
	else:
		open_shop()

func _on_item_pressed(item: ItemData) -> void:
	if gold_system == null or player == null:
		return

	var pid := player.get_instance_id()

	# Check constraints
	if not gold_system.has_item_slot(pid):
		return
	if not gold_system.can_afford(pid, item.cost):
		return
	if gold_system.has_item(pid, item.item_id):
		return

	# Purchase
	gold_system.spend_gold(pid, item.cost)
	gold_system.add_item(pid, item)
	item_purchased.emit(item)

	_refresh_ui()

	# Auto-close after brief delay
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		close_shop()
	)

func _refresh_ui() -> void:
	if gold_system == null or player == null:
		return

	var pid := player.get_instance_id()
	var gold := gold_system.get_gold(pid)
	var owned_count := gold_system.get_item_count(pid)
	var max_items := 3
	if gold_system.economy_config:
		max_items = gold_system.economy_config.max_items

	_gold_label.text = "%d gold (%d/%d items)" % [gold, owned_count, max_items]

	for i in range(_items.size()):
		var item: ItemData = _items[i]
		var btn: Button = _item_buttons[i]

		var owned := gold_system.has_item(pid, item.item_id)
		var can_afford := gold >= item.cost
		var has_slot := owned_count < max_items

		if owned:
			btn.disabled = true
			btn.text = "%s\nOWNED" % item.display_name
			btn.modulate = Color(0.5, 0.8, 0.5)
		elif not has_slot:
			btn.disabled = true
			btn.text = "%s\n%dg\nFULL" % [item.display_name, item.cost]
			btn.modulate = Color(0.5, 0.5, 0.5)
		elif not can_afford:
			btn.disabled = true
			btn.text = "%s\n%dg\n%s" % [item.display_name, item.cost, item.description]
			btn.modulate = Color(0.6, 0.4, 0.4)
		else:
			btn.disabled = false
			btn.text = "%s\n%dg\n%s" % [item.display_name, item.cost, item.description]
			btn.modulate = Color.WHITE
