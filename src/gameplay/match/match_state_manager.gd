## Match State Manager — controls match flow: countdown, playing, ended.
##
## Central authority for match lifecycle. Emits [signal match_state_changed] on
## every transition. Other systems listen to this signal to enable/disable behavior.
## Implements GDD: design/gdd/match-state-manager.md (basic Sprint 1 subset).
class_name MatchStateManager
extends Node

signal match_state_changed(new_state: State)
signal countdown_tick(seconds_left: int)
signal match_timer_updated(time_remaining: float)
signal match_ended(winner_team: int, reason: String)

enum State { WAITING, COUNTDOWN, PLAYING, ENDED }

## Countdown duration in seconds before match starts.
@export var countdown_duration: float = 3.0
## Total match duration in seconds (default 5 minutes).
@export var match_duration: float = 300.0
## How long the "ended" screen stays before returning.
@export var ended_display_duration: float = 3.0
## Kill target — first team to this many kills wins. 0 = timer only.
@export var kill_target: int = 20

var current_state: State = State.WAITING
var match_time_remaining: float = 0.0

## Per-team kill counts. Index 0 = Team A, 1 = Team B.
var team_kills: Array[int] = [0, 0]

var _countdown_remaining: float = 0.0
var _ended_timer: float = 0.0
var _last_countdown_second: int = -1

## References set by Main.
var input_manager: InputManager
var players: Array[PlayerController] = []

func _ready() -> void:
	set_process(false)

## Start the match flow (called by Main after arena is ready).
func start_match() -> void:
	team_kills = [0, 0]
	_transition_to(State.COUNTDOWN)

## Register a kill for a team. Checks win condition.
func register_kill(team_id: int) -> void:
	if current_state != State.PLAYING:
		return
	if team_id < 0 or team_id >= team_kills.size():
		return
	team_kills[team_id] += 1

	# Check kill target win condition
	if kill_target > 0 and team_kills[team_id] >= kill_target:
		_end_match(team_id, "kill_target")

## Returns formatted time string "M:SS".
func get_time_display() -> String:
	var total_seconds := ceili(match_time_remaining)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%d:%02d" % [minutes, seconds]

func _process(delta: float) -> void:
	match current_state:
		State.COUNTDOWN:
			_process_countdown(delta)
		State.PLAYING:
			_process_playing(delta)
		State.ENDED:
			_process_ended(delta)

func _process_countdown(delta: float) -> void:
	_countdown_remaining -= delta

	# Emit tick each second
	var current_second := ceili(_countdown_remaining)
	if current_second != _last_countdown_second and current_second > 0:
		_last_countdown_second = current_second
		countdown_tick.emit(current_second)

	if _countdown_remaining <= 0:
		_transition_to(State.PLAYING)

func _process_playing(delta: float) -> void:
	match_time_remaining -= delta
	match_timer_updated.emit(match_time_remaining)

	if match_time_remaining <= 0:
		match_time_remaining = 0.0
		# Timer expired — team with more kills wins
		var winner := -1
		if team_kills[0] > team_kills[1]:
			winner = 0
		elif team_kills[1] > team_kills[0]:
			winner = 1
		# If tied, it's a draw (winner = -1)
		_end_match(winner, "timer" if winner >= 0 else "draw")

func _process_ended(delta: float) -> void:
	_ended_timer -= delta
	if _ended_timer <= 0:
		set_process(false)

func _end_match(winner_team: int, reason: String) -> void:
	_transition_to(State.ENDED)
	match_ended.emit(winner_team, reason)

func _transition_to(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.COUNTDOWN:
			_countdown_remaining = countdown_duration
			_last_countdown_second = ceili(countdown_duration)
			countdown_tick.emit(_last_countdown_second)
			_set_gameplay_enabled(false)
			set_process(true)
		State.PLAYING:
			match_time_remaining = match_duration
			_set_gameplay_enabled(true)
		State.ENDED:
			_ended_timer = ended_display_duration
			_set_gameplay_enabled(false)
			_freeze_all_players()
	match_state_changed.emit(new_state)

func _set_gameplay_enabled(enabled: bool) -> void:
	if input_manager:
		input_manager.set_enabled(enabled)

func _freeze_all_players() -> void:
	for player in players:
		if is_instance_valid(player):
			player.freeze()
