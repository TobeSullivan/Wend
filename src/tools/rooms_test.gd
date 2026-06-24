extends Node

const MatchServerScript := preload("res://net/match_server.gd")

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

	_ok("peer 10 START_MATCH seat 0", _has_start(mock.to(10), 0, 1))
	_ok("peer 11 START_MATCH seat 1", _has_start(mock.to(11), 1, 1))
	_ok("peer 20 START_MATCH seat 0 tier 3", _has_start(mock.to(20), 0, 3))
	_ok("peer 21 START_MATCH seat 1 tier 3", _has_start(mock.to(21), 1, 3))

	mock.clear()
	mock.inj_recv(10, NetProtocol.build_input_place(0, Vector2i(3, 3)))
	await get_tree().process_frame
	_ok("build input relayed to room-A peer 11", _count(mock.to(11), NetProtocol.BUILD_INPUT) >= 1)
	_ok("build input NOT leaked to room-B peer 20", _count(mock.to(20), NetProtocol.BUILD_INPUT) == 0)
	_ok("build input NOT leaked to room-B peer 21", _count(mock.to(21), NetProtocol.BUILD_INPUT) == 0)

	mock.clear()
	await get_tree().create_timer(0.35).timeout
	_ok("room A clock → peer 10", _count(mock.to(10), NetProtocol.CLOCK) > 0)
	_ok("room A clock → peer 11", _count(mock.to(11), NetProtocol.CLOCK) > 0)
	_ok("room B clock → peer 20", _count(mock.to(20), NetProtocol.CLOCK) > 0)
	_ok("room B clock → peer 21", _count(mock.to(21), NetProtocol.CLOCK) > 0)

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

func _join(mid: String, player_name: String, expected: int, tier: int) -> Dictionary:
	return {"t": NetProtocol.JOIN_ROOM, "match_id": mid, "name": player_name, "expected": expected, "tier": tier}

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
