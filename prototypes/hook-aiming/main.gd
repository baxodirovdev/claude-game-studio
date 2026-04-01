# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does hook-aiming with joystick-as-aim feel good on mobile touch?
# Date: 2026-03-28

extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $IsometricCamera
@onready var hook_button: Control = $UI/HookButton
@onready var joystick: Control = $UI/Joystick

var hook_projectile: MeshInstance3D = null
var hook_active: bool = false
var hook_direction: Vector3 = Vector3.ZERO
var hook_origin: Vector3 = Vector3.ZERO
var hook_distance_traveled: float = 0.0
var hook_returning: bool = false
var hook_cooldown_timer: float = 0.0
var pull_target: Node3D = null
var pull_progress: float = 0.0
var pull_start: Vector3 = Vector3.ZERO

# Chain visual (reused, not recreated every frame)
var chain_mesh_instance: MeshInstance3D = null
var chain_material: StandardMaterial3D = null

# --- Tuning knobs (hardcoded for prototype) ---
const MOVE_SPEED: float = 10.0
const HOOK_SPEED: float = 30.0
const HOOK_RETURN_SPEED: float = 45.0  # Faster return for snappy feel
const HOOK_RANGE: float = 25.0
const HOOK_DAMAGE: float = 30.0
const HOOK_COOLDOWN: float = 2.0
const HOOK_HITBOX_RADIUS: float = 1.0
const PULL_DURATION: float = 0.5
const CAMERA_FOLLOW_SPEED: float = 8.0
const CAMERA_GAP_OFFSET: float = 5.0

# Joystick state
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_direction: Vector2 = Vector2.ZERO
var facing_angle: float = 0.0
const JOYSTICK_RADIUS: float = 100.0
const DEAD_ZONE: float = 10.0

# Arena is now left-to-right: gap runs along Z at X=0.
# Camera looks from +Z toward -Z, so X = screen left-right.
# No isometric rotation needed — joystick maps directly to world axes.
const ISO_ANGLE: float = 0.0

# Hook button state
var hook_button_touch_index: int = -1

# Stats for prototype report
var hooks_fired: int = 0
var hooks_hit: int = 0
var hooks_missed: int = 0
var _camera_rotation: Vector3 = Vector3.ZERO

const CAMERA_OFFSET := Vector3(0, 25, 20)  # Fixed offset from follow target

func _ready() -> void:
	_build_arena_walls()
	_spawn_targets()
	_setup_chain()
	facing_angle = 0.0  # Face toward gap (+X direction, toward right/enemy side)
	# Apply initial facing
	var world_dir := _facing_to_world_dir(facing_angle)
	player.rotation.y = atan2(-world_dir.x, -world_dir.z)
	# Initialize camera — set position and rotation once, then only move position
	var target_pos := player.global_position + Vector3(CAMERA_GAP_OFFSET, 0, 0)
	camera.global_position = target_pos + CAMERA_OFFSET
	camera.look_at(target_pos)
	# Store the rotation so we never call look_at again
	_camera_rotation = camera.rotation

func _physics_process(delta: float) -> void:
	_process_movement(delta)
	_process_hook(delta)
	_process_pull(delta)
	_update_camera(delta)
	_update_cooldown(delta)
	_update_ui()
	_update_chain()

# --- HELPERS: direction conversion ---

func _facing_to_world_dir(angle: float) -> Vector3:
	var screen_dir := Vector2(cos(angle), -sin(angle))
	var rotated := screen_dir.rotated(ISO_ANGLE)
	return Vector3(rotated.x, 0, rotated.y).normalized()

# --- CHAIN SETUP (reuse instead of recreating every frame) ---

func _setup_chain() -> void:
	chain_mesh_instance = MeshInstance3D.new()
	chain_mesh_instance.name = "HookChain"
	chain_material = StandardMaterial3D.new()
	chain_material.albedo_color = Color.RED
	chain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chain_mesh_instance.material_override = chain_material
	chain_mesh_instance.visible = false
	add_child(chain_mesh_instance)

# --- MOVEMENT ---

