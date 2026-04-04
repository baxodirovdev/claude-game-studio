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
	var gap_mesh := MeshInstance3D.new()
	gap_mesh.name = "GapVisual"
	var box := BoxMesh.new()
	box.size = Vector3(arena_data.gap_width, 1, arena_data.arena_depth)
	gap_mesh.mesh = box
	gap_mesh.position = Vector3(0, -1.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = arena_data.gap_color
	gap_mesh.material_override = mat
	add_child(gap_mesh)

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

	for wall_info: Array in walls:
		var wall_pos: Vector3 = wall_info[0]
		var wall_size: Vector3 = wall_info[1]
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall_size
		shape.shape = box
		wall.add_child(shape)
		_walls_node.add_child(wall)
		wall.global_position = wall_pos

func _build_hazard_markers() -> void:
	_hazards_node = Node3D.new()
	_hazards_node.name = "HazardMarkers"
	add_child(_hazards_node)

	# Spike zone markers (red-orange discs on the ground)
	for spike_pos in arena_data.spike_zones:
		var marker := _create_hazard_disc(spike_pos, arena_data.spike_zone_radius, Color(0.9, 0.3, 0.1, 0.5))
		marker.name = "SpikeZone"
		_hazards_node.add_child(marker)

	# Pit markers (dark circles)
	for pit_pos in arena_data.pit_zones:
		var marker := _create_hazard_disc(pit_pos, arena_data.pit_radius, Color(0.1, 0.05, 0.15, 0.8))
		marker.name = "PitZone"
		_hazards_node.add_child(marker)

func _create_ground_body(pos: Vector3, box_size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	shape.shape = box
	body.add_child(shape)
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = arena_data.ground_color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	return body

func _create_hazard_disc(pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.05
	mesh_inst.mesh = cylinder
	mesh_inst.position = Vector3(pos.x, 0.01, pos.z)  # Slightly above ground
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat
	return mesh_inst
