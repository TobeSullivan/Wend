extends Node2D
class_name Mob

const DamageNumberScript := preload("res://scripts/damage_number.gd")
const DeathFxScript := preload("res://scripts/death_fx.gd")

var path: PackedVector2Array
var path_index: int = 0
var max_hp: float = GameConstants.MOB_BASE_HP
var hp: float = GameConstants.MOB_BASE_HP
var alive: bool = true

var board

var anim: AnimatedSprite2D

static var _walk_frames: SpriteFrames = null

func _ready() -> void:
	hp = max_hp
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = _shared_walk_frames()
	anim.scale = Vector2(0.08, 0.08)
	add_child(anim)
	anim.play("walk")

	if path.size() > 0:
		position = path[0]
		path_index = 1

static func _shared_walk_frames() -> SpriteFrames:
	if _walk_frames != null:
		return _walk_frames
	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 12.0)
	for i in range(10):
		var tex: Texture2D = load("res://assets/mobs/__zombie_01_walk_2_%03d.png" % i)
		frames.add_frame("walk", tex)
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_walk_frames = frames
	return _walk_frames

func sim_step(delta: float) -> bool:
	if path.size() < 2:
		return false

	if path_index >= path.size():
		return true

	var target := path[path_index]
	var to_target := target - position
	var step := _current_speed() * delta

	if step >= to_target.length():
		position = target
		path_index += 1
	else:
		position += to_target.normalized() * step

	if to_target.length_squared() > 0.01:
		anim.rotation = to_target.angle() + PI / 2.0
	return false

func _current_speed() -> float:
	var slow_total := 0
	var zones: Array = board.bonus_zones if board != null else get_tree().get_nodes_in_group("bonus_zones")
	for zone in zones:
		if zone.type != "slow":
			continue
		if zone.contains_world(position):
			slow_total += zone.magnitude
	var mult: float = maxf(GameConstants.MOB_SLOW_FLOOR, 1.0 - float(slow_total) / 100.0)
	return GameConstants.MOB_SPEED * mult

func take_hit(damage: float, is_crit: bool = false, source: Node2D = null) -> void:
	var credited := minf(damage, hp)
	hp -= damage
	_spawn_damage_number(damage, is_crit)
	if board != null:
		board._on_damage_dealt(credited)
	var killed := hp <= 0.0
	if source != null and is_instance_valid(source):
		source.register_damage(credited, killed)
	if killed:
		_explode_and_respawn()

func _spawn_damage_number(amount: float, is_crit: bool) -> void:
	if not bool(SaveData.get_setting("damage_numbers")):
		return
	if not is_visible_in_tree():
		return
	var dn := DamageNumberScript.new()
	get_parent().add_child(dn)
	dn.setup(amount, is_crit, position)

func _explode_and_respawn() -> void:
	if is_visible_in_tree():
		var fx := DeathFxScript.new()
		get_parent().add_child(fx)
		fx.setup(position, anim.rotation)
	hp = max_hp
	if board != null:
		board._on_mob_killed()