func _process_movement(delta: float) -> void:
	if hook_active or pull_target != null:
		player.velocity = Vector3.ZERO
		player.move_and_slide()
		return  # Locked during hook flight or pull

	if joystick_direction.length() > 0:
		var rotated := joystick_direction.rotated(ISO_ANGLE)
		var move_dir := Vector3(rotated.x, 0, rotated.y)
		player.velocity = move_dir * MOVE_SPEED
	else:
		player.velocity = Vector3.ZERO
	player.move_and_slide()

	# Update facing rotation to match hook fire direction
	var world_dir := _facing_to_world_dir(facing_angle)
	player.rotation.y = atan2(-world_dir.x, -world_dir.z)

# --- HOOK ---

func _process_hook(delta: float) -> void:
	if hook_projectile == null:
		return

	if hook_returning:
		# Animate hook returning to player
		var player_hand := player.global_position + Vector3(0, 0.5, 0)
		var to_player := player_hand - hook_projectile.global_position
		var dist_to_player := to_player.length()

		if dist_to_player < 1.0:
			# Reached player — remove hook
			_remove_hook()
			return

		# Move toward player
		var return_dir := to_player.normalized()
		hook_projectile.global_position += return_dir * HOOK_RETURN_SPEED * delta
		return

	# --- Forward travel ---
	hook_projectile.global_position += hook_direction * HOOK_SPEED * delta
	hook_distance_traveled += HOOK_SPEED * delta

	# Check max range
	if hook_distance_traveled >= HOOK_RANGE:
		hooks_missed += 1
		_start_hook_return()
		return

	# Check collision with targets
	var hook_pos := hook_projectile.global_position
	for target in get_tree().get_nodes_in_group("targets"):
		if not target.visible:
			continue
		var dist := hook_pos.distance_to(target.global_position)
		if dist < HOOK_HITBOX_RADIUS + 0.5:
			hooks_hit += 1
			_on_hook_hit(target)
			return

	# Check collision with arena boundaries (AABB)
	# Arena: X: -23 to 23, Z: -20 to 20. Gap at X: -3 to 3 (no hook collision)
	if abs(hook_pos.x) > 23.0 or abs(hook_pos.z) > 20.0:
		hooks_missed += 1
		_start_hook_return()

func _fire_hook() -> void:
	if hook_active or hook_cooldown_timer > 0:
		return

	hooks_fired += 1
	hook_active = true
	hook_returning = false
	hook_distance_traveled = 0.0
	hook_origin = player.global_position

	# Direction from facing angle
	hook_direction = _facing_to_world_dir(facing_angle)

	# Create projectile visual (simple sphere)
	hook_projectile = _create_sphere(0.3, Color.RED)
	add_child(hook_projectile)
	hook_projectile.global_position = player.global_position + Vector3(0, 0.5, 0)

func _on_hook_hit(target: Node3D) -> void:
	pull_target = target
	pull_progress = 0.0
	pull_start = target.global_position
	_start_hook_return()

func _start_hook_return() -> void:
	hook_returning = true

func _remove_hook() -> void:
	if hook_projectile:
		hook_projectile.queue_free()
		hook_projectile = null
	chain_mesh_instance.visible = false
	hook_active = false
	hook_returning = false
	hook_cooldown_timer = HOOK_COOLDOWN

# --- PULL ---

func _process_pull(delta: float) -> void:
	if pull_target == null:
		return

	pull_progress += (1.0 / PULL_DURATION) * delta
	if pull_progress >= 1.0:
		pull_target.global_position = player.global_position
		_on_pull_complete()
		return

	pull_target.global_position = pull_start.lerp(player.global_position, pull_progress)

func _on_pull_complete() -> void:
	if pull_target:
		pull_target.visible = false
		var t := pull_target
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(t):
				t.visible = true
				t.global_position = t.get_meta("spawn_pos")
		)
	pull_target = null

# --- CAMERA ---

func _update_camera(delta: float) -> void:
	var target_pos := player.global_position + Vector3(CAMERA_GAP_OFFSET, 0, 0)
	var cam_target := target_pos + CAMERA_OFFSET
	# Only move position — never change rotation. This keeps the view angle fixed.
	camera.global_position = camera.global_position.lerp(cam_target, CAMERA_FOLLOW_SPEED * delta)
	camera.rotation = _camera_rotation

# --- COOLDOWN ---

func _update_cooldown(delta: float) -> void:
	if hook_cooldown_timer > 0:
		hook_cooldown_timer -= delta
		if hook_cooldown_timer < 0:
			hook_cooldown_timer = 0

