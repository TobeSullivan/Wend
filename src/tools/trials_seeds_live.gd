extends Node

const NakamaBackendScript := preload("res://scripts/nakama_backend.gd")

func _ready() -> void:
	var fails := 0
	var connected: bool = await NakamaService.connect_backend()
	print("connected: ", connected)
	if not connected:
		get_tree().quit(1)
		return
	var be = NakamaBackendScript.new(NakamaService)
	var a: Dictionary = await be.fetch_trials_seeds()
	var b: Dictionary = await be.fetch_trials_seeds()
	for w in ["daily", "weekly", "monthly"]:
		var sa: Array = a.get(w, [])
		var sb: Array = b.get(w, [])
		var ok5: bool = sa.size() == 5
		var stable: bool = str(sa) == str(sb)
		print("  ", w, " -> ", sa, "  5? ", ok5, "  stable? ", stable)
		if not ok5 or not stable:
			fails += 1
	if str(a.get("daily")) == str(a.get("monthly")):
		print("  ❌ daily == monthly (should differ)"); fails += 1
	print("RESULT ", "✅ TRIALS SEEDS LIVE OK" if fails == 0 else "❌ FAILED (%d)" % fails)
	get_tree().quit(fails)
