extends Node

const XS := 0.09
const S := 0.16
const M := 0.26
const L := 0.44
const SCREEN := 0.32

const STAGGER := 0.06
const STAGGER_SETPIECE := 0.13
const STAGGER_CAP := 0.42

const POP_SCALE := 1.14

const ARRIVE_OVERSHOOT_S := 1.8

static var reduced := false

const REDUCED_DUR_SCALE := 0.6

static func dur(seconds: float) -> float:
	return seconds * REDUCED_DUR_SCALE if reduced else seconds

static func arrive(t):
	if reduced:
		return t.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	return t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func settle(t):
	return t.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

static func leave(t):
	return t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

static func arrive_ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	if reduced:
		return 1.0 - pow(1.0 - x, 3.0)
	var u := x - 1.0
	var s := ARRIVE_OVERSHOOT_S
	return 1.0 + (s + 1.0) * u * u * u + s * u * u

static func pop(node: CanvasItem, to := POP_SCALE, duration := S) -> Tween:
	var base: Vector2 = node.scale
	if base.is_zero_approx():
		base = Vector2.ONE
	if node is Control:
		node.pivot_offset = node.size * 0.5
	var t := node.create_tween()
	if reduced:
		to = 1.0 + (to - 1.0) * 0.5
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", base * to, dur(duration) * 0.45)
	t.tween_property(node, "scale", base, dur(duration) * 0.55)
	return t

static func fade_in(node: CanvasItem, duration := S, delay := 0.0) -> Tween:
	node.modulate.a = 0.0
	var t := node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	settle(t)
	t.tween_property(node, "modulate:a", 1.0, dur(duration))
	return t

static func fade_out(node: CanvasItem, duration := S, delay := 0.0) -> Tween:
	var t := node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	leave(t)
	t.tween_property(node, "modulate:a", 0.0, dur(duration))
	return t

static func arrive_property(node: Node, property: NodePath, from, to, duration := M, delay := 0.0) -> Tween:
	node.set_indexed(property, from)
	var t := node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.tween_method(
		func(p: float): node.set_indexed(property, lerp(from, to, arrive_ease(p))),
		0.0, 1.0, dur(duration))
	return t

static func slide_in(node: Control, from_offset: Vector2, duration := M, delay := 0.0) -> Tween:
	var target := node.position
	var start := target + from_offset
	node.position = start
	node.modulate.a = 0.0
	var t := node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.tween_method(
		func(p: float): node.position = start.lerp(target, arrive_ease(p)),
		0.0, 1.0, dur(duration))
	t.set_parallel(true)
	settle(t)
	t.tween_property(node, "modulate:a", 1.0, dur(duration) * 0.62)
	return t

static func overlay_in(dim: CanvasItem, panel: Control, panel_dur := M) -> void:
	dim.modulate.a = 0.0
	fade_in(dim, M)
	panel.pivot_offset = panel.size * 0.5
	arrive_property(panel, "scale", Vector2.ONE * 0.92, Vector2.ONE, panel_dur)
	fade_in(panel, S)

static func overlay_out(dim: CanvasItem, panel: Control, on_hidden: Callable) -> void:
	fade_out(dim, S)
	var t := panel.create_tween()
	t.set_parallel(true)
	leave(t)
	t.tween_property(panel, "scale", Vector2.ONE * 0.96, dur(S))
	t.tween_property(panel, "modulate:a", 0.0, dur(S))
	t.chain().tween_callback(func():
		panel.scale = Vector2.ONE
		panel.modulate.a = 1.0
		dim.modulate.a = 1.0
		on_hidden.call())

static func cascade(items: Array, per_item: Callable, step := STAGGER) -> void:
	var n := items.size()
	for i in n:
		per_item.call(items[i], i, stagger_delay(i, n, step))

static func stagger_delay(i: int, n: int, step := STAGGER) -> float:
	var effective := step
	if n > 1 and step * (n - 1) > STAGGER_CAP:
		effective = STAGGER_CAP / float(n - 1)
	if reduced:
		effective *= REDUCED_DUR_SCALE
	return effective * i
