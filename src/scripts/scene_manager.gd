extends Node

const MapResourceScript := preload("res://resources/map_resource.gd")
const MapGeneratorScript := preload("res://scripts/map_generator.gd")
const ResimScript := preload("res://scripts/resim.gd")
const RESIM_TICKS_PER_FRAME := 256
const EnetTransportScript := preload("res://net/enet_transport.gd")
const NetProtocolScript := preload("res://net/net_protocol.gd")
const MatchServerScript := preload("res://net/match_server.gd")
const Motion := preload("res://scripts/motion.gd")
const CosmeticsCatalogScript := preload("res://scripts/cosmetics_catalog.gd")

const PVP_BOARD_COUNT := 8

const HOME_SCENE := "res://scenes/home_screen.tscn"
const CAMPAIGN_SELECT_SCENE := "res://scenes/campaign_select.tscn"
const PVE_SELECT_SCENE := "res://scenes/pve_select.tscn"
const LOBBY_SCENE := "res://scenes/lobby.tscn"
const LEADERBOARD_SCENE := "res://scenes/leaderboard_browse.tscn"
const COLLECTION_SCENE := "res://scenes/collection.tscn"
const SEASON_SCENE := "res://scenes/season.tscn"
const MATCH_SCENE := "res://scenes/prototype.tscn"

var transport = null
var is_dedicated_server := false
var last_player_name := "Player"
var pending_local_index := 0
var pending_player_names: Array = []
var pending_seat_by_peer: Dictionary = {}
var pending_ranked_avg_mmr := 150.0
var pending_is_ranked := false
var last_task_award: Dictionary = {}

const CAMPAIGN_MISSIONS := {
	1: "res://campaign/mission_01.tres",
	2: "res://campaign/mission_02.tres",
	3: "res://campaign/mission_03.tres",
	4: "res://campaign/mission_04.tres",
	5: "res://campaign/mission_05.tres",
}
const CAMPAIGN_MISSION_COUNT := 5

var active_coordinator = null

var pending_leaderboard := {}

var pending_map = null
var pending_board_count := 1
var current_is_multiplayer := false

func goto_home() -> void:
	pending_map = null
	pending_board_count = 1
	current_is_multiplayer = false
	pending_is_ranked = false
	active_coordinator = null
	get_tree().paused = false
	Engine.time_scale = 1.0
	_menu_change(HOME_SCENE, true)

func goto_campaign_select() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_menu_change(CAMPAIGN_SELECT_SCENE)

func goto_pve_select() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_menu_change(PVE_SELECT_SCENE)

func goto_collection() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_menu_change(COLLECTION_SCENE)

func goto_season() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_menu_change(SEASON_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		for it in CosmeticsCatalogScript.ITEMS:
			SaveData.grant_cosmetic(it["id"])
		print("[DEV] F10 — unlocked all %d cosmetics" % CosmeticsCatalogScript.ITEMS.size())
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("dev_refresh"):
			scene.dev_refresh()

var _transition_layer: CanvasLayer = null
var _did_first_nav := false

func _menu_change(path: String, back := false) -> void:
	if not _did_first_nav:
		_did_first_nav = true
		get_tree().change_scene_to_file(path)
		return
	var vp_size := get_viewport().get_visible_rect().size
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		get_tree().change_scene_to_file(path)
		return
	var cover := TextureRect.new()
	cover.texture = ImageTexture.create_from_image(img)
	cover.size = vp_size
	cover.position = Vector2.ZERO
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	if _transition_layer == null:
		_transition_layer = CanvasLayer.new()
		_transition_layer.layer = 128
		add_child(_transition_layer)
	_transition_layer.add_child(cover)
	get_tree().change_scene_to_file(path)
	_slide_cover_off.call_deferred(cover, back, vp_size.x)

func _slide_cover_off(cover: TextureRect, back: bool, w: float) -> void:
	if not is_instance_valid(cover):
		return
	var t := cover.create_tween()
	t.set_parallel(true)
	Motion.leave(t)
	t.tween_property(cover, "position:x", (w if back else -w), Motion.dur(Motion.SCREEN))
	t.tween_property(cover, "modulate:a", 0.0, Motion.dur(Motion.SCREEN))
	t.chain().tween_callback(cover.queue_free)
	get_tree().create_timer(1.0).timeout.connect(func(): if is_instance_valid(cover): cover.queue_free())

func goto_leaderboards(ctx := {}) -> void:
	pending_leaderboard = ctx
	get_tree().paused = false
	Engine.time_scale = 1.0
	_menu_change(LEADERBOARD_SCENE)

func start_pve_map(map) -> void:
	pending_map = map
	pending_board_count = 1
	current_is_multiplayer = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MATCH_SCENE)

