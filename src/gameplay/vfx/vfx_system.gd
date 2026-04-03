## VFX System — manages visual effects for hooks, hits, deaths, and respawns.
##
## Creates GPU particle effects and mesh-based flashes. All effects are fire-and-forget.
## Colors are driven by hero config. Purely visual — no gameplay logic.
## Sprint 3 S3-07.
class_name VFXSystem
extends Node3D

## --- Hook Trail ---

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
