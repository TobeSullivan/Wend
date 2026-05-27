extends Node2D
class_name Tower

# Base values — actual values derived from tiers.
const BASE_RANGE := 320.0
const BASE_DAMAGE := 25.0
const BASE_COOLDOWN := 0.8

const TIER_INCREMENT := 0.10  # +10% per tier on most stats

const LOADED_TEX := preload("res://assets/towers/arrow_box_loaded.png")
const UNLOADED_TEX := preload("res://assets/towers/arrow_box_unloaded.png")
const ProjectileScript := preload("res://scripts/projectile.gd")

# DESIGN color map: damage=red, range=green, attack_speed=blue,
# crit_chance=yellow, crit_damage=orange, multishot=purple.
# Each tier subtracts K from the complementary RGB channels.
const STAT_COLOR_SUB := {
	"damage":       Vector3(0.0,  0.7, 0.7),  # red
	"range":        Vector3(0.7,  0.0, 0.7),  # green
	"attack_speed": Vector3(0.7,  0.7, 0.0),  # blue
	"crit_chance":  Vector3(0.0,  0.0, 0.7),  # yellow
	"crit_damage":  Vector3(0.0,  0.35, 0.7), # orange
	"multishot":    Vector3(0.0,  0.7, 0.0),  # purple
}
const K_PER_TIER := 0.07

const RANGE_SEGMENTS := 48

var mobs: Array = []  # injected by build_controller / main
var sprite: Sprite2D
var cooldown: float = 0.0
var _current_target: Node2D = null

var tiers := {
	"damage": 0,
	"range": 0,
	"attack_speed": 0,
	"crit_chance": 0,
	"crit_damage": 0,
	"multishot": 0,
}

var _selected_range: Line2D
var _selected: bool = false

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = LOADED_TEX
	sprite.scale = Vector2(0.25, 0.25)
	add_child(sprite)

	_selected_range = Line2D.new()
	_selected_range.width = 3.0
	_selected_range.closed = true
	_selected_range.default_color = Color(1.0, 0.85, 0.35, 0.8)
	_selected_range.visible = false
	add_child(_selected_range)
	_refresh_range_circle()

func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)

	_current_target = _find_target()
	if _current_target != null:
		var to_target := _current_target.position - position
		sprite.rotation = to_target.angle() + PI / 2.0

	if cooldown > 0.0:
		return
	if _current_target != null:
		_fire_at(_current_target)
		cooldown = get_cooldown()

func get_damage() -> float:
	return BASE_DAMAGE * (1.0 + tiers["damage"] * TIER_INCREMENT)

func get_range() -> float:
	return BASE_RANGE * (1.0 + tiers["range"] * TIER_INCREMENT)

func get_cooldown() -> float:
	return BASE_COOLDOWN / (1.0 + tiers["attack_speed"] * TIER_INCREMENT)

func upgrade(stat: String) -> void:
	if not (stat in tiers):
		return
	tiers[stat] += 1
	_update_modulate()
	if stat == "range":
		_refresh_range_circle()

func set_selected(value: bool) -> void:
	_selected = value
	_selected_range.visible = value

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_progress: int = -1
	var r := get_range()
	for m in mobs:
		if not is_instance_valid(m):
			continue
		if m.state != "walk":
			continue
		if position.distance_to(m.position) > r:
			continue
		if m.path_index > best_progress:
			best_progress = m.path_index
			best = m
	return best

func _fire_at(target: Node2D) -> void:
	var p := ProjectileScript.new()
	p.target = target
	p.damage = get_damage()
	p.position = position
	get_parent().add_child(p)

	sprite.texture = UNLOADED_TEX
	var tween := create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(func(): sprite.texture = LOADED_TEX)

func _update_modulate() -> void:
	var r := 1.0
	var g := 1.0
	var b := 1.0
	for stat in tiers:
		var t: int = tiers[stat]
		if t == 0:
			continue
		var sub: Vector3 = STAT_COLOR_SUB[stat]
		r -= sub.x * t * K_PER_TIER
		g -= sub.y * t * K_PER_TIER
		b -= sub.z * t * K_PER_TIER
	sprite.modulate = Color(maxf(0.0, r), maxf(0.0, g), maxf(0.0, b), 1.0)

func _refresh_range_circle() -> void:
	var r := get_range()
	var pts := PackedVector2Array()
	for i in range(RANGE_SEGMENTS):
		var a := i * TAU / RANGE_SEGMENTS
		pts.append(Vector2(cos(a), sin(a)) * r)
	_selected_range.points = pts
