extends Node2D

# Campaign rebuild verification harness (design/CAMPAIGN.md).
# PASS 1 (all missions): load each mission_NN.tres, validate the resource + tutorial beats,
# and prove every ghost_cells set is a BUILDABLE maze on three independent axes:
#   (A) supply — the outline fits supply_cap (player can place every cell),
#   (B) legality — placing all cells keeps the mob path open (gold is topped up first so the
#       economy can't masquerade as a path closure: with no income, 250g only buys 25 towers),
#   (C) affordability — the outline's gold cost is earnable by the final round (start + per-round
#       kill/bonus income), so the player can actually buy the whole suggested maze in a match.
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

	# ---- PASS 3: build-guide deviation (polish follow-up #1) ----
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

	# Maze: place every ghost cell through the real placement path and assert each keeps the
	# mob path open. The match economy is NOT a maze property, so we top up gold before the
	# loop — otherwise bot_place_tower's can_afford gate (250g/10 = 25 towers, no income yet)
	# falsely rejects legal cells and masks them as "closes the path." Affordability is a
	# SEPARATE check below (can the player buy the whole outline by the final round?).
	var ghost_cells: Array = []
	for b in beats:
		if b.ghost_cells != null:
			for c in b.ghost_cells:
				ghost_cells.append(c)
	var ghost_total := ghost_cells.size()

	# A) The outline must fit the supply cap — otherwise the player can't build it all.
	if ghost_total > int(map.supply_cap):
		print("M", idx, " ❌ outline has ", ghost_total, " cells > supply_cap ", map.supply_cap,
			" (player can't place the whole outline)")
		ok = false

	# B) Maze legality: every ghost cell is a legal placement and the path stays open.
	var host := Node2D.new()
	add_child(host)
	var boards: Array = MapLoaderScript.build_match(host, map, 1, -1, false)
	var ctrl = boards[0].build_controller
	ctrl.round_manager.gold = 1_000_000  # decouple from economy; affordability checked in (C)
	for c in ghost_cells:
		if not ctrl.bot_place_tower(c):
			print("M", idx, " ❌ ghost cell ", c, " is not a legal placement (closes the path or blocked)")
			ok = false
	host.queue_free()

	# C) Affordability: the suggested outline (ghost_total towers @ TOWER_COST) must be buyable
	# by the time the player reaches the final round. Income per completed round = mob kills +
	# round bonus (interest is ignored — a conservative lower bound on gold). The player has
	# (round_count - 1) rounds of income in hand entering the final build phase.
	var outline_cost := ghost_total * GameConstants.TOWER_COST
	var gold := GameConstants.STARTING_GOLD
	var affordable_by := -1
	if outline_cost <= gold:
		affordable_by = 1
	for r in range(1, int(map.round_count)):  # rounds 1..round_count-1 completed before final round
		gold += int(map.mob_count) * GameConstants.KILL_BONUS + GameConstants.ROUND_BONUS_BASE + r
		if affordable_by < 0 and outline_cost <= gold:
			affordable_by = r + 1  # affordable entering this build phase
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

# The build-guide outline: a tower built ON a suggested cell clears just that cell (the outline
# persists); a tower built OFF the suggested set retires the whole outline (CAMPAIGN.md "Build
# guidance"). Unit-tested against a stub controller so maze legality can't muddy the result.
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

	# Build ON a suggested cell → that cell clears, the outline persists.
	stub.add_tower(Vector2i(2, 2))
	guide.refresh()
	if not guide.has_prompts():
		print("GUIDE ❌ outline vanished after an on-suggestion build"); ok = false

	# Build OFF the suggested set → the whole outline retires.
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
