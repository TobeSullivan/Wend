extends Node2D

const MapLoader := preload("res://scripts/map_loader.gd")
const MISSION_01 := preload("res://campaign/mission_01.tres")
const NetMatchScript := preload("res://net/net_match.gd")

var mobs: Array = []

func _ready() -> void:
	var map = SceneManager.pending_map
	if map == null:
		map = MISSION_01
	Engine.time_scale = float(SaveData.get_setting("default_game_speed"))
	if SceneManager.current_is_multiplayer and SceneManager.transport != null:
		var boards := MapLoader.build_match(self, map, SceneManager.pending_board_count, SceneManager.pending_local_index, false, SceneManager.pending_player_names)
		SceneManager.active_coordinator = boards[0].coordinator
		var nm := NetMatchScript.new()
		nm.name = "NetMatch"
		add_child(nm)
		nm.setup(SceneManager.transport, boards[0].coordinator, boards, SceneManager.pending_local_index, SceneManager.pending_seat_by_peer)
	else:
		var boards := MapLoader.build_match(self, map, SceneManager.pending_board_count)
		SceneManager.active_coordinator = boards[0].coordinator
