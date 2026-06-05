extends Node
class_name MatchTransport

# Abstract transport seam for multiplayer. The rest of the game talks to THIS
# interface, never to a concrete peer — so "host-authoritative ENet now → dedicated
# server / Steam relay / Nakama later" is swapping a subclass, not a rewrite
# (notes/multiplayer_architecture.md §2, the pivot-insurance rule).
#
# Subclasses: LocalTransport (single-process; solo/PVE/bot-practice) and
# EnetTransport (host-authoritative over the internet). Owned by SceneManager so it
# persists across the lobby→match scene change; lives at a stable tree path so the
# high-level multiplayer RPCs resolve on both ends.
#
# Authority model: peer id 1 is the host/authority. Clients send UP to the authority
# (send_to_authority); the authority sends DOWN to everyone (broadcast). Every
# payload is a NetProtocol Dictionary.

# A message arrived. from_id is the sender's peer id (1 = authority).
signal received(from_id: int, msg: Dictionary)
# Peer lifecycle (authority side mostly; clients see connection_* / server_closed).
signal peer_joined(id: int)
signal peer_left(id: int)
signal connection_succeeded   # client: handshake with host completed
signal connection_failed      # client: could not reach host
signal server_closed          # client: host went away / match ended

# --- Lifecycle (override) ---
func start_host(_port: int) -> int:
	return ERR_UNAVAILABLE
func start_join(_address: String, _port: int) -> int:
	return ERR_UNAVAILABLE
func close() -> void:
	pass

# --- Identity (override) ---
func is_authority() -> bool:
	return true
func unique_id() -> int:
	return 1
func peer_ids() -> Array:   # all connected peer ids INCLUDING self
	return [1]

# --- Send (override) ---
# Client → authority.
func send_to_authority(_msg: Dictionary) -> void:
	pass
# Authority → every client (does NOT loop back to the authority itself; the
# authority applies its own state directly). LocalTransport loops back so the solo
# path exercises the same handlers.
func broadcast(_msg: Dictionary) -> void:
	pass
# Authority → one client.
func send_to(_id: int, _msg: Dictionary) -> void:
	pass
