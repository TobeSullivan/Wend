extends Node2D
class_name RoadRenderer

## Renders the live mob path as a cartoon dirt road (Bloons / Kingdom-Rush look),
## true to the orthogonal grid path but with rounded corners. Pure Line2D stack —
## NO TileSet / atlas classification — so it re-renders instantly when the maze
## re-routes (tower placed, tower sold, and the build-phase hover preview).
##
## --- WHY Line2D AND NOT THE summer_grass_path TILESET ---
## The tileset is built for STATIC authored roads. This path re-routes on every
## hover, so per-cell connectivity auto-tiling would have to reclassify the whole
## route constantly — the same per-frame churn that caused the earlier hover-overlay
## perf spike. A 3-layer Line2D through the path centres gives the flat-gold-with-
## outline look the mockup used, rounded corners for free (LINE_JOINT_ROUND), and
## costs nothing to update (set .points on change, not per frame). The tileset can
## be layered back in later if we ever want baked texture detail on the committed road.
##
## --- THIS REPLACES the old immediate-mode `_draw` dashed path overlay ---
## That overlay repainted antialiased segments EVERY frame and was the memory/perf
## sink. Delete it. Setting Line2D.points only when the path changes is strictly cheaper.
##
## --- INTEGRATION (hand to Claude Code) ---
## 1. In map_loader, per board, after the grass/grid background is built:
##        var road := RoadRenderer.new()
##        board_container.add_child(road)          # add THEN configure (configure needs _ready done)
##        road.configure(GameConstants.CELL_PX)    # pixel size of one cell
##        road.z_index = 1                          # above grass(0), below towers/mobs
##        board.road_renderer = road                # keep a ref on the board/BoardState
## 2. Wherever the committed path is recomputed (build_controller.recompute_path()
##    after place/sell, and at match start) feed it the path:
##        board.road_renderer.set_path(world_points)            # if you already have world centres
##        # or, if you have grid cells:
##        board.road_renderer.set_path(RoadRenderer.cells_to_world(path_cells, GameConstants.CELL_PX))
## 3. Build-phase hover (the handler that already computes the PROJECTED path for the
##    old dashed overlay): replace the overlay draw with:
##        board.road_renderer.set_preview(projected_world_points)   # on hover over a buildable cell
##        board.road_renderer.clear_preview()                        # on leave / after placement
##    Keep your existing ~30fps throttle on the hover recompute; set_preview itself is cheap.
## 4. Entry marker + exit flag sprites are placed separately by map_loader; the road
##    auto-extends one cell past each end (see _with_stubs) so it runs under them to the edge.

# ---- style (sampled from summer_grass_path + the approved mockup) ----
@export var road_color: Color = Color("c9a93f")
@export var outline_color: Color = Color("2e2a14")
@export var highlight_color: Color = Color("e2c45a")
# widths are FRACTIONS of the cell size, resolved at runtime in configure()
@export var outline_w_frac: float = 1.04
@export var fill_w_frac: float = 0.84
@export var highlight_w_frac: float = 0.58
@export_range(0.0, 1.0) var preview_alpha: float = 0.45

var _cell: float = 64.0
var _committed := PackedVector2Array()
var _preview := PackedVector2Array()

var _l_outline: Line2D
var _l_fill: Line2D
var _l_top: Line2D
var _l_dash: Line2D   # faint white centre dashes (direction/path hint, from the mockup)
var _p_outline: Line2D
var _p_fill: Line2D

