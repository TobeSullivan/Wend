extends Node
class_name RoundManager

var mob_count: int = 8
var bronze_threshold: int = 0
var silver_threshold: int = 0
var gold_threshold: int = 0

var coordinator

signal gold_changed(new_gold: int)
signal damage_dealt_changed(total: int)
signal kills_changed(total: int)
signal gold_goal_reached
signal round_summary(round_completed: int, kill_gold: int, round_bonus: int, interest: int)

signal phase_changed(phase: String)
signal round_changed(new_round: int)
signal build_timer_changed(time_left: float)
signal match_ended

var gold: int = GameConstants.STARTING_GOLD
var total_damage_dealt: int = 0
var total_kills: int = 0
var gold_goal_hit: bool = false
var lives: int = 0
var kills_this_round: int = 0
var eliminated: bool = false
var _round_kill_gold: int = 0

var spawner
var build_controller
var mobs_array: Array
var projectiles: Array = []
var bonus_zones: Array = []

var phase: String:
	get:
		return coordinator.phase if coordinator != null else "build"

var round_num: int:
	get:
		return coordinator.round_num if coordinator != null else 1

var build_time_left: float:
	get:
		return coordinator.build_time_left if coordinator != null else GameConstants.BUILD_TIME_FIRST

var max_rounds: int:
	get:
		return coordinator.max_rounds if coordinator != null else 10

var match_over: bool:
	get:
		return coordinator.match_over if coordinator != null else false

func _ready() -> void:
	if coordinator != null:
		coordinator.phase_changed.connect(func(p): emit_signal("phase_changed", p))
		coordinator.round_changed.connect(func(r): emit_signal("round_changed", r))
		coordinator.build_timer_changed.connect(func(t): emit_signal("build_timer_changed", t))
		coordinator.match_ended.connect(func(): emit_signal("match_ended"))
	emit_signal("gold_changed", gold)
	emit_signal("damage_dealt_changed", total_damage_dealt)
	emit_signal("kills_changed", total_kills)
	emit_signal("phase_changed", phase)
	emit_signal("round_changed", round_num)
	emit_signal("build_timer_changed", build_time_left)

func is_active() -> bool:
	return not eliminated

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

func net_spend(cost: int) -> void:
	gold = maxi(0, gold - cost)
	emit_signal("gold_changed", gold)

func _on_mob_killed() -> void:
	gold += GameConstants.KILL_BONUS
	_round_kill_gold += GameConstants.KILL_BONUS
	total_kills += 1
	kills_this_round += 1
	emit_signal("gold_changed", gold)
	emit_signal("kills_changed", total_kills)

func _on_damage_dealt(amount: float) -> void:
	total_damage_dealt += int(round(amount))
	emit_signal("damage_dealt_changed", total_damage_dealt)
	if gold_threshold > 0 and not gold_goal_hit and not match_over and total_damage_dealt >= gold_threshold:
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

func request_start_now() -> void:
	if coordinator != null:
		coordinator.request_start_now()

func start_run(_round_num: int, mob_hp: float) -> void:
	clear_projectiles()
	var wave_path: PackedVector2Array = build_controller.current_path_world()
	spawner.start_wave(mob_count, GameConstants.SPAWN_INTERVAL, mob_hp, wave_path)

func sim_step(dt: float, rng: RandomNumberGenerator) -> void:
	if spawner != null:
		spawner.sim_step(dt)
	if build_controller != null:
		for t in build_controller.towers:
			if is_instance_valid(t):
				t.sim_step(dt, rng)
	var i := 0
	while i < projectiles.size():
		var p = projectiles[i]
		if not is_instance_valid(p):
			projectiles.remove_at(i)
			continue
		if p.sim_step(dt):
			projectiles.remove_at(i)
			p.queue_free()
		else:
			i += 1
	var j := 0
	while j < mobs_array.size():
		var m = mobs_array[j]
		if not is_instance_valid(m):
			mobs_array.remove_at(j)
			continue
		if m.sim_step(dt):
			m.alive = false
			mobs_array.remove_at(j)
			m.queue_free()
		else:
			j += 1

func clear_projectiles() -> void:
	for p in projectiles:
		if is_instance_valid(p):
			p.queue_free()
	projectiles.clear()

func is_run_done() -> bool:
	return spawner != null and spawner.is_done() and _alive_mob_count() == 0

func settle_round(round_completed: int) -> void:
	var round_bonus := GameConstants.ROUND_BONUS_BASE + round_completed
	var interest := mini(int(floor(gold * GameConstants.INTEREST_RATE)), GameConstants.INTEREST_CAP)
	gold += round_bonus + interest
	emit_signal("gold_changed", gold)
	emit_signal("round_summary", round_completed, _round_kill_gold, round_bonus, interest)
	_round_kill_gold = 0

func _alive_mob_count() -> int:
	var n := 0
	for m in mobs_array:
		if is_instance_valid(m):
			n += 1
	return n
