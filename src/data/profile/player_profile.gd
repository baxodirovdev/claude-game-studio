## Player Profile — persistent account data saved between sessions.
##
## Tracks lifetime stats: total wins, kills, matches, per-hero mastery.
## Loads from and saves to user://profile.cfg. Account level derived from total XP.
## Sprint 6 S6-05.
class_name PlayerProfile
extends Node

const PROFILE_PATH := "user://profile.cfg"

## XP thresholds per account level (cumulative).
const LEVEL_THRESHOLDS: Array[int] = [
	0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5200,
	6500, 8000, 10000, 12500, 15500, 19000, 23000, 27500, 32500, 38000,
]

signal profile_updated
signal level_up(new_level: int)

var _config := ConfigFile.new()

## Lifetime stats.
var total_xp: int = 0
var account_level: int = 1
var total_wins: int = 0
var total_kills: int = 0
var total_deaths: int = 0
var total_assists: int = 0
var matches_played: int = 0

## Per-hero mastery: { hero_id: { "games": int, "wins": int, "kills": int } }
var hero_mastery: Dictionary = {}

func _ready() -> void:
	load_profile()

## Load profile from disk.
func load_profile() -> void:
	var err := _config.load(PROFILE_PATH)
	if err != OK:
		# First time — defaults are fine
		return

	total_xp = _config.get_value("stats", "total_xp", 0)
	total_wins = _config.get_value("stats", "total_wins", 0)
	total_kills = _config.get_value("stats", "total_kills", 0)
	total_deaths = _config.get_value("stats", "total_deaths", 0)
	total_assists = _config.get_value("stats", "total_assists", 0)
	matches_played = _config.get_value("stats", "matches_played", 0)

	# Load hero mastery
	if _config.has_section("heroes"):
		for key: String in _config.get_section_keys("heroes"):
			var data: Dictionary = _config.get_value("heroes", key, {})
			hero_mastery[key] = data

	_recalculate_level()

## Save profile to disk.
func save_profile() -> void:
	_config.set_value("stats", "total_xp", total_xp)
	_config.set_value("stats", "total_wins", total_wins)
	_config.set_value("stats", "total_kills", total_kills)
	_config.set_value("stats", "total_deaths", total_deaths)
	_config.set_value("stats", "total_assists", total_assists)
	_config.set_value("stats", "matches_played", matches_played)

	for hero_id: String in hero_mastery:
		_config.set_value("heroes", hero_id, hero_mastery[hero_id])

	_config.save(PROFILE_PATH)

## Record a completed match.
func record_match(hero_id: String, won: bool, kills: int, deaths: int, assists: int, xp_earned: int) -> void:
	matches_played += 1
	total_kills += kills
	total_deaths += deaths
	total_assists += assists
	if won:
		total_wins += 1

	# XP
	var old_level := account_level
	total_xp += xp_earned
	_recalculate_level()
	if account_level > old_level:
		level_up.emit(account_level)

	# Hero mastery
	if not hero_mastery.has(hero_id):
		hero_mastery[hero_id] = {"games": 0, "wins": 0, "kills": 0}
	hero_mastery[hero_id]["games"] += 1
	if won:
		hero_mastery[hero_id]["wins"] += 1
	hero_mastery[hero_id]["kills"] += kills

	save_profile()
	profile_updated.emit()

## Get account level.
func get_level() -> int:
	return account_level

## Get XP progress toward next level (0.0 to 1.0).
func get_level_progress() -> float:
	if account_level >= LEVEL_THRESHOLDS.size():
		return 1.0
	var prev_threshold := LEVEL_THRESHOLDS[account_level - 1] if account_level > 1 else 0
	var next_threshold := LEVEL_THRESHOLDS[mini(account_level, LEVEL_THRESHOLDS.size() - 1)]
	if next_threshold <= prev_threshold:
		return 1.0
	return float(total_xp - prev_threshold) / float(next_threshold - prev_threshold)

## Get hero mastery tier: 0=none, 1=bronze (10 games), 2=silver (25), 3=gold (50).
func get_hero_mastery_tier(hero_id: String) -> int:
	if not hero_mastery.has(hero_id):
		return 0
	var games: int = hero_mastery[hero_id].get("games", 0)
	if games >= 50:
		return 3
	elif games >= 25:
		return 2
	elif games >= 10:
		return 1
	return 0

## Get total win rate as percentage.
func get_win_rate() -> float:
	if matches_played == 0:
		return 0.0
	return float(total_wins) / float(matches_played) * 100.0

func _recalculate_level() -> void:
	account_level = 1
	for i in range(LEVEL_THRESHOLDS.size()):
		if total_xp >= LEVEL_THRESHOLDS[i]:
			account_level = i + 1
		else:
			break
