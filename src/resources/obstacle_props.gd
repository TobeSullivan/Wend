extends RefCounted
class_name ObstacleProps

# Curated registry of environmental props that can appear as map obstacles.
# Each entry maps a prop_id -> texture + footprint (cells it BLOCKS) + overhang
# (a small width fudge; the drawn sprite spills upward from the art's own aspect
# ratio, see obstacle.gd). ObstacleDefinition stores prop_id + origin + footprint;
# this registry supplies the texture/overhang the runtime needs to draw it.
#
# Curation follows design/INMATCH_FIXES.md §1: favour clean wrecks (cars, drums,
# trees, lamps); use big building ruins SPARINGLY (low weight) so boards don't get
# busy. Art is drawn in elevation, so most props block 1x1 at the base and overhang
# upward; cars/trucks/ruins are the genuine multi-cell blockers.

const P := "res://assets/environment/props/"
const R := "res://assets/environment/building_ruins/"

# weight: relative odds when the generator picks a prop (higher = more common).
const PROPS := {
	# --- 1x1 ground / small props (common) ---
	"dead_tree_01":     {"tex": preload(P + "dead_tree_01.png"),     "footprint": Vector2i(1, 1), "overhang": 1.05, "weight": 8},
	"dead_tree_02":     {"tex": preload(P + "dead_tree_02.png"),     "footprint": Vector2i(1, 1), "overhang": 1.05, "weight": 8},
	"oil_drum_fallen":  {"tex": preload(P + "oil_drum_fallen.png"),  "footprint": Vector2i(1, 1), "overhang": 1.0,  "weight": 8},
	"oil_drum_top":     {"tex": preload(P + "oil_drum_top.png"),     "footprint": Vector2i(1, 1), "overhang": 0.9,  "weight": 6},
	"street_lamp_01":   {"tex": preload(P + "street_lamp_01.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0,  "weight": 6},
	"street_lamp_02":   {"tex": preload(P + "street_lamp_02.png"),   "footprint": Vector2i(1, 1), "overhang": 1.0,  "weight": 6},
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

	# --- multi-cell wrecks (uncommon) ---
	"car_02":           {"tex": preload(P + "car_02.png"),           "footprint": Vector2i(1, 2), "overhang": 1.05, "weight": 4},
	"car_reck":         {"tex": preload(P + "car_reck.png"),         "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 3},
	"truck_on_side":    {"tex": preload(P + "truck_on_side.png"),    "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 2},

	# --- building ruins (rare; sparingly per spec) ---
	"building_ruin_05": {"tex": preload(R + "building_ruin_05.png"), "footprint": Vector2i(1, 2), "overhang": 1.0,  "weight": 2},
	"building_ruin_11": {"tex": preload(R + "building_ruin_11.png"), "footprint": Vector2i(1, 2), "overhang": 1.0,  "weight": 2},
	"building_ruin_04": {"tex": preload(R + "building_ruin_04.png"), "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 1},
	"building_ruin_06": {"tex": preload(R + "building_ruin_06.png"), "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 1},
	"building_ruin_10": {"tex": preload(R + "building_ruin_10.png"), "footprint": Vector2i(2, 2), "overhang": 1.0,  "weight": 1},
}

# Fallback for any unknown prop_id (e.g. a stale .tres) so the loader never crashes.
const FALLBACK_ID := "rubble_pile_01"

static func has_prop(prop_id: String) -> bool:
	return PROPS.has(prop_id)

static func _entry(prop_id: String) -> Dictionary:
	if PROPS.has(prop_id):
		return PROPS[prop_id]
	return PROPS[FALLBACK_ID]

static func tex_for(prop_id: String) -> Texture2D:
	return _entry(prop_id)["tex"]

static func footprint_for(prop_id: String) -> Vector2i:
	return _entry(prop_id)["footprint"]

static func overhang_for(prop_id: String) -> float:
	return _entry(prop_id)["overhang"]

# Weighted pick among props whose footprint fits within (max_w x max_h). Returns
# "" if nothing fits. Used by the generator: the weights bias heavily toward 1x1
# props, so multi-cell wrecks and ruins stay occasional even when space allows.
static func pick_for_footprint(rng: RandomNumberGenerator, max_w: int, max_h: int) -> String:
	var eligible: Array = []
	var total := 0
	for id in PROPS:
		var fp: Vector2i = PROPS[id]["footprint"]
		if fp.x <= max_w and fp.y <= max_h:
			var w: int = PROPS[id]["weight"]
			eligible.append([id, w])
			total += w
	if total <= 0:
		return ""
	var roll := rng.randi_range(1, total)
	for pair in eligible:
		roll -= pair[1]
		if roll <= 0:
			return pair[0]
	return eligible[-1][0]
