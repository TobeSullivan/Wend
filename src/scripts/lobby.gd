extends Control

# PVP lobby (built from the locked visual system — no separate design doc exists yet;
# follows ui_style.gd + the home/pve_select patterns). Two views on one card:
#   CONNECT — name field, Host Game / Join Game (+ address), Back.
#   ROOM    — ranked player list, host's Play (≥2), auto-countdown from 10 at 8, Leave.
#
# Networking: host-authoritative over the SceneManager-owned MatchTransport. The host
# owns the authoritative player list + seats and broadcasts LOBBY_STATE; clients render
# it. On start the host picks the shared seed and broadcasts START_MATCH; everyone then
# generates the identical map and loads the match on their own seat (SceneManager).

const UiStyle := preload("res://scripts/ui_style.gd")
const NetProtocol := preload("res://net/net_protocol.gd")

var _t                                  # MatchTransport (from SceneManager)
var _is_host := false
var _my_id := 1
var _my_seat := 0
var _players: Array = []                # [{id, name, seat}] — authoritative on host, mirror on client
var _countdown := -1.0                  # >=0 = auto-start ticking (host-driven)
var _broadcast_accum := 0.0

# UI
var _card: PanelContainer
var _connect_box: VBoxContainer
var _room_box: VBoxContainer
var _name_edit: LineEdit
var _addr_edit: LineEdit
var _status: Label
var _rows: VBoxContainer
var _play_btn: Button
var _addr_info: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyle.menu_backdrop(self)
	_build_ui()
	_show_connect()

# ============================================================================
# UI
# ============================================================================

func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	UiStyle.apply_card(_card)
	_card.custom_minimum_size = Vector2(440, 0)
	center.add_child(_card)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)

	var title := _label("MULTIPLAYER", 30, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	_status = _label("", 15, UiStyle.LABEL_COL)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_status)

	_connect_box = _build_connect_box()
	col.add_child(_connect_box)

	_room_box = _build_room_box()
	col.add_child(_room_box)

func _build_connect_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	box.add_child(_field_label("Your name"))
	_name_edit = LineEdit.new()
	_name_edit.text = "Player"
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(0, 40)
	box.add_child(_name_edit)

	var host_btn := Button.new()
	host_btn.text = "Host Game"
	host_btn.add_theme_font_size_override("font_size", 18)
	UiStyle.style_go_button(host_btn)
	host_btn.pressed.connect(_on_host_pressed)
	box.add_child(host_btn)

	box.add_child(_field_label("Join a host (address)"))
	_addr_edit = LineEdit.new()
	_addr_edit.text = "127.0.0.1"
	_addr_edit.placeholder_text = "host IP or address"
	_addr_edit.custom_minimum_size = Vector2(0, 40)
	box.add_child(_addr_edit)

	var join_btn := Button.new()
	join_btn.text = "Join Game"
	join_btn.add_theme_font_size_override("font_size", 18)
	UiStyle.style_hero_button(join_btn)
	join_btn.pressed.connect(_on_join_pressed)
	box.add_child(join_btn)

	box.add_child(_spacer(6))
	var back := Button.new()
	back.text = "← Back"
	back.add_theme_font_size_override("font_size", 15)
	UiStyle.style_menu_button(back)
	back.pressed.connect(_on_back_pressed)
	box.add_child(back)
	return box

func _build_room_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.visible = false

	_addr_info = _label("", 12, UiStyle.LABEL_COL)
	_addr_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_addr_info)

	var hdr := _label("PLAYERS", 14, UiStyle.LABEL_COL)
	box.add_child(hdr)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	box.add_child(_rows)

	box.add_child(_spacer(4))

	_play_btn = Button.new()
	_play_btn.text = "Play"
	_play_btn.add_theme_font_size_override("font_size", 18)
	UiStyle.style_go_button(_play_btn)
	_play_btn.pressed.connect(_on_play_pressed)
	box.add_child(_play_btn)

	var leave := Button.new()
	leave.text = "Leave"
	leave.add_theme_font_size_override("font_size", 15)
	UiStyle.style_danger_button(leave)
	leave.pressed.connect(_on_leave_pressed)
	box.add_child(leave)
	return box

