extends Node
class_name Grid

# Map dimensions in tiles.
# Canonical board (2026-06-07): 25x16, PC-first, LOCKED UNIVERSAL (design/INMATCH_HUD.md
# "Board maximization"). Derived once at the 1080p reference: with the right rail reserved
# (~280px) the board area fits 25 cols x 16 rows at the fixed tile size; the two extra rows
# (over the old 25x14) fill what used to be the top/bottom letterbox. Every player runs
# 25x16 regardless of monitor — other resolutions scale+center the same grid. Generated
# PVE/PVP maps read COLS/ROWS directly; the authored campaign .tres are 25x16. TILE_SIZE
# stays world-space; on-screen size is the camera's concern, not a world value.
const TILE_SIZE := 48
const COLS := 25
const ROWS := 16  # 1200 x 768 world px

const ORIGIN := Vector2.ZERO  # top-left of grid in world coordinates

static func cell_to_world(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell.x * TILE_SIZE + TILE_SIZE / 2.0, cell.y * TILE_SIZE + TILE_SIZE / 2.0)

static func world_to_cell(pos: Vector2) -> Vector2i:
	var local := pos - ORIGIN
	return Vector2i(int(floor(local.x / TILE_SIZE)), int(floor(local.y / TILE_SIZE)))

static func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS
