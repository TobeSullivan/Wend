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

var max_rounds: int = 10  # set by map_loader from the MapResource

var round_num: int = 1
var phase: String = "build"  # "build", "run", or "ended"
var build_time_left: float = GameConstants.BUILD_TIME_FIRST
var match_over: bool = false

var boards: Array = []  # BoardState nodes, registered by map_loader

func register_board(board) -> void:
	boards.append(board)

func _process(delta: float) -> void:
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

# Skip the remaining build timer and start the run phase now. In solo this fires
# immediately; in MP it will gate on all players being ready (a later phase).
func request_start_now() -> void:
	if phase != "build":
		return
	_start_run_phase()

func _start_run_phase() -> void:
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

	# Cross-board resolution hook (PVP lives transfers / PVE aggregation) lands
	# here in Phase D/E. Solo has nothing to resolve.

	if round_num >= max_rounds:
		_end_match()
		return

	round_num += 1
	emit_signal("round_changed", round_num)
	phase = "build"
	build_time_left = _build_duration_for(round_num)
	emit_signal("phase_changed", phase)
	emit_signal("build_timer_changed", build_time_left)

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
