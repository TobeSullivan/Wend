extends Node2D

# Determinism + re-sim round-trip + legality regression harness (resim_contract.md §4/§5).
# Plays a real headless match while RECORDING the tick-tagged input log (towers placed +
# upgraded across multiple rounds, all through the real economy so the record is LEGAL),
# then exercises the full anti-cheat contract:
#   • ROUND-TRIP — re-sim the captured record; its score must equal the live score (§4).
#   • SERIALIZE — encode→decode the record (var_to_bytes; Vector2i cells) and re-sim the
#     decoded copy → identical result (§2).
#   • LEGALITY — two tampered copies (a place at an occupied cell; a build action stamped at
#     a run-phase tick) must re-sim legal=false (§4.1).
#   • WIRING — an inflated client claim is ignored; the honest re-sim score is written (§4).
#   • REJECT — an illegal log submitted through report_match_result writes NO score (§4.1).
# Drive headlessly: godot --headless --path src res://tools/sim_harness.tscn (no project.godot
# edit needed — pass the scene as an argument). Autoloads (GameConstants/SaveData) are available.
# Last verified 2026-06-08: all five checks ✅, 0 errors, 13-round match (honest dmg=54985).

const MapLoaderScript := preload("res://scripts/map_loader.gd")
const MapGen := preload("res://scripts/map_generator.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")
const GridScript := preload("res://scripts/grid.gd")
const ResimScript := preload("res://scripts/resim.gd")

const MAP_SEED := 777
const TICK_CAP := 200000

