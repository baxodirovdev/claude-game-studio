## Fixed-angle isometric camera that follows a target with smooth movement.
##
## Uses orthographic projection. Rotation is set once and never changes.
## Only position moves — this prevents the tilting/shifting bug from look_at().
class_name GameCamera
extends Camera3D

## The node to follow (usually the player).
@export var follow_target: Node3D
## Offset from target toward the gap (positive X = toward enemy side).
@export var gap_offset: float = 5.0
## Camera offset from the follow point (determines view angle).
@export var camera_offset: Vector3 = Vector3(0, 18, 14)
## Smoothing speed (higher = snappier).
@export var follow_speed: float = 8.0
## Perspective field of view (degrees).
@export var camera_fov: float = 45.0

var _fixed_rotation: Vector3 = Vector3.ZERO
var _initialized: bool = false
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0

func _ready() -> void:
	projection = Camera3D.PROJECTION_PERSPECTIVE
	fov = camera_fov
	near = 0.1
	far = 100.0
	# Point at the origin as a sane default until initialize() is called
	look_at(Vector3.ZERO)
	_fixed_rotation = rotation

## Call once after the arena and player are positioned to set the camera angle.
func initialize() -> void:
	if follow_target == null:
		push_error("GameCamera: follow_target not assigned!")
		return
	var target_pos := _get_follow_point()
	global_position = target_pos + camera_offset
	look_at(target_pos)
	_fixed_rotation = rotation
	_initialized = true

func _physics_process(delta: float) -> void:
	if not _initialized or follow_target == null:
		return
	var target_pos := _get_follow_point()
	var desired := target_pos + camera_offset

	# Apply screen shake offset
	if _shake_intensity > 0:
		var shake_offset := Vector3(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity),
			0
		)
		desired += shake_offset
		_shake_intensity = maxf(0.0, _shake_intensity - _shake_decay * delta)

	global_position = global_position.lerp(desired, follow_speed * delta)
	# Lock rotation — never recalculate, prevents view angle shifting
	rotation = _fixed_rotation

## Snap camera immediately to the target (for respawn, teleport).
func snap_to_target() -> void:
	if follow_target == null:
		return
	var target_pos := _get_follow_point()
	global_position = target_pos + camera_offset
	rotation = _fixed_rotation

## Trigger screen shake with given intensity.
func shake(intensity: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)

func _get_follow_point() -> Vector3:
	var pos := follow_target.global_position
	pos.x += gap_offset
	return pos
