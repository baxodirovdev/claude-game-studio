## Unit tests for PlayerProfile — persistent stats and mastery.
extends GutTest

var _profile: PlayerProfile

func before_each() -> void:
	_profile = PlayerProfile.new()
	# Don't add to tree — test without file I/O
	_profile.total_xp = 0
	_profile.account_level = 1
	_profile.total_wins = 0
	_profile.total_kills = 0
	_profile.total_deaths = 0
	_profile.total_assists = 0
	_profile.matches_played = 0
	_profile.hero_mastery = {}

## --- Record Match ---

func test_record_match_increments_stats() -> void:
	_profile.record_match("pudge", true, 5, 2, 1, 100)
	assert_eq(_profile.matches_played, 1)
	assert_eq(_profile.total_wins, 1)
	assert_eq(_profile.total_kills, 5)
	assert_eq(_profile.total_deaths, 2)
	assert_eq(_profile.total_assists, 1)
	assert_eq(_profile.total_xp, 100)

func test_record_match_loss() -> void:
	_profile.record_match("pudge", false, 3, 4, 0, 50)
	assert_eq(_profile.total_wins, 0)
	assert_eq(_profile.matches_played, 1)

func test_multiple_matches() -> void:
	_profile.record_match("pudge", true, 5, 2, 1, 100)
	_profile.record_match("pudge", false, 3, 4, 0, 50)
	assert_eq(_profile.matches_played, 2)
	assert_eq(_profile.total_wins, 1)
	assert_eq(_profile.total_kills, 8)
	assert_eq(_profile.total_deaths, 6)

## --- Leveling ---

func test_level_up_from_xp() -> void:
	_profile.record_match("pudge", true, 5, 0, 0, 150)
	# 150 XP, threshold for level 2 is 100
	assert_eq(_profile.get_level(), 2)

func test_level_progress() -> void:
	_profile.total_xp = 50
	_profile._recalculate_level()
	var progress := _profile.get_level_progress()
	assert_almost_eq(progress, 0.5, 0.01)

## --- Hero Mastery ---

func test_hero_mastery_tracking() -> void:
	_profile.record_match("pudge", true, 5, 2, 1, 100)
	assert_true(_profile.hero_mastery.has("pudge"))
	assert_eq(_profile.hero_mastery["pudge"]["games"], 1)
	assert_eq(_profile.hero_mastery["pudge"]["wins"], 1)
	assert_eq(_profile.hero_mastery["pudge"]["kills"], 5)

func test_mastery_tier_none() -> void:
	assert_eq(_profile.get_hero_mastery_tier("pudge"), 0)

func test_mastery_tier_bronze() -> void:
	_profile.hero_mastery["pudge"] = {"games": 10, "wins": 5, "kills": 50}
	assert_eq(_profile.get_hero_mastery_tier("pudge"), 1)

func test_mastery_tier_silver() -> void:
	_profile.hero_mastery["pudge"] = {"games": 25, "wins": 12, "kills": 150}
	assert_eq(_profile.get_hero_mastery_tier("pudge"), 2)

func test_mastery_tier_gold() -> void:
	_profile.hero_mastery["pudge"] = {"games": 50, "wins": 30, "kills": 300}
	assert_eq(_profile.get_hero_mastery_tier("pudge"), 3)

## --- Win Rate ---

func test_win_rate_zero_matches() -> void:
	assert_almost_eq(_profile.get_win_rate(), 0.0, 0.01)

func test_win_rate_calculation() -> void:
	_profile.record_match("pudge", true, 1, 0, 0, 10)
	_profile.record_match("pudge", false, 1, 0, 0, 10)
	assert_almost_eq(_profile.get_win_rate(), 50.0, 0.01)
