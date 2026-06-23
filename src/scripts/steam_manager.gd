extends Node

# SteamManager — autoload owning the Steamworks SDK lifecycle (GodotSteam GDExtension 4.19.1,
# Steamworks SDK 1.64). Everything here is OPTIONAL at runtime: if Steam isn't running, the
# extension fails to init and the game keeps working (device-auth, no overlay, no achievements).
#
# Layers:
#   Phase 1 — init + per-frame callbacks + overlay + identity (steam id / persona name).
#   Phase 2 — get_web_api_ticket_async(): a Steam auth ticket for NakamaService to sign in with
#             (see scripts/nakama_service.gd). Steam identity replaces anonymous device-auth.
#   Phase 3 — achievement/stat helpers. NOTE: achievements/stats must be DEFINED in Steamworks
#             (Stats & Achievements) before these do anything; until then they're no-ops server-side.
#
# steam_appid.txt (repo: src/steam_appid.txt = 4884650) lets the editor + a locally-run export
# init without launching through Steam. It is EXCLUDED from the shipped depot (see export preset).

signal steam_ready(available: bool)            # emitted once after init attempt
signal overlay_toggled(active: bool)           # Steam overlay opened/closed
signal stats_ready()                           # current user stats loaded (achievements writable)

# 0 = auto-detect appid from steam_appid.txt (editor / local export) or the Steam launch context
# (shipped build). Keep 0 so the same code works for the playtest app and any future store app.
const APP_ID := 0

# Identity string baked into the web-API auth ticket. MUST match what the validating server
# (Nakama) expects. Nakama's authenticateSteam validates via the Steam Web API without an
# identity, so this is empty. If you later set an identity on the server, set it here too.
const WEB_API_IDENTITY := "wend-nakama"

var _available := false
var _stats_ready := false
var _web_ticket: Dictionary = {}              # filled by the get_ticket_for_web_api callback

func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		push_warning("SteamManager: GodotSteam extension not present — Steam features disabled.")
		_emit_ready(false)
		return

	# embed_callbacks=false → we pump Steam.run_callbacks() ourselves in _process (explicit/controlled).
	var result: Dictionary = Steam.steamInitEx(APP_ID, false)
	if int(result.get("status", -1)) != Steam.STEAM_API_INIT_RESULT_OK:
		push_warning("SteamManager: steamInit failed (%s) — Steam not running or app not owned. Game continues without Steam." % str(result.get("verbal", "unknown")))
		_emit_ready(false)
		return

	_available = true
	Steam.overlay_toggled.connect(_on_overlay_toggled)
	Steam.get_ticket_for_web_api.connect(_on_web_ticket)
	Steam.user_stats_received.connect(_on_user_stats_received)
	# steamInitEx auto-requests this user's stats; user_stats_received fires when they've loaded
	# (Phase 3 — see _on_user_stats_received). No explicit request call needed in 4.19.
	print("SteamManager: Steam OK — %s (id %d)" % [Steam.getPersonaName(), Steam.getSteamID()])
	_emit_ready(true)

func _process(_delta: float) -> void:
	if _available:
		Steam.run_callbacks()

func _emit_ready(ok: bool) -> void:
	steam_ready.emit(ok)

# ----- Phase 1: identity + overlay -----------------------------------------------------------

func is_available() -> bool:
	return _available

func get_steam_id() -> int:
	return Steam.getSteamID() if _available else 0

func get_persona_name() -> String:
	return Steam.getPersonaName() if _available else ""

# type: "friends" | "community" | "players" | "settings" | "stats" | "achievements" | ...
func open_overlay(type: String = "friends") -> void:
	if _available:
		Steam.activateGameOverlay(type)

func _on_overlay_toggled(active: bool, _user_initiated: bool, _app_id: int) -> void:
	overlay_toggled.emit(active)

# ----- Phase 2: web-API auth ticket for Nakama -----------------------------------------------

# Requests a Steam web-API auth ticket and returns it hex-encoded (the token Nakama's
# authenticate_steam_async expects), or "" on failure/timeout. Safe to await.
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

# ----- Phase 3: achievements + stats ---------------------------------------------------------
# Define the achievement/stat API names in Steamworks (Stats & Achievements) first; these helpers
# reference them by that API name. Calls are no-ops until Steam is available AND stats have loaded.

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
