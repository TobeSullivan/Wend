extends "res://net/match_transport.gd"
class_name EnetTransport

const NetProtocolScript := preload("res://net/net_protocol.gd")
const MAX_PLAYERS := NetProtocolScript.MAX_PLAYERS

var _peer: ENetMultiplayerPeer
var _started := false

func start_host(port: int) -> int:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		_peer = null
		return err
	multiplayer.multiplayer_peer = _peer
	_connect_signals()
	_started = true
	return OK

func start_join(address: String, port: int) -> int:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(address, port)
	if err != OK:
		_peer = null
		return err
	multiplayer.multiplayer_peer = _peer
	_connect_signals()
	_started = true
	return OK

func close() -> void:
	if not _started:
		return
	_started = false
	if multiplayer.multiplayer_peer == _peer:
		multiplayer.multiplayer_peer = null
	if _peer != null:
		_peer.close()
		_peer = null

func is_authority() -> bool:
	return _started and multiplayer.is_server()

func unique_id() -> int:
	return multiplayer.get_unique_id() if _started else 1

func peer_ids() -> Array:
	if not _started:
		return [1]
	var ids: Array = [unique_id()]
	for p in multiplayer.get_peers():
		ids.append(p)
	return ids

func send_to_authority(msg: Dictionary) -> void:
	if _started:
		_recv.rpc_id(1, msg)

func broadcast(msg: Dictionary) -> void:
	if _started:
		_recv.rpc(msg)

func send_to(id: int, msg: Dictionary) -> void:
	if _started:
		_recv.rpc_id(id, msg)

func _connect_signals() -> void:
	multiplayer.peer_connected.connect(func(id): peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_left.emit(id))
	multiplayer.connected_to_server.connect(func(): connection_succeeded.emit())
	multiplayer.connection_failed.connect(func(): connection_failed.emit())
	multiplayer.server_disconnected.connect(func(): server_closed.emit())

@rpc("any_peer", "call_remote", "reliable")
func _recv(msg: Dictionary) -> void:
	received.emit(multiplayer.get_remote_sender_id(), msg)
