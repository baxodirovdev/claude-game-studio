## Hero configuration resource — all per-hero gameplay values.
##
## Create one .tres per hero. All gameplay systems read from this resource
## instead of using hardcoded values. Change values here to tune without code edits.
## Implements GDD: design/gdd/hero-system.md.
class_name HeroConfig
extends Resource

enum HookType { PULL, GRAPPLE, BOOMERANG }

@export_group("Identity")
## Unique hero identifier.
@export var hero_id: String = "vex"
## Display name shown in HUD and selection.
@export var display_name: String = "Vex"
## Hook type determining projectile behavior.
@export var hook_type: HookType = HookType.PULL
## Hero color for capsule mesh.
@export var hero_color: Color = Color(0.2, 0.6, 1.0)

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
@export var hook_range: float = 20.0
## Damage dealt on hook hit.
@export var hook_damage: float = 30.0
## Cooldown after hook returns (seconds).
@export var hook_cooldown: float = 2.0
## Hook collision radius (units).
@export var hook_hitbox_radius: float = 1.0
## Duration of pull toward hooker (seconds). PULL type only.
@export var pull_duration: float = 0.5

@export_group("Grapple (Lash)")
## Duration of hooker travel to target (seconds). GRAPPLE type only.
@export var grapple_duration: float = 0.4

@export_group("Boomerang (Maw)")
## Damage dealt on boomerang return pass. BOOMERANG type only.
@export var boomerang_return_damage: float = 30.0
## Hitbox radius multiplier on return pass (wider = more forgiving).
@export var boomerang_return_hitbox_mult: float = 1.0

@export_group("Leveling")
## XP gained per hook hit (non-lethal).
@export var xp_on_hook_hit: int = 15
## XP gained per kill.
@export var xp_on_kill: int = 50
## XP gained per assist.
@export var xp_on_assist: int = 25
## XP needed to reach Level 2.
@export var level_2_threshold: int = 100
## XP needed to reach Level 3.
@export var level_3_threshold: int = 300
## Level 2 damage bonus (percentage, e.g., 0.10 = +10%).
@export var level_2_damage_bonus: float = 0.10
## Level 2 speed bonus (percentage).
@export var level_2_speed_bonus: float = 0.05
## Level 3 damage bonus (cumulative with level 2).
@export var level_3_damage_bonus: float = 0.25
## Level 3 speed bonus (cumulative with level 2).
@export var level_3_speed_bonus: float = 0.10
## Level 3 range bonus (percentage).
@export var level_3_range_bonus: float = 0.10

## Returns effective stat value with level bonuses applied.
func get_effective_stat(stat_name: String, level: int) -> float:
	var base: float
	match stat_name:
		"hook_damage":
			base = hook_damage
		"move_speed":
			base = move_speed
		"hook_range":
			base = hook_range
		"max_health":
			return max_health  # Health doesn't scale with level
		_:
			return 0.0

	var bonus := 0.0
	if level >= 2:
		match stat_name:
			"hook_damage":
				bonus += level_2_damage_bonus
			"move_speed":
				bonus += level_2_speed_bonus
	if level >= 3:
		match stat_name:
			"hook_damage":
				bonus += level_3_damage_bonus - level_2_damage_bonus
			"move_speed":
				bonus += level_3_speed_bonus - level_2_speed_bonus
			"hook_range":
				bonus += level_3_range_bonus

	return base * (1.0 + bonus)
