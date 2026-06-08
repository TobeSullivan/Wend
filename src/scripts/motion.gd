extends Node

# Motion — the single source of timing + easing for all juice (design/JUICE.md).
#
# The doc's keystone instruction: "Promote the durations + curves to one shared helper
# so no surface re-invents them — that single source is what makes it read as one authored
# hand." Every juice surface routes its tweens through here; no screen hard-codes a
# duration or an easing curve.
#
# Used like UiStyle: `const Motion := preload("res://scripts/motion.gd")`, then call the
# static methods. Not an autoload (the one piece of state, `reduced`, is a static var that
# lives on the class regardless).
#
# The three verbs (JUICE "The three verbs"): nothing teleports — things ARRIVE (fast in,
# ~11% overshoot, settle), SETTLE (reposition, no overshoot), or LEAVE (accelerate out,
# always quicker than they arrived).

# ============================================================================
# Timing scale (seconds). JUICE "Timing scale".
# ============================================================================

const XS := 0.09     # taps / micro-feedback
const S := 0.16      # single element
const M := 0.26      # panels, transitions — the default
const L := 0.44      # staged set-pieces only (earned)
const SCREEN := 0.32 # full screen-to-screen

# Stagger between siblings (JUICE "Stagger"). Set-pieces may widen for drama; the visible
# cascade is capped so a long list doesn't crawl (compress the per-step beyond the cap).
const STAGGER := 0.06
const STAGGER_SETPIECE := 0.13
const STAGGER_CAP := 0.42

# Emphasis pop: a value that just changed scales 1.0 -> 1.14 -> 1.0 over S (JUICE).
const POP_SCALE := 1.14

# Arrive overshoot (JUICE "tune the overshoot constant down to ~10-12%"). Implemented as an
# easeOutBack with a tunable constant `s`, so the overshoot is exactly controllable and
# DISTANCE-INDEPENDENT — unlike Godot's built-in TRANS_BACK, whose overshoot grows with the
# travel distance. peak_overshoot = 4*s^3 / (27*(s+1)^2); s = 1.8 -> ~11% (PLAYTEST DIAL).
# (Note: the motion-reference mock's literal bezier .34,1.32,.5,1 only overshoots ~3.4%;
# this honors the doc's stated 10-12% + the CC Godot-map instead. Flagged for Tobe.)
const ARRIVE_OVERSHOOT_S := 1.8

# Reduced-motion (JUICE "Reduced-motion"): drops overshoot -> plain ease and shortens
# durations. Wire a Settings toggle to this; everything reads through it.
static var reduced := false

const REDUCED_DUR_SCALE := 0.6

# Scale a base duration by the reduced-motion factor. All helpers below route through this,
# so the toggle shortens every animation from one place.
static func dur(seconds: float) -> float:
	return seconds * REDUCED_DUR_SCALE if reduced else seconds

# ============================================================================
# Verb appliers — set trans/ease and return the same object for chaining (JUICE "Godot map
# for CC"). Accept EITHER a whole Tween (sets its defaults) OR a single Tweener from
# tween_property() (sets just that step) — both expose set_trans/set_ease, so the param is
# duck-typed. Use these for direct tween_property work where the built-in curves are faithful
# (settle/leave never overshoot, so the engine curves match). For overshoot that must stay
# ~11% regardless of travel, drive the value through arrive_property/slide_in instead.
# ============================================================================

static func arrive(t):
	if reduced:
		return t.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	return t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func settle(t):
	return t.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

static func leave(t):
	return t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

# ============================================================================
# The arrive curve (easeOutBack). Driving a property through arrive_ease keeps the overshoot
# at ~11% of the remaining distance no matter how far the element travels — the fix for
# "Godot's default back is stronger" (whose overshoot scales with travel distance).
# ============================================================================

