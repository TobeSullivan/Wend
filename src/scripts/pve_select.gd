extends Control

const UiStyle := preload("res://scripts/ui_style.gd")
const StarRatingScript := preload("res://scripts/star_rating.gd")
const MapGen := preload("res://scripts/map_generator.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")
const Motion := preload("res://scripts/motion.gd")

const WINDOW_SALT := {
	MapResourceScript.WindowType.DAILY: 0,
	MapResourceScript.WindowType.WEEKLY: 1_000_003,
	MapResourceScript.WindowType.MONTHLY: 2_000_003,
}
const WEEK_SECONDS := 604800.0

var _windows: Dictionary = {}
var _current: int = MapResourceScript.WindowType.DAILY

var _title: Label
var _subtitle: Label
var _list_box: VBoxContainer
var _tab_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _generate_all_windows()
	_build_background()
	_build_header()
	_build_tabs()
	_build_list_container()
	_show_window(MapResourceScript.WindowType.DAILY)

func _generate_all_windows() -> void:
	var server: Dictionary = await LeaderboardService.trials_seeds()
	for wt in [MapResourceScript.WindowType.DAILY, MapResourceScript.WindowType.WEEKLY, MapResourceScript.WindowType.MONTHLY]:
		var meta: Dictionary = _window_meta(wt)
		var server_seeds: Array = server.get(LeaderboardService.WINDOW_IDS.get(wt, ""), [])
		var base: int = hash(meta.date) + int(WINDOW_SALT[wt])
		var maps: Array = []
		for tier in range(1, 6):
			var map_seed: int = int(server_seeds[tier - 1]) if server_seeds.size() >= 5 else base + tier * 1013
			maps.append(MapGen.generate(map_seed, tier, MapResourceScript.Mode.PVE, wt, meta.date))
		_windows[wt] = maps

func _window_meta(window_type: int) -> Dictionary:
	var d := Time.get_date_dict_from_system()
	match window_type:
		MapResourceScript.WindowType.WEEKLY:
			var week := int(Time.get_unix_time_from_system() / WEEK_SECONDS)
			return {"date": "%04d-W%03d" % [d.year, week % 1000], "label": "Weekly", "sub": "Five maps, Scale 1–5. New set each week."}
		MapResourceScript.WindowType.MONTHLY:
			return {"date": "%04d-%02d" % [d.year, d.month], "label": "Monthly", "sub": "Five maps, Scale 1–5. New set each month."}
		_:
			return {"date": "%04d-%02d-%02d" % [d.year, d.month, d.day], "label": "Daily", "sub": "Five maps, Scale 1–5. New set each day. Solo run for high score."}

func _build_background() -> void:
	UiStyle.menu_backdrop(self)

func _build_header() -> void:
	_title = _label("Daily Trials", 36, Color.WHITE)
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.offset_left = 40
	_title.offset_top = 28
	add_child(_title)

	_subtitle = _label("", 16, UiStyle.LABEL_COL)
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_subtitle.offset_left = 40
	_subtitle.offset_top = 74
	add_child(_subtitle)

	var back := Button.new()
	back.text = "← Back"
	back.add_theme_font_size_override("font_size", 16)
	UiStyle.style_menu_button(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back.offset_left = -150
	back.offset_top = 28
	back.offset_right = -40
	back.offset_bottom = 68
	back.pressed.connect(func(): SceneManager.goto_home())
	add_child(back)

func _build_tabs() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 40
	row.offset_top = 108
	add_child(row)

	for wt in [MapResourceScript.WindowType.DAILY, MapResourceScript.WindowType.WEEKLY, MapResourceScript.WindowType.MONTHLY]:
		var b := Button.new()
		b.toggle_mode = true
		b.text = _window_meta(wt).label
		b.custom_minimum_size = Vector2(130, 40)
		b.add_theme_font_size_override("font_size", 16)
		UiStyle.style_tab_button(b)
		b.pressed.connect(func(): _show_window(wt))
		row.add_child(b)
		_tab_buttons[wt] = b

func _build_list_container() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 60
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 12)
	center.add_child(_list_box)

func _show_window(window_type: int) -> void:
	_current = window_type
	var meta: Dictionary = _window_meta(window_type)
	_title.text = "%s Trials" % meta.label
	_subtitle.text = meta.sub
	for wt in _tab_buttons:
		_tab_buttons[wt].button_pressed = (wt == window_type)

	for child in _list_box.get_children():
		child.queue_free()
	var cards: Array = []
	for map in _windows[window_type]:
		var c := await _map_card(map)
		_list_box.add_child(c)
		cards.append(c)
	_cascade_cards(cards)

func _cascade_cards(cards: Array) -> void:
	for c in cards:
		c.modulate.a = 0.0
	_do_cascade_cards.call_deferred(cards)

func _do_cascade_cards(cards: Array) -> void:
	for i in cards.size():
		var c: Control = cards[i]
		if not is_instance_valid(c):
			continue
		c.pivot_offset = c.size * 0.5
		var d := Motion.stagger_delay(i, cards.size(), 0.07)
		Motion.arrive_property(c, "scale", Vector2.ONE * 0.94, Vector2.ONE, Motion.M, d)
		Motion.fade_in(c, Motion.S, d)

func _map_card(map) -> Control:
	var tier: int = map.scale_tier
	var rinfo: Dictionary = await LeaderboardService.trials_rank(_current, tier)
	var best: int = int(rinfo.get("best", 0))
	var rank: int = int(rinfo.get("rank", 0))

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	UiStyle.apply_card(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	info.add_child(_label(LeaderboardService.scale_name(tier), 22, _tier_color(tier)))
	info.add_child(_label("Rounds %d   ·   Supply %d   ·   Checkpoints %d   ·   Zones %d   ·   Mobs %d" % [
		map.round_count, map.supply_cap, map.checkpoint_cells.size(), map.bonus_zones.size(), map.mob_count], 14, UiStyle.LABEL_COL))

	var best_row := HBoxContainer.new()
	best_row.add_theme_constant_override("separation", 6)
	if best > 0:
		var star = StarRatingScript.new()
		star.configure(1, 1, 16.0)
		star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		best_row.add_child(star)
	best_row.add_child(_label("Best: %d" % best if best > 0 else "No score yet", 14, Color(1.0, 0.9, 0.5)))
	info.add_child(best_row)

	if rank > 0:
		var rank_btn := Button.new()
		rank_btn.text = "#%d  ›" % rank
		rank_btn.add_theme_font_size_override("font_size", 14)
		rank_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		UiStyle.style_flat_button(rank_btn, UiStyle.CHIP_BG, 12, UiStyle.CHIP_BORDER, 2, false, 12, 5)
		rank_btn.add_theme_color_override("font_color", Color("bfe6a3"))
		rank_btn.pressed.connect(func(): SceneManager.goto_leaderboards(
			{"category": 0, "window": _current, "tier": tier, "group": "solo"}))
		info.add_child(rank_btn)
	else:
		info.add_child(_label("unplayed", 12, UiStyle.LABEL_COL))

	var play := Button.new()
	play.text = "Play"
	play.custom_minimum_size = Vector2(120, 52)
	play.add_theme_font_size_override("font_size", 18)
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_go_button(play)
	play.pressed.connect(func(): SceneManager.start_pve_map(map))
	row.add_child(play)

	return panel

func _tier_color(tier: int) -> Color:
	return Color(0.45, 0.85, 0.5).lerp(Color(1.0, 0.45, 0.35), (tier - 1) / 4.0)

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
