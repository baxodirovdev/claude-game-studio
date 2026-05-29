## Player Controller — translates input into movement, facing, and state transitions.
##
## Reads movement_vector and facing_angle from InputManager.
## Handles Active, Locked (hook in flight), Pulled (hooked by enemy), and Dead states.
class_name PlayerController
extends CharacterBody3D

signal died(victim: PlayerController, killer: Node, damage_type: String)
signal respawned

enum State { INACTIVE, ACTIVE, LOCKED, PULLED, DEAD, FROZEN }

## Movement speed in units/second. Overridden by hero data.
@export var move_speed: float = 10.0

var state: State = State.INACTIVE
var facing_angle: float = 0.0
var team_id: int = 0

## Reference set by Main after scene is ready.
var input_manager: InputManager

## Drives the hero model's animations. Null until refresh_hero_animator() finds
## an AnimationPlayer in the built model (primitive-fallback heroes have none).
var _animator: HeroAnimator

## (Re)bind the animator to the current hero model. Call after the model is
## (re)built by HeroModelBuilder.
func refresh_hero_animator() -> void:
	_animator = HeroAnimator.new()
	if not _animator.setup(self):
		_animator = null

# Pull state (written by Hook System when this player is hooked)
var _pull_origin: Vector3 = Vector3.ZERO
var _pull_destination: Vector3 = Vector3.ZERO
var _pull_progress: float = 0.0
var _pull_duration: float = 0.5
var _pull_hooker: Node = null

func _physics_process(delta: float) -> void:
	match state:
		State.ACTIVE:
			_process_active(delta)
		State.LOCKED:
			velocity = Vector3.ZERO
			move_and_slide()
		State.PULLED:
			_process_pulled(delta)
		_:
			velocity = Vector3.ZERO

## Activate the player (match start or respawn).
func activate() -> void:
	state = State.ACTIVE
	visible = true
	$CollisionShape3D.disabled = false

## Kill the player. Emits [signal died].
func kill(killer: Node, damage_type: String) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	$CollisionShape3D.disabled = true
	velocity = Vector3.ZERO
	# Play the death animation, then hide the body once it finishes. The hide is
	# guarded on state so a respawn mid-animation cancels it (see activate()).
	if _animator != null:
		_animator.play_death(func() -> void:
			if state == State.DEAD:
				visible = false
		)
	else:
		visible = false
	died.emit(self, killer, damage_type)

## Lock movement (hook fired — player can't move until hook returns).
func lock() -> void:
	if state == State.ACTIVE:
		state = State.LOCKED
		if _animator != null:
			_animator.play_throw()

## Unlock movement (hook returned).
func unlock() -> void:
	if state == State.LOCKED:
		state = State.ACTIVE

## Begin being pulled by an enemy hook.
func start_pull(hooker: Node, destination: Vector3, duration: float) -> void:
	if state == State.DEAD:
		return
	state = State.PULLED
	_pull_origin = global_position
	_pull_destination = destination
	_pull_progress = 0.0
	_pull_duration = duration
	_pull_hooker = hooker

## Cancel an in-progress pull (hooker died).
func cancel_pull() -> void:
	if state == State.PULLED:
		state = State.ACTIVE
		_pull_hooker = null

## Freeze the player (match ended).
func freeze() -> void:
	state = State.FROZEN
	velocity = Vector3.ZERO

func _process_active(delta: float) -> void:
	if input_manager == null:
		return

	var move_dir := input_manager.get_movement_vector()
	if move_dir.length() > 0:
		velocity = Vector3(move_dir.x, 0, move_dir.y) * move_speed
	else:
		velocity = Vector3.ZERO
	move_and_slide()

	if _animator != null:
		_animator.set_moving(velocity.length() > 0.1)

	# Update facing from input
	facing_angle = input_manager.get_facing_angle()
	var face_dir := Vector2(cos(facing_angle), -sin(facing_angle))
	var world_dir := Vector3(face_dir.x, 0, face_dir.y)
	if world_dir.length() > 0:
		rotation.y = atan2(-world_dir.x, -world_dir.z)

func _process_pulled(delta: float) -> void:
	_pull_progress += (1.0 / _pull_duration) * delta
	if _pull_progress >= 1.0:
		global_position = _pull_destination
		state = State.ACTIVE
		_pull_hooker = null
		return
	global_position = _pull_origin.lerp(_pull_destination, _pull_progress)