# --- TOUCH INPUT ---

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var half_x := screen_size.x / 2.0

	if event.pressed:
		if event.position.x < half_x:
			# Left side - joystick
			joystick_active = true
			joystick_touch_index = event.index
			# Joystick is a direct child of CanvasLayer, so position = screen position
			joystick_center = joystick.position + joystick.size / 2.0
			_update_joystick(event.position)
		else:
			# Right side - hook button
			hook_button_touch_index = event.index
			_fire_hook()
	else:
		if event.index == joystick_touch_index:
			joystick_active = false
			joystick_touch_index = -1
			joystick_direction = Vector2.ZERO
			$UI/Joystick/Thumb.position = Vector2(80, 80)
		elif event.index == hook_button_touch_index:
			hook_button_touch_index = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_index:
		_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var offset := touch_pos - joystick_center
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS

	if offset.length() < DEAD_ZONE:
		joystick_direction = Vector2.ZERO
		$UI/Joystick/Thumb.position = Vector2(80, 80)
		return

	joystick_direction = offset.normalized()
	facing_angle = atan2(-offset.y, offset.x)

	var joy_size := joystick.size
	$UI/Joystick/Thumb.position = (joy_size / 2.0 - Vector2(20, 20)) + offset

# --- UI ---

func _update_ui() -> void:
	if hook_active:
		hook_button.modulate = Color(0.5, 0.5, 0.5, 0.7)
	elif hook_cooldown_timer > 0:
		hook_button.modulate = Color(0.7, 0.5, 0.5, 0.8)
	else:
		hook_button.modulate = Color(1, 1, 1, 1)

	if hook_cooldown_timer > 0:
		$UI/CooldownLabel.text = "%.1f" % hook_cooldown_timer
		$UI/CooldownLabel.visible = true
	else:
		$UI/CooldownLabel.visible = false

	$UI/StatsLabel.text = "Fired: %d | Hit: %d | Miss: %d | Acc: %s%%" % [
		hooks_fired, hooks_hit, hooks_missed,
		"%.0f" % (float(hooks_hit) / max(hooks_fired, 1) * 100)
	]

func _update_chain() -> void:
	if hook_projectile == null or not is_instance_valid(hook_projectile):
		chain_mesh_instance.visible = false
		return

	var im: ImmediateMesh
	if chain_mesh_instance.mesh is ImmediateMesh:
		im = chain_mesh_instance.mesh as ImmediateMesh
		im.clear_surfaces()
	else:
		im = ImmediateMesh.new()
		chain_mesh_instance.mesh = im

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(player.global_position + Vector3(0, 0.5, 0))
	im.surface_add_vertex(hook_projectile.global_position)
	im.surface_end()

	chain_mesh_instance.visible = true

# --- HELPERS ---

func _create_sphere(radius: float, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat
	return mesh_instance

func _spawn_targets() -> void:
	# Targets on the RIGHT side of the gap (positive X = enemy territory)
	var positions := [
		Vector3(12, 0.5, -6),
		Vector3(15, 0.5, 0),
		Vector3(12, 0.5, 6),
	]
	for i in range(positions.size()):
		var target := _create_sphere(0.5, Color.ORANGE)
		target.name = "Target_%d" % i
		target.set_meta("spawn_pos", positions[i])
		target.add_to_group("targets")
		add_child(target)
		target.global_position = positions[i]

func _build_arena_walls() -> void:
	# Arena: gap runs along Z at X=0. Team A on left (X<0), Team B on right (X>0).
	# Playable area: X: -23 to 23, Z: -20 to 20. Gap: X: -3 to 3.

	var walls := [
		# Boundary walls [position, size]
		[Vector3(0, 1, 21), Vector3(48, 4, 2)],     # North wall (Z+)
		[Vector3(0, 1, -21), Vector3(48, 4, 2)],     # South wall (Z-)
		[Vector3(24, 1, 0), Vector3(2, 4, 42)],      # East wall (X+)
		[Vector3(-24, 1, 0), Vector3(2, 4, 42)],     # West wall (X-)
		# Gap walls — block walking into the gap
		[Vector3(-3, 1, 0), Vector3(0.5, 4, 42)],    # Left gap edge
		[Vector3(3, 1, 0), Vector3(0.5, 4, 42)],     # Right gap edge
	]

	for wall_data in walls:
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall_data[1]
		shape.shape = box
		wall.add_child(shape)
		add_child(wall)
		wall.global_position = wall_data[0]
