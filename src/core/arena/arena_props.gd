## Scatters environment props (rocks, barrels, crates, etc.) around the arena.
##
## Loads GLB models from the environment assets folder and places them
## along arena edges, corners, and interior for visual atmosphere.
## Props are non-gameplay — decorative only, no collision.
class_name ArenaProps
extends Node3D

const MODELS_PATH := "res://assets/models/environment/"

## Prop definitions: path, scale range, and placement rules.
var _prop_scenes: Dictionary = {}

var _rng := RandomNumberGenerator.new()

## Initialize and scatter props based on arena dimensions.
func build_props(arena_data: ArenaData, seed_value: int = 42) -> void:
	_rng.seed = seed_value
	_load_prop_scenes()
	_place_outer_scenery(arena_data)
	_place_border_nature(arena_data)
	_place_corner_clusters(arena_data)
	_place_edge_props(arena_data)
	_place_interior_scatter(arena_data)
	_place_interior_trees(arena_data)

func _load_prop_scenes() -> void:
	var entries := {
		# Props for corners and edges
		"barrel": MODELS_PATH + "barrel.glb",
		"barrel_open": MODELS_PATH + "barrel-open.glb",
		"box": MODELS_PATH + "box.glb",
		"box_large": MODELS_PATH + "box-large.glb",
		"crate_open": MODELS_PATH + "box-open.glb",
		"chest": MODELS_PATH + "chest.glb",
		"bucket": MODELS_PATH + "bucket.glb",
		"campfire": MODELS_PATH + "campfire-pit.glb",
		"fence": MODELS_PATH + "fence.glb",
		"fence_fortified": MODELS_PATH + "fence-fortified.glb",
		# Rocks for scatter
		"rock_a": MODELS_PATH + "rock-a.glb",
		"rock_b": MODELS_PATH + "rock-b.glb",
		"rock_c": MODELS_PATH + "rock-c.glb",
		"rock_flat": MODELS_PATH + "rock-flat.glb",
		"rock_flat_grass": MODELS_PATH + "rock-flat-grass.glb",
		# Ground vegetation
		"grass": MODELS_PATH + "grass.glb",
		"grass_large": MODELS_PATH + "grass-large.glb",
		"patch_grass": MODELS_PATH + "patch-grass.glb",
		"patch_grass_large": MODELS_PATH + "patch-grass-large.glb",
		# Trees for borders
		"tree": MODELS_PATH + "tree.glb",
		"tree_tall": MODELS_PATH + "tree-tall.glb",
		"tree_autumn": MODELS_PATH + "tree-autumn.glb",
		"tree_autumn_tall": MODELS_PATH + "tree-autumn-tall.glb",
		"tree_trunk": MODELS_PATH + "tree-trunk.glb",
		"tree_log": MODELS_PATH + "tree-log.glb",
		# Stone resources
		"stone_large": MODELS_PATH + "resource-stone-large.glb",
		"stone": MODELS_PATH + "resource-stone.glb",
		"planks": MODELS_PATH + "resource-planks.glb",
		"wood": MODELS_PATH + "resource-wood.glb",
		"anvil": MODELS_PATH + "workbench-anvil.glb",
	}
	for key: String in entries:
		var path: String = entries[key]
		if ResourceLoader.exists(path):
			_prop_scenes[key] = load(path)

