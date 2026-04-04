## Hero Model Builder — constructs 3D character models from combined primitives.
##
## Each hero gets a distinct silhouette built from Godot mesh primitives.
## Models are purely visual — collision uses the existing CapsuleShape3D.
## Called by Main when creating player meshes.
class_name HeroModelBuilder
extends RefCounted

## Build a hero model and attach it to the given parent node.
## Replaces the default MeshInstance3D with a multi-mesh character.
static func build_model(parent: Node3D, hero_config: HeroConfig) -> void:
	# Remove existing simple mesh
	var old_mesh := parent.get_node_or_null("MeshInstance3D")
	if old_mesh:
		old_mesh.queue_free()

	var model := Node3D.new()
	model.name = "MeshInstance3D"  # Keep same name for compatibility
	parent.add_child(model)

	match hero_config.hook_type:
		HeroConfig.HookType.PULL:
			_build_pudge(model, hero_config.hero_color)
		HeroConfig.HookType.GRAPPLE:
			_build_lash(model, hero_config.hero_color)
		HeroConfig.HookType.BOOMERANG:
			_build_maw(model, hero_config.hero_color)
		HeroConfig.HookType.BEAM:
			_build_flux(model, hero_config.hero_color)
		HeroConfig.HookType.CHARGE:
			_build_coil(model, hero_config.hero_color)
		_:
			_build_pudge(model, hero_config.hero_color)

## Pudge — bulky, round, menacing. Wide body, small head, thick arms.
static func _build_pudge(model: Node3D, color: Color) -> void:
	var body_mat := _make_mat(color, 0.7, 0.1)
	var dark_mat := _make_mat(color.darkened(0.3), 0.6, 0.15)
	var eye_mat := _make_mat(Color(1.0, 0.9, 0.2), 0.3, 0.0, true, Color(1.0, 0.8, 0.1), 2.0)

	# Torso — wide sphere
	var torso := _mesh(SphereMesh.new(), body_mat)
	(torso.mesh as SphereMesh).radius = 0.55
	(torso.mesh as SphereMesh).height = 0.9
	torso.position = Vector3(0, 0.5, 0)
	model.add_child(torso)

	# Belly — slightly larger, overlapping
	var belly := _mesh(SphereMesh.new(), body_mat)
	(belly.mesh as SphereMesh).radius = 0.5
	(belly.mesh as SphereMesh).height = 0.7
	belly.position = Vector3(0, 0.3, 0.1)
	model.add_child(belly)

	# Head — smaller sphere on top
	var head := _mesh(SphereMesh.new(), dark_mat)
	(head.mesh as SphereMesh).radius = 0.28
	(head.mesh as SphereMesh).height = 0.5
	head.position = Vector3(0, 1.0, 0)
	model.add_child(head)

	# Eyes — two small glowing spheres
	for side in [-1.0, 1.0]:
		var eye := _mesh(SphereMesh.new(), eye_mat)
		(eye.mesh as SphereMesh).radius = 0.06
		(eye.mesh as SphereMesh).height = 0.12
		eye.position = Vector3(side * 0.12, 1.05, -0.22)
		model.add_child(eye)

	# Arms — cylinders
	for side in [-1.0, 1.0]:
		var arm := _mesh(CylinderMesh.new(), dark_mat)
		(arm.mesh as CylinderMesh).top_radius = 0.1
		(arm.mesh as CylinderMesh).bottom_radius = 0.14
		(arm.mesh as CylinderMesh).height = 0.5
		arm.position = Vector3(side * 0.55, 0.5, 0)
		arm.rotation_degrees = Vector3(0, 0, side * -20)
		model.add_child(arm)

## Lash — slim, agile. Thin body, long limbs.
static func _build_lash(model: Node3D, color: Color) -> void:
	var body_mat := _make_mat(color, 0.6, 0.1)
	var accent_mat := _make_mat(color.lightened(0.2), 0.5, 0.2)

	var torso := _mesh(CapsuleMesh.new(), body_mat)
	(torso.mesh as CapsuleMesh).radius = 0.25
	(torso.mesh as CapsuleMesh).height = 0.9
	torso.position = Vector3(0, 0.55, 0)
	model.add_child(torso)

	var head := _mesh(SphereMesh.new(), accent_mat)
	(head.mesh as SphereMesh).radius = 0.2
	(head.mesh as SphereMesh).height = 0.35
	head.position = Vector3(0, 1.1, 0)
	model.add_child(head)

	for side in [-1.0, 1.0]:
		var arm := _mesh(CylinderMesh.new(), body_mat)
		(arm.mesh as CylinderMesh).top_radius = 0.06
		(arm.mesh as CylinderMesh).bottom_radius = 0.08
		(arm.mesh as CylinderMesh).height = 0.6
		arm.position = Vector3(side * 0.35, 0.6, 0)
		arm.rotation_degrees = Vector3(0, 0, side * -15)
		model.add_child(arm)

