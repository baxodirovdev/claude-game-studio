## VFX System — manages visual effects for hooks, hits, deaths, and respawns.
##
## Creates GPU particle effects and mesh-based flashes. All effects are fire-and-forget.
## Colors are driven by hero config. Per-hero variants use different particle shapes,
## counts, and behaviors. Purely visual — no gameplay logic.
## Sprint 3 S3-07, Sprint 4 S4-04 (per-hero differentiation).
class_name VFXSystem
extends Node3D

## --- Per-Hero Hook Trail (S4-04) ---

## Attach hero-specific hook trail particles to a projectile.
func attach_hero_hook_trail(projectile: Node3D, hero_config: HeroConfig) -> GPUParticles3D:
	match hero_config.hook_type:
		HeroConfig.HookType.PULL:
			return _attach_pull_trail(projectile, hero_config.hero_color)
		HeroConfig.HookType.GRAPPLE:
			return _attach_grapple_trail(projectile, hero_config.hero_color)
		HeroConfig.HookType.BEAM:
			return _attach_beam_trail(projectile, hero_config.hero_color)
		HeroConfig.HookType.BOOMERANG:
			return _attach_boomerang_trail(projectile, hero_config.hero_color)
		_:
			return attach_hook_trail(projectile, hero_config.hero_color)

## Vex (PULL): Electric blue chain sparks — tight, focused, crackling.
func _attach_pull_trail(projectile: Node3D, color: Color) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 25
	particles.lifetime = 0.3
	particles.emitting = true
	particles.one_shot = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 5.0  # Tight — chain sparks
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.02
	mat.scale_max = 0.08
	mat.color = Color(color.r * 1.3, color.g * 1.3, color.b * 1.5)  # Bright electric

	particles.process_material = mat

	# Small cubes for spark-like appearance
	var draw_pass := BoxMesh.new()
	draw_pass.size = Vector3(0.04, 0.04, 0.04)
	particles.draw_pass_1 = draw_pass

	projectile.add_child(particles)
	return particles

## Lash (GRAPPLE): Green energy trail — wispy, flowing, tether-like.
func _attach_grapple_trail(projectile: Node3D, color: Color) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 15
	particles.lifetime = 0.6
	particles.emitting = true
	particles.one_shot = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 20.0  # Wider — energy wisps
	mat.initial_velocity_min = 0.3
	mat.initial_velocity_max = 1.0
	mat.gravity = Vector3(0, 0.5, 0)  # Slight float up
	mat.scale_min = 0.06
	mat.scale_max = 0.2
	mat.color = Color(color.r, color.g * 1.2, color.b, 0.7)  # Semi-transparent

	particles.process_material = mat

	var draw_pass := SphereMesh.new()
	draw_pass.radius = 0.08
	draw_pass.height = 0.16
	particles.draw_pass_1 = draw_pass

	projectile.add_child(particles)
	return particles

## Maw (BOOMERANG): Orange spinning embers — wide, fiery, aggressive.
func _attach_boomerang_trail(projectile: Node3D, color: Color) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 35
	particles.lifetime = 0.5
	particles.emitting = true
	particles.one_shot = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 45.0  # Wide — spinning disc sheds embers everywhere
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 4.0
	mat.gravity = Vector3(0, -2, 0)  # Embers fall slightly
	mat.scale_min = 0.03
	mat.scale_max = 0.12
	mat.color = Color(color.r * 1.2, color.g * 0.8, 0.1)  # Hot orange-yellow

	particles.process_material = mat

	# Flat quads for ember look
	var draw_pass := QuadMesh.new()
	draw_pass.size = Vector2(0.06, 0.06)
	particles.draw_pass_1 = draw_pass

	projectile.add_child(particles)
	return particles

## Flux (BEAM): Purple magnetic field — swirling, electric.
func _attach_beam_trail(projectile: Node3D, color: Color) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 20
	particles.lifetime = 0.5
	particles.emitting = true
	particles.one_shot = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 2.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.03
	mat.scale_max = 0.1
	mat.color = Color(color.r * 1.2, color.g * 0.8, color.b * 1.4, 0.8)
	mat.orbit_velocity_min = 0.5
	mat.orbit_velocity_max = 1.5

	particles.process_material = mat

	var draw_pass := SphereMesh.new()
	draw_pass.radius = 0.04
	draw_pass.height = 0.08
	particles.draw_pass_1 = draw_pass

	projectile.add_child(particles)
	return particles

## --- Per-Hero Hit Flash (S4-04) ---

## Spawn hero-specific hit impact effect.
func spawn_hero_hit_flash(position: Vector3, hero_config: HeroConfig) -> void:
	match hero_config.hook_type:
		HeroConfig.HookType.PULL:
			# Electric burst — multiple small flashes
			spawn_hit_flash(position, hero_config.hero_color)
			_spawn_spark_burst(position, hero_config.hero_color, 8)
		HeroConfig.HookType.GRAPPLE:
			# Green energy slash — elongated flash
			_spawn_slash_flash(position, hero_config.hero_color)
		HeroConfig.HookType.BOOMERANG:
			# Orange explosion — larger, fiery
			_spawn_explosion_flash(position, hero_config.hero_color)
		HeroConfig.HookType.BEAM:
			# Purple magnetic pulse — concentric rings
			spawn_hit_flash(position, hero_config.hero_color)
		_:
			spawn_hit_flash(position, hero_config.hero_color)

