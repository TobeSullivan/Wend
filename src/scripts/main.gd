extends Node2D

const SpawnerScript := preload("res://scripts/spawner.gd")
const BuildControllerScript := preload("res://scripts/build_controller.gd")
const MARKER_TEX := preload("res://assets/maps/level_marker_01.png")

# Entry (off-screen left) → checkpoint (top middle) → exit (off-screen right)
var path := PackedVector2Array([
	Vector2(-120, 540),
	Vector2(960, 320),
	Vector2(2040, 540),
])

var mobs: Array = []

func _ready() -> void:
	_setup_background()
	_setup_path()
	_spawn_spawner()
	_spawn_build_controller()

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.24, 0.42, 0.22)  # placeholder mid-green
	bg.size = Vector2(1920, 1080)
	bg.z_index = -100
	add_child(bg)

func _setup_path() -> void:
	var line := Line2D.new()
	line.points = path
	line.width = 50.0
	line.default_color = Color(0.46, 0.36, 0.24, 1.0)
	line.z_index = -50
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)

	var marker := Sprite2D.new()
	marker.texture = MARKER_TEX
	marker.position = path[1]
	marker.z_index = -40
	add_child(marker)

func _spawn_build_controller() -> void:
	var ctrl := BuildControllerScript.new()
	ctrl.path = path
	ctrl.mobs_array = mobs
	add_child(ctrl)

func _spawn_spawner() -> void:
	var spawner := SpawnerScript.new()
	spawner.path = path
	spawner.mobs_array = mobs
	spawner.mob_count = 8
	spawner.spawn_interval = 1.5
	spawner.initial_delay = 0.5
	add_child(spawner)
