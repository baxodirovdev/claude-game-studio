# Sprint 3 Balance Tuning Notes

> Date: 2026-04-03
> Target: 3-4 hits to kill in most matchups, 3-8 second active combat time

## Changes Made

### Lash (Grapple)
- **hook_damage**: 20 → 25 (+25%)
- **hook_cooldown**: 3.0s → 2.5s (-17%)
- **Rationale**: At 20 dmg, Lash needed 7 hits to kill Maw (130 HP), making the grapple
  risk completely unrewarding. With 25 dmg and faster cooldown, Lash's DPS improves
  significantly while the grapple-into-danger mechanic feels justified by the damage output.

### Maw (Boomerang)
- **hook_damage**: 40 → 35 (-12.5%)
- **boomerang_return_damage**: 30 → 25 (-17%)
- **Total per-pass damage**: 70 → 60 (-14%)
- **Rationale**: Maw's double-hit dealt 70 damage per pass, nearly one-shotting Lash (80 HP).
  At 60 per pass, Maw still kills Lash in 2 passes but Lash survives a forward-only hit
  (35 < 80), preserving counterplay. Maw remains the highest burst hero but not oppressive.

### Vex (Pull) — Unchanged
- 30 dmg, 100 HP, 2.0s CD remains the baseline.

## Hits-to-Kill Matrix

| Attacker → | vs Vex (100 HP) | vs Lash (80 HP) | vs Maw (130 HP) |
|------------|----------------|-----------------|-----------------|
| **Vex** (30 dmg) | 4 hits | 3 hits | 5 hits |
| **Lash** (25 dmg) | 4 hits | 4 hits | 6 hits |
| **Maw** (35+25 pass) | 2 passes | 2 passes | 3 passes |

## Kill Time Estimates (with cooldowns)

| Matchup | Hits Needed | Cooldown | Est. Kill Time |
|---------|------------|----------|----------------|
| Vex vs Vex | 4 | 2.0s | ~6s |
| Vex vs Lash | 3 | 2.0s | ~4s |
| Vex vs Maw | 5 | 2.0s | ~8s |
| Lash vs Vex | 4 | 2.5s | ~7.5s |
| Lash vs Lash | 4 | 2.5s | ~7.5s |
| Lash vs Maw | 6 | 2.5s | ~12.5s (high, offset by grapple mobility) |
| Maw vs Vex | 2 passes | 2.5s | ~5s (if both hit) |
| Maw vs Lash | 2 passes | 2.5s | ~5s (if both hit) |
| Maw vs Maw | 3 passes | 2.5s | ~7.5s |

All matchups fall within the 3-8s target for active combat, except Lash vs Maw
which is intentionally longer (Lash compensates with mobility and escape).

## Open Issues for Future Tuning
- Lash vs Maw time (12.5s) may need monitoring — if it feels too long, consider
  a Lash-specific bonus like grapple damage multiplier
- Maw's double-hit reward could use skill-scaling (e.g., return hit bonus if both
  connect in same pass)
- Level 3 bonuses may push some matchups too far — monitor after leveling tests