func _show_connect() -> void:
	_connect_box.visible = true
	_room_box.visible = false

func _show_room() -> void:
	_connect_box.visible = false
	_room_box.visible = true
	_refresh_room()

# ============================================================================
# Connect / leave
# ============================================================================

func _on_host_pressed() -> void:
	var err = SceneManager.net_host()
	if err != OK:
		_status.text = "Could not host (error %d)" % err
		return
	_t = SceneManager.transport
	_is_host = true
	_my_id = 1
	_my_seat = 0
	_players = [{"id": 1, "name": _my_name(), "seat": 0}]
	_wire_transport()
	_status.text = "Hosting on port %d — waiting for players" % NetProtocol.DEFAULT_PORT
	_addr_info.text = "Same Wi-Fi: others Join at %s:%d\nInternet: forward UDP %d to this PC, share your public IP" % [_local_ip(), NetProtocol.DEFAULT_PORT, NetProtocol.DEFAULT_PORT]
	_show_room()

func _on_join_pressed() -> void:
	var addr := _addr_edit.text.strip_edges()
	if addr == "":
		_status.text = "Enter a host address"
		return
	var err = SceneManager.net_join(addr)
	if err != OK:
		_status.text = "Could not connect (error %d)" % err
		return
	_t = SceneManager.transport
	_is_host = false
	_wire_transport()
	_status.text = "Connecting to %s…" % addr
	_show_room()

func _on_back_pressed() -> void:
	SceneManager.net_close()
	SceneManager.goto_home()

func _on_leave_pressed() -> void:
	SceneManager.net_close()
	_t = null
	_is_host = false
	_players = []
	_countdown = -1.0
	_status.text = ""
	_show_connect()

# ============================================================================
# Transport wiring
# ============================================================================

func _wire_transport() -> void:
	_t.received.connect(_on_received)
	_t.peer_joined.connect(_on_peer_joined)
	_t.peer_left.connect(_on_peer_left)
	_t.connection_succeeded.connect(_on_connected)
	_t.connection_failed.connect(_on_conn_failed)
	_t.server_closed.connect(_on_server_closed)

func _on_connected() -> void:
	_my_id = _t.unique_id()
	_status.text = "Connected — waiting for host"
	_t.send_to_authority({"t": NetProtocol.SET_NAME, "name": _my_name()})

func _on_conn_failed() -> void:
	_status.text = "Connection failed"
	SceneManager.net_close()
	_t = null
	_show_connect()

func _on_server_closed() -> void:
	_status.text = "Host left the lobby"
	SceneManager.net_close()
	_t = null
	_show_connect()

# Host: a client connected → assign the next seat, announce.
func _on_peer_joined(id: int) -> void:
	if not _is_host:
		return
	_players.append({"id": id, "name": "Player", "seat": 0})
	_reassign_seats()
	_broadcast_lobby_state()
	_maybe_start_countdown()

func _on_peer_left(id: int) -> void:
	if not _is_host:
		return
	for i in range(_players.size() - 1, -1, -1):
		if _players[i]["id"] == id:
			_players.remove_at(i)
	_reassign_seats()
	if _players.size() < NetProtocol.MAX_PLAYERS:
		_countdown = -1.0
	_broadcast_lobby_state()

func _on_received(from_id: int, msg: Dictionary) -> void:
	match msg.get("t", ""):
		NetProtocol.SET_NAME:
			if _is_host:
				for p in _players:
					if p["id"] == from_id:
						p["name"] = String(msg.get("name", "Player")).substr(0, 16)
				_broadcast_lobby_state()
		NetProtocol.LOBBY_STATE:
			if not _is_host:
				_players = msg.get("players", [])
				_countdown = msg.get("countdown", -1.0)
				_my_seat = _seat_of(_my_id)
				_refresh_room()
		NetProtocol.START_MATCH:
			if not _is_host:
				_my_seat = _seat_of(_my_id)
				SceneManager.start_networked_pvp(msg["seed"], msg["tier"], msg["count"], _my_seat, msg["names"])

