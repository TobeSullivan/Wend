extends Control

const HomeScreen := preload("res://scripts/home_screen.gd")
const DIR := "C:/dev/Maze Battle TD/"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var h := HomeScreen.new()
	add_child(h)
	_capture.call_deferred()

func _capture() -> void:
	await get_tree().create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DIR + "home_mid.png")
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DIR + "home_settled.png")
	get_tree().quit()
