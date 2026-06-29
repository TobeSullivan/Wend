extends Node2D
class_name RoadRenderer

@export var road_color: Color = Color("c9a93f")
@export var outline_color: Color = Color("2e2a14")
@export var highlight_color: Color = Color("e2c45a")
@export var outline_w_frac: float = 1.04
@export var fill_w_frac: float = 0.84
@export var highlight_w_frac: float = 0.58
@export_range(0.0, 1.0) var preview_alpha: float = 0.45

const DASH_LEN_TILES := 0.5
const DASH_GAP_TILES := 0.45
const DASH_WIDTH_FRAC := 0.18
const DASH_TILES_PER_SEC := 2.0
const DASH_COLOR := Color(1.0, 1.0, 1.0, 0.85)

var _cell: float = 64.0
var _committed := PackedVector2Array()
var _preview := PackedVector2Array()

var _cum := PackedFloat32Array()
var _total_len: float = 0.0
var _arc_offset: float = 0.0
var _chevrons_visible: bool = true

var _l_outline: Line2D
var _l_fill: Line2D
var _l_top: Line2D
var _p_outline: Line2D
var _p_fill: Line2D
var _dash_layer: _DashLayer

class _DashLayer extends Node2D:
	var rr: Node = null
	func _draw() -> void:
		if rr != null:
			rr._paint_dashes(self)

func _ready() -> void:
	_l_outline = _make_line(outline_color, outline_w_frac, 0)
	_l_fill    = _make_line(road_color,    fill_w_frac,    1)
	_l_top     = _make_line(highlight_color, highlight_w_frac, 2)
	_l_top.default_color.a = 0.9
	_p_outline = _make_line(outline_color, outline_w_frac, 3)
	_p_fill    = _make_line(road_color,    fill_w_frac,    4)
	_p_outline.modulate.a = preview_alpha
	_p_fill.modulate.a = preview_alpha
	_show_preview(false)
	_dash_layer = _DashLayer.new()
	_dash_layer.rr = self
	_dash_layer.z_index = 5
	add_child(_dash_layer)
	_apply_widths()

func _process(delta: float) -> void:
	if not _chevrons_visible or _total_len <= 0.0:
		return
	_arc_offset = fposmod(_arc_offset + delta * DASH_TILES_PER_SEC * _cell, _total_len)
	_dash_layer.queue_redraw()

func _make_line(col: Color, w_frac: float, z: int) -> Line2D:
	var l := Line2D.new()
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.round_precision = 8
	l.antialiased = false
	l.z_index = z
	l.set_meta("w_frac", w_frac)
	add_child(l)
	return l

func configure(cell_size: float) -> void:
	_cell = cell_size
	_apply_widths()
	if _dash_layer != null:
		_dash_layer.queue_redraw()

func _apply_widths() -> void:
	for l in [_l_outline, _l_fill, _l_top, _p_outline, _p_fill]:
		if l != null:
			l.width = _cell * float(l.get_meta("w_frac"))

func set_path(points: PackedVector2Array) -> void:
	_committed = points
	_l_outline.points = _committed
	_l_fill.points = _committed
	_l_top.points = _committed
	_rebuild_arc()
	if _dash_layer != null:
		_dash_layer.queue_redraw()

func set_preview(points: PackedVector2Array) -> void:
	_preview = points
	_p_outline.points = _preview
	_p_fill.points = _preview
	_show_preview(true)

func clear_preview() -> void:
	_show_preview(false)

func set_chevrons_visible(v: bool) -> void:
	_chevrons_visible = v
	if _dash_layer != null:
		_dash_layer.visible = v
		_dash_layer.queue_redraw()

func _rebuild_arc() -> void:
	_cum = PackedFloat32Array()
	_total_len = 0.0
	var n := _committed.size()
	if n < 2:
		return
	_cum.resize(n)
	_cum[0] = 0.0
	for i in range(1, n):
		_total_len += _committed[i - 1].distance_to(_committed[i])
		_cum[i] = _total_len

func _paint_dashes(c: CanvasItem) -> void:
	if not _chevrons_visible or _total_len <= 0.0 or _committed.size() < 2:
		return
	var dash_len: float = DASH_LEN_TILES * _cell
	var period: float = (DASH_LEN_TILES + DASH_GAP_TILES) * _cell
	var width: float = DASH_WIDTH_FRAC * _cell
	var s: float = fposmod(_arc_offset, period) - period
	while s < _total_len:
		var a: float = maxf(s, 0.0)
		var b: float = minf(s + dash_len, _total_len)
		if b > a:
			c.draw_polyline(_dash_points(a, b), DASH_COLOR, width, true)
		s += period

func _dash_points(a: float, b: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(_sample_pos(a))
	for k in range(_committed.size()):
		var cm: float = _cum[k]
		if cm > a and cm < b:
			pts.append(_committed[k])
	pts.append(_sample_pos(b))
	return pts

func _sample_pos(s: float) -> Vector2:
	var k := _seg_at(s)
	var seg_len := _cum[k + 1] - _cum[k]
	var t: float = 0.0 if seg_len <= 0.0 else (s - _cum[k]) / seg_len
	return _committed[k].lerp(_committed[k + 1], t)

func _seg_at(s: float) -> int:
	var n := _committed.size()
	for k in range(n - 1):
		if s <= _cum[k + 1]:
			return k
	return n - 2

func _show_preview(on: bool) -> void:
	if _p_outline != null: _p_outline.visible = on
	if _p_fill != null:    _p_fill.visible = on

static func cells_to_world(cells: Array, cell_size: float, origin: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c in cells:
		out.append(origin + Vector2((c.x + 0.5) * cell_size, (c.y + 0.5) * cell_size))
	return out
