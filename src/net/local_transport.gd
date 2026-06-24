extends "res://net/match_transport.gd"
class_name LocalTransport

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
