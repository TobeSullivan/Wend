extends Node

# SceneManager autoload — owns navigation between screens and carries the chosen
# MapResource into the match scene. The match scene reads `pending_map` in its
# _ready; the loader does the rest. All in-match exits route back to the home
# screen through here (DESIGN_MODES: "no intermediate screen between any in-match
# exit and the home screen").

const MapResourceScript := preload("res://resources/map_resource.gd")

const HOME_SCENE := "res://scenes/home_screen.tscn"
const CAMPAIGN_SELECT_SCENE := "res://scenes/campaign_select.tscn"
const MATCH_SCENE := "res://scenes/prototype.tscn"

# Authored campaign missions, by mission index. Missions 2–10 are not authored
# yet (campaign is the tutorial — content is deliberately minimal for now).
const CAMPAIGN_MISSIONS := {
	1: "res://campaign/mission_01.tres",
}
const CAMPAIGN_MISSION_COUNT := 10  # design cap; only authored entries are playable

# Set before a scene change; consumed by the match scene.
var pending_map = null
# Drives the pause-menu variant (single-player pauses the tree; multiplayer does
# not). Campaign and solo PVE are single-player.
var current_is_multiplayer := false

func goto_home() -> void:
	pending_map = null
	get_tree().paused = false
	Engine.time_scale = 1.0  # menus always run at normal speed
	get_tree().change_scene_to_file(HOME_SCENE)

func goto_campaign_select() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(CAMPAIGN_SELECT_SCENE)

func has_campaign_mission(index: int) -> bool:
	return CAMPAIGN_MISSIONS.has(index)

func start_campaign_mission(index: int) -> void:
	if not CAMPAIGN_MISSIONS.has(index):
		push_warning("SceneManager: campaign mission %d is not authored" % index)
		return
	pending_map = load(CAMPAIGN_MISSIONS[index])
	current_is_multiplayer = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MATCH_SCENE)

func restart_current_match() -> void:
	# pending_map is still set; reloading the match scene re-runs the loader on it.
	get_tree().paused = false
	get_tree().reload_current_scene()

# Called by the match-end panel when a campaign match finishes, so the medal is
# persisted for the mission list.
func report_match_result(damage: int, medal: String) -> void:
	if pending_map == null:
		return
	if pending_map.mode == MapResourceScript.Mode.CAMPAIGN and pending_map.mission_index > 0:
		SaveData.record_campaign_medal(pending_map.mission_index, medal)
