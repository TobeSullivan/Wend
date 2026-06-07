extends Node

# Verifies the dedicated server runs MANY concurrent matches keyed by match_id, fully isolated
# (phase 3a). Drives the room router (match_server.gd) through a MockTransport: forms 2 rooms of 2
# peers, asserts each room is its own match with its own coordinator, that traffic is routed only
# within a room (no cross-talk — structurally guaranteed by RoomTransport's per-room peer set), and
# that a room tears itself down on match end while the other keeps running.
# Run by swapping run/main_scene to res://tools/rooms_test.tscn.

const MatchServerScript := preload("res://net/match_server.gd")
const NetProtocol := preload("res://net/net_protocol.gd")

# Stands in for the server's real ENet transport: records every send_to and lets the test inject
# inbound traffic / peer lifecycle as if real clients were connected.
class MockTransport extends MatchTransport:
	var sends: Array = []
	func is_authority() -> bool: return true
	func unique_id() -> int: return 1
	func send_to(id: int, msg: Dictionary) -> void: sends.append({"to": id, "msg": msg})
	func broadcast(_msg: Dictionary) -> void: pass
	func inj_recv(from: int, msg: Dictionary) -> void: received.emit(from, msg)
	func inj_join(id: int) -> void: peer_joined.emit(id)
	func inj_left(id: int) -> void: peer_left.emit(id)
	func clear() -> void: sends.clear()
	func to(id: int) -> Array:
		var out: Array = []
		for s in sends:
			if int(s["to"]) == id:
				out.append(s["msg"])
		return out

var _fails := 0

func _ready() -> void:
	await _run()
	get_tree().quit(_fails)

func _ok(label: String, cond: bool) -> void:
	if cond:
		print("  OK  ", label)
	else:
		print("  FAIL  ", label)
		_fails += 1

func _run() -> void:
	print("=== concurrent rooms ===")
	var mock := MockTransport.new()
	mock.name = "MockTransport"
	add_child(mock)
	SceneManager.transport = mock

	var server = MatchServerScript.new()
	server.name = "MatchServer"
	add_child(server)
	await get_tree().process_frame

	# Two rooms, two peers each — each pair completes its room and auto-starts.
	mock.inj_join(10); mock.inj_recv(10, _join("A", "p10", 2, 1))
	mock.inj_join(11); mock.inj_recv(11, _join("A", "p11", 2, 1))
	mock.inj_join(20); mock.inj_recv(20, _join("B", "p20", 2, 3))
	mock.inj_join(21); mock.inj_recv(21, _join("B", "p21", 2, 3))
	await get_tree().process_frame
	await get_tree().process_frame

	var roomA = server.get_node_or_null("Room_A")
	var roomB = server.get_node_or_null("Room_B")
	_ok("2 rooms exist", server.room_count() == 2)
	_ok("room A started", roomA != null and roomA.started)
	_ok("room B started", roomB != null and roomB.started)
	_ok("room A peers == [10,11]", roomA != null and roomA.peer_list() == [10, 11])
	_ok("room B peers == [20,21]", roomB != null and roomB.peer_list() == [20, 21])
	_ok("rooms have distinct coordinators", roomA != null and roomB != null and roomA.coordinator != roomB.coordinator)
	_ok("rooms have distinct NetMatch", roomA != null and roomB != null and roomA.net_match != roomB.net_match)

	# START_MATCH delivered per-peer with the correct seat.
	_ok("peer 10 START_MATCH seat 0", _has_start(mock.to(10), 0, 1))
	_ok("peer 11 START_MATCH seat 1", _has_start(mock.to(11), 1, 1))
	_ok("peer 20 START_MATCH seat 0 tier 3", _has_start(mock.to(20), 0, 3))
	_ok("peer 21 START_MATCH seat 1 tier 3", _has_start(mock.to(21), 1, 3))

	# Routing isolation: a build input from room-A peer 10 is relayed within room A only.
	mock.clear()
	mock.inj_recv(10, NetProtocol.build_input_place(0, Vector2i(3, 3)))
	await get_tree().process_frame
	_ok("build input relayed to room-A peer 11", _count(mock.to(11), NetProtocol.BUILD_INPUT) >= 1)
	_ok("build input NOT leaked to room-B peer 20", _count(mock.to(20), NetProtocol.BUILD_INPUT) == 0)
	_ok("build input NOT leaked to room-B peer 21", _count(mock.to(21), NetProtocol.BUILD_INPUT) == 0)

	# Each room's authority clock reaches only its own peers (give the 0.2s periodic a window).
	mock.clear()
	await get_tree().create_timer(0.35).timeout
	_ok("room A clock → peer 10", _count(mock.to(10), NetProtocol.CLOCK) > 0)
	_ok("room A clock → peer 11", _count(mock.to(11), NetProtocol.CLOCK) > 0)
	_ok("room B clock → peer 20", _count(mock.to(20), NetProtocol.CLOCK) > 0)
	_ok("room B clock → peer 21", _count(mock.to(21), NetProtocol.CLOCK) > 0)

	# Teardown: dropping one of room A's two peers forfeits → last board standing → match ends.
	mock.inj_left(10)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok("room A torn down on match end", server.get_node_or_null("Room_A") == null)
	_ok("room B still running", server.room_count() == 1 and server.get_node_or_null("Room_B") != null)

	SceneManager.transport = null
	if _fails == 0:
		print("RESULT OK — concurrent rooms: isolated builds, per-room routing, clean teardown")
	else:
		print("RESULT FAIL — ", _fails, " check(s) failed")

func _join(mid: String, name: String, expected: int, tier: int) -> Dictionary:
	return {"t": NetProtocol.JOIN_ROOM, "match_id": mid, "name": name, "expected": expected, "tier": tier}

func _has_start(msgs: Array, seat: int, tier: int) -> bool:
	for m in msgs:
		if String(m.get("t", "")) == NetProtocol.START_MATCH and int(m.get("seat", -1)) == seat and int(m.get("tier", -1)) == tier:
			return true
	return false

func _count(msgs: Array, t: String) -> int:
	var n := 0
	for m in msgs:
		if String(m.get("t", "")) == t:
			n += 1
	return n
