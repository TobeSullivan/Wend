extends Node

const MapLoaderScript := preload("res://scripts/map_loader.gd")
const MapGen := preload("res://scripts/map_generator.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")

static func run(host: Node2D, record: Dictionary, ticks_per_frame: int = 0) -> Dictionary:
	var map = _rebuild_map(record["map_ref"])
	var num_boards: int = int(record.get("players", 1))
	var boards: Array = MapLoaderScript.build_match(host, map, num_boards, -1, false)
	var coord = boards[0].coordinator
	coord.record_enabled = false
	coord.set_process(false)
	coord.sim_seed = int(record["seed"])
	coord.rng.seed = int(record["seed"])
	host.visible = false

	var input_log: Array = record["input_log"]
	var idx := 0
	var legal := true
	var illegal = null
	while idx < input_log.size() and int(input_log[idx]["tick"]) <= 0:
		var reason := _apply(boards, input_log[idx])
		if reason != "":
			legal = false
			illegal = _diag(input_log[idx], reason)
			break
		idx += 1
	var cap := 2000000
	var ended := false
	var ticks_since_yield := 0
	while legal and not coord.match_over and not ended and coord.sim_tick < cap:
		coord._sim_tick_once()
		while idx < input_log.size() and int(input_log[idx]["tick"]) == coord.sim_tick:
			var entry: Dictionary = input_log[idx]
			if String(entry["action"]["type"]) == "end":
				idx += 1
				ended = true
				break
			var reason := _apply(boards, entry)
			if reason != "":
				legal = false
				illegal = _diag(entry, reason)
				break
			idx += 1
		if ticks_per_frame > 0:
			ticks_since_yield += 1
			if ticks_since_yield >= ticks_per_frame:
				ticks_since_yield = 0
				await host.get_tree().process_frame

	var per_board: Array = []
	for b in boards:
		per_board.append({"damage": b.total_damage_dealt, "kills": b.total_kills})
	return {
		"over": coord.match_over,
		"final_round": coord.round_num,
		"sim_tick": coord.sim_tick,
		"applied": idx,
		"log_size": input_log.size(),
		"legal": legal,
		"illegal": illegal,
		"boards": per_board,
	}

static func _diag(entry: Dictionary, reason: String) -> Dictionary:
	return {
		"tick": int(entry["tick"]),
		"seat": int(entry["seat"]),
		"action": entry["action"],
		"reason": reason,
	}

static func encode_record(record: Dictionary) -> PackedByteArray:
	return var_to_bytes(record)

static func decode_record(bytes: PackedByteArray) -> Dictionary:
	return bytes_to_var(bytes)

static func _rebuild_map(mr: Dictionary):
	if String(mr.get("kind", "")) == "authored":
		return load("res://campaign/mission_%02d.tres" % int(mr["mission_index"]))
	return MapGen.generate(int(mr["seed"]), int(mr["scale_tier"]), int(mr["mode"]),
		int(mr.get("window_type", 0)), String(mr.get("window_date", "")))

static func _apply(boards: Array, entry: Dictionary) -> String:
	var seat: int = int(entry["seat"])
	if seat < 0 or seat >= boards.size():
		return "bad_seat"
	var board = boards[seat]
	var bc = board.build_controller
	var a: Dictionary = entry["action"]
	var atype := String(a["type"])
	if (atype == "place" or atype == "sell" or atype == "upgrade") and board.coordinator.phase == "run":
		return "phase_gate"
	match atype:
		"place":
			if not bc.bot_place_tower(a["cell"]):
				return "illegal_place"
		"sell":
			if not bc._sell_tower_at_cell(a["cell"]):
				return "illegal_sell"
		"upgrade":
			var t = bc._tower_at_cell(a["cell"])
			if t == null:
				return "no_tower"
			var stat := String(a["stat"])
			if not t.can_upgrade(stat):
				return "cannot_upgrade"
			var cost: int = t.upgrade_cost(stat)
			if not board.can_afford(cost):
				return "cannot_afford"
			board.spend(cost)
			t.upgrade(stat)
		"start":
			board.coordinator.request_start_now()
		"vote_start":
			board.coordinator.set_board_ready(board, bool(a["value"]))
		_:
			return "unknown_action"
	return ""
