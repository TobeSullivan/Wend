extends Node
class_name CosmeticsCatalog

const SLOTS := [
	{"id": "tower", "name": "Tower", "group": "match"},
	{"id": "board", "name": "Board", "group": "match"},
	{"id": "zone", "name": "Zone", "group": "match"},
	{"id": "proj", "name": "Projectile", "group": "match"},
	{"id": "mob", "name": "Mob", "group": "match"},
	{"id": "sticker", "name": "Sticker", "group": "match"},
	{"id": "frame", "name": "Frame", "group": "pro"},
	{"id": "banner", "name": "Banner", "group": "pro"},
	{"id": "title", "name": "Title", "group": "pro"},
]

const RARITY_LABEL := {"common": "common", "rare": "rare", "prestige": "prestige"}

const ITEMS := [
	{"id": "tower_arrow", "slot": "tower", "name": "Arrow Box", "rarity": "common",
		"art": "res://assets/towers/arrow_box_loaded.png", "default_owned": true},
	{"id": "board_summer", "slot": "board", "name": "Summer", "rarity": "common",
		"art": "res://assets/maps/summer_grass_tile.png", "default_owned": true},
	{"id": "zone_classic", "slot": "zone", "name": "Classic", "rarity": "common",
		"tint": Color("7a5a8a"), "default_owned": true},
	{"id": "proj_arrow", "slot": "proj", "name": "Arrow", "rarity": "common",
		"art": "res://assets/towers/arrow.png", "default_owned": true},
	{"id": "mob_undead", "slot": "mob", "name": "Undead", "rarity": "common",
		"art": "res://assets/mobs/__zombie_01_walk_2_000.png", "default_owned": true},
	{"id": "frame_none", "slot": "frame", "name": "None", "rarity": "common",
		"tint": Color("23170d"), "default_owned": true},
	{"id": "banner_olive", "slot": "banner", "name": "Olive", "rarity": "common",
		"tint": Color("323d2c"), "default_owned": true},

	{"id": "title_recruit", "slot": "title", "name": "Recruit", "rarity": "common", "hint": "Season 1 · Tier 1"},
	{"id": "mob_green", "slot": "mob", "name": "Green recolor", "rarity": "common", "tint": Color("5fbe38"), "hint": "Season 1 · Tier 2"},
	{"id": "zone_teal", "slot": "zone", "name": "Teal", "rarity": "common", "tint": Color("2fa7a0"), "hint": "Season 1 · Tier 3"},
	{"id": "fx_gold_bolt", "slot": "proj", "name": "Gold projectile", "rarity": "common", "tint": Color("d8af46"), "hint": "Season 1 · Tier 4"},
	{"id": "frame_wood", "slot": "frame", "name": "Wood frame", "rarity": "rare", "tint": Color("8a6a3a"), "hint": "Season 1 · Tier 5"},
	{"id": "mob_fish", "slot": "mob", "name": "Fish", "rarity": "rare", "hint": "Season 1 · Tier 6"},
	{"id": "title_pathfinder", "slot": "title", "name": "Pathfinder", "rarity": "common", "hint": "Season 1 · Tier 7"},
	{"id": "board_forest", "slot": "board", "name": "Forest", "rarity": "rare",
		"art": "res://assets/maps/forest_tile.png", "hint": "Season 1 · Tier 8"},
	{"id": "fx_blue_impact", "slot": "proj", "name": "Blue impact", "rarity": "common", "tint": Color("4a9fdf"), "hint": "Season 1 · Tier 9"},
	{"id": "tower_fire_crystal", "slot": "tower", "name": "Fire Crystal", "rarity": "rare",
		"art": "res://assets/towers/skins/fire_crystal.png", "hint": "Season 1 · Tier 10"},
	{"id": "fx_fireball", "slot": "proj", "name": "Fireball", "rarity": "rare", "tint": Color("d96a2a"), "hint": "Season 1 · Tier 10"},
	{"id": "mob_purple", "slot": "mob", "name": "Purple recolor", "rarity": "common", "tint": Color("8a5bbf"), "hint": "Season 1 · Tier 11"},
	{"id": "zone_magenta", "slot": "zone", "name": "Magenta", "rarity": "common", "tint": Color("b04a9a"), "hint": "Season 1 · Tier 12"},
	{"id": "title_maze_runner", "slot": "title", "name": "Maze Runner", "rarity": "common", "hint": "Season 1 · Tier 13"},
	{"id": "fx_arcane_bolt", "slot": "proj", "name": "Arcane bolt", "rarity": "rare", "tint": Color("5fd0ff"), "hint": "Season 1 · Tier 14"},
	{"id": "banner_mint_choco", "slot": "banner", "name": "Mint Choco", "rarity": "rare", "tint": Color("2a4a3a"), "hint": "Season 1 · Tier 15"},
	{"id": "mob_starfish", "slot": "mob", "name": "Starfish", "rarity": "rare", "hint": "Season 1 · Tier 16"},
	{"id": "board_beach", "slot": "board", "name": "Beach", "rarity": "rare", "hint": "Season 1 · Tier 17"},
	{"id": "fx_smoke_ring", "slot": "proj", "name": "Smoke ring", "rarity": "rare", "tint": Color("9a9282"), "hint": "Season 1 · Tier 18"},
	{"id": "title_overclocked", "slot": "title", "name": "Overclocked", "rarity": "common", "hint": "Season 1 · Tier 19"},
	{"id": "tower_ice_crystal", "slot": "tower", "name": "Ice Crystal", "rarity": "rare",
		"art": "res://assets/towers/skins/ice_crystal.png", "hint": "Season 1 · Tier 20"},
	{"id": "fx_ice_spell", "slot": "proj", "name": "Ice spell", "rarity": "rare", "tint": Color("7fd0ff"), "hint": "Season 1 · Tier 20"},
	{"id": "mob_cyan", "slot": "mob", "name": "Cyan recolor", "rarity": "common", "tint": Color("4ac0c0"), "hint": "Season 1 · Tier 21"},
	{"id": "zone_amber", "slot": "zone", "name": "Amber", "rarity": "common", "tint": Color("d79a52"), "hint": "Season 1 · Tier 22"},
	{"id": "frame_parchment", "slot": "frame", "name": "Parchment", "rarity": "rare", "tint": Color("d8c89a"), "hint": "Season 1 · Tier 23"},
	{"id": "fx_lightning", "slot": "proj", "name": "Lightning", "rarity": "rare", "tint": Color("ffe98a"), "hint": "Season 1 · Tier 24"},
	{"id": "title_gauntlet_vet", "slot": "title", "name": "Gauntlet Veteran", "rarity": "common", "hint": "Season 1 · Tier 25"},
	{"id": "board_suburbia", "slot": "board", "name": "Suburbia", "rarity": "rare",
		"art": "res://assets/maps/suburbia_tile.png", "hint": "Season 1 · Tier 26"},
	{"id": "mob_hammerhead", "slot": "mob", "name": "Hammerhead", "rarity": "rare", "hint": "Season 1 · Tier 27"},
	{"id": "sticker_speech", "slot": "sticker", "name": "Speech bubble", "rarity": "rare", "tint": Color("b9c7a4"), "hint": "Season 1 · Tier 28"},
	{"id": "fx_explosion", "slot": "proj", "name": "Explosion recolor", "rarity": "common", "tint": Color("b04a2a"), "hint": "Season 1 · Tier 29"},
	{"id": "tower_dark_crystal", "slot": "tower", "name": "Dark Crystal", "rarity": "rare",
		"art": "res://assets/towers/skins/dark_crystal.png", "hint": "Season 1 · Tier 30"},
	{"id": "fx_dark", "slot": "proj", "name": "Dark spell", "rarity": "rare", "tint": Color("6a3a8a"), "hint": "Season 1 · Tier 30"},

	{"id": "title_stone", "slot": "title", "name": "Stone", "rarity": "prestige", "hint": "Ranked · Stone placement"},
	{"id": "title_bronze", "slot": "title", "name": "Bronze", "rarity": "prestige", "hint": "Ranked · Bronze placement"},
	{"id": "title_silver", "slot": "title", "name": "Silver", "rarity": "prestige", "hint": "Ranked · Silver placement"},
	{"id": "title_gold", "slot": "title", "name": "Gold", "rarity": "prestige", "hint": "Ranked · Gold placement"},
	{"id": "title_masters", "slot": "title", "name": "Masters", "rarity": "prestige", "hint": "Ranked · Masters placement"},
	{"id": "frame_stone", "slot": "frame", "name": "Stone frame", "rarity": "prestige", "tint": Color("9099a0"), "hint": "Ranked · Stone placement"},
	{"id": "frame_bronze", "slot": "frame", "name": "Bronze frame", "rarity": "prestige", "tint": Color("d79a52"), "hint": "Ranked · Bronze placement"},
	{"id": "frame_silver", "slot": "frame", "name": "Silver frame", "rarity": "prestige", "tint": Color("c0c8d0"), "hint": "Ranked · Silver placement"},
	{"id": "frame_gold", "slot": "frame", "name": "Gold frame", "rarity": "prestige", "tint": Color("b38e2c"), "hint": "Ranked · Gold placement"},
	{"id": "frame_masters", "slot": "frame", "name": "Masters frame", "rarity": "prestige", "tint": Color("e0c060"), "hint": "Ranked · Masters placement"},
	{"id": "sticker_rect_s1", "slot": "sticker", "name": "Rectangle (S1)", "rarity": "prestige", "tint": Color("b38e2c"), "hint": "Ranked · season placement"},
]

