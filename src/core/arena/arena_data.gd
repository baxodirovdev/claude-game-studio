## Data resource defining an arena's layout, dimensions, and hazard placement.
##
## Create .tres files from this resource for each map.
## All systems read arena properties from this resource, never from hardcoded values.
class_name ArenaData
extends Resource

@export_group("Dimensions")
## Total playable width (X axis, left-to-right).
@export var arena_width: float = 46.0
## Total playable depth (Z axis, top-to-bottom).
@export var arena_depth: float = 40.0
## Width of the central gap (impassable zone at X=0).
@export var gap_width: float = 6.0

@export_group("Spawn Points")
## Spawn positions for Team A (left side, negative X).
@export var team_a_spawns: Array[Vector3] = [
	Vector3(-15, 0.8, -6),
	Vector3(-15, 0.8, -3),
	Vector3(-15, 0.8, 0),
	Vector3(-15, 0.8, 3),
	Vector3(-15, 0.8, 6),
]
## Spawn positions for Team B (right side, positive X).
@export var team_b_spawns: Array[Vector3] = [
	Vector3(15, 0.8, -6),
	Vector3(15, 0.8, -3),
	Vector3(15, 0.8, 0),
	Vector3(15, 0.8, 3),
	Vector3(15, 0.8, 6),
]

@export_group("Hazards")
## Spike zone positions (center of each zone).
@export var spike_zones: Array[Vector3] = [
	Vector3(-4, 0, -8),
	Vector3(-4, 0, 8),
	Vector3(4, 0, -8),
	Vector3(4, 0, 8),
]
## Spike zone radius.
@export var spike_zone_radius: float = 3.0
## Pit positions (center of each pit).
@export var pit_zones: Array[Vector3] = [
	Vector3(-10, 0, -10),
	Vector3(-10, 0, 10),
	Vector3(10, 0, -10),
	Vector3(10, 0, 10),
]
## Pit radius.
@export var pit_radius: float = 2.0

@export_group("Visuals")
## Ground color for both halves.
@export var ground_color: Color = Color(0.3, 0.5, 0.3, 1)
## Gap color (void).
@export var gap_color: Color = Color(0.15, 0.15, 0.4, 1)

## Half-width of each team's playable area (from gap edge to boundary).
func get_half_width() -> float:
	return (arena_width - gap_width) / 2.0

## X coordinate of the left gap edge.
func get_gap_left_edge() -> float:
	return -gap_width / 2.0

## X coordinate of the right gap edge.
func get_gap_right_edge() -> float:
	return gap_width / 2.0

## Left boundary X.
func get_left_boundary() -> float:
	return -arena_width / 2.0

## Right boundary X.
func get_right_boundary() -> float:
	return arena_width / 2.0

## Top boundary Z (positive).
func get_top_boundary() -> float:
	return arena_depth / 2.0

## Bottom boundary Z (negative).
func get_bottom_boundary() -> float:
	return -arena_depth / 2.0
