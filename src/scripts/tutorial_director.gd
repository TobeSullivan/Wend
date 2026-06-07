extends Node
class_name TutorialDirector

# Fires a campaign mission's tutorial beats as the match plays (design/CAMPAIGN.md).
# Created by map_loader for the LOCAL board in CAMPAIGN mode only (and only when the map
# carries beats). Maps the existing match signals to the seven beat triggers, drives the
# callout UI, and feeds ghost_cells to the build-guide overlay. Each trigger fires at most
# once per match (the curriculum never needs a trigger to repeat).
#
# Open sequence: on_mission_load (the framing line — blocking on M1) → on_build_phase_start
# (which carries the starter-maze ghost outline). If the framing beat is blocking, the
# build-phase beat chains when the player acknowledges; otherwise it shows right after.

var coordinator        # MatchCoordinator
var board              # BoardState (round_manager) — the local board
var build_controller   # BuildController — the local board's
var callout            # TutorialCallout
var guide              # BuildGuide, or null if this mission has no ghost beats

var _by_trigger: Dictionary = {}  # trigger:String -> Array[beat]
var _fired: Dictionary = {}       # trigger -> true (one-shot guard)
var _after_ack: String = ""       # trigger to fire once a blocking beat is acknowledged

# Called by map_loader before add_child. `beats` is map.tutorial_beats (duck-typed).
func setup(beats: Array) -> void:
	for b in beats:
		var trig := String(b.trigger)
		if not _by_trigger.has(trig):
			_by_trigger[trig] = []
		_by_trigger[trig].append(b)

func _ready() -> void:
	if callout != null:
		callout.acknowledged.connect(_on_ack)
	if coordinator != null:
		coordinator.phase_changed.connect(_on_phase_changed)
		coordinator.match_ended.connect(_on_match_ended)
	if board != null:
		board.kills_changed.connect(_on_kills_changed)
		board.round_summary.connect(_on_round_summary)
	if build_controller != null:
		build_controller.towers_changed.connect(_on_towers_changed)
	# Deferred so the scene is fully built before the (pause-capable) framing beat — pausing
	# from inside _ready is unsafe per project memory.
	call_deferred("_begin")

func _begin() -> void:
	var has_load: bool = _by_trigger.has("on_mission_load") and not _by_trigger["on_mission_load"].is_empty()
	var load_blocking: bool = has_load and bool(_by_trigger["on_mission_load"][0].blocking)
	if has_load:
		_fire("on_mission_load")
	if load_blocking:
		_after_ack = "on_build_phase_start"  # chains when the framing modal is acknowledged
	else:
		_fire("on_build_phase_start")

# --- trigger plumbing ---

func _fire(trigger: String) -> void:
	if _fired.has(trigger):
		return
	_fired[trigger] = true
	for b in _by_trigger.get(trigger, []):
		_show_beat(b)  # ≤1 beat/trigger in the curriculum; a 2nd would replace the toast

func _show_beat(beat) -> void:
	if guide != null and beat.ghost_cells != null and not beat.ghost_cells.is_empty():
		guide.set_prompts(beat.ghost_cells)
	if bool(beat.blocking):
		callout.show_blocking(String(beat.text))
	else:
		callout.show_toast(String(beat.text), String(beat.anchor))

func _on_ack() -> void:
	if _after_ack != "":
		var t := _after_ack
		_after_ack = ""
		_fire(t)

# --- signal hooks ---

func _on_phase_changed(phase: String) -> void:
	if phase == "run":
		_fire("on_round_start")

func _on_match_ended() -> void:
	_fire("on_win")

func _on_kills_changed(total: int) -> void:
	if total >= 1:
		_fire("on_first_kill")

func _on_round_summary(_completed: int, _kill_gold: int, _round_bonus: int, _interest: int) -> void:
	_fire("on_round_end")

func _on_towers_changed(count: int, _cap: int) -> void:
	if count >= 1:
		_fire("on_first_tower_placed")
