## Hero Model Builder — constructs 3D character models from combined primitives.
##
## Each hero gets a distinct silhouette built from Godot mesh primitives.
## Models are purely visual — collision uses the existing CapsuleShape3D.
## Called by Main when creating player meshes.
##
## OVERRIDE WITH A PRE-MADE GLB:
## Drop a model at `res://assets/models/heroes/<hero_id>.glb` and this
## builder will use it instead of the primitive composition. Falls back to
## the primitive builder when the GLB is missing, so you can adopt
## pre-made models hero-by-hero without breaking anything.
class_name HeroModelBuilder
extends RefCounted

const HERO_GLB_PATH := "res://assets/models/heroes/%s.glb"
const HERO_HOOK_GLB_PATH := "res://assets/models/heroes/%s_hook.glb"
const HERO_BODY_TINT_SHADER := "res://assets/shaders/hero_body_tint.gdshader"

# Socket spec (brief §6). Position is the rest-pose local offset for the
# pre-rig fallback (Marker3D); the rig path replaces these with
# BoneAttachment3D using the bone names below.
# Bones author as `mixamorig:Name` in Blender, but Godot's glTF importer
# sanitizes the `:` to `_` on import, so the runtime skeleton names are
# `mixamorig_Name`. Match the sanitized form here (epic story-001).
const HERO_SOCKETS := {
	"socket_hook_hand": {
		"position": Vector3(-0.84, 0.50, -0.10),
		"bone": "mixamorig_LeftHand",
	},
	"socket_offhand": {
		"position": Vector3(0.84, 0.50, -0.10),
		"bone": "mixamorig_RightHand",
	},
	"socket_chain_origin": {
		"position": Vector3(0.0, 1.16, 0.0),
		"bone": "mixamorig_Spine2",
	},
	"socket_hit_center": {
		"position": Vector3(0.0, 0.96, -0.22),
		"bone": "mixamorig_Spine1",
	},
	"socket_head_top": {
		"position": Vector3(0.0, 1.88, 0.0),
		"bone": "mixamorig_Head",
	},
}

## Build a hero model and attach it to the given parent node.
## Replaces the default MeshInstance3D with a multi-mesh character.
static func build_model(parent: Node3D, hero_config: HeroConfig) -> void:
	# Remove any existing hero model(s). Match by meta as well as name, and
	# detach immediately (remove_child) rather than only queue_free: queue_free
	# is deferred, so on a rebuild the same frame the "MeshInstance3D" name would
	# collide, the new node would get a mangled name, and the prior instance
	# would linger as a second (static) copy overlapping the new one.
	for child in parent.get_children():
		if child.name == "MeshInstance3D" or child.has_meta("hero_model"):
			parent.remove_child(child)
			child.queue_free()

	# If a pre-made GLB exists for this hero, use it and skip the primitive
	# builder entirely. Pre-made models are expected to have feet at Y=0.
	var glb_path: String = HERO_GLB_PATH % hero_config.hero_id
	if ResourceLoader.exists(glb_path):
		var scene: PackedScene = load(glb_path)
		if scene != null:
			var glb_root: Node3D = scene.instantiate()
			if glb_root != null:
				glb_root.name = "MeshInstance3D"
				glb_root.set_meta("hero_model", true)
				# GLB exports with the character facing +Z; Godot's forward is
				# -Z (the convention player_controller's facing logic assumes),
				# so flip 180° about Y so the model faces its movement/aim.
				glb_root.rotation.y = PI
				parent.add_child(glb_root)
				_apply_hero_tint(glb_root, hero_config.hero_color)
				_setup_hero_sockets(glb_root, hero_config.hero_id)
				_attach_hook_prop(glb_root, hero_config.hero_id)
				return

	var model := Node3D.new()
	model.name = "MeshInstance3D"  # Keep same name for compatibility
	model.set_meta("hero_model", true)
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


## --- GLB integration helpers (Stage 8 partial — pre-Mixamo) ---

## Walk the imported GLB scene and override every MeshInstance3D's material
## with the hero body tint shader. The tint shader keeps non-skin vertex
## colors intact and tints only the skin band (yellow-green hue range)
## using the hero's per-team color. Once the textured PBR pass lands, this
## function will additionally bind the BaseColor / Normal / ORM / Emissive /
## TintMask textures from `design/gdd/materials/pudge.md`.
static func _apply_hero_tint(root: Node3D, tint_color: Color) -> void:
	var shader := load(HERO_BODY_TINT_SHADER) as Shader
	if shader == null:
		push_warning("HeroModelBuilder: tint shader missing at %s" % HERO_BODY_TINT_SHADER)
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tint_color", tint_color)
	mat.set_shader_parameter("tint_strength", 1.0)
	for n in _all_descendants(root):
		if n is MeshInstance3D:
			(n as MeshInstance3D).material_override = mat


## Add 5 socket nodes (brief §6) under the imported GLB.
##
## If the import contains a Skeleton3D (Mixamo-rigged path), each socket
## becomes a `BoneAttachment3D` bound to the bone listed in `HERO_SOCKETS`.
## If there is no skeleton (current pre-Mixamo state), each socket is a
## `Marker3D` placed at the rest-pose offset — gameplay code can already
## query these by name; they will silently start tracking bones once the
## rigged GLB lands and replaces the placeholders.
static func _setup_hero_sockets(root: Node3D, hero_id: String) -> void:
	var skeleton: Skeleton3D = _find_first_skeleton(root)
	for socket_name in HERO_SOCKETS.keys():
		var spec: Dictionary = HERO_SOCKETS[socket_name]
		var node: Node3D
		if skeleton != null:
			var bone_idx: int = skeleton.find_bone(spec["bone"])
			if bone_idx == -1:
				push_warning("HeroModelBuilder[%s]: bone %s not found, falling back to Marker3D" % [hero_id, spec["bone"]])
				node = Marker3D.new()
				node.position = spec["position"]
			else:
				var ba := BoneAttachment3D.new()
				ba.bone_idx = bone_idx
				ba.bone_name = spec["bone"]
				node = ba
				skeleton.add_child(ba)
				ba.name = socket_name
				continue
		else:
			node = Marker3D.new()
			node.position = spec["position"]
		node.name = socket_name
		root.add_child(node)


## Load the hero's separate hook prop GLB (if present) and parent it to the
## hook-hand socket. Called only on the rigged path — without bones the
## socket is a static Marker3D and the prop just hangs at the rest position.
static func _attach_hook_prop(root: Node3D, hero_id: String) -> void:
	var hook_path: String = HERO_HOOK_GLB_PATH % hero_id
	if not ResourceLoader.exists(hook_path):
		return
	var hook_socket: Node = root.get_node_or_null("socket_hook_hand")
	if hook_socket == null:
		# Fall back: the rig path attached socket under skeleton, search for it.
		hook_socket = _find_node_named(root, "socket_hook_hand")
	if hook_socket == null:
		return
	var hook_scene: PackedScene = load(hook_path)
	if hook_scene == null:
		return
	var hook_inst: Node = hook_scene.instantiate()
	if hook_inst == null:
		return
	hook_inst.name = "hook_prop"
	hook_socket.add_child(hook_inst)


static func _all_descendants(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_all_descendants(child))
	return out


static func _find_first_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_first_skeleton(child)
		if found != null:
			return found
	return null


static func _find_node_named(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_node_named(child, target)
		if found != null:
			return found
	return null
