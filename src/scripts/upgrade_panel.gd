extends CanvasLayer
class_name UpgradePanel

const STATS := ["damage", "range", "attack_speed", "crit_chance", "crit_damage", "multishot"]
const STAT_LABELS := {
	"damage": "Damage",
	"range": "Range",
	"attack_speed": "Atk Speed",
	"crit_chance": "Crit Chance",
	"crit_damage": "Crit Damage",
	"multishot": "Multishot",
}

var round_manager  # RoundManager — untyped to avoid class-name cycle

var _target_tower: Node2D
var _panel: PanelContainer
var _stat_tier_labels: Dictionary = {}
var _stat_buttons: Dictionary = {}

func _ready() -> void:
	layer = 10
	_build_ui()
	_panel.visible = false
	if round_manager != null:
		round_manager.gold_changed.connect(_on_gold_changed)
		round_manager.phase_changed.connect(_on_phase_changed)

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(320, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Tower upgrades"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	for stat in STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var name_label := Label.new()
		name_label.text = STAT_LABELS[stat]
		name_label.custom_minimum_size = Vector2(120, 40)
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_label)

		var tier_label := Label.new()
		tier_label.text = "T0"
		tier_label.custom_minimum_size = Vector2(40, 40)
		tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_stat_tier_labels[stat] = tier_label
		row.add_child(tier_label)

		var button := Button.new()
		button.text = "+"
		button.custom_minimum_size = Vector2(110, 40)
		button.pressed.connect(_on_upgrade_pressed.bind(stat))
		_stat_buttons[stat] = button
		row.add_child(button)

		vbox.add_child(row)

	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(hide_panel)
	vbox.add_child(close)

func show_for(tower: Node2D) -> void:
	if _target_tower != null and _target_tower != tower and is_instance_valid(_target_tower):
		_target_tower.set_selected(false)
	_target_tower = tower
	if is_instance_valid(_target_tower):
		_target_tower.set_selected(true)
	_refresh_labels()
	_panel.position = tower.position + Vector2(80, -120)
	_panel.visible = true

func hide_panel() -> void:
	if _target_tower != null and is_instance_valid(_target_tower):
		_target_tower.set_selected(false)
	_target_tower = null
	_panel.visible = false

func _refresh_labels() -> void:
	if not is_instance_valid(_target_tower):
		return
	var in_build: bool = round_manager == null or round_manager.phase == "build"
	var gold: int = round_manager.gold if round_manager != null else 99999
	for stat in STATS:
		_stat_tier_labels[stat].text = "T%d" % _target_tower.tiers[stat]
		var button: Button = _stat_buttons[stat]
		var cost: int = _target_tower.upgrade_cost(stat)
		if cost <= 0:
			button.text = "MAX"
			button.disabled = true
		else:
			button.text = "+ %dg" % cost
			button.disabled = (not in_build) or (gold < cost)

func _on_upgrade_pressed(stat: String) -> void:
	if not is_instance_valid(_target_tower):
		return
	if round_manager == null:
		_target_tower.upgrade(stat)
		_refresh_labels()
		return
	if round_manager.phase != "build":
		return
	var cost: int = _target_tower.upgrade_cost(stat)
	if cost <= 0:
		return
	if not round_manager.spend(cost):
		return
	_target_tower.upgrade(stat)
	_refresh_labels()

func _on_gold_changed(_new_gold: int) -> void:
	if _panel.visible:
		_refresh_labels()

func _on_phase_changed(_phase: String) -> void:
	if _panel.visible:
		_refresh_labels()

func is_visible_panel() -> bool:
	return _panel.visible

func contains_screen_point(screen_pos: Vector2) -> bool:
	if not _panel.visible:
		return false
	return _panel.get_global_rect().has_point(screen_pos)
