extends "res://net/match_transport.gd"
class_name EnetTransport
# extends by PATH not `MatchTransport` — see local_transport.gd / memory note: a fresh
# checkout hasn't scanned the new class_name into the global cache yet.

# Host-authoritative transport over ENet (UDP). Peer id 1 is the host/authority;
# clients connect out to it (works through NAT for outbound connections to a host
# that has the port open / forwarded — see the Phase 4 internet step). Messages move
# through a single reliable relay RPC (`_recv`) so the wire surface is one method;
# the protocol lives in the Dictionary payload (NetProtocol).
#
# This node must sit at the SAME tree path on host and client for the RPC to resolve
# — SceneManager owns it as a fixed-name child (/root/SceneManager/<name>), so it
# persists across the lobby→match scene change and matches on both ends.

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
		_recv.rpc(msg)  # all connected peers except self; authority applies its own state directly

func send_to(id: int, msg: Dictionary) -> void:
	if _started:
		_recv.rpc_id(id, msg)

# --- internals ---

func _connect_signals() -> void:
	multiplayer.peer_connected.connect(func(id): peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_left.emit(id))
	multiplayer.connected_to_server.connect(func(): connection_succeeded.emit())
	multiplayer.connection_failed.connect(func(): connection_failed.emit())
	multiplayer.server_disconnected.connect(func(): server_closed.emit())

@rpc("any_peer", "call_remote", "reliable")
func _recv(msg: Dictionary) -> void:
	received.emit(multiplayer.get_remote_sender_id(), msg)
