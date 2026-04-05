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

# Cached targets — populated once on ready, avoids per-frame tree queries
var _cached_targets: Array[Node3D] = []

func _ready() -> void:
	_create_visuals()
	# Cache hookable targets once on spawn instead of querying every frame
	for node in get_tree().get_nodes_in_group(target_group):
		if node is Node3D:
			_cached_targets.append(node as Node3D)

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
	for target in _cached_targets:
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
		for target in _cached_targets:
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

## Pre-created chain link meshes for reuse
var _chain_links: Array[MeshInstance3D] = []
const CHAIN_LINK_SPACING: float = 0.8
const MAX_CHAIN_LINKS: int = 40

func _create_visuals() -> void:
	_mesh = MeshInstance3D.new()

	if is_boomerang:
		# Spinning disc for Maw
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.5
		cylinder.bottom_radius = 0.5
		cylinder.height = 0.1
		_mesh.mesh = cylinder
		var disc_mat := StandardMaterial3D.new()
		disc_mat.albedo_color = projectile_color
		disc_mat.metallic = 0.5
		disc_mat.roughness = 0.4
		_mesh.material_override = disc_mat
	else:
		# Hook head — curved hook shape from combined meshes
		_build_hook_head()

	add_child(_mesh)

	# Chain links — pre-create a pool of small torus-like link meshes
	_chain_mat = StandardMaterial3D.new()
	_chain_mat.albedo_color = Color(0.5, 0.48, 0.44)
	_chain_mat.roughness = 0.4
	_chain_mat.metallic = 0.7

	# Container for chain links (world-space)
	_chain_mesh = MeshInstance3D.new()
	_chain_mesh.name = "ChainContainer"
	add_child(_chain_mesh)

	for i in range(MAX_CHAIN_LINKS):
		var link := MeshInstance3D.new()
		var link_mesh := CylinderMesh.new()
		# Alternate orientation for chain-link look
		if i % 2 == 0:
			link_mesh.top_radius = 0.06
			link_mesh.bottom_radius = 0.06
			link_mesh.height = 0.15
		else:
			link_mesh.top_radius = 0.07
			link_mesh.bottom_radius = 0.07
			link_mesh.height = 0.1
		link.mesh = link_mesh
		link.material_override = _chain_mat
		link.visible = false
		add_child(link)
		_chain_links.append(link)

	# Also keep the ImmediateMesh for fallback
	_chain_im = ImmediateMesh.new()

func _build_hook_head() -> void:
	# Hook body — main curved hook from a cylinder bent forward
	var hook_mat := StandardMaterial3D.new()
	hook_mat.albedo_color = Color(0.55, 0.5, 0.45)
	hook_mat.roughness = 0.3
	hook_mat.metallic = 0.75
	hook_mat.emission_enabled = true
	hook_mat.emission = projectile_color
	hook_mat.emission_energy_multiplier = 0.3

	# Shaft (straight part)
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.08
	shaft_mesh.bottom_radius = 0.06
	shaft_mesh.height = 0.4
	shaft.mesh = shaft_mesh
	shaft.material_override = hook_mat
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.position = Vector3(0, 0, -0.1)
	_mesh.add_child(shaft)

	# Hook tip (curved part — sphere at the end angled down)
	var tip := MeshInstance3D.new()
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = 0.0
	tip_mesh.bottom_radius = 0.07
	tip_mesh.height = 0.25
	tip.mesh = tip_mesh
	tip.material_override = hook_mat
	tip.rotation_degrees = Vector3(45, 0, 0)
	tip.position = Vector3(0, -0.08, -0.35)
	_mesh.add_child(tip)

	# Hook barb (small spike)
	var barb := MeshInstance3D.new()
	var barb_mesh := CylinderMesh.new()
	barb_mesh.top_radius = 0.0
	barb_mesh.bottom_radius = 0.03
	barb_mesh.height = 0.12
	barb.mesh = barb_mesh
	barb.material_override = hook_mat
	barb.rotation_degrees = Vector3(-30, 0, 0)
	barb.position = Vector3(0, -0.15, -0.42)
	_mesh.add_child(barb)

	# Ring where chain attaches (back of hook)
	var ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.1
	ring_mesh.bottom_radius = 0.1
	ring_mesh.height = 0.04
	ring.mesh = ring_mesh
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.4, 0.38, 0.35)
	ring_mat.metallic = 0.8
	ring_mat.roughness = 0.3
	ring.material_override = ring_mat
	ring.position = Vector3(0, 0, 0.12)
	_mesh.add_child(ring)

func _update_chain() -> void:
	if is_boomerang:
		for link in _chain_links:
			link.visible = false
		# Spin the disc
		_mesh.rotate_y(0.3)
		return

	if owner_node == null:
		for link in _chain_links:
			link.visible = false
		return

	# Position chain links along the line from owner to hook
	var start := owner_node.global_position + Vector3(0, 0.5, 0)
	var end := global_position
	var chain_vec := end - start
	var chain_length := chain_vec.length()
	var chain_dir := chain_vec.normalized() if chain_length > 0.01 else Vector3.FORWARD
	var links_needed := mini(int(chain_length / CHAIN_LINK_SPACING), MAX_CHAIN_LINKS)

	for i in range(MAX_CHAIN_LINKS):
		if i < links_needed:
			var t := float(i + 1) / float(links_needed + 1)
			var link_pos := start.lerp(end, t)
			# Slight sag in the middle (catenary approximation)
			var sag := sin(t * PI) * chain_length * 0.02
			link_pos.y -= sag
			_chain_links[i].global_position = link_pos
			# Rotate to face along chain direction
			_chain_links[i].look_at(link_pos + chain_dir, Vector3.UP)
			# Alternate rotation for chain-link appearance
			if i % 2 == 0:
				_chain_links[i].rotate_object_local(Vector3.FORWARD, PI / 2.0)
			_chain_links[i].visible = true
		else:
			_chain_links[i].visible = false
