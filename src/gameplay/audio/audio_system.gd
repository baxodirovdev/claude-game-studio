## Audio System — manages game sound effects with pooled AudioStreamPlayers.
##
## Uses procedurally generated placeholder sounds (AudioStreamGenerator or simple
## WAV tones). Replace with real assets when available. All sounds go through
## a pooled player system to avoid runtime allocation.
## Sprint 3 S3-08, Sprint 4 S4-05 (per-hero audio).
class_name AudioSystem
extends Node

## SFX pool size.
const POOL_SIZE: int = 8

var _sfx_pool: Array[AudioStreamPlayer] = []

# Generic sound streams (placeholder beeps/clicks)
var _sfx_kill: AudioStream
var _sfx_death: AudioStream
var _sfx_countdown_beep: AudioStream
var _sfx_match_start: AudioStream
var _sfx_respawn: AudioStream

# Per-hero sound streams: { HookType: { "fire": AudioStream, "hit": AudioStream, "miss": AudioStream } }
var _hero_sfx: Dictionary = {}

func _ready() -> void:
	# Create pooled players
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_sfx_pool.append(player)

	# Generate generic sounds
	_sfx_kill = _generate_tone(1200.0, 0.25, -3.0)
	_sfx_death = _generate_tone(100.0, 0.4, -6.0)
	_sfx_countdown_beep = _generate_tone(600.0, 0.1, -6.0)
	_sfx_match_start = _generate_tone(800.0, 0.3, -3.0)
	_sfx_respawn = _generate_tone(500.0, 0.2, -6.0)

	# Generate per-hero sounds
	# PULL (Vex): Metallic chain rattle — mid-frequency, sharp attack
	_hero_sfx[HeroConfig.HookType.PULL] = {
		"fire": _generate_noise_burst(200.0, 0.12, -6.0, 8.0),  # Chain rattle
		"hit": _generate_tone(900.0, 0.08, -3.0),  # Sharp metallic ping
		"miss": _generate_tone(160.0, 0.2, -10.0),  # Low chain drag
	}
	# GRAPPLE (Lash): Zipline whoosh — high sweep, airy
	_hero_sfx[HeroConfig.HookType.GRAPPLE] = {
		"fire": _generate_sweep(400.0, 1200.0, 0.15, -6.0),  # Rising whoosh
		"hit": _generate_tone(1100.0, 0.06, -4.0),  # Quick high snap
		"miss": _generate_sweep(800.0, 200.0, 0.25, -10.0),  # Falling whoosh
	}
	# BOOMERANG (Maw): Spinning blade hum — buzzy, heavy
	_hero_sfx[HeroConfig.HookType.BOOMERANG] = {
		"fire": _generate_buzz(180.0, 0.2, -5.0),  # Heavy spinning buzz
		"hit": _generate_tone(600.0, 0.15, -2.0),  # Meaty impact thud
		"miss": _generate_buzz(120.0, 0.3, -8.0),  # Fading spin
	}
	# BEAM (Flux): Electric hum — sustained, crackling
	_hero_sfx[HeroConfig.HookType.BEAM] = {
		"fire": _generate_sweep(300.0, 600.0, 0.2, -5.0),  # Charging up
		"hit": _generate_tone(500.0, 0.1, -3.0),  # Electric lock-on snap
		"miss": _generate_sweep(500.0, 150.0, 0.2, -10.0),  # Power down
	}

## Play hook fire sound for a specific hero type.
func play_hook_fire(hook_type: int = HeroConfig.HookType.PULL) -> void:
	var sfx: Dictionary = _hero_sfx.get(hook_type, _hero_sfx.get(HeroConfig.HookType.PULL, {}))
	if sfx.has("fire"):
		_play_pooled(sfx["fire"])

## Play hook hit sound for a specific hero type.
func play_hook_hit(hook_type: int = HeroConfig.HookType.PULL) -> void:
	var sfx: Dictionary = _hero_sfx.get(hook_type, _hero_sfx.get(HeroConfig.HookType.PULL, {}))
	if sfx.has("hit"):
		_play_pooled(sfx["hit"])

## Play hook miss sound for a specific hero type.
func play_hook_miss(hook_type: int = HeroConfig.HookType.PULL) -> void:
	var sfx: Dictionary = _hero_sfx.get(hook_type, _hero_sfx.get(HeroConfig.HookType.PULL, {}))
	if sfx.has("miss"):
		_play_pooled(sfx["miss"])

## Play kill confirmation chime. Escalates with multi-kills.
func play_kill(multi_kill_count: int = 1) -> void:
	if multi_kill_count >= 3:
		# Triple kill: high chord
		_play_pooled(_generate_tone(1400.0, 0.3, -2.0))
	elif multi_kill_count == 2:
		# Double kill: higher pitch
		_play_pooled(_generate_tone(1300.0, 0.25, -2.0))
	else:
		_play_pooled(_sfx_kill)

