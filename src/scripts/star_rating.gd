extends Control

var total: int = 3
var filled: int = 0
var star_size: float = 22.0
var gap: float = 4.0

const GOLD := Color("f2c84b")
const GOLD_EDGE := Color("7a5a14")
const EMPTY := Color(0.0, 0.0, 0.0, 0.28)
const EMPTY_EDGE := Color(0.0, 0.0, 0.0, 0.45)

func configure(p_filled: int, p_total: int = 3, p_size: float = 22.0) -> Control:
	filled = clampi(p_filled, 0, p_total)
	total = p_total
	star_size = p_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(total * star_size + (total - 1) * gap, star_size)
	queue_redraw()
	return self

func _draw() -> void:
	for i in range(total):
		var c := Vector2(i * (star_size + gap) + star_size * 0.5, star_size * 0.5)
		var pts := _star_points(c, star_size * 0.5, star_size * 0.21)
		var loop := pts + PackedVector2Array([pts[0]])
		if i < filled:
			draw_colored_polygon(pts, GOLD)
			draw_polyline(loop, GOLD_EDGE, 2.0, true)
		else:
			draw_colored_polygon(pts, EMPTY)
			draw_polyline(loop, EMPTY_EDGE, 1.5, true)

func _star_points(c: Vector2, r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(10):
		var ang := -PI / 2.0 + k * PI / 5.0
		var r := r_out if k % 2 == 0 else r_in
		pts.append(c + Vector2(cos(ang), sin(ang)) * r)
	return pts
