## Hero configuration resource — all per-hero gameplay values.
##
## Create one .tres per hero. All gameplay systems read from this resource
## instead of using hardcoded values. Change values here to tune without code edits.
## Implements GDD: design/gdd/hero-system.md (data-driven config).
class_name HeroConfig
extends Resource

@export_group("Movement")
## Movement speed in units/second.
@export var move_speed: float = 10.0

@export_group("Health")
## Maximum health points.
@export var max_health: float = 100.0

@export_group("Hook")
## Hook projectile travel speed (units/second).
@export var hook_speed: float = 30.0
## Hook return speed (units/second).
@export var hook_return_speed: float = 45.0
## Maximum hook travel distance (units).
@export var hook_range: float = 25.0
## Damage dealt on hook hit.
@export var hook_damage: float = 30.0
## Cooldown after hook returns (seconds).
@export var hook_cooldown: float = 2.0
## Hook collision radius (units).
@export var hook_hitbox_radius: float = 1.0
## Duration of pull toward hooker (seconds).
@export var pull_duration: float = 0.5
