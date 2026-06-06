extends Node2D
class_name GridOverlay

# Faint cell grid drawn over the play area (mockup: #grid line, white @ 0.07 opacity).
# Sits above the grass, below the road. Purely cosmetic — shows the buildable cells.

var cols: int = 25
var rows: int = 14
var cell: float = 48.0

func _draw() -> void:
	var col := Color(1, 1, 1, 0.07)
	var w := cols * cell
	var h := rows * cell
	for x in range(cols + 1):
		draw_line(Vector2(x * cell, 0), Vector2(x * cell, h), col, 1.4)
	for y in range(rows + 1):
		draw_line(Vector2(0, y * cell), Vector2(w, y * cell), col, 1.4)
