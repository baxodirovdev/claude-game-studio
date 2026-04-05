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

## Pudge — massive, stitched-together butcher. Inspired by Dota 2 Pudge.
## Built from ~25 primitives for maximum detail without external models.
static func _build_pudge(model: Node3D, color: Color) -> void:
	# Materials
	var skin_mat := _make_mat(color, 0.75, 0.05)
	var skin_dark := _make_mat(color.darkened(0.25), 0.7, 0.08)
	var skin_light := _make_mat(color.lightened(0.1), 0.8, 0.05)
	var eye_mat := _make_mat(Color(1.0, 0.85, 0.1), 0.2, 0.0, true, Color(1.0, 0.7, 0.0), 3.0)
	var pupil_mat := _make_mat(Color(0.15, 0.05, 0.05), 0.9, 0.0)
	var metal_mat := _make_mat(Color(0.45, 0.42, 0.4), 0.35, 0.7)
	var metal_dark := _make_mat(Color(0.3, 0.28, 0.26), 0.4, 0.6)
	var stitch_mat := _make_mat(Color(0.2, 0.15, 0.1), 0.9, 0.0)
	var mouth_mat := _make_mat(Color(0.4, 0.08, 0.08), 0.6, 0.1)
	var belt_mat := _make_mat(Color(0.35, 0.2, 0.1), 0.7, 0.15)

	# --- TORSO: massive bloated belly ---
	var torso := _mesh(SphereMesh.new(), skin_mat)
	(torso.mesh as SphereMesh).radius = 0.6
	(torso.mesh as SphereMesh).height = 1.0
	torso.position = Vector3(0, 0.5, 0)
	model.add_child(torso)

	# Lower belly bulge (hangs forward)
	var belly := _mesh(SphereMesh.new(), skin_light)
	(belly.mesh as SphereMesh).radius = 0.55
	(belly.mesh as SphereMesh).height = 0.75
	belly.position = Vector3(0, 0.28, 0.15)
	model.add_child(belly)

	# Upper chest (slightly darker, stitched area)
	var chest := _mesh(SphereMesh.new(), skin_dark)
	(chest.mesh as SphereMesh).radius = 0.48
	(chest.mesh as SphereMesh).height = 0.6
	chest.position = Vector3(0, 0.75, -0.05)
	model.add_child(chest)

	# Belt/waistband
	var belt := _mesh(CylinderMesh.new(), belt_mat)
	(belt.mesh as CylinderMesh).top_radius = 0.58
	(belt.mesh as CylinderMesh).bottom_radius = 0.55
	(belt.mesh as CylinderMesh).height = 0.12
	belt.position = Vector3(0, 0.15, 0.05)
	model.add_child(belt)

	# Belt buckle
	var buckle := _mesh(BoxMesh.new(), metal_mat)
	(buckle.mesh as BoxMesh).size = Vector3(0.15, 0.12, 0.06)
	buckle.position = Vector3(0, 0.15, -0.55)
	model.add_child(buckle)

	# --- STITCHES: visible lines across body ---
	# Vertical stitch down center
	var stitch_v := _mesh(BoxMesh.new(), stitch_mat)
	(stitch_v.mesh as BoxMesh).size = Vector3(0.03, 0.6, 0.03)
	stitch_v.position = Vector3(0, 0.55, -0.58)
	model.add_child(stitch_v)

	# Horizontal stitches
	for y_off in [0.35, 0.55, 0.75]:
		var stitch_h := _mesh(BoxMesh.new(), stitch_mat)
		(stitch_h.mesh as BoxMesh).size = Vector3(0.4, 0.025, 0.03)
		stitch_h.position = Vector3(0, y_off, -0.56)
		model.add_child(stitch_h)

	# --- HEAD: small, hunched into shoulders ---
	var head := _mesh(SphereMesh.new(), skin_dark)
	(head.mesh as SphereMesh).radius = 0.25
	(head.mesh as SphereMesh).height = 0.42
	head.position = Vector3(0, 1.05, -0.08)
	model.add_child(head)

	# Jaw (wider lower face)
	var jaw := _mesh(SphereMesh.new(), skin_mat)
	(jaw.mesh as SphereMesh).radius = 0.18
	(jaw.mesh as SphereMesh).height = 0.2
	jaw.position = Vector3(0, 0.92, -0.18)
	model.add_child(jaw)

	# Mouth (dark slit)
	var mouth := _mesh(BoxMesh.new(), mouth_mat)
	(mouth.mesh as BoxMesh).size = Vector3(0.15, 0.04, 0.04)
	mouth.position = Vector3(0, 0.93, -0.34)
	model.add_child(mouth)

	# Eyes — asymmetric, one bigger (Pudge's deranged look)
	var eye_l := _mesh(SphereMesh.new(), eye_mat)
	(eye_l.mesh as SphereMesh).radius = 0.065
	(eye_l.mesh as SphereMesh).height = 0.13
	eye_l.position = Vector3(-0.1, 1.08, -0.28)
	model.add_child(eye_l)

	var eye_r := _mesh(SphereMesh.new(), eye_mat)
	(eye_r.mesh as SphereMesh).radius = 0.05
	(eye_r.mesh as SphereMesh).height = 0.1
	eye_r.position = Vector3(0.1, 1.06, -0.28)
	model.add_child(eye_r)

	# Pupils
	for pos in [Vector3(-0.1, 1.08, -0.34), Vector3(0.1, 1.06, -0.33)]:
		var pupil := _mesh(SphereMesh.new(), pupil_mat)
		(pupil.mesh as SphereMesh).radius = 0.025
		(pupil.mesh as SphereMesh).height = 0.05
		pupil.position = pos
		model.add_child(pupil)

	# --- ARMS: thick, meaty, different sizes ---
	# Left arm (hook arm — slightly bigger)
	var arm_l := _mesh(CylinderMesh.new(), skin_dark)
	(arm_l.mesh as CylinderMesh).top_radius = 0.16
	(arm_l.mesh as CylinderMesh).bottom_radius = 0.12
	(arm_l.mesh as CylinderMesh).height = 0.55
	arm_l.position = Vector3(-0.65, 0.55, 0)
	arm_l.rotation_degrees = Vector3(0, 0, 25)
	model.add_child(arm_l)

	# Left hand/fist
	var hand_l := _mesh(SphereMesh.new(), skin_mat)
	(hand_l.mesh as SphereMesh).radius = 0.1
	(hand_l.mesh as SphereMesh).height = 0.15
	hand_l.position = Vector3(-0.8, 0.3, 0)
	model.add_child(hand_l)

	# Right arm (cleaver arm)
	var arm_r := _mesh(CylinderMesh.new(), skin_dark)
	(arm_r.mesh as CylinderMesh).top_radius = 0.14
	(arm_r.mesh as CylinderMesh).bottom_radius = 0.1
	(arm_r.mesh as CylinderMesh).height = 0.5
	arm_r.position = Vector3(0.63, 0.55, 0)
	arm_r.rotation_degrees = Vector3(0, 0, -25)
	model.add_child(arm_r)

	# Right hand
	var hand_r := _mesh(SphereMesh.new(), skin_mat)
	(hand_r.mesh as SphereMesh).radius = 0.09
	(hand_r.mesh as SphereMesh).height = 0.13
	hand_r.position = Vector3(0.77, 0.32, 0)
	model.add_child(hand_r)

	# --- CLEAVER: held in right hand ---
	# Blade (flat box)
	var blade := _mesh(BoxMesh.new(), metal_mat)
	(blade.mesh as BoxMesh).size = Vector3(0.04, 0.35, 0.2)
	blade.position = Vector3(0.82, 0.45, -0.12)
	blade.rotation_degrees = Vector3(0, 0, -15)
	model.add_child(blade)

	# Blade edge (thinner, lighter)
	var edge := _mesh(BoxMesh.new(), _make_mat(Color(0.6, 0.58, 0.55), 0.2, 0.8))
	(edge.mesh as BoxMesh).size = Vector3(0.015, 0.32, 0.2)
	edge.position = Vector3(0.85, 0.45, -0.12)
	edge.rotation_degrees = Vector3(0, 0, -15)
	model.add_child(edge)

	# Handle
	var handle := _mesh(CylinderMesh.new(), metal_dark)
	(handle.mesh as CylinderMesh).top_radius = 0.025
	(handle.mesh as CylinderMesh).bottom_radius = 0.03
	(handle.mesh as CylinderMesh).height = 0.15
	handle.position = Vector3(0.8, 0.28, -0.12)
	model.add_child(handle)

	# --- LEGS: short, stubby ---
	for side in [-1.0, 1.0]:
		var leg := _mesh(CylinderMesh.new(), skin_dark)
		(leg.mesh as CylinderMesh).top_radius = 0.14
		(leg.mesh as CylinderMesh).bottom_radius = 0.12
		(leg.mesh as CylinderMesh).height = 0.3
		leg.position = Vector3(side * 0.22, 0.0, 0)
		model.add_child(leg)

		# Feet
		var foot := _mesh(BoxMesh.new(), skin_dark)
		(foot.mesh as BoxMesh).size = Vector3(0.16, 0.08, 0.22)
		foot.position = Vector3(side * 0.22, -0.12, -0.04)
		model.add_child(foot)

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
