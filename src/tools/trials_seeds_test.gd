extends Node

# Trials server-owned seed wiring (leaderboard_schema.md §3 + resim_contract.md §10).
# Verifies pve_select seeds its five maps from the SERVER seeds when a backend supplies them,
# and falls back to its deterministic local derivation when offline (empty).
# Drive headlessly: godot --headless --path src res://tools/trials_seeds_test.tscn

const LeaderboardService := preload("res://scripts/leaderboard_service.gd")
const PveSelectScript := preload("res://scripts/pve_select.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")

const SERVER := {
	"daily":   [101, 102, 103, 104, 105],
	"weekly":  [201, 202, 203, 204, 205],
	"monthly": [301, 302, 303, 304, 305],
}

var _fails := 0

func _ready() -> void:
	await _test_server_seeds()
	await _test_offline_fallback()
	if _fails == 0:
		print("RESULT ✅ TRIALS SEEDS OK (server-owned seeds used; offline fallback deterministic)")
	else:
		print("RESULT ❌ TRIALS SEEDS FAILED — ", _fails, " check(s) above")
	get_tree().quit(_fails)

func _check(label: String, got, want) -> void:
	if got != want:
		_fails += 1
		print("  ❌ %s — got %s, want %s" % [label, str(got), str(want)])

func _check_true(label: String, cond: bool) -> void:
	_check(label, cond, true)

# Build a fresh pve_select and let its async _ready finish generating all windows.
func _build_select():
	var sel = PveSelectScript.new()
	add_child(sel)
	for i in range(10):
		await get_tree().process_frame
	return sel

func _test_server_seeds() -> void:
	LeaderboardService.set_backend(SeedBackend.new())
	var sel = await _build_select()
	var daily: Array = sel._windows[MapResourceScript.WindowType.DAILY]
	_check("daily map 0 uses server seed", daily[0].seed, 101)
	_check("daily map 4 uses server seed", daily[4].seed, 105)
	var weekly: Array = sel._windows[MapResourceScript.WindowType.WEEKLY]
	_check("weekly map 2 uses server seed", weekly[2].seed, 203)
	var monthly: Array = sel._windows[MapResourceScript.WindowType.MONTHLY]
	_check("monthly map 0 uses server seed", monthly[0].seed, 301)
	sel.queue_free()

func _test_offline_fallback() -> void:
	LeaderboardService.set_backend(LeaderboardService.LocalBackend.new())  # returns {} seeds
	var sel = await _build_select()
	var daily: Array = sel._windows[MapResourceScript.WindowType.DAILY]
	# Falls back to the local window-identity derivation — NOT the server seeds, and deterministic.
	_check_true("offline daily map 0 is NOT the server seed", daily[0].seed != 101)
	var sel2 = await _build_select()
	_check("offline derivation is deterministic", sel2._windows[MapResourceScript.WindowType.DAILY][0].seed, daily[0].seed)
	# Distinct salts → windows never collide on the same map.
	var monthly0: int = sel._windows[MapResourceScript.WindowType.MONTHLY][0].seed
	_check_true("offline windows don't collide", daily[0].seed != monthly0)
	sel.queue_free()
	sel2.queue_free()

class SeedBackend extends LeaderboardService.LeaderboardBackend:
	func fetch_trials_seeds() -> Dictionary:
		return {
			"daily":   [101, 102, 103, 104, 105],
			"weekly":  [201, 202, 203, 204, 205],
			"monthly": [301, 302, 303, 304, 305],
		}
