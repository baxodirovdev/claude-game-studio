## Item data resource — defines a purchasable in-match item.
##
## Each .tres file represents one item in the shop.
## Stat bonuses are percentage multipliers (0.15 = +15%).
## Flat bonuses are absolute values (20 = +20 max health).
## Implements GDD: design/gdd/in-match-economy.md.
class_name ItemData
extends Resource

enum Category { OFFENSIVE, DEFENSIVE, UTILITY }

@export_group("Identity")
## Unique item identifier.
@export var item_id: String = ""
## Display name in shop.
@export var display_name: String = ""
## Brief effect description.
@export var description: String = ""
## Item category for UI grouping.
@export var category: Category = Category.OFFENSIVE
## UI color for the item icon.
@export var icon_color: Color = Color.WHITE

@export_group("Cost")
## Gold cost to purchase.
@export var cost: int = 200

@export_group("Stat Bonuses (Percentage)")
## Hook damage bonus (0.15 = +15%).
@export var damage_bonus: float = 0.0
## Move speed bonus (0.15 = +15%).
@export var speed_bonus: float = 0.0
## Hook range bonus (0.10 = +10%).
@export var range_bonus: float = 0.0
## Hook cooldown reduction (0.20 = -20%).
@export var cooldown_reduction: float = 0.0
## Hook return speed bonus (0.10 = +10%).
@export var return_speed_bonus: float = 0.0

@export_group("Stat Bonuses (Flat)")
## Max health increase (flat value).
@export var health_bonus: float = 0.0
