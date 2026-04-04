## Hook System — manages hook firing, hit processing, pull execution, and stats.
##
## One HookSystem per player. Listens to InputManager for fire requests.
## Coordinates with PlayerController (lock/unlock), HealthComponent (damage),
## and Arena (wall collision, hazard detection during pull).
class_name HookSystem
extends Node

signal hook_fired
signal hook_hit(target: Node3D)
signal hook_missed
signal hook_returned
signal target_killed(target: Node3D, damage_type: String)

## Hook tuning — overridden by hero data.
@export var hook_speed: float = 30.0
@export var hook_return_speed: float = 45.0
@export var hook_range: float = 25.0
@export var hook_damage: float = 30.0
@export var hook_cooldown: float = 2.0
@export var hook_hitbox_radius: float = 1.0
@export var pull_duration: float = 0.5

## References set by Main.
var player: PlayerController
var input_manager: InputManager
var arena: Arena
var hero_config: HeroConfig

var _active_projectile: HookProjectile = null
var _pull_target: PlayerController = null
var _grapple_active: bool = false

# Beam state (Flux)
var _beam_active: bool = false
var _beam_target: Node3D = null
var _beam_elapsed: float = 0.0

# Charge state (Coil)
var _charging: bool = false
var _charge_time: float = 0.0
var _charge_facing: float = 0.0

# Stats
var hooks_fired: int = 0
var hooks_hit: int = 0
var hooks_missed: int = 0

## Fire the hook in the given direction. Returns true if fired.
func fire(facing_angle: float) -> bool:
	if _active_projectile != null:
		return false
	if _beam_active:
		return false

	# Beam hook type: scan and lock-on instead of projectile
	if hero_config and hero_config.hook_type == HeroConfig.HookType.BEAM:
		return _fire_beam(facing_angle)

	# Charge hook type: start charging on first fire, release fires projectile
	if hero_config and hero_config.hook_type == HeroConfig.HookType.CHARGE:
		if not _charging:
			return _start_charge(facing_angle)
		# If already charging, this is the release
		return _release_charge()

	hooks_fired += 1

	# Calculate world direction from facing angle
	var face_dir := Vector2(cos(facing_angle), -sin(facing_angle))
	var world_dir := Vector3(face_dir.x, 0, face_dir.y).normalized()

	# Spawn projectile
	_active_projectile = HookProjectile.new()
	_active_projectile.direction = world_dir
	_active_projectile.speed = hook_speed
	_active_projectile.return_speed = hook_return_speed
	_active_projectile.max_range = hook_range
	_active_projectile.hitbox_radius = hook_hitbox_radius
	_active_projectile.owner_node = player
	_active_projectile.target_group = "hookable"

	# Set projectile color from hero config
	if hero_config:
		_active_projectile.projectile_color = hero_config.hero_color

	if arena:
		_active_projectile.arena_bounds = arena.get_arena_bounds()

	# Configure boomerang mode
	var hook_type := HeroConfig.HookType.PULL
	if hero_config:
		hook_type = hero_config.hook_type
	if hook_type == HeroConfig.HookType.BOOMERANG:
		_active_projectile.is_boomerang = true
		_active_projectile.return_hitbox_radius = hook_hitbox_radius * hero_config.boomerang_return_hitbox_mult

	# Connect signals
	_active_projectile.hit_target.connect(_on_hook_hit_target)
	_active_projectile.hit_target_return.connect(_on_boomerang_return_hit)
	_active_projectile.hit_wall.connect(_on_hook_missed)
	_active_projectile.reached_max_range.connect(_on_hook_missed)
	_active_projectile.returned_to_owner.connect(_on_hook_returned)

	# Add to scene tree and position at player
	get_tree().current_scene.add_child(_active_projectile)
	_active_projectile.global_position = player.global_position + Vector3(0, 0.5, 0)

	# Lock player and update input
	player.lock()
	input_manager.notify_hook_fired()
	input_manager.lock_joystick()

	hook_fired.emit()
	return true

