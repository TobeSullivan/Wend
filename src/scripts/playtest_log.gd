extends Node
class_name PlaytestLog

const ENABLED := false
const PATH := "user://playtest_log.jsonl"

var board
var coordinator
var map

func _ready() -> void:
	if not ENABLED:
		return
	if board != null:
		board.round_summary.connect(_on_round_summary)
	if coordinator != null:
		coordinator.match_ended.connect(_on_match_ended)

func _on_round_summary(round_completed: int, kill_gold: int, round_bonus: int, interest: int) -> void:
	_append({
		"ev": "round",
		"t": Time.get_datetime_string_from_system(),
		"mode": map.mode,
		"mission": map.mission_index,
		"seed": map.map_seed,
		"round": round_completed,
		"cum_damage": board.total_damage_dealt,
		"cum_kills": board.total_kills,
		"round_kill_gold": kill_gold,
		"round_bonus": round_bonus,
		"interest": interest,
		"gold": board.gold,
		"towers": board.build_controller.towers.size(),
	})

func _on_match_ended() -> void:
	var placement := 0
	if coordinator != null and coordinator.is_pvp:
		placement = coordinator.placement_of(board)
	_append({
		"ev": "match",
		"t": Time.get_datetime_string_from_system(),
		"mode": map.mode,
		"mission": map.mission_index,
		"mission_name": map.mission_name,
		"seed": map.map_seed,
		"scale_tier": map.scale_tier,
		"window_date": map.window_date,
		"supply_cap": map.supply_cap,
		"rounds_played": coordinator.round_num if coordinator != null else 0,
		"max_rounds": map.round_count,
		"final_damage": board.total_damage_dealt,
		"final_kills": board.total_kills,
		"stars": board.star_rating(board.star_metric()),
		"star1": map.star1_threshold,
		"star2": map.star2_threshold,
		"star3": map.star3_threshold,
		"placement": placement,
	})

func _append(d: Dictionary) -> void:
	var f: FileAccess
	if FileAccess.file_exists(PATH):
		f = FileAccess.open(PATH, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("PlaytestLog: could not open %s" % PATH)
		return
	f.store_line(JSON.stringify(d))
	f.close()