const SEASON := 1
const TIER_COUNT := 30
const POINTS_PER_TIER := 1000
const MILESTONES := [10, 20, 30]

const TRACK := [
	{"tier": 1, "items": ["title_recruit"]},
	{"tier": 2, "items": ["mob_green"]},
	{"tier": 3, "items": ["zone_teal"]},
	{"tier": 4, "items": ["fx_gold_bolt"]},
	{"tier": 5, "items": ["frame_wood"]},
	{"tier": 6, "items": ["mob_fish"]},
	{"tier": 7, "items": ["title_pathfinder"]},
	{"tier": 8, "items": ["board_forest"]},
	{"tier": 9, "items": ["fx_blue_impact"]},
	{"tier": 10, "items": ["tower_fire_crystal", "fx_fireball"]},
	{"tier": 11, "items": ["mob_purple"]},
	{"tier": 12, "items": ["zone_magenta"]},
	{"tier": 13, "items": ["title_maze_runner"]},
	{"tier": 14, "items": ["fx_arcane_bolt"]},
	{"tier": 15, "items": ["banner_mint_choco"]},
	{"tier": 16, "items": ["mob_starfish"]},
	{"tier": 17, "items": ["board_beach"]},
	{"tier": 18, "items": ["fx_smoke_ring"]},
	{"tier": 19, "items": ["title_overclocked"]},
	{"tier": 20, "items": ["tower_ice_crystal", "fx_ice_spell"]},
	{"tier": 21, "items": ["mob_cyan"]},
	{"tier": 22, "items": ["zone_amber"]},
	{"tier": 23, "items": ["frame_parchment"]},
	{"tier": 24, "items": ["fx_lightning"]},
	{"tier": 25, "items": ["title_gauntlet_vet"]},
	{"tier": 26, "items": ["board_suburbia"]},
	{"tier": 27, "items": ["mob_hammerhead"]},
	{"tier": 28, "items": ["sticker_speech"]},
	{"tier": 29, "items": ["fx_explosion"]},
	{"tier": 30, "items": ["tower_dark_crystal", "fx_dark"]},
]

const AURA_WARM := [
	{"inner": Color("fff0b8"), "mid": Color("f5c542")},
	{"inner": Color("ffc488"), "mid": Color("f0832e")},
	{"inner": Color("ffae7a"), "mid": Color("ff2f24")},
]
const AURA_COOL := [
	{"inner": Color("a6f5d8"), "mid": Color("21c08c")},
	{"inner": Color("b3c6ff"), "mid": Color("4f7bff")},
	{"inner": Color("ecbcff"), "mid": Color("c44eff")},
]
const AURA_BOARD_RAMP := {
	"board_suburbia": "warm",
	"board_summer": "cool",
	"board_forest": "cool",
}

static func aura_ramp_for(board_id: String) -> Array:
	var key := String(AURA_BOARD_RAMP.get(board_id, "cool"))
	return AURA_WARM if key == "warm" else AURA_COOL

static func aura_sample(ramp: Array, p: float) -> Dictionary:
	if ramp.is_empty():
		return {"inner": Color.WHITE, "mid": Color.WHITE}
	if ramp.size() == 1:
		return ramp[0]
	var seg := clampf(p, 0.0, 1.0) * float(ramp.size() - 1)
	var i := clampi(int(floor(seg)), 0, ramp.size() - 2)
	var f := seg - float(i)
	var a: Dictionary = ramp[i]
	var b: Dictionary = ramp[i + 1]
	return {
		"inner": Color(a["inner"]).lerp(b["inner"], f),
		"mid": Color(a["mid"]).lerp(b["mid"], f),
	}