func _on_hook_hit_target(target: Node3D) -> void:
	hooks_hit += 1
	hook_hit.emit(target)

	# Deal damage if target has HealthComponent
	var health := _find_health(target)
	if health:
		var dealt := health.take_damage(hook_damage, player, "HOOK")
		if health.is_dead:
			target_killed.emit(target, "HOOK")
			return  # No pull/grapple on dead target

	# Determine behavior based on hook type
	var hook_type := HeroConfig.HookType.PULL
	if hero_config:
		hook_type = hero_config.hook_type

	match hook_type:
		HeroConfig.HookType.PULL:
			# Standard: pull TARGET to HOOKER
			if target is PlayerController:
				_pull_target = target as PlayerController
				_pull_target.start_pull(player, player.global_position, pull_duration)
				_start_pull_monitor()
		HeroConfig.HookType.GRAPPLE:
			# Reverse: pull HOOKER to TARGET
			var destination := target.global_position
			player.start_pull(target, destination, _get_grapple_duration())
			_grapple_active = true
			_start_pull_monitor()
		HeroConfig.HookType.BOOMERANG:
			pass  # No pull — damage only (handled by boomerang projectile)

func _on_boomerang_return_hit(target: Node3D) -> void:
	hooks_hit += 1
	hook_hit.emit(target)

	# Deal return damage
	var return_damage := hook_damage
	if hero_config:
		return_damage = hero_config.boomerang_return_damage

	var health := _find_health(target)
	if health:
		health.take_damage(return_damage, player, "HOOK")
		if health.is_dead:
			target_killed.emit(target, "HOOK")

func _on_hook_missed() -> void:
	# Boomerang doesn't count forward misses — return pass can still hit
	var hook_type := HeroConfig.HookType.PULL
	if hero_config:
		hook_type = hero_config.hook_type
	if hook_type == HeroConfig.HookType.BOOMERANG:
		return
	hooks_missed += 1
	hook_missed.emit()

func _on_hook_returned() -> void:
	# For boomerang: check if anything was hit at all
	if _active_projectile and _active_projectile.is_boomerang:
		if _active_projectile._hit_forward.is_empty() and _active_projectile._hit_return.is_empty():
			hooks_missed += 1
			hook_missed.emit()

	_active_projectile = null

	# Unlock player and update input
	player.unlock()
	input_manager.unlock_joystick()
	input_manager.notify_hook_returned()

	hook_returned.emit()

func _start_pull_monitor() -> void:
	# Check pull progress each physics frame
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _charging:
		_process_charge(delta)
		return

	if _beam_active:
		_process_beam(delta)
		return

	if _grapple_active:
		_process_grapple_monitor()
		return

	if _pull_target == null:
		set_physics_process(false)
		return

	# Check if pull target crossed a hazard during pull
	if arena:
		if arena.is_in_gap(_pull_target.global_position):
			_pull_target.cancel_pull()
			var health := _find_health(_pull_target)
			if health:
				health.take_damage(99999, player, "HAZARD_INSTANT_KILL")
			_pull_target = null
			set_physics_process(false)
			return

		if arena.is_in_pit(_pull_target.global_position):
			_pull_target.cancel_pull()
			var health := _find_health(_pull_target)
			if health:
				health.take_damage(99999, player, "HAZARD_INSTANT_KILL")
			_pull_target = null
			set_physics_process(false)
			return

	# Check if pull completed (target returned to ACTIVE state)
	if _pull_target.state != PlayerController.State.PULLED:
		_pull_target = null
		set_physics_process(false)

