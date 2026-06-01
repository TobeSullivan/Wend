extends CanvasLayer
class_name MatchEndPanel

# End-of-match panel, bound to the local board. Three modes:
#   - medal: campaign / solo PVE — medal + thresholds + Return Home / Play Again
#   - pvp_final: PVP match over — your placement + Find New Match / Return Home
#   - pvp_eliminated: local board knocked out mid-match — placement + Spectate /
#     Quit to Menu (the match keeps running; the player can watch via the camera)

var round_manager  # RoundManager (local board) — untyped to avoid class-name cycle

var _panel: PanelContainer
var _title_label: Label
var _result_label: Label
var _detail_label: Label
var _thresholds_vbox: VBoxContainer
var _buttons_vbox: VBoxContainer

const MEDAL_COLORS := {
	"gold":   Color(1.0, 0.85, 0.2),
	"silver": Color(0.85, 0.85, 0.9),
	"bronze": Color(0.85, 0.55, 0.25),
	"none":   Color(0.7, 0.7, 0.7),
}
const MEDAL_LABELS := {
	"gold": "GOLD", "silver": "SILVER", "bronze": "BRONZE", "none": "No medal — try again",
}

func _ready() -> void:
	layer = 20
	_build_ui()
	_panel.visible = false
	if round_manager != null:
		round_manager.match_ended.connect(_on_match_ended)
		var coord = round_manager.coordinator
		if coord != null and coord.is_pvp:
			coord.board_eliminated.connect(_on_board_eliminated)

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -240
	_panel.offset_right = 240
	_panel.offset_top = -220
	_panel.offset_bottom = 220
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_title_label = _make_label(28, Color.WHITE)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	_result_label = _make_label(32, Color.WHITE)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_label)

	_detail_label = _make_label(20, Color.WHITE)
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_detail_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_thresholds_vbox = VBoxContainer.new()
	_thresholds_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(_thresholds_vbox)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	_buttons_vbox = VBoxContainer.new()
	_buttons_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(_buttons_vbox)

# --- Mode entry points ---

func _on_match_ended() -> void:
	var coord = round_manager.coordinator
	if coord != null and coord.is_pvp:
		_show_pvp_final(coord)
	else:
		_show_medal()

func _on_board_eliminated(board) -> void:
	var coord = round_manager.coordinator
	# Only react to the LOCAL board's elimination, and not once the match is over
	# (the final panel takes precedence then).
	if board != round_manager or coord == null or coord.match_over:
		return
	var placement: int = coord.placement_of(round_manager)
	_title_label.text = "Eliminated"
	_result_label.text = "%s of %d" % [_ordinal(placement), coord.boards.size()]
	_result_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	_detail_label.text = "Your lives ran out. The match continues."
	_thresholds_vbox.visible = false
	_set_buttons([
		{"text": "Spectate", "cb": _hide_panel},
		{"text": "Quit to Menu", "cb": _on_return_home},
	])
	_panel.visible = true

func _show_pvp_final(coord) -> void:
	var placement: int = coord.placement_of(round_manager)
	var won := placement == 1
	_title_label.text = "Victory!" if won else "Match Over"
	_result_label.text = "1st — Last Standing" if won else "%s of %d" % [_ordinal(placement), coord.boards.size()]
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if won else Color.WHITE)
	_detail_label.text = "Kills: %d" % round_manager.total_kills
	_thresholds_vbox.visible = false
	_set_buttons([
		{"text": "Find New Match", "cb": _on_find_new_match},
		{"text": "Return Home", "cb": _on_return_home},
	])
	_panel.visible = true

func _show_medal() -> void:
	var damage: int = round_manager.total_damage_dealt
	var medal: String = round_manager.medal_for(damage)
	_title_label.text = "Match Complete"
	_result_label.text = MEDAL_LABELS[medal]
	_result_label.add_theme_color_override("font_color", MEDAL_COLORS[medal])
	_detail_label.text = "Total damage: %d  ·  Rounds: %d" % [damage, round_manager.max_rounds]
	_thresholds_vbox.visible = true
	_populate_thresholds(damage)
	_set_buttons([
		{"text": "Return Home", "cb": _on_return_home},
		{"text": "Play Again", "cb": _on_play_again},
	])
	_panel.visible = true
	# Persist the result (campaign medal / PVE score).
	SceneManager.report_match_result(damage)

# --- Helpers ---

func _set_buttons(specs: Array) -> void:
	for child in _buttons_vbox.get_children():
		child.queue_free()
	for spec in specs:
		var b := Button.new()
		b.text = spec["text"]
		b.custom_minimum_size = Vector2(0, 44)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(spec["cb"])
		_buttons_vbox.add_child(b)

func _populate_thresholds(damage: int) -> void:
	for child in _thresholds_vbox.get_children():
		child.queue_free()
	_add_threshold_row("Bronze", round_manager.bronze_threshold, damage, MEDAL_COLORS.bronze)
	_add_threshold_row("Silver", round_manager.silver_threshold, damage, MEDAL_COLORS.silver)
	_add_threshold_row("Gold",   round_manager.gold_threshold,   damage, MEDAL_COLORS.gold)

func _add_threshold_row(name: String, threshold: int, achieved: int, color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var dot := _make_label(18, color)
	dot.text = "●" if achieved >= threshold else "○"
	row.add_child(dot)
	var text := _make_label(16, Color.WHITE)
	text.text = "%s: %d" % [name, threshold]
	row.add_child(text)
	_thresholds_vbox.add_child(row)

func _hide_panel() -> void:
	_panel.visible = false

func _on_return_home() -> void:
	SceneManager.goto_home()

func _on_play_again() -> void:
	SceneManager.restart_current_match()

func _on_find_new_match() -> void:
	SceneManager.start_pvp()

func _ordinal(n: int) -> String:
	if n <= 0:
		return "—"
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
	return "%d%s" % [n, suffix]

func _make_label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l
