# In-Match Economy

> **Status**: Designed
> **Author**: economy-designer + game-designer
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Pillar 1 (Skillshot is King), Pillar 3 (Quick to Play, Deep to Master)

## Overview

The In-Match Economy gives players gold for skillful play (kills, assists, hook hits)
and a small passive trickle. Gold is spent at a quick-buy shop on 6 items that modify
hero stats for the remainder of the match. Items create meaningful power spikes that
reward skilled play without creating insurmountable leads — a player behind on gold
can still outplay an itemized opponent through superior hook accuracy.

## Player Fantasy

**"I'm snowballing."** Landing hooks earns gold. Gold buys items. Items make hooks
deadlier. The better you play, the faster you scale — but one whiffed fight and the
enemy catches up. The economy creates momentum without making the game feel decided
by minute 2. Every purchase is a commitment: "Do I buy damage to close kills faster,
or defense to survive longer fights?"

## Detailed Rules

### Gold Sources

| Source | Gold Amount | Condition |
|--------|-----------|-----------|
| Kill | 100 | Killing blow on enemy player |
| Assist | 50 | Assist credit (damage within 5s, not killer) |
| Hook Hit (non-lethal) | 15 | Hook connects but doesn't kill |
| Passive Income | 10 | Every 15 seconds during PLAYING state |
| First Blood Bonus | 50 | First kill of the match (bonus on top of kill gold) |

### Gold Rules

1. Gold starts at 0 every match
2. Gold is NOT lost on death
3. Gold carries through respawn
4. Gold is per-player, not per-team
5. Passive income ticks during PLAYING and OVERTIME
6. No gold earned during COUNTDOWN or ENDED states

### Items

| # | Name | Category | Cost | Effect | Stack |
|---|------|----------|------|--------|-------|
| 1 | Sharpened Hook | Offensive | 200 | +15% hook damage | No |
| 2 | Barbed Chain | Offensive | 350 | +25% hook damage, +10% hook range | No |
| 3 | Iron Plating | Defensive | 200 | +20 max health (and current health) | No |
| 4 | Thick Hide | Defensive | 350 | +40 max health, +5% move speed | No |
| 5 | Swift Boots | Utility | 150 | +15% move speed | No |
| 6 | Quick Reel | Utility | 300 | -20% hook cooldown, +10% hook return speed | No |

### Item Rules

1. Maximum 3 items per player per match
2. Items cannot be sold or refunded
3. Each item can only be purchased once (no stacking same item)
4. Item stats apply immediately on purchase
5. Items persist through death and respawn
6. Item effects are multiplicative with level bonuses

### Shop Access

1. Shop button visible at bottom of HUD during PLAYING/OVERTIME
2. Tap opens a compact overlay (does NOT pause game)
3. Items show name, cost, effect summary, and affordability
4. One tap to buy — no confirmation dialog (speed is priority)
5. Shop auto-closes 1 second after purchase
6. Owned items shown with checkmark, grayed out

## Formulas

### Gold Per Minute (GPM) Estimates

```
passive_gpm = (60 / passive_interval) * passive_amount
            = (60 / 15) * 10 = 40 gold/min

kill_gpm = kills_per_minute * kill_gold
         = ~2 * 100 = 200 gold/min (active player)

total_gpm_active = ~240-280 gold/min
total_gpm_passive = ~40 gold/min
```

### Time to First Item (cheapest: Swift Boots, 150g)

```
passive_only: 150 / 40 = 3.75 minutes
with_2_kills: (150 - 200) → instant after 2 kills
with_hits: 150 / (40 + 15*3) = 1.76 minutes (3 hits/min + passive)
```

### Time to Full Build (3 items, ~700-1000g total)

```
budget_build (150+200+200 = 550g): ~2-3 minutes active play
expensive_build (300+350+350 = 1000g): ~4-5 minutes active play
match_duration: 5 minutes → most players get 2-3 items per match
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| kill_gold | int | 50-200 | config | Gold per kill |
| assist_gold | int | 25-100 | config | Gold per assist |
| hit_gold | int | 5-30 | config | Gold per non-lethal hook hit |
| passive_gold | int | 5-20 | config | Gold per passive tick |
| passive_interval | float | 10-30s | config | Seconds between passive ticks |
| first_blood_bonus | int | 25-100 | config | Extra gold for first kill |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player dies with 349 gold (1 short of Barbed Chain) | Gold retained. Can earn 1 more gold after respawn. | Gold not lost on death. |
| Player has 3 items and tries to buy | Shop shows all items grayed with "FULL" text. | Clear feedback, no confusion. |
| Player buys health item while damaged | Max health increases. Current health increases by same amount. | Feel-good moment — instant value. |
| Two players get kill simultaneously (edge case) | Both get kill gold for their respective victims. | Independent tracking. |
| Passive tick fires at exact match end | Gold awarded (match end processes after tick). | Generous — doesn't matter since match is ending. |
| Player disconnects with items | Items and gold are lost. Stats revert on disconnected player's node removal. | Per-match state, no persistence. |
| Overtime starts — does passive continue? | Yes, passive income continues during overtime. | Keeps economy flowing in extended games. |

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| **Score/Kill Tracking** | Upstream | Hard — triggers gold on kill/assist | Listens to `kill_occurred`, `assist_awarded` |
| **Hook System** | Upstream | Soft — triggers gold on hook hit | Listens to `hook_hit` |
| **Match State Manager** | Upstream | Hard — controls passive tick timing | Reads match state for tick enable/disable |
| **Hero System** | Downstream | Hard — items modify hero stats | Calls stat modification methods |
| **HUD** | Downstream | Soft — displays gold and shop | Provides gold count and item state |

## Tuning Knobs

| Parameter | Default | Safe Range | Increase Effect | Decrease Effect |
|-----------|---------|------------|----------------|-----------------|
| kill_gold | 100 | 50-200 | Faster snowball from kills | Slower economy, more items from passive |
| assist_gold | 50 | 25-100 | Supports more rewarding teamwork | Assists feel less valuable |
| hit_gold | 15 | 5-30 | Rewards accuracy even without kills | Less reward for chip damage |
| passive_gold | 10 | 5-20 | Catches up losing player faster | Widens skill-based gold gap |
| passive_interval | 15 | 10-30 | More frequent ticks, faster catchup | Slower catchup, kills matter more |
| item_max | 3 | 2-4 | More build diversity | Simpler decisions, less snowball |

## Acceptance Criteria

- [ ] Gold awarded correctly for kills (100), assists (50), hook hits (15)
- [ ] Passive income ticks every 15 seconds during PLAYING/OVERTIME
- [ ] First blood bonus (50) awarded for first kill of the match
- [ ] Gold displays on HUD and updates in real-time
- [ ] Shop UI opens/closes quickly (<0.3s)
- [ ] All 6 items purchasable with correct costs
- [ ] Item stat effects apply immediately and correctly
- [ ] Maximum 3 items enforced
- [ ] Items persist through death
- [ ] Gold resets on new match
- [ ] All gold/cost values loaded from config — no hardcoded values
