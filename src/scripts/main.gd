extends Node2D

# Match host. Owns nothing about map configuration — it picks a MapResource and
# hands it to the loader, which builds the scene. Campaign passes a .tres; PVE/PVP
# will pass a generated MapResource once mode select / matchmaking is wired up.
# For now we boot straight into the first campaign mission.

const MapLoader := preload("res://scripts/map_loader.gd")
const MISSION_01 := preload("res://campaign/mission_01.tres")

# Shared mob list, read by the loader and injected into spawner/towers/round_manager.
var mobs: Array = []

func _ready() -> void:
	# SceneManager picks the map (campaign mission, or generated PVE/PVP later).
	# Falls back to mission 1 so opening prototype.tscn directly in the editor works.
	var map = SceneManager.pending_map
	if map == null:
		map = MISSION_01
	# Apply the player's default game speed for the match (menus reset to 1× via
	# SceneManager). Engine.time_scale scales mobs, towers, and the build timer.
	Engine.time_scale = float(SaveData.get_setting("default_game_speed"))
	MapLoader.build_match(self, map, SceneManager.pending_board_count)
