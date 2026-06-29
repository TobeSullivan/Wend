extends Node

const LOG_INTERVAL := 30.0

var _layer: CanvasLayer
var _label: Label
var _ui_accum := 0.0
var _log_accum := 0.0
var _peak_nodes := 0
var _peak_objects := 0

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 200
	add_child(_layer)
	_label = Label.new()
	_label.position = Vector2(8, 8)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	_label.visible = false
	_layer.add_child(_label)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_label.visible = not _label.visible
		if _label.visible:
			_label.text = _stats()

func _process(delta: float) -> void:
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	_peak_nodes = maxi(_peak_nodes, nodes)
	_peak_objects = maxi(_peak_objects, objects)
	_ui_accum += delta
	if _label.visible and _ui_accum >= 0.5:
		_ui_accum = 0.0
		_label.text = _stats()
	_log_accum += delta
	if _log_accum >= LOG_INTERVAL:
		_log_accum = 0.0
		print("[MONITOR] ", _stats().replace("\n", "  "))

func _stats() -> String:
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var static_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var video_mb := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	var fps := int(Performance.get_monitor(Performance.TIME_FPS))
	return "FPS %d\nNodes %d (peak %d)\nOrphans %d\nObjects %d (peak %d)\nStatic %.1f MB\nVideo %.1f MB" % [
		fps, nodes, _peak_nodes, orphans, objects, _peak_objects, static_mb, video_mb]
