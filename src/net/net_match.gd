extends Node

# Drives a networked PVP match over a MatchTransport. Created by main.gd after the
# match is built (one per match), it bridges the local sim to the host-authoritative
# protocol (NetProtocol):
#
#   HOST (authority): runs the real MatchCoordinator clock + resolve_lives, broadcasts
#     CLOCK / RESOLUTION / MATCH_END, and relays each client's build inputs to everyone.
#   CLIENT: its coordinator is driven_externally (no self-clock) — it mirrors the host's
#     CLOCK/RESOLUTION, and sends its own build inputs + ready vote up to the host.
#
# Each client simulates ALL boards locally (full live opponent boards for free); only
# discrete build inputs, the clock, and per-round lives cross the wire (round-barrier
# model). Trust-client: kills accrue on each owner's local sim; lives are resolved by
# the host. boards[i] is seat i (map_loader builds boards in seat order).

const NetProtocol := preload("res://net/net_protocol.gd")

var transport
var coordinator
var boards: Array = []
var local_seat: int = 0

var local_ready: bool = false       # this client's own ready vote (host owns the rest)
var net_ready_count: int = 0        # host-reported ready count (for the Ready (n/m) label)
var seat_by_peer: Dictionary = {}   # {enet_peer_id: seat} — host maps a disconnect to a board
var _clock_accum: float = 0.0

func setup(t, coord, board_list: Array, seat: int, peer_seats: Dictionary = {}) -> void:
	transport = t
	coordinator = coord
	boards = board_list
	local_seat = seat
	seat_by_peer = peer_seats
	coordinator.net = self
	coordinator.driven_externally = not transport.is_authority()

	# Only the LOCAL interactive board relays its actions; opponent boards apply inbound
	# relays (apply_remote_*) which never re-relay, so there's no loop.
	var lc = boards[local_seat].build_controller
	lc.net = self
	lc.seat = local_seat

	transport.received.connect(_on_received)
	transport.peer_left.connect(_on_peer_left)
	transport.server_closed.connect(_on_server_closed)

	if transport.is_authority():
		coordinator.phase_changed.connect(func(_p): _broadcast_clock())
		coordinator.round_changed.connect(func(_r): _broadcast_clock())
		coordinator.lives_resolved.connect(_broadcast_resolution)
		coordinator.match_ended.connect(_broadcast_match_end)

func is_local_board(b) -> bool:
	return b == boards[local_seat]

func local_board():
	return boards[local_seat]

# --- Local actions out (called by build_controller / coordinator on the local board) ---

func submit_local_input(msg: Dictionary) -> void:
	if transport.is_authority():
		transport.broadcast(msg)          # host → all clients
	else:
		transport.send_to_authority(msg)  # client → host (which relays on)

func send_local_ready(value: bool) -> void:
	local_ready = value
	transport.send_to_authority(NetProtocol.ready(local_seat, value))

# --- Inbound ---

func _on_received(_from_id: int, msg: Dictionary) -> void:
	match msg.get("t", ""):
		NetProtocol.BUILD_INPUT:
			if int(msg["seat"]) == local_seat:
				return  # our own echo — already applied locally
			_apply_build_input(msg)
			if transport.is_authority():
				transport.broadcast(msg)  # relay a client's input on to everyone else
		NetProtocol.READY:
			if transport.is_authority():
				coordinator.set_board_ready(boards[int(msg["seat"])], bool(msg["value"]))
		NetProtocol.CLOCK:
			if not transport.is_authority():
				_apply_clock(msg)
		NetProtocol.RESOLUTION:
			if not transport.is_authority():
				_apply_resolution(msg)
		NetProtocol.MATCH_END:
			if not transport.is_authority():
				_apply_match_end(msg)

func _apply_build_input(msg: Dictionary) -> void:
	var bc = boards[int(msg["seat"])].build_controller
	match msg.get("action", ""):
		NetProtocol.ACT_PLACE:
			bc.apply_remote_place(msg["cell"])
		NetProtocol.ACT_SELL:
			bc.apply_remote_sell(msg["cell"])
		NetProtocol.ACT_UPGRADE:
			bc.apply_remote_upgrade(msg["cell"], msg["stat"])

