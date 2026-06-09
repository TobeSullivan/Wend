extends Control

# Throwaway capture harness for the home screen. Instances the real HomeScreen and saves a
# mid-arrival frame + the settled frame, to eyeball the JUICE entrance + break-the-grid hero
# attitude (design/JUICE.md + meta_menu_mock). Run WINDOWED (headless saves blank images):
#   Godot.exe --path . res://tools/home_shot.tscn

const HomeScreen := preload("res://scripts/home_screen.gd")
const DIR := "C:/dev/Maze Battle TD/"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var h := HomeScreen.new()
	add_child(h)
	_capture.call_deferred()

func _capture() -> void:
	# Mid-arrival: heroes dropping in, campaign/corners not yet up (~0.45s).
	await get_tree().create_timer(0.45).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DIR + "home_mid.png")
	# Settled: full composition at rest (off-axis heroes).
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DIR + "home_settled.png")
	get_tree().quit()
