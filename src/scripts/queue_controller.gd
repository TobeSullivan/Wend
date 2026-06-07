extends Node
class_name QueueController

# Client glue for the ranked queue (phase 3d): Matchmaker → forming LobbyClient → on GO, connect to
# the Godot match server and JOIN_ROOM → on START_MATCH, launch the networked match. Bridges the
# Nakama meta layer (queue + lobby) to the Godot match authority (a room on the dedicated server).
# Drives one queue attempt; the lobby UI owns one of these and reacts to its signals.

signal phase_changed(phase, info)   # Phase + a context dict (reason/mode/lobby state)
signal lobby_update(info)           # {count, max, floor, present, voted, you_voted}

enum Phase { IDLE, QUEUING, LOBBY, CONNECTING, IN_MATCH, ERROR }

const NetProtocol := preload("res://net/net_protocol.gd")
const MatchmakerScript := preload("res://scripts/matchmaker.gd")
const LobbyClientScript := preload("res://scripts/lobby_client.gd")

var phase: Phase = Phase.IDLE
var _mm
var _lobby
var _socket
var _go := {}
var _player_name := "Player"
var _my_mmr := RankedLadder.SEED_MMR  # the local player's hidden MMR — announced to the lobby (ranked)

func _emit(p: Phase, info: Dictionary = {}) -> void:
	phase = p
	phase_changed.emit(p, info)

func start_queue(player_name: String = "Player", mode: String = "ranked") -> bool:
	if phase != Phase.IDLE:
		return false
	_player_name = player_name
	if mode == "ranked":
		_my_mmr = SaveData.ranked_mmr()
	if not NakamaService.has_session():
		if not await NakamaService.connect_backend():
			_emit(Phase.ERROR, {"reason": "not connected to backend"})
			return false
	_socket = await NakamaService.ensure_socket()
	if _socket == null:
		_emit(Phase.ERROR, {"reason": "no realtime socket"})
		return false
	_mm = MatchmakerScript.new(); _mm.name = "Matchmaker"; add_child(_mm)
	_mm.matched.connect(_on_matched)
	_mm.failed.connect(func(r): _emit(Phase.ERROR, {"reason": r}))
	_emit(Phase.QUEUING, {"mode": mode})
	await _mm.start(_socket, MatchmakerScript.RANKED_SCHEDULE, {"mode": mode}, {})
	return true

func cancel() -> void:
	if _mm != null:
		await _mm.cancel()
	if _lobby != null:
		await _lobby.leave()
	_emit(Phase.IDLE, {})

func vote() -> void:
	if _lobby != null:
		await _lobby.vote()

func _on_matched(info) -> void:
	_lobby = LobbyClientScript.new(); _lobby.name = "Lobby"; add_child(_lobby)
	_lobby.lobby_state.connect(func(s): lobby_update.emit(s))
	_lobby.launched.connect(_on_go)
	_lobby.closed.connect(func(r): _emit(Phase.ERROR, {"reason": r}))
	_emit(Phase.LOBBY, {})
	await _lobby.join(_socket, String(info.get("match_id", "")), String(NakamaService.session.user_id), _my_mmr)

# Lobby launched → connect to the Godot room router (ENet/UDP) and declare our room.
func _on_go(info) -> void:
	_go = info
	# Carry the lobby-average MMR into the match (the net-positive LP anchor, read at match end).
	# Rides the Nakama GO message — the Godot match server stays MMR-agnostic.
	SceneManager.pending_ranked_avg_mmr = float(info.get("avg_mmr", RankedLadder.SEED_MMR))
	SceneManager.pending_is_ranked = true
	_emit(Phase.CONNECTING, info)
	var err := SceneManager.net_join(String(info.get("host", "")))  # DEFAULT_PORT 8771
	if err != OK:
		_emit(Phase.ERROR, {"reason": "could not reach match server (%d)" % err})
		return
	var t = SceneManager.transport
	t.received.connect(_on_server_msg)
	t.connection_succeeded.connect(_send_join_room)
	t.connection_failed.connect(func(): _emit(Phase.ERROR, {"reason": "match server unreachable"}))

func _send_join_room() -> void:
	var mid := String(_go.get("match_id", ""))
	# tier derives from match_id, so every client in this room agrees without extra coordination.
	var tier := (absi(hash(mid)) % 5) + 1
	SceneManager.transport.send_to_authority({
		"t": NetProtocol.JOIN_ROOM, "match_id": mid, "name": _player_name,
		"expected": int(_go.get("count", 2)), "tier": tier})

# The server started the room → hand off to the existing networked-match scene path.
func _on_server_msg(_from: int, msg: Dictionary) -> void:
	if String(msg.get("t", "")) != NetProtocol.START_MATCH:
		return
	var t = SceneManager.transport
	if t.received.is_connected(_on_server_msg):
		t.received.disconnect(_on_server_msg)  # the match scene's NetMatch takes over the transport
	_emit(Phase.IN_MATCH, msg)
	if _lobby != null:
		_lobby.leave()
	SceneManager.start_networked_pvp(int(msg["seed"]), int(msg["tier"]), int(msg["count"]),
		int(msg["seat"]), msg.get("names", []))
