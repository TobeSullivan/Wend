extends Sprite2D
class_name Obstacle

# A static environment prop that occupies (and blocks) one or more grid cells. Its
# footprint cells are marked blocked, so towers can't be placed on them AND the mob
# pathfinder treats them as walls and routes around. Hand-placed in campaign; random
# in MP. Placement must never fully seal the path to a checkpoint (caller's job).
#
# Block = footprint. Draw = sprite, BASE-ANCHORED: the art is drawn in elevation
# (props stand up), so the sprite is fit to the footprint width and allowed to
# overhang UPWARD beyond its blocked cells (a building facade spills over the 2×2 it
# blocks) — overhang is cosmetic and never blocks. A per-prop `overhang` fudges the
# width; tall art is height-capped so a thin lamp doesn't tower over the board.

const GridScript := preload("res://scripts/grid.gd")

# How many tiles a prop may spill above its footprint before the fit switches from
# width-driven to height-capped (keeps tall/thin art from dominating the board).
const OVERHANG_ROWS := 3.0

var cells: Array = []  # Array[Vector2i] this prop occupies (= blocks)
# Cells the base-anchored art spills UPWARD into, above the footprint. These stay walkable
# (pathfinding) and unblocked (sim/resim); the LOCAL build UI just forbids placing towers on
# them so a tower never appears to float on a tall prop. Cosmetic — never enters the record.
var overhang_cells: Array = []  # Array[Vector2i]

# origin = top-left footprint cell; footprint = cells (w×h) it blocks; overhang =
# width fudge (≈0.8–1.1). The drawn sprite keeps the texture aspect, so it may
# extend above the footprint.
func setup(tex: Texture2D, origin: Vector2i, footprint: Vector2i, overhang: float = 1.0) -> void:
	texture = tex
	var fw_cells: int = maxi(1, footprint.x)
	var fh_cells: int = maxi(1, footprint.y)

	cells = []
	for dx in range(fw_cells):
		for dy in range(fh_cells):
			cells.append(origin + Vector2i(dx, dy))

	var tile := float(GridScript.TILE_SIZE)
	var fw := fw_cells * tile   # footprint width in px
	var fh := fh_cells * tile   # footprint height in px

	var ts := tex.get_size()
	if ts.x <= 0.0 or ts.y <= 0.0:
		return
	var aspect := ts.x / ts.y  # width / height

	# Width-fit to the footprint (× overhang); if the art is tall enough that this
	# would spill more than OVERHANG_ROWS above the footprint, height-cap instead so
	# it stays within the footprint width.
	var draw_w := fw * overhang
	var draw_h := draw_w / aspect
	var max_h := fh + OVERHANG_ROWS * tile
	if draw_h > max_h:
		draw_h = max_h
		draw_w = draw_h * aspect
	scale = Vector2(draw_w / ts.x, draw_w / ts.x)

	# Base-anchor: bottom edge of the sprite sits at the bottom of the footprint
	# rect, centered horizontally over it. Sprite2D is centered by default, so place
	# its center half a drawn-height above the footprint's bottom edge.
	var fp_top_left := GridScript.cell_to_world(origin) - Vector2(tile / 2.0, tile / 2.0)
	var base_y := fp_top_left.y + fh
	position = Vector2(fp_top_left.x + fw / 2.0, base_y - draw_h / 2.0)

	# Mark the cells the art overhangs above the footprint as no-build (local UI only). Only
	# props whose art rises more than half a cell past their footprint contribute — small props
	# (a bin, a tyre) don't, so this is just the genuinely tall art (e.g. the ruin pillar).
	overhang_cells = []
	var overhang_px := draw_h - fh
	if overhang_px > tile * 0.5:
		var rows := int(round(overhang_px / tile))
		for dx in range(fw_cells):
			for r in range(1, rows + 1):
				overhang_cells.append(origin + Vector2i(dx, -r))

	# Above background / path overlay, below towers and mobs (z = 0). Sort taller
	# props by their base row so nearer (lower) ones overlap correctly.
	z_index = -5
	add_to_group("obstacles")
