extends Node

const Tasks := preload("res://scripts/task_catalog.gd")

var _fails := 0

func _ready() -> void:
	_test_schema()
	_test_accumulate()
	_test_window_roll()
	_test_cumulative_score()
	_test_record_match()
	if _fails == 0:
		print("RESULT ✅ TASKS OK (schema + accumulate + roll + cumulative + record_match)")
	else:
		print("RESULT ❌ TASKS FAILED — ", _fails, " check(s) above")
	get_tree().quit(_fails)

func _check(label: String, got, want) -> void:
	if got == want:
		print("  ✅ ", label)
	else:
		print("  ❌ ", label, "  got=", got, "  want=", want)
		_fails += 1

func _check_true(label: String, cond: bool) -> void:
	_check(label, cond, true)

func _test_schema() -> void:
	print("schema:")
	_check("5 shapes", Tasks.SHAPES.size(), 5)
	_check("3 cadences", Tasks.CADENCES.size(), 3)
	_check("payout chain 120/600/2400",
		[Tasks.PAYOUTS["daily"], Tasks.PAYOUTS["weekly"], Tasks.PAYOUTS["monthly"]],
		[120, 600, 2400])
	_check("×5 daily→weekly", Tasks.PAYOUTS["weekly"], Tasks.PAYOUTS["daily"] * 5)
	_check("×4 weekly→monthly", Tasks.PAYOUTS["monthly"], Tasks.PAYOUTS["weekly"] * 4)
	var missing := 0
	for c in Tasks.CADENCES:
		for shape in Tasks.SHAPES:
			if not Tasks.THRESHOLDS[c].has(shape) or int(Tasks.THRESHOLDS[c][shape]) <= 0:
				missing += 1
	_check("every cadence×shape has a positive threshold", missing, 0)
	_check("task_list enumerates all 15", Tasks.task_list(Tasks.fresh_state()).size(), 15)

func _test_accumulate() -> void:
	print("accumulate:")
	var s := Tasks.fresh_state()
	var r := Tasks.accumulate(s, {"towers": 0, "zones": 0, "kills": 0, "games": 1, "score": 100_000_000})
	_check("score crosses all three cadences", r["completed"].size(), 3)
	_check("payout = 120+600+2400", r["points"], 3120)
	_check("daily score progress recorded", int(s["progress"]["daily"]["score"]), 100_000_000)
	var r2 := Tasks.accumulate(s, {"games": 1, "score": 0})
	_check("completed tasks never re-award", r2["points"], 0)
	var r3 := Tasks.accumulate(s, {"games": 1})
	_check("daily games (3) completes for 120", r3["points"], 120)
	_check_true("daily games marked done", (s["completed"]["daily"] as Array).has("games"))

func _test_window_roll() -> void:
	print("window roll:")
	var s := Tasks.fresh_state()
	var k1 := {"daily": "d1", "weekly": "w1", "monthly": "m1"}
	Tasks.roll_windows(s, k1)
	Tasks.accumulate(s, {"games": 1, "kills": 5})
	_check("weekly carries kills", int(s["progress"]["weekly"]["kills"]), 5)
	Tasks.roll_windows(s, {"daily": "d2", "weekly": "w1", "monthly": "m1"})
	_check("daily kills reset on new day", int(s["progress"]["daily"]["kills"]), 0)
	_check("weekly kills survive new day", int(s["progress"]["weekly"]["kills"]), 5)
	_check("daily window key updated", String(s["windows"]["daily"]), "d2")
	for i in range(3):
		Tasks.accumulate(s, {"games": 1})
	_check_true("daily games done before roll", (s["completed"]["daily"] as Array).has("games"))
	Tasks.roll_windows(s, {"daily": "d3", "weekly": "w1", "monthly": "m1"})
	_check("daily completed clears on roll", (s["completed"]["daily"] as Array).size(), 0)

func _test_cumulative_score() -> void:
	print("cumulative score:")
	var s := Tasks.fresh_state()
	Tasks.roll_windows(s, {"daily": "d1", "weekly": "w1", "monthly": "m1"})
	var pts := 0
	for i in range(3):
		pts += int(Tasks.accumulate(s, {"score": 800_000})["points"])
	_check("3×0.8M sums to 2.4M ≥ daily 2M", int(s["progress"]["daily"]["score"]), 2_400_000)
	_check("daily score task awarded once across the three", pts, 120)

func _test_record_match() -> void:
	print("record_match:")
	var saved_tasks = SaveData.data.get("tasks", {}).duplicate(true)
	var saved_cos = SaveData.data.get("cosmetics", {}).duplicate(true)

	SaveData.data["tasks"] = {}
	SaveData.data["cosmetics"] = {}
	var before := SaveData.season_points()
	var res := Tasks.record_match({"towers": 0, "zones": 0, "kills": 250, "score": 100_000_000})
	_check_true("record_match awarded points", int(res["points"]) > 0)
	_check("season_points rose by exactly the award",
		SaveData.season_points() - before, int(res["points"]))
	_check_true("award reaches the cosmetics track (≥ tier 3)",
		CosmeticsCatalog.unlocked_tier(SaveData.season_points()) >= 3)

	SaveData.data["tasks"] = saved_tasks
	SaveData.data["cosmetics"] = saved_cos
	SaveData.save()
