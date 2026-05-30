# Performance Tests

Stress scenes that measure frame time / draw-call cost for specific assets
or scenarios. Distinct from `tests/unit/` (GUT logic tests) — these need
the renderer running.

## Pudge stress test

**Scene**: `src/scenes/perf/pudge_stress_test.tscn`
**Script**: `src/scenes/perf/pudge_stress_test.gd`
**Purpose**: Replaces the "wishful <16 ms" placeholder in
`design/gdd/models/pudge.md` §11 F.4 with a measured number. Contract
item O-12 (see `design/gdd/contracts/pudge-interface-contract.md`).

### How to run

#### Headed (real perf measurement — needs a display)

From project root, using the project's default Mobile renderer (Vulkan):

```bash
~/Applications/Godot/Godot_v4.6.3-stable_linux.x86_64 \
    --path src \
    res://scenes/perf/pudge_stress_test.tscn
```

The script disables vsync internally so frame deltas reflect actual GPU/CPU
cost rather than the monitor refresh rate. Auto-quits after sampling.

#### Headless (smoke test only — no real perf data)

```bash
~/Applications/Godot/Godot_v4.6.3-stable_linux.x86_64 \
    --headless --path src \
    res://scenes/perf/pudge_stress_test.tscn
```

Headless mode reports CPU `_process` overhead only — GPU never draws
anything. Use for verifying the scene loads + spawns 10 instances
without errors, NOT for perf evaluation.

### Exported parameters (edit in scene inspector)

| Property | Default | Purpose |
|---|---|---|
| `instance_count` | 10 | Number of Pudges to spawn in a grid |
| `grid_spacing` | 2.5 m | Distance between adjacent grid cells |
| `sample_duration_sec` | 5.0 | How long to sample frame times |
| `warmup_sec` | 1.0 | Skip first N seconds (excludes scene-load spike) |
| `quit_after_report` | true | Auto-exit after report (false for editor inspection) |
| `hero_config_path` | `res://data/heroes/pudge.tres` | Which hero's GLB to spawn |

### Output format

```
PUDGE STRESS TEST — 10 instances of pudge
============================================================
Renderer: <GPU name>
Warmup: 1.0 s    Sample window: 5.0 s
Grid: 4 x 3    Spacing: 2.50 m

[stress] warmup complete — sampling begins

--- STRESS RESULTS ---
Samples collected: <N> frames over <s> s
Frame time (ms):  min=...  p50=...  mean=...  p95=...  p99=...  max=...
Avg FPS: ...

Budget reference (contract §11 F.4): under 16 ms at p95 on mid-tier device.
```

### Baselines (history)

| Date | Hardware | Renderer | Pudge build | Instances | p50 ms | p95 ms | Notes |
|------|----------|----------|-------------|-----------|--------|--------|-------|
| 2026-05-31 | RTX 5050 (desktop) | Vulkan / Forward Mobile | Prototype primitives (~25 meshes/char) | 10 | 0.23 | 0.34 | ⚠ Desktop ≠ mobile target. Number is informational only. |

### What this number doesn't tell you

The dev-machine baseline above is **NOT** a substitute for measurement on
the actual target device. RTX 5050 is approximately 30-100× faster than
mid-tier mobile GPUs (Adreno 613, Apple A14) depending on the workload.
A useful mid-tier mobile estimate is ~10-30× the dev-machine p95.

Final perf verdict requires:

1. Resolving contract O-1 (target device tier)
2. Shipping the final Stage 10 Pudge GLB (currently the scene loads the
   prototype primitives version, which renders very differently than the
   final single-skinned-mesh version will)
3. Running this scene on the target device hardware

Until both unblock, the dev-machine baseline is captured purely to:
- Validate the measurement workflow works
- Detect regressions across changes (compare two dev-machine runs)
- Establish the result format that the final mobile run will fill in
