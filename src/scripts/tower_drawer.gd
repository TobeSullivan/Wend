extends CanvasLayer
class_name TowerDrawer

const UiLayout := preload("res://scripts/ui_layout.gd")
const UiStyle := preload("res://scripts/ui_style.gd")

const STATS := ["damage", "range", "attack_speed", "crit_chance", "crit_damage", "multishot"]
const STAT_LABELS := {
	"damage": "Damage", "range": "Range", "attack_speed": "Attack speed",
	"crit_chance": "Crit", "crit_damage": "Crit dmg", "multishot": "Multishot",
}
const TILE_PX := 48.0
const OVERLAY_W := 266.0
const OVERLAY_PAD := 10.0

var round_manager
var build_controller
var game_view
var rail

var _panel: PanelContainer
var _name_lab: Label
var _sub_lab: Label
var _stat_val: Dictionary = {}
var _stat_btn: Dictionary = {}
var _stat_cost: Dictionary = {}
var _dmg_lab: Label

var _selected

func _ready() -> void:
	layer = 9
	_build_ui()
	_panel.visible = false
	get_viewport().size_changed.connect(_place)
	if build_controller != null:
		build_controller.tower_selected.connect(_on_tower_selected)
		build_controller.selection_cleared.connect(_on_selection_cleared)
		build_controller.towers_changed.connect(func(_c, _cap): _refresh())
	if round_manager != null:
		round_manager.gold_changed.connect(func(_g): _refresh())
		round_manager.phase_changed.connect(func(_p): _refresh())

func _process(_delta: float) -> void:
	if _panel.visible and is_instance_valid(_selected):
		_update_damage()

func covers(pos: Vector2) -> bool:
	return _panel != null and _panel.visible and _panel.get_global_rect().has_point(pos)

func _build_ui() -> void:
	var s := UiLayout.scale_factor()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.dock_box())
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_panel)

	var m := MarginContainer.new()
	var pad := int(13 * s)
	m.add_theme_constant_override("margin_left", pad)
	m.add_theme_constant_override("margin_right", pad)
	m.add_theme_constant_override("margin_top", int(12 * s))
	m.add_theme_constant_override("margin_bottom", int(12 * s))
	_panel.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", int(4 * s))
	m.add_child(v)

	var head := Label.new()
	head.text = "TOWER"
	head.add_theme_font_size_override("font_size", int(11 * s))
	head.add_theme_color_override("font_color", UiStyle.LABEL_COL)
	v.add_child(head)

	_name_lab = Label.new()
	_name_lab.text = "Arrow Tower"
	_name_lab.add_theme_font_size_override("font_size", int(18 * s))
	_name_lab.add_theme_color_override("font_color", Color.WHITE)
	v.add_child(_name_lab)

	_sub_lab = Label.new()
	_sub_lab.text = ""
	_sub_lab.add_theme_font_size_override("font_size", int(11 * s))
	_sub_lab.add_theme_color_override("font_color", Color("9fb088"))
	v.add_child(_sub_lab)

	for stat in STATS:
		var rowpanel := PanelContainer.new()
		rowpanel.add_theme_stylebox_override("panel", UiStyle.stat_box())
		var rm := MarginContainer.new()
		rm.add_theme_constant_override("margin_left", int(8 * s))
		rm.add_theme_constant_override("margin_right", int(8 * s))
		rm.add_theme_constant_override("margin_top", int(6 * s))
		rm.add_theme_constant_override("margin_bottom", int(6 * s))
		rowpanel.add_child(rm)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", int(6 * s))
		rm.add_child(row)
		var nm := Label.new()
		nm.text = STAT_LABELS[stat]
		nm.add_theme_font_size_override("font_size", int(13 * s))
		nm.add_theme_color_override("font_color", Color("e7eedd"))
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(nm)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", int(13 * s))
		val.add_theme_color_override("font_color", Color.WHITE)
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_stat_val[stat] = val
		row.add_child(val)
		var cost := Label.new()
		cost.add_theme_font_size_override("font_size", int(13 * s))
		cost.add_theme_color_override("font_color", Color("ffe98c"))
		cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost.custom_minimum_size = Vector2(30 * s, 0)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_stat_cost[stat] = cost
		row.add_child(cost)
		var up := Button.new()
		up.text = "+"
		up.custom_minimum_size = Vector2(26, 26) * s
		up.add_theme_font_size_override("font_size", int(16 * s))
		UiStyle.style_flat_button(up, UiStyle.UP_BG, 8, UiStyle.UP_BG.darkened(0.3), 1, false, 4, 0)
		up.pressed.connect(_on_upgrade_pressed.bind(stat))
		_stat_btn[stat] = up
		row.add_child(up)
		v.add_child(rowpanel)

	var dmgpanel := PanelContainer.new()
	dmgpanel.add_theme_stylebox_override("panel", UiStyle.stat_box())
	var dm := MarginContainer.new()
	dm.add_theme_constant_override("margin_left", int(8 * s))
	dm.add_theme_constant_override("margin_right", int(8 * s))
	dm.add_theme_constant_override("margin_top", int(6 * s))
	dm.add_theme_constant_override("margin_bottom", int(6 * s))
	dmgpanel.add_child(dm)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", int(6 * s))
	dm.add_child(drow)
	var dlab := Label.new()
	dlab.text = "Total damage"
	dlab.add_theme_font_size_override("font_size", int(13 * s))
	dlab.add_theme_color_override("font_color", Color("dfe6d6"))
	dlab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drow.add_child(dlab)
	_dmg_lab = Label.new()
	_dmg_lab.text = "0"
	_dmg_lab.add_theme_font_size_override("font_size", int(13 * s))
	_dmg_lab.add_theme_color_override("font_color", Color("ffd27a"))
	drow.add_child(_dmg_lab)
	v.add_child(dmgpanel)

	var sell := Button.new()
	sell.text = "Sell"
	sell.custom_minimum_size = Vector2(0, 34 * s)
	sell.add_theme_font_size_override("font_size", int(14 * s))
	UiStyle.style_flat_button(sell, UiStyle.SELL_BG, 11, UiStyle.SELL_BORDER, 2, false)
	sell.pressed.connect(_on_sell_pressed)
	v.add_child(sell)

