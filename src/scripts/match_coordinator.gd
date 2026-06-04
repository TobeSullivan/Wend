extends Node
class_name MatchCoordinator

# Owns the SHARED match clock across all boards: round number, phase, and the
# build timer. Every board builds together and runs together; the run phase ends
# only when *all* active boards' trains have exited. Between rounds the coordinator
# runs cross-board resolution (PVP lives transfers / PVE scoring — added in later
# phases) and the win check.
#
# A solo match (campaign / solo PVE) is simply a coordinator with one board, so
# this single path serves every mode — the same philosophy as map_loader.
#
# Per-board state (gold, damage, kills, economy, towers, spawner) lives in the
# BoardState (round_manager.gd). Boards are referenced untyped to avoid the
# class-name cycle pitfall noted in project memory.

signal phase_changed(phase: String)
signal round_changed(new_round: int)
signal build_timer_changed(time_left: float)
signal match_ended
signal lives_resolved          # PVP: emitted after each round's lives transfer
signal board_eliminated(board) # PVP: a board dropped to 0 lives
signal ready_changed           # PVP: a board's build-phase ready vote changed

var max_rounds: int = 10  # set by map_loader from the MapResource

# PVP: lives transfer pairwise after each run phase and the match is last-standing
# (not capped by max_rounds). A safety cap prevents an unkillable stalemate.
var is_pvp: bool = false
const PVP_SAFETY_CAP := 60

var round_num: int = 1
var phase: String = "build"  # "build", "run", or "ended"
# PVP ready votes for the current build phase. The run starts early only when every
# active board has readied; otherwise it waits for the build timer (lockstep — no
# unilateral start, and no fast-forward, in multiplayer).
var _ready_set: Dictionary = {}
var build_time_left: float = GameConstants.BUILD_TIME_FIRST
var match_over: bool = false

var boards: Array = []  # BoardState nodes, registered by map_loader
# PVP: display handles per board (same index as `boards`). Board 0 is the local
# player ("You"); the rest are opponent handles. Set by map_loader for PVP matches.
var board_names: Array = []

# Display name for a board node (falls back to "Board N" if names aren't set).
func name_for(board) -> String:
	var i := boards.find(board)
	if i >= 0 and i < board_names.size():
		return board_names[i]
	return "Board %d" % (i + 1) if i >= 0 else "—"

# Per-frame cap on bot build actions across ALL boards. Each bot action runs a
# burst of A* path computations; with 7 bots created together their timers fired on
# the same frame (~90 A* runs at once), producing multi-second build-phase hitches
# that could trip the OS GPU watchdog. This serializes them to a few per frame —
# they still build over the (seconds-long) build phase, just without the spike.
const MAX_BOT_ACTIONS_PER_FRAME := 2
var _bot_actions_this_frame := 0
# PVP placement, worst-first: boards are appended as they're eliminated, and the
# surviving winner(s) are appended last. placement_of() reads this.
var finish_order: Array = []

func register_board(board) -> void:
	boards.append(board)

# A bot asks permission to act this frame; returns false once the frame's budget is
# spent (the bot keeps its timer and retries next frame). Caps total bot pathfinding
# per frame regardless of how many bots are ready at once.
func try_consume_bot_action() -> bool:
	if _bot_actions_this_frame >= MAX_BOT_ACTIONS_PER_FRAME:
		return false
	_bot_actions_this_frame += 1
	return true

func _process(delta: float) -> void:
	_bot_actions_this_frame = 0  # reset the per-frame bot budget (coordinator runs first)
	if match_over:
		return
	if phase == "build":
		build_time_left = maxf(0.0, build_time_left - delta)
		emit_signal("build_timer_changed", build_time_left)
		if build_time_left <= 0.0:
			_start_run_phase()
	else:  # run
		if _all_runs_done():
			_end_round()

# Global mob-HP curve (per DESIGN): flat for the first N rounds, then geometric.
func mob_hp_for_round() -> float:
	if round_num <= GameConstants.MOB_HP_FLAT_ROUNDS:
		return GameConstants.MOB_BASE_HP
	var growth_rounds := round_num - GameConstants.MOB_HP_FLAT_ROUNDS
	return GameConstants.MOB_BASE_HP * pow(GameConstants.MOB_HP_GROWTH, growth_rounds)

