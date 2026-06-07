extends "res://net/match_transport.gd"
class_name RoomTransport
# extends by PATH not `MatchTransport` — a fresh checkout hasn't scanned the new class_name into
# the global cache yet (see enet_transport.gd / memory note).

# Per-room, server-side transport adapter. The dedicated server hosts MANY concurrent matches on
# ONE real transport; each room gets one of these so its NetMatch authority talks only to that
# room's peers. broadcast() fans out to the room's members (never the whole server); the router
# (match_server.gd) feeds inbound traffic in via route_received / route_peer_left after it has
# demuxed the real transport by peer→room. The client side never uses this — a client is only ever
# in one match and talks to the real transport directly.

var _real                  # the underlying MatchTransport (EnetTransport) the server hosts on
var _peers: Array = []     # enet peer ids that belong to this room

func init_room(real_transport) -> void:
	_real = real_transport

func add_peer(id: int) -> void:
	if not _peers.has(id):
		_peers.append(id)

func remove_peer(id: int) -> void:
	_peers.erase(id)

func peers() -> Array:
	return _peers.duplicate()

# --- MatchTransport interface (server is the authority of every room) ---

func is_authority() -> bool:
	return true

func unique_id() -> int:
	return 1

func peer_ids() -> Array:
	var a: Array = [1]
	a.append_array(_peers)
	return a

# Authority → this room's clients only (NOT the whole server).
func broadcast(msg: Dictionary) -> void:
	for p in _peers:
		_real.send_to(p, msg)

func send_to(id: int, msg: Dictionary) -> void:
	_real.send_to(id, msg)

func send_to_authority(_msg: Dictionary) -> void:
	pass  # we ARE the authority

# --- Fed by the router after per-room demux ---

func route_received(from_id: int, msg: Dictionary) -> void:
	received.emit(from_id, msg)

func route_peer_left(id: int) -> void:
	remove_peer(id)
	peer_left.emit(id)
