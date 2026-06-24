extends Node2D
class_name RoadRenderer

@export var road_color: Color = Color("c9a93f")
@export var outline_color: Color = Color("2e2a14")
@export var highlight_color: Color = Color("e2c45a")
@export var outline_w_frac: float = 1.04
@export var fill_w_frac: float = 0.84
@export var highlight_w_frac: float = 0.58
@export_range(0.0, 1.0) var preview_alpha: float = 0.45

const CHEV_SPACING_TILES := 1.5
const CHEV_TILES_PER_SEC := 2.0
const CHEV_HEIGHT_TILES := 0.4
const GLOW_SCALE := 1.30
const GLOW_ALPHA := 0.5

var _cell: float = 64.0
var _committed := PackedVector2Array()
var _preview := PackedVector2Array()

var _chev_tex: Texture2D
var _glow_tex: Texture2D
var _add_mat: CanvasItemMaterial
var _markers: Array = []
var _active_count: int = 0
var _cum := PackedFloat32Array()
var _total_len: float = 0.0
var _arc_offset: float = 0.0
var _chevrons_visible: bool = true

var _l_outline: Line2D
var _l_fill: Line2D
var _l_top: Line2D
var _p_outline: Line2D
var _p_fill: Line2D

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
	_chev_tex = _make_chevron_tex()
	_glow_tex = _make_glow_tex()
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_apply_widths()

func _process(delta: float) -> void:
	if not _chevrons_visible or _active_count <= 0 or _total_len <= 0.0:
		return
	_arc_offset = fposmod(_arc_offset + delta * CHEV_TILES_PER_SEC * _cell, _total_len)
	_layout_markers()

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
	for m in _markers:
		_scale_marker(m)

func _apply_widths() -> void:
	for l in [_l_outline, _l_fill, _l_top, _p_outline, _p_fill]:
		if l != null:
			l.width = _cell * float(l.get_meta("w_frac"))

func _make_marker() -> Node2D:
	var m := Node2D.new()
	m.z_index = 5
	var glow := Sprite2D.new()
	glow.texture = _glow_tex
	glow.material = _add_mat
	glow.modulate = Color(1, 1, 1, GLOW_ALPHA)
	m.add_child(glow)
	var chev := Sprite2D.new()
	chev.texture = _chev_tex
	m.add_child(chev)
	m.set_meta("glow", glow)
	m.set_meta("chev", chev)
	add_child(m)
	_scale_marker(m)
	return m

func _scale_marker(m: Node2D) -> void:
	var chev: Sprite2D = m.get_meta("chev")
	var glow: Sprite2D = m.get_meta("glow")
	var s: float = (CHEV_HEIGHT_TILES * _cell) / float(_chev_tex.get_height())
	chev.scale = Vector2(s, s)
	glow.scale = Vector2(s * GLOW_SCALE, s * GLOW_SCALE)

func set_path(points: PackedVector2Array) -> void:
	_committed = points
	_l_outline.points = _committed
	_l_fill.points = _committed
	_l_top.points = _committed
	_rebuild_arc()
	_size_pool()
	_layout_markers()

func set_preview(points: PackedVector2Array) -> void:
	_preview = points
	_p_outline.points = _preview
	_p_fill.points = _preview
	_show_preview(true)

func clear_preview() -> void:
	_show_preview(false)

func set_chevrons_visible(v: bool) -> void:
	_chevrons_visible = v
	for i in range(_markers.size()):
		_markers[i].visible = v and i < _active_count

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

func _size_pool() -> void:
	var spacing := CHEV_SPACING_TILES * _cell
	var n := 0
	if _total_len > 0.0 and spacing > 0.0:
		n = maxi(1, int(round(_total_len / spacing)))
	_active_count = n
	while _markers.size() < n:
		_markers.append(_make_marker())
	for i in range(_markers.size()):
		_markers[i].visible = _chevrons_visible and i < n

func _layout_markers() -> void:
	if _active_count <= 0 or _total_len <= 0.0:
		return
	var step := _total_len / float(_active_count)
	for i in range(_active_count):
		var s := fposmod(_arc_offset + i * step, _total_len)
		var m: Node2D = _markers[i]
		m.position = _sample_pos(s)
		m.rotation = _sample_dir(s).angle()

func _sample_pos(s: float) -> Vector2:
	var k := _seg_at(s)
	var seg := _committed[k + 1] - _committed[k]
	var seg_len := _cum[k + 1] - _cum[k]
	var t: float = 0.0 if seg_len <= 0.0 else (s - _cum[k]) / seg_len
	return _committed[k].lerp(_committed[k + 1], t)

func _sample_dir(s: float) -> Vector2:
	var k := _seg_at(s)
	var d := _committed[k + 1] - _committed[k]
	return d.normalized() if d.length() > 0.0 else Vector2.RIGHT

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

func _make_chevron_tex() -> ImageTexture:
	var w := 64
	var h := 56
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var fill := Color("d9531e")
	var edge := Color("4a3a16")
	var cx := w * 0.5
	var tip := Vector2(cx + h * 0.22, h * 0.5)
	var top := Vector2(cx - h * 0.16, h * 0.20)
	var bot := Vector2(cx - h * 0.16, h * 0.80)
	var fill_half := h * 0.15
	var edge_w := h * 0.05
	for y in range(h):
		for x in range(w):
			var p := Vector2(x + 0.5, y + 0.5)
			var d: float = min(_dist_to_seg(p, top, tip), _dist_to_seg(p, tip, bot))
			if d <= fill_half:
				img.set_pixel(x, y, fill)
			elif d <= fill_half + edge_w:
				img.set_pixel(x, y, edge)
	return ImageTexture.create_from_image(img)

func _make_glow_tex() -> ImageTexture:
	var w := 64
	var h := 56
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var glow := Color("ffbf45")
	var cx := w * 0.5
	var tip := Vector2(cx + h * 0.22, h * 0.5)
	var top := Vector2(cx - h * 0.16, h * 0.20)
	var bot := Vector2(cx - h * 0.16, h * 0.80)
	var radius := h * 0.34
	for y in range(h):
		for x in range(w):
			var p := Vector2(x + 0.5, y + 0.5)
			var d: float = min(_dist_to_seg(p, top, tip), _dist_to_seg(p, tip, bot))
			var a: float = pow(clampf(1.0 - d / radius, 0.0, 1.0), 2.0)
			if a > 0.0:
				img.set_pixel(x, y, Color(glow.r, glow.g, glow.b, a))
	return ImageTexture.create_from_image(img)

func _dist_to_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	var t := 0.0
	if denom > 0.0:
		t = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)