func _process_grapple_monitor() -> void:
	# Monitor Lash grapple: player is being pulled to target position
	if player.state != PlayerController.State.PULLED:
		# Grapple travel complete
		_grapple_active = false
		set_physics_process(false)
		return

	# Check if player crossed a hazard during grapple travel
	if arena:
		if arena.is_in_gap(player.global_position):
			player.cancel_pull()
			var health := _find_health(player)
			if health:
				health.take_damage(99999, null, "HAZARD_INSTANT_KILL")
			_grapple_active = false
			set_physics_process(false)
			return

		if arena.is_in_pit(player.global_position):
			player.cancel_pull()
			var health := _find_health(player)
			if health:
				health.take_damage(99999, null, "HAZARD_INSTANT_KILL")
			_grapple_active = false
			set_physics_process(false)

func _get_grapple_duration() -> float:
	if hero_config:
		return hero_config.grapple_duration
	return 0.4

func _find_health(node: Node) -> HealthComponent:
	for child in node.get_children():
		if child is HealthComponent:
			return child as HealthComponent
	return null

func _ready() -> void:
	set_physics_process(false)  # Only enable during pull monitoring

## --- Charge Hook (Coil) ---

func _start_charge(facing_angle: float) -> bool:
	_charging = true
	_charge_time = 0.0
	_charge_facing = facing_angle
	player.lock()
	input_manager.lock_joystick()
	hook_fired.emit()
	set_physics_process(true)
	return true

func _release_charge() -> bool:
	var charge_progress := clampf(
		(_charge_time - hero_config.charge_min_time) /
		(hero_config.charge_max_time - hero_config.charge_min_time),
		0.0, 1.0
	)

	_charging = false
	set_physics_process(false)

	# If released before minimum charge, treat as a miss
	if _charge_time < hero_config.charge_min_time:
		hooks_fired += 1
		hooks_missed += 1
		hook_missed.emit()
		player.unlock()
		input_manager.unlock_joystick()
		input_manager.notify_hook_returned()
		hook_returned.emit()
		return true

	# Fire a powered-up projectile
	hooks_fired += 1
	var charged_damage := hook_damage * lerpf(1.0, hero_config.charge_damage_mult, charge_progress)
	var charged_range := hook_range * lerpf(1.0, hero_config.charge_range_mult, charge_progress)

	# Store originals and apply charge bonuses temporarily
	var orig_damage := hook_damage
	var orig_range := hook_range
	hook_damage = charged_damage
	hook_range = charged_range

	# Fire using standard projectile logic (reuse the rest of fire())
	var face_dir := Vector2(cos(_charge_facing), -sin(_charge_facing))
	var world_dir := Vector3(face_dir.x, 0, face_dir.y).normalized()

	_active_projectile = HookProjectile.new()
	_active_projectile.direction = world_dir
	_active_projectile.speed = hook_speed * lerpf(1.0, 1.5, charge_progress)
	_active_projectile.return_speed = hook_return_speed
	_active_projectile.max_range = charged_range
	_active_projectile.hitbox_radius = hook_hitbox_radius
	_active_projectile.owner_node = player
	_active_projectile.target_group = "hookable"
	if hero_config:
		_active_projectile.projectile_color = hero_config.hero_color
	if arena:
		_active_projectile.arena_bounds = arena.get_arena_bounds()

	_active_projectile.hit_target.connect(_on_hook_hit_target)
	_active_projectile.hit_wall.connect(_on_hook_missed)
	_active_projectile.reached_max_range.connect(_on_hook_missed)
	_active_projectile.returned_to_owner.connect(func() -> void:
		# Restore original stats after shot
		hook_damage = orig_damage
		hook_range = orig_range
		_on_hook_returned()
	)

	get_tree().current_scene.add_child(_active_projectile)
	_active_projectile.global_position = player.global_position + Vector3(0, 0.5, 0)

	input_manager.notify_hook_fired()
	return true

func _process_charge(delta: float) -> void:
	if not _charging:
		return
	_charge_time += delta
	# Auto-release at max charge
	if _charge_time >= hero_config.charge_max_time:
		_release_charge()

## --- Beam Hook (Flux) ---

