extends Node2D

const MapLoaderScript := preload("res://scripts/map_loader.gd")
const MapGen := preload("res://scripts/map_generator.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")
const GridScript := preload("res://scripts/grid.gd")
const ResimScript := preload("res://scripts/resim.gd")

const MAP_SEED := 777
const TICK_CAP := 200000

func _ready() -> void:
	var map = MapGen.generate(MAP_SEED, 1, MapResourceScript.Mode.PVE)
	var live_host := Node2D.new()
	add_child(live_host)
	var boards: Array = MapLoaderScript.build_match(live_host, map, 1, -1, false)
	var board = boards[0]
	var coord = board.coordinator
	coord.set_process(false)
	live_host.visible = false

	var ctrl = board.build_controller
	var placed := _place_flanking(ctrl, 10, [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)])
	placed += _place_adjacent_pairs(ctrl, 4)
	var upg := 0
	for _k in range(8):
		if _try_merge_any(ctrl): upg += 1
	print("HARNESS LIVE seed=", map.map_seed, " grid=", map.grid_size,
		" rounds=", map.round_count, " mob_count=", map.mob_count, " towers=", placed, " merges=", upg)

	var ticks := 0
	var added_r2 := false
	var first_run_tick := -1
	while ticks < TICK_CAP and not coord.match_over:
		coord._sim_tick_once()
		ticks += 1
		if first_run_tick < 0 and coord.phase == "run":
			first_run_tick = coord.sim_tick
		if not added_r2 and coord.round_num == 2 and coord.phase == "build":
			var extra := _place_flanking(ctrl, 2, [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)])
			var extra_upg := 0
			for _k in range(4):
				if _try_merge_any(ctrl): extra_upg += 1
			added_r2 = true
			print("  round 2 build @tick ", coord.sim_tick, ": placed ", extra, " more, merged ", extra_upg)

	var live_dmg: int = board.total_damage_dealt
	var live_kills: int = board.total_kills
	var record: Dictionary = coord.make_record()
	print("HARNESS LIVE DONE round=", coord.round_num, " dmg=", live_dmg,
		" kills=", live_kills, " ticks=", ticks, " log_actions=", record["input_log"].size())

	var resim_host := Node2D.new()
	add_child(resim_host)
	var res: Dictionary = await ResimScript.run(resim_host, record)
	var rb: Dictionary = res["boards"][0]
	print("HARNESS RESIM over=", res["over"], " round=", res["final_round"],
		" dmg=", rb["damage"], " kills=", rb["kills"],
		" applied=", res["applied"], "/", res["log_size"], " sim_tick=", res["sim_tick"])

	var rt_ok: bool = res["over"] and res["legal"] and rb["damage"] == live_dmg and rb["kills"] == live_kills \
		and res["applied"] == record["input_log"].size()

	var bytes := ResimScript.encode_record(record)
	var decoded: Dictionary = ResimScript.decode_record(bytes)
	var ser_host := Node2D.new()
	add_child(ser_host)
	var res_ser: Dictionary = await ResimScript.run(ser_host, decoded)
	var rbs: Dictionary = res_ser["boards"][0]
	var ser_ok: bool = res_ser["legal"] and rbs["damage"] == live_dmg and rbs["kills"] == live_kills
	print("HARNESS SERIALIZE bytes=", bytes.size(), " decoded dmg=", rbs["damage"],
		" kills=", rbs["kills"], " legal=", res_ser["legal"])

	var occ_cell: Vector2i = ctrl.towers[0].grid_cell
	var tamper_a: Dictionary = record.duplicate(true)
	tamper_a["input_log"].insert(1, {"tick": 0, "seat": 0, "action": {"type": "place", "cell": occ_cell}})
	var ta_host := Node2D.new()
	add_child(ta_host)
	var res_a: Dictionary = await ResimScript.run(ta_host, tamper_a)
	var tamper_b: Dictionary = record.duplicate(true)
	_insert_sorted(tamper_b["input_log"], {"tick": first_run_tick, "seat": 0, "action": {"type": "place", "cell": occ_cell}})
	var tb_host := Node2D.new()
	add_child(tb_host)
	var res_b: Dictionary = await ResimScript.run(tb_host, tamper_b)
	var legal_ok: bool = (not res_a["legal"]) and (not res_b["legal"])
	print("HARNESS LEGALITY occupied-cell→", res_a["illegal"], " | phase-gate(tick ",
		first_run_tick, ")→", res_b["illegal"])

	SaveData.data.pve_best_scores.clear()
	SceneManager.pending_map = map
	SceneManager.active_coordinator = coord
	var fake_claim := 99999999
	await SceneManager.report_match_result(fake_claim)
	var written: int = SaveData.best_pve_score(map.window_date, map.scale_tier)
	var wire_ok: bool = written == live_dmg and written != fake_claim
	print("HARNESS WIRING claim=", fake_claim, " written=", written, " (honest re-sim=", live_dmg, ")")

	SaveData.data.pve_best_scores.clear()
	coord.input_log.insert(1, {"tick": 0, "seat": 0, "action": {"type": "place", "cell": occ_cell}})
	await SceneManager.report_match_result(12345)
	var after_illegal: int = SaveData.best_pve_score(map.window_date, map.scale_tier)
	var reject_ok: bool = after_illegal == 0
	print("HARNESS REJECT illegal-log submitted → written=", after_illegal, " (expect 0)")

	var all_ok: bool = rt_ok and wire_ok and ser_ok and legal_ok and reject_ok
	if all_ok:
		print("RESULT ✅ ROUND-TRIP (re-sim==live, dmg=", live_dmg, ") + WIRING (inflated claim ignored)",
			" + SERIALIZE + LEGALITY (tampered logs rejected) + REJECT (illegal log writes no score)")
	else:
		print("RESULT ❌ FAIL — rt_ok=", rt_ok, " wire_ok=", wire_ok, " ser_ok=", ser_ok,
			" legal_ok=", legal_ok, " reject_ok=", reject_ok,
			" | live=", live_dmg, " resim=", rb["damage"], " written=", written)
	get_tree().quit()

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

func _place_adjacent_pairs(ctrl, max_pairs: int) -> int:
	# Place horizontally-adjacent tower pairs on empty cells so the merge action
	# is exercised through the record/re-sim round-trip.
	var placed := 0
	var pairs := 0
	for y in range(ctrl.grid_size.y):
		if pairs >= max_pairs:
			break
		for x in range(ctrl.grid_size.x - 1):
			if pairs >= max_pairs:
				break
			var a := Vector2i(x, y)
			var b := Vector2i(x + 1, y)
			if ctrl.blocked.has(a) or ctrl.blocked.has(b):
				continue
			if not ctrl.bot_place_tower(a):
				continue
			if not ctrl.bot_place_tower(b):
				continue
			placed += 2
			pairs += 1
	return placed

func _try_merge_any(ctrl) -> bool:
	for t in ctrl.towers:
		if not is_instance_valid(t) or t.tier >= GameConstants.MAX_TIER:
			continue
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var other = ctrl._tower_at_cell(t.grid_cell + d)
			if other != null and other.tier == t.tier:
				return ctrl._try_merge(t.grid_cell, t.grid_cell + d)
	return false

func _insert_sorted(log: Array, entry: Dictionary) -> void:
	var t := int(entry["tick"])
	var i := 0
	while i < log.size() and int(log[i]["tick"]) <= t:
		i += 1
	log.insert(i, entry)