# --- Authority → broadcasts ---

func _process(dt: float) -> void:
	if transport == null or not transport.is_authority() or coordinator.match_over:
		return
	# Periodic clock sync so client build timers stay smooth (discrete phase/round changes
	# are pushed immediately via the connected signals).
	_clock_accum += dt
	if _clock_accum >= 0.2:
		_clock_accum = 0.0
		_broadcast_clock()

func _broadcast_clock() -> void:
	if transport == null or not transport.is_authority():
		return
	transport.broadcast({
		"t": NetProtocol.CLOCK,
		"phase": coordinator.phase,
		"round": coordinator.round_num,
		"build_time_left": coordinator.build_time_left,
		"ready": coordinator.ready_count(),
		"active": coordinator.active_boards().size(),
	})

func _broadcast_resolution() -> void:
	var lives := {}
	var elim: Array = []
	for i in range(boards.size()):
		lives[i] = boards[i].lives
		if boards[i].eliminated:
			elim.append(i)
	transport.broadcast({"t": NetProtocol.RESOLUTION, "lives": lives, "eliminated": elim, "round": coordinator.round_num})

func _broadcast_match_end() -> void:
	var order: Array = []
	for b in coordinator.finish_order:
		order.append(boards.find(b))
	transport.broadcast({"t": NetProtocol.MATCH_END, "order": order})

# --- Client ← applies ---

func _apply_clock(msg: Dictionary) -> void:
	net_ready_count = int(msg.get("ready", 0))
	var was: String = coordinator.phase
	coordinator.net_set_build_time(float(msg["build_time_left"]))
	var new_phase: String = msg["phase"]
	var new_round: int = int(msg["round"])
	if new_phase == "run" and was != "run":
		coordinator.round_num = new_round
		coordinator.net_enter_run()
	elif new_phase == "build" and was == "run":
		coordinator.net_enter_build(new_round)
	elif new_phase != "ended" and new_round != coordinator.round_num:
		coordinator.round_num = new_round
		coordinator.emit_signal("round_changed", new_round)
	# "ended" is handled by MATCH_END (it carries placement) so it lands after lives.

func _apply_resolution(msg: Dictionary) -> void:
	var lives: Dictionary = msg["lives"]
	for k in lives:
		var b = boards[int(k)]
		b.lives = int(lives[k])
		b.kills_this_round = 0
	for s in msg.get("eliminated", []):
		var b = boards[int(s)]
		if not b.eliminated:
			b.eliminated = true
			coordinator.emit_signal("board_eliminated", b)
	coordinator.emit_signal("lives_resolved")

func _apply_match_end(msg: Dictionary) -> void:
	coordinator.finish_order.clear()
	for s in msg.get("order", []):
		coordinator.finish_order.append(boards[int(s)])
	coordinator.net_end_match()

# A client dropped: the host forfeits that player's board (eliminated, worst placement),
# tells everyone, and ends the match if only one board is left standing.
func _on_peer_left(id: int) -> void:
	if not transport.is_authority() or coordinator.match_over:
		return
	var s: int = int(seat_by_peer.get(id, -1))
	if s < 0 or s >= boards.size():
		return
	var b = boards[s]
	if b.eliminated:
		return
	b.eliminated = true
	b.lives = 0
	coordinator.finish_order.append(b)
	coordinator.emit_signal("board_eliminated", b)
	_broadcast_resolution()
	var active = coordinator.active_boards()
	if active.size() <= 1:
		for sb in active:
			coordinator.finish_order.append(sb)
		coordinator.net_end_match()
		_broadcast_match_end()

# The host vanished (clients only). The match can't continue without the authority —
# end it locally so the player isn't stuck staring at a frozen board.
func _on_server_closed() -> void:
	if transport.is_authority():
		return
	coordinator.net_end_match()
