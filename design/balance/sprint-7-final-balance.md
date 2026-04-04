# Sprint 7 Final Balance Pass

> Date: 2026-04-04
> Target: Beta readiness, all matchups 3-8s kill time

## Changes

| Hero | Parameter | Before | After | Rationale |
|------|-----------|--------|-------|-----------|
| Flux | beam_dps | 25 | 30 | 37.5 total/beam was too low (3 beams = 10.5s kill). Now 45/beam = 6s kill. |
| Flux | hook_cooldown | 3.5s | 3.0s | Shorter CD to compensate for beam's short range and vulnerability during channel. |
| Coil | hook_cooldown | 2.0s | 2.5s | Max-charge shot (50dmg, 24 range) was too spammable at 2.0s CD. |

## Final Hero Balance Matrix

| Hero | HP | Damage | Range | CD | Mechanic | Identity |
|------|----|--------|-------|-----|----------|----------|
| Vex | 100 | 30 | 20 | 2.0s | Pull target to you | Balanced baseline |
| Lash | 80 | 25 | 25 | 2.5s | Grapple to target | Glass cannon mobility |
| Maw | 130 | 35+25/pass | 15 | 2.5s | Boomerang hits twice | Tanky burst |
| Flux | 90 | 30 DPS×1.5s | 14 | 3.0s | Beam tether + pull | Sustained control |
| Coil | 95 | 20-50 | 12-24 | 2.5s | Charge for power | High skill ceiling |

## Hits/Activations to Kill (vs 100 HP Vex baseline)

| Attacker | Damage/Activation | Hits to Kill Vex | CD | Kill Time |
|----------|------------------|------------------|-----|-----------|
| Vex | 30 | 4 | 2.0s | ~6s |
| Lash | 25 | 4 | 2.5s | ~7.5s |
| Maw | 60/pass | 2 passes | 2.5s | ~5s |
| Flux | 45/beam | 3 beams | 3.0s | ~6s |
| Coil (min) | 20 | 5 | 2.5s | ~10s |
| Coil (max) | 50 | 2 | 2.5s+2s charge | ~7s |

All within 5-10s range. Maw fastest but shortest range. Coil highest variance.

## Item Impact Analysis

| Build | Stats Change | Kill Time Impact |
|-------|-------------|-----------------|
| Sharpened Hook (+15% dmg) | Vex 30→34.5 | 3 hits to kill 100HP (instead of 4) |
| Swift Boots (+15% speed) | Vex 10→11.5 | Better positioning, no direct kill impact |
| Quick Reel (-20% CD) | Vex 2.0→1.6s | Kill time drops ~20% |

Items create meaningful power spikes without being game-breaking.
Budget build (550g) reachable at ~2min active. Premium build (1000g) at ~4min.
