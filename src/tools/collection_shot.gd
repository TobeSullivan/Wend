extends Control

const DIR := "C:/dev/Maze Battle TD/"
var _saved

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_saved = SaveData.data.get("cosmetics", {}).duplicate(true)
	SaveData.data["cosmetics"] = {
		"owned": ["frame_wood", "banner_mint_choco"],
		"equipped": {"frame": "frame_wood", "banner": "banner_mint_choco"},
		"season_points": 0, "claimed_tiers": [],
	}
	var coll = load("res://scenes/collection.tscn").instantiate()
	add_child(coll)
	_capture.call_deferred()

func _capture() -> void:
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DIR + "collection_shot.png")
	print("SHOT collection_shot.png")
	SaveData.data["cosmetics"] = _saved
	SaveData.save()
	get_tree().quit()
