## Drives a hero model's imported AnimationPlayer (from the GLB) for gameplay.
##
## Locomotion (walk) loops while moving; one-shots (hook throw, death) play over
## the top. The hook-throw one-shot is interruptible by movement; death is not.
## Safe no-op if the model has no AnimationPlayer (e.g. the primitive fallback
## heroes), so callers don't need to branch on whether a rigged GLB was loaded.
class_name HeroAnimator
extends RefCounted

const LOCOMOTION := "walk"

var _ap: AnimationPlayer
var _moving: bool = false
var _oneshot: String = ""
var _oneshot_interruptible: bool = false
var _death_done: Callable

## Find the model's AnimationPlayer anywhere under [param model_root] and make
## the walk clip loop. Returns false when there is no AnimationPlayer to drive.
func setup(model_root: Node) -> bool:
	_ap = _find_anim_player(model_root)
	if _ap == null:
		return false
	if not _ap.animation_finished.is_connected(_on_finished):
		_ap.animation_finished.connect(_on_finished)
	if _ap.has_animation(LOCOMOTION):
		_ap.get_animation(LOCOMOTION).loop_mode = Animation.LOOP_LINEAR
	return true

## Play/stop the looping walk based on whether the player is moving.
## Ignored while a non-interruptible one-shot (death) is playing.
func set_moving(moving: bool) -> void:
	if _ap == null:
		return
	if _oneshot != "" and not _oneshot_interruptible:
		return
	if _oneshot != "" and _oneshot_interruptible and not moving:
		return  # let the throw keep playing while standing still
	if _oneshot != "":
		_oneshot = ""  # movement interrupts the throw
	_moving = moving
	if moving and _ap.has_animation(LOCOMOTION):
		if _ap.current_animation != LOCOMOTION:
			_ap.play(LOCOMOTION)
	elif _ap.current_animation == LOCOMOTION:
		_ap.stop()

func play_throw() -> void:
	_play_oneshot("hook_throw", true)

## Play the death clip once, then invoke [param on_done] (used to hide the body
## only after the animation finishes). Non-interruptible.
func play_death(on_done: Callable) -> void:
	_death_done = on_done
	if not _play_oneshot("death", false):
		# no death clip — hide immediately so behaviour matches the old flow
		if on_done.is_valid():
			on_done.call()

func _play_oneshot(name: String, interruptible: bool) -> bool:
	if _ap == null or not _ap.has_animation(name):
		return false
	_oneshot = name
	_oneshot_interruptible = interruptible
	_ap.play(name)
	return true

func _on_finished(anim: StringName) -> void:
	if String(anim) != _oneshot:
		return
	var finished := _oneshot
	_oneshot = ""
	if finished == "death" and _death_done.is_valid():
		_death_done.call()
	elif _moving and _ap.has_animation(LOCOMOTION):
		_ap.play(LOCOMOTION)

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for c in node.get_children():
		var r := _find_anim_player(c)
		if r != null:
			return r
	return null
