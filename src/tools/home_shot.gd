extends Control

# Throwaway capture harness for the home screen (polish #1 white-corner diagnosis). Instances
# the real HomeScreen, lets it render, then saves a full screenshot + 8x corner crops so the
# corner pixels are clearly inspectable. Run WINDOWED (headless saves blank images):
#   Godot.exe --path . res://tools/home_shot.tscn

const HomeScreen := preload("res://scripts/home_screen.gd")
const DIR := "C:/dev/Maze Battle TD/"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var h := HomeScreen.new()
	add_child(h)
	_capture.call_deferred()

func _capture() -> void:
	for i in range(40):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(DIR + "home_shot.png")
	var vp := img.get_size()
	var s := 64
	_crop(img, Rect2i(0, 0, s, s), "tl")
	_crop(img, Rect2i(vp.x - s, 0, s, s), "tr")
	_crop(img, Rect2i(0, vp.y - s, s, s), "bl")
	_crop(img, Rect2i(vp.x - s, vp.y - s, s, s), "br")
	get_tree().quit()

func _crop(img: Image, r: Rect2i, tag: String) -> void:
	var c := img.get_region(r)
	c.resize(r.size.x * 8, r.size.y * 8, Image.INTERPOLATE_NEAREST)
	c.save_png(DIR + "home_corner_%s.png" % tag)
