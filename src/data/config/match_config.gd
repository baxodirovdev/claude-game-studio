## Match configuration resource — all match-level gameplay values.
##
## One per match mode. Systems read from this resource for match timing,
## respawn rules, and win conditions.
## Implements GDD: design/gdd/match-state-manager.md, design/gdd/respawn-system.md.
class_name MatchConfig
extends Resource

@export_group("Arena")
## Arena data resource to use for this match.
@export var arena_data: ArenaData

@export_group("Match Flow")
## Countdown before match starts (seconds).
@export var countdown_duration: float = 3.0
## Total match duration (seconds). Default 5 minutes.
@export var match_duration: float = 300.0
## How long the ended screen displays (seconds).
@export var ended_display_duration: float = 3.0
## Kills needed to win. 0 = timer only.
@export var kill_target: int = 20

@export_group("Respawn")
## Base respawn wait time (seconds).
@export var base_respawn_time: float = 3.0
## Extra respawn time during overtime (seconds).
@export var overtime_penalty: float = 2.0
## Post-respawn invulnerability duration (seconds).
@export var invulnerability_duration: float = 2.0

@export_group("Hazards")
## Spike zone base damage per trigger.
@export var spike_base_damage: float = 30.0
## Per-player spike cooldown between damage triggers (seconds).
@export var spike_cooldown_duration: float = 1.0
## Spike damage scaling per minute of match time.
@export var spike_scaling_per_minute: float = 0.05
