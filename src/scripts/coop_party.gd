extends Control

const UiStyle := preload("res://scripts/ui_style.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")

var _window: int = 0
var _tier: int = 1
var _starting: bool = false

var _status: Label
var _members_box: VBoxContainer
var _create_btn: Button
var _invite_btn: Button
var _start_btn: Button
var _leave_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyle.menu_backdrop(self)
	_window = SceneManager.pending_coop_window
	_tier = SceneManager.pending_coop_tier
	_build_ui()
	if SteamManager.party_changed.is_connected(_refresh):
		SteamManager.party_changed.disconnect(_refresh)
	SteamManager.party_changed.connect(_refresh)
	SteamManager.party_left.connect(_refresh)
	if SteamManager.is_party_leader():
		_publish_scale()
	_refresh()

func _exit_tree() -> void:
	if SteamManager.party_changed.is_connected(_refresh):
		SteamManager.party_changed.disconnect(_refresh)
	if SteamManager.party_left.is_connected(_refresh):
		SteamManager.party_left.disconnect(_refresh)

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	UiStyle.apply_card(card)
	card.custom_minimum_size = Vector2(460, 0)
	center.add_child(card)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	var title := _label("CO-OP TRIALS", 30, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var scale_lbl := _label("%s  ·  %s" % [LeaderboardService.scale_name(_tier), _window_label(_window)], 16, Color("d79a52"))
	scale_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(scale_lbl)

	_status = _label("", 14, UiStyle.LABEL_COL)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_status)

	_members_box = VBoxContainer.new()
	_members_box.add_theme_constant_override("separation", 6)
	col.add_child(_members_box)

	col.add_child(_spacer(4))

	_create_btn = Button.new()
	_create_btn.text = "Create Party"
	_create_btn.add_theme_font_size_override("font_size", 18)
	UiStyle.style_hero_button(_create_btn)
	_create_btn.pressed.connect(func(): SteamManager.create_party())
	col.add_child(_create_btn)

	_invite_btn = Button.new()
	_invite_btn.text = "Invite Friends"
	_invite_btn.add_theme_font_size_override("font_size", 16)
	UiStyle.style_menu_button(_invite_btn)
	_invite_btn.pressed.connect(func(): SteamManager.invite_overlay())
	col.add_child(_invite_btn)

	_start_btn = Button.new()
	_start_btn.text = "Start"
	_start_btn.add_theme_font_size_override("font_size", 18)
	UiStyle.style_go_button(_start_btn)
	_start_btn.pressed.connect(_on_start_pressed)
	col.add_child(_start_btn)

	col.add_child(_spacer(4))

	_leave_btn = Button.new()
	_leave_btn.text = "Leave Party"
	_leave_btn.add_theme_font_size_override("font_size", 15)
	UiStyle.style_danger_button(_leave_btn)
	_leave_btn.pressed.connect(func(): SteamManager.leave_party())
	col.add_child(_leave_btn)

	var back := Button.new()
	back.text = "← Back"
	back.add_theme_font_size_override("font_size", 15)
	UiStyle.style_menu_button(back)
	back.pressed.connect(func(): SteamManager.leave_party(); SceneManager.goto_home())
	col.add_child(back)

func _refresh(_a = null) -> void:
	if not is_inside_tree():
		return
	if not SteamManager.is_available():
		_status.text = "Steam is required for co-op."
		_create_btn.visible = false
		_invite_btn.visible = false
		_start_btn.visible = false
		_leave_btn.visible = false
		_clear_members()
		return

	var in_party: bool = SteamManager.in_party()
	var leader: bool = SteamManager.is_party_leader()
	_create_btn.visible = not in_party
	_invite_btn.visible = in_party
	_start_btn.visible = in_party and leader
	_leave_btn.visible = in_party

	if not in_party:
		_status.text = "Create a party, then invite friends from the Steam overlay."
		_clear_members()
		return

	if not leader:
		var host_window := SteamManager.get_party_data("window")
		var host_tier := SteamManager.get_party_data("tier")
		if host_tier != "":
			_tier = int(host_tier)
		if host_window != "":
			_window = int(host_window)
		_status.text = "Waiting for the host to start…"
	else:
		_status.text = "%d in party — invite up to %d." % [SteamManager.party_size(), SteamManager.PARTY_MAX]

	_clear_members()
	for m in SteamManager.party_members():
		var tag := "  ★" if bool(m.get("leader", false)) else ""
		_members_box.add_child(_label(String(m.get("name", "Player")) + tag, 15, Color.WHITE))

func _publish_scale() -> void:
	SteamManager.set_party_data("window", str(_window))
	SteamManager.set_party_data("tier", str(_tier))

func _on_start_pressed() -> void:
	if _starting or not SteamManager.is_party_leader():
		return
	if SteamManager.party_size() < 2:
		_status.text = "Need at least 2 players to start co-op."
		return
	_starting = true
	_start_btn.disabled = true
	_status.text = "Starting…"
	var server: Dictionary = await LeaderboardService.trials_seeds()
	var wid: String = LeaderboardService.WINDOW_IDS.get(_window, "daily")
	var seeds: Array = server.get(wid, [])
	var seed: int = int(seeds[_tier - 1]) if seeds.size() >= 5 else (hash(wid) + _tier * 1013)
	var info := {
		"match_id": "%d_%d" % [SteamManager.party_lobby_id, int(Time.get_unix_time_from_system())],
		"host": SceneManager.MATCH_SERVER_HOST,
		"port": 8771,
		"count": SteamManager.party_size(),
		"window": _window,
		"tier": _tier,
		"seed": seed,
	}
	SteamManager.launch_party(info)

func _window_label(window: int) -> String:
	match window:
		MapResourceScript.WindowType.WEEKLY:
			return "Weekly"
		MapResourceScript.WindowType.MONTHLY:
			return "Monthly"
		_:
			return "Daily"

func _clear_members() -> void:
	for c in _members_box.get_children():
		c.queue_free()

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	return l

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