func _ready() -> void:
	# committed road: outline (back) -> fill -> highlight (front)
	_l_outline = _make_line(outline_color, outline_w_frac, 0)
	_l_fill    = _make_line(road_color,    fill_w_frac,    1)
	_l_top     = _make_line(highlight_color, highlight_w_frac, 2)
	_l_top.default_color.a = 0.9
	# White centre-line "›" chevrons pointing toward the exit (direction markers). Solid
	# (stay visible), tiled, and scrolled along the path to animate travel direction.
	_l_dash = _make_line(Color(1, 1, 1, 0.92), 0.16, 2)
	_l_dash.texture = _make_arrow_texture()
	_l_dash.texture_mode = Line2D.LINE_TEXTURE_TILE
	_l_dash.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED  # required for the tiling to repeat
	# Scroll the chevrons along the path (entry → exit). GPU-driven via TIME — no redraw.
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform float scroll_speed = 1.1;\nvoid fragment() {\n\tvec2 uv = UV;\n\tuv.x -= TIME * scroll_speed;\n\tCOLOR *= texture(TEXTURE, uv);\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_l_dash.material = mat
	# preview road draws above the committed road, translucent
	_p_outline = _make_line(outline_color, outline_w_frac, 3)
	_p_fill    = _make_line(road_color,    fill_w_frac,    4)
	_p_outline.modulate.a = preview_alpha
	_p_fill.modulate.a = preview_alpha
	_show_preview(false)
	_apply_widths()

func _make_line(col: Color, w_frac: float, z: int) -> Line2D:
	var l := Line2D.new()
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.round_precision = 8
	l.antialiased = false  # gl_compatibility: AA polylines were the perf sink (see STATE/RULES)
	l.z_index = z
	l.set_meta("w_frac", w_frac)
	add_child(l)
	return l

## Call once after the node is in the tree. cell_size = pixel size of one grid cell.
func configure(cell_size: float) -> void:
	_cell = cell_size
	_apply_widths()

func _apply_widths() -> void:
	for l in [_l_outline, _l_fill, _l_top, _l_dash, _p_outline, _p_fill]:
		if l != null:
			l.width = _cell * float(l.get_meta("w_frac"))

# A white "›" chevron (pointing +x, toward the exit) followed by a transparent gap,
# tiled along the centre line. The texture's height maps to the road width.
func _make_arrow_texture() -> ImageTexture:
	var w := 132
	var h := 26
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var tip := Vector2(w * 0.20, h * 0.5)
	var top := Vector2(w * 0.06, h * 0.16)
	var bot := Vector2(w * 0.06, h * 0.84)
	_draw_seg(img, top, tip, 2.6)
	_draw_seg(img, tip, bot, 2.6)
	return ImageTexture.create_from_image(img)

func _draw_seg(img: Image, a: Vector2, b: Vector2, t: float) -> void:
	var steps := maxi(int(a.distance_to(b)) * 2, 1)
	for i in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		_stamp(img, int(round(p.x)), int(round(p.y)), t)

func _stamp(img: Image, cx: int, cy: int, t: float) -> void:
	var r := int(ceil(t))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if Vector2(dx, dy).length() <= t:
				var x := cx + dx
				var y := cy + dy
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, Color(1, 1, 1, 1))

# ---- public API ----

## The committed mob route. points = world-space path through cell CENTRES, in travel order.
func set_path(points: PackedVector2Array) -> void:
	_committed = _with_stubs(points)
	_l_outline.points = _committed
	_l_fill.points = _committed
	_l_top.points = _committed
	_l_dash.points = _committed

## Build-phase hover: the route the maze WOULD take if a tower were placed at the
## hovered cell. Pass the projected path the pathfinder already computes on hover.
func set_preview(points: PackedVector2Array) -> void:
	_preview = _with_stubs(points)
	_p_outline.points = _preview
	_p_fill.points = _preview
	_show_preview(true)

func clear_preview() -> void:
	_show_preview(false)

# ---- helpers ----

func _show_preview(on: bool) -> void:
	if _p_outline != null: _p_outline.visible = on
	if _p_fill != null:    _p_fill.visible = on

## Extend the road one cell past the entry and exit so it runs off the board edge
## (under the entry marker / exit flag) instead of stopping dead at a cell centre.
func _with_stubs(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var out := PackedVector2Array()
	out.append(pts[0] + (pts[0] - pts[1]).normalized() * _cell)
	out.append_array(pts)
	out.append(pts[pts.size() - 1] + (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized() * _cell)
	return out

## Convenience: convert an array of Vector2i grid cells to world-space centres.
static func cells_to_world(cells: Array, cell_size: float, origin: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	for c in cells:
		out.append(origin + Vector2((c.x + 0.5) * cell_size, (c.y + 0.5) * cell_size))
	return out
