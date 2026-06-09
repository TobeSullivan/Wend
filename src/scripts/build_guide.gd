extends Node2D
class_name BuildGuide

# Ghost-outline build guidance (design/CAMPAIGN.md "Build guidance"): a programmatic
# overlay that shows WHERE to build to form a proper maze. Each prompted cell gets a
# dashed tile highlight + a semi-transparent tower footprint. When the player builds on a
# prompted cell it clears (satisfied). No new art — it reuses the loaded-tower texture and
# draws the dashes itself. Lives in the local board's container (board/world space), under
# towers; only campaign missions create one, driven by TutorialDirector.

const GridScript := preload("res://scripts/grid.gd")
const FOOTPRINT_TEX := preload("res://assets/towers/arrow_box_loaded.png")
const FOOTPRINT_SCALE := 0.12  # matches BuildController.TOWER_SCALE

const DASH := 9.0
const GAP := 6.0
const BORDER_INSET := 3.0
const DASH_COLOR := Color(0.68, 0.93, 1.0, 0.95)      # soft "build here" cyan
const FOOTPRINT_MODULATE := Color(0.6, 1.0, 0.6, 0.4) # ghost-green, ~40% alpha

var build_controller  # BuildController — to detect when a prompted cell gets a tower

var _prompts: Array = []          # Array[Vector2i] still-prompted (unbuilt) cells
var _footprints: Dictionary = {}  # Vector2i -> Sprite2D
var _suggested: Dictionary = {}   # Vector2i -> true, the FULL prompted set (for deviation detection)

func _ready() -> void:
	z_index = -40  # above the road (-50), below towers/mobs (0)

# Prompt this exact set of cells (replaces any current prompts). A cell that already holds
# a tower is treated as satisfied immediately, so re-prompting mid-mission is safe.
func set_prompts(cells: Array) -> void:
	clear()
	for c in cells:
		_suggested[c] = true  # remember the full suggested set, including already-built cells
		if build_controller != null and build_controller._tower_at_cell(c) != null:
			continue  # already built here — nothing to prompt
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

# Re-check prompted cells against the board. A tower placed OFF the suggested maze retires
# the whole outline (design/CAMPAIGN.md "Build guidance" — once the player deviates, it's
# their maze; the guide steps back). Otherwise clear any prompted cell that now holds a tower.
func refresh() -> void:
	if build_controller == null:
		return
	for t in build_controller.towers:
		if is_instance_valid(t) and not _suggested.has(t.grid_cell):
			clear()  # deviation — the player went off-script, drop the guidance entirely
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
	var tr := tl + Vector2(size, 0)
	var br := tl + Vector2(size, size)
	var bl := tl + Vector2(0, size)
	_dashed_line(tl, tr)
	_dashed_line(tr, br)
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
