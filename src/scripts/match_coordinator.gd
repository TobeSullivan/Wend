extends Node
class_name MatchCoordinator

signal phase_changed(phase: String)
signal round_changed(new_round: int)
signal build_timer_changed(time_left: float)
signal match_ended
signal lives_resolved
signal board_eliminated(board)
signal ready_changed
signal shared_gold_changed(new_gold: int)
signal shared_lives_changed(new_lives: int)
signal shared_supply_changed(used: int, cap: int)

var max_rounds: int = 10

var is_pvp: bool = false
# Trials runs until difficulty outpaces the player and lives deplete; max_rounds
# is only a win cap for the authored campaign.
var endless: bool = false

var is_coop_relay: bool = false
var shared_gold: int = 0
var shared_lives: int = 0
var shared_supply_used: int = 0
var shared_supply_cap: int = 0
var scale_tier: int = 1
const PVP_SAFETY_CAP := 60
const ENDLESS_SAFETY_CAP := 999

var round_num: int = 1
var phase: String = "build"
var _ready_set: Dictionary = {}
var build_time_left: float = GameConstants.BUILD_TIME_FIRST
var match_over: bool = false

const SIM_HZ := 60
const SIM_DT := 1.0 / SIM_HZ
const MAX_STEPS_PER_FRAME := 12
const COOP_RUN_SPEED := 3.0
const PVP_RUN_SPEED := 3.0
var sim_tick: int = 0
var _sim_accum: float = 0.0
var build_ticks_left: int = 0
var sim_seed: int = 0
var rng := RandomNumberGenerator.new()

var record_enabled := false
var ruleset_version := "0.1"
var map_ref: Dictionary = {}
var input_log: Array = []

func log_input(seat: int, action: Dictionary) -> void:
	if not record_enabled:
		return
	input_log.append({"tick": sim_tick, "seat": seat, "action": action})

func record_end_marker() -> void:
	log_input(0, {"type": "end"})

func make_record() -> Dictionary:
	return {
		"seed": sim_seed,
		"map_ref": map_ref.duplicate(true),
		"ruleset_version": ruleset_version,
		"players": boards.size(),
		"input_log": input_log.duplicate(true),
	}

var driven_externally: bool = false
var net = null

var boards: Array = []
var board_names: Array = []

func name_for(board) -> String:
	var i := boards.find(board)
	if i >= 0 and i < board_names.size():
		return board_names[i]
	return "Board %d" % (i + 1) if i >= 0 else "—"

const MAX_BOT_ACTIONS_PER_FRAME := 2
var _bot_actions_this_frame := 0
var finish_order: Array = []

func register_board(board) -> void:
	boards.append(board)

func try_consume_bot_action() -> bool:
	if _bot_actions_this_frame >= MAX_BOT_ACTIONS_PER_FRAME:
		return false
	_bot_actions_this_frame += 1
	return true

func _ready() -> void:
	rng.seed = sim_seed
	build_ticks_left = _build_ticks_for(round_num)
	build_time_left = build_ticks_left * SIM_DT

func _run_speed_mult() -> float:
	if phase == "run" and not match_over:
		if is_coop_relay:
			return COOP_RUN_SPEED
		if is_pvp:
			return PVP_RUN_SPEED
	return 1.0

func _process(delta: float) -> void:
	_bot_actions_this_frame = 0
	if match_over:
		return
	_sim_accum += delta * _run_speed_mult()
	var backlog_cap := MAX_STEPS_PER_FRAME * SIM_DT
	if _sim_accum > backlog_cap:
		_sim_accum = backlog_cap
	var steps := 0
	while _sim_accum >= SIM_DT and steps < MAX_STEPS_PER_FRAME:
		_sim_accum -= SIM_DT
		steps += 1
		_sim_tick_once()

func _sim_tick_once() -> void:
	sim_tick += 1
	if phase == "run":
		_step_entities()
	if driven_externally:
		return
	if phase == "build":
		if build_ticks_left > 0:
			build_ticks_left -= 1
			build_time_left = build_ticks_left * SIM_DT
			emit_signal("build_timer_changed", build_time_left)
		if build_ticks_left <= 0:
			_start_run_phase()
	else:
		if _all_runs_done():
			_end_round()

func _step_entities() -> void:
	for b in boards:
		if b.is_active():
			b.sim_step(SIM_DT, rng)

func _build_ticks_for(rn: int) -> int:
	return int(round(_build_duration_for(rn) * SIM_HZ))

func mob_hp_for_round() -> float:
	var base := GameConstants.MOB_BASE_HP
	if round_num > GameConstants.MOB_HP_FLAT_ROUNDS:
		base *= pow(GameConstants.MOB_HP_GROWTH, round_num - GameConstants.MOB_HP_FLAT_ROUNDS)
	return base * _scale_hp_mult()

func _scale_hp_mult() -> float:
	if is_pvp:
		var pramp := clampf(float(round_num) / float(GameConstants.PVP_HP_RAMP_ROUND), 0.0, 1.0)
		return lerpf(1.0, GameConstants.PVP_HP_SCALE_MAX, pramp)
	if not endless:
		return 1.0
	var full: float = GameConstants.SCALE_HP_MULT[clampi(scale_tier - 1, 0, GameConstants.SCALE_HP_MULT.size() - 1)]
	var ramp := clampf(float(round_num) / float(GameConstants.SCALE_HP_RAMP_ROUND), 0.0, 1.0)
	return lerpf(1.0, full, ramp)

func mob_count_for_round(board) -> int:
	if is_pvp:
		var np := GameConstants.WAVE_COUNT_BASE + (round_num - 1) * GameConstants.PVP_COUNT_PER_ROUND
		return clampi(np, GameConstants.WAVE_COUNT_BASE, GameConstants.WAVE_COUNT_MAX)
	if not endless:
		return board.mob_count
	var n := GameConstants.WAVE_COUNT_BASE + (round_num - 1) * GameConstants.WAVE_COUNT_PER_ROUND
	return clampi(n, GameConstants.WAVE_COUNT_BASE, GameConstants.WAVE_COUNT_MAX)

func is_boss_round() -> bool:
	return round_num > 0 and round_num % GameConstants.BOSS_INTERVAL == 0

func boss_hp_for_round() -> float:
	return mob_hp_for_round() * GameConstants.BOSS_HP_MULT

func request_start_now() -> void:
	if phase != "build" or is_pvp:
		return
	log_input(0, {"type": "start"})
	_start_run_phase()

func set_board_ready(board, value: bool) -> void:
	if driven_externally and net != null:
		net.send_local_ready(value)
		return
	if not (is_pvp or is_coop_relay) or phase != "build":
		return
	log_input(boards.find(board), {"type": "vote_start", "value": value})
	if value:
		_ready_set[board] = true
	else:
		_ready_set.erase(board)
	emit_signal("ready_changed")
	for b in boards:
		if b.is_active() and not _ready_set.has(b):
			return
	_start_run_phase()

func is_board_ready(board) -> bool:
	if driven_externally and net != null:
		return net.local_ready if net.is_local_board(board) else false
	return _ready_set.has(board)

func ready_count() -> int:
	if driven_externally and net != null:
		return net.net_ready_count
	var n := 0
	for b in active_boards():
		if _ready_set.has(b):
			n += 1
	return n

func _start_run_phase() -> void:
	_ready_set.clear()
	phase = "run"
	emit_signal("phase_changed", phase)
	_start_wave_on_boards()

func _start_wave_on_boards() -> void:
	var hp := mob_hp_for_round()
	var boss := is_boss_round()
	var bhp := boss_hp_for_round()
	if is_coop_relay:
		var nb := boards.size()
		var hp_mult := 1.0 + GameConstants.COOP_HP_PER_BOARD * float(nb - 1)
		var count_mult := 1.0 + GameConstants.COOP_COUNT_PER_BOARD * float(nb - 1)
		hp *= hp_mult
		bhp *= hp_mult
		var base_count: int = mob_count_for_round(boards[0]) if not boards.is_empty() else 0
		var count := int(round(float(base_count) * count_mult))
		for i in boards.size():
			var b = boards[i]
			if b.is_active():
				b.start_run(round_num, hp, count if i == 0 else 0, boss, bhp)
		return
	for b in boards:
		if b.is_active():
			b.start_run(round_num, hp, mob_count_for_round(b), boss, bhp)

func _all_runs_done() -> bool:
	if is_coop_relay:
		if boards.is_empty():
			return true
		var lead = boards[0]
		if lead.is_active() and lead.spawner != null and not lead.spawner.is_done():
			return false
		for b in boards:
			if b._alive_mob_count() > 0:
				return false
		return true
	for b in boards:
		if b.is_active() and not b.is_run_done():
			return false
	return true

func setup_shared_pools(num_boards: int, supply_each: int) -> void:
	is_coop_relay = true
	shared_gold = GameConstants.STARTING_GOLD * num_boards
	shared_lives = GameConstants.TRIALS_LIVES * num_boards
	shared_supply_cap = supply_each * num_boards
	shared_supply_used = 0

func add_shared_gold(n: int) -> void:
	shared_gold += n
	emit_signal("shared_gold_changed", shared_gold)

func can_afford_shared(n: int) -> bool:
	return shared_gold >= n

func spend_shared_gold(n: int) -> bool:
	if shared_gold < n:
		return false
	shared_gold -= n
	emit_signal("shared_gold_changed", shared_gold)
	return true

func shared_supply_used_now() -> int:
	var n := 0
	for b in boards:
		if b.build_controller != null:
			n += b.build_controller.towers.size()
	return n

func refresh_shared_supply() -> void:
	shared_supply_used = shared_supply_used_now()
	emit_signal("shared_supply_changed", shared_supply_used, shared_supply_cap)

func shared_supply_full() -> bool:
	return shared_supply_used_now() >= shared_supply_cap

func lose_shared_lives(penalty: int) -> void:
	shared_lives = maxi(0, shared_lives - penalty)
	emit_signal("shared_lives_changed", shared_lives)
	if shared_lives <= 0 and not match_over:
		for b in boards:
			b.eliminated = true
			if not finish_order.has(b):
				finish_order.append(b)
		_end_match()

