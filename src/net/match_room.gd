extends Node
class_name MatchRoom

signal finished(match_id)

const MapGeneratorScript := preload("res://scripts/map_generator.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")
const MapLoader := preload("res://scripts/map_loader.gd")
const NetMatchScript := preload("res://net/net_match.gd")
const RoomTransportScript := preload("res://net/room_transport.gd")

var match_id: String = ""
var expected: int = 2
var tier: int = 1
var mode_name: String = "pvp"
var seed_override: int = 0
var window_type: int = 0
var started: bool = false

var _roster: Array = []
var _transport
var _host
var coordinator
var boards: Array = []
var net_match

func setup(real_transport) -> void:
	_transport = RoomTransportScript.new()
	_transport.name = "RoomTransport"
	add_child(_transport)
	_transport.init_room(real_transport)

func add_member(peer: int, member_name: String, user_id: String = "") -> bool:
	if started or _roster.size() >= expected:
		return false
	_roster.append({"peer": peer, "name": member_name, "user_id": user_id, "seat": _roster.size()})
	return true

func member_count() -> int:
	return _roster.size()

func peer_list() -> Array:
	var out: Array = []
	for m in _roster:
		out.append(int(m["peer"]))
	return out

func start() -> void:
	if started:
		return
	started = true
	var count := _roster.size()
	var match_seed := seed_override if seed_override != 0 else absi(hash(match_id))
	var names: Array = []
	names.resize(count)
	var seat_by_peer := {}
	for m in _roster:
		names[int(m["seat"])] = m["name"]
		seat_by_peer[int(m["peer"])] = int(m["seat"])
		_transport.add_peer(int(m["peer"]))

	var godot_mode := MapResourceScript.Mode.PVE if mode_name == "coop" else MapResourceScript.Mode.PVP
	var map = MapGeneratorScript.generate(match_seed, tier, godot_mode, window_type, "")
	_host = Node2D.new()
	_host.name = "MatchHost"
	add_child(_host)
	boards = MapLoader.build_match(_host, map, count, -1, false, names)
	coordinator = boards[0].coordinator

	net_match = NetMatchScript.new()
	net_match.name = "NetMatch"
	add_child(net_match)
	net_match.setup(_transport, coordinator, boards, -1, seat_by_peer)
	net_match.match_finished.connect(_on_match_finished)

	for m in _roster:
		_transport.send_to(int(m["peer"]), {
			"t": NetProtocol.START_MATCH, "seed": match_seed, "tier": tier,
			"count": count, "seat": int(m["seat"]), "names": names,
			"mode": mode_name, "window": window_type})
	print("[room %s] started: %d boards, seed=%d tier=%d mode=%s" % [match_id, count, match_seed, tier, mode_name])

func deliver(from_id: int, msg: Dictionary) -> void:
	if _transport != null:
		_transport.route_received(from_id, msg)

func peer_dropped(id: int) -> void:
	if not started:
		for i in range(_roster.size() - 1, -1, -1):
			if int(_roster[i]["peer"]) == id:
				_roster.remove_at(i)
		return
	if _transport != null:
		_transport.route_peer_left(id)

func _on_match_finished() -> void:
	_submit_team_result()
	finished.emit(match_id)

func _submit_team_result() -> void:
	if mode_name != "coop" or coordinator == null or boards.is_empty():
		return
	var team_damage := 0
	for b in boards:
		team_damage += int(b.total_damage_dealt)
	var rounds := int(coordinator.round_num)
	var names: Array = []
	var ids: Array = []
	var owner := ""
	for m in _roster:
		names.append(String(m.get("name", "")))
		var uid := String(m.get("user_id", ""))
		ids.append(uid)
		if owner == "" and uid != "":
			owner = uid
	if owner == "":
		push_warning("[room %s] roster has no Nakama user_id — team score not submitted" % match_id)
		return
	var group: String = LeaderboardService.GROUPS[clampi(_roster.size() - 1, 0, 3)]
	var board_id := LeaderboardService.trials_board_id(window_type, tier, group)
	var composite := LeaderboardService.encode_score(rounds, team_damage)
	NakamaService.submit_team_score_async({
		"board_id": board_id,
		"owner_id": owner,
		"names": names,
		"user_ids": ids,
		"score": composite,
		"subscore": 0,
	})
