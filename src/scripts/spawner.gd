extends Node2D
class_name Spawner

const MobScript := preload("res://scripts/mob.gd")

var mobs_array: Array
var board

var _mob_count: int = 0
var _spawn_interval: float = 1.0
var _mob_hp: float = 100.0
var _wave_path: PackedVector2Array
var _spawned: int = 0
var _timer: float = 0.0
var _active: bool = false
var _boss: bool = false
var _boss_hp: float = 0.0
var _boss_index: int = -1

func start_wave(mob_count: int, spawn_interval: float, mob_hp: float, wave_path: PackedVector2Array,
		boss: bool = false, boss_hp: float = 0.0) -> void:
	_mob_count = mob_count
	_spawn_interval = spawn_interval
	_mob_hp = mob_hp
	_wave_path = wave_path
	_spawned = 0
	_timer = 0.0
	_active = true
	_boss = boss
	_boss_hp = boss_hp
	# Boss rides in the middle of the train so it is shielded by, but among, the wave.
	_boss_index = mob_count / 2 if boss else -1

func is_done() -> bool:
	return _spawned >= _mob_count and not _active

func sim_step(delta: float) -> void:
	if not _active:
		return
	if _spawned >= _mob_count:
		_active = false
		return
	_timer -= delta
	if _timer <= 0.0:
		_spawn_one()
		_timer = _spawn_interval

func _spawn_one() -> void:
	var mob := MobScript.new()
	mob.path = _wave_path
	if _boss and _spawned == _boss_index:
		mob.is_boss = true
		mob.max_hp = _boss_hp
	else:
		mob.max_hp = _mob_hp
	mob.board = board
	mobs_array.append(mob)
	get_parent().add_child(mob)
	_spawned += 1
