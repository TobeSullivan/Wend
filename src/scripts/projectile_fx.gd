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
const LTN := "res://assets/fx/lightning/"
const SMK := "res://assets/fx/smoke/"

const _ARCANE_BOLT := [preload(ARC + "bolt.png")]   # single static frame
const _DARK_ORB := [preload(ARC + "orb.png")]       # single static frame (recoloured dark)
const _STAR := preload("res://assets/fx/burst/star.png")   # single-frame burst (tint per FX)

const _LIGHTNING := [
	preload(LTN + "electric_01.png"), preload(LTN + "electric_02.png"),
	preload(LTN + "electric_03.png"), preload(LTN + "electric_04.png"),
]

const _SMOKE_RING := [
	preload(SMK + "ring_01.png"), preload(SMK + "ring_02.png"), preload(SMK + "ring_03.png"),
	preload(SMK + "ring_04.png"), preload(SMK + "ring_05.png"), preload(SMK + "ring_06.png"),
	preload(SMK + "ring_07.png"), preload(SMK + "ring_08.png"), preload(SMK + "ring_09.png"),
	preload(SMK + "ring_10.png"), preload(SMK + "ring_11.png"), preload(SMK + "ring_12.png"),
]

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
		"fx_lightning":
			# Electric streak (tesla pack), 4-frame flicker, lies along travel (face_offset 0).
			return {
				"body": {"key": "fx_lightning:body", "frames": _LIGHTNING, "fps": 16.0, "px": 14.0, "rotates": true, "face_offset": 0.0},
			}
		"fx_dark":
			# Dark spell = the magic orb recoloured dark-violet (body modulate). Radial.
			return {
				"body": {"key": "fx_dark:body", "frames": _DARK_ORB, "fps": 1.0, "px": 24.0, "rotates": false, "modulate": Color("6a3a8a")},
			}
		"fx_explosion":
			# Impact-only starburst (single-frame BURST: scales up + fades). On-kill, native orange.
			return {
				"impact": {"frame": _STAR, "px": 34.0, "life": 0.22, "from": 0.3, "to": 1.05, "alpha": 0.7},
			}
		"fx_blue_impact":
			# Same starburst, tinted blue. Impact-only (arrow body stays).
			return {
				"impact": {"frame": _STAR, "px": 30.0, "life": 0.20, "from": 0.3, "to": 1.0, "alpha": 0.6, "modulate": Color("4a9fdf")},
			}
		"fx_smoke_ring":
			# Animated 12-frame smoke ring (cannon pack), pale + on-kill. Impact-only.
			return {
				"impact": {"key": "fx_smoke_ring:impact", "frames": _SMOKE_RING, "fps": 30.0, "px": 40.0, "alpha": 0.6},
			}
		_:
			return {}

# A single representative frame for the Collection icon (so each FX self-illustrates):
# the body's first frame, else a MID impact frame (full ring/burst), else null = no art.
static func icon_frame(id: String) -> Texture2D:
	var cfg := config_for(id)
	if cfg.has("body"):
		return cfg["body"]["frames"][0]
	if cfg.has("impact"):
		var imp: Dictionary = cfg["impact"]
		if imp.has("frame"):
			return imp["frame"]
		if imp.has("frames"):
			return imp["frames"][imp["frames"].size() / 2]
	return null

# The FX's own recolour (dark spell / blue impact), so the icon matches the in-match look.
static func icon_modulate(id: String) -> Color:
	var cfg := config_for(id)
	if cfg.has("body") and cfg["body"].has("modulate"):
		return cfg["body"]["modulate"]
	if cfg.has("impact") and cfg["impact"].has("modulate"):
		return cfg["impact"]["modulate"]
	return Color.WHITE

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
	if cfg.has("modulate"):
		a.modulate = cfg["modulate"]   # recolour (e.g. dark spell)
	a.play("default")
	return a

# Spawn a one-shot impact burst at `pos` under `parent` (the board container). Render-only;
# frees itself when the animation finishes. No-op if `id` has no impact hook.
static func spawn_impact(parent: Node2D, pos: Vector2, id: String) -> void:
	var cfg := config_for(id)
	if not cfg.has("impact"):
		return
	var imp: Dictionary = cfg["impact"]
	var tint: Color = imp.get("modulate", Color.WHITE)
	var col := Color(tint.r, tint.g, tint.b, float(imp.get("alpha", 1.0)))
	if imp.has("frame"):
		# Single-frame BURST: a Sprite2D that scales up + fades, then frees. Used for the
		# starburst explosion / blue impact (no sprite sheet for those).
		var tex: Texture2D = imp["frame"]
		var base: float = float(imp["px"]) / tex.get_size().y
		var s := Sprite2D.new()
		s.texture = tex
		s.scale = Vector2(base, base) * float(imp.get("from", 0.4))
		s.position = pos
		s.modulate = col
		s.z_index = 5
		parent.add_child(s)
		var life: float = float(imp.get("life", 0.2))
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "scale", Vector2(base, base) * float(imp.get("to", 1.0)), life)
		tw.tween_property(s, "modulate:a", 0.0, life)
		tw.set_parallel(false)
		tw.tween_callback(s.queue_free)
		return
	# Animated one-shot (sprite sheet): smoke ring, ice shatter, fireball burst.
	var a := AnimatedSprite2D.new()
	a.sprite_frames = _sprite_frames(imp, false)
	a.position = pos
	var fh: float = imp["frames"][0].get_size().y
	a.scale = Vector2(float(imp["px"]) / fh, float(imp["px"]) / fh)
	a.modulate = col
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