## Scatter trees, rocks, logs, and grass on the green area outside the arena.
## Places on the left (negative X) side only, then mirrors to the right.
func _place_outer_scenery(arena_data: ArenaData) -> void:
	var outer_node := Node3D.new()
	outer_node.name = "OuterScenery"
	add_child(outer_node)

	var left := arena_data.get_left_boundary()
	var top_z := arena_data.get_top_boundary()
	var bottom_z := arena_data.get_bottom_boundary()
	var margin := 25.0

	var tree_types: Array[String] = ["tree", "tree_tall", "tree_autumn", "tree_autumn_tall"]
	var rock_types: Array[String] = ["rock_a", "rock_b", "rock_c", "rock_flat", "rock_flat_grass"]
	var detail_types: Array[String] = ["tree_log", "tree_log", "tree_trunk", "grass_large", "patch_grass_large", "wood", "planks"]

	# Scatter trees outside — left side only, mirrored to right
	var tree_count := 40  # Half count since each is mirrored
	for i in range(tree_count):
		var pos: Vector3 = _random_outer_position_left(left, top_z, bottom_z, margin)
		if pos == Vector3.ZERO:
			continue
		var key: String = tree_types[_rng.randi_range(0, tree_types.size() - 1)]
		if not _prop_scenes.has(key):
			continue
		var rot := _rng.randf_range(0, TAU)
		var s := _rng.randf_range(3.0, 5.0)
		_place_mirrored(outer_node, key, pos, rot, s)

	# Scatter rocks outside — mirrored
	var rock_count := 18
	for i in range(rock_count):
		var pos: Vector3 = _random_outer_position_left(left, top_z, bottom_z, margin)
		if pos == Vector3.ZERO:
			continue
		var key: String = rock_types[_rng.randi_range(0, rock_types.size() - 1)]
		if not _prop_scenes.has(key):
			continue
		var rot := _rng.randf_range(0, TAU)
		var s := _rng.randf_range(1.2, 2.0)
		_place_mirrored(outer_node, key, pos, rot, s)

	# Scatter detail objects — mirrored
	var detail_count := 25
	for i in range(detail_count):
		var pos: Vector3 = _random_outer_position_left(left, top_z, bottom_z, margin)
		if pos == Vector3.ZERO:
			continue
		var key: String = detail_types[_rng.randi_range(0, detail_types.size() - 1)]
		if not _prop_scenes.has(key):
			continue
		var rot := _rng.randf_range(0, TAU)
		var s := _rng.randf_range(1.0, 1.8)
		_place_mirrored(outer_node, key, pos, rot, s)

## Returns a random position outside the arena on the LEFT side only.
func _random_outer_position_left(left: float, top_z: float, bottom_z: float, margin: float) -> Vector3:
	for _attempt in range(10):
		var x := _rng.randf_range(left - margin, 0.0)
		var z := _rng.randf_range(bottom_z - margin, top_z + margin)
		# Must be outside the arena boundary (with a small buffer)
		if x > left - 1.5 and z > bottom_z - 1.5 and z < top_z + 1.5:
			continue
		return Vector3(x, 0, z)
	return Vector3.ZERO

## Place rocks and trees along the arena boundary as a natural border.
## North/South borders: place on left half, mirror to right half.
## West border placed directly, East border mirrors it.
func _place_border_nature(arena_data: ArenaData) -> void:
	var border_node := Node3D.new()
	border_node.name = "BorderNature"
	add_child(border_node)

	var left := arena_data.get_left_boundary()
	var top_z := arena_data.get_top_boundary()
	var bottom_z := arena_data.get_bottom_boundary()

	var tree_types: Array[String] = ["tree", "tree_tall", "tree_autumn", "tree_autumn_tall"]
	var rock_types: Array[String] = ["rock_a", "rock_b", "rock_c", "stone_large"]

	# North border — left half only, mirrored to right
	var x := left - 2.0
	while x <= 0.0:
		_place_border_piece_mirrored(border_node, Vector3(x, 0, top_z + 0.5), tree_types, rock_types)
		x += _rng.randf_range(1.0, 1.8)

	# South border — left half only, mirrored to right
	x = left - 2.0
	while x <= 0.0:
		_place_border_piece_mirrored(border_node, Vector3(x, 0, bottom_z - 0.5), tree_types, rock_types)
		x += _rng.randf_range(1.0, 1.8)

	# West border — placed, then mirrored to East
	var z := bottom_z - 2.0
	while z <= top_z + 2.0:
		_place_border_piece_mirrored(border_node, Vector3(left - 0.5, 0, z), tree_types, rock_types)
		z += _rng.randf_range(1.0, 1.8)

func _place_border_piece_mirrored(parent: Node3D, pos: Vector3, tree_types: Array[String], rock_types: Array[String]) -> void:
	var use_tree := _rng.randf() < 0.6
	var key: String
	if use_tree:
		key = tree_types[_rng.randi_range(0, tree_types.size() - 1)]
	else:
		key = rock_types[_rng.randi_range(0, rock_types.size() - 1)]

	if not _prop_scenes.has(key):
		return

	var offset := Vector3(_rng.randf_range(-0.8, 0.8), 0, _rng.randf_range(-0.8, 0.8))
	var final_pos := pos + offset
	var rot := _rng.randf_range(0, TAU)
	var s: float
	if use_tree:
		s = _rng.randf_range(3.0, 4.5)
	else:
		s = _rng.randf_range(1.4, 2.2)
	_place_mirrored(parent, key, final_pos, rot, s)