func _ready() -> void:
	# ---- LIVE match (records its own input log) ----
	var map = MapGen.generate(MAP_SEED, 1, MapResourceScript.Mode.PVE)
	var live_host := Node2D.new()
	add_child(live_host)
	var boards: Array = MapLoaderScript.build_match(live_host, map, 1, -1, false)
	var board = boards[0]
	var coord = board.coordinator
	coord.set_process(false)        # drive ticks here, not the frame accumulator
	live_host.visible = false       # skip cosmetic FX

	var ctrl = board.build_controller
	# Round-1 build (tick 0): place a batch + upgrade some for crit. Upgrades go through the
	# REAL economy (pay-then-upgrade, only when affordable) so the captured record is LEGAL —
	# the §4.1 check rejects unpaid upgrades, so a free direct t.upgrade() would make the
	# honest record itself illegal. The round-1 surplus buys a handful; round 2 buys more.
	var placed := _place_flanking(ctrl, 10, [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)])
	var upg := 0
	for i in range(mini(6, ctrl.towers.size())):
		var t = ctrl.towers[i]
		for _k in range(3):
			if _try_upgrade(board, t, "crit_chance"): upg += 1
		for _k in range(2):
			if _try_upgrade(board, t, "damage"): upg += 1
	print("HARNESS LIVE seed=", map.seed, " grid=", map.grid_size,
		" rounds=", map.round_count, " mob_count=", map.mob_count, " towers=", placed, " upgrades=", upg)

	# Natural build-timer expiry (no request_start_now) so the build→run auto-transition
	# is exercised. During round 2's build phase, place 2 MORE towers — proves the record
	# captures actions across rounds at non-zero ticks, not just the opening batch.
	var ticks := 0
	var added_r2 := false
	var first_run_tick := -1   # a known run-phase tick, for the phase-gate tamper below
	while ticks < TICK_CAP and not coord.match_over:
		coord._sim_tick_once()
		ticks += 1
		if first_run_tick < 0 and coord.phase == "run":
			first_run_tick = coord.sim_tick
		if not added_r2 and coord.round_num == 2 and coord.phase == "build":
			var extra := _place_flanking(ctrl, 2, [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)])
			# Spend the gold accrued over round 1 on more upgrades (real economy) — proves the
			# record captures legal upgrades at a non-zero tick, across rounds.
			var extra_upg := 0
			for i in range(ctrl.towers.size()):
				if _try_upgrade(board, ctrl.towers[i], "damage"): extra_upg += 1
			added_r2 = true
			print("  round 2 build @tick ", coord.sim_tick, ": placed ", extra, " more, upgraded ", extra_upg)

	var live_dmg: int = board.total_damage_dealt
	var live_kills: int = board.total_kills
	var record: Dictionary = coord.make_record()
	print("HARNESS LIVE DONE round=", coord.round_num, " dmg=", live_dmg,
		" kills=", live_kills, " ticks=", ticks, " log_actions=", record["input_log"].size())

	# ---- RE-SIM the captured record from scratch ----
	var resim_host := Node2D.new()
	add_child(resim_host)
	var res: Dictionary = await ResimScript.run(resim_host, record)
	var rb: Dictionary = res["boards"][0]
	print("HARNESS RESIM over=", res["over"], " round=", res["final_round"],
		" dmg=", rb["damage"], " kills=", rb["kills"],
		" applied=", res["applied"], "/", res["log_size"], " sim_tick=", res["sim_tick"])

	var rt_ok: bool = res["over"] and res["legal"] and rb["damage"] == live_dmg and rb["kills"] == live_kills \
		and res["applied"] == record["input_log"].size()

	# ---- SERIALIZATION round-trip (resim_contract §2): encode→decode the record (cells are
	# Vector2i, JSON-unsafe → Godot var encoding) and re-sim the decoded copy — identical result. ----
	var bytes := ResimScript.encode_record(record)
	var decoded: Dictionary = ResimScript.decode_record(bytes)
	var ser_host := Node2D.new()
	add_child(ser_host)
	var res_ser: Dictionary = await ResimScript.run(ser_host, decoded)
	var rbs: Dictionary = res_ser["boards"][0]
	var ser_ok: bool = res_ser["legal"] and rbs["damage"] == live_dmg and rbs["kills"] == live_kills
	print("HARNESS SERIALIZE bytes=", bytes.size(), " decoded dmg=", rbs["damage"],
		" kills=", rbs["kills"], " legal=", res_ser["legal"])

	# ---- LEGALITY (resim_contract §4.1): a tampered log must re-sim legal=false. Two
	# independent attack vectors, each on a fresh deep copy of the honest record. ----
	# (a) Illegal placement: a place at an already-occupied cell (towers[0]'s cell), inserted
	#     just after the opening place at tick 0 so the log stays tick-sorted.
	var occ_cell: Vector2i = ctrl.towers[0].grid_cell
	var tamper_a: Dictionary = record.duplicate(true)
	tamper_a["input_log"].insert(1, {"tick": 0, "seat": 0, "action": {"type": "place", "cell": occ_cell}})
	var ta_host := Node2D.new()
	add_child(ta_host)
	var res_a: Dictionary = await ResimScript.run(ta_host, tamper_a)
	# (b) Phase gate: a build action stamped at a known RUN-phase tick. Inserted in tick
	#     order so the replay is identical up to that tick, then the gate fires.
	var tamper_b: Dictionary = record.duplicate(true)
	_insert_sorted(tamper_b["input_log"], {"tick": first_run_tick, "seat": 0, "action": {"type": "place", "cell": occ_cell}})
	var tb_host := Node2D.new()
	add_child(tb_host)
	var res_b: Dictionary = await ResimScript.run(tb_host, tamper_b)
	var legal_ok: bool = (not res_a["legal"]) and (not res_b["legal"])
	print("HARNESS LEGALITY occupied-cell→", res_a["illegal"], " | phase-gate(tick ",
		first_run_tick, ")→", res_b["illegal"])

	# ---- WIRING: report_match_result must RECORD the re-sim score, never a client claim ----
	# Feed it a wildly inflated "advisory" damage and confirm SaveData stores the honest
	# re-sim score instead (resim_contract §4 — you can't write score = 9,999,999).
	SaveData.data.pve_best_scores.clear()
	SceneManager.pending_map = map
	SceneManager.active_coordinator = coord
	var fake_claim := 99999999
	await SceneManager.report_match_result(fake_claim)   # async (chunked re-sim) — also proves chunked==live
	var written: int = SaveData.best_pve_score(map.window_date, map.scale_tier)
	var wire_ok: bool = written == live_dmg and written != fake_claim
	print("HARNESS WIRING claim=", fake_claim, " written=", written, " (honest re-sim=", live_dmg, ")")

	# ---- WIRING REJECT (resim_contract §4.1): an illegal log submitted through the real
	# write path (report_match_result) must write NO score. Inject an illegal action into the
	# live record, clear storage, submit, and confirm nothing was written. ----
	SaveData.data.pve_best_scores.clear()
	coord.input_log.insert(1, {"tick": 0, "seat": 0, "action": {"type": "place", "cell": occ_cell}})
	await SceneManager.report_match_result(12345)
	var after_illegal: int = SaveData.best_pve_score(map.window_date, map.scale_tier)
	var reject_ok: bool = after_illegal == 0
	print("HARNESS REJECT illegal-log submitted → written=", after_illegal, " (expect 0)")

	# ---- VERDICT ----
	var all_ok: bool = rt_ok and wire_ok and ser_ok and legal_ok and reject_ok
	if all_ok:
		print("RESULT ✅ ROUND-TRIP (re-sim==live, dmg=", live_dmg, ") + WIRING (inflated claim ignored)",
			" + SERIALIZE + LEGALITY (tampered logs rejected) + REJECT (illegal log writes no score)")
	else:
		print("RESULT ❌ FAIL — rt_ok=", rt_ok, " wire_ok=", wire_ok, " ser_ok=", ser_ok,
			" legal_ok=", legal_ok, " reject_ok=", reject_ok,
			" | live=", live_dmg, " resim=", rb["damage"], " written=", written)
	get_tree().quit()

# Place up to max_n towers on cells flanking the mob path (guaranteed in range so they
# fire). Deterministic: fixed path order, fixed offset order. Returns count placed.
func _place_flanking(ctrl, max_n: int, offsets: Array) -> int:
	var path: PackedVector2Array = ctrl.current_path_world()
	var placed := 0
	for i in range(path.size()):
		var cell := GridScript.world_to_cell(path[i])
		for off in offsets:
			if placed >= max_n:
				return placed
			if ctrl.bot_place_tower(cell + off):
				placed += 1
	return placed

# Upgrade a tower the way real play does: only if it's upgradeable AND affordable, paying
# the gold first. t.upgrade() logs the action for the record. Returns true if it happened.
func _try_upgrade(board, t, stat: String) -> bool:
	if not t.can_upgrade(stat):
		return false
	var cost: int = t.upgrade_cost(stat)
	if not board.can_afford(cost):
		return false
	board.spend(cost)
	t.upgrade(stat)
	return true

# Insert an entry into a tick-sorted input log, preserving the ascending-tick order the
# re-sim assumes (it consumes the log as a sorted stream). Lands after all entries whose
# tick is <= the new one's.
func _insert_sorted(log: Array, entry: Dictionary) -> void:
	var t := int(entry["tick"])
	var i := 0
	while i < log.size() and int(log[i]["tick"]) <= t:
		i += 1
	log.insert(i, entry)
