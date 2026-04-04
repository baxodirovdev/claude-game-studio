## Economy configuration resource — all in-match economy tuning values.
##
## One per match mode. Gold rates, item costs, and economy rules.
## Implements GDD: design/gdd/in-match-economy.md.
class_name EconomyConfig
extends Resource

@export_group("Gold Income")
## Gold awarded per kill.
@export var kill_gold: int = 100
## Gold awarded per assist.
@export var assist_gold: int = 50
## Gold awarded per non-lethal hook hit.
@export var hit_gold: int = 15
## Passive gold per tick.
@export var passive_gold: int = 10
## Seconds between passive gold ticks.
@export var passive_interval: float = 15.0
## Bonus gold for first kill of the match.
@export var first_blood_bonus: int = 50

@export_group("Items")
## Maximum items a player can hold.
@export var max_items: int = 3