## Place clusters of props in arena corners — left side only, mirrored to right.
func _place_corner_clusters(arena_data: ArenaData) -> void:
	var corners_node := Node3D.new()
	corners_node.name = "CornerClusters"
	add_child(corners_node)

	var left := arena_data.get_left_boundary()
	var top := arena_data.get_top_boundary()
	var bottom := arena_data.get_bottom_boundary()
	var gap_half := arena_data.gap_width / 2.0

	# Left-side corners only — mirrored to right
	var left_corners := [
		Vector3(left + 3.0, 0, top - 3.0),
		Vector3(left + 3.0, 0, bottom + 3.0),
	]

	var cluster_props: Array[String] = ["barrel", "barrel_open", "box", "box_large", "crate_open", "chest", "bucket", "planks", "wood"]

	for corner_pos in left_corners:
		var count := _rng.randi_range(5, 8)
		for i in range(count):
			var prop_key: String = cluster_props[_rng.randi_range(0, cluster_props.size() - 1)]
			if not _prop_scenes.has(prop_key):
				continue
			var offset := Vector3(
				_rng.randf_range(-2.5, 2.5),
				0,
				_rng.randf_range(-2.5, 2.5)
			)
			var pos: Vector3 = corner_pos + offset
			var rot := _rng.randf_range(0, TAU)
			var s := _rng.randf_range(1.2, 1.8)
			_place_mirrored(corners_node, prop_key, pos, rot, s)

	# Left gap-side clusters only — mirrored to right
	var left_gap_clusters := [
		Vector3(-gap_half - 2.5, 0, top - 4.0),
		Vector3(-gap_half - 2.5, 0, bottom + 4.0),
	]

	for cluster_pos in left_gap_clusters:
		var count := _rng.randi_range(2, 3)
		for i in range(count):
			var prop_key: String = cluster_props[_rng.randi_range(0, cluster_props.size() - 1)]
			if not _prop_scenes.has(prop_key):
				continue
			var offset := Vector3(
				_rng.randf_range(-1.5, 1.5),
				0,
				_rng.randf_range(-1.5, 1.5)
			)
			var pos: Vector3 = cluster_pos + offset
			var rot := _rng.randf_range(0, TAU)
			var s := _rng.randf_range(1.2, 1.6)
			_place_mirrored(corners_node, prop_key, pos, rot, s)

## Place props along the arena edges — left half of N/S + west edge, mirrored.
func _place_edge_props(arena_data: ArenaData) -> void:
	var edges_node := Node3D.new()
	edges_node.name = "EdgeProps"
	add_child(edges_node)

	var left := arena_data.get_left_boundary()
	var top := arena_data.get_top_boundary()
	var bottom := arena_data.get_bottom_boundary()

	var edge_props: Array[String] = ["fence", "fence_fortified", "stone_large", "stone", "anvil"]

	# North and South edges — left half only, mirrored to right
	for z_pos in [top - 1.5, bottom + 1.5]:
		var x := left + 8.0
		while x < -arena_data.gap_width - 2.0:
			if _rng.randf() < 0.5:
				var prop_key: String = edge_props[_rng.randi_range(0, edge_props.size() - 1)]
				if _prop_scenes.has(prop_key):
					var pos: Vector3 = Vector3(x + _rng.randf_range(-1.0, 1.0), 0, z_pos)
					var rot := _rng.randf_range(0, TAU)
					var s := _rng.randf_range(1.4, 2.0)
					_place_mirrored(edges_node, prop_key, pos, rot, s)
			x += 5.0

	# West edge only, mirrored to East
	var z := bottom + 8.0
	while z < top - 8.0:
		if _rng.randf() < 0.5:
			var prop_key: String = edge_props[_rng.randi_range(0, edge_props.size() - 1)]
			if _prop_scenes.has(prop_key):
				var pos: Vector3 = Vector3(left + 1.5, 0, z + _rng.randf_range(-1.0, 1.0))
				var rot := _rng.randf_range(0, TAU)
				var s := _rng.randf_range(1.4, 2.0)
				_place_mirrored(edges_node, prop_key, pos, rot, s)
		z += 5.0

## Scatter rocks and grass patches — left side only, mirrored to right.
func _place_interior_scatter(arena_data: ArenaData) -> void:
	var scatter_node := Node3D.new()
	scatter_node.name = "InteriorScatter"
	add_child(scatter_node)

	var left := arena_data.get_left_boundary()
	var top := arena_data.get_top_boundary()
	var bottom := arena_data.get_bottom_boundary()
	var gap_half := arena_data.gap_width / 2.0

	var rock_props: Array[String] = ["rock_a", "rock_b", "rock_c", "rock_flat", "rock_flat_grass"]
	var grass_props: Array[String] = ["grass", "grass_large", "patch_grass", "patch_grass_large"]

	# Scatter rocks — left side only, mirrored (half count)
	var rock_count := 20
	for i in range(rock_count):
		var x := _rng.randf_range(left + 4.0, -gap_half - 1.5)
		var z := _rng.randf_range(bottom + 4.0, top - 4.0)
		# Skip near spawn points (X around -15)
		if abs(x + 15.0) < 3.0 and abs(z) < 8.0:
			continue

		var prop_key: String = rock_props[_rng.randi_range(0, rock_props.size() - 1)]
		if not _prop_scenes.has(prop_key):
			continue
		var rot := _rng.randf_range(0, TAU)
		var s := _rng.randf_range(1.0, 1.8)
		_place_mirrored(scatter_node, prop_key, Vector3(x, 0, z), rot, s)

	# Scatter grass patches — left side only, mirrored (half count)
	var grass_count := 38
	for i in range(grass_count):
		var x := _rng.randf_range(left + 2.0, -gap_half - 0.5)
		var z := _rng.randf_range(bottom + 2.0, top - 2.0)

		var prop_key: String = grass_props[_rng.randi_range(0, grass_props.size() - 1)]
		if not _prop_scenes.has(prop_key):
			continue
		var rot := _rng.randf_range(0, TAU)
		var s := _rng.randf_range(1.2, 2.0)
		_place_mirrored(scatter_node, prop_key, Vector3(x, 0, z), rot, s)

## Place trees inside the playable arena — left side only, mirrored to right.
## Avoids spawn points and gap zone.
func _place_interior_trees(arena_data: ArenaData) -> void:
	var trees_node := Node3D.new()
	trees_node.name = "InteriorTrees"
	add_child(trees_node)

	var left := arena_data.get_left_boundary()
	var top := arena_data.get_top_boundary()
	var bottom := arena_data.get_bottom_boundary()
	var gap_half := arena_data.gap_width / 2.0

	var tree_types: Array[String] = ["tree", "tree_tall", "tree_autumn", "tree_autumn_tall"]

	# Place 5-8 trees on the LEFT side, each mirrored to the right (10-16 total)
	var tree_count := _rng.randi_range(5, 8)
	var placed := 0
	var attempts := 0
	while placed < tree_count and attempts < 40:
		attempts += 1

		var x := _rng.randf_range(left + 3.0, -gap_half - 2.0)
		var z := _rng.randf_range(bottom + 3.0, top - 3.0)

		# Skip near spawn points (X around -15, Z within ±8)
		if abs(x + 15.0) < 4.0 and abs(z) < 9.0:
			continue

		var tree_key: String = tree_types[_rng.randi_range(0, tree_types.size() - 1)]
		if not _prop_scenes.has(tree_key):
			continue
		var rot := _rng.randf_range(0, TAU)
		var s := _rng.randf_range(2.5, 3.8)
		if _place_mirrored(trees_node, tree_key, Vector3(x, 0, z), rot, s):
			placed += 1

## Place a prop and its X-axis mirror copy. Returns true if placed.
func _place_mirrored(parent: Node3D, key: String, pos: Vector3, rot_y: float, scl: float) -> bool:
	var left := _create_prop(key)
	if left == null:
		return false
	left.position = pos
	left.rotation.y = rot_y
	left.scale = Vector3(scl, scl, scl)
	parent.add_child(left)

	var right := _create_prop(key)
	if right == null:
		return false
	right.position = Vector3(-pos.x, pos.y, pos.z)
	right.rotation.y = TAU - rot_y  # Mirror rotation across X
	right.scale = Vector3(scl, scl, scl)
	parent.add_child(right)
	return true

## Create a prop instance from a loaded scene.
func _create_prop(key: String) -> Node3D:
	if not _prop_scenes.has(key):
		return null
	var scene: PackedScene = _prop_scenes[key]
	var instance: Node3D = scene.instantiate()
	return instance
