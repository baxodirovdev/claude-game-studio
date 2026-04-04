## Theme Manager — applies the game theme to the root viewport on startup.
##
## Registered as autoload in project.godot. No class_name to avoid
## conflicting with the autoload singleton name.
extends Node

func _ready() -> void:
	var theme := GameThemeGenerator.create_theme()
	# Apply to the root viewport's default theme
	get_tree().root.theme = theme
