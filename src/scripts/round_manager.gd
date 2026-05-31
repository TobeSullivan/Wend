extends Node
class_name RoundManager

# Global tuning (economy, timings, mob HP growth) lives in the GameConstants
# autoload. Per-map values below are injected by map_loader before tree entry.

# Per-map config — set by map_loader from the MapResource.
var max_rounds: int = 10
var mob_count: int = 8           # enemy supply, constant per match
var bronze_threshold: int = 0
var silver_threshold: int = 0
var gold_threshold: int = 0

signal phase_changed(phase: String)
signal gold_changed(new_gold: int)
signal round_changed(new_round: int)
signal build_timer_changed(time_left: float)
signal damage_dealt_changed(total: int)
signal kills_changed(total: int)
signal match_ended
signal gold_goal_reached  # total damage crossed the Gold threshold mid-match
signal round_summary(round_completed: int, kill_gold: int, round_bonus: int, interest: int)

var round_num: int = 1
var gold: int = GameConstants.STARTING_GOLD
var phase: String = "build"  # "build", "run", or "ended"
var build_time_left: float = GameConstants.BUILD_TIME_FIRST
var total_damage_dealt: int = 0
var total_kills: int = 0
var match_over: bool = false
var gold_goal_hit: bool = false  # has the Gold threshold been reached this match
var _round_kill_gold: int = 0    # kill gold accumulated during the current round

var spawner  # Spawner — untyped to avoid class-name cycle
var build_controller  # BuildController — untyped to avoid class-name cycle
var mobs_array: Array  # shared with towers + spawner

func _ready() -> void:
	add_to_group("round_manager")
	emit_signal("gold_changed", gold)
	emit_signal("round_changed", round_num)
	emit_signal("phase_changed", phase)
	emit_signal("build_timer_changed", build_time_left)
	emit_signal("damage_dealt_changed", total_damage_dealt)
	emit_signal("kills_changed", total_kills)

func _process(delta: float) -> void:
	if match_over:
		return
	if phase == "build":
		build_time_left = maxf(0.0, build_time_left - delta)
		emit_signal("build_timer_changed", build_time_left)
		if build_time_left <= 0.0:
			_start_run_phase()
	else:
		if spawner != null and spawner.is_done() and _alive_mob_count() == 0:
			_end_round()

func mob_hp_for_round() -> float:
	if round_num <= GameConstants.MOB_HP_FLAT_ROUNDS:
		return GameConstants.MOB_BASE_HP
	var growth_rounds := round_num - GameConstants.MOB_HP_FLAT_ROUNDS
	return GameConstants.MOB_BASE_HP * pow(GameConstants.MOB_HP_GROWTH, growth_rounds)

func can_afford(cost: int) -> bool:
	return gold >= cost

func spend(cost: int) -> bool:
	if gold < cost:
		return false
	gold -= cost
	emit_signal("gold_changed", gold)
	return true

func refund(amount: int) -> void:
	gold += amount
	emit_signal("gold_changed", gold)

func _on_mob_killed() -> void:
	gold += GameConstants.KILL_BONUS
	_round_kill_gold += GameConstants.KILL_BONUS
	total_kills += 1
	emit_signal("gold_changed", gold)
	emit_signal("kills_changed", total_kills)

# Called via group dispatch from mob.take_hit. Overkill is clamped at the
# call site so a 100-damage shot on a 10-HP mob credits 10, not 100.
func _on_damage_dealt(amount: float) -> void:
	total_damage_dealt += int(round(amount))
	emit_signal("damage_dealt_changed", total_damage_dealt)
	# Crossing the Gold threshold mid-match offers an early "you won" choice.
	if not gold_goal_hit and not match_over and total_damage_dealt >= gold_threshold:
		gold_goal_hit = true
		emit_signal("gold_goal_reached")

func medal_for(damage: int) -> String:
	if damage >= gold_threshold:
		return "gold"
	if damage >= silver_threshold:
		return "silver"
	if damage >= bronze_threshold:
		return "bronze"
	return "none"

# Public: skip the remaining build timer and start the run phase immediately.
# In MP this will need to gate on all players pressing — TBD in DESIGN.
func request_start_now() -> void:
	if phase != "build":
		return
	_start_run_phase()

func _start_run_phase() -> void:
	phase = "run"
	emit_signal("phase_changed", phase)
	var wave_path: PackedVector2Array = build_controller.current_path_world()
	spawner.start_wave(mob_count, GameConstants.SPAWN_INTERVAL, mob_hp_for_round(), wave_path)

func _end_round() -> void:
	# Award completed-round bonus + interest for the round just finished.
	var round_bonus := GameConstants.ROUND_BONUS_BASE + round_num
	var interest := mini(int(floor(gold * GameConstants.INTEREST_RATE)), GameConstants.INTEREST_CAP)
	gold += round_bonus + interest
	emit_signal("gold_changed", gold)
	emit_signal("round_summary", round_num, _round_kill_gold, round_bonus, interest)
	_round_kill_gold = 0

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

func _alive_mob_count() -> int:
	var n := 0
	for m in mobs_array:
		if is_instance_valid(m):
			n += 1
	return n
