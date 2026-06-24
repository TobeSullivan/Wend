extends Node2D
class_name BonusZone

const GridScript := preload("res://scripts/grid.gd")

const TYPE_COLORS := {
	"damage":       Color(1.0, 0.25, 0.25, 0.32),
	"attack_speed": Color(0.25, 0.55, 1.0, 0.32),
	"range":        Color(0.30, 0.95, 0.30, 0.32),
	"slow":         Color(0.20, 0.90, 0.95, 0.32),
}

const TYPE_DISPLAY_NAMES := {
	"damage":       "DAMAGE",
	"attack_speed": "ATK SPEED",
	"range":        "RANGE",
	"slow":         "SLOW",
}

var type: String
var magnitude: int
var radius: float

func _ready() -> void:
	add_to_group("bonus_zones")
	z_index = 50
	_add_label()

func _add_label() -> void:
	var label := Label.new()
	label.text = _format_label_text()
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var w := 220.0
	var h := 30.0
	label.size = Vector2(w, h)
	label.position = Vector2(-w / 2.0, -h / 2.0)
	add_child(label)

func _format_label_text() -> String:
	var display: String = TYPE_DISPLAY_NAMES.get(type, type.to_upper())
	var sign_str := "-" if type == "slow" else "+"
	return "%s %s%d%%" % [display, sign_str, magnitude]

func _draw() -> void:
	var fill: Color = TYPE_COLORS.get(type, Color(1, 1, 1, 0.3))
	draw_circle(Vector2.ZERO, radius, fill)
	var outline := Color(fill.r, fill.g, fill.b, 0.75)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, outline, 2.0, true)

func touches_tower_cell(cell: Vector2i) -> bool:
	var tower_center := GridScript.cell_to_world(cell)
	return position.distance_to(tower_center) <= radius + GridScript.TILE_SIZE / 2.0

func contains_world(pt: Vector2) -> bool:
	return position.distance_to(pt) <= radius

static func radius_for_magnitude(mag: int) -> float:
	var t: float = clampf(float(mag - 10) / 90.0, 0.0, 1.0)
	var r_tiles: float = lerpf(2.25, 0.85, t)
	return r_tiles * GridScript.TILE_SIZE
