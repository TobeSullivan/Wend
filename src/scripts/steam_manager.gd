extends Node

signal steam_ready(available: bool)
signal overlay_toggled(active: bool)
signal stats_ready()
signal party_changed()
signal party_joined(ok: bool)
signal party_left()
signal party_launch(info: Dictionary)
signal avatar_ready(texture: Texture2D)

const APP_ID := 0

const WEB_API_IDENTITY := "wend-nakama"
const PARTY_MAX := 4
const PARTY_GO_KEY := "wend_go"

var _available := false
var _stats_ready := false
var _web_ticket: Dictionary = {}

var party_lobby_id: int = 0
var _party_launched := false

func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		push_warning("SteamManager: GodotSteam extension not present — Steam features disabled.")
		_emit_ready(false)
		return

	var result: Dictionary = Steam.steamInitEx(APP_ID, false)
	if int(result.get("status", -1)) != Steam.STEAM_API_INIT_RESULT_OK:
		push_warning("SteamManager: steamInit failed (%s) — Steam not running or app not owned. Game continues without Steam." % str(result.get("verbal", "unknown")))
		_emit_ready(false)
		return

	_available = true
	Steam.overlay_toggled.connect(_on_overlay_toggled)
	Steam.get_ticket_for_web_api.connect(_on_web_ticket)
	Steam.user_stats_received.connect(_on_user_stats_received)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.join_requested.connect(_on_join_requested)
	Steam.avatar_loaded.connect(_on_avatar_loaded)
	print("SteamManager: Steam OK — %s (id %d)" % [Steam.getPersonaName(), Steam.getSteamID()])
	_emit_ready(true)

func _process(_delta: float) -> void:
	if _available:
		Steam.run_callbacks()

func _emit_ready(ok: bool) -> void:
	steam_ready.emit(ok)

func is_available() -> bool:
	return _available

func get_steam_id() -> int:
	return Steam.getSteamID() if _available else 0

func get_persona_name() -> String:
	return Steam.getPersonaName() if _available else ""

func open_overlay(type: String = "friends") -> void:
	if _available:
		Steam.activateGameOverlay(type)

func request_local_avatar() -> void:
	if _available:
		Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, Steam.getSteamID())

func _on_avatar_loaded(avatar_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	if avatar_id != Steam.getSteamID():
		return
	if avatar_size <= 0 or avatar_buffer.is_empty():
		return
	var img := Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
	avatar_ready.emit(ImageTexture.create_from_image(img))

func _on_overlay_toggled(active: bool, _user_initiated: bool, _app_id: int) -> void:
	overlay_toggled.emit(active)

func get_web_api_ticket_async(timeout_s: float = 8.0) -> String:
	if not _available:
		return ""
	_web_ticket = {}
	if Steam.getAuthTicketForWebApi(WEB_API_IDENTITY) == 0:
		push_warning("SteamManager: getAuthTicketForWebApi returned a null handle.")
		return ""
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while _web_ticket.is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if _web_ticket.is_empty():
		push_warning("SteamManager: web-API ticket timed out.")
		return ""
	if int(_web_ticket.get("result", -1)) != Steam.RESULT_OK:
		push_warning("SteamManager: web-API ticket failed (result %s)." % str(_web_ticket.get("result")))
		return ""
	var buffer: PackedByteArray = _web_ticket.get("buffer", PackedByteArray())
	return buffer.hex_encode()

func _on_web_ticket(_auth_ticket: int, result: int, _ticket_size: int, ticket_buffer: PackedByteArray) -> void:
	_web_ticket = {"result": result, "buffer": ticket_buffer}

func _on_user_stats_received(_game_id: int, result: int, _user_id: int) -> void:
	if result == Steam.RESULT_OK:
		_stats_ready = true
		stats_ready.emit()

func unlock_achievement(api_name: String) -> void:
	if not (_available and _stats_ready):
		return
	if Steam.setAchievement(api_name):
		Steam.storeStats()

func set_stat_int(api_name: String, value: int) -> void:
	if _available and _stats_ready:
		Steam.setStatInt(api_name, value)

func set_stat_float(api_name: String, value: float) -> void:
	if _available and _stats_ready:
		Steam.setStatFloat(api_name, value)

func store_stats() -> void:
	if _available and _stats_ready:
		Steam.storeStats()

func create_party() -> void:
	if not _available or party_lobby_id != 0:
		return
	_party_launched = false
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, PARTY_MAX)

func join_party(lobby_id: int) -> void:
	if not _available or lobby_id == 0:
		return
	if party_lobby_id == lobby_id:
		return
	_party_launched = false
	Steam.joinLobby(lobby_id)

func leave_party() -> void:
	if _available and party_lobby_id != 0:
		Steam.leaveLobby(party_lobby_id)
	party_lobby_id = 0
	_party_launched = false
	party_left.emit()

func invite_overlay() -> void:
	if _available and party_lobby_id != 0:
		Steam.activateGameOverlayInviteDialog(party_lobby_id)

func in_party() -> bool:
	return party_lobby_id != 0

func is_party_leader() -> bool:
	return _available and party_lobby_id != 0 and Steam.getLobbyOwner(party_lobby_id) == Steam.getSteamID()

func party_members() -> Array:
	var out: Array = []
	if not _available or party_lobby_id == 0:
		return out
	var owner := Steam.getLobbyOwner(party_lobby_id)
	var n := Steam.getNumLobbyMembers(party_lobby_id)
	for i in range(n):
		var sid := Steam.getLobbyMemberByIndex(party_lobby_id, i)
		out.append({"steam_id": sid, "name": Steam.getFriendPersonaName(sid), "leader": sid == owner})
	return out

func party_size() -> int:
	if not _available or party_lobby_id == 0:
		return 0
	return Steam.getNumLobbyMembers(party_lobby_id)

func set_party_data(key: String, value: String) -> void:
	if is_party_leader():
		Steam.setLobbyData(party_lobby_id, key, value)

func get_party_data(key: String) -> String:
	if _available and party_lobby_id != 0:
		return Steam.getLobbyData(party_lobby_id, key)
	return ""

func launch_party(info: Dictionary) -> void:
	if is_party_leader():
		Steam.setLobbyData(party_lobby_id, PARTY_GO_KEY, JSON.stringify(info))

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result == Steam.RESULT_OK:
		party_lobby_id = lobby_id
		Steam.setLobbyJoinable(lobby_id, true)
		party_joined.emit(true)
		party_changed.emit()
	else:
		party_joined.emit(false)

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		party_lobby_id = lobby_id
		party_joined.emit(true)
		party_changed.emit()
		_maybe_emit_launch()
	else:
		party_joined.emit(false)

func _on_lobby_chat_update(lobby_id: int, _changed: int, _maker: int, _state: int) -> void:
	if lobby_id == party_lobby_id:
		party_changed.emit()

func _on_lobby_data_update(_success: int, lobby_id: int, _member: int) -> void:
	if lobby_id == party_lobby_id:
		party_changed.emit()
		_maybe_emit_launch()

func _on_join_requested(lobby_id: int, _friend_id: int) -> void:
	join_party(lobby_id)

func _maybe_emit_launch() -> void:
	if _party_launched or party_lobby_id == 0:
		return
	var raw := Steam.getLobbyData(party_lobby_id, PARTY_GO_KEY)
	if raw == "":
		return
	var info = JSON.parse_string(raw)
	if typeof(info) == TYPE_DICTIONARY:
		_party_launched = true
		party_launch.emit(info)
