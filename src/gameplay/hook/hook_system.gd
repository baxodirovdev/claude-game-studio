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

# Stats
var hooks_fired: int = 0
var hooks_hit: int = 0
var hooks_missed: int = 0

## Fire the hook in the given direction. Returns true if fired.
func fire(facing_angle: float) -> bool:
	if _active_projectile != null:
		return false

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