static func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it["id"] == id:
			return it
	return {}

static func texture_for(id: String, fallback_path: String) -> Texture2D:
	var art := String(item(id).get("art", ""))
	if art != "" and ResourceLoader.exists(art):
		return load(art)
	return load(fallback_path)

static func tint_for(id: String, default_color: Color) -> Color:
	return item(id).get("tint", default_color)

static func slot_items(slot: String) -> Array:
	var out: Array = []
	for it in ITEMS:
		if it["slot"] == slot:
			out.append(it)
	return out

static func slot_name(slot: String) -> String:
	for s in SLOTS:
		if s["id"] == slot:
			return s["name"]
	return slot

static func default_equipped() -> Dictionary:
	var out := {}
	for it in ITEMS:
		if it.get("default_owned", false) and not out.has(it["slot"]):
			out[it["slot"]] = it["id"]
	return out

static func is_owned(id: String, owned: Array) -> bool:
	var it := item(id)
	return not it.is_empty() and (it.get("default_owned", false) or owned.has(id))

static func slot_completion(slot: String, owned: Array) -> Vector2i:
	var have := 0
	var items := slot_items(slot)
	for it in items:
		if is_owned(it["id"], owned):
			have += 1
	return Vector2i(have, items.size())

static func overall_completion(owned: Array) -> float:
	var have := 0
	for it in ITEMS:
		if is_owned(it["id"], owned):
			have += 1
	return float(have) / float(ITEMS.size()) if ITEMS.size() > 0 else 0.0

static func unlocked_tier(points: int) -> int:
	return clampi(points / POINTS_PER_TIER, 0, TIER_COUNT)

static func tier_state(tier: int, points: int, claimed: Array) -> String:
	if claimed.has(tier):
		return "claimed"
	var unlocked := unlocked_tier(points)
	if tier <= unlocked:
		return "claimable"
	if tier == unlocked + 1:
		return "current"
	return "locked"

static func tier_items(tier: int) -> Array:
	for t in TRACK:
		if t["tier"] == tier:
			return t["items"]
	return []

static func next_reward_tier(_points: int, claimed: Array) -> int:
	for t in TRACK:
		if not claimed.has(t["tier"]):
			return t["tier"]
	return 0
