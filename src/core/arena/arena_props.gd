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
	_place_river_bank_props(arena_data)

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
	# River pieces are loaded directly in _place_river_bank_props from
	# the procedurally generated kit — not via this cache.
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
	var detail_types: Array[String] = ["tree_log", "tree_log", "tree_trunk", "wood", "planks"]

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

	# Grass-tuft scatter removed — the Kenney grass props (grass, grass_large,
	# patch_grass, patch_grass_large) are flat-ish meshes that read as dark
	# patches from a top-down camera and were visually noisy on the unshaded
	# arena ground. Re-enable later if desired with a different prop set.

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

## Fills the arena gap with a procedurally generated Kenney-style river
## composed of 2m tiles from `src/assets/models/environment/generated/`.
##
## Composition (fits the 6m gap exactly):
##   LEFT column  at X=-2 → river_bank_sand rotated -90° (sandy bank, Team A side)
##   CENTER col   at X= 0 → river_water (all water) with river_source rock
##                          clusters at the north and south ends
##   RIGHT column at X=+2 → river_bank_sand rotated +90° (sandy bank, Team B side)
##
## Extra polish on top of the base composition:
##   - bank columns have a seeded ±6 cm X-jitter per row so the shoreline
##     doesn't read as a perfect ruler-straight line
##   - small rocks scatter on the water surface (every few rows) and on the
##     sand banks for silhouette variety
##
## The banks themselves are spawned as TWO continuous slab meshes (one per
## side) rather than 22 per-tile GLB instances. Per-tile banks produced
## short dark dashes at every 2m boundary because SSAO darkens the
## coplanar edges where adjacent tiles meet. A single long slab has no
## internal seams and renders as a clean uninterrupted shore.
##
## A single seamless water plane is laid on top of the per-tile water
## surfaces (5.2m wide so its X edges are buried inside the bank slab —
## not coplanar with the slab's inner face). Shadow casting is disabled
## on every river piece so bank edges don't project dark lines onto water.
##
## Tiles sit at Y=-0.2 so bank tops align with arena ground (Y=0).
func _place_river_bank_props(arena_data: ArenaData) -> void:
	const GEN_PATH := "res://assets/models/environment/generated/"
	const TILE_SIZE := 2.0
	const Y_OFFSET := -0.2
	const EXTENSION_TILES := 1
	const WATER_ROCK_EVERY := 5
	const BANK_SLAB_HEIGHT := 0.2  # matches GROUND_H in primitives.py
	# Bank shifted 1cm OUTWARD so its outer edge sits 1cm inside the arena
	# ground footprint (overlap rather than touch). The bank GLB has a
	# sand→grass vertex gradient, so the overlap region renders grass-on-
	# grass and any sub-millimeter precision gap from the GLB rotation is
	# bridged. Combined with the unshaded material override below this
	# eliminates the dark line at the bank-grass border.
	const BANK_OVERLAP := 0.01
	const BANK_TILE_CENTER_X := 2.0 + BANK_OVERLAP
	const BANK_SLAB_CENTER_X := 2.7 + BANK_OVERLAP

	var water_scene: PackedScene = load(GEN_PATH + "river_water.glb")
	var source_scene: PackedScene = load(GEN_PATH + "river_source.glb")
	var rock_scene: PackedScene = load(GEN_PATH + "rock.glb")
	var bank_scene: PackedScene = load(GEN_PATH + "river_bank_rock.glb")
	if water_scene == null or bank_scene == null:
		push_warning("Arena river: missing river_water.glb / river_bank_rock.glb"
			+ " in " + GEN_PATH + " — run /kenney-gen to produce them.")
		return

	# Banks use the GLB's default shaded material so the beveled top edges
	# read as 3D (chamfer faces shade slightly differently from the flat
	# top under directional light).

	var river_node := Node3D.new()
	river_node.name = "RiverProps"
	add_child(river_node)

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260424

	var top_z := arena_data.get_top_boundary() + TILE_SIZE * EXTENSION_TILES
	var bottom_z := arena_data.get_bottom_boundary() - TILE_SIZE * EXTENSION_TILES

	var z_positions: Array[float] = []
	var z := bottom_z + TILE_SIZE / 2.0
	while z <= top_z - TILE_SIZE / 2.0 + 0.01:
		z_positions.append(z)
		z += TILE_SIZE

	var n_rows := z_positions.size()
	var bank_top_y: float = Y_OFFSET + BANK_SLAB_HEIGHT  # bank top surface (Y=0)
	# Water sits 2cm below bank top.
	var water_surface_y: float = bank_top_y - 0.02
	var rock_base_y: float = water_surface_y + 0.001  # sit on the big water plane

	# Per-row iteration: a center water/source tile + a sand bank tile per
	# side + in-water rock scatter + on-bank pebble scatter. Banks use
	# river_bank_sand directly (the per-tile beveled GLB).
	for i in n_rows:
		var z_pos: float = z_positions[i]

		var center: Node3D
		if i == 0 and source_scene != null:
			center = source_scene.instantiate()
			center.rotation.y = PI / 2.0
		elif i == n_rows - 1 and source_scene != null:
			center = source_scene.instantiate()
			center.rotation.y = -PI / 2.0
		else:
			center = water_scene.instantiate()
		center.position = Vector3(0.0, Y_OFFSET, z_pos)
		river_node.add_child(center)

		# Bank tiles — one per side, rotated so the bank face is on the
		# outer (grass) edge. Default GLB material (shaded) so bevel
		# chamfers read as 3D under directional light.
		for side_sign: int in [-1, 1]:
			var bank: Node3D = bank_scene.instantiate()
			bank.position = Vector3(
				float(side_sign) * BANK_TILE_CENTER_X, Y_OFFSET, z_pos
			)
			bank.rotation.y = float(side_sign) * PI / 2.0
			bank.name = "Bank" + ("R" if side_sign > 0 else "L") + str(i)
			river_node.add_child(bank)

		# A — scatter 1-2 rocks on water every few rows (skip source endpoints)
		if rock_scene != null and i != 0 and i != n_rows - 1 \
				and (i % WATER_ROCK_EVERY) == (WATER_ROCK_EVERY / 2):
			var rock_count := rng.randi_range(1, 2)
			for r in rock_count:
				var r_inst: Node3D = rock_scene.instantiate()
				var r_scale := rng.randf_range(0.45, 0.85)
				r_inst.scale = Vector3(r_scale, r_scale, r_scale)
				r_inst.position = Vector3(
					rng.randf_range(-1.0, 1.0),
					rock_base_y,
					z_pos + rng.randf_range(-0.5, 0.5),
				)
				r_inst.rotation.y = rng.randf_range(0.0, TAU)
				river_node.add_child(r_inst)

		# (Rock-pile-on-bank scatter removed — the bank slab itself now has a
		# full 3D bevel profile so it doesn't need extra rocks for shape.)

	# Lay a single seamless water plane over the per-tile water surfaces.
	# It is deliberately wider than the visible channel (5.2m vs 4.8m) so the
	# plane's X edges are buried INSIDE the bank geometry rather than meeting
	# the bank inner face at a coplanar edge — coplanar shared edges would
	# otherwise trigger SSAO darkening and render as thin dark lines.
	# The Z edges are hidden at the north/south outer-ground boundary.
	var seamless_len: float = (top_z - bottom_z) + 0.6
	var seamless := MeshInstance3D.new()
	var seamless_mesh := BoxMesh.new()
	seamless_mesh.size = Vector3(5.2, 0.04, seamless_len)
	seamless.mesh = seamless_mesh
	seamless.position = Vector3(
		0.0,
		water_surface_y + 0.001 - 0.02,  # top surface 1 mm above tile water
		0.0,
	)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.15, 0.42, 0.88)
	water_mat.roughness = 0.85
	seamless.material_override = water_mat
	seamless.name = "SeamlessWater"
	river_node.add_child(seamless)

	# Kill cast_shadow on every spawned river piece so bank edges don't
	# project thin dark shadow seams onto the water surface.
	_disable_cast_shadow_recursive(river_node)


## Walks the subtree and sets cast_shadow OFF on every GeometryInstance3D.
## Used after spawning river tiles so they don't cast shadows onto the
## adjacent water — which would otherwise appear as long dark seams.
func _disable_cast_shadow_recursive(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = \
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_cast_shadow_recursive(child)


## Walks the subtree and sets `material_override` on every MeshInstance3D.
## Used to force the bank to unshaded vertex-color rendering.
func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)

## Create a prop instance from a loaded scene.
func _create_prop(key: String) -> Node3D:
	if not _prop_scenes.has(key):
		return null
	var scene: PackedScene = _prop_scenes[key]
	var instance: Node3D = scene.instantiate()
	return instance
