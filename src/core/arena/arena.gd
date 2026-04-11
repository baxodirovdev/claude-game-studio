## Arena system — builds and manages the 3D arena from ArenaData.
##
## Generates ground geometry, gap visual, collision walls, and hazard zone markers.
## Provides spatial queries for spawn points and hazard zones.
## Other systems read arena properties through this node, never directly from ArenaData.
class_name Arena
extends Node3D

## The arena data resource defining layout, dimensions, and hazards.
@export var arena_data: ArenaData

## Emitted when arena is fully built and ready for gameplay.
signal arena_ready

var _walls_node: Node3D
var _ground_node: Node3D
var _hazards_node: Node3D

func _ready() -> void:
	if arena_data == null:
		push_warning("Arena: no arena_data assigned, using defaults.")
		arena_data = ArenaData.new()
	_build_arena()
	call_deferred("emit_signal", "arena_ready")

## Returns spawn points for the given team (0 = Team A / left, 1 = Team B / right).
func get_spawn_points(team_id: int) -> Array[Vector3]:
	if team_id == 0:
		return arena_data.team_a_spawns
	return arena_data.team_b_spawns

## Returns the arena bounds as a dictionary {min: Vector3, max: Vector3, center: Vector3}.
func get_arena_bounds() -> Dictionary:
	return {
		"min": Vector3(arena_data.get_left_boundary(), 0, arena_data.get_bottom_boundary()),
		"max": Vector3(arena_data.get_right_boundary(), 0, arena_data.get_top_boundary()),
		"center": Vector3.ZERO,
	}

## Returns hazard zone data: [{position, radius, type}].
func get_hazard_zones() -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	for pos in arena_data.spike_zones:
		zones.append({"position": pos, "radius": arena_data.spike_zone_radius, "type": "spike"})
	for pos in arena_data.pit_zones:
		zones.append({"position": pos, "radius": arena_data.pit_radius, "type": "pit"})
	# Central gap is always a hazard
	zones.append({
		"position": Vector3.ZERO,
		"radius": arena_data.gap_width / 2.0,
		"type": "gap",
	})
	return zones

## Returns the gap width for hook range validation.
func get_gap_width() -> float:
	return arena_data.gap_width

## Check if a world position is inside the gap (for pull-through detection).
func is_in_gap(world_pos: Vector3) -> bool:
	return abs(world_pos.x) < arena_data.gap_width / 2.0

## Check if a world position is inside any pit.
func is_in_pit(world_pos: Vector3) -> bool:
	for pit_pos in arena_data.pit_zones:
		var dist := Vector2(world_pos.x, world_pos.z).distance_to(Vector2(pit_pos.x, pit_pos.z))
		if dist < arena_data.pit_radius:
			return true
	return false

## Check if a world position is inside any spike zone. Returns the zone position or null.
func get_spike_zone_at(world_pos: Vector3) -> Variant:
	for spike_pos in arena_data.spike_zones:
		var dist := Vector2(world_pos.x, world_pos.z).distance_to(Vector2(spike_pos.x, spike_pos.z))
		if dist < arena_data.spike_zone_radius:
			return spike_pos
	return null

# --- Arena Construction ---

func _build_arena() -> void:
	_build_ground()
	_build_gap_visual()
	_build_collision_walls()
	_build_hazard_markers()

func _build_ground() -> void:
	_ground_node = Node3D.new()
	_ground_node.name = "Ground"
	add_child(_ground_node)

	var half_w := arena_data.get_half_width()
	var depth := arena_data.arena_depth
	var gap_half := arena_data.gap_width / 2.0

	# Team A ground (left side)
	var ground_a := _create_ground_body(
		Vector3(-(gap_half + half_w / 2.0), -0.5, 0),
		Vector3(half_w, 1, depth)
	)
	ground_a.name = "GroundA"
	_ground_node.add_child(ground_a)

	# Team B ground (right side)
	var ground_b := _create_ground_body(
		Vector3(gap_half + half_w / 2.0, -0.5, 0),
		Vector3(half_w, 1, depth)
	)
	ground_b.name = "GroundB"
	_ground_node.add_child(ground_b)

