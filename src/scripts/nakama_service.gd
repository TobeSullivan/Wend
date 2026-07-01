extends Node

signal session_ready(session)
signal session_failed(reason)

const CFG_PATH := "res://nakama_local.cfg"

var client: NakamaClient = null
var session: NakamaSession = null
var socket: NakamaSocket = null

var _host := "127.0.0.1"
var _port := 7350
var _scheme := "http"
var _server_key := ""
var _http_key := "defaulthttpkey"
var _configured := false

func _ready() -> void:
	_load_config()

func _load_config() -> void:
	var cf := ConfigFile.new()
	var err := cf.load(CFG_PATH)
	if err != OK:
		push_warning("NakamaService: %s missing (err %d) — backend disabled. Copy nakama_local.cfg.example -> nakama_local.cfg." % [CFG_PATH, err])
		return
	_host = String(cf.get_value("nakama", "host", _host))
	_port = int(cf.get_value("nakama", "port", _port))
	_scheme = String(cf.get_value("nakama", "scheme", _scheme))
	_server_key = String(cf.get_value("nakama", "server_key", ""))
	_http_key = String(cf.get_value("nakama", "http_key", _http_key))
	if _server_key == "" or _server_key.begins_with("PUT_"):
		push_warning("NakamaService: server_key not set in %s — backend disabled." % CFG_PATH)
		return
	_configured = true

func is_configured() -> bool:
	return _configured

func submit_team_score_async(payload: Dictionary) -> bool:
	if not _configured:
		return false
	if client == null:
		client = Nakama.create_client(_server_key, _host, _port, _scheme)
	payload["secret"] = OS.get_environment("WEND_SERVER_SUBMIT_SECRET")
	var res = await client.rpc_async_with_key(_http_key, "submit_team_score", JSON.stringify(payload))
	if res == null or res.is_exception():
		push_warning("NakamaService: submit_team_score failed (%s)" % (str(res.get_exception()) if res != null else "null"))
		return false
	return true

func report_client_log_async(payload: Dictionary) -> bool:
	if not has_session() or client == null:
		return false
	var res = await client.rpc_async(session, "client_log", JSON.stringify(payload))
	if res == null or res.is_exception():
		push_warning("NakamaService: client_log failed (%s)" % (str(res.get_exception()) if res != null else "null result"))
		return false
	return true

func fetch_display_names(ids: Array) -> Dictionary:
	var out := {}
	if not has_session() or client == null or ids.is_empty():
		return out
	var res = await client.get_users_async(session, PackedStringArray(ids))
	if res == null or res.is_exception():
		return out
	for u in res.users:
		var nm := String(u.display_name).strip_edges()
		if nm == "":
			nm = String(u.username)
		out[String(u.id)] = nm
	return out

func has_session() -> bool:
	return session != null and session.valid and not session.is_expired()

func connect_backend() -> bool:
	if not _configured:
		session_failed.emit("not_configured")
		return false
	if client == null:
		client = Nakama.create_client(_server_key, _host, _port, _scheme)

	var want_steam := SteamManager.is_available()
	var saved_kind := String(SaveData.data.get("nakama_auth_kind", ""))

	if session == null and (saved_kind == "steam" or not want_steam):
		var tok := String(SaveData.data.get("nakama_token", ""))
		var rtok := String(SaveData.data.get("nakama_refresh_token", ""))
		if tok != "":
			var restored := NakamaSession.new(tok, false, rtok)
			if not restored.is_expired():
				session = restored
			elif rtok != "" and not restored.is_refresh_expired():
				var refreshed: NakamaSession = await client.session_refresh_async(restored)
				if not refreshed.is_exception():
					session = refreshed

	if session == null and want_steam:
		session = await _authenticate_steam()
		if session != null:
			SaveData.data["nakama_auth_kind"] = "steam"

	if session == null:
		var authed: NakamaSession = await client.authenticate_device_async(_device_id())
		if authed.is_exception():
			session_failed.emit(str(authed.get_exception()))
			return false
		session = authed
		SaveData.data["nakama_auth_kind"] = "device"

	_persist_session()
	LeaderboardService.set_backend(NakamaBackend.new(self))
	session_ready.emit(session)
	return true

func get_account_async():
	if not has_session():
		return null
	return await client.get_account_async(session)

func ensure_socket() -> NakamaSocket:
	if socket != null and socket.is_connected_to_host():
		return socket
	if not has_session():
		return null
	socket = Nakama.create_socket_from(client)
	await socket.connect_async(session)
	if not socket.is_connected_to_host():
		push_warning("NakamaService: socket failed to connect to %s:%d" % [_host, _port])
		socket = null
	return socket

func _authenticate_steam() -> NakamaSession:
	var ticket := await SteamManager.get_web_api_ticket_async()
	if ticket == "":
		return null
	var payload := JSON.stringify({
		"ticket": ticket,
		"identity": SteamManager.WEB_API_IDENTITY,
		"persona": SteamManager.get_persona_name(),
	})
	var res = await client.rpc_async_with_key(_http_key, "steam_auth", payload)
	if res.is_exception():
		push_warning("NakamaService: steam_auth RPC failed (%s) — falling back to device auth." % str(res.get_exception()))
		return null
	var data = JSON.parse_string(res.payload)
	if typeof(data) != TYPE_DICTIONARY or not data.has("token"):
		push_warning("NakamaService: steam_auth returned no token — falling back to device auth.")
		return null
	return NakamaSession.new(String(data["token"]), bool(data.get("created", false)), String(data.get("refresh", "")))

func _persist_session() -> void:
	SaveData.data["nakama_token"] = session.token
	SaveData.data["nakama_refresh_token"] = session.refresh_token
	SaveData.save()

func _device_id() -> String:
	var did := String(SaveData.data.get("nakama_device_id", ""))
	if did == "":
		did = _new_uuid()
		SaveData.data["nakama_device_id"] = did
		SaveData.save()
	return did

func _new_uuid() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]
