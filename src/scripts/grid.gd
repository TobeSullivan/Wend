extends Node
class_name Grid

# Map dimensions in tiles.
# Canonical board (2026-06-06): 25x14, PC-first. Widened 1 tile each side from the 23x14
# tile-feel-check size so the board fills more of the frame and the maze has room before
# the edges. Reverses the dead mobile-first 20x11 shrink — mobile would be a separate fork,
# not a resize. Generated PVE/PVP maps read COLS/ROWS directly; the authored campaign .tres
# (M1-M10) were rescaled to this board (tools/rescale_campaign.gd) and inherit this size via
# the MapResource default. TILE_SIZE stays world-space; on-screen size is the camera's
# concern, not a world value.
const TILE_SIZE := 48
const COLS := 25
const ROWS := 14  # 1200 x 672 world px

const ORIGIN := Vector2.ZERO  # top-left of grid in world coordinates

static func cell_to_world(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE / 2.0)

static func world_to_cell(pos: Vector2) -> Vector2i:
	var local := pos - ORIGIN
	return Vector2i(int(floor(local.x / TILE_SIZE)), int(floor(local.y / TILE_SIZE)))

static func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS
