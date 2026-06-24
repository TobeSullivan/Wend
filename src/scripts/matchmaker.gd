extends Node
class_name Matchmaker

signal matched(info)
signal escalated(step, info)
signal failed(reason)

const RANKED_SCHEDULE := [
	{"at": 0.0,  "query": "+properties.mode:ranked", "min": 8, "max": 8},
	{"at": 15.0, "query": "+properties.mode:ranked", "min": 6, "max": 8},
	{"at": 30.0, "query": "+properties.mode:ranked", "min": 4, "max": 8},
]

var _socket
var _schedule: Array = []
var _string_props: Dictionary = {}
var _numeric_props: Dictionary = {}
var _ticket := ""
var _step := -1
var _elapsed := 0.0
var _running := false
var _advancing := false

func is_running() -> bool:
	return _running

func current_ticket() -> String:
	return _ticket

func start(socket, schedule: Array = RANKED_SCHEDULE, string_props: Dictionary = {"mode": "ranked"}, numeric_props: Dictionary = {}) -> void:
	if _running:
		return
	_socket = socket
	_schedule = schedule
	_string_props = string_props
	_numeric_props = numeric_props
	_elapsed = 0.0
	_step = -1
	_running = true
	if not _socket.received_matchmaker_matched.is_connected(_on_matched):
		_socket.received_matchmaker_matched.connect(_on_matched)
	await _advance_to(0)

func cancel() -> void:
	_running = false
	if _socket != null and _socket.received_matchmaker_matched.is_connected(_on_matched):
		_socket.received_matchmaker_matched.disconnect(_on_matched)
	if _ticket != "" and _socket != null:
		await _socket.remove_matchmaker_async(_ticket)
	_ticket = ""

func _process(dt: float) -> void:
	if not _running or _advancing:
		return
	_elapsed += dt
	var target := _step
	for i in range(_schedule.size()):
		if _elapsed >= float(_schedule[i]["at"]):
			target = i
	if target > _step:
		_advance_to(target)

func _advance_to(step: int) -> void:
	if not _running or step <= _step or _advancing:
		return
	_advancing = true
	if _ticket != "":
		await _socket.remove_matchmaker_async(_ticket)
		_ticket = ""
	if not _running:
		_advancing = false
		return
	var s: Dictionary = _schedule[step]
	var res = await _socket.add_matchmaker_async(String(s["query"]), int(s["min"]), int(s["max"]), _string_props, _numeric_props)
	if res == null or res.is_exception():
		_advancing = false
		_running = false
		failed.emit("add_matchmaker failed: %s" % (str(res.get_exception()) if res != null else "null"))
		return
	_ticket = res.ticket
	_step = step
	_advancing = false
	escalated.emit(step, {"query": String(s["query"]), "min": int(s["min"]), "max": int(s["max"])})

func _on_matched(m) -> void:
	if not _running:
		return
	_running = false
	_ticket = ""
	var users: Array = []
	for u in m.users:
		users.append({"user_id": String(u.presence.user_id), "username": String(u.presence.username)})
	matched.emit({"match_id": String(m.match_id), "token": String(m.token), "ticket": String(m.ticket), "users": users})