func _place() -> void:
	if _panel == null or not _panel.visible:
		return
	var s := UiLayout.scale_factor()
	var slot: Rect2 = rail.tower_slot_rect() if rail != null else Rect2()
	if slot.size.y > 0.0:
		_panel.custom_minimum_size = Vector2(slot.size.x, 0)
		_panel.position = slot.position
	else:
		var w := OVERLAY_W * s
		var pad := OVERLAY_PAD * s
		_panel.custom_minimum_size = Vector2(w, 0)
		var brect: Rect2 = game_view.board_screen_rect() if game_view != null else Rect2()
		if brect.size.x > 0.0:
			_panel.position = Vector2(brect.position.x + brect.size.x - w - pad, brect.position.y + pad)
		else:
			var vp := get_viewport().get_visible_rect().size
			_panel.position = Vector2(vp.x - UiLayout.rail_w() - w - pad, pad)
	_panel.reset_size()

func _on_tower_selected(tower) -> void:
	_selected = tower
	_panel.visible = true
	_refresh()
	_place.call_deferred()

func _on_selection_cleared() -> void:
	_selected = null
	_panel.visible = false

func _refresh() -> void:
	if not is_instance_valid(_selected) or not _panel.visible:
		return
	var in_build: bool = round_manager == null or round_manager.phase == "build"
	var gold: int = round_manager.gold if round_manager != null else 99999
	_name_lab.text = "Arrow Tower"
	var lv: int = 1
	for stat in STATS:
		lv += _selected.tiers[stat]
	_sub_lab.text = "Lv %d · selected" % lv
	for stat in STATS:
		_stat_val[stat].text = _effective_value(stat)
		var b: Button = _stat_btn[stat]
		var cost: int = _selected.upgrade_cost(stat)
		var cost_lab: Label = _stat_cost[stat]
		if cost <= 0:
			cost_lab.text = "MAX"
			cost_lab.add_theme_color_override("font_color", Color("9fb088"))
			b.disabled = true
			b.visible = false
		else:
			b.visible = true
			cost_lab.text = str(cost)
			var afford: bool = in_build and gold >= cost
			cost_lab.add_theme_color_override("font_color", Color("ffe98c") if afford else Color(1, 0.92, 0.55, 0.4))
			b.disabled = not afford
	_update_damage()

func _update_damage() -> void:
	if _dmg_lab == null or not is_instance_valid(_selected):
		return
	_dmg_lab.text = "%s  ·  %d kills" % [_fmt_num(_selected.damage_done), _selected.kills]

static func _fmt_num(value: float) -> String:
	var n := int(round(value))
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fk" % (n / 1000.0)
	return str(n)

func _effective_value(stat: String) -> String:
	var t = _selected
	match stat:
		"damage":       return "%.0f" % t.get_damage()
		"range":        return "%.1f" % (t.get_range() / TILE_PX)
		"attack_speed": return "%.1f/s" % (1.0 / t.get_cooldown())
		"crit_chance":  return "%d%%" % int(round(t.get_crit_chance() * 100.0))
		"crit_damage":  return "x%.2f" % t.get_crit_damage_mult()
		"multishot":    return "%d" % (1 + t.get_multishot())
	return "-"

func _on_upgrade_pressed(stat: String) -> void:
	if not is_instance_valid(_selected):
		return
	if round_manager != null and round_manager.phase != "build":
		return
	var cost: int = _selected.upgrade_cost(stat)
	if cost <= 0:
		return
	if round_manager != null and not round_manager.spend(cost):
		return
	var ucell: Vector2i = _selected.grid_cell
	_selected.upgrade(stat)
	if build_controller != null:
		build_controller.on_local_upgrade(ucell, stat)
	_refresh()

func _on_sell_pressed() -> void:
	if build_controller != null:
		build_controller.sell_selected_tower()
