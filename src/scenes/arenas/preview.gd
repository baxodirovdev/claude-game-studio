## Editor-friendly preview of generated Kenney-style assets.
## Opens directly in the Godot 3D viewport — no game run required.
##
## Usage:
##   1. Open this scene (src/scenes/arenas/preview.tscn) in the Godot editor.
##   2. Use the inspector on the root node to switch layouts:
##        - Wide River   (3 columns bank/water/bank, 6 tiles long)
##        - Narrow River (1-tile-wide river_straight chain)
##        - All Pieces   (grid of every generated asset)
##   3. Toggle `rebuild` to force a rebuild after regenerating GLBs.
##
## Orbit with middle mouse, zoom with scroll, pan with Shift + middle mouse.
@tool
class_name GeneratedAssetsPreview
extends Node3D

const GEN_PATH := "res://assets/models/environment/generated/"

enum Layout { WIDE_RIVER, NARROW_RIVER, ALL_PIECES }

@export var layout: Layout = Layout.WIDE_RIVER:
	set(value):
		layout = value
		_rebuild()

## Toggle to force a rebuild (useful after regenerating the GLB files).
@export var rebuild: bool = false:
	set(value):
		rebuild = false
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	# Remove previously spawned previews (leave any manually added nodes alone).
	for child in get_children():
		if child.has_meta("preview_spawned"):
			child.queue_free()

	match layout:
		Layout.WIDE_RIVER: _build_wide_river()
		Layout.NARROW_RIVER: _build_narrow_river()
		Layout.ALL_PIECES: _build_all_pieces()

func _spawn(packed: PackedScene, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	var inst: Node3D = packed.instantiate()
	inst.set_meta("preview_spawned", true)
	inst.position = pos
	inst.rotation.y = rot_y
	add_child(inst)
	if Engine.is_editor_hint():
		inst.owner = get_tree().edited_scene_root
	return inst

func _load(piece: String) -> PackedScene:
	var path := GEN_PATH + piece + ".glb"
	if not ResourceLoader.exists(path):
		push_warning("preview: missing %s — run /kenney-gen" % path)
		return null
	return load(path) as PackedScene

func _build_wide_river() -> void:
	var bank := _load("river_bank_rock")
	var water := _load("river_water")
	if bank == null or water == null:
		return
	var y := -0.2
	for i in range(6):
		var z := (i - 2.5) * 2.0
		_spawn(bank, Vector3(-2.0, y, z), -PI / 2.0)
		_spawn(water, Vector3(0.0, y, z))
		_spawn(bank, Vector3(2.0, y, z), PI / 2.0)

func _build_narrow_river() -> void:
	var straight := _load("river_straight")
	if straight == null:
		return
	var y := -0.2
	for i in range(6):
		_spawn(straight, Vector3(0.0, y, (i - 2.5) * 2.0))

func _build_all_pieces() -> void:
	var pieces: Array[String] = [
		"barrel", "crate", "tree", "rock",
		"river_straight", "river_corner", "river_end", "river_rocks",
		"river_bridge", "river_water", "river_bank", "river_bank_rock",
		"river_bank_corner", "river_source",
	]
	var cols := 5
	var spacing := 3.5
	for i in pieces.size():
		var packed := _load(pieces[i])
		if packed == null:
			continue
		var col := i % cols
		var row := i / cols
		var x := (col - (cols - 1) / 2.0) * spacing
		var z := (row - 1.0) * spacing
		_spawn(packed, Vector3(x, 0.0, z))
