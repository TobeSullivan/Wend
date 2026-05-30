extends AnimatedSprite2D
# One-shot death/explosion effect. Spawned at a mob's position when it's killed;
# plays once, then frees itself. Decoupled from the mob so the mob keeps moving.

const _DIE_FRAMES := 10

func setup(world_pos: Vector2, rot: float) -> void:
	position = world_pos
	rotation = rot
	scale = Vector2(0.08, 0.08)
	z_index = 1  # above mobs so the burst reads on top
	sprite_frames = _build_frames()
	animation_finished.connect(queue_free)
	play("die")

func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("die")
	frames.set_animation_loop("die", false)
	frames.set_animation_speed("die", 24.0)  # fast burst
	for i in range(_DIE_FRAMES):
		var tex: Texture2D = load("res://assets/mobs/__zombie_01_die_%03d.png" % i)
		frames.add_frame("die", tex)
	if frames.has_animation("default"):
		frames.remove_animation("default")
	return frames
