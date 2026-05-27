extends Node2D
class_name Spawner

const MobScript := preload("res://scripts/mob.gd")

# Configured by main.gd before _ready()
var path: PackedVector2Array
var mobs_array: Array  # shared reference with tower(s)
var mob_count: int = 8
var spawn_interval: float = 1.5
var initial_delay: float = 0.0  # wait this long before first spawn

var _spawned: int = 0
var _timer: float = 0.0

func _ready() -> void:
	_timer = initial_delay

func _process(delta: float) -> void:
	if _spawned >= mob_count:
		return
	_timer -= delta
	if _timer <= 0.0:
		_spawn_one()
		_timer = spawn_interval

func _spawn_one() -> void:
	var mob := MobScript.new()
	mob.path = path
	mobs_array.append(mob)
	get_parent().add_child(mob)
	_spawned += 1