# Single-player (campaign / solo PVE): skip the remaining build timer and start now.
# Ignored in PVP, where the run is gated on the ready vote (set_board_ready).
func request_start_now() -> void:
	if phase != "build" or is_pvp:
		return
	_start_run_phase()

# PVP ready vote. The run starts early once every active board has readied; until
# then the build timer keeps running and the round simply waits.
func set_board_ready(board, value: bool) -> void:
	if not is_pvp or phase != "build":
		return
	if value:
		_ready_set[board] = true
	else:
		_ready_set.erase(board)
	emit_signal("ready_changed")
	for b in boards:
		if b.is_active() and not _ready_set.has(b):
			return  # someone still isn't ready — keep waiting
	_start_run_phase()

func is_board_ready(board) -> bool:
	return _ready_set.has(board)

func ready_count() -> int:
	var n := 0
	for b in active_boards():
		if _ready_set.has(b):
			n += 1
	return n

func _start_run_phase() -> void:
	_ready_set.clear()  # ready votes are per build phase
	phase = "run"
	emit_signal("phase_changed", phase)
	var hp := mob_hp_for_round()
	for b in boards:
		if b.is_active():
			b.start_run(round_num, hp)

func _all_runs_done() -> bool:
	for b in boards:
		if b.is_active() and not b.is_run_done():
			return false
	return true

func _end_round() -> void:
	# Each board awards its own end-of-round economy (round bonus + interest) and
	# emits its round summary.
	for b in boards:
		if b.is_active():
			b.settle_round(round_num)

	# PVP: pairwise lives transfers + eliminations; last-standing ends the match.
	if is_pvp:
		resolve_lives()
		var active := active_boards()
		if active.size() <= 1 or round_num >= PVP_SAFETY_CAP:
			# Rank any survivors best-last, then finish.
			active.sort_custom(func(a, b): return a.lives < b.lives)
			for b in active:
				finish_order.append(b)
			_end_match()
			return
	elif round_num >= max_rounds:
		_end_match()
		return

	round_num += 1
	emit_signal("round_changed", round_num)
	phase = "build"
	build_time_left = _build_duration_for(round_num)
	emit_signal("phase_changed", phase)
	emit_signal("build_timer_changed", build_time_left)

# Active = not eliminated.
func active_boards() -> Array:
	var a: Array = []
	for b in boards:
		if b.is_active():
			a.append(b)
	return a

# Model B pairwise transfers among active boards: each board's net change equals
# the sum over opponents of (my kills - their kills) this round, i.e.
# n*my_kills - total_kills. Zero-sum. Then eliminate boards at <= 0 lives.
func resolve_lives() -> void:
	var active := active_boards()
	var n := active.size()
	if n <= 1:
		return
	var total_kills := 0
	for b in active:
		total_kills += b.kills_this_round
	# Apply transfers (compute all deltas first; they only depend on this round).
	for b in active:
		b.lives += n * b.kills_this_round - total_kills
	for b in active:
		b.kills_this_round = 0
	# Eliminate, worst (most negative) first so placement ties resolve sensibly.
	var newly: Array = []
	for b in active:
		if b.lives <= 0:
			newly.append(b)
	newly.sort_custom(func(a, b): return a.lives < b.lives)
	for b in newly:
		b.lives = 0
		b.eliminated = true
		finish_order.append(b)
		emit_signal("board_eliminated", b)
	emit_signal("lives_resolved")

# 1-based placement (1 = winner / last standing). 0 if not yet decided.
func placement_of(board) -> int:
	var idx := finish_order.find(board)
	if idx == -1:
		return 0
	return boards.size() - idx

func _end_match() -> void:
	match_over = true
	phase = "ended"
	emit_signal("phase_changed", phase)
	emit_signal("match_ended")

func _build_duration_for(rn: int) -> float:
	if rn == 1:
		return GameConstants.BUILD_TIME_FIRST
	if rn >= GameConstants.LATE_ROUND_THRESHOLD:
		return GameConstants.BUILD_TIME_LATE
	return GameConstants.BUILD_TIME_NORMAL
