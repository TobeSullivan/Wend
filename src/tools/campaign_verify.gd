extends Node2D

const MapLoaderScript := preload("res://scripts/map_loader.gd")

const MISSION_COUNT := 5
const VALID_TRIGGERS := [
	"on_mission_load", "on_build_phase_start", "on_first_tower_placed",
	"on_round_start", "on_first_kill", "on_round_end", "on_win",
]

func _ready() -> void:
	var ok := true
	for s in ["res://scripts/campaign_select.gd", "res://scripts/scene_manager.gd"]:
		if load(s) == null:
			print("PARSE ❌ ", s)
			ok = false
	if SceneManager.CAMPAIGN_MISSION_COUNT != MISSION_COUNT or SceneManager.CAMPAIGN_MISSIONS.size() != MISSION_COUNT:
		print("PARSE ❌ mission count mismatch: count=", SceneManager.CAMPAIGN_MISSION_COUNT,
			" dict=", SceneManager.CAMPAIGN_MISSIONS.size(), " expected ", MISSION_COUNT)
		ok = false

	for idx in range(1, MISSION_COUNT + 1):
		ok = _verify_mission(idx) and ok

	ok = await _smoke_director(2) and ok

	ok = _verify_build_guide() and ok

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

	var ghost_cells: Array = []
	for b in beats:
		if b.ghost_cells != null:
			for c in b.ghost_cells:
				ghost_cells.append(c)
	var ghost_total := ghost_cells.size()

	if ghost_total > int(map.supply_cap):
		print("M", idx, " ❌ outline has ", ghost_total, " cells > supply_cap ", map.supply_cap,
			" (player can't place the whole outline)")
		ok = false

	var host := Node2D.new()
	add_child(host)
	var boards: Array = MapLoaderScript.build_match(host, map, 1, -1, false)
	var ctrl = boards[0].build_controller
	ctrl.round_manager.gold = 1_000_000
	for c in ghost_cells:
		if not ctrl.bot_place_tower(c):
			print("M", idx, " ❌ ghost cell ", c, " is not a legal placement (closes the path or blocked)")
			ok = false
	host.queue_free()

	var outline_cost := ghost_total * GameConstants.TOWER_COST
	var gold := GameConstants.STARTING_GOLD
	var affordable_by := -1
	if outline_cost <= gold:
		affordable_by = 1
	for r in range(1, int(map.round_count)):
		gold += int(map.mob_count) * GameConstants.KILL_BONUS + GameConstants.ROUND_BONUS_BASE + r
		if affordable_by < 0 and outline_cost <= gold:
			affordable_by = r + 1
	if outline_cost > gold:
		print("M", idx, " ❌ outline costs ", outline_cost, "g but only ", gold,
			"g earnable by the final round (round ", map.round_count, ")")
		ok = false

	print("M", idx, " ", ("✅" if ok else "❌"), " beats=", beats.size(),
		" ghost_cells=", ghost_total, " cost=", outline_cost, "g affordable_by_round=", affordable_by,
		" CP=", map.checkpoint_cells.size(),
		" zones=", map.bonus_zones.size(), " supply=", map.supply_cap,
		" rounds=", map.round_count)
	return ok

func _smoke_director(idx: int) -> bool:
	var path := "res://campaign/mission_%02d.tres" % idx
	var map = load(path)
	for b in map.tutorial_beats:
		if String(b.trigger) == "on_mission_load" and bool(b.blocking):
			print("SMOKE ⚠️ mission ", idx, " has a blocking opener; skipping director smoke")
			return true
	var host := Node2D.new()
	add_child(host)
	MapLoaderScript.build_match(host, map, 1, 0, false)
	await _wait(0.3)
	var found := _find_node(host, "TutorialDirector") != null and _find_node(host, "TutorialCallout") != null
	print("SMOKE ", ("✅" if found else "❌"), " director+callout built for mission ", idx)
	host.queue_free()
	return found

func _verify_build_guide() -> bool:
	var ok := true
	var host := Node2D.new()
	add_child(host)
	var guide = load("res://scripts/build_guide.gd").new()
	var stub := _GuideStub.new()
	guide.build_controller = stub
	host.add_child(guide)

	var cells := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)]
	guide.set_prompts(cells)
	if not guide.has_prompts():
		print("GUIDE ❌ prompts not set"); ok = false

	stub.add_tower(Vector2i(2, 2))
	guide.refresh()
	if not guide.has_prompts():
		print("GUIDE ❌ outline vanished after an on-suggestion build"); ok = false

	stub.add_tower(Vector2i(10, 9))
	guide.refresh()
	if guide.has_prompts():
		print("GUIDE ❌ outline survived an off-suggestion build"); ok = false

	print("GUIDE ", ("✅" if ok else "❌"), " on-suggestion build keeps outline; deviation clears it")
	host.queue_free()
	return ok

class _GuideStub:
	var towers: Array = []
	func _tower_at_cell(cell):
		for t in towers:
			if t.grid_cell == cell:
				return t
		return null
	func add_tower(cell) -> void:
		var t := _StubTower.new()
		t.grid_cell = cell
		towers.append(t)

class _StubTower:
	var grid_cell: Vector2i

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
