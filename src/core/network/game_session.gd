## Game Session — multiplayer-aware game coordinator.
##
## Replaces Main's player spawning logic for networked play. Spawns a PlayerController
## per connected peer, assigns multiplayer authority, and routes game events through RPCs.
## For single-player, behaves identically to the original Main flow.
## Implements ADR-001 (multiplayer foundation).
class_name GameSession
extends Node

signal all_players_spawned

## Player scene to instantiate per peer.
var player_scene: PackedScene

## Spawned players: { peer_id: PlayerController }
var spawned_players: Dictionary = {}

## Reference to network manager (null in single-player).
var network_manager: Node  # NetworkManager autoload

## Spawn a player for the given peer ID at the given position.
func spawn_player(peer_id: int, team_id: int, spawn_pos: Vector3, hero_config: HeroConfig) -> PlayerController:
	var player := _create_player_node(peer_id, team_id, hero_config)
	player.global_position = spawn_pos
	add_child(player)
	spawned_players[peer_id] = player

	# Set multiplayer authority — each player is controlled by their own peer
	if network_manager != null and multiplayer.multiplayer_peer != null:
		player.set_multiplayer_authority(peer_id)

	return player

## Get the local player (the one controlled by this peer).
func get_local_player() -> PlayerController:
	if network_manager == null:
		# Single player — return the first (only) player
		if spawned_players.size() > 0:
			return spawned_players.values()[0]
		return null
	return spawned_players.get(network_manager.local_peer_id)

## Get a player by peer ID.
func get_player(peer_id: int) -> PlayerController:
	return spawned_players.get(peer_id)

## Get all spawned players.
func get_all_players() -> Array[PlayerController]:
	var players: Array[PlayerController] = []
	for pid: int in spawned_players:
		players.append(spawned_players[pid])
	return players

## Remove a player (disconnect).
func remove_player(peer_id: int) -> void:
	if spawned_players.has(peer_id):
		var player: PlayerController = spawned_players[peer_id]
		if is_instance_valid(player):
			player.queue_free()
		spawned_players.erase(peer_id)

## Despawn all players.
func clear_players() -> void:
	for pid: int in spawned_players:
		var player: PlayerController = spawned_players[pid]
		if is_instance_valid(player):
			player.queue_free()
	spawned_players.clear()

func _create_player_node(peer_id: int, team_id: int, hero_config: HeroConfig) -> PlayerController:
	var player := PlayerController.new()
	player.name = "Player_%d" % peer_id
	player.team_id = team_id
	player.move_speed = hero_config.move_speed

	# Collision
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	col.shape = capsule
	col.name = "CollisionShape3D"
	player.add_child(col)

	# Visual
	var mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.4
	capsule_mesh.height = 1.6
	mesh.mesh = capsule_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hero_config.hero_color
	mesh.material_override = mat
	mesh.name = "MeshInstance3D"
	player.add_child(mesh)

	# Health component
	var health := HealthComponent.new()
	health.max_health = hero_config.max_health
	health.name = "HealthComponent"
	player.add_child(health)

	# Hook system
	var hook := HookSystem.new()
	hook.name = "HookSystem"
	hook.player = player
	hook.hook_speed = hero_config.hook_speed
	hook.hook_return_speed = hero_config.hook_return_speed
	hook.hook_range = hero_config.hook_range
	hook.hook_damage = hero_config.hook_damage
	hook.hook_cooldown = hero_config.hook_cooldown
	hook.hook_hitbox_radius = hero_config.hook_hitbox_radius
	hook.pull_duration = hero_config.pull_duration
	hook.hero_config = hero_config
	player.add_child(hook)

	# MultiplayerSynchronizer for position sync (unreliable for movement)
	if network_manager != null and multiplayer.multiplayer_peer != null:
		var sync := MultiplayerSynchronizer.new()
		sync.name = "MultiplayerSynchronizer"
		var config := SceneReplicationConfig.new()
		config.add_property(NodePath(".:position"))
		config.add_property(NodePath(".:rotation"))
		sync.replication_config = config
		player.add_child(sync)

	return player
