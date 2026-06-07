extends Node

# Headless dedicated-server ROOM ROUTER (godot --headless -- --server). One server process hosts
# MANY concurrent matches: it owns the single real transport and demuxes it by peer→room. Each
# room (match_room.gd) is an isolated authority match with its own RoomTransport; the server is
# peer 1 / authority of every room but is never a player and holds no seat.
#
# Replaces the old single-shared-lobby model. There is no in-process lobby here: Nakama forms the
# lobby (phases 3b–3d) and points each client at this server with a match_id; the client connects
# and sends JOIN_ROOM. A room auto-starts once `expected` members have joined, and is destroyed
# when its match ends. Round-barrier traffic is kilobytes/round, so one small box runs many rooms.
#
# Lives at /root/SceneManager/MatchServer (persistent autoload child) so it owns the transport for
# the whole server lifetime.

const NetProtocol := preload("res://net/net_protocol.gd")
const MatchRoomScript := preload("res://net/match_room.gd")

var _t                          # the real transport (SceneManager.transport)
var _peer_room: Dictionary = {} # enet peer id -> match_id
var _rooms: Dictionary = {}     # match_id -> MatchRoom

func _ready() -> void:
	_t = SceneManager.transport
	if _t == null:
		push_error("MatchServer: no transport (start_dedicated_server must host first)")
		return
	_t.received.connect(_on_received)
	_t.peer_joined.connect(_on_peer_joined)
	_t.peer_left.connect(_on_peer_left)
	print("[server] room router up on port %d — waiting for JOIN_ROOM" % NetProtocol.DEFAULT_PORT)

func room_count() -> int:
	return _rooms.size()

func _on_peer_joined(_id: int) -> void:
	pass  # nothing until the peer declares its room via JOIN_ROOM

func _on_received(from_id: int, msg: Dictionary) -> void:
	if String(msg.get("t", "")) == NetProtocol.JOIN_ROOM:
		_join_room(from_id, msg)
		return
	# In-match traffic: route to the sender's room (and only that room).
	var mid := String(_peer_room.get(from_id, ""))
	if mid != "" and _rooms.has(mid):
		_rooms[mid].deliver(from_id, msg)

func _join_room(peer: int, msg: Dictionary) -> void:
	var mid := String(msg.get("match_id", ""))
	if mid == "":
		return
	var room
	if _rooms.has(mid):
		room = _rooms[mid]
	else:
		room = MatchRoomScript.new()
		room.name = "Room_%s" % mid
		room.match_id = mid
		room.expected = maxi(2, int(msg.get("expected", 2)))
		room.tier = int(msg.get("tier", 1))
		room.finished.connect(_on_room_finished)
		add_child(room)
		room.setup(_t)
		_rooms[mid] = room
		print("[server] room %s created (expected %d)" % [mid, room.expected])
	if room.started:
		return  # late join into a running room — ignored for the beta (reconnect is a later task)
	if room.add_member(peer, String(msg.get("name", "Player"))):
		_peer_room[peer] = mid
		print("[server] peer %d → room %s (%d/%d)" % [peer, mid, room.member_count(), room.expected])
		if room.member_count() >= room.expected:
			room.start()

func _on_peer_left(id: int) -> void:
	var mid := String(_peer_room.get(id, ""))
	_peer_room.erase(id)
	if mid != "" and _rooms.has(mid):
		_rooms[mid].peer_dropped(id)

func _on_room_finished(mid: String) -> void:
	if not _rooms.has(mid):
		return
	var room = _rooms[mid]
	for p in room.peer_list():
		_peer_room.erase(p)
	_rooms.erase(mid)
	room.queue_free()
	print("[server] room %s ended — %d room(s) remain" % [mid, _rooms.size()])
