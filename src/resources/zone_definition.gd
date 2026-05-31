extends Resource
class_name ZoneDefinition

# A single bonus zone on a map. Authored in campaign .tres files; produced by the
# generator for PVE/PVP. The runtime BonusZone node uses string types and a
# radius derived from magnitude — the loader translates this definition into that.

enum Type { DAMAGE, ATTACK_SPEED, RANGE, SLOW }

# Maps the Type enum to the string keys the runtime (BonusZone, Tower, Mob) uses.
# Order MUST match the Type enum.
const TYPE_NAMES := ["damage", "attack_speed", "range", "slow"]

@export var type: Type = Type.DAMAGE
@export var cell: Vector2i = Vector2i.ZERO  # center cell on the grid
@export var magnitude: int = 10             # 10..100, stepped in 10s

func type_name() -> String:
	return TYPE_NAMES[type]
