## Hook projectile — travels forward, checks collisions, returns to owner.
##
## Spawned by HookSystem. Manages its own travel, collision, and return.
## Does NOT handle pull logic — that's owned by HookSystem.
class_name HookProjectile
extends Node3D

signal hit_target(target: Node3D)
signal hit_target_return(target: Node3D)
signal hit_wall
signal reached_max_range
signal returned_to_owner

## Projectile color (set by HookSystem based on hero).
var projectile_color: Color = Color.RED

## Set by HookSystem on spawn.
var direction: Vector3 = Vector3.FORWARD
var speed: float = 30.0
var max_range: float = 25.0
var return_speed: float = 45.0
var hitbox_radius: float = 1.0
var owner_node: Node3D = null
var target_group: String = "hookable"

## Boomerang mode — hits on return pass too, no stop on forward hit.
var is_boomerang: bool = false
var return_hitbox_radius: float = 1.0

var _distance_traveled: float = 0.0
var _returning: bool = false
var _hit_forward: Array[Node3D] = []  # Targets hit on forward pass
var _hit_return: Array[Node3D] = []   # Targets hit on return pass
var _mesh: MeshInstance3D
var _chain_mesh: MeshInstance3D
var _chain_im: ImmediateMesh
var _chain_mat: StandardMaterial3D

# Arena bounds for wall collision (set by HookSystem)
var arena_bounds: Dictionary = {}

func _ready() -> void:
	_create_visuals()

func _physics_process(delta: float) -> void:
	if _returning:
		_process_return(delta)
	else:
		_process_forward(delta)
	_update_chain()

func start_return() -> void:
	_returning = true

func _process_forward(delta: float) -> void:
	global_position += direction * speed * delta
	_distance_traveled += speed * delta

	# Check max range
	if _distance_traveled >= max_range:
		if not is_boomerang:
			reached_max_range.emit()
		start_return()
		return

	# Check collision with targets
	for target in get_tree().get_nodes_in_group(target_group):
		if target == owner_node:
			continue
		if not target.visible:
			continue
		if target in _hit_forward:
			continue
		var dist := global_position.distance_to(target.global_position)
		if dist < hitbox_radius + 0.5:
			_hit_forward.append(target)
			hit_target.emit(target)
			if not is_boomerang:
				start_return()
				return
			# Boomerang continues traveling after hit

	# Check wall collision (arena bounds) — boomerang bounces back at walls too
	if arena_bounds.size() > 0:
		var pos := global_position
		var bounds_min: Vector3 = arena_bounds["min"]
		var bounds_max: Vector3 = arena_bounds["max"]
		if pos.x < bounds_min.x or pos.x > bounds_max.x or pos.z < bounds_min.z or pos.z > bounds_max.z:
			if not is_boomerang:
				hit_wall.emit()
			start_return()

func _process_return(delta: float) -> void:
	if owner_node == null:
		queue_free()
		return

	var target_pos := owner_node.global_position + Vector3(0, 0.5, 0)
	var to_owner := target_pos - global_position
	var dist := to_owner.length()

	if dist < 1.0:
		returned_to_owner.emit()
		queue_free()
		return

	global_position += to_owner.normalized() * return_speed * delta

	# Boomerang: check for hits on return pass
	if is_boomerang:
		var check_radius := return_hitbox_radius + 0.5
		for target in get_tree().get_nodes_in_group(target_group):
			if target == owner_node:
				continue
			if not target.visible:
				continue
			if target in _hit_return:
				continue
			var target_dist := global_position.distance_to(target.global_position)
			if target_dist < check_radius:
				_hit_return.append(target)
				hit_target_return.emit(target)

func _create_visuals() -> void:
	_mesh = MeshInstance3D.new()
	var mat := StandardMaterial3D.new()

	if is_boomerang:
		# Spinning disc for Maw
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.5
		cylinder.bottom_radius = 0.5
		cylinder.height = 0.1
		_mesh.mesh = cylinder
	else:
		# Sphere for Vex/Lash
		var sphere := SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		_mesh.mesh = sphere

	mat.albedo_color = projectile_color

	_mesh.material_override = mat
	add_child(_mesh)

	# Chain line (reused ImmediateMesh)
	_chain_mesh = MeshInstance3D.new()
	_chain_im = ImmediateMesh.new()
	_chain_mesh.mesh = _chain_im
	_chain_mat = StandardMaterial3D.new()
	_chain_mat.albedo_color = projectile_color
	_chain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_chain_mesh.material_override = _chain_mat
	# Add chain to the scene root so it renders in world space, not local
	add_child(_chain_mesh)

func _update_chain() -> void:
	if is_boomerang:
		_chain_mesh.visible = false
		# Spin the disc
		_mesh.rotate_y(0.3)
		return

	if owner_node == null:
		_chain_mesh.visible = false
		return

	_chain_im.clear_surfaces()
	_chain_im.surface_begin(Mesh.PRIMITIVE_LINES)
	_chain_im.surface_add_vertex(owner_node.global_position + Vector3(0, 0.5, 0) - global_position)
	_chain_im.surface_add_vertex(Vector3.ZERO)
	_chain_im.surface_end()
	_chain_mesh.visible = true
