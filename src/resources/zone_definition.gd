extends Resource
class_name ZoneDefinition

enum Type { DAMAGE, ATTACK_SPEED, RANGE, SLOW }

const TYPE_NAMES := ["damage", "attack_speed", "range", "slow"]

@export var type: Type = Type.DAMAGE
@export var cell: Vector2i = Vector2i.ZERO
@export var magnitude: int = 10

func type_name() -> String:
	return TYPE_NAMES[type]
