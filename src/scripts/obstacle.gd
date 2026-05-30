extends Sprite2D
class_name Obstacle

# A static environment prop that occupies one or more grid cells. Its cells are
# marked blocked, so towers can't be placed on them AND the mob pathfinder treats
# them as walls and routes around. Hand-placed in campaign; random in MP. Placement
# must never fully seal the path to a checkpoint (caller's responsibility).

const GridScript := preload("res://scripts/grid.gd")

const FILL := 1.12  # scale props slightly past their footprint so they read as solid

var cells: Array = []  # Array[Vector2i] this prop occupies

# origin = top-left footprint cell; w/h = footprint size in tiles.
func setup(tex: Texture2D, origin: Vector2i, w: int, h: int) -> void:
	texture = tex
	cells = []
	for dx in range(w):
		for dy in range(h):
			cells.append(origin + Vector2i(dx, dy))

	# Center the sprite over the footprint rectangle.
	var fw := w * GridScript.TILE_SIZE
	var fh := h * GridScript.TILE_SIZE
	var top_left := GridScript.cell_to_world(origin) - Vector2(GridScript.TILE_SIZE / 2.0, GridScript.TILE_SIZE / 2.0)
	position = top_left + Vector2(fw / 2.0, fh / 2.0)

	# Uniform-fit the texture inside the footprint box (no distortion).
	var ts := tex.get_size()
	if ts.x > 0.0 and ts.y > 0.0:
		var s: float = minf(float(fw) / ts.x, float(fh) / ts.y) * FILL
		scale = Vector2(s, s)

	# Above background / path overlay, below towers and mobs (z = 0).
	z_index = -5
	add_to_group("obstacles")
