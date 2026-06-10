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

const _FIREBALL := [
	preload(FB + "fireball_01.png"), preload(FB + "fireball_02.png"), preload(FB + "fireball_03.png"),
	preload(FB + "fireball_04.png"), preload(FB + "fireball_05.png"), preload(FB + "fireball_06.png"),
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
