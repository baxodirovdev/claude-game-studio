# Sprint 6 Economy Tuning Notes

> Date: 2026-04-04

## Changes

| Parameter | Before | After | Rationale |
|-----------|--------|-------|-----------|
| passive_gold | 10 | 15 | First item took ~3.75min passive-only. Now ~2min. |
| passive_interval | 15s | 12s | Combined with gold increase, passive GPM goes from 40 to 75. |

## Updated GPM Analysis

| Income Source | GPM (Before) | GPM (After) |
|--------------|-------------|-------------|
| Passive only | 40 | 75 |
| + 2 kills/min | 240 | 275 |
| + 3 hits/min | 285 | 320 |

## Time to Items (Active Player, ~275 GPM)

| Item | Cost | Time |
|------|------|------|
| Swift Boots | 150g | ~33s |
| Sharpened Hook | 200g | ~44s |
| Iron Plating | 200g | ~44s |
| Quick Reel | 300g | ~65s |
| Barbed Chain | 350g | ~76s |
| Thick Hide | 350g | ~76s |

## Time to Items (Passive Only, 75 GPM)

| Item | Cost | Time |
|------|------|------|
| Swift Boots | 150g | ~2.0min |
| Sharpened Hook | 200g | ~2.7min |
| Quick Reel | 300g | ~4.0min |
| Barbed Chain | 350g | ~4.7min |

First item at ~2min passive feels right. Active players get first item at ~30-45s,
which is a meaningful power spike without being oppressive.
