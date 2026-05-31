extends Node

# STUB. Produces a MapResource from (seed, scale_tier, mode) for PVE and PVP.
# This is a placeholder that returns a simple valid map so campaign/loader work
# is unblocked — it does NOT yet implement the real procedural generation or the
# constraint guarantees specced in DESIGN_MODES.md ("Procgen constraints"):
#   - at least one bonus zone reachable within the supply cap
#   - no more than two zones overlapping
#   - a valid entry→checkpoints→exit path with zero towers
#   - entry/exit on opposite sides, checkpoints forcing a long traversal
#   - obstacles never seal the initial path or the entry/exit funnel
# TODO: implement seeded generation + constraint validation/retry loop.

const MapResourceScript := preload("res://resources/map_resource.gd")
const ZoneDefinitionScript := preload("res://resources/zone_definition.gd")

# Per-scale parameters from DESIGN_MODES.md (PVE difficulty table). Round count
# is a [min, max] range; the real generator picks within it from the seed.
const SCALE_TABLE := {
	1: {"supply": 10, "checkpoints": 1, "zones": [1, 2], "mobs": 8,  "rounds": [10, 13]},
	2: {"supply": 20, "checkpoints": 1, "zones": [2, 3], "mobs": 12, "rounds": [13, 17]},
	3: {"supply": 30, "checkpoints": 2, "zones": [3, 4], "mobs": 16, "rounds": [17, 21]},
	4: {"supply": 40, "checkpoints": 2, "zones": [4, 5], "mobs": 20, "rounds": [21, 26]},
	5: {"supply": 50, "checkpoints": 3, "zones": [5, 6], "mobs": 24, "rounds": [26, 30]},
}

# Returns a MapResource. `mode` is a MapResource.Mode value.
static func generate(seed: int, scale_tier: int, mode: int):
	var tier: int = clampi(scale_tier, 1, 5)
	var params: Dictionary = SCALE_TABLE[tier]

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var map = MapResourceScript.new()
	map.seed = seed
	map.mode = mode
	map.scale_tier = tier
	map.grid_size = Vector2i(40, 22)
	map.supply_cap = params.supply
	map.mob_count = params.mobs
	map.round_count = rng.randi_range(params.rounds[0], params.rounds[1])

	# Placeholder fixed layout — entry left, exit right, one mid checkpoint.
	# The real generator scatters checkpoints/obstacles/zones per the constraints.
	map.entry_cell = Vector2i(0, 11)
	map.exit_cell = Vector2i(39, 11)
	map.checkpoint_cells = [Vector2i(20, 4)] as Array[Vector2i]
	map.obstacle_cells = [] as Array[Vector2i]

	var zone := ZoneDefinitionScript.new()
	zone.type = ZoneDefinitionScript.Type.DAMAGE
	zone.cell = Vector2i(20, 11)
	zone.magnitude = 30
	map.bonus_zones = [zone]

	return map
