## Unit tests for ScoreSystem.
##
## Tests kill recording, assist tracking, team scores, kill feed, and freeze.
extends GutTest

var _score: ScoreSystem
var _player_a: PlayerController
var _player_b: PlayerController

func before_each() -> void:
	_score = ScoreSystem.new()
	add_child(_score)
	_score._ready()

	_player_a = PlayerController.new()
	_player_a.name = "PlayerA"
	_player_a.team_id = 0
	add_child(_player_a)

	_player_b = PlayerController.new()
	_player_b.name = "PlayerB"
	_player_b.team_id = 1
	add_child(_player_b)

	# Add HealthComponent to player_b for assist detection
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	_player_b.add_child(health)

	_score.register_player(_player_a)
	_score.register_player(_player_b)

func after_each() -> void:
	_score.queue_free()
	_player_a.queue_free()
	_player_b.queue_free()

## --- Kill Recording ---

func test_record_kill_increments_killer_kills() -> void:
	_score.record_kill(_player_b, _player_a, "HOOK")
	var stats: Dictionary = _score.player_stats[_player_a.get_instance_id()]
	assert_eq(stats["kills"], 1)

func test_record_kill_increments_victim_deaths() -> void:
	_score.record_kill(_player_b, _player_a, "HOOK")
	var stats: Dictionary = _score.player_stats[_player_b.get_instance_id()]
	assert_eq(stats["deaths"], 1)

func test_record_kill_increments_team_score() -> void:
	_score.record_kill(_player_b, _player_a, "HOOK")
	assert_eq(_score.team_kills[0], 1, "Team A should have 1 kill")
	assert_eq(_score.team_kills[1], 0, "Team B should have 0 kills")

func test_suicide_no_kill_credit() -> void:
	_score.record_kill(_player_a, null, "HAZARD_INSTANT_KILL")
	var stats: Dictionary = _score.player_stats[_player_a.get_instance_id()]
	assert_eq(stats["deaths"], 1)
	assert_eq(_score.team_kills[0], 0, "Suicide doesn't count as team kill")

## --- Streaks ---

func test_kill_streak_increments() -> void:
	_score.record_kill(_player_b, _player_a, "HOOK")
	_score.record_kill(_player_b, _player_a, "HOOK")
	var stats: Dictionary = _score.player_stats[_player_a.get_instance_id()]
	assert_eq(stats["streak"], 2)

func test_death_resets_streak() -> void:
	_score.record_kill(_player_b, _player_a, "HOOK")
	_score.record_kill(_player_a, _player_b, "HOOK")  # A dies
	var stats: Dictionary = _score.player_stats[_player_a.get_instance_id()]
	assert_eq(stats["streak"], 0)

func test_best_streak_preserved() -> void:
	_score.record_kill(_player_b, _player_a, "HOOK")
	_score.record_kill(_player_b, _player_a, "HOOK")
	_score.record_kill(_player_b, _player_a, "HOOK")
	_score.record_kill(_player_a, _player_b, "HOOK")  # A dies, streak was 3
	_score.record_kill(_player_b, _player_a, "HOOK")   # A gets 1 more
	var stats: Dictionary = _score.player_stats[_player_a.get_instance_id()]
	assert_eq(stats["best_streak"], 3)

## --- Kill Feed ---

func test_kill_feed_adds_entry() -> void:
	_score.record_kill(_player_b, _player_a, "HOOK")
	var feed := _score.get_kill_feed()
	assert_eq(feed.size(), 1)
	assert_eq(feed[0]["killer_name"], "PlayerA")
	assert_eq(feed[0]["victim_name"], "PlayerB")

func test_kill_feed_max_entries() -> void:
	for i in range(10):
		_score.record_kill(_player_b, _player_a, "HOOK")
	var feed := _score.get_kill_feed()
	assert_eq(feed.size(), _score.kill_feed_max_entries)

## --- Freeze ---

func test_freeze_blocks_recording() -> void:
	_score.freeze()
	_score.record_kill(_player_b, _player_a, "HOOK")
	var stats: Dictionary = _score.player_stats[_player_a.get_instance_id()]
	assert_eq(stats["kills"], 0, "Frozen score system should not record kills")

## --- Assists ---

func test_assist_signal_emitted() -> void:
	watch_signals(_score)
	# Player A damages player B, then player B dies to some other cause
	var health: HealthComponent = _player_b.get_node("HealthComponent")
	health.max_health = 100.0
	health.current_health = 100.0
	health.take_damage(30.0, _player_a, "HOOK")
	# Now simulate player B being killed by environment (null killer)
	# The assist candidate check needs damage history
	_score.record_kill(_player_b, null, "HAZARD_INSTANT_KILL")
	# Assist should be awarded to player A
	assert_signal_emitted(_score, "assist_awarded")
