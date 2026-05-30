extends Node2D

const GridScript := preload("res://scripts/grid.gd")
const BonusZoneScript := preload("res://scripts/bonus_zone.gd")
const SpawnerScript := preload("res://scripts/spawner.gd")
const BuildControllerScript := preload("res://scripts/build_controller.gd")
const RoundManagerScript := preload("res://scripts/round_manager.gd")
const HUDScript := preload("res://scripts/hud.gd")
const MatchEndPanelScript := preload("res://scripts/match_end_panel.gd")
const WinPanelScript := preload("res://scripts/win_panel.gd")
const RoundToastScript := preload("res://scripts/round_toast.gd")
const ObstacleScript := preload("res://scripts/obstacle.gd")
const CHECKPOINT_TEX := preload("res://assets/maps/level_marker_01.png")
const GRASS_TEX := preload("res://assets/maps/summer_grass_tile.png")

# Maze cells. Entry/exit live on opposite edges; checkpoints scatter to force
# a long route across the map. Towers cannot be placed on these cells.
const ENTRY_CELL := Vector2i(0, 11)
const EXIT_CELL := Vector2i(39, 11)
const CHECKPOINT_CELLS := [
	Vector2i(35, 3),   # cp1: far right, near top
	Vector2i(4, 18),   # cp2: far left, near bottom
	Vector2i(35, 18),  # cp3: far right, near bottom
]

# Supply cap for this map — per DESIGN, "Supply" is a per-map variable. 50 is
# a high working cap for the prototype; later campaign levels will be tighter
# as part of the puzzle design.
const MAX_TOWERS := 50

# MVP bonus zones — hand-placed to give the player meaningful routing/placement
# choices. Magnitudes vary so size variety is visible: smaller magnitude = larger
# zone = less-rewarding-but-easier-to-reach; bigger magnitude = small zone =
# powerful-but-must-route-to-it.
const ZONES := [
	{"type": "damage",       "mag": 20, "cell": Vector2i(18, 5)},   # large, upper middle
	{"type": "attack_speed", "mag": 70, "cell": Vector2i(13, 12)},  # small, valuable
	{"type": "range",        "mag": 30, "cell": Vector2i(26, 16)},  # medium-large, lower right
	{"type": "slow",         "mag": 40, "cell": Vector2i(22, 9)},   # medium, on cp1→cp2 sweep
]

# Scattered environment props (test map). Each: prop texture + top-left footprint
# cell + footprint size in tiles. Placed in open areas so they add mazing detours
# without sealing the path to any checkpoint. Random generation comes later for MP.
const OBSTACLE_DIR := "res://assets/environment/props/"
const OBSTACLES := [
	{"tex": "car_reck.png",        "cell": Vector2i(10, 7),  "w": 2, "h": 2},
	{"tex": "truck_on_side.png",   "cell": Vector2i(27, 8),  "w": 2, "h": 2},
	{"tex": "car_02.png",          "cell": Vector2i(31, 13), "w": 2, "h": 2},
	{"tex": "dead_tree_01.png",    "cell": Vector2i(23, 4),  "w": 2, "h": 2},
	{"tex": "dead_tree_02.png",    "cell": Vector2i(8, 15),  "w": 1, "h": 1},
	{"tex": "rubble_pile_01.png",  "cell": Vector2i(19, 14), "w": 1, "h": 1},
	{"tex": "rubble_pile_02.png",  "cell": Vector2i(15, 17), "w": 1, "h": 1},
	{"tex": "oil_drum_fallen.png", "cell": Vector2i(33, 6),  "w": 1, "h": 1},
]

var mobs: Array = []

func _ready() -> void:
	_setup_background()
	_setup_zones()
	_setup_markers()
	var obstacle_blocked := _setup_obstacles()

	# Construct all and wire cross-references BEFORE adding to scene tree —
	# each node's _ready may depend on the others being injected.
	var spawner := SpawnerScript.new()
	spawner.mobs_array = mobs

	var ctrl := BuildControllerScript.new()
	ctrl.mobs_array = mobs
	ctrl.entry_cell = ENTRY_CELL
	ctrl.exit_cell = EXIT_CELL
	ctrl.checkpoint_cells = CHECKPOINT_CELLS
	ctrl.max_towers = MAX_TOWERS
	ctrl.blocked = obstacle_blocked  # obstacles are permanent walls from the start

	var round_manager := RoundManagerScript.new()
	round_manager.spawner = spawner
	round_manager.mobs_array = mobs
	round_manager.build_controller = ctrl

	ctrl.round_manager = round_manager

	var hud := HUDScript.new()
	hud.round_manager = round_manager
	hud.build_controller = ctrl

	var match_end := MatchEndPanelScript.new()
	match_end.round_manager = round_manager

	var win_panel := WinPanelScript.new()
	win_panel.round_manager = round_manager

	var round_toast := RoundToastScript.new()
	round_toast.round_manager = round_manager

	add_child(spawner)
	add_child(round_manager)
	add_child(ctrl)
	add_child(hud)
	add_child(match_end)
	add_child(win_panel)
	add_child(round_toast)

func _setup_background() -> void:
	var bg := TextureRect.new()
	bg.texture = GRASS_TEX
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.size = Vector2(GridScript.COLS * GridScript.TILE_SIZE, GridScript.ROWS * GridScript.TILE_SIZE)
	bg.z_index = -100
	add_child(bg)

func _setup_obstacles() -> Dictionary:
	# Spawn each prop and collect every cell it occupies into a blocked map the
	# build controller seeds its pathfinding/placement with.
	var blocked := {}
	for o in OBSTACLES:
		var tex: Texture2D = load(OBSTACLE_DIR + o.tex)
		if tex == null:
			continue
		var obs := ObstacleScript.new()
		add_child(obs)
		obs.setup(tex, o.cell, o.w, o.h)
		for cell in obs.cells:
			blocked[cell] = true
	return blocked

func _setup_zones() -> void:
	for z in ZONES:
		var zone := BonusZoneScript.new()
		zone.type = z.type
		zone.magnitude = z.mag
		zone.radius = BonusZoneScript.radius_for_magnitude(z.mag)
		zone.position = GridScript.cell_to_world(z.cell)
		add_child(zone)

func _setup_markers() -> void:
	# Entry and exit are off-screen (mobs spawn/despawn beyond the map edge),
	# so no entry/exit flags are drawn. Only checkpoint markers are shown.
	for cell in CHECKPOINT_CELLS:
		var marker := Sprite2D.new()
		marker.texture = CHECKPOINT_TEX
		marker.position = GridScript.cell_to_world(cell)
		marker.scale = Vector2(0.55, 0.55)
		marker.z_index = -40
		add_child(marker)
