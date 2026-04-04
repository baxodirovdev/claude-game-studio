## Unit tests for HealthComponent.
##
## Tests damage, death, invulnerability, assist tracking, and restore.
## Run via GUT (Godot Unit Test) framework.
extends GutTest

var _health: HealthComponent
var _source: Node3D

func before_each() -> void:
	_health = HealthComponent.new()
	_health.max_health = 100.0
	add_child(_health)
	_health._ready()

	_source = Node3D.new()
	_source.name = "TestAttacker"
	add_child(_source)

func after_each() -> void:
	_health.queue_free()
	_source.queue_free()

## --- Basic Damage ---

func test_take_damage_reduces_health() -> void:
	var dealt := _health.take_damage(30.0, _source, "HOOK")
	assert_eq(dealt, 30.0, "Should deal 30 damage")
	assert_eq(_health.current_health, 70.0, "Health should be 70")

func test_take_damage_minimum_1() -> void:
	var dealt := _health.take_damage(0.5, _source, "HOOK")
	assert_eq(dealt, 1.0, "Minimum damage is 1")
	assert_eq(_health.current_health, 99.0)

func test_take_damage_no_damage_when_dead() -> void:
	_health.take_damage(100.0, _source, "HOOK")
	assert_true(_health.is_dead)
	var dealt := _health.take_damage(50.0, _source, "HOOK")
	assert_eq(dealt, 0.0, "No damage on dead entity")

## --- Death ---

func test_death_on_zero_health() -> void:
	_health.take_damage(100.0, _source, "HOOK")
	assert_true(_health.is_dead)

func test_death_on_overkill() -> void:
	_health.take_damage(999.0, _source, "HOOK")
	assert_true(_health.is_dead)
	assert_eq(_health.current_health, 0.0)

func test_death_emits_signal() -> void:
	watch_signals(_health)
	_health.take_damage(100.0, _source, "HOOK")
	assert_signal_emitted(_health, "died")

## --- Invulnerability ---

func test_invulnerability_blocks_damage() -> void:
	_health.is_invulnerable = true
	var dealt := _health.take_damage(50.0, _source, "HOOK")
	assert_eq(dealt, 0.0, "Invulnerable blocks damage")
	assert_eq(_health.current_health, 100.0)

func test_invulnerability_allows_hazard_instant_kill() -> void:
	_health.is_invulnerable = true
	_health.take_damage(100.0, _source, "HAZARD_INSTANT_KILL")
	assert_true(_health.is_dead, "HAZARD_INSTANT_KILL bypasses invuln")

## --- Restore ---

func test_restore_full_resets_state() -> void:
	_health.take_damage(50.0, _source, "HOOK")
	_health.is_dead = true
	_health.restore_full()
	assert_eq(_health.current_health, 100.0)
	assert_false(_health.is_dead)

## --- Assist Tracking ---

func test_get_assist_candidate_returns_non_killer() -> void:
	var attacker_a := Node3D.new()
	attacker_a.name = "AttackerA"
	add_child(attacker_a)

	var attacker_b := Node3D.new()
	attacker_b.name = "AttackerB"
	add_child(attacker_b)

	# A deals damage, then B gets the kill
	_health.take_damage(30.0, attacker_a, "HOOK")
	_health.take_damage(30.0, attacker_b, "HOOK")

	var assist := _health.get_assist_candidate(attacker_b)
	assert_eq(assist, attacker_a, "Assist should be attacker_a (not the killer)")

	attacker_a.queue_free()
	attacker_b.queue_free()

func test_get_assist_candidate_returns_null_if_only_killer() -> void:
	_health.take_damage(30.0, _source, "HOOK")
	var assist := _health.get_assist_candidate(_source)
	assert_null(assist, "No assist if only the killer dealt damage")

func test_damage_history_clears_on_restore() -> void:
	_health.take_damage(30.0, _source, "HOOK")
	_health.restore_full()
	var assist := _health.get_assist_candidate(_source)
	assert_null(assist, "Damage history cleared after restore")

## --- Kill Credit ---

func test_kill_credit_from_hook() -> void:
	_health.take_damage(10.0, _source, "HOOK")
	var credit := _health.get_kill_credit_source()
	assert_eq(credit, _source, "Kill credit should be the hooker")

func test_kill_credit_null_for_non_hook() -> void:
	_health.take_damage(10.0, _source, "HAZARD_SPIKE")
	var credit := _health.get_kill_credit_source()
	assert_null(credit, "No kill credit for non-hook damage")
