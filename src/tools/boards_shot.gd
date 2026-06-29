extends Node2D

const MapLoaderScript := preload("res://scripts/map_loader.gd")
const MapGen := preload("res://scripts/map_generator.gd")
const MapResourceScript := preload("res://resources/map_resource.gd")

const OUT := "C:/dev/Wend/notes/shots/"

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await _shoot("coop", MapResourceScript.Mode.PVE, 3, 0, ["You", "Maple", "Koi"])
	await _shoot("ranked", MapResourceScript.Mode.PVP, 8, 1, [])
	print("BOARDS_SHOT DONE -> ", OUT)
	get_tree().quit()

func _shoot(tag: String, mode: int, boards: int, local: int, names: Array) -> void:
	var map = MapGen.generate(202 + boards, 2, mode)
	var host := Node2D.new()
	add_child(host)
	MapLoaderScript.build_match(host, map, boards, local, true, names)
	var coord = _find(host, func(c): return c.has_method("_start_run_phase") and "boards" in c)
	var rail = _find(host, func(c): return c.has_method("_on_boards_pressed"))
	var gv = _find(host, func(c): return c.has_method("focus_board") and "local_index" in c)

	await get_tree().create_timer(2.2).timeout
	if coord != null:
		coord._start_run_phase()
	await get_tree().create_timer(1.0).timeout
	await _frame()
	_save(tag + "_inmatch.png")

	if rail != null:
		rail._on_boards_pressed()
		await _frame()
		_save(tag + "_boards_picker.png")
		rail._on_boards_pressed()

	if gv != null:
		gv.focus_board(0 if local != 0 else 1)
		await _frame()
		_save(tag + "_spectate.png")

	host.queue_free()
	await _frame()

func _advance_done(coord) -> bool:
	return coord == null or coord.match_over

func _frame() -> void:
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _save(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name)
	print("  saved ", name)

func _find(node: Node, pred: Callable):
	for c in node.get_children():
		if pred.call(c):
			return c
		var r = _find(c, pred)
		if r != null:
			return r
	return null
