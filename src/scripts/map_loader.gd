extends Node

const GridScript := preload("res://scripts/grid.gd")
const BonusZoneScript := preload("res://scripts/bonus_zone.gd")
const SpawnerScript := preload("res://scripts/spawner.gd")
const BuildControllerScript := preload("res://scripts/build_controller.gd")
const MatchCoordinatorScript := preload("res://scripts/match_coordinator.gd")
const RoundManagerScript := preload("res://scripts/round_manager.gd")
const RailScript := preload("res://scripts/rail.gd")
const BuildConfirmScript := preload("res://scripts/build_confirm.gd")
const TowerDrawerScript := preload("res://scripts/tower_drawer.gd")
const CountdownOverlayScript := preload("res://scripts/countdown_overlay.gd")
const MatchEndPanelScript := preload("res://scripts/match_end_panel.gd")
const WinPanelScript := preload("res://scripts/win_panel.gd")
const PauseMenuScript := preload("res://scripts/pause_menu.gd")
const GameViewScript := preload("res://scripts/game_view.gd")
const LeaderboardPanelScript := preload("res://scripts/leaderboard_panel.gd")

const OPPONENT_HANDLES := [
	"ShadowFox", "MazeKing", "Vortex", "NightOwl", "IronWall", "Specter",
	"BlazeUp", "Quibble", "RogueAI", "Hexed", "Tidal", "Grimlock", "Pyre", "Zenith",
]
const RoadRendererScript := preload("res://scripts/road_renderer.gd")
const GridOverlayScript := preload("res://scripts/grid_overlay.gd")
const BotControllerScript := preload("res://scripts/bot_controller.gd")
const PlaytestLogScript := preload("res://scripts/playtest_log.gd")
const ObstacleScript := preload("res://scripts/obstacle.gd")
const ZoneDefinitionScript := preload("res://resources/zone_definition.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")
const MapGeneratorScript := preload("res://scripts/map_generator.gd")
const BuildGuideScript := preload("res://scripts/build_guide.gd")
const TutorialDirectorScript := preload("res://scripts/tutorial_director.gd")
const TutorialCalloutScript := preload("res://scripts/tutorial_callout.gd")
const GhostLadderScript := preload("res://scripts/ghost_ladder.gd")

const CHECKPOINT_TEX := preload("res://assets/maps/level_marker_flag.png")
const GRASS_TEX := preload("res://assets/maps/summer_grass_tile.png")
const ObstaclePropsScript := preload("res://resources/obstacle_props.gd")

const BOARD_GAP_TILES := 6

static func load_into(host: Node2D, map) -> void:
	build_match(host, map, 1)

static func build_match(host: Node2D, map, num_boards: int = 1, local_index: int = 0, use_bots: bool = true, player_names: Array = []) -> Array:
	var coordinator := MatchCoordinatorScript.new()
	coordinator.max_rounds = map.round_count
	coordinator.is_pvp = (map.mode == MapResourceScript.Mode.PVP)
	# Trials runs until lives deplete; the authored campaign keeps its fixed round cap.
	coordinator.endless = (map.mode == MapResourceScript.Mode.PVE)
	coordinator.scale_tier = map.scale_tier
	coordinator.sim_seed = map.map_seed
	coordinator.map_ref = _map_ref_for(map)
	coordinator.record_enabled = true
	host.add_child(coordinator)

	var is_coop_relay: bool = (map.mode == MapResourceScript.Mode.PVE and num_boards > 1)
	var board_maps: Array = []
	for i in range(num_boards):
		if is_coop_relay and i > 0:
			board_maps.append(MapGeneratorScript.generate(
				map.map_seed + i, map.scale_tier, map.mode, map.window_type, map.window_date))
		else:
			board_maps.append(map)

	var boards: Array = []
	var containers: Array = []
	for i in range(num_boards):
		var container := Node2D.new()
		container.name = "Board%d" % i
		container.position = _board_offset(i, map.grid_size, local_index)
		host.add_child(container)
		containers.append(container)
		var board = _build_board(container, board_maps[i], coordinator, i == local_index, use_bots)
		board.lives = GameConstants.LIVES_PER_PLAYER if coordinator.is_pvp else GameConstants.TRIALS_LIVES
		board.relay_position = i
		boards.append(board)

	if is_coop_relay:
		coordinator.setup_shared_pools(num_boards, map.supply_cap)

	if local_index < 0:
		return boards

	_setup_surround(host)

	var local_board = boards[local_index]
	var local_ctrl = local_board.build_controller
	var local_map = board_maps[local_index]
	var ui = _build_match_ui(host, local_board, local_ctrl, local_map, _build_ghost_ladder(local_map))
	var rail = ui[0]
	var drawer = ui[1]

	var plog := PlaytestLogScript.new()
	plog.board = local_board
	plog.coordinator = coordinator
	plog.map = map
	host.add_child(plog)

	var game_view := GameViewScript.new()
	game_view.coordinator = coordinator
	game_view.board_containers = containers
	game_view.grid_size = map.grid_size
	game_view.local_index = local_index
	game_view.is_pvp = coordinator.is_pvp
	game_view.local_build_controller = local_ctrl
	game_view.tower_drawer = drawer
	local_ctrl.tower_drawer = drawer
	drawer.game_view = game_view
	host.add_child(game_view)
	rail._game_view = game_view

	if map.mode == MapResourceScript.Mode.CAMPAIGN and map.tutorial_beats != null and not map.tutorial_beats.is_empty():
		var guide = null
		if _beats_use_ghost(map.tutorial_beats):
			guide = BuildGuideScript.new()
			guide.build_controller = local_ctrl
			containers[local_index].add_child(guide)
			local_ctrl.towers_changed.connect(guide._on_towers_changed)
		var callout = TutorialCalloutScript.new()
		host.add_child(callout)
		var director = TutorialDirectorScript.new()
		director.coordinator = coordinator
		director.board = local_board
		director.build_controller = local_ctrl
		director.callout = callout
		director.guide = guide
		director.setup(map.tutorial_beats)
		host.add_child(director)

	if num_boards > 1:
		var names: Array = []
		names.resize(num_boards)
		for i in range(num_boards):
			if i < player_names.size() and player_names[i] != "":
				names[i] = player_names[i]
			elif i == local_index:
				names[i] = "You"
			else:
				names[i] = OPPONENT_HANDLES[(i * 5) % OPPONENT_HANDLES.size()]
		coordinator.board_names = names
		game_view.board_names = names

		var leaderboard := LeaderboardPanelScript.new()
		leaderboard.coordinator = coordinator
		leaderboard.boards = boards
		leaderboard.local_index = local_index
		leaderboard.grid_size = map.grid_size
		leaderboard.arena = game_view
		host.add_child(leaderboard)
		rail.minimap = leaderboard
		game_view.minimap = leaderboard
		local_ctrl.minimap = leaderboard

	return boards

static func _beats_use_ghost(beats: Array) -> bool:
	for b in beats:
		if b.ghost_cells != null and not b.ghost_cells.is_empty():
			return true
	return false

static func _map_ref_for(map) -> Dictionary:
	if map.mode == MapResourceScript.Mode.CAMPAIGN:
		return {"kind": "authored", "mission_index": map.mission_index, "tres_version": 1}
	return {
		"kind": "generated",
		"seed": map.map_seed,
		"scale_tier": map.scale_tier,
		"mode": int(map.mode),
		"window_type": int(map.window_type),
		"window_date": map.window_date,
	}

static func _board_offset(index: int, grid_size: Vector2i, local_index: int = 0) -> Vector2:
	if index == local_index:
		return Vector2.ZERO
	var slot := index + 1 if index < local_index else index
	var stride := (grid_size.x + BOARD_GAP_TILES) * GridScript.TILE_SIZE
	return Vector2(slot * stride, 0.0)

static func _build_board(container: Node2D, map, coordinator, is_local: bool, use_bots: bool = true):
	var board_tex: Texture2D = GRASS_TEX
	var tower_skin: Texture2D = null
	var proj_tint := Color.WHITE
	var fx_id := ""
	var board_id := ""
	if is_local:
		board_id = SaveData.equipped_cosmetic("board")
		board_tex = CosmeticsCatalog.texture_for(
			board_id, "res://assets/maps/summer_grass_tile.png")
		var tw := SaveData.equipped_cosmetic("tower")
		if tw != "" and tw != "tower_arrow":
			tower_skin = CosmeticsCatalog.texture_for(tw, "res://assets/towers/arrow_box_loaded.png")
		proj_tint = CosmeticsCatalog.tint_for(SaveData.equipped_cosmetic("proj"), Color.WHITE)
		fx_id = SaveData.equipped_cosmetic("proj")
	var aura_ramp := CosmeticsCatalog.aura_ramp_for(board_id)
	_setup_background(container, map.grid_size, board_tex)

	var road := RoadRendererScript.new()
	container.add_child(road)
	road.configure(float(GridScript.TILE_SIZE))
	road.z_index = -50

	var zones := _setup_zones(container, map.bonus_zones)
	_setup_markers(container, map.checkpoint_cells)
	var obstacle_blocked := _setup_obstacles(container, map, board_id)

	var mobs: Array = []

	var spawner := SpawnerScript.new()
	spawner.mobs_array = mobs

	var ctrl := BuildControllerScript.new()
	ctrl.interactive = is_local
	ctrl.tower_skin_tex = tower_skin
	ctrl.proj_tint = proj_tint
	ctrl.fx_id = fx_id
	ctrl.aura_ramp = aura_ramp
	ctrl.mobs_array = mobs
	ctrl.entry_cell = map.entry_cell
	ctrl.exit_cell = map.exit_cell
	ctrl.checkpoint_cells = map.checkpoint_cells
	ctrl.max_towers = map.supply_cap
	ctrl.grid_size = map.grid_size
	ctrl.blocked = obstacle_blocked

	var board := RoundManagerScript.new()
	board.coordinator = coordinator
	board.spawner = spawner
	board.mobs_array = mobs
	board.build_controller = ctrl
	board.bonus_zones = zones
	board.mob_count = map.mob_count
	board.star1_threshold = map.star1_threshold
	board.star2_threshold = map.star2_threshold
	board.star3_threshold = map.star3_threshold

	spawner.board = board
	ctrl.round_manager = board
	ctrl.road_renderer = road
	coordinator.register_board(board)

	container.add_child(spawner)
	container.add_child(board)
	container.add_child(ctrl)

	if not is_local and use_bots:
		var bot := BotControllerScript.new()
		bot.board = board
		bot.ctrl = ctrl
		bot.coordinator = coordinator
		container.add_child(bot)

	return board

static func _build_match_ui(host: Node2D, local_board, local_ctrl, map, ghost_ladder) -> Array:
	var mode: int = int(map.mode)
	var rail := RailScript.new()
	rail.round_manager = local_board
	rail.build_controller = local_ctrl
	rail.ghost_ladder = ghost_ladder

	var drawer := TowerDrawerScript.new()
	drawer.round_manager = local_board
	drawer.build_controller = local_ctrl
	drawer.rail = rail

	var match_end := MatchEndPanelScript.new()
	match_end.round_manager = local_board
	if mode == MapResourceScript.Mode.PVE:
		match_end.lb_ctx = {"window": int(map.window_type), "tier": int(map.scale_tier), "group": "solo"}
	match_end.ranked = (mode == MapResourceScript.Mode.PVP and SceneManager.transport != null)

	var pause_menu := PauseMenuScript.new()
	pause_menu.build_controller = local_ctrl
	pause_menu.round_manager = local_board
	rail.pause_menu = pause_menu

	host.add_child(rail)
	host.add_child(drawer)
	if DisplayServer.is_touchscreen_available():
		var build_confirm := BuildConfirmScript.new()
		build_confirm.build_controller = local_ctrl
		host.add_child(build_confirm)
	host.add_child(match_end)
	if mode == MapResourceScript.Mode.CAMPAIGN:
		var win_panel := WinPanelScript.new()
		win_panel.round_manager = local_board
		host.add_child(win_panel)
	host.add_child(pause_menu)
	var countdown := CountdownOverlayScript.new()
	countdown.round_manager = local_board
	host.add_child(countdown)
	return [rail, drawer]

static func _build_ghost_ladder(map):
	if map.mode != MapResourceScript.Mode.PVE:
		return null
	var ladder = GhostLadderScript.new()
	var best := LeaderboardService.round_part(SaveData.best_pve_score(map.window_date, map.scale_tier))
	ladder.setup(int(map.star1_threshold), int(map.star2_threshold), int(map.star3_threshold),
		GhostLadderScript.fetch_snapshot(map), best)
	return ladder

