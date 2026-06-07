extends Node2D

# Campaign rebuild verification harness (design/CAMPAIGN.md).
# PASS 1 (all missions): load each mission_NN.tres, validate the resource + tutorial beats,
# and prove every ghost_cells set is a BUILDABLE maze — place all prompted cells through the
# real placement path (bot_place_tower) and assert each succeeds (so the mob path stays open).
# PASS 2 (one non-blocking mission): full-build with UI + TutorialDirector and tick a few
# frames to smoke-test the director/callout/overlay wiring end to end.
# Drive headlessly: godot --headless --path src res://tools/campaign_verify.tscn

const MapLoaderScript := preload("res://scripts/map_loader.gd")

const MISSION_COUNT := 5
const VALID_TRIGGERS := [
	"on_mission_load", "on_build_phase_start", "on_first_tower_placed",
	"on_round_start", "on_first_kill", "on_round_end", "on_win",
]

func _ready() -> void:
	var ok := true
	# ---- PASS 0: the edited screen scripts parse + the mission count matches ----
	for s in ["res://scripts/campaign_select.gd", "res://scripts/scene_manager.gd"]:
		if load(s) == null:
			print("PARSE ❌ ", s)
			ok = false
	if SceneManager.CAMPAIGN_MISSION_COUNT != MISSION_COUNT or SceneManager.CAMPAIGN_MISSIONS.size() != MISSION_COUNT:
		print("PARSE ❌ mission count mismatch: count=", SceneManager.CAMPAIGN_MISSION_COUNT,
			" dict=", SceneManager.CAMPAIGN_MISSIONS.size(), " expected ", MISSION_COUNT)
		ok = false

	# ---- PASS 1: resource + maze validation ----
	for idx in range(1, MISSION_COUNT + 1):
		ok = _verify_mission(idx) and ok

	# ---- PASS 2: director/callout/overlay smoke test (mission 2 = non-blocking beats) ----
	# NOTE: M1's blocking opener (pause → "Got it" → resume) is deliberately NOT auto-tested
	# here — pausing the SceneTree headlessly deadlocks the await/timer loop. That live-UI
	# path is confirmed in the human playtest instead (see STATE.md handoff).
	ok = await _smoke_director(2) and ok

	if ok:
		print("RESULT ✅ CAMPAIGN VERIFY OK (", MISSION_COUNT, " missions: resource + maze + director)")
	else:
		print("RESULT ❌ CAMPAIGN VERIFY FAILED — see lines above")
	get_tree().quit()

func _verify_mission(idx: int) -> bool:
	var path := "res://campaign/mission_%02d.tres" % idx
	if not ResourceLoader.exists(path):
		print("M", idx, " ❌ missing: ", path)
		return false
	var map = load(path)
	var ok := true

	if int(map.mission_index) != idx:
		print("M", idx, " ❌ mission_index=", map.mission_index, " (expected ", idx, ")")
		ok = false

	# Beats: valid triggers, exactly one blocking beat allowed (M1 opener).
	var beats: Array = map.tutorial_beats
	var blocking_count := 0
	for b in beats:
		if not (String(b.trigger) in VALID_TRIGGERS):
			print("M", idx, " ❌ bad trigger: ", b.trigger)
			ok = false
		if bool(b.blocking):
			blocking_count += 1
	if blocking_count > 1:
		print("M", idx, " ❌ ", blocking_count, " blocking beats (max 1)")
		ok = false

	# Maze: place every ghost cell through the real path; each must be a legal placement
	# (in-bounds, empty, not entry/exit/checkpoint, supply cap, path stays open).
	var host := Node2D.new()
	add_child(host)
	var boards: Array = MapLoaderScript.build_match(host, map, 1, -1, false)
	var ctrl = boards[0].build_controller
	var ghost_total := 0
	for b in beats:
		var cells = b.ghost_cells
		if cells == null:
			continue
		for c in cells:
			ghost_total += 1
			if not ctrl.bot_place_tower(c):
				print("M", idx, " ❌ ghost cell ", c, " is not a legal placement (closes the path or blocked)")
				ok = false
	host.queue_free()

	print("M", idx, " ", ("✅" if ok else "❌"), " beats=", beats.size(),
		" ghost_cells=", ghost_total, " CP=", map.checkpoint_cells.size(),
		" zones=", map.bonus_zones.size(), " supply=", map.supply_cap,
		" rounds=", map.round_count)
	return ok

# Build a full match (UI + director + overlay) for a NON-blocking mission and tick a few
# frames. Catches script/parse/wiring errors that PASS 1 (local_index=-1) skips.
func _smoke_director(idx: int) -> bool:
	var path := "res://campaign/mission_%02d.tres" % idx
	var map = load(path)
	# A blocking opener would pause the tree and stall the harness — guard against it.
	for b in map.tutorial_beats:
		if String(b.trigger) == "on_mission_load" and bool(b.blocking):
			print("SMOKE ⚠️ mission ", idx, " has a blocking opener; skipping director smoke")
			return true
	var host := Node2D.new()
	add_child(host)
	MapLoaderScript.build_match(host, map, 1, 0, false)
	# Let _ready + the deferred _begin run, then a beat appear.
	await _wait(0.3)
	var found := _find_node(host, "TutorialDirector") != null and _find_node(host, "TutorialCallout") != null
	print("SMOKE ", ("✅" if found else "❌"), " director+callout built for mission ", idx)
	host.queue_free()
	return found

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _find_node(root: Node, cls: String) -> Node:
	for n in root.get_children():
		var s = n.get_script()
		if s != null and s.get_global_name() == cls:
			return n
		var hit = _find_node(n, cls)
		if hit != null:
			return hit
	return null
