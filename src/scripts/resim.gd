extends Node

# Authoritative re-sim runner (resim_contract.md §1, §3, §4, §7).
#
# Replays a match record headlessly and derives the TRUE result by re-running the
# exact same deterministic sim from the same seed. This is the number that gets
# written to a leaderboard / ladder — never the client-claimed one. Because the sim
# is deterministic (fixed tick + seeded RNG, see match_coordinator.gd) and build
# actions are build-phase-only, replaying the seed + tick-tagged input log
# reproduces the match exactly.
#
# Stateless: call Resim.run(host, record). `host` is a Node already in the tree to
# build the throwaway match under (free it after reading the result).

const MapLoaderScript := preload("res://scripts/map_loader.gd")
const MapGen := preload("res://scripts/map_generator.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")

# Replay `record` under `host` and return the derived result:
#   { over, final_round, sim_tick, applied, log_size, legal, illegal, boards:[{damage,kills}, ...] }
#
# `legal` (resim_contract §4.1) is the anti-cheat gate for a SUBMITTED solo log: every
# action must be legal at the tick it claims, replayed against the authoritative state —
# enough gold, a valid empty cell to build on, a real upgradeable/sellable tower, and
# stamped during the build phase (build actions only). The first illegal action stops the
# replay and is reported in `illegal` ({tick, seat, action, reason}); the submit path
# writes NO score for an illegal log. An honest log always replays fully legal — the live
# match only ever logged actions it had already validated through these same entry points,
# and the deterministic re-sim reproduces the exact gold trajectory, so nothing that was
# legal live can read as illegal here.
# `ticks_per_frame` > 0 spreads the replay across frames (await one process_frame every N ticks)
# so a long match doesn't freeze the UI — used by the client match-end path. 0 (default) runs
# straight through with no awaits, so existing synchronous callers (tests, server) are unchanged.
# Determinism is unaffected: identical computation, only wall-clock is spread.
static func run(host: Node2D, record: Dictionary, ticks_per_frame: int = 0) -> Dictionary:
	var map = _rebuild_map(record["map_ref"])
	var num_boards: int = int(record.get("players", 1))
	var boards: Array = MapLoaderScript.build_match(host, map, num_boards, -1, false)
	var coord = boards[0].coordinator
	coord.record_enabled = false   # replay must not re-log
	coord.set_process(false)       # we drive ticks here, not the frame accumulator
	coord.sim_seed = int(record["seed"])
	coord.rng.seed = int(record["seed"])
	host.visible = false           # skip cosmetic FX during the headless replay

	var log: Array = record["input_log"]
	var idx := 0
	var legal := true
	var illegal = null  # first-illegal diagnostics {tick, seat, action, reason}
	# Pre-run actions (tick 0): applied before the first tick advances.
	while idx < log.size() and int(log[idx]["tick"]) <= 0:
		var reason := _apply(boards, log[idx])
		if reason != "":
			legal = false
			illegal = _diag(log[idx], reason)
			break
		idx += 1
	var cap := 2000000
	var ended := false
	var ticks_since_yield := 0
	while legal and not coord.match_over and not ended and coord.sim_tick < cap:
		coord._sim_tick_once()
		# Apply every action stamped for the tick we just completed, in log order.
		while idx < log.size() and int(log[idx]["tick"]) == coord.sim_tick:
			var entry: Dictionary = log[idx]
			if String(entry["action"]["type"]) == "end":
				idx += 1
				ended = true  # bow-out marker — score the partial, stop replaying
				break
			var reason := _apply(boards, entry)
			if reason != "":
				legal = false  # leave the illegal action UNAPPLIED; stops the outer loop
				illegal = _diag(entry, reason)
				break
			idx += 1
		# Breathe every `ticks_per_frame` ticks so the main thread can render (see signature note).
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
		"log_size": log.size(),
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

# --- Record serialization (resim_contract §2): the wire/store format for a submitted
# solo log. Cells are Vector2i (JSON-unsafe), so use Godot's binary var encoding rather
# than JSON. A full record is kilobytes (§1) and round-trips exactly — var_to_bytes is
# Variant-aware; the record holds only Dictionaries/ints/Strings/Vector2i (no objects),
# so plain var_to_bytes is correct and safer than the with-objects variant.
static func encode_record(record: Dictionary) -> PackedByteArray:
	return var_to_bytes(record)

static func decode_record(bytes: PackedByteArray) -> Dictionary:
	return bytes_to_var(bytes)

static func _rebuild_map(mr: Dictionary):
	if String(mr.get("kind", "")) == "authored":
		# Authored campaign map: reload the same mission .tres (version-tagged in the record).
		return load("res://campaign/mission_%02d.tres" % int(mr["mission_index"]))
	# Generated map: map_generator is fully deterministic from the seed (§2.1).
	return MapGen.generate(int(mr["seed"]), int(mr["scale_tier"]), int(mr["mode"]),
		int(mr.get("window_type", 0)), String(mr.get("window_date", "")))

# Apply one logged action through the SAME board entry points the live match used, so
# the economy (cost/refund) and placement validation replay identically. Returns "" if the
# action was legal (and applied), or a non-empty reason string if it was illegal (in which
# case NOTHING is applied — each branch validates before it mutates, so a rejected log
# leaves the authoritative state untouched). The caller (run) records the first reason and
# stops replaying.
static func _apply(boards: Array, entry: Dictionary) -> String:
	var seat: int = int(entry["seat"])
	if seat < 0 or seat >= boards.size():
		return "bad_seat"
	var board = boards[seat]
	var bc = board.build_controller
	var a: Dictionary = entry["action"]
	var atype := String(a["type"])
	# Phase gate: place/sell/upgrade are build-only. A tampered log could stamp one at a
	# run-phase tick (bot_place_tower / _sell_tower_at_cell / upgrade have no phase gate of
	# their own), which would let it act mid-run. Reject it.
	if (atype == "place" or atype == "sell" or atype == "upgrade") and board.coordinator.phase == "run":
		return "phase_gate"
	match atype:
		"place":
			# bot_place_tower validates affordability + _is_valid_placement (in-bounds,
			# empty, not blocked, not entry/exit/checkpoint, supply cap, path stays open).
			if not bc.bot_place_tower(a["cell"]):
				return "illegal_place"
		"sell":
			# false ⇒ no tower at that cell to sell.
			if not bc._sell_tower_at_cell(a["cell"]):
				return "illegal_sell"
		"upgrade":
			var t = bc._tower_at_cell(a["cell"])
			if t == null:
				return "no_tower"
			var stat := String(a["stat"])
			if not t.can_upgrade(stat):
				return "cannot_upgrade"  # unknown stat, or the stat is already maxed
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