func start_pvp() -> void:
	var match_seed := int(Time.get_unix_time_from_system())
	var tier := (match_seed % 5) + 1
	pending_map = MapGeneratorScript.generate(match_seed, tier, MapResourceScript.Mode.PVP)
	pending_board_count = PVP_BOARD_COUNT
	current_is_multiplayer = true
	get_tree().paused = false
	get_tree().change_scene_to_file(MATCH_SCENE)

func goto_lobby() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_menu_change(LOBBY_SCENE)

func _make_transport():
	net_close()
	transport = EnetTransportScript.new()
	transport.name = "Transport"
	add_child(transport)
	return transport

func net_host() -> int:
	_make_transport()
	return transport.start_host(NetProtocolScript.DEFAULT_PORT)

func net_join(address: String) -> int:
	_make_transport()
	return transport.start_join(address, NetProtocolScript.DEFAULT_PORT)

func net_close() -> void:
	if transport != null:
		transport.close()
		transport.queue_free()
		transport = null

func start_dedicated_server() -> int:
	var err := net_host()
	if err != OK:
		push_error("dedicated server: could not host (error %d)" % err)
		return err
	is_dedicated_server = true
	var server := MatchServerScript.new()
	server.name = "MatchServer"
	add_child(server)
	return OK

func start_networked_pvp(map_seed: int, tier: int, board_count: int, seat: int, names: Array, seat_by_peer: Dictionary = {}) -> void:
	pending_map = MapGeneratorScript.generate(map_seed, tier, MapResourceScript.Mode.PVP)
	pending_board_count = board_count
	pending_local_index = seat
	pending_player_names = names
	pending_seat_by_peer = seat_by_peer
	current_is_multiplayer = true
	get_tree().paused = false
	get_tree().change_scene_to_file(MATCH_SCENE)

func has_campaign_mission(index: int) -> bool:
	return CAMPAIGN_MISSIONS.has(index)

func start_campaign_mission(index: int) -> void:
	if not CAMPAIGN_MISSIONS.has(index):
		push_warning("SceneManager: campaign mission %d is not authored" % index)
		return
	pending_map = load(CAMPAIGN_MISSIONS[index])
	pending_board_count = 1
	current_is_multiplayer = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MATCH_SCENE)

func restart_current_match() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func report_match_result(advisory_damage: int) -> void:
	var snap := _snapshot_match_result(advisory_damage)
	if not snap.is_empty():
		await _finish_match_result(snap)

func _snapshot_match_result(advisory_damage: int) -> Dictionary:
	if pending_map == null:
		return {}
	var snap := {
		"advisory": advisory_damage,
		"advisory_round": _final_round(),
		"mode": pending_map.mode,
		"mission_index": pending_map.mission_index,
		"window_date": pending_map.window_date,
		"window_type": pending_map.window_type,
		"scale_tier": pending_map.scale_tier,
		"star3": pending_map.star3_threshold,
		"star2": pending_map.star2_threshold,
		"star1": pending_map.star1_threshold,
		"record": {},
		"task": {},
	}
	var coord = active_coordinator
	if coord != null and is_instance_valid(coord) and coord.record_enabled:
		if not coord.match_over:
			coord.record_end_marker()
		snap["record"] = coord.make_record()
	var board = _local_board()
	if board != null and is_instance_valid(board):
		var towers := 0
		var zones := 0
		if board.build_controller != null and is_instance_valid(board.build_controller):
			towers = board.build_controller.towers.size()
			zones = _zones_occupied(board)
		snap["task"] = {"towers": towers, "zones": zones, "kills": board.total_kills}
	return snap

