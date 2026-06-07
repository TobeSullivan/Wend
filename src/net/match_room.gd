extends Node
class_name MatchRoom

# One concurrent match on the dedicated server, keyed by match_id. Holds the authority-only match
# subtree (boards + MatchCoordinator, built WITHOUT change_scene so many rooms coexist), a
# RoomTransport scoping traffic to this room's peers, and the NetMatch authority bridge. Mirrors
# what main.gd does for a single client match, but isolated and headless (local_index = -1, no UI).
#
# Lifecycle: add_member() while forming → start() once `expected` joined → emits finished() when
# the match ends (last board standing / all-but-one forfeited), at which point the router frees it.

signal finished(match_id)

const MapGeneratorScript := preload("res://scripts/map_generator.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")
const MapLoader := preload("res://scripts/map_loader.gd")
const NetMatchScript := preload("res://net/net_match.gd")
const RoomTransportScript := preload("res://net/room_transport.gd")
const NetProtocol := preload("res://net/net_protocol.gd")

var match_id: String = ""
var expected: int = 2
var tier: int = 1
var started: bool = false

var _roster: Array = []          # [{peer:int, name:String, seat:int}]
var _transport                   # RoomTransport
var _host                        # Node2D holding the match subtree
var coordinator                  # MatchCoordinator (authority sim)
var boards: Array = []
var net_match                    # NetMatch

func setup(real_transport) -> void:
	_transport = RoomTransportScript.new()
	_transport.name = "RoomTransport"
	add_child(_transport)
	_transport.init_room(real_transport)

func add_member(peer: int, name: String) -> bool:
	if started or _roster.size() >= expected:
		return false
	_roster.append({"peer": peer, "name": name, "seat": _roster.size()})
	return true

func member_count() -> int:
	return _roster.size()

func peer_list() -> Array:
	var out: Array = []
	for m in _roster:
		out.append(int(m["peer"]))
	return out

# Build the authority match and hand each client its seat. Seats are 0..n-1 in join order.
func start() -> void:
	if started:
		return
	started = true
	var count := _roster.size()
	var seed := absi(hash(match_id))           # deterministic per room → all clients agree on the map
	var names: Array = []
	names.resize(count)
	var seat_by_peer := {}
	for m in _roster:
		names[int(m["seat"])] = m["name"]
		seat_by_peer[int(m["peer"])] = int(m["seat"])
		_transport.add_peer(int(m["peer"]))

	var map = MapGeneratorScript.generate(seed, tier, MapResourceScript.Mode.PVP)
	_host = Node2D.new()
	_host.name = "MatchHost"
	add_child(_host)
	# Authority-only build (local_index = -1): sims all boards for resolve_lives, no UI/camera.
	boards = MapLoader.build_match(_host, map, count, -1, false, names)
	coordinator = boards[0].coordinator

	net_match = NetMatchScript.new()
	net_match.name = "NetMatch"
	add_child(net_match)
	net_match.setup(_transport, coordinator, boards, -1, seat_by_peer)
	net_match.match_finished.connect(_on_match_finished)

	# Tell each client to build the identical match on its own seat.
	for m in _roster:
		_transport.send_to(int(m["peer"]), {
			"t": NetProtocol.START_MATCH, "seed": seed, "tier": tier,
			"count": count, "seat": int(m["seat"]), "names": names})
	print("[room %s] started: %d boards, seed=%d tier=%d" % [match_id, count, seed, tier])

# --- Router → room (after per-room demux) ---

func deliver(from_id: int, msg: Dictionary) -> void:
	if _transport != null:
		_transport.route_received(from_id, msg)

func peer_dropped(id: int) -> void:
	# Pre-start: just drop from the roster. In-match: NetMatch handles forfeit/placement.
	if not started:
		for i in range(_roster.size() - 1, -1, -1):
			if int(_roster[i]["peer"]) == id:
				_roster.remove_at(i)
		return
	if _transport != null:
		_transport.route_peer_left(id)

func _on_match_finished() -> void:
	finished.emit(match_id)
