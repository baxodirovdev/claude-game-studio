## Score/Kill Tracking — records kills, deaths, streaks, and feeds data to HUD and Match State.
##
## Listens to death events, maintains per-player and per-team stats, provides kill feed
## entries for the HUD, and emits kill_occurred for Match State win condition checks.
## Implements GDD: design/gdd/score-kill-tracking.md (basic Sprint 1 subset).
class_name ScoreSystem
extends Node

signal kill_occurred(killer_team: int, team_kills: Array[int])
signal kill_feed_updated(entries: Array[Dictionary])

## Kill feed display duration (seconds).
@export var kill_feed_duration: float = 5.0
## Maximum visible kill feed entries.
@export var kill_feed_max_entries: int = 4

## Per-team kill totals. Index 0 = Team A, 1 = Team B.
var team_kills: Array[int] = [0, 0]

## Per-player stats: { instance_id: { kills, deaths, streak, best_streak, team_id } }
var player_stats: Dictionary = {}

## Kill feed entries: [ { killer, victim, type, time } ]
var _kill_feed: Array[Dictionary] = []

var _frozen: bool = false

func _ready() -> void:
	set_process(false)

## Register a player for stat tracking.
func register_player(player: PlayerController) -> void:
	player_stats[player.get_instance_id()] = {
		"node": player,
		"team_id": player.team_id,
		"kills": 0,
		"deaths": 0,
		"streak": 0,
		"best_streak": 0,
	}

## Record a kill event. Called by Main when a target/player dies.
func record_kill(victim: Node, killer: Node, damage_type: String) -> void:
	if _frozen:
		return

	var victim_id := victim.get_instance_id() if victim else -1
	var killer_id := killer.get_instance_id() if killer else -1

	# Increment victim deaths
	if player_stats.has(victim_id):
		player_stats[victim_id]["deaths"] += 1
		player_stats[victim_id]["streak"] = 0

	# Increment killer kills and team score
	var killer_team := -1
	if killer != null and killer_id != victim_id:
		if player_stats.has(killer_id):
			player_stats[killer_id]["kills"] += 1
			player_stats[killer_id]["streak"] += 1
			if player_stats[killer_id]["streak"] > player_stats[killer_id]["best_streak"]:
				player_stats[killer_id]["best_streak"] = player_stats[killer_id]["streak"]
			killer_team = player_stats[killer_id]["team_id"]

		# Increment team kills
		if killer_team >= 0 and killer_team < team_kills.size():
			team_kills[killer_team] += 1
			kill_occurred.emit(killer_team, team_kills)

	# Add kill feed entry
	_add_feed_entry(killer, victim, damage_type)

## Record a kill from a non-player source (e.g., dummy target killed by player).
func record_target_kill(killer_team: int) -> void:
	if _frozen:
		return
	if killer_team >= 0 and killer_team < team_kills.size():
		team_kills[killer_team] += 1
		kill_occurred.emit(killer_team, team_kills)

## Freeze scoring (match ended).
func freeze() -> void:
	_frozen = true
	set_process(false)

## Get the current kill feed entries (filters expired).
func get_kill_feed() -> Array[Dictionary]:
	return _kill_feed

## Get stats for a player by instance id.
func get_player_stats(player: PlayerController) -> Dictionary:
	var pid := player.get_instance_id()
	if player_stats.has(pid):
		return player_stats[pid]
	return {}

func _process(delta: float) -> void:
	# Remove expired feed entries
	var current_time := Time.get_ticks_msec() / 1000.0
	var changed := false
	var i := _kill_feed.size() - 1
	while i >= 0:
		if current_time - _kill_feed[i]["time"] > kill_feed_duration:
			_kill_feed.remove_at(i)
			changed = true
		i -= 1
	if changed:
		kill_feed_updated.emit(_kill_feed)
	if _kill_feed.is_empty():
		set_process(false)

func _add_feed_entry(killer: Node, victim: Node, damage_type: String) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var entry: Dictionary = {
		"killer_name": killer.name if killer else "",
		"victim_name": victim.name if victim else "",
		"type": damage_type,
		"time": current_time,
		"is_suicide": killer == null or killer == victim,
	}
	_kill_feed.append(entry)

	# Trim to max entries
	while _kill_feed.size() > kill_feed_max_entries:
		_kill_feed.remove_at(0)

	kill_feed_updated.emit(_kill_feed)
	set_process(true)
