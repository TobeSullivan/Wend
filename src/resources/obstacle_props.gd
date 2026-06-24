extends RefCounted
class_name ObstacleProps

const P  := "res://assets/environment/props/"
const R  := "res://assets/environment/building_ruins/"
const SB := "res://assets/environment/suburbia/"

const PROPS := {
	"dead_tree_01":     {"tex": preload(P + "dead_tree_01.png"),     "footprint": Vector2i(1, 1), "overhang": 1.05, "weight": 8},
	"dead_tree_02":     {"tex": preload(P + "dead_tree_02.png"),     "footprint": Vector2i(1, 1), "overhang": 1.05, "weight": 8},
	"oil_drum_fallen":  {"tex": preload(P + "oil_drum_fallen.png"),  "footprint": Vector2i(1, 1), "overhang": 1.0,  "weight": 8},
	"oil_drum_top":     {"tex": preload(P + "oil_drum_top.png"),     "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 6},
	"hydrant":          {"tex": preload(P + "hydrant.png"),          "footprint": Vector2i(1, 1), "overhang": 0.85, "weight": 6},
	"tire_01":          {"tex": preload(P + "tire_01.png"),          "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 5},
	"tire_02":          {"tex": preload(P + "tire_02.png"),          "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 5},
	"tire_03":          {"tex": preload(P + "tire_03.png"),          "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 5},
	"trash_can":        {"tex": preload(P + "trash_can.png"),        "footprint": Vector2i(1, 1), "overhang": 0.95, "weight": 6},
	"trash_can_fallen": {"tex": preload(P + "trash_can_fallen.png"), "footprint": Vector2i(1, 1), "overhang": 0.95, "weight": 5},
	"wheelie_bin":      {"tex": preload(P + "wheelie_bin.png"),      "footprint": Vector2i(1, 1), "overhang": 1.0,  "weight": 6},
	"rubble_pile_01":   {"tex": preload(P + "rubble_pile_01.png"),   "footprint": Vector2i(1, 1), "overhang": 1.1,  "weight": 7},
	"rubble_pile_02":   {"tex": preload(P + "rubble_pile_02.png"),   "footprint": Vector2i(1, 1), "overhang": 1.1,  "weight": 7},
	"rubble_pile_03":   {"tex": preload(P + "rubble_pile_03.png"),   "footprint": Vector2i(1, 1), "overhang": 1.1,  "weight": 6},
	"rubbish_01":       {"tex": preload(P + "rubbish_01.png"),       "footprint": Vector2i(1, 1), "overhang": 0.85, "weight": 4},
	"rubbish_02":       {"tex": preload(P + "rubbish_02.png"),       "footprint": Vector2i(1, 1), "overhang": 0.8,  "weight": 4},
	"rubbish_03":       {"tex": preload(P + "rubbish_03.png"),       "footprint": Vector2i(1, 1), "overhang": 0.8,  "weight": 4},

	"car_02":           {"tex": preload(P + "car_02.png"),           "footprint": Vector2i(1, 2), "overhang": 1.05, "weight": 4},
	"car_reck":         {"tex": preload(P + "car_reck.png"),         "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 3},
	"truck_on_side":    {"tex": preload(P + "truck_on_side.png"),    "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 2},

	"building_ruin_05": {"tex": preload(R + "building_ruin_05.png"), "footprint": Vector2i(1, 2), "overhang": 1.0,  "weight": 2},
	"building_ruin_11": {"tex": preload(R + "building_ruin_11.png"), "footprint": Vector2i(1, 4), "overhang": 1.0,  "weight": 2},
	"building_ruin_04": {"tex": preload(R + "building_ruin_04.png"), "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 1},
	"building_ruin_06": {"tex": preload(R + "building_ruin_06.png"), "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 1},
	"building_ruin_10": {"tex": preload(R + "building_ruin_10.png"), "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 1},
}

const SUBURBIA := {
	"sub_tree_01":   {"tex": preload(SB + "tree_01.png"),   "footprint": Vector2i(1, 1), "overhang": 1.1, "weight": 5},
	"sub_tree_02":   {"tex": preload(SB + "tree_02.png"),   "footprint": Vector2i(1, 1), "overhang": 1.1, "weight": 5},
	"sub_tree_03":   {"tex": preload(SB + "tree_03.png"),   "footprint": Vector2i(1, 1), "overhang": 1.1, "weight": 5},
	"sub_bush_01":   {"tex": preload(SB + "bush_01.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0, "weight": 8},
	"sub_bush_02":   {"tex": preload(SB + "bush_02.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0, "weight": 8},
	"sub_bush_03":   {"tex": preload(SB + "bush_03.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0, "weight": 8},
	"sub_bush_04":   {"tex": preload(SB + "bush_04.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0, "weight": 8},
	"sub_bush_05":   {"tex": preload(SB + "bush_05.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0, "weight": 7},
	"sub_bbq":          {"tex": preload(SB + "bbq.png"),                 "footprint": Vector2i(1, 1), "overhang": 0.95, "weight": 4},
	"sub_mailbox":      {"tex": preload(SB + "mail_box.png"),            "footprint": Vector2i(1, 1), "overhang": 0.85, "weight": 4},
	"sub_bird_house":   {"tex": preload(SB + "bird_house.png"),          "footprint": Vector2i(1, 1), "overhang": 0.85, "weight": 3},
	"sub_bin_black":    {"tex": preload(SB + "wheelie_bin_black.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0,  "weight": 4},
	"sub_bin_green":    {"tex": preload(SB + "wheelie_bin_green.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0,  "weight": 4},
	"sub_chair_blue":   {"tex": preload(SB + "garden_chair_blue.png"),   "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 3},
	"sub_chair_red":    {"tex": preload(SB + "garden_chair_red.png"),    "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 3},
	"sub_chair_yellow": {"tex": preload(SB + "garden_chair_yellow.png"), "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 3},
	"sub_pot_large":    {"tex": preload(SB + "plant_pot_large.png"),     "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 4},
	"sub_pot_small":    {"tex": preload(SB + "plant_pot_small.png"),     "footprint": Vector2i(1, 1), "overhang": 0.85, "weight": 4},
	"sub_slide":        {"tex": preload(SB + "slide.png"),               "footprint": Vector2i(1, 2), "overhang": 1.0,  "weight": 1},
	"sub_pond":         {"tex": preload(SB + "pond.png"),                "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 1},
}

const FALLBACK_ID := "rubble_pile_01"

static func _set_for(board_id: String) -> Dictionary:
	match board_id:
		"board_suburbia": return SUBURBIA
		_:                return PROPS

static func has_prop(prop_id: String) -> bool:
	return PROPS.has(prop_id) or SUBURBIA.has(prop_id)

static func _entry(prop_id: String) -> Dictionary:
	if PROPS.has(prop_id):
		return PROPS[prop_id]
	if SUBURBIA.has(prop_id):
		return SUBURBIA[prop_id]
	return PROPS[FALLBACK_ID]

static func tex_for(prop_id: String) -> Texture2D:
	return _entry(prop_id)["tex"]

static func footprint_for(prop_id: String) -> Vector2i:
	return _entry(prop_id)["footprint"]

static func overhang_for(prop_id: String) -> float:
	return _entry(prop_id)["overhang"]

static func pick_footprint(rng: RandomNumberGenerator, max_dim: int) -> Vector2i:
	if max_dim < 2:
		return Vector2i.ONE
	var roll := rng.randi_range(1, 100)
	if roll <= 70:
		return Vector2i(1, 1)
	if roll <= 90:
		return Vector2i(1, 2)
	if roll <= 95 and max_dim >= 4:
		return Vector2i(1, 4)
	return Vector2i(2, 2)

static func art_for(board_id: String, footprint: Vector2i, key: int) -> Dictionary:
	var id := _pick_in_pool(_set_for(board_id), footprint, key)
	if id == "":
		id = _pick_in_pool(PROPS, footprint, key)
	if id == "":
		id = FALLBACK_ID
	return _entry(id)

static func _pick_in_pool(pool: Dictionary, footprint: Vector2i, key: int) -> String:
	var eligible: Array = []
	var total := 0
	for id in pool:
		if pool[id]["footprint"] == footprint:
			var w: int = pool[id]["weight"]
			eligible.append([id, w])
			total += w
	if total <= 0:
		return ""
	var roll: int = (absi(key) % total) + 1
	for pair in eligible:
		roll -= pair[1]
		if roll <= 0:
			return pair[0]
	return eligible[-1][0]