func _fire_beam(facing_angle: float) -> bool:
	hooks_fired += 1

	var face_dir := Vector2(cos(facing_angle), -sin(facing_angle))
	var world_dir := Vector3(face_dir.x, 0, face_dir.y).normalized()

	# Scan for target in cone
	var target := _find_beam_target(world_dir)
	if target == null:
		hooks_missed += 1
		hook_missed.emit()
		# Brief lockout
		player.lock()
		input_manager.notify_hook_fired()
		input_manager.lock_joystick()
		hook_fired.emit()
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			player.unlock()
			input_manager.unlock_joystick()
			input_manager.notify_hook_returned()
			hook_returned.emit()
		)
		return true

	# Lock on
	hooks_hit += 1
	_beam_active = true
	_beam_target = target
	_beam_elapsed = 0.0

	player.lock()
	input_manager.notify_hook_fired()
	input_manager.lock_joystick()
	hook_fired.emit()
	hook_hit.emit(target)

	set_physics_process(true)
	return true

func _find_beam_target(direction: Vector3) -> Node3D:
	var cone_cos := cos(deg_to_rad(hero_config.beam_aim_cone))
	var best_target: Node3D = null
	var best_dist := INF

	for target in get_tree().get_nodes_in_group("hookable"):
		if target == player:
			continue
		if not target.visible:
			continue
		var to_target: Vector3 = target.global_position - player.global_position
		to_target.y = 0
		var dist := to_target.length()
		if dist > hook_range or dist < 0.5:
			continue
		var dot := to_target.normalized().dot(direction)
		if dot >= cone_cos and dist < best_dist:
			best_dist = dist
			best_target = target

	return best_target

func _process_beam(delta: float) -> void:
	if not _beam_active or _beam_target == null:
		_end_beam()
		return

	if not is_instance_valid(_beam_target) or not _beam_target.visible:
		_end_beam()
		return

	_beam_elapsed += delta

	# Deal DPS
	var health := _find_health(_beam_target)
	if health:
		var dmg := hero_config.beam_dps * delta
		health.take_damage(dmg, player, "HOOK")
		if health.is_dead:
			target_killed.emit(_beam_target, "HOOK")
			_end_beam()
			return

	# Slowly pull target toward player
	var to_player := player.global_position - _beam_target.global_position
	to_player.y = 0
	if to_player.length() > 1.5:
		_beam_target.global_position += to_player.normalized() * hero_config.beam_pull_speed * delta

	# Check range break
	var dist := player.global_position.distance_to(_beam_target.global_position)
	if dist > hook_range * 1.5:
		_end_beam()
		return

	# Check duration
	if _beam_elapsed >= hero_config.beam_duration:
		_end_beam()

func _end_beam() -> void:
	_beam_active = false
	_beam_target = null
	_beam_elapsed = 0.0
	player.unlock()
	input_manager.unlock_joystick()
	input_manager.notify_hook_returned()
	hook_returned.emit()

	# Check if we should stop physics processing
	if _pull_target == null and not _grapple_active:
		set_physics_process(false)

## --- Networking RPCs ---

## Request hook fire from client to server.
@rpc("any_peer", "call_local", "reliable")
func request_fire(facing: float) -> void:
	if not multiplayer.is_server():
		return
	# Server validates and broadcasts
	notify_fire.rpc(facing)

## Notify all peers of a hook fire (broadcast by server).
@rpc("authority", "call_local", "unreliable")
func notify_fire(facing: float) -> void:
	# Each client simulates the projectile locally
	fire(facing)

## Notify all peers of a hook hit (broadcast by server).
@rpc("authority", "call_local", "reliable")
func notify_hit(target_path: String) -> void:
	var target := get_node_or_null(target_path)
	if target:
		hook_hit.emit(target)

## Notify all peers of a hook miss (broadcast by server).
@rpc("authority", "call_local", "reliable")
func notify_miss() -> void:
	hook_missed.emit()