# Eased output [rises past 1 to the peak, settles to 1] for linear progress x in [0,1].
# Honors reduced-motion (no overshoot, plain ease-out cubic).
static func arrive_ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	if reduced:
		return 1.0 - pow(1.0 - x, 3.0)  # ease-out cubic, no overshoot
	var u := x - 1.0
	var s := ARRIVE_OVERSHOOT_S
	return 1.0 + (s + 1.0) * u * u * u + s * u * u

# ============================================================================
# High-level helpers. These bake in the two sequencing rules so surfaces can't get them
# wrong: ARM BEFORE REVEAL (set the pre-entrance state before the first animated frame, so
# the end frame never flashes) and the arrive curve.
# ============================================================================

# Emphasis pop: scale a node 1.0 -> `to` -> 1.0 over S. Pivots at the node's centre so it
# grows in place. Call after layout (on the value change) so size is settled.
static func pop(node: CanvasItem, to := POP_SCALE, duration := S) -> Tween:
	if node is Control:
		node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE
	var t := node.create_tween()
	if reduced:
		# Still register the beat, just smaller and snappier.
		to = 1.0 + (to - 1.0) * 0.5
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", Vector2.ONE * to, dur(duration) * 0.45)
	t.tween_property(node, "scale", Vector2.ONE, dur(duration) * 0.55)
	return t

# Fade a node in (alpha 0 -> 1). Arms alpha to 0 before animating.
static func fade_in(node: CanvasItem, duration := S, delay := 0.0) -> Tween:
	node.modulate.a = 0.0
	var t := node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	settle(t)
	t.tween_property(node, "modulate:a", 1.0, dur(duration))
	return t

# Fade a node out (alpha -> 0) on the leave curve. Optional positional drift.
static func fade_out(node: CanvasItem, duration := S, delay := 0.0) -> Tween:
	var t := node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	leave(t)
	t.tween_property(node, "modulate:a", 0.0, dur(duration))
	return t

# Drive any single property along the faithful arrive curve (distance-independent ~11%
# overshoot). Works for any lerp-able type (float, Vector2, Color...). Arms `from` first.
static func arrive_property(node: Node, property: NodePath, from, to, duration := M, delay := 0.0) -> Tween:
	node.set_indexed(property, from)
	var t := node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.tween_method(
		func(p: float): node.set_indexed(property, lerp(from, to, arrive_ease(p))),
		0.0, 1.0, dur(duration))
	return t

# Slide + fade a Control in from an edge offset (JUICE "Spatial grammar": elements enter
# from the edge they belong to). Arms the start state, arrives on the faithful curve, and
# fades a touch quicker than it moves (matches the mock). Returns the position tween.
static func slide_in(node: Control, from_offset: Vector2, duration := M, delay := 0.0) -> Tween:
	var target := node.position
	var start := target + from_offset
	node.position = start
	node.modulate.a = 0.0
	var t := node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.set_parallel(true)
	t.tween_method(
		func(p: float): node.position = start.lerp(target, arrive_ease(p)),
		0.0, 1.0, dur(duration))
	t.chain()  # alpha after the (possible) interval, parallel to the move
	t.set_parallel(true)
	settle(t)
	t.tween_property(node, "modulate:a", 1.0, dur(duration) * 0.62)
	return t

# Cascade a sibling set with stagger (JUICE "Stagger"). `per_item.call(item, index, delay)`
# does the per-item animation (typically a slide_in/fade_in given that delay); this only
# computes the spacing. The total visible cascade is capped at STAGGER_CAP by compressing
# the step for long lists.
static func cascade(items: Array, per_item: Callable, step := STAGGER) -> void:
	var n := items.size()
	for i in n:
		per_item.call(items[i], i, stagger_delay(i, n, step))

# Per-item delay for index `i` in a set of `n`, honoring the cap + reduced-motion. Use when
# you build items with explicit delays rather than the cascade() callback form.
static func stagger_delay(i: int, n: int, step := STAGGER) -> float:
	var effective := step
	if n > 1 and step * (n - 1) > STAGGER_CAP:
		effective = STAGGER_CAP / float(n - 1)
	if reduced:
		effective *= REDUCED_DUR_SCALE
	return effective * i
