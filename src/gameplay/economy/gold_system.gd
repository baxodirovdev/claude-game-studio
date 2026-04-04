## Gold System — tracks per-player gold and handles passive income ticks.
##
## Listens to game events (kills, assists, hook hits) and awards gold per EconomyConfig.
## Provides gold query interface for Shop UI and HUD. Manages passive income timer.
## Implements GDD: design/gdd/in-match-economy.md.
class_name GoldSystem
extends Node

signal gold_changed(player_id: int, new_amount: int, delta: int)
signal first_blood(player_id: int)

## Economy config resource.
var economy_config: EconomyConfig

## Per-player gold: { instance_id: int }
var player_gold: Dictionary = {}

## Per-player items: { instance_id: Array[ItemData] }
var player_items: Dictionary = {}

var _passive_timer: float = 0.0
var _first_blood_claimed: bool = false
var _active: bool = false
var _registered_players: Array[int] = []

func _ready() -> void:
	set_process(false)

## Register a player for gold tracking.
func register_player(player: PlayerController) -> void:
	var pid := player.get_instance_id()
	player_gold[pid] = 0
	player_items[pid] = []
	_registered_players.append(pid)

## Start passive income (call when match enters PLAYING).
func activate() -> void:
	_active = true
	_passive_timer = 0.0
	set_process(true)

## Stop passive income (call when match ends).
func deactivate() -> void:
	_active = false
	set_process(false)

## Reset all gold and items (new match).
func reset() -> void:
	for pid: int in player_gold:
		player_gold[pid] = 0
		player_items[pid] = []
	_first_blood_claimed = false
	_passive_timer = 0.0

## Award gold for a kill.
func award_kill_gold(killer_id: int) -> void:
	if economy_config == null:
		return
	var amount := economy_config.kill_gold
	# First blood bonus
	if not _first_blood_claimed:
		_first_blood_claimed = true
		amount += economy_config.first_blood_bonus
		first_blood.emit(killer_id)
	_add_gold(killer_id, amount)

## Award gold for an assist.
func award_assist_gold(assister_id: int) -> void:
	if economy_config == null:
		return
	_add_gold(assister_id, economy_config.assist_gold)

## Award gold for a hook hit (non-lethal).
func award_hit_gold(hooker_id: int) -> void:
	if economy_config == null:
		return
	_add_gold(hooker_id, economy_config.hit_gold)

## Get current gold for a player.
func get_gold(player_id: int) -> int:
	return player_gold.get(player_id, 0)

## Get items owned by a player.
func get_items(player_id: int) -> Array:
	return player_items.get(player_id, [])

## Get item count for a player.
func get_item_count(player_id: int) -> int:
	return get_items(player_id).size()

## Check if player can afford an item.
func can_afford(player_id: int, cost: int) -> bool:
	return get_gold(player_id) >= cost

## Check if player has room for another item.
func has_item_slot(player_id: int) -> bool:
	if economy_config == null:
		return get_item_count(player_id) < 3
	return get_item_count(player_id) < economy_config.max_items

## Spend gold (returns true if successful).
func spend_gold(player_id: int, amount: int) -> bool:
	if not can_afford(player_id, amount):
		return false
	_add_gold(player_id, -amount)
	return true

## Add an item to a player's inventory (called by shop after purchase).
func add_item(player_id: int, item: Resource) -> void:
	if player_items.has(player_id):
		player_items[player_id].append(item)

## Check if a player already owns a specific item.
func has_item(player_id: int, item_id: String) -> bool:
	for item: Resource in get_items(player_id):
		if item.get("item_id") == item_id:
			return true
	return false

func _process(delta: float) -> void:
	if not _active or economy_config == null:
		return

	_passive_timer += delta
	if _passive_timer >= economy_config.passive_interval:
		_passive_timer -= economy_config.passive_interval
		# Award passive gold to all registered players
		for pid: int in _registered_players:
			_add_gold(pid, economy_config.passive_gold)

func _add_gold(player_id: int, amount: int) -> void:
	if not player_gold.has(player_id):
		return
	player_gold[player_id] += amount
	if player_gold[player_id] < 0:
		player_gold[player_id] = 0
	gold_changed.emit(player_id, player_gold[player_id], amount)