func _spawn_spark_burst(position: Vector3, color: Color, count: int) -> void:
	for i in range(count):
		var spark := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.05, 0.15)
		spark.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5, 0.9)
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 4.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark.material_override = mat

		add_child(spark)
		spark.global_position = position + Vector3(0, 0.5, 0)

		# Random direction
		var angle := randf() * TAU
		var dir := Vector3(cos(angle), randf_range(0.3, 1.0), sin(angle)) * randf_range(0.5, 1.5)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", spark.position + dir, 0.2)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)
		tween.chain().tween_callback(spark.queue_free)

func _spawn_slash_flash(position: Vector3, color: Color) -> void:
	var slash := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.5, 0.3)
	slash.mesh = quad

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.9)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	slash.material_override = mat

	add_child(slash)
	slash.global_position = position + Vector3(0, 0.5, 0)
	slash.rotation.z = randf_range(-0.3, 0.3)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(slash, "scale", Vector3(2.0, 0.5, 1.0), 0.25)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tween.chain().tween_callback(slash.queue_free)

func _spawn_explosion_flash(position: Vector3, color: Color) -> void:
	# Larger sphere with fiery colors
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.8
	sphere.height = 1.6
	flash.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g * 0.6, 0.1, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.1)
	mat.emission_energy_multiplier = 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = mat

	add_child(flash)
	flash.global_position = position + Vector3(0, 0.5, 0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3(2.5, 2.5, 2.5), 0.35)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.chain().tween_callback(flash.queue_free)

## --- Hook Trail (generic fallback) ---

## Spawn a trail of particles behind the hook projectile.
func attach_hook_trail(projectile: Node3D, color: Color) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 20
	particles.lifetime = 0.4
	particles.emitting = true
	particles.one_shot = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 10.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = color

	particles.process_material = mat

	# Use a small sphere mesh for particles
	var draw_pass := SphereMesh.new()
	draw_pass.radius = 0.05
	draw_pass.height = 0.1
	particles.draw_pass_1 = draw_pass

	projectile.add_child(particles)
	return particles

## --- Hit Impact Flash ---

## Spawn a brief flash at the hit location.
func spawn_hit_flash(position: Vector3, color: Color) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	flash.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = mat

	add_child(flash)
	flash.global_position = position + Vector3(0, 0.5, 0)

	# Animate: expand and fade over 0.3s
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3(2.0, 2.0, 2.0), 0.3)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(flash.queue_free)

## --- Death Effect ---

## Spawn a death effect: brief shrink + fade + particle burst.
func spawn_death_effect(position: Vector3, color: Color) -> void:
	# Particle burst
	var particles := GPUParticles3D.new()
	particles.amount = 30
	particles.lifetime = 0.8
	particles.emitting = true
	particles.one_shot = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3(0, -8, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = color

	particles.process_material = mat

	var draw_pass := SphereMesh.new()
	draw_pass.radius = 0.06
	draw_pass.height = 0.12
	particles.draw_pass_1 = draw_pass

	add_child(particles)
	particles.global_position = position + Vector3(0, 0.5, 0)

	# Auto-cleanup after particles finish
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_instance_valid(particles):
			particles.queue_free()
	)

## --- Respawn Effect ---

## Spawn a respawn flash: fade-in glow + invulnerability shimmer.
func spawn_respawn_effect(player: Node3D, color: Color) -> void:
	# Glow ring expanding outward
	var ring := MeshInstance3D.new()
	var torus := CylinderMesh.new()
	torus.top_radius = 0.8
	torus.bottom_radius = 0.8
	torus.height = 0.05
	ring.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.6)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = mat

	add_child(ring)
	ring.global_position = player.global_position

	# Animate: expand ring and fade
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(3.0, 1.0, 3.0), 0.5)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tween.chain().tween_callback(ring.queue_free)

## --- Invulnerability Glow ---

## Apply a pulsing glow to a player's mesh during invulnerability.
func start_invuln_glow(player: Node3D, color: Color, duration: float) -> void:
	var mesh := player.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return

	var original_mat := mesh.material_override
	if original_mat == null:
		return

	# Create glow material
	var glow_mat := original_mat.duplicate() as StandardMaterial3D
	glow_mat.emission_enabled = true
	glow_mat.emission = color
	glow_mat.emission_energy_multiplier = 1.5
	mesh.material_override = glow_mat

	# Pulse the emission energy
	var tween := create_tween()
	tween.set_loops(ceili(duration / 0.4))
	tween.tween_property(glow_mat, "emission_energy_multiplier", 3.0, 0.2)
	tween.tween_property(glow_mat, "emission_energy_multiplier", 0.5, 0.2)

	# Restore original material after duration
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if is_instance_valid(mesh):
			mesh.material_override = original_mat
	)
