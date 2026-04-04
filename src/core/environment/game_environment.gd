## Game Environment — sets up WorldEnvironment, sky, fog, bloom, and lighting.
##
## Attach to the main game scene. Creates a polished 3D atmosphere with
## procedural sky, volumetric fog, bloom glow, SSAO, and tonal color grading.
## Designed for isometric arena view.
class_name GameEnvironment
extends Node3D

var _world_env: WorldEnvironment
var _fill_light: DirectionalLight3D
var _rim_light: DirectionalLight3D
var _ambient_spots: Array[OmniLight3D] = []

func _ready() -> void:
	_create_world_environment()
	_create_lighting()

func _create_world_environment() -> void:
	_world_env = WorldEnvironment.new()
	var env := Environment.new()

	# --- Sky ---
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.05, 0.06, 0.15)       # Deep dark blue
	sky_mat.sky_horizon_color = Color(0.08, 0.1, 0.25)     # Slightly lighter horizon
	sky_mat.ground_bottom_color = Color(0.03, 0.03, 0.08)  # Near black ground
	sky_mat.ground_horizon_color = Color(0.06, 0.07, 0.18)
	sky_mat.sun_angle_max = 10.0  # Low sun for dramatic lighting
	sky_mat.sun_curve = 0.1
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.12, 0.14, 0.25)
	env.ambient_light_energy = 0.4

	# --- Tonemap ---
	env.tonemap_mode = Environment.TONE_MAP_FILMIC
	env.tonemap_white = 6.0

	# --- Bloom (glow) --- makes lights and emissive materials pop
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_strength = 0.8
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 0.8

	# --- SSAO --- depth perception
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 1.5

	# --- Fog --- atmospheric depth
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.1, 0.2)
	env.fog_density = 0.003
	env.fog_sky_affect = 0.3

	# --- Adjustments --- color grading for mood
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.05
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.15

	_world_env.environment = env
	add_child(_world_env)

func _create_lighting() -> void:
	# Main key light — warm directional from above-left
	# (supplements the existing DirectionalLight in main.tscn)
	_fill_light = DirectionalLight3D.new()
	_fill_light.light_color = Color(0.9, 0.85, 0.7)  # Warm white
	_fill_light.light_energy = 0.6
	_fill_light.rotation_degrees = Vector3(-45, 30, 0)
	_fill_light.shadow_enabled = false  # Fill only, no double shadows
	_fill_light.name = "FillLight"
	add_child(_fill_light)

	# Rim light — cool blue from behind for edge definition
	_rim_light = DirectionalLight3D.new()
	_rim_light.light_color = Color(0.4, 0.5, 0.9)  # Cool blue
	_rim_light.light_energy = 0.3
	_rim_light.rotation_degrees = Vector3(-30, -150, 0)
	_rim_light.shadow_enabled = false
	_rim_light.name = "RimLight"
	add_child(_rim_light)

	# Colored accent spots at arena edges (creates colored pools of light)
	_add_accent_light(Vector3(-15, 4, 0), Color(0.3, 0.5, 1.0), 1.0, 15.0)   # Blue team side
	_add_accent_light(Vector3(15, 4, 0), Color(1.0, 0.35, 0.25), 1.0, 15.0)  # Red team side
	_add_accent_light(Vector3(0, 3, 0), Color(0.9, 0.6, 0.1), 0.6, 10.0)     # Center gold glow

func _add_accent_light(pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.5
	light.shadow_enabled = false
	light.position = pos
	add_child(light)
	_ambient_spots.append(light)
