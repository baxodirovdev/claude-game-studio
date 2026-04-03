## Hero Level System — tracks XP, triggers level-ups, applies stat bonuses.
##
## One per player. Reads XP values from HeroConfig. Emits level_up signal for HUD.
## Systems query get_effective_stat() to get level-scaled values.
## Implements GDD: design/gdd/hero-system.md (in-match leveling).
class_name HeroLevelSystem
extends Node

signal level_up(new_level: int)
signal xp_changed(current_xp: int, next_threshold: int)

var hero_config: HeroConfig
var current_level: int = 1
var current_xp: int = 0

## Add XP and check for level-up. Returns true if leveled up.
func add_xp(amount: int) -> bool:
	if hero_config == null:
		return false
	if current_level >= 3:
		return false

	current_xp += amount
	var leveled := false

	if current_level == 1 and current_xp >= hero_config.level_2_threshold:
		current_level = 2
		leveled = true
		level_up.emit(2)

	if current_level == 2 and current_xp >= hero_config.level_3_threshold:
		current_level = 3
		leveled = true
		level_up.emit(3)

	xp_changed.emit(current_xp, _get_next_threshold())
	return leveled

## Get XP progress toward next level (0.0 to 1.0).
func get_xp_progress() -> float:
	if current_level >= 3:
		return 1.0
	var prev := 0 if current_level == 1 else hero_config.level_2_threshold
	var next := _get_next_threshold()
	if next <= prev:
		return 1.0
	return float(current_xp - prev) / float(next - prev)

## Get effective stat with level bonuses applied.
func get_effective_stat(stat_name: String) -> float:
	if hero_config == null:
		return 0.0
	return hero_config.get_effective_stat(stat_name, current_level)

## Reset to level 1 (match end / new match).
func reset() -> void:
	current_level = 1
	current_xp = 0

func _get_next_threshold() -> int:
	if hero_config == null:
		return 100
	match current_level:
		1:
			return hero_config.level_2_threshold
		2:
			return hero_config.level_3_threshold
		_:
			return hero_config.level_3_threshold
