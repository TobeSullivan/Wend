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

	# Trail hook: a fx_fire_trail projectile dropping a puff after travelling past `spacing`.
	var tgt2 := FakeMob.new()
	tgt2.position = Vector2(500, 0)   # far, so a partial step moves without hitting
	board.add_child(tgt2)
	var pt = ProjScript.new()
	pt.target = tgt2
	pt.damage = 10.0
	pt.fx_id = "fx_fire_trail"
	pt.position = Vector2.ZERO
	board.add_child(pt)
	await get_tree().process_frame
	var tb := board.get_child_count()
	pt.sim_step(0.05)   # 900*0.05 = 45px > spacing(26) → one puff, no hit
	var trail_ok: bool = (board.get_child_count() - tb) == 1
	print("trail puff dropped in flight: ", trail_ok)

	var pass_all: bool = body_ok and target.hits == 1 and done and (after - before == 1) \
		and crit_is_arrow and config.has("body") and config.has("impact") and unwired_empty \
		and trail_ok
	print("RESULT ", "✅ FX SMOKE OK" if pass_all else "❌ FX SMOKE FAILED")
	get_tree().quit()
