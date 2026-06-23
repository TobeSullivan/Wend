extends Node

# NakamaService — autoload owning the connection to the meta backend (identity, leaderboards,
# matchmaking). The match AUTHORITY stays in the headless Godot match server; this is META only
# (notes/multiplayer_architecture.md, notes/remote_beta_plan.md).
#
# Connection details come from a gitignored res://nakama_local.cfg (copy nakama_local.cfg.example
# and paste the server key from the box .env). Device-auth for the beta; Steam auth lands later.
#
# NAME NOTE: deliberately NOT named "NakamaClient" — that's the addon's class_name, and an autoload
# of that name would shadow the type (see memory: reference_godot_native_class_shadow). The addon's
# own autoload is "Nakama" (the factory); this service sits on top of it.

signal session_ready(session)   # authenticated (fresh, restored, or refreshed)
signal session_failed(reason)   # could not authenticate / not configured

const CFG_PATH := "res://nakama_local.cfg"

var client: NakamaClient = null
var session: NakamaSession = null
var socket: NakamaSocket = null

var _host := "127.0.0.1"
var _port := 7350
var _scheme := "http"
var _server_key := ""
var _http_key := "defaulthttpkey"   # runtime http key for no-session RPC (steam_auth); Nakama default
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

func has_session() -> bool:
	return session != null and session.valid and not session.is_expired()

# Authenticate against the backend. Restores a persisted session (refreshing if needed) and
# falls back to device auth. Idempotent — safe to call again. Returns true on success.
func connect_backend() -> bool:
	if not _configured:
		session_failed.emit("not_configured")
		return false
	if client == null:
		client = Nakama.create_client(_server_key, _host, _port, _scheme)

	# 1. Try a persisted session (token + refresh token from SaveData).
	if session == null:
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

	# 2. Steam identity via the custom steam_auth RPC (Nakama's built-in authenticate_steam can't
	#    validate modern web-API tickets — it omits the required `identity`). Falls through to
	#    device auth if Steam is unavailable or the ticket can't be obtained/validated.
	if session == null and SteamManager.is_available():
		session = await _authenticate_steam()

	# 3. Device-auth fallback (creates the account on first run; also the non-Steam path).
	if session == null:
		var authed: NakamaSession = await client.authenticate_device_async(_device_id())
		if authed.is_exception():
			session_failed.emit(str(authed.get_exception()))
			return false
		session = authed

	_persist_session()
	# Light up the leaderboard surfaces with real data (LocalBackend → NakamaBackend). Reads
	# through LeaderboardService are already await-tolerant, so this swap needs no UI changes.
	LeaderboardService.set_backend(NakamaBackend.new(self))
	session_ready.emit(session)
	return true

# Fetch the authenticated account (ApiAccount) or null if not authenticated.
func get_account_async():
	if not has_session():
		return null
	return await client.get_account_async(session)

# Lazily open (and return) the realtime socket, or null on failure. Needed for matchmaking later.
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

# Steam login via the server's steam_auth RPC: fetch a web-API ticket, exchange it (using the
# runtime http_key, since we have no session yet) for a server-minted Nakama session keyed by the
# verified Steam ID. Returns null on any failure so connect_backend() falls back to device auth.
# Requires the server to have STEAM_PUBLISHER_KEY configured (see deploy/nakama).
func _authenticate_steam() -> NakamaSession:
	var ticket := await SteamManager.get_web_api_ticket_async()
	if ticket == "":
		return null
	var payload := JSON.stringify({"ticket": ticket, "identity": SteamManager.WEB_API_IDENTITY})
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

# A stable per-install device id (Nakama requires 10..128 chars). Generated once, persisted.
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
