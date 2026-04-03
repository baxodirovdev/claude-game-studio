## Enemy Health Bar — world-space health bar displayed above an enemy entity.
##
## Attaches to a Node3D and tracks its HealthComponent. Renders as two flat quads
## (background + fill) positioned above the entity. Billboard-mode faces camera.
## Hidden when entity is dead or at full health. Sprint 3 S3-09.
class_name EnemyHealthBar
extends Node3D

## Height offset above the parent entity.
const BAR_HEIGHT: float = 2.2
## Bar dimensions (world units).
const BAR_WIDTH: float = 1.2
const BAR_THICKNESS: float = 0.08

var health_component: HealthComponent
var _bg_mesh: MeshInstance3D
var _fill_mesh: MeshInstance3D
var _fill_mat: StandardMaterial3D
var _bg_mat: StandardMaterial3D

func _ready() -> void:
	_create_bar()
	visible = false

func _process(_delta: float) -> void:
	if health_component == null:
		visible = false
		return

	if health_component.is_dead:
		visible = false
		return

	var ratio := health_component.current_health / maxf(health_component.max_health, 1.0)

	# Hide at full health — no need to show
	if ratio >= 1.0:
		visible = false
		return

	visible = true

	# Scale fill bar width by health ratio
	_fill_mesh.scale.x = ratio
	# Offset fill bar to keep it left-aligned
	_fill_mesh.position.x = -(1.0 - ratio) * BAR_WIDTH * 0.5

	# Color: green > yellow > red
	if ratio > 0.5:
		_fill_mat.albedo_color = Color(0.2, 0.85, 0.2)
	elif ratio > 0.25:
		_fill_mat.albedo_color = Color(0.9, 0.8, 0.1)
	else:
		_fill_mat.albedo_color = Color(0.9, 0.15, 0.15)

func _create_bar() -> void:
	# Background (dark)
	_bg_mesh = MeshInstance3D.new()
	var bg_quad := QuadMesh.new()
	bg_quad.size = Vector2(BAR_WIDTH, BAR_THICKNESS)
	_bg_mesh.mesh = bg_quad

	_bg_mat = StandardMaterial3D.new()
	_bg_mat.albedo_color = Color(0.15, 0.15, 0.15, 0.8)
	_bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_bg_mat.no_depth_test = true
	_bg_mat.render_priority = 10
	_bg_mesh.material_override = _bg_mat
	_bg_mesh.position = Vector3(0, BAR_HEIGHT, 0)
	add_child(_bg_mesh)

	# Fill (colored)
	_fill_mesh = MeshInstance3D.new()
	var fill_quad := QuadMesh.new()
	fill_quad.size = Vector2(BAR_WIDTH, BAR_THICKNESS)
	_fill_mesh.mesh = fill_quad

	_fill_mat = StandardMaterial3D.new()
	_fill_mat.albedo_color = Color(0.2, 0.85, 0.2)
	_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_fill_mat.no_depth_test = true
	_fill_mat.render_priority = 11
	_fill_mesh.material_override = _fill_mat
	_fill_mesh.position = Vector3(0, BAR_HEIGHT, 0)
	add_child(_fill_mesh)
