extends Node2D
class_name Mob

const MAX_HP := 100.0
const SPEED := 80.0  # pixels/sec

var path: PackedVector2Array
var path_index: int = 0
var hp: float = MAX_HP
var state: String = "walk"  # "walk" or "die"

var anim: AnimatedSprite2D

func _ready() -> void:
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = _build_frames()
	anim.scale = Vector2(0.13, 0.13)
	anim.animation_finished.connect(_on_anim_finished)
	add_child(anim)
	anim.play("walk")

	if path.size() > 0:
		position = path[0]
		path_index = 1

func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()

	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 12.0)
	for i in range(10):
		var tex: Texture2D = load("res://assets/mobs/__zombie_01_walk_2_%03d.png" % i)
		frames.add_frame("walk", tex)

	frames.add_animation("die")
	frames.set_animation_loop("die", false)
	frames.set_animation_speed("die", 18.0)
	for i in range(10):
		var tex: Texture2D = load("res://assets/mobs/__zombie_01_die_%03d.png" % i)
		frames.add_frame("die", tex)

	# Remove the auto-created "default" animation
	if frames.has_animation("default"):
		frames.remove_animation("default")

	return frames

func _physics_process(delta: float) -> void:
	if state != "walk" or path.size() < 2:
		return

	if path_index >= path.size():
		# Reached exit — despawn
		queue_free()
		return

	var target := path[path_index]
	var to_target := target - position
	var step := SPEED * delta

	if step >= to_target.length():
		position = target
		path_index += 1
	else:
		position += to_target.normalized() * step

	# Sprite's native facing is north (head at top of sprite, -Y axis).
	# Rotate +PI/2 offset so head leads the movement direction.
	if to_target.length_squared() > 0.01:
		anim.rotation = to_target.angle() + PI / 2.0

func take_hit(damage: float) -> void:
	if state != "walk":
		return
	hp -= damage
	if hp <= 0.0:
		_explode_and_respawn()

func _explode_and_respawn() -> void:
	state = "die"
	anim.play("die")

func _on_anim_finished() -> void:
	if state == "die":
		hp = MAX_HP
		state = "walk"
		anim.play("walk")
