extends Control

# PVP queue + forming-lobby UI (phase 3d). Drives a QueueController: press Find Match → Nakama
# matchmaker → forming lobby (X/8 + launch vote) → on launch the controller connects to the Godot
# match-server room and starts the networked match (the scene changes itself). The old
# single-shared-lobby / connect-by-IP model is gone — Nakama forms the group, the dedicated Godot
# server hosts the room (notes/matchmaking_orchestration.md, notes/remote_beta_plan.md).

const UiStyle := preload("res://scripts/ui_style.gd")
const QueueControllerScript := preload("res://scripts/queue_controller.gd")

var _queue
var _idle_box: VBoxContainer
var _queue_box: VBoxContainer
var _lobby_box: VBoxContainer
var _name_edit: LineEdit
var _status: Label
var _lobby_count: Label
var _present: VBoxContainer
var _vote_btn: Button
var _vote_hint: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyle.menu_backdrop(self)
	_queue = QueueControllerScript.new()
	_queue.name = "QueueController"
	add_child(_queue)
	_queue.phase_changed.connect(_on_phase)
	_queue.lobby_update.connect(_on_lobby_update)
	_build_ui()
	_name_edit.text = SceneManager.last_player_name
	_show(_idle_box)

# ============================================================================
# UI
# ============================================================================

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

	var title := _label("RANKED", 30, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	_status = _label("", 15, UiStyle.LABEL_COL)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_status)

	col.add_child(_build_idle_box())
	col.add_child(_build_queue_box())
	col.add_child(_build_lobby_box())

func _build_idle_box() -> VBoxContainer:
	_idle_box = VBoxContainer.new()
	_idle_box.add_theme_constant_override("separation", 12)

	_idle_box.add_child(_field_label("Your name"))
	_name_edit = LineEdit.new()
	_name_edit.text = "Player"
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(0, 40)
	_idle_box.add_child(_name_edit)

	var find := Button.new()
	find.text = "Find Match"
	find.add_theme_font_size_override("font_size", 18)
	UiStyle.style_hero_button(find)
	find.pressed.connect(_on_find_pressed)
	_idle_box.add_child(find)

	_idle_box.add_child(_spacer(6))
	var back := Button.new()
	back.text = "← Back"
	back.add_theme_font_size_override("font_size", 15)
	UiStyle.style_menu_button(back)
	back.pressed.connect(func(): SceneManager.goto_home())
	_idle_box.add_child(back)
	return _idle_box

func _build_queue_box() -> VBoxContainer:
	_queue_box = VBoxContainer.new()
	_queue_box.add_theme_constant_override("separation", 12)
	_queue_box.visible = false

	var spin := _label("Searching for a match…", 16, Color.WHITE)
	spin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_queue_box.add_child(spin)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.add_theme_font_size_override("font_size", 15)
	UiStyle.style_danger_button(cancel)
	cancel.pressed.connect(_on_cancel_pressed)
	_queue_box.add_child(cancel)
	return _queue_box

func _build_lobby_box() -> VBoxContainer:
	_lobby_box = VBoxContainer.new()
	_lobby_box.add_theme_constant_override("separation", 10)
	_lobby_box.visible = false

	_lobby_count = _label("Lobby 0/8", 18, Color.WHITE)
	_lobby_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_box.add_child(_lobby_count)

	_present = VBoxContainer.new()
	_present.add_theme_constant_override("separation", 6)
	_lobby_box.add_child(_present)

	_lobby_box.add_child(_spacer(4))
	_vote_btn = Button.new()
	_vote_btn.text = "Launch Now"
	_vote_btn.add_theme_font_size_override("font_size", 18)
	UiStyle.style_go_button(_vote_btn)
	_vote_btn.pressed.connect(_on_vote_pressed)
	_lobby_box.add_child(_vote_btn)

	_vote_hint = _label("", 12, UiStyle.LABEL_COL)
	_vote_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_box.add_child(_vote_hint)

	var leave := Button.new()
	leave.text = "Leave"
	leave.add_theme_font_size_override("font_size", 15)
	UiStyle.style_danger_button(leave)
	leave.pressed.connect(_on_cancel_pressed)
	_lobby_box.add_child(leave)
	return _lobby_box

func _show(box) -> void:
	_idle_box.visible = (box == _idle_box)
	_queue_box.visible = (box == _queue_box)
	_lobby_box.visible = (box == _lobby_box)

# ============================================================================
# Actions
# ============================================================================

func _on_find_pressed() -> void:
	SceneManager.last_player_name = _my_name()
	_status.text = "Connecting…"
	_queue.start_queue(_my_name())

func _on_cancel_pressed() -> void:
	_queue.cancel()

func _on_vote_pressed() -> void:
	_queue.vote()
	_vote_btn.disabled = true
	_vote_hint.text = "Waiting for everyone to launch…"

# ============================================================================
# QueueController signals
# ============================================================================

func _on_phase(phase, info) -> void:
	match phase:
		QueueControllerScript.Phase.IDLE:
			_status.text = ""
			_show(_idle_box)
		QueueControllerScript.Phase.QUEUING:
			_status.text = "Searching…"
			_show(_queue_box)
		QueueControllerScript.Phase.LOBBY:
			_status.text = "Match found — forming lobby"
			_show(_lobby_box)
		QueueControllerScript.Phase.CONNECTING:
			_status.text = "Launching — connecting to match server…"
		QueueControllerScript.Phase.IN_MATCH:
			_status.text = "Starting match…"
		QueueControllerScript.Phase.ERROR:
			_status.text = "Error: %s" % String(info.get("reason", "unknown"))
			_show(_idle_box)

func _on_lobby_update(info: Dictionary) -> void:
	var count := int(info.get("count", 0))
	var maxp := int(info.get("max", 8))
	var floorp := int(info.get("floor", 4))
	var you_voted := bool(info.get("you_voted", false))
	_lobby_count.text = "Lobby %d/%d" % [count, maxp]

	for c in _present.get_children():
		c.queue_free()
	var voted: Array = info.get("voted", [])
	for uid in info.get("present", []):
		_present.add_child(_label(String(uid).substr(0, 8) + ("   ✓" if voted.has(uid) else ""), 14, Color.WHITE))

	# Vote is offered only at floor..max-1; at max the server auto-launches (no vote).
	_vote_btn.visible = count < maxp
	_vote_btn.disabled = not (count >= floorp and count < maxp and not you_voted)
	if count < floorp:
		_vote_hint.text = "Need %d to launch early (or keep filling to %d)" % [floorp, maxp]
	elif count >= maxp:
		_vote_hint.text = "Full — launching…"
	elif you_voted:
		_vote_hint.text = "You voted — waiting for everyone present"
	else:
		_vote_hint.text = "Everyone present must vote to launch now"

# ============================================================================
# Helpers
# ============================================================================

func _my_name() -> String:
	var n := _name_edit.text.strip_edges()
	return n.substr(0, 16) if n != "" else "Player"

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	return l

func _field_label(text: String) -> Label:
	return _label(text, 13, UiStyle.LABEL_COL)

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
