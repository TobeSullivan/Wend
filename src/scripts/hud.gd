extends CanvasLayer
class_name HUD

# Floating HUD pills (mockup maze_battle_td_mockup.html), overlaid on the full-bleed
# battlefield — they reserve no space. Top-left: Round + phase/timer pills. Top-right:
# gold, kills, score (+ next medal) pills; lives pill in PVP. Untyped refs avoid the
# class-name cycle pitfall.

const UiLayout := preload("res://scripts/ui_layout.gd")
const UiStyle := preload("res://scripts/ui_style.gd")
const TOWER_ICON := preload("res://assets/towers/arrow_box_loaded.png")

var round_manager  # RoundManager
var build_controller  # BuildController

var _round_val: Label
var _phase_val: Label
var _gold_val: Label
var _kills_val: Label
var _score_val: Label
var _score_medal_lab: Label
var _medal_icon: TextureRect
var _lives_pill: Control
var _lives_val: Label
var _supply_val: Label

var _towers_count: int = 0
var _towers_cap: int = 0

func _ready() -> void:
	layer = 6
	var s := UiLayout.scale_factor()

	# --- Top-left cluster: Round + phase ---
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", int(10 * s))
	left.position = Vector2(16, 16) * s
	add_child(left)
	var round_pill := _pill(false)
	_label(round_pill, "ROUND", true)
	_round_val = _label(round_pill, "—", false)
	left.add_child(round_pill["root"])
	var phase_pill := _pill(true)
	_icon(phase_pill, "timer", Color("2a2008"))
	_phase_val = _label(phase_pill, "—", false, Color("2a2008"))
	left.add_child(phase_pill["root"])
	var supply_pill := _pill(false)
	_tex_icon(supply_pill, TOWER_ICON, int(26 * s))
	_supply_val = _label(supply_pill, "0 / 0", false)
	left.add_child(supply_pill["root"])

	# --- Top-right cluster: gold / kills / score (+ lives in PVP) ---
	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", int(10 * s))
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.offset_top = 16 * s
	right.offset_right = -16 * s
	add_child(right)

	var lives_pill := _pill(false)
	_icon(lives_pill, "heart")
	_lives_val = _label(lives_pill, "0", false)
	_lives_pill = lives_pill["root"]
	_lives_pill.visible = false
	right.add_child(_lives_pill)

	var gold_pill := _pill(false)
	_icon(gold_pill, "coin")
	_gold_val = _label(gold_pill, "0", false, Color("ffe98c"))
	right.add_child(gold_pill["root"])

	var kills_pill := _pill(false)
	_label(kills_pill, "KILLS", true)
	_kills_val = _label(kills_pill, "0", false)
	right.add_child(kills_pill["root"])

	var score_pill := _pill(false)
	_medal_icon = _icon(score_pill, "medal_bronze")
	_label(score_pill, "SCORE", true)
	_score_val = _label(score_pill, "0", false)
	_score_medal_lab = _label(score_pill, "", true, Color("e0a55a"))
	right.add_child(score_pill["root"])

	if round_manager != null:
		round_manager.gold_changed.connect(func(_g): _refresh())
		round_manager.round_changed.connect(func(_r): _refresh())
		round_manager.phase_changed.connect(func(_p): _refresh())
		round_manager.build_timer_changed.connect(func(_t): _refresh())
		round_manager.damage_dealt_changed.connect(func(_d): _refresh())
		round_manager.kills_changed.connect(func(_k): _refresh())
	if build_controller != null:
		build_controller.towers_changed.connect(_on_towers_changed)
		_towers_count = build_controller.towers.size()
		_towers_cap = build_controller.max_towers
	_refresh()

# Build a pill: PanelContainer ("root") → margin → HBox ("hb" for content).
func _pill(gold: bool) -> Dictionary:
	var s := UiLayout.scale_factor()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.pill_box(gold))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", int(15 * s))
	m.add_theme_constant_override("margin_right", int(15 * s))
	m.add_theme_constant_override("margin_top", int(8 * s))
	m.add_theme_constant_override("margin_bottom", int(8 * s))
	panel.add_child(m)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", int(9 * s))
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(hb)
	return {"root": panel, "hb": hb}

func _icon(pill: Dictionary, name: String, _modulate := Color.WHITE) -> TextureRect:
	var s := UiLayout.scale_factor()
	var tr := UiStyle.icon_rect(name, int(24 * s))
	if _modulate != Color.WHITE:
		tr.modulate = _modulate
	(pill["hb"] as HBoxContainer).add_child(tr)
	return tr

func _tex_icon(pill: Dictionary, tex: Texture2D, px: int) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(pill["hb"] as HBoxContainer).add_child(tr)
	return tr

func _label(pill: Dictionary, text: String, is_lab: bool, col := Color.WHITE) -> Label:
	var s := UiLayout.scale_factor()
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_lab:
		l.add_theme_font_size_override("font_size", int(12 * s))
		l.add_theme_color_override("font_color", col if col != Color.WHITE else UiStyle.LABEL_COL)
	else:
		l.add_theme_font_size_override("font_size", int(23 * s))
		l.add_theme_color_override("font_color", col)
	(pill["hb"] as HBoxContainer).add_child(l)
	return l

func _on_towers_changed(count: int, cap: int) -> void:
	_towers_count = count
	_towers_cap = cap
	_refresh()

func _is_pvp() -> bool:
	return round_manager != null and round_manager.coordinator != null and round_manager.coordinator.is_pvp

func _refresh() -> void:
	if round_manager == null:
		return
	if _is_pvp():
		_round_val.text = "%d" % round_manager.round_num
		_lives_pill.visible = true
		_lives_val.text = "%d" % round_manager.lives
	else:
		_round_val.text = "%d / %d" % [round_manager.round_num, round_manager.max_rounds]
		_lives_pill.visible = false
	_gold_val.text = "%d" % round_manager.gold
	_kills_val.text = "%d" % round_manager.total_kills
	_supply_val.text = "%d / %d" % [_towers_count, _towers_cap]
	if round_manager.match_over:
		_phase_val.text = "ENDED"
	elif round_manager.phase == "build":
		_phase_val.text = "BUILD  %d:%02d" % [int(round_manager.build_time_left) / 60, int(round_manager.build_time_left) % 60]
	else:
		_phase_val.text = "RUN"
	_refresh_score()

func _refresh_score() -> void:
	var dmg: int = round_manager.total_damage_dealt
	_score_val.text = _commas(dmg)
	if round_manager.gold_threshold <= 0:
		_score_medal_lab.text = ""
		_medal_icon.visible = false
		return
	_medal_icon.visible = true
	var tier := "gold"
	var nextv := int(round_manager.gold_threshold)
	if dmg < int(round_manager.bronze_threshold):
		tier = "bronze"; nextv = int(round_manager.bronze_threshold)
	elif dmg < int(round_manager.silver_threshold):
		tier = "silver"; nextv = int(round_manager.silver_threshold)
	elif dmg < int(round_manager.gold_threshold):
		tier = "gold"; nextv = int(round_manager.gold_threshold)
	else:
		_score_medal_lab.text = "★ GOLD"
		_medal_icon.texture = UiStyle.icon_texture("medal_gold")
		return
	_medal_icon.texture = UiStyle.icon_texture("medal_%s" % tier)
	_score_medal_lab.text = "→%s %s" % [tier.capitalize(), _commas(nextv)]

func _commas(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out