func _finish_match_result(snap: Dictionary) -> void:
	var record: Dictionary = snap["record"]
	var result := await _authoritative_score(record, int(snap["advisory"]), int(snap["advisory_round"]))
	if not bool(result["legal"]):
		push_warning("Match record failed legality check (%s) — no score recorded." % str(result.get("reason", "")))
		return
	var damage: int = int(result["score"])
	var rounds: int = int(result["rounds"])
	var record_b64 := ""
	if not record.is_empty():
		record_b64 = Marshalls.raw_to_base64(ResimScript.encode_record(record))
	if snap["mode"] == MapResourceScript.Mode.CAMPAIGN and int(snap["mission_index"]) > 0:
		SaveData.record_campaign_stars(int(snap["mission_index"]), _star_for(damage, snap))
		_post_online("campaign", "campaign_m%02d" % int(snap["mission_index"]), damage, record_b64)
	elif snap["mode"] == MapResourceScript.Mode.PVE:
		var composite := LeaderboardService.encode_score(rounds, damage)
		SaveData.record_pve_score(snap["window_date"], snap["scale_tier"], composite)
		_post_online("trials", LeaderboardService.trials_board_id(
			snap["window_type"], snap["scale_tier"], "solo"), composite, record_b64)
		var t: Dictionary = snap["task"]
		if not t.is_empty():
			_award_tasks({"towers": t["towers"], "zones": t["zones"], "kills": t["kills"], "score": damage})

func report_ranked_result(value_after: int) -> void:
	_post_online("ranked", "ranked_s%d" % SaveData.ranked_season(), value_after)
	var b = _local_board()
	if b != null:
		_record_match_tasks(b, b.total_damage_dealt)

func _local_board():
	if active_coordinator != null and is_instance_valid(active_coordinator) \
			and not active_coordinator.boards.is_empty():
		return active_coordinator.boards[0]
	return null

func _final_round() -> int:
	if active_coordinator != null and is_instance_valid(active_coordinator):
		return int(active_coordinator.round_num)
	return 1

func _record_match_tasks(board, score: int) -> void:
	if board == null or not is_instance_valid(board):
		return
	var towers := 0
	var zones := 0
	if board.build_controller != null and is_instance_valid(board.build_controller):
		towers = board.build_controller.towers.size()
		zones = _zones_occupied(board)
	_award_tasks({"towers": towers, "zones": zones, "kills": board.total_kills, "score": score})

func _award_tasks(stats: Dictionary) -> void:
	last_task_award = TaskCatalog.record_match(stats)

func _zones_occupied(board) -> int:
	var count := 0
	for zone in board.bonus_zones:
		for tower in board.build_controller.towers:
			if zone.touches_tower_cell(tower.grid_cell):
				count += 1
				break
	return count

func _post_online(kind: String, board_id: String, score: int, record_b64 := "") -> void:
	var be = LeaderboardService.backend()
	if be == null or not be.has_method("submit"):
		return
	if record_b64 == "":
		var coord = active_coordinator
		if coord != null and is_instance_valid(coord) and coord.record_enabled:
			var bytes: PackedByteArray = ResimScript.encode_record(coord.make_record())
			record_b64 = Marshalls.raw_to_base64(bytes)
	await be.submit(kind, board_id, score, record_b64)

func _authoritative_score(record: Dictionary, advisory: int, advisory_round: int) -> Dictionary:
	if record.is_empty():
		return {"score": advisory, "rounds": advisory_round, "legal": true, "reason": ""}
	var host := Node2D.new()
	add_child(host)
	var res: Dictionary = await ResimScript.run(host, record, RESIM_TICKS_PER_FRAME)
	host.queue_free()
	if not bool(res.get("legal", true)):
		return {"score": 0, "rounds": 0, "legal": false, "reason": str(res.get("illegal", ""))}
	var rounds := int(res.get("final_round", advisory_round))
	var rboards: Array = res.get("boards", [])
	if rboards.is_empty():
		return {"score": advisory, "rounds": rounds, "legal": true, "reason": ""}
	var score := int(rboards[0]["damage"])
	if score != advisory:
		push_warning("Re-sim score %d differs from live %d — determinism check (recording re-sim)." % [score, advisory])
	return {"score": score, "rounds": rounds, "legal": true, "reason": ""}

func _star_for(damage: int, snap: Dictionary) -> int:
	if damage >= int(snap["star3"]):
		return 3
	if damage >= int(snap["star2"]):
		return 2
	if damage >= int(snap["star1"]):
		return 1
	return 0

func leave_match_to_home(damage: int) -> void:
	var snap := _snapshot_match_result(damage)
	goto_home()
	if not snap.is_empty():
		_finish_match_result(snap)
