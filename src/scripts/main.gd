extends Node2D

const GridScript := preload("res://scripts/grid.gd")
const BonusZoneScript := preload("res://scripts/bonus_zone.gd")
const SpawnerScript := preload("res://scripts/spawner.gd")
const BuildControllerScript := preload("res://scripts/build_controller.gd")
const RoundManagerScript := preload("res://scripts/round_manager.gd")
const HUDScript := preload("res://scripts/hud.gd")
const MatchEndPanelScript := preload("res://scripts/match_end_panel.gd")
const CHECKPOINT_TEX := preload("res://assets/maps/level_marker_01.png")
const FLAG_TEX := preload("res://assets/maps/level_marker_flag.png")
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

var mobs: Array = []

func _ready() -> void:
	_setup_background()
	_setup_zones()
	_setup_markers()

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

	add_child(spawner)
	add_child(round_manager)
	add_child(ctrl)
	add_child(hud)
	add_child(match_end)

func _setup_background() -> void:
	var bg := TextureRect.new()
	bg.texture = GRASS_TEX
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.size = Vector2(GridScript.COLS * GridScript.TILE_SIZE, GridScript.ROWS * GridScript.TILE_SIZE)
	bg.z_index = -100
	add_child(bg)

func _setup_zones() -> void:
	for z in ZONES:
		var zone := BonusZoneScript.new()
		zone.type = z.type
		zone.magnitude = z.mag
		zone.radius = BonusZoneScript.radius_for_magnitude(z.mag)
		zone.position = GridScript.cell_to_world(z.cell)
		add_child(zone)

func _setup_markers() -> void:
	# Entry flag (green-tinted), exit flag (red), checkpoint buttons.
	var entry := Sprite2D.new()
	entry.texture = FLAG_TEX
	entry.modulate = Color(0.4, 1.0, 0.4)
	entry.position = GridScript.cell_to_world(ENTRY_CELL)
	entry.scale = Vector2(0.45, 0.45)
	entry.z_index = -40
	add_child(entry)

	var exit := Sprite2D.new()
	exit.texture = FLAG_TEX
	exit.modulate = Color(1.0, 0.5, 0.5)
	exit.position = GridScript.cell_to_world(EXIT_CELL)
	exit.scale = Vector2(0.45, 0.45)
	exit.z_index = -40
	add_child(exit)

	for cell in CHECKPOINT_CELLS:
		var marker := Sprite2D.new()
		marker.texture = CHECKPOINT_TEX
		marker.position = GridScript.cell_to_world(cell)
		marker.scale = Vector2(0.55, 0.55)
		marker.z_index = -40
		add_child(marker)
