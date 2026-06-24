extends "res://net/match_transport.gd"
class_name RoomTransport

var _real
var _peers: Array = []

func init_room(real_transport) -> void:
	_real = real_transport

func add_peer(id: int) -> void:
	if not _peers.has(id):
		_peers.append(id)

func remove_peer(id: int) -> void:
	_peers.erase(id)

func peers() -> Array:
	return _peers.duplicate()

func is_authority() -> bool:
	return true

func unique_id() -> int:
	return 1

func peer_ids() -> Array:
	var a: Array = [1]
	a.append_array(_peers)
	return a

func broadcast(msg: Dictionary) -> void:
	for p in _peers:
		_real.send_to(p, msg)

func send_to(id: int, msg: Dictionary) -> void:
	_real.send_to(id, msg)

func send_to_authority(_msg: Dictionary) -> void:
	pass

func route_received(from_id: int, msg: Dictionary) -> void:
	received.emit(from_id, msg)

func route_peer_left(id: int) -> void:
	remove_peer(id)
	peer_left.emit(id)