# ============================================================================
# Host: countdown + start
# ============================================================================

func _process(dt: float) -> void:
	if not _is_host or _countdown < 0.0:
		return
	_countdown -= dt
	_broadcast_accum += dt
	if _broadcast_accum >= 0.5:
		_broadcast_accum = 0.0
		_broadcast_lobby_state()
	_refresh_room()
	if _countdown <= 0.0:
		_start_match()

func _maybe_start_countdown() -> void:
	if _players.size() >= NetProtocol.MAX_PLAYERS and _countdown < 0.0:
		_countdown = 10.0

func _on_play_pressed() -> void:
	if not _is_host or _players.size() < 2:
		return
	_start_match()

func _start_match() -> void:
	if not _is_host:
		return
	_countdown = -1.0
	var seed := int(Time.get_unix_time_from_system())
	var tier := (seed % 5) + 1
	var count := _players.size()
	var names: Array = []
	names.resize(count)
	var seat_by_peer := {}
	for p in _players:
		names[p["seat"]] = p["name"]
		seat_by_peer[p["id"]] = p["seat"]
	_t.broadcast({"t": NetProtocol.START_MATCH, "seed": seed, "tier": tier, "count": count, "names": names})
	SceneManager.start_networked_pvp(seed, tier, count, 0, names, seat_by_peer)

# ============================================================================
# Helpers
# ============================================================================

func _broadcast_lobby_state() -> void:
	_t.broadcast({"t": NetProtocol.LOBBY_STATE, "players": _players, "host_id": 1, "count": _players.size(), "countdown": _countdown})
	_refresh_room()

# Host: keep seats contiguous 0..n-1 in current seat order (host stays seat 0).
func _reassign_seats() -> void:
	_players.sort_custom(func(a, b): return a["seat"] < b["seat"])
	for i in range(_players.size()):
		_players[i]["seat"] = i

func _seat_of(id: int) -> int:
	for p in _players:
		if p["id"] == id:
			return int(p["seat"])
	return 0

func _refresh_room() -> void:
	if _rows == null:
		return
	for c in _rows.get_children():
		c.queue_free()
	var ordered: Array = _players.duplicate()
	ordered.sort_custom(func(a, b): return a["seat"] < b["seat"])
	for p in ordered:
		_rows.add_child(_player_row(p))
	# status / countdown
	if _countdown >= 0.0:
		_status.text = "Starting in %d…" % int(ceil(_countdown))
	elif _is_host:
		if _players.size() < 2:
			_status.text = "Waiting for players (need 2+)"
		else:
			_status.text = "%d players — press Play, or wait for 8" % _players.size()
	# Only the host has a working Play button.
	_play_btn.visible = _is_host
	_play_btn.disabled = _players.size() < 2

func _player_row(p: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	var is_me := int(p["id"]) == _my_id
	row.add_theme_stylebox_override("panel", UiStyle.pill_box())
	if is_me:
		row.modulate = Color(0.78, 1.0, 0.78)  # tint your own row green-ish

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 7)
	m.add_theme_constant_override("margin_bottom", 7)
	row.add_child(m)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	m.add_child(hb)

	var seat_lbl := _label("%d" % (int(p["seat"]) + 1), 15, UiStyle.LABEL_COL)
	seat_lbl.custom_minimum_size = Vector2(22, 0)
	hb.add_child(seat_lbl)

	var tag := ""
	if int(p["id"]) == 1:
		tag = "  (host)"
	if is_me:
		tag += "  (you)"
	var name_lbl := _label(String(p["name"]) + tag, 16, Color.WHITE)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(name_lbl)
	return row

# Best-guess LAN IPv4 to display to the host (skip loopback + link-local).
func _local_ip() -> String:
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254"):
			return a
	return "127.0.0.1"

func _my_name() -> String:
	var n := _name_edit.text.strip_edges() if _name_edit != null else "Player"
	return n.substr(0, 16) if n != "" else "Player"

func _field_label(text: String) -> Label:
	return _label(text, 13, UiStyle.LABEL_COL)

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	return l
