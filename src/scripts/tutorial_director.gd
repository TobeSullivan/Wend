extends Node
class_name TutorialDirector

var coordinator
var board
var build_controller
var callout
var guide

var _by_trigger: Dictionary = {}
var _fired: Dictionary = {}
var _after_ack: String = ""

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
		board.round_settled.connect(_on_round_settled)
	if build_controller != null:
		build_controller.towers_changed.connect(_on_towers_changed)
	call_deferred("_begin")

func _begin() -> void:
	var has_load: bool = _by_trigger.has("on_mission_load") and not _by_trigger["on_mission_load"].is_empty()
	var load_blocking: bool = has_load and bool(_by_trigger["on_mission_load"][0].blocking)
	if has_load:
		_fire("on_mission_load")
	if load_blocking:
		_after_ack = "on_build_phase_start"
	else:
		_fire("on_build_phase_start")

func _fire(trigger: String) -> void:
	if _fired.has(trigger):
		return
	_fired[trigger] = true
	for b in _by_trigger.get(trigger, []):
		_show_beat(b)

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

func _on_phase_changed(phase: String) -> void:
	if phase == "run":
		_fire("on_round_start")

func _on_match_ended() -> void:
	_fire("on_win")

func _on_kills_changed(total: int) -> void:
	if total >= 1:
		_fire("on_first_kill")

func _on_round_settled(_completed: int) -> void:
	_fire("on_round_end")

func _on_towers_changed(count: int, _cap: int) -> void:
	if count >= 1:
		_fire("on_first_tower_placed")
