extends Node2D
# Cosmetic merge feedback: a soft pastel poof on the new tower and a dashed
# "gap!" cue on the emptied source tile. Render-only, never in the sim, so RNG
# here is free to use randf(). No screen shake (design pivot juice spec).

const TILE := 48.0

var _mode := "poof"
var _t := 0.0
var _dur := 0.55
var _color := Color.WHITE
var _ring_r := 0.0
var _dots: Array = []
var _font: Font = ThemeDB.fallback_font

static func poof(parent: Node, world_pos: Vector2, color: Color) -> void:
	var fx = new()
	fx.position = world_pos
	fx._mode = "poof"
	fx._dur = 0.56
	fx._color = color
	fx.z_index = 30
	parent.add_child(fx)
	fx._seed_dots(color)

static func hole(parent: Node, world_pos: Vector2) -> void:
	var fx = new()
	fx.position = world_pos
	fx._mode = "hole"
	fx._dur = 1.05
	fx.z_index = 30
	parent.add_child(fx)

func _seed_dots(color: Color) -> void:
	var cols := [Color.WHITE, color, Color("f6ce73")]
	for i in range(9):
		var ang := -0.4 - randf() * 2.3
		var dist := 18.0 + randf() * 20.0
		_dots.append({
			"dir": Vector2(cos(ang), sin(ang)),
			"dist": dist,
			"size": 3.0 + randf() * 2.5,
			"col": cols[i % 3],
		})

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= _dur:
		queue_free()

func _draw() -> void:
	var p := clampf(_t / _dur, 0.0, 1.0)
	if _mode == "poof":
		_draw_poof(p)
	else:
		_draw_hole(p)

func _draw_poof(p: float) -> void:
	# Expanding ring.
	var ease := 1.0 - pow(1.0 - p, 2.0)
	var r := lerpf(4.0, 30.0, ease)
	var ring_col := _color
	ring_col.a = (1.0 - p) * 0.8
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, ring_col, 3.0, true)
	# Puff dots.
	for d in _dots:
		var pos: Vector2 = d["dir"] * d["dist"] * ease + Vector2(0, 14.0 * ease)
		var c: Color = d["col"]
		c.a = 1.0 - p
		draw_circle(pos, d["size"] * (1.0 - 0.7 * p), c)

func _draw_hole(p: float) -> void:
	var a := 0.0
	if p < 0.15:
		a = p / 0.15
	elif p < 0.6:
		a = 1.0
	else:
		a = 1.0 - (p - 0.6) / 0.4
	var col := Color("e8b84b")
	col.a = a
	# Dashed square outline on the tile.
	var half := TILE * 0.5 - 2.0
	var dash := 6.0
	for side in 4:
		var from: Vector2
		var to: Vector2
		match side:
			0: from = Vector2(-half, -half); to = Vector2(half, -half)
			1: from = Vector2(half, -half); to = Vector2(half, half)
			2: from = Vector2(half, half); to = Vector2(-half, half)
			_: from = Vector2(-half, half); to = Vector2(-half, -half)
		var len := from.distance_to(to)
		var dir := (to - from).normalized()
		var d := 0.0
		while d < len:
			var seg_end := minf(d + dash, len)
			draw_line(from + dir * d, from + dir * seg_end, col, 2.0)
			d += dash * 2.0
	# "gap!" label.
	var txt := "gap!"
	var fs := 11
	var w := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(_font, Vector2(-w * 0.5, -half - 4.0), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, col)
