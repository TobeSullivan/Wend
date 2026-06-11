extends RefCounted
class_name ProjectileFX

# Render-only projectile FX, resolved from the equipped "proj" cosmetic id. LOCAL board
# ONLY (cardinal rule: never enters the sim/record — opponents see the default arrow).
# Hooks a milestone FX can declare:
#   body   — the projectile sprite IS this animation (e.g. a fireball), sized to the
#            arrow's on-screen footprint (~28px) and moving at the same speed, so what an
#            opponent reads (timing + footprint) is unchanged — only the sprite differs.
#   impact — a one-shot burst spawned at the hit point. NOISE-GATED: kept small/short;
#            dial back to on-kill-only if it reads busy at scale (many towers × shots).
#   trail  — (not yet wired) a fading streak behind the projectile.
#
# Only FULLY art-wired FX appear in config_for(); every other "proj" id falls back to the
# plain tinted arrow (CosmeticsCatalog.tint_for still applies). Crits always keep the gold
# arrow tell and get NO body/impact FX, so the crit read never depends on a cosmetic.

const FB := "res://assets/fx/fireball/"
const ICE := "res://assets/fx/ice/"
const ARC := "res://assets/fx/arcane/"

const _ARCANE_BOLT := [preload(ARC + "bolt.png")]   # single static frame

const _FIREBALL := [
	preload(FB + "fireball_01.png"), preload(FB + "fireball_02.png"), preload(FB + "fireball_03.png"),
	preload(FB + "fireball_04.png"), preload(FB + "fireball_05.png"), preload(FB + "fireball_06.png"),
]

const _ICE_SHARD := [
	preload(ICE + "shard_01.png"), preload(ICE + "shard_02.png"), preload(ICE + "shard_03.png"),
	preload(ICE + "shard_04.png"), preload(ICE + "shard_05.png"), preload(ICE + "shard_06.png"),
	preload(ICE + "shard_07.png"),
]

const _ICE_EXPLODE := [
	preload(ICE + "explode_01.png"), preload(ICE + "explode_02.png"), preload(ICE + "explode_03.png"),
	preload(ICE + "explode_04.png"), preload(ICE + "explode_05.png"), preload(ICE + "explode_06.png"),
	preload(ICE + "explode_07.png"), preload(ICE + "explode_08.png"), preload(ICE + "explode_09.png"),
	preload(ICE + "explode_10.png"), preload(ICE + "explode_11.png"), preload(ICE + "explode_12.png"),
]

# Cache of built SpriteFrames keyed "<id>:<hook>[:once]", so many projectiles share one
# resource instead of rebuilding a SpriteFrames per shot.
static var _frames_cache := {}

# id -> {body?: {...}, impact?: {...}}. Returns {} for unwired ids (plain arrow + tint).
# px = target on-screen HEIGHT in pixels (arrow renders ~14–35px, tile is 48px).
static func config_for(id: String) -> Dictionary:
	match id:
		"fx_fireball":
			return {
				"body":   {"key": "fx_fireball:body",   "frames": _FIREBALL, "fps": 14.0, "px": 28.0, "rotates": false},
				"impact": {"key": "fx_fireball:impact", "frames": _FIREBALL, "fps": 36.0, "px": 24.0, "alpha": 0.5},
			}
		"fx_ice_spell":
			# The shard is directional (tip leads), so it faces travel like the arrow (+PI).
			# Impact = ice shatter, kept subtle/translucent + on-kill like the fireball.
			return {
				"body":   {"key": "fx_ice_spell:body",   "frames": _ICE_SHARD,   "fps": 18.0, "px": 12.0, "rotates": true, "face_offset": PI},
				"impact": {"key": "fx_ice_spell:impact", "frames": _ICE_EXPLODE, "fps": 34.0, "px": 26.0, "alpha": 0.5},
			}
		"fx_arcane_bolt":
			# The crystal towers' own magic projectile (towers.zip): a glowing energy bolt,
			# directional (tip leads). A distinct silhouette from the round fireball + the ice
			# shard. Single-frame (static), body-only.
			return {
				"body": {"key": "fx_arcane_bolt:body", "frames": _ARCANE_BOLT, "fps": 1.0, "px": 24.0, "rotates": true, "face_offset": PI / 2.0},
			}
		_:
			return {}

static func has_body(id: String) -> bool:
	return config_for(id).has("body")

static func has_impact(id: String) -> bool:
	return config_for(id).has("impact")

# Shared SpriteFrames for a hook (built once, cached). `loop` true for the flying body,
# false for the one-shot impact burst.
static func _sprite_frames(cfg: Dictionary, loop: bool) -> SpriteFrames:
	var key: String = String(cfg["key"]) + ("" if loop else ":once")
	if _frames_cache.has(key):
		return _frames_cache[key]
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", cfg["fps"])
	sf.set_animation_loop("default", loop)
	for t in cfg["frames"]:
		sf.add_frame("default", t)
	_frames_cache[key] = sf
	return sf

# Build the flying-body AnimatedSprite2D for a projectile (caller adds it as the visual).
# Height ~= cfg.px (matched to the arrow footprint). modulate stays WHITE — a fireball
# carries its own colour; the proj tint is for the plain arrow only.
static func make_body(cfg: Dictionary) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = _sprite_frames(cfg, true)
	var fh: float = cfg["frames"][0].get_size().y
	var s: float = float(cfg["px"]) / fh
	a.scale = Vector2(s, s)
	a.play("default")
	return a

# Spawn a one-shot impact burst at `pos` under `parent` (the board container). Render-only;
# frees itself when the animation finishes. No-op if `id` has no impact hook.
static func spawn_impact(parent: Node2D, pos: Vector2, id: String) -> void:
	var cfg := config_for(id)
	if not cfg.has("impact"):
		return
	var imp: Dictionary = cfg["impact"]
	var a := AnimatedSprite2D.new()
	a.sprite_frames = _sprite_frames(imp, false)
	a.position = pos
	var fh: float = imp["frames"][0].get_size().y
	var s: float = float(imp["px"]) / fh
	a.scale = Vector2(s, s)
	a.modulate = Color(1.0, 1.0, 1.0, float(imp.get("alpha", 1.0)))   # translucent = less busy
	a.z_index = 5
	a.animation_finished.connect(a.queue_free)
	parent.add_child(a)
	a.play("default")

# Drop one fading trail puff at `pos` under `parent` (the board container). Render-only;
# fades alpha→0 and shrinks over `life`, then frees. Called as the projectile travels.
static func spawn_trail_puff(parent: Node2D, pos: Vector2, cfg: Dictionary) -> void:
	var tex: Texture2D = cfg["frame"]
	var s := Sprite2D.new()
	s.texture = tex
	var sc: float = float(cfg["px"]) / tex.get_size().y
	s.scale = Vector2(sc, sc)
	s.position = pos
	s.modulate = Color(1.0, 1.0, 1.0, float(cfg.get("alpha", 0.35)))
	s.z_index = 4   # under the body + impact, so the live projectile reads on top
	parent.add_child(s)
	var life: float = float(cfg.get("life", 0.25))
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "modulate:a", 0.0, life)
	tw.tween_property(s, "scale", s.scale * 0.5, life)
	tw.set_parallel(false)
	tw.tween_callback(s.queue_free)
