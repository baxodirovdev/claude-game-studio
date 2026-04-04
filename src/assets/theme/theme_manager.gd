## Theme Manager — applies the game theme to the root viewport on startup.
##
## Register as autoload to apply consistent styling across all scenes.
class_name ThemeManager
extends Node

func _ready() -> void:
	var theme := GameThemeGenerator.create_theme()
	# Apply to the root viewport's default theme
	get_tree().root.theme = theme