func _build_gap_visual() -> void:
	var gap_node := Node3D.new()
	gap_node.name = "GapVisual"
	add_child(gap_node)

	# Deep pit underneath
	var pit := MeshInstance3D.new()
	var pit_box := BoxMesh.new()
	pit_box.size = Vector3(arena_data.gap_width, 4, arena_data.arena_depth)
	pit.mesh = pit_box
	pit.position = Vector3(0, -2.5, 0)
	var pit_mat := StandardMaterial3D.new()
	pit_mat.albedo_color = Color(0.02, 0.02, 0.06)
	pit_mat.roughness = 1.0
	pit.material_override = pit_mat
	gap_node.add_child(pit)

	# Glowing lava/energy surface at the bottom
	var lava := MeshInstance3D.new()
	var lava_mesh := BoxMesh.new()
	lava_mesh.size = Vector3(arena_data.gap_width - 0.4, 0.1, arena_data.arena_depth - 0.4)
	lava.mesh = lava_mesh
	lava.position = Vector3(0, -3.5, 0)
	var lava_mat := StandardMaterial3D.new()
	lava_mat.albedo_color = Color(arena_data.gap_color.r * 2, arena_data.gap_color.g * 1.5, arena_data.gap_color.b * 2)
	lava_mat.emission_enabled = true
	lava_mat.emission = Color(arena_data.gap_color.r * 3, arena_data.gap_color.g * 2, arena_data.gap_color.b * 3)
	lava_mat.emission_energy_multiplier = 2.5
	lava_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lava.material_override = lava_mat
	gap_node.add_child(lava)

	# Edge lips on both sides of gap (stone edges)
	for side in [-1.0, 1.0]:
		var edge := MeshInstance3D.new()
		var edge_mesh := BoxMesh.new()
		edge_mesh.size = Vector3(0.3, 0.5, arena_data.arena_depth)
		edge.mesh = edge_mesh
		edge.position = Vector3(side * (arena_data.gap_width / 2.0 - 0.15), -0.25, 0)
		var edge_mat := StandardMaterial3D.new()
		edge_mat.albedo_color = Color(0.2, 0.2, 0.25)
		edge_mat.roughness = 0.5
		edge_mat.metallic = 0.3
		edge.material_override = edge_mat
		gap_node.add_child(edge)

func _build_collision_walls() -> void:
	_walls_node = Node3D.new()
	_walls_node.name = "Walls"
	add_child(_walls_node)

	var left := arena_data.get_left_boundary()
	var right := arena_data.get_right_boundary()
	var top := arena_data.get_top_boundary()
	var bottom := arena_data.get_bottom_boundary()
	var gap_half := arena_data.gap_width / 2.0
	var full_width := arena_data.arena_width + 2
	var full_depth := arena_data.arena_depth + 2

	var walls := [
		# Boundary walls [position, size]
		[Vector3(0, 1, top + 1), Vector3(full_width, 4, 2)],       # North
		[Vector3(0, 1, bottom - 1), Vector3(full_width, 4, 2)],    # South
		[Vector3(right + 1, 1, 0), Vector3(2, 4, full_depth)],     # East
		[Vector3(left - 1, 1, 0), Vector3(2, 4, full_depth)],      # West
		# Gap edges — block player movement across the gap
		[Vector3(-gap_half, 1, 0), Vector3(0.5, 4, full_depth)],   # Left gap wall
		[Vector3(gap_half, 1, 0), Vector3(0.5, 4, full_depth)],    # Right gap wall
	]

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.22, 0.2, 0.28)
	wall_mat.roughness = 0.6
	wall_mat.metallic = 0.15

	for wall_info: Array in walls:
		var wall_pos: Vector3 = wall_info[0]
		var wall_size: Vector3 = wall_info[1]
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall_size
		shape.shape = box
		wall.add_child(shape)

		# Visible wall mesh
		var wall_mesh := MeshInstance3D.new()
		var wall_box := BoxMesh.new()
		wall_box.size = wall_size
		wall_mesh.mesh = wall_box
		wall_mesh.material_override = wall_mat
		wall.add_child(wall_mesh)

		# Top edge highlight
		var top_trim := MeshInstance3D.new()
		var top_mesh := BoxMesh.new()
		top_mesh.size = Vector3(wall_size.x + 0.1, 0.1, wall_size.z + 0.1)
		top_trim.mesh = top_mesh
		top_trim.position = Vector3(0, wall_size.y / 2.0, 0)
		var top_mat := StandardMaterial3D.new()
		top_mat.albedo_color = Color(0.35, 0.32, 0.42)
		top_mat.roughness = 0.4
		top_mat.metallic = 0.3
		top_trim.material_override = top_mat
		wall.add_child(top_trim)

		_walls_node.add_child(wall)
		wall.global_position = wall_pos

func _build_hazard_markers() -> void:
	_hazards_node = Node3D.new()
	_hazards_node.name = "HazardMarkers"
	add_child(_hazards_node)

	# Spike zone markers — raised glowing danger platforms
	for spike_pos in arena_data.spike_zones:
		var marker := _create_hazard_disc(spike_pos, arena_data.spike_zone_radius, Color(0.95, 0.3, 0.1, 0.7))
		marker.name = "SpikeZone"
		_hazards_node.add_child(marker)

	# Pit zones — deep dark holes with edge glow
	for pit_pos in arena_data.pit_zones:
		var pit := _create_pit_visual(pit_pos, arena_data.pit_radius)
		pit.name = "PitZone"
		_hazards_node.add_child(pit)

