## Audio System — manages game sound effects with pooled AudioStreamPlayers.
##
## Uses procedurally generated placeholder sounds (AudioStreamGenerator or simple
## WAV tones). Replace with real assets when available. All sounds go through
## a pooled player system to avoid runtime allocation.
## Sprint 3 S3-08.
class_name AudioSystem
extends Node

## SFX pool size.
const POOL_SIZE: int = 8

var _sfx_pool: Array[AudioStreamPlayer] = []

# Pre-generated sound streams (placeholder beeps/clicks)
var _sfx_hook_fire: AudioStream
var _sfx_hook_hit: AudioStream
var _sfx_hook_miss: AudioStream
var _sfx_kill: AudioStream
var _sfx_death: AudioStream
var _sfx_countdown_beep: AudioStream
var _sfx_match_start: AudioStream
var _sfx_respawn: AudioStream

func _ready() -> void:
	# Create pooled players
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_sfx_pool.append(player)

	# Generate placeholder sounds
	_sfx_hook_fire = _generate_tone(220.0, 0.15, -6.0)
	_sfx_hook_hit = _generate_tone(880.0, 0.1, -3.0)
	_sfx_hook_miss = _generate_tone(150.0, 0.2, -10.0)
	_sfx_kill = _generate_tone(1200.0, 0.25, -3.0)
	_sfx_death = _generate_tone(100.0, 0.4, -6.0)
	_sfx_countdown_beep = _generate_tone(600.0, 0.1, -6.0)
	_sfx_match_start = _generate_tone(800.0, 0.3, -3.0)
	_sfx_respawn = _generate_tone(500.0, 0.2, -6.0)

## Play hook fire sound.
func play_hook_fire() -> void:
	_play_pooled(_sfx_hook_fire)

## Play hook hit (impact) sound.
func play_hook_hit() -> void:
	_play_pooled(_sfx_hook_hit)

## Play hook miss (whoosh) sound.
func play_hook_miss() -> void:
	_play_pooled(_sfx_hook_miss)

## Play kill confirmation chime.
func play_kill() -> void:
	_play_pooled(_sfx_kill)

## Play death sound.
func play_death() -> void:
	_play_pooled(_sfx_death)

## Play countdown beep.
func play_countdown_beep() -> void:
	_play_pooled(_sfx_countdown_beep)

## Play match start horn.
func play_match_start() -> void:
	_play_pooled(_sfx_match_start)

## Play respawn sound.
func play_respawn() -> void:
	_play_pooled(_sfx_respawn)

## Play a sound from the pool.
func _play_pooled(stream: AudioStream) -> void:
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# All players busy — steal the first one
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()

## Generate a simple sine wave tone as an AudioStreamWAV.
## frequency: Hz, duration: seconds, volume_db: decibels relative to 0
func _generate_tone(frequency: float, duration: float, volume_db: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit samples

	var volume := db_to_linear(volume_db)
	var max_amp := 32767.0 * volume

	for i in range(num_samples):
		var t := float(i) / sample_rate
		# Envelope: quick attack, exponential decay
		var envelope := maxf(0.0, 1.0 - t / duration) * (1.0 - exp(-t * 50.0))
		var sample := sin(TAU * frequency * t) * max_amp * envelope
		var sample_int := clampi(int(sample), -32768, 32767)
		# Little-endian 16-bit
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav
