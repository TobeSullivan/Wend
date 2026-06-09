extends Node2D

# Throwaway: drive the campaign victory choreography and capture a mid-animation frame + the
# settled frame, to eyeball the staged reveal (design/JUICE.md). Run WINDOWED:
#   Godot.exe --path . res://tools/victory_shot.tscn
# Tween FEEL is a playtest item; this only confirms the composition stages without breaking.

const MapLoaderScript := preload("res://scripts/map_loader.gd")
const DIR := "C:/dev/Maze Battle TD/"

var _panel

func _ready() -> void:
	var map = load("res://campaign/mission_01.tres")
	MapLoaderScript.load_into(self, map)
	SceneManager.pending_map = map
	_run.call_deferred()

func _run() -> void:
	for i in range(20):
		await get_tree().process_frame
	# M1 opens with a blocking tutorial modal that pauses the tree — clear all tutorial UI and
	# unpause so the victory choreography (and its timers/tweens) can run for the capture.
	var doomed: Array = []
	for cls in ["TutorialCallout", "TutorialDirector", "BuildGuide"]:
		_find_all(self, cls, doomed)
	for n in doomed:
		n.free()  # immediate (queue_free would keep it findable this frame)
	get_tree().paused = false
	await get_tree().process_frame
	_panel = _find(self, "MatchEndPanel")
	if _panel == null:
		print("VICTORY_SHOT ❌ no MatchEndPanel found")
		get_tree().quit()
		return
	var rm = _panel.round_manager
	rm.total_damage_dealt = int(rm.gold_threshold) + 6000  # earn 3 stars, a round number to tick
	_panel._show_campaign_victory()
	# Mid-animation: hero in, stars cascading (~0.9s into the ~1.7s sequence).
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DIR + "victory_mid.png")
	# Settled.
	await get_tree().create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(DIR + "victory_final.png")
	print("VICTORY_SHOT ✅ captured mid + final")
	get_tree().quit()

func _find(root: Node, cls: String) -> Node:
	for n in root.get_children():
		var s = n.get_script()
		if s != null and s.get_global_name() == cls:
			return n
		var hit = _find(n, cls)
		if hit != null:
			return hit
	return null

func _find_all(root: Node, cls: String, out: Array) -> void:
	for n in root.get_children():
		var s = n.get_script()
		if s != null and s.get_global_name() == cls:
			out.append(n)
		_find_all(n, cls, out)
