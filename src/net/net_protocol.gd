extends RefCounted
class_name NetProtocol

# Wire message shapes for PVP netcode. Messages are plain Dictionaries with a "t"
# (type) field; transports move them verbatim (see match_transport.gd). The set is
# deliberately tiny — the match is round-barrier synchronized, so only build inputs,
# the shared clock, ready votes, and per-round kill tallies ever cross the wire
# (notes/multiplayer_architecture.md §0).
#
# Direction key: C→H client→host(authority), H→C host→clients, both = either way.

# --- Lobby (pre-match) ---
const LOBBY_STATE := "lobby_state"   # H→C: {players:[{id,name,seat}], host_id, count, countdown}
const SET_NAME := "set_name"         # C→H: {name}
const START_MATCH := "start_match"   # H→C: {seed, tier, board_count, seat, names:[...]}

# --- In-match: build phase ---
const BUILD_INPUT := "build_input"   # both: {seat, action, cell?, stat?}  (host relays C→H to all)
const READY := "ready"               # C→H: {seat, value}

# --- In-match: clock / barrier (authority owns these) ---
const CLOCK := "clock"               # H→C: {phase, round, build_time_left}
const RUN_DONE := "run_done"         # C→H: {seat, round, kills}
const RESOLUTION := "resolution"     # H→C: {lives:{seat:int}, eliminated:[seat], round}
const MATCH_END := "match_end"       # H→C: {placement:{seat:int}}

# Build-input action kinds.
const ACT_PLACE := "place"
const ACT_SELL := "sell"
const ACT_UPGRADE := "upgrade"

const DEFAULT_PORT := 8771
const MAX_PLAYERS := 8

# --- Builders (keep call sites terse + typo-safe) ---

static func build_input_place(seat: int, cell: Vector2i) -> Dictionary:
	return {"t": BUILD_INPUT, "seat": seat, "action": ACT_PLACE, "cell": cell}

static func build_input_sell(seat: int, cell: Vector2i) -> Dictionary:
	return {"t": BUILD_INPUT, "seat": seat, "action": ACT_SELL, "cell": cell}

static func build_input_upgrade(seat: int, cell: Vector2i, stat: String) -> Dictionary:
	return {"t": BUILD_INPUT, "seat": seat, "action": ACT_UPGRADE, "cell": cell, "stat": stat}

static func ready(seat: int, value: bool) -> Dictionary:
	return {"t": READY, "seat": seat, "value": value}

static func clock(phase: String, round_num: int, build_time_left: float) -> Dictionary:
	return {"t": CLOCK, "phase": phase, "round": round_num, "build_time_left": build_time_left}

static func run_done(seat: int, round_num: int, kills: int) -> Dictionary:
	return {"t": RUN_DONE, "seat": seat, "round": round_num, "kills": kills}
