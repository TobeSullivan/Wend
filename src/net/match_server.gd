extends Node

# Headless dedicated-server lobby authority (godot --headless -- --server). Owns the
# authoritative player list + seats for ONE lobby/match. The server is peer 1 / authority
# but is NOT a player and holds no seat. Clients connect in; the leader (first to join)
# starts the match; the server then loads the match scene authority-only via
# SceneManager.start_networked_pvp(..., seat = -1) (MapLoader builds with local_index < 0).
#
# Option A (sims the match scene) ⇒ one match at a time per server process. Late joiners
# while a match is running are ignored; in-match disconnects are handled by NetMatch.
#
# Lives at /root/SceneManager/MatchServer (persistent autoload child), so it survives the
# lobby→match scene change and keeps the transport alive for the match.

const NetProtocol := preload("res://net/net_protocol.gd")

var _t                          # transport (SceneManager.transport)
var _players: Array = []        # [{id, name, seat}] — joined clients only (server holds no seat)
var _leader_id: int = 0         # first joined peer; the only one allowed to start
var _in_match: bool = false

func _ready() -> void:
	_t = SceneManager.transport
	if _t == null:
		push_error("MatchServer: no transport (start_dedicated_server must host first)")
		return
	_t.received.connect(_on_received)
	_t.peer_joined.connect(_on_peer_joined)
	_t.peer_left.connect(_on_peer_left)
	print("[server] dedicated lobby up on port %d — waiting for players" % NetProtocol.DEFAULT_PORT)

func _on_peer_joined(id: int) -> void:
	if _in_match:
		return  # one match at a time (Option A) — ignore late joiners
	_players.append({"id": id, "name": "Player", "seat": 0})
	if _leader_id == 0:
		_leader_id = id
	_reassign_seats()
	print("[server] peer %d joined (%d in lobby, leader=%d)" % [id, _players.size(), _leader_id])
	_broadcast_lobby_state()

func _on_peer_left(id: int) -> void:
	if _in_match:
		return  # in-match drops are NetMatch's job (forfeit/placement)
	for i in range(_players.size() - 1, -1, -1):
		if _players[i]["id"] == id:
			_players.remove_at(i)
	if id == _leader_id:
		_leader_id = int(_players[0]["id"]) if not _players.is_empty() else 0
	_reassign_seats()
	print("[server] peer %d left (%d in lobby, leader=%d)" % [id, _players.size(), _leader_id])
	_broadcast_lobby_state()

func _on_received(from_id: int, msg: Dictionary) -> void:
	if _in_match:
		return  # match traffic (build inputs / ready) is handled by NetMatch
	match msg.get("t", ""):
		NetProtocol.SET_NAME:
			var nm := String(msg.get("name", "Player")).substr(0, 16)
			var found := false
			for p in _players:
				if int(p["id"]) == from_id:
					p["name"] = nm
					found = true
			if not found:
				# Re-join into a freshly-reset lobby (returning from a match): whoever comes
				# back first becomes the leader and the rest join on them.
				_players.append({"id": from_id, "name": nm, "seat": 0})
				if _leader_id == 0:
					_leader_id = from_id
				_reassign_seats()
			_broadcast_lobby_state()
		NetProtocol.PLAY:
			if from_id == _leader_id and _players.size() >= 2:
				_start_match()

# Seats are contiguous 0..n-1 in join order (the server is never a player, so seat 0 is a
# real client — unlike the old P2P host which sat at seat 0 itself).
func _reassign_seats() -> void:
	for i in range(_players.size()):
		_players[i]["seat"] = i

func _broadcast_lobby_state() -> void:
	# host_id carries the leader (the client whose "Play" the server honours); countdown
	# stays -1 (leader-driven start for the beta — no auto-countdown yet).
	_t.broadcast({"t": NetProtocol.LOBBY_STATE, "players": _players, "host_id": _leader_id, "count": _players.size(), "countdown": -1.0})

func _start_match() -> void:
	_in_match = true
	var seed := int(Time.get_unix_time_from_system())
	var tier := (seed % 5) + 1
	var count := _players.size()
	var names: Array = []
	names.resize(count)
	var seat_by_peer := {}
	for p in _players:
		names[int(p["seat"])] = p["name"]
		seat_by_peer[int(p["id"])] = int(p["seat"])
	print("[server] starting match: %d players, seed=%d tier=%d" % [count, seed, tier])
	_t.broadcast({"t": NetProtocol.START_MATCH, "seed": seed, "tier": tier, "count": count, "names": names})
	# Server loads the match scene authority-only (seat -1 = no local player board).
	SceneManager.start_networked_pvp(seed, tier, count, -1, names, seat_by_peer)

# Called when the match ends (NetMatch authority → SceneManager.reset_dedicated_lobby):
# resume lobby duty so the SAME still-connected players can re-queue. Reconcile the roster
# against who's actually still connected (peers that dropped mid-match were ignored while
# _in_match) and re-pick a leader if the old one left.
func reset_to_lobby() -> void:
	if not _in_match:
		return
	_in_match = false
	# Empty the lobby: players opt back in via "Find New Match" (which re-sends SET_NAME).
	# The FIRST to return leads the new lobby and the rest join on them — nobody waits on a
	# player still sitting on their end screen. (One match at a time per server; concurrent
	# matches are the later Option-B step — see notes/remote_beta_plan.md.)
	_players = []
	_leader_id = 0
	print("[server] match over — lobby cleared; first to return leads")
	_broadcast_lobby_state()
