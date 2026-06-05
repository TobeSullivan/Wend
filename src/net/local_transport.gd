extends "res://net/match_transport.gd"
class_name LocalTransport
# extends by PATH not `MatchTransport` — a fresh checkout/CI hasn't scanned the new
# class_name into the global cache yet, so the global identifier won't resolve headless
# (see memory reference-godot-classname-cycle). class_name kept for editor/typing.

# Single-process transport for solo / PVE / offline bot-practice. There are no
# remote peers; the local player is always the authority (id 1). Sends loop straight
# back to `received` so the same message handlers run whether the match is networked
# or local — solo just talks to itself.

func start_host(_port: int) -> int:
	return OK
func start_join(_address: String, _port: int) -> int:
	return OK

func is_authority() -> bool:
	return true
func unique_id() -> int:
	return 1
func peer_ids() -> Array:
	return [1]

func send_to_authority(msg: Dictionary) -> void:
	received.emit(1, msg)
func broadcast(msg: Dictionary) -> void:
	received.emit(1, msg)
func send_to(_id: int, msg: Dictionary) -> void:
	received.emit(1, msg)