const BOARD_BORDER := 6
static func _setup_background(parent: Node2D, grid_size: Vector2i, board_tex: Texture2D = GRASS_TEX) -> void:
	var tile := GridScript.TILE_SIZE
	var board := Vector2(grid_size.x * tile, grid_size.y * tile)

	var edge := ColorRect.new()
	edge.color = Color("3c6e26")
	edge.position = Vector2(-BOARD_BORDER, -BOARD_BORDER)
	edge.size = board + Vector2(BOARD_BORDER * 2, BOARD_BORDER * 2)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.z_index = -101
	parent.add_child(edge)

	var grass := TextureRect.new()
	grass.texture = board_tex
	grass.stretch_mode = TextureRect.STRETCH_TILE
	grass.size = board
	grass.position = Vector2.ZERO
	grass.modulate = Color(0.88, 0.97, 0.74)
	grass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grass.z_index = -100
	parent.add_child(grass)

	var grid := GridOverlayScript.new()
	grid.cols = grid_size.x
	grid.rows = grid_size.y
	grid.cell = float(tile)
	grid.z_index = -90
	parent.add_child(grid)

static func _setup_surround(host: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = -100
	host.add_child(layer)
	var bg := TextureRect.new()
	bg.texture = _surround_tex()
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)

static func _surround_tex() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color("26301a"), Color("1d2614")])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.42)
	t.fill_to = Vector2(1.05, 1.05)
	t.width = 256
	t.height = 256
	return t

static func _setup_obstacles(parent: Node2D, map, board_id: String) -> Dictionary:
	var blocked := {}
	var defs: Array = map.obstacles if map.obstacles != null else []
	if defs.is_empty() and not map.obstacle_cells.is_empty():
		for cell in map.obstacle_cells:
			_spawn_obstacle(parent, board_id, "", cell, Vector2i.ONE, blocked)
	else:
		for d in defs:
			_spawn_obstacle(parent, board_id, d.prop_id, d.origin, d.footprint, blocked)
	return blocked

static func _spawn_obstacle(parent: Node2D, board_id: String, prop_id: String, origin: Vector2i, footprint: Vector2i, blocked: Dictionary) -> void:
	var tex: Texture2D
	var overhang: float
	if prop_id != "":
		tex = ObstaclePropsScript.tex_for(prop_id)
		overhang = ObstaclePropsScript.overhang_for(prop_id)
	else:
		var art := ObstaclePropsScript.art_for(board_id, footprint, _cell_art_key(origin))
		tex = art["tex"]
		overhang = art["overhang"]
	var obs := ObstacleScript.new()
	parent.add_child(obs)
	obs.setup(tex, origin, footprint, overhang)
	for c in obs.cells:
		blocked[c] = true

static func _cell_art_key(cell: Vector2i) -> int:
	return absi(cell.x * 73856093 ^ cell.y * 19349663)

static func _setup_zones(parent: Node2D, zone_defs: Array) -> Array:
	var zones: Array = []
	for z in zone_defs:
		var zone := BonusZoneScript.new()
		zone.type = z.type_name()
		zone.magnitude = z.magnitude
		zone.radius = BonusZoneScript.radius_for_magnitude(z.magnitude)
		zone.position = GridScript.cell_to_world(z.cell)
		parent.add_child(zone)
		zones.append(zone)
	return zones

static func _setup_markers(parent: Node2D, checkpoint_cells: Array) -> void:
	var flag_h := CHECKPOINT_TEX.get_height() * 0.42
	for i in range(checkpoint_cells.size()):
		var cell = checkpoint_cells[i]
		var base := GridScript.cell_to_world(cell)
		var marker := Sprite2D.new()
		marker.texture = CHECKPOINT_TEX
		marker.position = base
		marker.scale = Vector2(0.42, 0.42)
		marker.offset = Vector2(0, -CHECKPOINT_TEX.get_height() * 0.5)
		marker.z_index = 3
		parent.add_child(marker)

		var banner_cy := 0.50 * flag_h
		var box := 26.0
		var num := Label.new()
		num.text = str(i + 1)
		num.add_theme_font_size_override("font_size", 15)
		num.add_theme_color_override("font_color", Color.WHITE)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.custom_minimum_size = Vector2(box, box)
		num.z_index = 4
		num.position = base + Vector2(-box * 0.5, -banner_cy - box * 0.5)
		parent.add_child(num)
