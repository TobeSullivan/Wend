extends Node2D

# Regression test for the projectile FX path (projectile_fx.gd):
#   Godot.exe --headless --path src res://tools/fx_smoke.tscn
# Directly fires a fx_fireball projectile at a dummy target and steps it to impact,
# asserting: body is an AnimatedSprite2D (not the arrow), the hit resolves, and an
# impact burst node is spawned as a sibling. Proves the path runs error-free without
# needing a live match / tutorial gating.

const ProjScript := preload("res://scripts/projectile.gd")
const ProjFXScript := preload("res://scripts/projectile_fx.gd")

class FakeMob extends Node2D:
	var alive := true
	var hp := 1.0   # < projectile damage, so the hit registers as a KILL (impact fires)
	var hits := 0
	func take_hit(_d, _c, _s) -> void:
		hits += 1
		alive = false

func _ready() -> void:
	var board := Node2D.new()
	add_child(board)

	var target := FakeMob.new()
	target.position = Vector2(50, 0)
	board.add_child(target)

	var p = ProjScript.new()
	p.target = target
	p.damage = 10.0
	p.is_crit = false
	p.fx_id = "fx_fireball"
	p.position = Vector2.ZERO
	board.add_child(p)
	await get_tree().process_frame   # let the projectile's _ready build its visual

	var body_ok: bool = p.sprite is AnimatedSprite2D
	print("BODY is AnimatedSprite2D: ", body_ok)

	# Big delta forces step >= dist → take_hit + impact spawn → returns true.
	var before := board.get_child_count()
	var done: bool = p.sim_step(1.0)
	var after := board.get_child_count()
	print("hit resolved: ", target.hits == 1, "  sim_step done: ", done)
	print("impact spawned (child delta): ", after - before, " (expect +1)")

	# A crit must stay the gold arrow (no body FX), and an unwired id must be empty.
	var crit = ProjScript.new()
	crit.target = FakeMob.new()
	crit.is_crit = true
	crit.fx_id = "fx_fireball"
	board.add_child(crit.get("target"))
	board.add_child(crit)
	await get_tree().process_frame
	var crit_is_arrow: bool = crit.sprite is Sprite2D
	print("crit stays arrow (not body FX): ", crit_is_arrow)

	var config := ProjFXScript.config_for("fx_fireball")
	var unwired_empty: bool = ProjFXScript.config_for("fx_gold_bolt").is_empty()
	print("config has body+impact: ", config.has("body") and config.has("impact"))
	print("unwired id returns empty: ", unwired_empty)

	# Trail hook (general capability — not currently bound to a shipped FX): one puff = one node.
	var fb_frame = config["body"]["frames"][0]
	var tb := board.get_child_count()
	ProjFXScript.spawn_trail_puff(board, Vector2(10, 10), {"frame": fb_frame, "px": 14.0, "alpha": 0.3, "life": 0.2})
	var trail_ok: bool = (board.get_child_count() - tb) == 1
	print("trail puff spawns a node: ", trail_ok)

	# Arcane bolt (T14 replacement) — directional single-frame body, no impact/trail.
	var arc := ProjFXScript.config_for("fx_arcane_bolt")
	var arcane_ok: bool = arc.has("body") and not arc.has("trail") and bool(arc["body"]["rotates"])
	print("arcane bolt is directional body-only: ", arcane_ok)

	var pass_all: bool = body_ok and target.hits == 1 and done and (after - before == 1) \
		and crit_is_arrow and config.has("body") and config.has("impact") and unwired_empty \
		and trail_ok and arcane_ok
	print("RESULT ", "✅ FX SMOKE OK" if pass_all else "❌ FX SMOKE FAILED")
	get_tree().quit()
