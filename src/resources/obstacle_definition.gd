extends Resource
class_name ObstacleDefinition

@export var prop_id: String = ""
@export var origin: Vector2i = Vector2i.ZERO
@export var footprint: Vector2i = Vector2i.ONE

func blocked_cells() -> Array:
	var cells: Array = []
	for dx in range(maxi(1, footprint.x)):
		for dy in range(maxi(1, footprint.y)):
			cells.append(origin + Vector2i(dx, dy))
	return cells
