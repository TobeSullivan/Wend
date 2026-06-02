extends Control
class_name MinimapTile

# One board's thumbnail in the PVP arena minimap. Draws a schematic of the board
# (outline, entry/exit, checkpoints, and every tower as a color-modulated cell —
# so a heavily-built kill zone reads as a dark cluster, exactly as it does on the
# real board). Fog-of-war is applied by the panel via the `fogged`/`seen` flags:
#   - seen == false           → solid fog with a "?" (never observed this board)
#   - fogged == true          → schematic of the last-seen build, dimmed under fog
#   - fogged == false         → clear (the board is visible to you right now)
# Used both as a small grid tile and as the large click-to-focus panel.

signal clicked(index: int)

var index: int = 0
var grid_size: Vector2i = Vector2i(40, 22)
var entry: Vector2i = Vector2i.ZERO
var exit_cell: Vector2i = Vector2i.ZERO
var checkpoints: Array = []
var snapshot: Array = []      # [{cell: Vector2i, color: Color}]
var header: String = ""
var subhdr: String = ""
var fogged: bool = false
var seen: bool = false
var selected: bool = false
var eliminated: bool = false

const HEADER_H := 18.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", index)
		accept_event()

func _draw() -> void:
	var sz := size
	var font := get_theme_default_font()
	var fs := 11 if sz.y < 160 else 16

	# Frame + header band.
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.05, 0.06, 0.09, 0.93), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(sz.x, HEADER_H if sz.y < 160 else 26.0)), Color(0.12, 0.14, 0.2, 0.96), true)
	var head_h: float = HEADER_H if sz.y < 160 else 26.0
	draw_string(font, Vector2(6, head_h - 5), header, HORIZONTAL_ALIGNMENT_LEFT, sz.x * 0.5, fs, Color(0.85, 0.9, 1.0))
	if subhdr != "":
		# Right-align within the full tile width — a -1 width does NOT right-align,
		# which is why opponents' lives were invisible.
		var sub_col := Color(1.0, 0.5, 0.5) if eliminated else Color(0.6, 1.0, 0.6)
		draw_string(font, Vector2(0, head_h - 5), subhdr, HORIZONTAL_ALIGNMENT_RIGHT, sz.x - 6, fs, sub_col)

	var area := Rect2(Vector2(4, head_h + 3), Vector2(sz.x - 8, sz.y - head_h - 7))
	draw_rect(area, Color(0.11, 0.17, 0.13, 1.0), true)  # grass base

	if not seen:
		draw_rect(area, Color(0.2, 0.22, 0.26, 0.97), true)
		draw_string(font, area.position + Vector2(area.size.x / 2.0 - 5, area.size.y / 2.0 + 6), "?",
			HORIZONTAL_ALIGNMENT_LEFT, -1, int(min(area.size.y * 0.4, 28.0)), Color(0.55, 0.6, 0.68))
	else:
		_draw_schematic(area)
		if fogged:
			# Translucent fog over the last-seen remnants (build-phase view).
			draw_rect(area, Color(0.46, 0.49, 0.56, 0.58), true)

	if eliminated:
		draw_rect(area, Color(0.3, 0.0, 0.0, 0.42), true)
		draw_line(area.position, area.position + area.size, Color(1, 0.35, 0.35, 0.9), 2.0)
		draw_line(area.position + Vector2(area.size.x, 0), area.position + Vector2(0, area.size.y), Color(1, 0.35, 0.35, 0.9), 2.0)

	var border := Color(1.0, 0.85, 0.3, 1.0) if selected else Color(0.3, 0.34, 0.42, 1.0)
	draw_rect(Rect2(Vector2.ZERO, sz), border, false, 2.0 if selected else 1.0)

func _draw_schematic(area: Rect2) -> void:
	var gx := area.size.x / float(grid_size.x)
	var gy := area.size.y / float(grid_size.y)
	# Entry (green), exit (red), checkpoints (gold).
	_dot(area, gx, gy, entry, Color(0.5, 0.95, 0.5), 2.2)
	_dot(area, gx, gy, exit_cell, Color(0.95, 0.5, 0.5), 2.2)
	for cp in checkpoints:
		_dot(area, gx, gy, cp, Color(0.95, 0.85, 0.4), 1.8)
	# Towers as filled, color-modulated cells.
	var cw: float = maxf(1.5, gx)
	var ch: float = maxf(1.5, gy)
	for t in snapshot:
		var cell: Vector2i = t.cell
		var col: Color = t.color
		draw_rect(Rect2(area.position + Vector2(cell.x * gx, cell.y * gy), Vector2(cw, ch)), col, true)

func _dot(area: Rect2, gx: float, gy: float, cell: Vector2i, col: Color, r: float) -> void:
	draw_circle(area.position + Vector2((cell.x + 0.5) * gx, (cell.y + 0.5) * gy), r, col)
