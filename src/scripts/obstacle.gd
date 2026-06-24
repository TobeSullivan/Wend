extends Sprite2D
class_name Obstacle

const GridScript := preload("res://scripts/grid.gd")

const OVERHANG_ROWS := 3.0

var cells: Array = []

func setup(tex: Texture2D, origin: Vector2i, footprint: Vector2i, overhang: float = 1.0) -> void:
	texture = tex
	var fw_cells: int = maxi(1, footprint.x)
	var fh_cells: int = maxi(1, footprint.y)

	cells = []
	for dx in range(fw_cells):
		for dy in range(fh_cells):
			cells.append(origin + Vector2i(dx, dy))

	var tile := float(GridScript.TILE_SIZE)
	var fw := fw_cells * tile
	var fh := fh_cells * tile

	var ts := tex.get_size()
	if ts.x <= 0.0 or ts.y <= 0.0:
		return
	var aspect := ts.x / ts.y

	var draw_w := fw * overhang
	var draw_h := draw_w / aspect
	var max_h := fh + OVERHANG_ROWS * tile
	if draw_h > max_h:
		draw_h = max_h
		draw_w = draw_h * aspect
	scale = Vector2(draw_w / ts.x, draw_w / ts.x)

	var fp_top_left := GridScript.cell_to_world(origin) - Vector2(tile / 2.0, tile / 2.0)
	var base_y := fp_top_left.y + fh
	position = Vector2(fp_top_left.x + fw / 2.0, base_y - draw_h / 2.0)

	z_index = -5
	add_to_group("obstacles")
