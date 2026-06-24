extends Control

const DIR := "C:/dev/Maze Battle TD/"
const TaskCat := preload("res://scripts/task_catalog.gd")
var _saved_t; var _saved_c

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_saved_t = SaveData.data.get("tasks")
	_saved_c = SaveData.data.get("cosmetics")
	var st = TaskCat.fresh_state()
	TaskCat.roll_windows(st, TaskCat.current_keys())
	TaskCat.accumulate(st, {"towers": 12, "zones": 4, "kills": 140, "games": 2, "score": 1200000})
	SaveData.data["tasks"] = st
	var c = (_saved_c.duplicate(true) if typeof(_saved_c) == TYPE_DICTIONARY else {})
	c["season_points"] = 2300
	SaveData.data["cosmetics"] = c
	var s = load("res://scenes/season.tscn").instantiate()
	add_child(s)
	_shot.call_deferred(s)

func _shot(s) -> void:
	await get_tree().create_timer(0.6).timeout
	s._show_tasks(true)
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DIR + "season_shot.png")
	print("SHOT season_shot.png")
	SaveData.data["tasks"] = _saved_t
	SaveData.data["cosmetics"] = _saved_c
	SaveData.save()
	get_tree().quit()
