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

# === Wooden art theme (StyleBoxTexture nine-patch). All helpers fall back to the flat
# styles above if a texture is missing, so the UI never depends on the art being present.

const TEX_DIR := "res://assets/ui/"

static func _tex(path: String) -> Texture2D:
	var full := TEX_DIR + path
	if ResourceLoader.exists(full):
		return load(full)
	return null

static func _texbox(path: String, l: int, r: int, t: int, b: int) -> StyleBoxTexture:
	var tex := _tex(path)
	if tex == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = l
	sb.texture_margin_right = r
	sb.texture_margin_top = t
	sb.texture_margin_bottom = b
	return sb

# --- Panels (named wrappers; each falls back to a flat style) ---

# Top/bottom margins are kept SMALL on purpose: a StyleBoxTexture's min size is
# texture_margin_top + texture_margin_bottom, and if that exceeds the bar height the
# panel overflows onto the board. Side margins stay large (the plank ends are the
# detailed part that must not stretch).
static func apply_top_bar(p: Control) -> void:
	var sb := _texbox("panels/top_edge.png", 140, 140, 22, 28)
	if sb == null:
		apply_bar(p)
	else:
		# content_margin (child padding) defaults to the texture_margin — keep it SMALL
		# vertically so the bar height tracks the content, not the chunky plank lip.
		sb.content_margin_left = 28
		sb.content_margin_right = 24
		sb.content_margin_top = 4
		sb.content_margin_bottom = 8
		p.add_theme_stylebox_override("panel", sb)

static func apply_bottom_strip(p: Control) -> void:
	var sb := _texbox("panels/horizontal_strip.png", 130, 130, 30, 30)
	if sb == null:
		apply_bar(p)
	else:
		sb.content_margin_left = 28
		sb.content_margin_right = 28
		sb.content_margin_top = 6
		sb.content_margin_bottom = 10
		p.add_theme_stylebox_override("panel", sb)

static func apply_drawer(p: Control) -> void:
	var sb := _texbox("panels/right_edge.png", 80, 60, 120, 120)
	if sb == null:
		apply_panel(p, 0)
	else:
		p.add_theme_stylebox_override("panel", sb)

static func apply_minimap(p: Control) -> void:
	var sb := _texbox("panels/left_edge.png", 60, 80, 120, 120)
	if sb == null:
		apply_panel(p, 0)
	else:
		p.add_theme_stylebox_override("panel", sb)

# --- Buttons ---

# Long wooden plank button (Start / Build / Sell / upgrade rows). `color` picks the
# tinted variant (green/grey/red/blue). Falls back to the flat accent if missing.
static func style_wood_button(b: Button, color: String = "blue") -> void:
	var sb := _texbox("buttons/long_%s.png" % color, 80, 80, 40, 40)
	if sb == null:
		style_primary_button(b)
		return
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", sb)
	var hover: StyleBoxTexture = sb.duplicate()
	hover.modulate_color = Color(1.12, 1.12, 1.12)
	b.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxTexture = sb.duplicate()
	pressed.modulate_color = Color(0.85, 0.85, 0.85)
	b.add_theme_stylebox_override("pressed", pressed)
	var disabled: StyleBoxTexture = sb.duplicate()
	disabled.modulate_color = Color(0.65, 0.65, 0.65, 0.75)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04))
	b.add_theme_constant_override("outline_size", 4)

# Round wooden icon button (Pause / Speed / close). Sets the plank as background and
# the glyph as the button icon. `icon_px` is the icon's drawn square size.
static func style_round_button(b: Button, icon_name: String, color: String = "grey", icon_px: int = 40) -> void:
	var sb := _texbox("buttons/round_%s.png" % color, 0, 0, 0, 0)
	if sb != null:
		b.add_theme_stylebox_override("normal", sb)
		var hover: StyleBoxTexture = sb.duplicate()
		hover.modulate_color = Color(1.12, 1.12, 1.12)
		b.add_theme_stylebox_override("hover", hover)
		var pressed: StyleBoxTexture = sb.duplicate()
		pressed.modulate_color = Color(0.85, 0.85, 0.85)
		b.add_theme_stylebox_override("pressed", pressed)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ic := _tex("icons/%s.png" % icon_name)
	if ic != null:
		b.icon = ic
		b.text = ""
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", icon_px)

static func icon_texture(icon_name: String) -> Texture2D:
	return _tex("icons/%s.png" % icon_name)

# ============================================================================
# Mockup flat theme (maze_battle_td_mockup.html) — floating rounded pills, chips,
# dock, and control buttons over a full-bleed battlefield. Replaces the wood bars.
# ============================================================================

# Pill / panel base colours (gradient midpoints from the mockup).
const PILL_BG := Color("323d2c")
const PILL_BORDER := Color("1a2012")
const PILL_GOLD := Color("b38e2c")
const PILL_GOLD_BORDER := Color("5e4710")
const CHIP_BG := Color("39402c")
const CHIP_BORDER := Color("23170d")
const START_BG := Color("5fbe38")
const START_BORDER := Color("2c5a18")
const UP_BG := Color("6fae3a")
const SELL_BG := Color("b04a2a")
const DOCK_BG := Color("2a3322")
const DOCK_BORDER := Color("161c0f")
const LABEL_COL := Color("b9c7a4")
const STAT_BG := Color(0, 0, 0, 0.22)

static func _flat(bg: Color, corner: int, border_col: Color, border_w: int, shadow := true, pad_h := 0, pad_v := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(corner)
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.border_width_bottom = border_w + 2  # subtle bevel
	if pad_h > 0:
		sb.content_margin_left = pad_h
		sb.content_margin_right = pad_h
	if pad_v > 0:
		sb.content_margin_top = pad_v
		sb.content_margin_bottom = pad_v
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.42)
		sb.shadow_size = 7
		sb.shadow_offset = Vector2(0, 5)
	return sb

static func pill_box(gold := false) -> StyleBoxFlat:
	if gold:
		return _flat(PILL_GOLD, 16, PILL_GOLD_BORDER, 2)
	return _flat(PILL_BG, 16, PILL_BORDER, 2)

# Apply a button look from a base bg colour, with hover (lighter) / pressed (darker).
# pad_h/pad_v add internal padding so text/icons aren't squished against the edges.
static func style_flat_button(b: Button, bg: Color, corner: int, border_col: Color, border_w := 2, shadow := true, pad_h := 16, pad_v := 9) -> void:
	b.add_theme_stylebox_override("normal", _flat(bg, corner, border_col, border_w, shadow, pad_h, pad_v))
	b.add_theme_stylebox_override("hover", _flat(bg.lightened(0.10), corner, border_col, border_w, shadow, pad_h, pad_v))
	b.add_theme_stylebox_override("pressed", _flat(bg.darkened(0.14), corner, border_col, border_w, shadow, pad_h, pad_v))
	b.add_theme_stylebox_override("disabled", _flat(bg.darkened(0.35), corner, border_col, border_w, false, pad_h, pad_v))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	b.add_theme_constant_override("outline_size", 3)

static func stat_box() -> StyleBoxFlat:
	return _flat(STAT_BG, 10, Color(0, 0, 0, 0), 0, false)

static func dock_box() -> StyleBoxFlat:
	return _flat(DOCK_BG, 18, DOCK_BORDER, 2)

# Small inline status icon for the top bar (coin / heart / timer / medal).
static func icon_rect(icon_name: String, px: int) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = _tex("icons/%s.png" % icon_name)
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr
