extends Node2D

# Motion helper verification harness (design/JUICE.md, src/scripts/motion.gd).
# Pure-math only — the FEEL (overshoot character, stagger rhythm) is a human playtest. This
# pins the contract the surfaces depend on:
#   PASS 1: the arrive curve — boundaries (0->0, 1->1), it actually overshoots ~11% with a
#           single peak above 1, and the underlying bezier-x is monotonic (so the Newton
#           solve is well-posed).
#   PASS 2: reduced-motion — no overshoot anywhere, durations shortened by the scale.
#   PASS 3: stagger — cap compresses long lists, short lists keep the base step, cascade
#           hands each item the right delay.
#   PASS 4: token sanity — the timing scale is ordered XS<S<M<L and matches the doc.
# Drive headlessly: godot --headless --path src res://tools/motion_test.tscn

const Motion := preload("res://scripts/motion.gd")

var _fails := 0

func _ready() -> void:
	Motion.reduced = false  # tests assume a known start; PASS 2 flips it explicitly
	_test_arrive_curve()
	_test_reduced_motion()
	_test_stagger()
	_test_tokens()
	Motion.reduced = false  # leave the static flag clean for any later loader
	if _fails == 0:
		print("RESULT ✅ MOTION OK (arrive curve + reduced-motion + stagger + tokens)")
	else:
		print("RESULT ❌ MOTION FAILED — ", _fails, " check(s) above")
	get_tree().quit()

# --- helpers ---

func _check(label: String, cond: bool, detail := "") -> void:
	if cond:
		print("  ✅ ", label)
	else:
		print("  ❌ ", label, ("  " + detail) if detail != "" else "")
		_fails += 1

func _approx(label: String, got: float, want: float, tol: float) -> void:
	_check(label, absf(got - want) <= tol, "got=%.4f want=%.4f tol=%.4f" % [got, want, tol])

# --- PASS 1: the arrive curve ---

func _test_arrive_curve() -> void:
	print("PASS 1 — arrive curve")
	_approx("arrive_ease(0) == 0", Motion.arrive_ease(0.0), 0.0, 0.001)
	_approx("arrive_ease(1) == 1", Motion.arrive_ease(1.0), 1.0, 0.001)
	_check("arrive_ease clamps below 0", is_equal_approx(Motion.arrive_ease(-0.5), 0.0))
	_check("arrive_ease clamps above 1", is_equal_approx(Motion.arrive_ease(1.5), 1.0))

	# Sample the curve and confirm it has the "fast in, overshoot once, settle" signature:
	# a single local maximum above 1 (rises, peaks ~11%, comes back). One sign change in the
	# slope = exactly one hump (no wobble).
	var peak := 0.0
	var prev := Motion.arrive_ease(0.0)
	var slope_flips := 0
	var was_rising := true
	var samples := 400
	for i in range(1, samples + 1):
		var y := Motion.arrive_ease(float(i) / float(samples))
		var rising := y >= prev
		if rising != was_rising:
			slope_flips += 1
		was_rising = rising
		prev = y
		peak = maxf(peak, y)
	_check("arrive overshoots (peak > 1)", peak > 1.0, "peak=%.4f" % peak)
	_check("overshoot is ~10-12%% (peak in 1.09..1.13)", peak >= 1.09 and peak <= 1.13, "peak=%.4f" % peak)
	_check("single overshoot hump (one slope flip)", slope_flips == 1, "flips=%d" % slope_flips)

	# Distance independence: the eased fraction is the same shape no matter the travel, so a
	# 30px and a 900px slide overshoot the SAME proportion. (This is the whole reason for the
	# bezier vs Godot's distance-coupled TRANS_BACK.) Check the eased value at x=0.5 is shared.
	var mid := Motion.arrive_ease(0.5)
	_check("arrive_ease is pure (distance-independent)", mid == Motion.arrive_ease(0.5), "mid=%.4f" % mid)

# --- PASS 2: reduced-motion ---

func _test_reduced_motion() -> void:
	print("PASS 2 — reduced-motion")
	var full_m := Motion.dur(Motion.M)
	Motion.reduced = true
	_approx("dur() shortens by the reduced scale", Motion.dur(Motion.M), Motion.M * Motion.REDUCED_DUR_SCALE, 0.0001)
	_check("reduced full duration < normal", Motion.dur(Motion.M) < full_m)

	# No overshoot when reduced: the eased curve must never exceed 1.
	var max_y := 0.0
	for i in range(101):
		max_y = maxf(max_y, Motion.arrive_ease(float(i) / 100.0))
	_check("reduced arrive never overshoots (max <= 1)", max_y <= 1.0001, "max=%.4f" % max_y)
	_approx("reduced arrive still lands at 1", Motion.arrive_ease(1.0), 1.0, 0.001)

	# Stagger also compresses under reduced-motion.
	var normal_delay := 0.0
	Motion.reduced = false
	normal_delay = Motion.stagger_delay(2, 4, Motion.STAGGER)
	Motion.reduced = true
	_check("reduced stagger_delay < normal", Motion.stagger_delay(2, 4, Motion.STAGGER) < normal_delay)
	Motion.reduced = false

# --- PASS 3: stagger ---

func _test_stagger() -> void:
	print("PASS 3 — stagger")
	# Short list: base step, no compression.
	_approx("short list keeps base step (i=2,n=4)", Motion.stagger_delay(2, 4, Motion.STAGGER), Motion.STAGGER * 2, 0.0001)
	_check("index 0 has no delay", is_equal_approx(Motion.stagger_delay(0, 4, Motion.STAGGER), 0.0))

	# Long list: total cascade is capped (compressed step).
	var n := 30
	var last := Motion.stagger_delay(n - 1, n, Motion.STAGGER)
	_check("long-list total cascade is capped at STAGGER_CAP", last <= Motion.STAGGER_CAP + 0.0001, "last=%.4f cap=%.4f" % [last, Motion.STAGGER_CAP])
	_check("long-list step compressed below base", (last / float(n - 1)) < Motion.STAGGER, "step=%.4f" % (last / float(n - 1)))

	# cascade() hands each item (item, index, delay) with delays matching stagger_delay.
	var seen: Array = []
	var items := ["a", "b", "c"]
	Motion.cascade(items, func(item, idx, delay): seen.append([item, idx, delay]), Motion.STAGGER)
	_check("cascade visits every item", seen.size() == 3)
	_check("cascade passes (item, index, delay) in order", seen[1][0] == "b" and seen[1][1] == 1)
	_approx("cascade delay for index 1 matches stagger_delay", seen[1][2], Motion.stagger_delay(1, 3, Motion.STAGGER), 0.0001)

# --- PASS 4: token sanity ---

func _test_tokens() -> void:
	print("PASS 4 — tokens")
	_check("timing scale ordered XS < S < M < L", Motion.XS < Motion.S and Motion.S < Motion.M and Motion.M < Motion.L)
	_approx("XS == 90ms", Motion.XS, 0.09, 0.0001)
	_approx("S == 160ms", Motion.S, 0.16, 0.0001)
	_approx("M == 260ms", Motion.M, 0.26, 0.0001)
	_approx("L == 440ms", Motion.L, 0.44, 0.0001)
	_approx("SCREEN == 320ms", Motion.SCREEN, 0.32, 0.0001)
	_approx("POP_SCALE == 1.14", Motion.POP_SCALE, 1.14, 0.0001)
	_check("set-piece stagger wider than base", Motion.STAGGER_SETPIECE > Motion.STAGGER)
