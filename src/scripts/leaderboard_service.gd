extends Node
class_name LeaderboardService

const MapResourceScript := preload("res://resources/map_resource.gd")

const SCALE_IDS := ["thread", "weave", "tangle", "snarl", "knot"]
const SCALE_NAMES := ["Thread", "Weave", "Tangle", "Snarl", "Knot"]
const WINDOW_IDS := {
	MapResourceScript.WindowType.DAILY: "daily",
	MapResourceScript.WindowType.WEEKLY: "weekly",
	MapResourceScript.WindowType.MONTHLY: "monthly",
}
const GROUPS := ["solo", "duo", "trio", "quad"]

const BETA := true

const ROUND_SCORE_MULT := 1_000_000_000_000

static func encode_score(rounds: int, score: int) -> int:
	return maxi(0, rounds) * ROUND_SCORE_MULT + clampi(score, 0, ROUND_SCORE_MULT - 1)

static func round_part(composite: int) -> int:
	return int(composite / ROUND_SCORE_MULT)

static func score_part(composite: int) -> int:
	return int(composite % ROUND_SCORE_MULT)

const RANKED_BANDS := [
	{"name": "Masters", "tag": "mas", "base": 400, "cap": -1},
	{"name": "Gold", "tag": "gold", "base": 300, "cap": 399},
	{"name": "Silver", "tag": "sil", "base": 200, "cap": 299},
	{"name": "Bronze", "tag": "brz", "base": 100, "cap": 199},
	{"name": "Stone", "tag": "stn", "base": 0, "cap": 99},
]

const WEEK_SECONDS := 604800
const _MONDAY_EPOCH := 345600

static var _backend

static func backend():
	if _backend == null:
		_backend = LocalBackend.new()
	return _backend

static func set_backend(b) -> void:
	_backend = b

static func scale_id(tier: int) -> String:
	return SCALE_IDS[clampi(tier - 1, 0, 4)]

static func scale_name(tier: int) -> String:
	return SCALE_NAMES[clampi(tier - 1, 0, 4)]

static func trials_board_id(window: int, tier: int, group: String) -> String:
	var root := "trials_beta" if BETA else "trials"
	return "%s_%s_%s_%s" % [root, WINDOW_IDS.get(window, "daily"), scale_id(tier), group]

static func window_date(window: int) -> String:
	var d := Time.get_date_dict_from_system()
	match window:
		MapResourceScript.WindowType.WEEKLY:
			var week := int(Time.get_unix_time_from_system() / float(WEEK_SECONDS))
			return "%04d-W%03d" % [d.year, week % 1000]
		MapResourceScript.WindowType.MONTHLY:
			return "%04d-%02d" % [d.year, d.month]
		_:
			return "%04d-%02d-%02d" % [d.year, d.month, d.day]

static func window_word(window: int) -> String:
	match window:
		MapResourceScript.WindowType.WEEKLY: return "this week"
		MapResourceScript.WindowType.MONTHLY: return "this month"
		_: return "today"

static func window_reset_text(window: int) -> String:
	var now := int(Time.get_unix_time_from_system())
	var target := now
	match window:
		MapResourceScript.WindowType.WEEKLY:
			target = ((now - _MONDAY_EPOCH) / WEEK_SECONDS + 1) * WEEK_SECONDS + _MONDAY_EPOCH
		MapResourceScript.WindowType.MONTHLY:
			var u := Time.get_datetime_dict_from_unix_time(now)
			var ny: int = u.year + (1 if u.month == 12 else 0)
			var nm: int = 1 if u.month == 12 else u.month + 1
			target = int(Time.get_unix_time_from_datetime_dict({
				"year": ny, "month": nm, "day": 1, "hour": 0, "minute": 0, "second": 0}))
		_:
			target = (now / 86400 + 1) * 86400
	return "resets in " + _dur(maxi(0, target - now))

