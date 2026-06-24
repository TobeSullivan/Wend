extends Node2D
class_name BuildGuide

const GridScript := preload("res://scripts/grid.gd")
const FOOTPRINT_TEX := preload("res://assets/towers/arrow_box_loaded.png")
const FOOTPRINT_SCALE := 0.12

const DASH := 9.0
const GAP := 6.0
const BORDER_INSET := 3.0
const DASH_COLOR := Color(0.68, 0.93, 1.0, 0.95)
const FOOTPRINT_MODULATE := Color(0.6, 1.0, 0.6, 0.4)

var build_controller

var _prompts: Array = []
var _footprints: Dictionary = {}
var _suggested: Dictionary = {}

func _ready() -> void:
	z_index = -40

func set_prompts(cells: Array) -> void:
	clear()
	for c in cells:
		_suggested[c] = true
		if build_controller != null and build_controller._tower_at_cell(c) != null:
			continue
		_prompts.append(c)
		var fp := Sprite2D.new()
		fp.texture = FOOTPRINT_TEX
		fp.scale = Vector2(FOOTPRINT_SCALE, FOOTPRINT_SCALE)
		fp.modulate = FOOTPRINT_MODULATE
		fp.position = GridScript.cell_to_world(c)
		add_child(fp)
		_footprints[c] = fp
	queue_redraw()

func clear() -> void:
	for c in _footprints:
		var fp = _footprints[c]
		if is_instance_valid(fp):
			fp.queue_free()
	_footprints.clear()
	_prompts.clear()
	_suggested.clear()
	queue_redraw()

func has_prompts() -> bool:
	return not _prompts.is_empty()

func refresh() -> void:
	if build_controller == null:
		return
	for t in build_controller.towers:
		if is_instance_valid(t) and not _suggested.has(t.grid_cell):
			clear()
			return
	var still: Array = []
	var changed := false
	for c in _prompts:
		if build_controller._tower_at_cell(c) != null:
			changed = true
			var fp = _footprints.get(c)
			if fp != null and is_instance_valid(fp):
				fp.queue_free()
			_footprints.erase(c)
		else:
			still.append(c)
	if changed:
		_prompts = still
		queue_redraw()

func _on_towers_changed(_count: int, _cap: int) -> void:
	refresh()

func _draw() -> void:
	var t := float(GridScript.TILE_SIZE)
	var half := t * 0.5
	var size := t - 2.0 * BORDER_INSET
	for c in _prompts:
		var center: Vector2 = GridScript.cell_to_world(c)
		var tl := center - Vector2(half, half) + Vector2(BORDER_INSET, BORDER_INSET)
		_dashed_rect(tl, size)

func _dashed_rect(tl: Vector2, size: float) -> void:
	var top_right := tl + Vector2(size, 0)
	var br := tl + Vector2(size, size)
	var bl := tl + Vector2(0, size)
	_dashed_line(tl, top_right)
	_dashed_line(top_right, br)
	_dashed_line(br, bl)
	_dashed_line(bl, tl)

func _dashed_line(a: Vector2, b: Vector2) -> void:
	var delta := b - a
	var length := delta.length()
	if length <= 0.0:
		return
	var dir := delta / length
	var pos := 0.0
	while pos < length:
		var seg_end := minf(pos + DASH, length)
		draw_line(a + dir * pos, a + dir * seg_end, DASH_COLOR, 2.0)
		pos = seg_end + GAP
