extends RefCounted
class_name RankedLadder


const BASE_LP_8 := [45.0, 30.0, 18.0, 8.0, -8.0, -18.0, -30.0, -45.0]

const MMR_K := 24.0
const MMR_SCALE := 400.0
const FACTOR_MIN := 0.5
const FACTOR_MAX := 1.5

const SEED_MMR := 150.0
const START_VALUE := 0

const MASTERS_BASE := 400
const DEMOTE_LANDING_LP := 75

static func resolve(placement: int, count: int, value_before: int, mmr_before: float, lobby_avg_mmr: float) -> Dictionary:
	var base := _base_lp(placement, count)
	var is_masters := value_before >= MASTERS_BASE

	var deficit := lobby_avg_mmr - mmr_before
	var factor: float
	if base >= 0.0:
		factor = clampf(1.0 + deficit / MMR_SCALE, FACTOR_MIN, FACTOR_MAX)
	else:
		factor = clampf(1.0 - deficit / MMR_SCALE, FACTOR_MIN, FACTOR_MAX)
	var earned := int(round(base * factor))

	if not is_masters:
		var half := int(ceil(count / 2.0))
		if placement <= half:
			earned = maxi(0, earned)
		else:
			earned = mini(0, earned)

	var raw := value_before + earned
	var cur := LeaderboardService.ranked_tier(value_before)
	var cur_base := value_before - int(cur["lp"])
	var value_after: int
	if is_masters:
		value_after = maxi(MASTERS_BASE, raw)
	elif raw < cur_base and cur_base > 0:
		value_after = maxi(0, cur_base - (100 - DEMOTE_LANDING_LP))
	else:
		value_after = maxi(0, raw)

	var expected := 1.0 / (1.0 + pow(10.0, (lobby_avg_mmr - mmr_before) / MMR_SCALE))
	var actual := 0.5 if count <= 1 else float(count - placement) / float(count - 1)
	var mmr_after := mmr_before + MMR_K * (actual - expected)

	var aft := LeaderboardService.ranked_tier(value_after)
	var bi_before := _band_index(value_before)
	var bi_after := _band_index(value_after)
	var nb := _next_band_above(value_after)
	return {
		"placement": placement, "count": count,
		"value_before": value_before, "value_after": value_after,
		"lp_delta": value_after - value_before,
		"earned": earned,
		"tier_before": String(cur["name"]), "tier_after": String(aft["name"]),
		"lp_before": int(cur["lp"]), "lp_after": int(aft["lp"]),
		"promoted": bi_after < bi_before,
		"demoted": bi_after > bi_before,
		"is_masters": value_after >= MASTERS_BASE,
		"to_next": int(nb["base"]) - value_after if not nb.is_empty() else 0,
		"next_tier": String(nb["name"]) if not nb.is_empty() else "",
		"mmr_before": mmr_before, "mmr_after": mmr_after,
	}

static func base_lp(placement: int, count: int) -> int:
	return int(round(_base_lp(placement, count)))

static func _base_lp(placement: int, count: int) -> float:
	var p := clampi(placement, 1, maxi(count, 1))
	if count >= 8:
		return BASE_LP_8[clampi(p - 1, 0, 7)]
	if count <= 1:
		return BASE_LP_8[0]
	var pos := float(p - 1) / float(count - 1) * 7.0
	var lo := int(floor(pos))
	var hi := mini(lo + 1, 7)
	return lerpf(BASE_LP_8[lo], BASE_LP_8[hi], pos - lo)

static func _band_index(value: int) -> int:
	for i in range(LeaderboardService.RANKED_BANDS.size()):
		if value >= int(LeaderboardService.RANKED_BANDS[i]["base"]):
			return i
	return LeaderboardService.RANKED_BANDS.size() - 1

static func _next_band_above(value: int) -> Dictionary:
	var best := {}
	for b in LeaderboardService.RANKED_BANDS:
		var base := int(b["base"])
		if base > value and (best.is_empty() or base < int(best["base"])):
			best = b
	return best