func _end_round() -> void:
	for b in boards:
		if b.is_active():
			b.settle_round(round_num)
	if is_coop_relay:
		add_shared_gold(GameConstants.ROUND_BONUS_BASE + round_num)

	if is_pvp:
		resolve_lives()
		var active := active_boards()
		if active.size() <= 1 or round_num >= PVP_SAFETY_CAP:
			active.sort_custom(_standing_worse_first)
			for b in active:
				finish_order.append(b)
			_end_match()
			return
	elif not endless and round_num >= max_rounds:
		_end_match()
		return
	elif endless and round_num >= ENDLESS_SAFETY_CAP:
		_end_match()
		return

	round_num += 1
	emit_signal("round_changed", round_num)
	phase = "build"
	build_ticks_left = _build_ticks_for(round_num)
	build_time_left = build_ticks_left * SIM_DT
	emit_signal("phase_changed", phase)
	emit_signal("build_timer_changed", build_time_left)

func active_boards() -> Array:
	var a: Array = []
	for b in boards:
		if b.is_active():
			a.append(b)
	return a

func resolve_lives() -> void:
	var active := active_boards()
	var n := active.size()
	if n <= 1:
		return
	# See-saw transfers on LEAKS, not kills: leaking fewer than the field gains
	# lives, leaking more loses them. Zero-sum across the active boards.
	var total_leaks := 0
	for b in active:
		total_leaks += b.leaks_this_round
	var deltas := {}
	for b in active:
		deltas[b] = total_leaks - n * b.leaks_this_round
	var shortfall := 0
	var total_gain := 0
	for b in active:
		if b.lives + deltas[b] < 0:
			shortfall += -(b.lives + deltas[b])
		if deltas[b] > 0:
			total_gain += deltas[b]
	var reduce := {}
	if shortfall > 0 and total_gain > 0:
		var assigned := 0
		var rema: Array = []
		for b in active:
			if deltas[b] > 0:
				var exact := float(shortfall) * float(deltas[b]) / float(total_gain)
				reduce[b] = int(floor(exact))
				assigned += reduce[b]
				rema.append([b, exact - floor(exact)])
		rema.sort_custom(func(a, c): return a[1] > c[1])
		for i in range(shortfall - assigned):
			reduce[rema[i % rema.size()][0]] += 1
	var raw_new := {}
	for b in active:
		var d: int = deltas[b] - int(reduce.get(b, 0))
		raw_new[b] = b.lives + d
		b.lives = max(0, raw_new[b])
		b.emit_signal("lives_changed", b.lives)
	for b in active:
		b.leaks_this_round = 0
	var newly: Array = []
	for b in active:
		if b.lives <= 0:
			newly.append(b)
	# Worst standing eliminated first; score breaks ties (lower score = worse).
	newly.sort_custom(func(a, c):
		if raw_new[a] != raw_new[c]:
			return raw_new[a] < raw_new[c]
		return a.total_damage_dealt < c.total_damage_dealt)
	for b in newly:
		b.lives = 0
		b.eliminated = true
		finish_order.append(b)
		emit_signal("board_eliminated", b)
	emit_signal("lives_resolved")

func _standing_worse_first(a, b) -> bool:
	if a.lives != b.lives:
		return a.lives < b.lives
	return a.total_damage_dealt < b.total_damage_dealt

func notify_board_dead(board) -> void:
	# Trials/Campaign fail state: a board out of lives ends its run immediately.
	if is_pvp:
		return
	if not finish_order.has(board):
		finish_order.append(board)
	_end_match()

func projected_lives(board) -> int:
	if not is_pvp or phase != "run":
		return board.lives
	var active := active_boards()
	var n := active.size()
	if n <= 1 or not active.has(board):
		return board.lives
	var total_leaks := 0
	var pool := 0
	for b in active:
		total_leaks += b.leaks_this_round
		pool += b.lives
	return clampi(board.lives + total_leaks - n * board.leaks_this_round, 0, pool)

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

func net_enter_run() -> void:
	phase = "run"
	if net != null:
		net.local_ready = false
	emit_signal("phase_changed", phase)
	_start_wave_on_boards()

func net_enter_build(new_round: int) -> void:
	for b in boards:
		if b.is_active():
			b.settle_round(round_num)
	_clear_all_mobs()
	round_num = new_round
	emit_signal("round_changed", round_num)
	phase = "build"
	emit_signal("phase_changed", phase)

func net_set_build_time(t: float) -> void:
	build_time_left = t
	emit_signal("build_timer_changed", build_time_left)

func net_end_match() -> void:
	if match_over:
		return
	match_over = true
	phase = "ended"
	emit_signal("phase_changed", phase)
	emit_signal("match_ended")

func _clear_all_mobs() -> void:
	for b in boards:
		for m in b.mobs_array:
			if is_instance_valid(m):
				m.alive = false
				m.queue_free()
		b.mobs_array.clear()
		b.clear_projectiles()

func _build_duration_for(rn: int) -> float:
	if rn == 1:
		return GameConstants.BUILD_TIME_FIRST
	return GameConstants.BUILD_TIME_NORMAL