static func _dur(secs: int) -> String:
	var days := secs / 86400
	var hours := (secs % 86400) / 3600
	var mins := (secs % 3600) / 60
	if days > 0:
		return "%dd %dh" % [days, hours]
	if hours > 0:
		return "%dh %dm" % [hours, mins]
	return "%dm" % mins

static func ranked_tier(value: int) -> Dictionary:
	for band in RANKED_BANDS:
		if value >= int(band["base"]):
			return {"name": band["name"], "tag": band["tag"], "lp": value - int(band["base"])}
	return {"name": "Stone", "tag": "stn", "lp": 0}

static func trials_board(window: int, tier: int, group: String) -> Dictionary:
	var bid := trials_board_id(window, tier, group)
	var my_score := SaveData.best_pve_score(window_date(window), tier) if group == "solo" else 0
	var res: Dictionary = await backend().fetch_trials(bid, my_score)
	res["id"] = bid
	res["reset_text"] = window_reset_text(window)
	res["my_score"] = my_score
	return res

static func trials_placement(window: int, tier: int, group: String, my_score: int) -> Dictionary:
	var bid := trials_board_id(window, tier, group)
	var res: Dictionary = await backend().fetch_trials_neighborhood(bid, my_score, 2)
	res["window_word"] = window_word(window)
	res["context"] = "%s · %s · %s" % [
		WINDOW_IDS.get(window, "daily").to_upper(), scale_name(tier).to_upper(), group.to_upper()]
	return res

static func trials_rank(window: int, tier: int, group: String = "solo") -> Dictionary:
	var my_score := SaveData.best_pve_score(window_date(window), tier)
	if my_score <= 0:
		return {"best": 0, "rank": 0}
	var res: Dictionary = await backend().fetch_trials_rank(trials_board_id(window, tier, group), my_score)
	return {"best": my_score, "rank": int(res.get("rank", 0))}

static func ranked_ladder(season: int) -> Dictionary:
	return await backend().fetch_ranked(season)

static func campaign_board(mission: int) -> Dictionary:
	return await backend().fetch_campaign(mission)

static func trials_seeds() -> Dictionary:
	return await backend().fetch_trials_seeds()

class LeaderboardBackend extends RefCounted:
	func fetch_trials(_board_id: String, _my_score: int) -> Dictionary:
		return {"entries": [], "my_rank": 0}
	func fetch_trials_neighborhood(_board_id: String, _my_score: int, _radius: int) -> Dictionary:
		return {"rank": 0, "rows": []}
	func fetch_trials_rank(_board_id: String, _my_score: int) -> Dictionary:
		return {"rank": 0}
	func fetch_ranked(season: int) -> Dictionary:
		return {"season_label": "Season %d · live" % season, "reset_text": "", "seasons": ["Season %d" % season], "you": null, "bands": []}
	func fetch_campaign(_mission: int) -> Dictionary:
		return {"entries": [], "my_score": 0}
	func fetch_trials_seeds() -> Dictionary:
		return {}

class LocalBackend extends LeaderboardBackend:
	func fetch_trials(_board_id: String, my_score: int) -> Dictionary:
		if my_score <= 0:
			return {"entries": [], "my_rank": 0}
		return {"entries": [{"rank": 1, "name": "you", "score": my_score, "is_me": true}], "my_rank": 1}

	func fetch_trials_neighborhood(_board_id: String, my_score: int, _radius: int) -> Dictionary:
		if my_score <= 0:
			return {"rank": 0, "rows": []}
		return {"rank": 1, "rows": [{"rank": 1, "name": "you", "score": my_score, "is_me": true}]}

	func fetch_trials_rank(_board_id: String, _my_score: int) -> Dictionary:
		return {"rank": 1}

	func fetch_ranked(season: int) -> Dictionary:
		return {"season_label": "Season %d · live" % season, "reset_text": "", "seasons": ["Season %d" % season], "you": null, "bands": []}

	func fetch_campaign(_mission: int) -> Dictionary:
		return {"entries": [], "my_score": 0}