func _create_ground_body(pos: Vector3, box_size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	shape.shape = box
	body.add_child(shape)

	# Main ground mesh with PBR material
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = arena_data.ground_color
	mat.roughness = 0.85
	mat.metallic = 0.0
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	# Edge trim — raised border along the top surface
	var trim := MeshInstance3D.new()
	var trim_mesh := BoxMesh.new()
	trim_mesh.size = Vector3(box_size.x + 0.2, 0.15, box_size.z + 0.2)
	trim.mesh = trim_mesh
	trim.position = Vector3(0, box_size.y / 2.0, 0)
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = arena_data.ground_color.darkened(0.3)
	trim_mat.roughness = 0.6
	trim_mat.metallic = 0.2
	trim.material_override = trim_mat
	body.add_child(trim)

	# Scatter small grass tufts on the ground surface
	_add_grass_patches(body, box_size)

	return body

func _add_grass_patches(parent: Node3D, area_size: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(parent.name)
	var count := int(area_size.x * area_size.z * 0.03)  # Density
	for i in range(count):
		var x := rng.randf_range(-area_size.x / 2.0 + 0.5, area_size.x / 2.0 - 0.5)
		var z := rng.randf_range(-area_size.z / 2.0 + 0.5, area_size.z / 2.0 - 0.5)
		var tuft := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = rng.randf_range(0.15, 0.3)
		cone.height = rng.randf_range(0.2, 0.45)
		tuft.mesh = cone
		tuft.position = Vector3(x, area_size.y / 2.0 + cone.height / 2.0, z)
		var grass_mat := StandardMaterial3D.new()
		var green_var := rng.randf_range(-0.05, 0.05)
		grass_mat.albedo_color = Color(
			arena_data.ground_color.r + green_var,
			arena_data.ground_color.g + 0.15 + green_var,
			arena_data.ground_color.b + green_var
		)
		grass_mat.roughness = 0.9
		tuft.material_override = grass_mat
		parent.add_child(tuft)

func _create_hazard_disc(pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	# Raised hazard platform with glowing emission
	var mesh_inst := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius + 0.2
	cylinder.height = 0.15
	mesh_inst.mesh = cylinder
	mesh_inst.position = Vector3(pos.x, 0.075, pos.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 0.8
	mesh_inst.material_override = mat

	# Outer warning ring
	var ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = radius * 0.7
	ring_mesh.bottom_radius = radius * 0.7
	ring_mesh.height = 0.02
	ring.mesh = ring_mesh
	ring.position = Vector3(0, 0.08, 0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5, 0.6)
	ring_mat.emission_enabled = true
	ring_mat.emission = color.lightened(0.3)
	ring_mat.emission_energy_multiplier = 2.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_mat
	mesh_inst.add_child(ring)

	return mesh_inst

func _create_pit_visual(pos: Vector3, radius: float) -> Node3D:
	var pit_node := Node3D.new()
	pit_node.position = Vector3(pos.x, 0, pos.z)

	# Deep hole (dark cylinder going down)
	var hole := MeshInstance3D.new()
	var hole_mesh := CylinderMesh.new()
	hole_mesh.top_radius = radius
	hole_mesh.bottom_radius = radius * 0.8
	hole_mesh.height = 2.0
	hole.mesh = hole_mesh
	hole.position = Vector3(0, -1.0, 0)
	var hole_mat := StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0.02, 0.01, 0.05)
	hole_mat.roughness = 1.0
	hole.material_override = hole_mat
	pit_node.add_child(hole)

	# Glowing edge ring
	var edge := MeshInstance3D.new()
	var edge_mesh := CylinderMesh.new()
	edge_mesh.top_radius = radius + 0.15
	edge_mesh.bottom_radius = radius + 0.15
	edge_mesh.height = 0.12
	edge.mesh = edge_mesh
	edge.position = Vector3(0, 0.06, 0)
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.5, 0.15, 0.6)
	edge_mat.emission_enabled = true
	edge_mat.emission = Color(0.6, 0.2, 0.8)
	edge_mat.emission_energy_multiplier = 1.5
	edge_mat.roughness = 0.3
	edge.material_override = edge_mat
	pit_node.add_child(edge)

	# Bottom glow (faint light from below)
	var glow := MeshInstance3D.new()
	var glow_mesh := CylinderMesh.new()
	glow_mesh.top_radius = radius * 0.5
	glow_mesh.bottom_radius = radius * 0.5
	glow_mesh.height = 0.05
	glow.mesh = glow_mesh
	glow.position = Vector3(0, -1.8, 0)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.4, 0.1, 0.5)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.6, 0.15, 0.8)
	glow_mat.emission_energy_multiplier = 3.0
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.material_override = glow_mat
	pit_node.add_child(glow)

	return pit_node