## Maw — heavy, armored. Box-like body, flat head.
static func _build_maw(model: Node3D, color: Color) -> void:
	var body_mat := _make_mat(color, 0.8, 0.2)
	var plate_mat := _make_mat(color.darkened(0.2), 0.5, 0.35)

	var torso := _mesh(BoxMesh.new(), body_mat)
	(torso.mesh as BoxMesh).size = Vector3(0.7, 0.8, 0.5)
	torso.position = Vector3(0, 0.5, 0)
	model.add_child(torso)

	var head := _mesh(BoxMesh.new(), plate_mat)
	(head.mesh as BoxMesh).size = Vector3(0.5, 0.35, 0.4)
	head.position = Vector3(0, 1.05, 0)
	model.add_child(head)

	# Shoulder plates
	for side in [-1.0, 1.0]:
		var plate := _mesh(BoxMesh.new(), plate_mat)
		(plate.mesh as BoxMesh).size = Vector3(0.25, 0.2, 0.35)
		plate.position = Vector3(side * 0.5, 0.85, 0)
		model.add_child(plate)

## Flux — ethereal, energy. Floating sphere body with orbiting rings.
static func _build_flux(model: Node3D, color: Color) -> void:
	var body_mat := _make_mat(color, 0.3, 0.1, true, color, 1.5)
	var ring_mat := _make_mat(color.lightened(0.3), 0.2, 0.5, true, color.lightened(0.3), 2.0)

	var core := _mesh(SphereMesh.new(), body_mat)
	(core.mesh as SphereMesh).radius = 0.35
	(core.mesh as SphereMesh).height = 0.7
	core.position = Vector3(0, 0.6, 0)
	model.add_child(core)

	# Orbital ring
	var ring := _mesh(CylinderMesh.new(), ring_mat)
	(ring.mesh as CylinderMesh).top_radius = 0.5
	(ring.mesh as CylinderMesh).bottom_radius = 0.5
	(ring.mesh as CylinderMesh).height = 0.04
	ring.position = Vector3(0, 0.6, 0)
	ring.rotation_degrees = Vector3(15, 0, 10)
	model.add_child(ring)

	var head := _mesh(SphereMesh.new(), body_mat)
	(head.mesh as SphereMesh).radius = 0.2
	(head.mesh as SphereMesh).height = 0.38
	head.position = Vector3(0, 1.05, 0)
	model.add_child(head)

## Coil — mechanical, spring-like. Stacked discs body.
static func _build_coil(model: Node3D, color: Color) -> void:
	var body_mat := _make_mat(color, 0.5, 0.3)
	var metal_mat := _make_mat(color.darkened(0.2), 0.3, 0.6)

	# Stacked rings for spring-like body
	for i in range(5):
		var ring := _mesh(CylinderMesh.new(), body_mat if i % 2 == 0 else metal_mat)
		var r := 0.3 - float(i) * 0.02
		(ring.mesh as CylinderMesh).top_radius = r
		(ring.mesh as CylinderMesh).bottom_radius = r
		(ring.mesh as CylinderMesh).height = 0.15
		ring.position = Vector3(0, 0.2 + float(i) * 0.18, 0)
		model.add_child(ring)

	var head := _mesh(SphereMesh.new(), metal_mat)
	(head.mesh as SphereMesh).radius = 0.22
	(head.mesh as SphereMesh).height = 0.4
	head.position = Vector3(0, 1.15, 0)
	model.add_child(head)

## --- Helpers ---

static func _make_mat(color: Color, roughness: float, metallic: float,
		emission: bool = false, emit_color: Color = Color.BLACK,
		emit_energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission:
		mat.emission_enabled = true
		mat.emission = emit_color
		mat.emission_energy_multiplier = emit_energy
	return mat

static func _mesh(mesh_res: Mesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh_res
	mi.material_override = mat
	return mi
