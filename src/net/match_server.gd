extends Node

const MatchRoomScript := preload("res://net/match_room.gd")

var _t
var _peer_room: Dictionary = {}
var _rooms: Dictionary = {}

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

func _on_peer_joined(id: int) -> void:
	print("[server] peer %d connected (%d room(s) live)" % [id, _rooms.size()])

func _on_received(from_id: int, msg: Dictionary) -> void:
	if String(msg.get("t", "")) == NetProtocol.JOIN_ROOM:
		_join_room(from_id, msg)
		return
	var mid := String(_peer_room.get(from_id, ""))
	if mid != "" and _rooms.has(mid):
		_rooms[mid].deliver(from_id, msg)

func _join_room(peer: int, msg: Dictionary) -> void:
	var mid := String(msg.get("match_id", ""))
	print("[server] JOIN_ROOM peer=%d match=%s expected=%s is_host=%s mode=%s" % [
		peer, mid, str(msg.get("expected", "?")), str(msg.get("is_host", false)), str(msg.get("mode", "pvp"))])
	if mid == "":
		print("[server] JOIN_ROOM peer=%d rejected: empty match_id" % peer)
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
		room.mode_name = String(msg.get("mode", "pvp"))
		room.seed_override = int(msg.get("seed", 0))
		room.window_type = int(msg.get("window", 0))
		room.finished.connect(_on_room_finished)
		add_child(room)
		room.setup(_t)
		_rooms[mid] = room
		print("[server] room %s created (expected %d)" % [mid, room.expected])
	if room.started:
		print("[server] peer %d rejected: room %s already started" % [peer, mid])
		return
	if room.add_member(peer, String(msg.get("name", "Player")), String(msg.get("user_id", "")), bool(msg.get("is_host", false))):
		_peer_room[peer] = mid
		print("[server] peer %d → room %s (%d/%d)" % [peer, mid, room.member_count(), room.expected])
		if room.member_count() >= room.expected:
			print("[server] room %s reached %d/%d — starting" % [mid, room.member_count(), room.expected])
			room.start()
		else:
			print("[server] room %s waiting for %d more peer(s)" % [mid, room.expected - room.member_count()])
	else:
		print("[server] peer %d rejected by room %s (started=%s, %d/%d)" % [
			peer, mid, str(room.started), room.member_count(), room.expected])

func _on_peer_left(id: int) -> void:
	var mid := String(_peer_room.get(id, ""))
	print("[server] peer %d disconnected (room %s)" % [id, mid if mid != "" else "none"])
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
