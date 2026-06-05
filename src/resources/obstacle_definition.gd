extends Resource
class_name ObstacleDefinition

# A single sized environmental prop on a map. Authored in campaign .tres files;
# produced by the generator for PVE/PVP. The runtime Obstacle node looks up the
# texture + overhang from ObstacleProps by prop_id; the cells it BLOCKS are the
# footprint rect anchored at origin. The drawn sprite may spill beyond these
# cells (base-anchored overhang) — block = footprint, draw = sprite.
#
# Stored in MapResource.obstacles as an UNTYPED Array (duck-typed in map_loader),
# mirroring bonus_zones — project memory flags typed cross-script Array[X] in
# .tres as failure-prone.

@export var prop_id: String = ""          # key into ObstacleProps.PROPS
@export var origin: Vector2i = Vector2i.ZERO   # top-left blocked cell
@export var footprint: Vector2i = Vector2i.ONE # cells blocked, w x h from origin

# The cells this prop occupies (and blocks). Registry-free so the loader and the
# generator's path validator never need ObstacleProps.
func blocked_cells() -> Array:
	var cells: Array = []
	for dx in range(maxi(1, footprint.x)):
		for dy in range(maxi(1, footprint.y)):
			cells.append(origin + Vector2i(dx, dy))
	return cells
