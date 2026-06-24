extends Node
class_name MatchTransport

signal received(from_id: int, msg: Dictionary)
signal peer_joined(id: int)
signal peer_left(id: int)
signal connection_succeeded
signal connection_failed
signal server_closed

func start_host(_port: int) -> int:
	return ERR_UNAVAILABLE
func start_join(_address: String, _port: int) -> int:
	return ERR_UNAVAILABLE
func close() -> void:
	pass

func is_authority() -> bool:
	return true
func unique_id() -> int:
	return 1
func peer_ids() -> Array:
	return [1]

func send_to_authority(_msg: Dictionary) -> void:
	pass
func broadcast(_msg: Dictionary) -> void:
	pass
func send_to(_id: int, _msg: Dictionary) -> void:
	pass
