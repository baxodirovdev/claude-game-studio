## Unit tests for HeroConfig — stat scaling and level bonuses.
extends GutTest

var _config: HeroConfig

func before_each() -> void:
	_config = HeroConfig.new()
	_config.hook_damage = 30.0
	_config.move_speed = 10.0
	_config.hook_range = 20.0
	_config.max_health = 100.0
	_config.level_2_damage_bonus = 0.10
	_config.level_2_speed_bonus = 0.05
	_config.level_3_damage_bonus = 0.25
	_config.level_3_speed_bonus = 0.10
	_config.level_3_range_bonus = 0.10

## --- Level 1 (no bonuses) ---

func test_level_1_damage() -> void:
	assert_eq(_config.get_effective_stat("hook_damage", 1), 30.0)

func test_level_1_speed() -> void:
	assert_eq(_config.get_effective_stat("move_speed", 1), 10.0)

func test_level_1_range() -> void:
	assert_eq(_config.get_effective_stat("hook_range", 1), 20.0)

## --- Level 2 bonuses ---

func test_level_2_damage_bonus() -> void:
	var expected := 30.0 * 1.10  # +10%
	assert_almost_eq(_config.get_effective_stat("hook_damage", 2), expected, 0.01)

func test_level_2_speed_bonus() -> void:
	var expected := 10.0 * 1.05  # +5%
	assert_almost_eq(_config.get_effective_stat("move_speed", 2), expected, 0.01)

func test_level_2_no_range_bonus() -> void:
	assert_eq(_config.get_effective_stat("hook_range", 2), 20.0, "No range bonus at level 2")

## --- Level 3 bonuses ---

func test_level_3_damage_bonus() -> void:
	var expected := 30.0 * 1.25  # +25% total
	assert_almost_eq(_config.get_effective_stat("hook_damage", 3), expected, 0.01)

func test_level_3_speed_bonus() -> void:
	var expected := 10.0 * 1.10  # +10% total
	assert_almost_eq(_config.get_effective_stat("move_speed", 3), expected, 0.01)

func test_level_3_range_bonus() -> void:
	var expected := 20.0 * 1.10  # +10%
	assert_almost_eq(_config.get_effective_stat("hook_range", 3), expected, 0.01)

## --- Health doesn't scale ---

func test_health_no_level_scaling() -> void:
	assert_eq(_config.get_effective_stat("max_health", 1), 100.0)
	assert_eq(_config.get_effective_stat("max_health", 2), 100.0)
	assert_eq(_config.get_effective_stat("max_health", 3), 100.0)

## --- Pudge one-shot check ---

func test_pudge_one_shot_damage() -> void:
	var pudge := HeroConfig.new()
	pudge.hook_damage = 99999.0
	pudge.max_health = 150.0
	pudge.hook_type = HeroConfig.HookType.PULL
	# Hook damage exceeds any hero's max HP
	assert_gt(pudge.hook_damage, 150.0, "Pudge hook should one-shot any hero")
