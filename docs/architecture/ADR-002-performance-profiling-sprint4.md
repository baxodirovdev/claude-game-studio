# ADR-002: Performance Profiling — Sprint 4

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-04-04 |
| **Decision Makers** | performance-analyst, lead-programmer |
| **Sprint** | Sprint 4 |

## Context

First formal performance audit of the codebase. Target: 60fps on desktop
(16.6ms frame budget). Identified hotspots and applied fixes.

## Issues Found and Fixed

### CRITICAL — Fixed

| Issue | File | Lines | Fix |
|-------|------|-------|-----|
| `get_tree().get_nodes_in_group()` in `_physics_process()` (2 calls per frame per projectile) | hook_projectile.gd | 67, 112 | Cache targets array once on `_ready()`, reuse cached list |

### HIGH — Documented for Future Fix

| Issue | File | Lines | Est. Impact | Recommended Fix |
|-------|------|-------|-------------|-----------------|
| VFX creates 8+ MeshInstance3D per hit, no pooling | vfx_system.gd | 126-204 | ~0.5ms per hit burst | Object pool for mesh instances |
| Unbounded `_damage_history` array growth + per-frame cleanup | health_component.gd | 28, 42, 71 | Negligible at current scale | Cap array size, timer-based cleanup |
| Dictionary allocation per kill in score feed | score_system.gd | 133-140 | Negligible (kills are rare events) | Pre-allocate feed entry pool |

### MEDIUM — Acceptable

| Issue | File | Lines | Notes |
|-------|------|-------|-------|
| Kill feed UI rebuilds all labels on update | game_hud.gd | 250-274 | Max 4 labels, acceptable. Pool if feed grows. |
| `get_nodes_in_group("hookable")` in respawn spawn-point selection | respawn_system.gd | 102 | Only runs on respawn (every ~3s), not hot path. |

## Frame Budget Analysis (Estimated)

| System | Est. Cost/Frame | Budget | Status |
|--------|----------------|--------|--------|
| Physics (CharacterBody3D move_and_slide) | ~1-2ms | 3ms | OK |
| Hook projectile collision (cached) | ~0.1ms | 1ms | OK (was ~0.5ms before caching) |
| Health component process | ~0.05ms | 0.5ms | OK |
| Score system process (kill feed cleanup) | ~0.02ms | 0.5ms | OK |
| HUD update (health bar, timer, XP) | ~0.1ms | 1ms | OK |
| VFX particles (GPU) | ~1-3ms GPU | 5ms GPU | OK |
| Camera follow + shake | ~0.05ms | 0.5ms | OK |
| **Total estimated** | **~3-5ms** | **16.6ms** | **Well under budget** |

## Decisions

1. **Fix critical issues immediately** — tree queries in hot paths are never acceptable.
2. **Document but defer medium issues** — current player count (2) makes these negligible.
   Revisit when scaling to 5v5.
3. **VFX pooling deferred to Sprint 5** — per-hit mesh creation is wasteful but
   infrequent enough at current scale. Add object pooling when VFX are finalized.

## Monitoring

Run Godot's built-in profiler (`F5` → Debugger → Profiler tab) during a full match.
Key metrics to watch:
- `idle_time` > 12ms → investigate
- `physics_process` > 4ms → investigate
- `Object count` growing unbounded → memory leak
