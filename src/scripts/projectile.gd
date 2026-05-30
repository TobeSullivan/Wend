extends Node2D
class_name Projectile

const SPEED := 900.0  # pixels/sec
const ARROW_TEX := preload("res://assets/towers/arrow.png")

var target: Node2D
var damage: float = 0.0
var is_crit: bool = false
var source_tower: Node2D = null  # who fired this — credited with damage/kills on hit

var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = ARROW_TEX
	if is_crit:
		sprite.scale = Vector2(0.32, 0.32)
		sprite.modulate = Color(1.6, 1.3, 0.4, 1.0)  # gold tint
	else:
		sprite.scale = Vector2(0.22, 0.22)
	add_child(sprite)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var to_target := target.position - position
	var dist := to_target.length()
	var step := SPEED * delta

	# Arrow native facing is west (head points -X); add PI so head leads.
	sprite.rotation = to_target.angle() + PI

	if step >= dist:
		if target.has_method("take_hit"):
			target.take_hit(damage, is_crit, source_tower)
		queue_free()
	else:
		position += to_target.normalized() * step
