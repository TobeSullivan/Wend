extends RefCounted
class_name NetProtocol

const JOIN_ROOM := "join_room"

const LOBBY_STATE := "lobby_state"
const SET_NAME := "set_name"
const START_MATCH := "start_match"
const PLAY := "play"

const BUILD_INPUT := "build_input"
const READY := "ready"

const CLOCK := "clock"
const RUN_DONE := "run_done"
const RESOLUTION := "resolution"
const MATCH_END := "match_end"

const ACT_PLACE := "place"
const ACT_SELL := "sell"
const ACT_MERGE := "merge"

const DEFAULT_PORT := 8771
const MAX_PLAYERS := 8

static func build_input_place(seat: int, cell: Vector2i) -> Dictionary:
	return {"t": BUILD_INPUT, "seat": seat, "action": ACT_PLACE, "cell": cell}

static func build_input_sell(seat: int, cell: Vector2i) -> Dictionary:
	return {"t": BUILD_INPUT, "seat": seat, "action": ACT_SELL, "cell": cell}

static func build_input_merge(seat: int, src: Vector2i, dst: Vector2i) -> Dictionary:
	return {"t": BUILD_INPUT, "seat": seat, "action": ACT_MERGE, "src": src, "dst": dst}

static func ready(seat: int, value: bool) -> Dictionary:
	return {"t": READY, "seat": seat, "value": value}

static func clock(phase: String, round_num: int, build_time_left: float) -> Dictionary:
	return {"t": CLOCK, "phase": phase, "round": round_num, "build_time_left": build_time_left}

static func run_done(seat: int, round_num: int, kills: int) -> Dictionary:
	return {"t": RUN_DONE, "seat": seat, "round": round_num, "kills": kills}
