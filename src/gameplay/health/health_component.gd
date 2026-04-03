## Health component — tracks HP, processes damage, handles death and invulnerability.
##
## Attach as a child of any entity that can take damage (PlayerController).
## All damage flows through [method take_damage]. Emits signals for HUD/Score/Respawn.
class_name HealthComponent
extends Node

## Emitted when health changes (for HUD).
signal health_changed(current: float, maximum: float)
## Emitted when the entity dies.
signal died(victim: Node, killer: Node, damage_type: String)
## Emitted when damage is dealt (for floating numbers, score tracking).
signal damage_taken(amount: float, source: Node, damage_type: String)

## Maximum health. Set from hero data.
@export var max_health: float = 100.0

var current_health: float = 0.0
var is_invulnerable: bool = false
var is_dead: bool = false

# Kill credit tracking (per Health & Damage GDD)
var _last_hooker: Node = null
var _last_hook_time: float = 0.0
const KILL_CREDIT_WINDOW: float = 3.0

## Recent damage dealers for assist tracking: [{ source: Node, time: float }]
var _damage_history: Array[Dictionary] = []
const ASSIST_WINDOW: float = 5.0

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if _last_hook_time > 0:
		_last_hook_time -= delta
		if _last_hook_time <= 0:
			_last_hooker = null

	# Clean expired damage history
	var current_time := Time.get_ticks_msec() / 1000.0
	while _damage_history.size() > 0 and current_time - _damage_history[0]["time"] > ASSIST_WINDOW:
		_damage_history.remove_at(0)

## Deal damage to this entity. Returns actual damage dealt.
func take_damage(amount: float, source: Node, damage_type: String) -> float:
	if is_dead:
		return 0.0

	# Invulnerability blocks everything except instant-kill hazards
	if is_invulnerable and damage_type != "HAZARD_INSTANT_KILL":
		return 0.0

	# Instant kill: set health to 0 regardless
	if damage_type == "HAZARD_INSTANT_KILL":
		amount = current_health

	# Minimum 1 damage per valid hit
	var final_damage := maxf(1.0, amount)
	current_health = maxf(0.0, current_health - final_damage)
	damage_taken.emit(final_damage, source, damage_type)
	health_changed.emit(current_health, max_health)

	# Track last hooker for kill credit attribution
	if damage_type == "HOOK" and source != null:
		_last_hooker = source
		_last_hook_time = KILL_CREDIT_WINDOW

	# Record damage dealer for assist tracking
	if source != null:
		_damage_history.append({"source": source, "time": Time.get_ticks_msec() / 1000.0})

	if current_health <= 0:
		_die(source, damage_type)

	return final_damage

## Restore health to full (respawn).
func restore_full() -> void:
	is_dead = false
	current_health = max_health
	_last_hooker = null
	_last_hook_time = 0.0
	_damage_history.clear()
	health_changed.emit(current_health, max_health)

## Grant invulnerability for a duration.
func grant_invulnerability(duration: float) -> void:
	is_invulnerable = true
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		is_invulnerable = false
	)

## Get the killer for hazard deaths (hooker within credit window, or null = suicide).
func get_kill_credit_source() -> Node:
	return _last_hooker

## Get the most recent damage dealer (besides the killer) for assist credit.
func get_assist_candidate(killer: Node) -> Node:
	var current_time := Time.get_ticks_msec() / 1000.0
	# Walk backwards to find most recent non-killer damage dealer
	for i in range(_damage_history.size() - 1, -1, -1):
		var entry: Dictionary = _damage_history[i]
		if current_time - entry["time"] > ASSIST_WINDOW:
			break
		if entry["source"] != killer and entry["source"] != null:
			return entry["source"]
	return null

func _die(source: Node, damage_type: String) -> void:
	is_dead = true
	is_invulnerable = false

	# Determine killer: if hazard kill, check hook credit window
	var killer: Node = source
	if damage_type.begins_with("HAZARD") and source == null:
		killer = _last_hooker  # May still be null (suicide)

	died.emit(get_parent(), killer, damage_type)
