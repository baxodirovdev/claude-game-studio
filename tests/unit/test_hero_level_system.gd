## Unit tests for HeroLevelSystem — XP gains and level-ups.
extends GutTest

var _level: HeroLevelSystem
var _config: HeroConfig

func before_each() -> void:
	_level = HeroLevelSystem.new()
	add_child(_level)

	_config = HeroConfig.new()
	_config.level_2_threshold = 100
	_config.level_3_threshold = 300
	_level.hero_config = _config

func after_each() -> void:
	_level.queue_free()

func test_starts_at_level_1() -> void:
	assert_eq(_level.current_level, 1)
	assert_eq(_level.current_xp, 0)

func test_add_xp_below_threshold() -> void:
	var leveled := _level.add_xp(50)
	assert_false(leveled)
	assert_eq(_level.current_level, 1)
	assert_eq(_level.current_xp, 50)

func test_level_up_to_2() -> void:
	watch_signals(_level)
	var leveled := _level.add_xp(100)
	assert_true(leveled)
	assert_eq(_level.current_level, 2)
	assert_signal_emitted(_level, "level_up")

func test_level_up_to_3() -> void:
	_level.add_xp(100)  # Level 2
	var leveled := _level.add_xp(200)  # 300 total → Level 3
	assert_true(leveled)
	assert_eq(_level.current_level, 3)

func test_max_level_3() -> void:
	_level.add_xp(500)  # Way past level 3
	assert_eq(_level.current_level, 3)
	var leveled := _level.add_xp(100)
	assert_false(leveled, "Cannot level past 3")

func test_xp_progress_at_zero() -> void:
	assert_almost_eq(_level.get_xp_progress(), 0.0, 0.01)

func test_xp_progress_at_half() -> void:
	_level.add_xp(50)
	assert_almost_eq(_level.get_xp_progress(), 0.5, 0.01)

func test_xp_progress_at_max() -> void:
	_level.add_xp(500)
	assert_almost_eq(_level.get_xp_progress(), 1.0, 0.01)

func test_reset() -> void:
	_level.add_xp(200)
	_level.reset()
	assert_eq(_level.current_level, 1)
	assert_eq(_level.current_xp, 0)
