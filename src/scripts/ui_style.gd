extends Node

# Shared in-match UI look so the frame (top bar / rail / dock) and the modal panels
# read as one design: dark translucent panels with a subtle border, a flat top bar,
# and an accent style for primary buttons. Consumers preload and call the statics.

# Opaque — the board is reserved out of the frame, so panels must NOT let the grass
# (or anything) show through; translucency read as "UI floating on the board".
const BG := Color(0.07, 0.09, 0.13, 1.0)
const BG_BAR := Color(0.09, 0.11, 0.16, 1.0)
const BORDER := Color(0.24, 0.30, 0.42, 1.0)
const ACCENT := Color(0.24, 0.50, 0.92)
const ACCENT_HI := Color(0.36, 0.62, 1.0)

static func panel_style(corner: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.border_color = BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(corner)
	return sb

static func bar_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_BAR
	sb.border_color = BORDER
	sb.border_width_bottom = 2
	return sb

static func apply_panel(p: Control, corner: int = 10) -> void:
	p.add_theme_stylebox_override("panel", panel_style(corner))

static func apply_bar(p: Control) -> void:
	p.add_theme_stylebox_override("panel", bar_style())

# Accent fill for the most important buttons (Build / Start Round).
static func style_primary_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _btn(ACCENT))
	b.add_theme_stylebox_override("hover", _btn(ACCENT_HI))
	b.add_theme_stylebox_override("pressed", _btn(ACCENT.darkened(0.2)))
	b.add_theme_stylebox_override("disabled", _btn(Color(0.2, 0.23, 0.3, 0.8)))
	b.add_theme_color_override("font_color", Color.WHITE)

static func _btn(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb
