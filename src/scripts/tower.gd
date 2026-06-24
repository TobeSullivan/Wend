extends Node2D
class_name Tower

const SPRITE_SCALE := 0.12

const LOADED_TEX := preload("res://assets/towers/arrow_box_loaded.png")
const UNLOADED_TEX := preload("res://assets/towers/arrow_box_unloaded.png")
const ProjectileScript := preload("res://scripts/projectile.gd")
const Motion := preload("res://scripts/motion.gd")
const TierAuraScript := preload("res://scripts/tier_aura.gd")

const GOLD_RING := Color("f4cc74")

# Barrel fan angles (degrees) by shot count, mirroring the reference.
const BARREL_FAN := {1: [0.0], 2: [-13.0, 13.0], 3: [-20.0, 0.0, 20.0], 4: [-27.0, -9.0, 9.0, 27.0]}
const BARREL_LEN := 13.0
const BARREL_WIDTH := 4.0
const BARREL_BASE_Y := -6.0
const BADGE_OFFSET := Vector2(15.0, -15.0)
const BADGE_R := 8.0

const RANGE_SEGMENTS := 48

var mobs: Array = []
var board
var skin_tex: Texture2D = null
var proj_tint: Color = Color.WHITE
var fx_id: String = ""
var aura_ramp: Array = []

var tier: int = GameConstants.MIN_TIER
var cooldown: float = 0.0
var _current_target: Node2D = null
var total_invested: int = 0
var grid_cell: Vector2i
var damage_done: float = 0.0
var kills: int = 0

var zone_bonus := {
	"damage": 0,
	"range": 0,
	"attack_speed": 0,
}

var sprite: Sprite2D
var _aura: TierAura
var _barrels: Node2D
var _ring: Line2D
var _selected_range: Line2D
var _selected: bool = false
var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	_barrels = Node2D.new()
	_barrels.z_index = 1
	add_child(_barrels)

	sprite = Sprite2D.new()
	if skin_tex != null:
		sprite.texture = skin_tex
		var fit := SPRITE_SCALE * float(LOADED_TEX.get_width()) / float(maxi(1, skin_tex.get_width()))
		sprite.scale = Vector2(fit, fit)
	else:
		sprite.texture = LOADED_TEX
		sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(sprite)

	_aura = TierAuraScript.new()
	add_child(_aura)

	_ring = Line2D.new()
	_ring.width = 2.5
	_ring.closed = true
	_ring.default_color = GOLD_RING
	_ring.visible = false
	_ring.z_index = 2
	add_child(_ring)

	_selected_range = Line2D.new()
	_selected_range.width = 3.0
	_selected_range.closed = true
	_selected_range.default_color = Color(1.0, 0.85, 0.35, 0.8)
	_selected_range.visible = false
	add_child(_selected_range)

	_compute_zone_bonuses()
	_apply_tier_visual()
	_refresh_range_circle()

func _compute_zone_bonuses() -> void:
	for stat in zone_bonus:
		zone_bonus[stat] = 0
	var zones: Array = board.bonus_zones if board != null else get_tree().get_nodes_in_group("bonus_zones")
	for zone in zones:
		if not zone.touches_tower_cell(grid_cell):
			continue
		if zone.type in zone_bonus:
			zone_bonus[zone.type] += zone.magnitude

func sim_step(delta: float, rng: RandomNumberGenerator) -> void:
	cooldown = maxf(0.0, cooldown - delta)

	var shot_count := get_shots()
	var targets := _find_targets(shot_count)
	_current_target = targets[0] if targets.size() > 0 else null

	if cooldown > 0.0:
		return
	if targets.is_empty():
		return
	for t in targets:
		_fire_at(t, rng)
	cooldown = get_cooldown()

# --- Tier-driven stats (placeholder scaling; balance deferred) ---

func get_damage() -> float:
	var tier_mult := pow(GameConstants.TIER_DAMAGE_GROWTH, tier - 1)
	return GameConstants.TOWER_BASE_DAMAGE * tier_mult * (1.0 + zone_bonus["damage"] / 100.0)

func get_range() -> float:
	var base := GameConstants.TOWER_BASE_RANGE + (tier - 1) * GameConstants.TIER_RANGE_PER_TIER
	return base * (1.0 + zone_bonus["range"] / 100.0)

func get_cooldown() -> float:
	var rate_mult: float = pow(GameConstants.TIER_RATE_GROWTH, tier - 1) * (1.0 + zone_bonus["attack_speed"] / 100.0)
	return GameConstants.TOWER_BASE_COOLDOWN / rate_mult

func get_shots() -> int:
	var s := 1
	if tier >= GameConstants.MULTISHOT_T2:
		s = 2
	if tier >= GameConstants.MULTISHOT_T3:
		s = 3
	if tier >= GameConstants.MULTISHOT_T4:
		s = 4
	return mini(s, GameConstants.MULTISHOT_HARD_CAP)

# Crit is parked under the tier model (plumbing kept for projectiles/cosmetics).
func get_crit_chance() -> float:
	return 0.0

func get_crit_damage_mult() -> float:
	return GameConstants.CRIT_DAMAGE_BASE

# --- Merge ---

func can_merge_with(other) -> bool:
	return other != null and is_instance_valid(other) and other != self \
		and other.tier == tier and tier < GameConstants.MAX_TIER

# `other` is consumed into this tower, which steps up one tier.
func absorb(other) -> void:
	total_invested += other.total_invested
	set_tier(tier + 1)

func set_tier(n: int) -> void:
	tier = clampi(n, GameConstants.MIN_TIER, GameConstants.MAX_TIER)
	_apply_tier_visual()
	_refresh_range_circle()
	if _selected and _selected_range != null:
		_selected_range.points = _circle_points(get_range())

func set_selected(value: bool) -> void:
	_selected = value
	_selected_range.visible = value
	if value:
		_selected_range.points = _circle_points(get_range())

func aura_poof_color() -> Color:
	if aura_ramp.is_empty():
		return GOLD_RING
	return CosmeticsCatalog.aura_sample(aura_ramp, TierAuraScript.tier_ratio(tier))["mid"]

func register_damage(amount: float, killed: bool) -> void:
	damage_done += amount
	if killed:
		kills += 1

func _find_targets(count: int) -> Array:
	var in_range: Array = []
	var r := get_range()
	for m in mobs:
		if not is_instance_valid(m) or not m.alive:
			continue
		if position.distance_to(m.position) > r:
			continue
		in_range.append(m)
	in_range.sort_custom(func(a, b): return a.path_index > b.path_index)
	if in_range.size() <= count:
		return in_range
	return in_range.slice(0, count)

func _fire_at(target: Node2D, rng: RandomNumberGenerator) -> void:
	var is_crit := rng.randf() < get_crit_chance()
	var dmg := get_damage()
	if is_crit:
		dmg *= get_crit_damage_mult()

	var p := ProjectileScript.new()
	p.target = target
	p.damage = dmg
	p.is_crit = is_crit
	p.source_tower = self
	p.position = position
	p.tint = proj_tint
	p.fx_id = fx_id
	get_parent().add_child(p)
	if board != null:
		board.projectiles.append(p)

	if skin_tex == null:
		sprite.texture = UNLOADED_TEX
		var tween := create_tween()
		tween.tween_interval(0.12)
		tween.tween_callback(func(): sprite.texture = LOADED_TEX)

# --- Visual morph ---

func _apply_tier_visual() -> void:
	if _aura != null:
		_aura.set_tier_aura(tier, aura_ramp)
	_rebuild_barrels()
	if _ring != null:
		if tier >= GameConstants.MAX_TIER:
			_ring.points = _circle_points(float(Grid.TILE_SIZE) * 0.42)
			_ring.visible = true
		else:
			_ring.visible = false
	queue_redraw()

func _rebuild_barrels() -> void:
	if _barrels == null:
		return
	for c in _barrels.get_children():
		c.queue_free()
	var fan: Array = BARREL_FAN[get_shots()]
	for ang in fan:
		var b := Line2D.new()
		b.width = BARREL_WIDTH
		b.default_color = Color("33372a")
		b.points = PackedVector2Array([Vector2(0, BARREL_BASE_Y), Vector2(0, BARREL_BASE_Y - BARREL_LEN)])
		b.rotation = deg_to_rad(ang)
		_barrels.add_child(b)

# Gummy squash-and-stretch that settles. No screen shake (design pivot juice spec).
func play_merge_juice() -> void:
	if not is_inside_tree():
		return
	scale = Vector2.ONE
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1.16, 1.30), Motion.dur(0.10))
	t.tween_property(self, "scale", Vector2(1.26, 0.80), Motion.dur(0.08))
	t.tween_property(self, "scale", Vector2(0.90, 1.12), Motion.dur(0.10))
	t.tween_property(self, "scale", Vector2(1.07, 0.95), Motion.dur(0.08))
	t.tween_property(self, "scale", Vector2(1.0, 1.0), Motion.dur(0.10))

func _draw() -> void:
	# Tier badge (upright, top-right): white disc + tier number.
	draw_circle(BADGE_OFFSET, BADGE_R, Color.WHITE)
	var txt := str(tier)
	var fs := 11
	var w := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(_font, BADGE_OFFSET + Vector2(-w * 0.5, fs * 0.36), txt,
		HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color("23261a"))

func _refresh_range_circle() -> void:
	_selected_range.points = _circle_points(get_range())

static func _circle_points(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(RANGE_SEGMENTS):
		var a := i * TAU / RANGE_SEGMENTS
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts
