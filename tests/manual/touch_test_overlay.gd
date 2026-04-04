## Touch Input Test Overlay — manual verification tool for mobile touch.
##
## Displays active touch points, measures response latency, and validates
## joystick/button routing. Run by adding this node to any scene.
## NOT a GUT test — this is for manual device testing.
class_name TouchTestOverlay
extends CanvasLayer

var _touch_points: Dictionary = {}  # { index: { pos: Vector2, time: float } }
var _draw_node: Control
var _info_label: Label
var _latency_samples: Array[float] = []
var _last_touch_time: float = 0.0

func _ready() -> void:
	layer = 99

	_draw_node = Control.new()
	_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_node.draw.connect(_on_draw)
	add_child(_draw_node)

	_info_label = Label.new()
	_info_label.position = Vector2(10, 10)
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(_info_label)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_points[touch.index] = {
				"pos": touch.position,
				"time": Time.get_ticks_msec() / 1000.0,
			}
			_last_touch_time = Time.get_ticks_msec() / 1000.0
		else:
			if _touch_points.has(touch.index):
				var duration := Time.get_ticks_msec() / 1000.0 - _touch_points[touch.index]["time"]
				_latency_samples.append(duration)
				if _latency_samples.size() > 30:
					_latency_samples.remove_at(0)
			_touch_points.erase(touch.index)
		_draw_node.queue_redraw()

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _touch_points.has(drag.index):
			_touch_points[drag.index]["pos"] = drag.position
		_draw_node.queue_redraw()

func _process(_delta: float) -> void:
	var viewport := get_viewport()
	var screen_size := viewport.get_visible_rect().size
	var half_x := screen_size.x / 2.0

	var avg_latency := 0.0
	if _latency_samples.size() > 0:
		for s: float in _latency_samples:
			avg_latency += s
		avg_latency /= _latency_samples.size()

	_info_label.text = "Touch Test\n"
	_info_label.text += "Active touches: %d\n" % _touch_points.size()
	_info_label.text += "Screen: %dx%d\n" % [int(screen_size.x), int(screen_size.y)]
	_info_label.text += "Half X: %.0f (L=joystick, R=hook)\n" % half_x
	_info_label.text += "Avg hold time: %.3fs\n" % avg_latency
	_info_label.text += "Samples: %d\n" % _latency_samples.size()
	_info_label.text += "FPS: %d" % Engine.get_frames_per_second()

func _on_draw() -> void:
	for idx: int in _touch_points:
		var pos: Vector2 = _touch_points[idx]["pos"]
		_draw_node.draw_circle(pos, 30.0, Color(1, 0, 0, 0.5))
		_draw_node.draw_circle(pos, 5.0, Color.WHITE)
		_draw_node.draw_string(
			ThemeDB.fallback_font, pos + Vector2(35, 5),
			"T%d" % idx, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE
		)

	# Draw center line (joystick/hook split)
	var screen_size := _draw_node.get_viewport_rect().size
	_draw_node.draw_line(
		Vector2(screen_size.x / 2, 0),
		Vector2(screen_size.x / 2, screen_size.y),
		Color(1, 1, 0, 0.3), 2.0
	)
