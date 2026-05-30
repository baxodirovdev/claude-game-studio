## Pudge stress test — spawns N copies of pudge.glb, samples frame time, exits.
##
## Step 6 of the Pudge revision sprint (per
## production/session-state/RESUME-PUDGE-SPEC-REVISION.md). Replaces the
## "wishful <16 ms" placeholder in `design/gdd/models/pudge.md` §11 F.4 with
## a measured number. Final pass/fail decision is gated on the target device
## tier (contract O-1, deferred); this scene establishes the dev-machine
## baseline + the measurement workflow.
##
## Run from the Godot editor (Project > Run Scene), or headlessly via:
##     ~/Applications/Godot/Godot_v4.6.3-stable_linux.x86_64 \
##         --path src/ res://scenes/perf/pudge_stress_test.tscn
##
## Headless mode reports CPU frame time only — GPU work is suppressed.
## For real GPU timings, run on a display.
class_name PudgeStressTest
extends Node3D

## How many Pudge instances to spawn in a grid. Default matches contract §11
## F.4 stress baseline (10 heroes).
@export var instance_count: int = 10

## Spacing between adjacent grid cells (meters in world space).
@export var grid_spacing: float = 2.5

## How many seconds of frame deltas to collect before reporting.
@export var sample_duration_sec: float = 5.0

## How long to wait before sampling begins (so scene-load spike is excluded).
@export var warmup_sec: float = 1.0

## Auto-quit after reporting (true for headless / CI; false for in-editor inspection).
@export var quit_after_report: bool = true

## Path to the HeroConfig resource used for all instances.
@export_file("*.tres") var hero_config_path: String = "res://data/heroes/pudge.tres"

# Sampling state
var _hero_config: HeroConfig
var _hero_containers: Array[Node3D] = []
var _state: String = "warmup"  # warmup → sampling → done
var _state_elapsed: float = 0.0
var _frame_deltas: Array[float] = []


func _ready() -> void:
	_hero_config = load(hero_config_path) as HeroConfig
	if _hero_config == null:
		push_error("PudgeStressTest: failed to load HeroConfig at %s" % hero_config_path)
		_finish_with_error()
		return

	# Disable vsync so frame deltas reflect actual GPU/CPU cost, not the
	# monitor refresh rate. With vsync on, every frame is artificially
	# clamped to 16.67 ms regardless of how fast the scene actually renders.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0

	_spawn_hero_grid()
	var bar: String = "=".repeat(60)
	var rd := RenderingServer.get_rendering_device()
	var renderer_name: String = rd.get_device_name() if rd != null else "<headless / no RenderingDevice>"
	print(bar)
	print("PUDGE STRESS TEST — %d instances of %s" % [instance_count, _hero_config.hero_id])
	print(bar)
	print("Renderer: %s" % renderer_name)
	print("Warmup: %.1f s    Sample window: %.1f s" % [warmup_sec, sample_duration_sec])
	print("Grid: %s    Spacing: %.2f m" % [_grid_dims_text(), grid_spacing])
	print()


func _process(delta: float) -> void:
	_state_elapsed += delta
	match _state:
		"warmup":
			if _state_elapsed >= warmup_sec:
				_state = "sampling"
				_state_elapsed = 0.0
				print("[stress] warmup complete — sampling begins")
		"sampling":
			_frame_deltas.append(delta)
			if _state_elapsed >= sample_duration_sec:
				_state = "done"
				_report()
				if quit_after_report:
					get_tree().quit(0)
		"done":
			pass


func _spawn_hero_grid() -> void:
	# Compute a roughly-square grid (e.g. 10 instances → 5x2 = 5 wide, 2 tall).
	var cols: int = int(ceil(sqrt(float(instance_count))))
	var rows: int = int(ceil(float(instance_count) / float(cols)))
	var origin_x: float = -float(cols - 1) * grid_spacing * 0.5
	var origin_z: float = -float(rows - 1) * grid_spacing * 0.5

	for i in instance_count:
		var col: int = i % cols
		var row: int = i / cols
		var container := Node3D.new()
		container.name = "PudgeInstance_%d" % i
		container.position = Vector3(
			origin_x + col * grid_spacing,
			0.0,
			origin_z + row * grid_spacing,
		)
		add_child(container)
		HeroModelBuilder.build_model(container, _hero_config)
		_hero_containers.append(container)


func _grid_dims_text() -> String:
	var cols: int = int(ceil(sqrt(float(instance_count))))
	var rows: int = int(ceil(float(instance_count) / float(cols)))
	return "%d x %d" % [cols, rows]


func _report() -> void:
	if _frame_deltas.is_empty():
		print("[stress] no samples collected — report aborted")
		return

	# Sort for percentile calc — copy first to avoid mutating the source.
	var sorted: Array[float] = _frame_deltas.duplicate()
	sorted.sort()
	var n: int = sorted.size()

	var total: float = 0.0
	for d in sorted:
		total += d
	var mean_ms: float = (total / float(n)) * 1000.0
	var min_ms: float = sorted[0] * 1000.0
	var max_ms: float = sorted[n - 1] * 1000.0
	var p50_ms: float = sorted[int(float(n) * 0.50)] * 1000.0
	var p95_ms: float = sorted[int(float(n) * 0.95)] * 1000.0
	var p99_ms: float = sorted[mini(int(float(n) * 0.99), n - 1)] * 1000.0
	var fps_avg: float = 1000.0 / mean_ms if mean_ms > 0.0 else 0.0

	print()
	print("--- STRESS RESULTS ---")
	print("Samples collected: %d frames over %.2f s" % [n, total])
	print("Frame time (ms):  min=%.2f  p50=%.2f  mean=%.2f  p95=%.2f  p99=%.2f  max=%.2f"
		% [min_ms, p50_ms, mean_ms, p95_ms, p99_ms, max_ms])
	print("Avg FPS: %.1f" % fps_avg)
	print()
	print("Budget reference (contract §11 F.4): under 16 ms at p95 on mid-tier device.")
	print("This run measured on dev machine — NOT the mid-tier device target (O-1 deferred).")
	if p95_ms < 16.0:
		print("✓ p95 within 16 ms — dev-machine baseline meets the placeholder budget")
	else:
		print("⚠ p95 %.2f ms exceeds 16 ms — even dev machine struggles; expect mobile issues" % p95_ms)


func _finish_with_error() -> void:
	if quit_after_report:
		get_tree().quit(1)
