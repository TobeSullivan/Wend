extends Node

# Reads a MapResource and builds the live match scene under `host`. This is the
# single configuration path: campaign passes a hand-authored .tres, PVE/PVP pass
# a generated MapResource in memory, and the loader treats them identically.
#
# The map argument is left untyped on purpose (duck-typed field access) to avoid
# the typed cross-script reference pitfalls noted in the project memory.

const GridScript := preload("res://scripts/grid.gd")
const BonusZoneScript := preload("res://scripts/bonus_zone.gd")
const SpawnerScript := preload("res://scripts/spawner.gd")
const BuildControllerScript := preload("res://scripts/build_controller.gd")
const RoundManagerScript := preload("res://scripts/round_manager.gd")
const HUDScript := preload("res://scripts/hud.gd")
const MatchEndPanelScript := preload("res://scripts/match_end_panel.gd")
const WinPanelScript := preload("res://scripts/win_panel.gd")
const RoundToastScript := preload("res://scripts/round_toast.gd")
const PauseMenuScript := preload("res://scripts/pause_menu.gd")
const ObstacleScript := preload("res://scripts/obstacle.gd")
const ZoneDefinitionScript := preload("res://resources/zone_definition.gd")

const CHECKPOINT_TEX := preload("res://assets/maps/level_marker_01.png")
const GRASS_TEX := preload("res://assets/maps/summer_grass_tile.png")
# The schema stores obstacles as bare cells (no texture/footprint), so every
# obstacle cell renders with this single debris prop.
const OBSTACLE_TEX := preload("res://assets/environment/props/rubble_pile_01.png")

# Builds the full match into `host` from `map`. Returns nothing; everything is
# parented under host.
static func load_into(host: Node2D, map) -> void:
	_setup_background(host, map.grid_size)
	_setup_zones(host, map.bonus_zones)
	_setup_markers(host, map.checkpoint_cells)
	var obstacle_blocked := _setup_obstacles(host, map.obstacle_cells)

	# Construct all and wire cross-references BEFORE adding to the scene tree —
	# each node's _ready may depend on the others being injected.
	var spawner := SpawnerScript.new()
	spawner.mobs_array = host.mobs

	var ctrl := BuildControllerScript.new()
	ctrl.mobs_array = host.mobs
	ctrl.entry_cell = map.entry_cell
	ctrl.exit_cell = map.exit_cell
	ctrl.checkpoint_cells = map.checkpoint_cells
	ctrl.max_towers = map.supply_cap
	ctrl.grid_size = map.grid_size
	ctrl.blocked = obstacle_blocked  # obstacles are permanent walls from the start

	var round_manager := RoundManagerScript.new()
	round_manager.spawner = spawner
	round_manager.mobs_array = host.mobs
	round_manager.build_controller = ctrl
	round_manager.max_rounds = map.round_count
	round_manager.mob_count = map.mob_count
	round_manager.bronze_threshold = map.bronze_threshold
	round_manager.silver_threshold = map.silver_threshold
	round_manager.gold_threshold = map.gold_threshold

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

	var pause_menu := PauseMenuScript.new()
	pause_menu.build_controller = ctrl
	pause_menu.round_manager = round_manager

	host.add_child(spawner)
	host.add_child(round_manager)
	host.add_child(ctrl)
	host.add_child(hud)
	host.add_child(match_end)
	host.add_child(win_panel)
	host.add_child(round_toast)
	host.add_child(pause_menu)

static func _setup_background(host: Node2D, grid_size: Vector2i) -> void:
	var bg := TextureRect.new()
	bg.texture = GRASS_TEX
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.size = Vector2(grid_size.x * GridScript.TILE_SIZE, grid_size.y * GridScript.TILE_SIZE)
	bg.z_index = -100
	host.add_child(bg)

static func _setup_obstacles(host: Node2D, obstacle_cells: Array) -> Dictionary:
	# Each obstacle cell becomes a permanent wall (seeds the build controller's
	# pathfinding/placement map) and renders a single-tile debris prop.
	var blocked := {}
	for cell in obstacle_cells:
		var obs := ObstacleScript.new()
		host.add_child(obs)
		obs.setup(OBSTACLE_TEX, cell, 1, 1)
		for c in obs.cells:
			blocked[c] = true
	return blocked

static func _setup_zones(host: Node2D, zone_defs: Array) -> void:
	for z in zone_defs:
		var zone := BonusZoneScript.new()
		zone.type = z.type_name()
		zone.magnitude = z.magnitude
		zone.radius = BonusZoneScript.radius_for_magnitude(z.magnitude)
		zone.position = GridScript.cell_to_world(z.cell)
		host.add_child(zone)

static func _setup_markers(host: Node2D, checkpoint_cells: Array) -> void:
	# Entry and exit are off-screen (mobs spawn/despawn beyond the map edge), so
	# only checkpoint markers are drawn.
	for cell in checkpoint_cells:
		var marker := Sprite2D.new()
		marker.texture = CHECKPOINT_TEX
		marker.position = GridScript.cell_to_world(cell)
		marker.scale = Vector2(0.55, 0.55)
		marker.z_index = -40
		host.add_child(marker)
