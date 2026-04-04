## Unit tests for GoldSystem.
##
## Tests gold awards, passive income, item purchases, and first blood.
extends GutTest

var _gold: GoldSystem
var _player: PlayerController
var _config: EconomyConfig

func before_each() -> void:
	_gold = GoldSystem.new()
	add_child(_gold)

	_config = EconomyConfig.new()
	_config.kill_gold = 100
	_config.assist_gold = 50
	_config.hit_gold = 15
	_config.passive_gold = 15
	_config.passive_interval = 12.0
	_config.first_blood_bonus = 50
	_config.max_items = 3
	_gold.economy_config = _config

	_player = PlayerController.new()
	_player.name = "TestPlayer"
	add_child(_player)
	_gold.register_player(_player)

func after_each() -> void:
	_gold.queue_free()
	_player.queue_free()

## --- Gold Awards ---

func test_kill_gold_awarded() -> void:
	var pid := _player.get_instance_id()
	_gold.award_kill_gold(pid)
	# First kill = kill_gold + first_blood_bonus = 150
	assert_eq(_gold.get_gold(pid), 150)

func test_first_blood_only_once() -> void:
	var pid := _player.get_instance_id()
	_gold.award_kill_gold(pid)  # 100 + 50 first blood = 150
	_gold.award_kill_gold(pid)  # 100 only = 250
	assert_eq(_gold.get_gold(pid), 250)

func test_assist_gold_awarded() -> void:
	var pid := _player.get_instance_id()
	_gold.award_assist_gold(pid)
	assert_eq(_gold.get_gold(pid), 50)

func test_hit_gold_awarded() -> void:
	var pid := _player.get_instance_id()
	_gold.award_hit_gold(pid)
	assert_eq(_gold.get_gold(pid), 15)

## --- Spending ---

func test_spend_gold_succeeds() -> void:
	var pid := _player.get_instance_id()
	_gold.award_kill_gold(pid)  # 150
	var success := _gold.spend_gold(pid, 100)
	assert_true(success)
	assert_eq(_gold.get_gold(pid), 50)

func test_spend_gold_fails_insufficient() -> void:
	var pid := _player.get_instance_id()
	_gold.award_hit_gold(pid)  # 15
	var success := _gold.spend_gold(pid, 100)
	assert_false(success)
	assert_eq(_gold.get_gold(pid), 15, "Gold unchanged on failed spend")

func test_can_afford() -> void:
	var pid := _player.get_instance_id()
	assert_false(_gold.can_afford(pid, 100))
	_gold.award_kill_gold(pid)  # 150
	assert_true(_gold.can_afford(pid, 100))
	assert_true(_gold.can_afford(pid, 150))
	assert_false(_gold.can_afford(pid, 151))

## --- Items ---

func test_item_slot_tracking() -> void:
	var pid := _player.get_instance_id()
	assert_true(_gold.has_item_slot(pid))
	assert_eq(_gold.get_item_count(pid), 0)

	var item := ItemData.new()
	item.item_id = "test_item"
	_gold.add_item(pid, item)
	assert_eq(_gold.get_item_count(pid), 1)
	assert_true(_gold.has_item(pid, "test_item"))
	assert_false(_gold.has_item(pid, "other_item"))

func test_max_items_enforced() -> void:
	var pid := _player.get_instance_id()
	for i in range(3):
		var item := ItemData.new()
		item.item_id = "item_%d" % i
		_gold.add_item(pid, item)
	assert_false(_gold.has_item_slot(pid), "No slot after 3 items")

## --- Reset ---

func test_reset_clears_gold_and_items() -> void:
	var pid := _player.get_instance_id()
	_gold.award_kill_gold(pid)
	var item := ItemData.new()
	item.item_id = "test"
	_gold.add_item(pid, item)

	_gold.reset()
	assert_eq(_gold.get_gold(pid), 0)
	assert_eq(_gold.get_item_count(pid), 0)

## --- Signal ---

func test_gold_changed_signal() -> void:
	watch_signals(_gold)
	var pid := _player.get_instance_id()
	_gold.award_hit_gold(pid)
	assert_signal_emitted(_gold, "gold_changed")