## Play streak sound (escalating pitch with streak count).
func play_streak(streak: int) -> void:
	var freq := 800.0 + float(streak) * 100.0
	_play_pooled(_generate_tone(minf(freq, 2000.0), 0.2, -3.0))

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

## --- Ambient Audio (S4-11) ---

var _ambient_player: AudioStreamPlayer
var _ambient_normal: AudioStream
var _ambient_overtime: AudioStream
var _ambient_active: bool = false

func _create_ambient() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = &"Master"
	_ambient_player.volume_db = -18.0
	add_child(_ambient_player)

	# Normal ambient: low drone (subtle hum)
	_ambient_normal = _generate_ambient_drone(55.0, 8.0, -20.0)
	# Overtime ambient: tense higher drone
	_ambient_overtime = _generate_ambient_drone(80.0, 6.0, -16.0)

## Start ambient audio for gameplay.
func start_ambient() -> void:
	if _ambient_player == null:
		_create_ambient()
	_ambient_player.stream = _ambient_normal
	_ambient_player.play()
	_ambient_active = true

## Switch to overtime ambient (more intense).
func set_overtime_ambient() -> void:
	if _ambient_player == null:
		return
	var tween := create_tween()
	tween.tween_property(_ambient_player, "volume_db", -30.0, 0.5)
	tween.tween_callback(func() -> void:
		_ambient_player.stream = _ambient_overtime
		_ambient_player.play()
	)
	tween.tween_property(_ambient_player, "volume_db", -14.0, 0.5)

## Stop ambient audio.
func stop_ambient() -> void:
	if _ambient_player:
		var tween := create_tween()
		tween.tween_property(_ambient_player, "volume_db", -40.0, 1.0)
		tween.tween_callback(func() -> void:
			_ambient_player.stop()
		)
	_ambient_active = false

## Generate a long looping ambient drone.
func _generate_ambient_drone(frequency: float, duration: float, volume_db: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var volume := db_to_linear(volume_db)
	var max_amp := 32767.0 * volume

	for i in range(num_samples):
		var t := float(i) / sample_rate
		# Layered sine waves for richness
		var s1 := sin(TAU * frequency * t)
		var s2 := sin(TAU * frequency * 1.5 * t) * 0.3
		var s3 := sin(TAU * frequency * 0.5 * t) * 0.5
		# Slow amplitude modulation for movement
		var mod := 0.7 + 0.3 * sin(TAU * 0.15 * t)
		var sample := (s1 + s2 + s3) * max_amp * mod / 1.8
		var sample_int := clampi(int(sample), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = data
	return wav

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

## Generate a frequency sweep (rising or falling) as an AudioStreamWAV.
func _generate_sweep(freq_start: float, freq_end: float, duration: float, volume_db: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var volume := db_to_linear(volume_db)
	var max_amp := 32767.0 * volume
	var phase := 0.0

	for i in range(num_samples):
		var t := float(i) / sample_rate
		var progress := t / duration
		var freq := lerpf(freq_start, freq_end, progress)
		var envelope := maxf(0.0, 1.0 - progress) * (1.0 - exp(-t * 40.0))
		phase += TAU * freq / sample_rate
		var sample := sin(phase) * max_amp * envelope
		var sample_int := clampi(int(sample), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

## Generate a buzzy/sawtooth-like tone (for spinning blade sounds).
func _generate_buzz(frequency: float, duration: float, volume_db: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var volume := db_to_linear(volume_db)
	var max_amp := 32767.0 * volume

	for i in range(num_samples):
		var t := float(i) / sample_rate
		var envelope := maxf(0.0, 1.0 - t / duration) * (1.0 - exp(-t * 30.0))
		# Sawtooth wave for buzzy quality
		var phase := fmod(t * frequency, 1.0)
		var sample := (phase * 2.0 - 1.0) * max_amp * envelope
		var sample_int := clampi(int(sample), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

## Generate a noise burst with resonance (for chain/rattle sounds).
func _generate_noise_burst(frequency: float, duration: float, volume_db: float, resonance: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var volume := db_to_linear(volume_db)
	var max_amp := 32767.0 * volume
	var prev_sample := 0.0
	var filter_coeff := exp(-TAU * frequency / sample_rate)

	for i in range(num_samples):
		var t := float(i) / sample_rate
		var envelope := maxf(0.0, 1.0 - t / duration) * (1.0 - exp(-t * 60.0))
		# Filtered noise for metallic quality
		var noise := randf_range(-1.0, 1.0)
		prev_sample = prev_sample * filter_coeff + noise * (1.0 - filter_coeff) * resonance
		var sample := prev_sample * max_amp * envelope
		var sample_int := clampi(int(sample), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	return wav

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
