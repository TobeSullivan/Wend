extends Node

const RAIL_W := 280.0
const BOARD_MARGIN := 12.0
const PLAY_MARGIN := 1.0
const MINIMAP_W := 300.0

static var _scale_override: float = 0.0

static func set_scale_override(v: float) -> void:
	_scale_override = v

static func scale_factor() -> float:
	if _scale_override > 0.0:
		return _scale_override
	return 2.0 if DisplayServer.is_touchscreen_available() else 1.0

static func rail_w() -> float:
	return RAIL_W * scale_factor()

static func board_margin() -> float:
	return BOARD_MARGIN * scale_factor()

static func minimap_w() -> float:
	return MINIMAP_W * scale_factor()

static func play_rect(_is_pvp: bool, vp: Vector2) -> Rect2:
	var m := board_margin()
	var w := vp.x - rail_w() - 2.0 * m
	var h := vp.y - 2.0 * m
	return Rect2(m, m, maxf(w, 120.0), maxf(h, 120.0))

static func rail_region(vp: Vector2) -> Rect2:
	return Rect2(vp.x - rail_w(), 0.0, rail_w(), vp.y)

static func minimap_region(vp: Vector2) -> Rect2:
	var m := board_margin()
	return Rect2(0.0, m, minimap_w(), vp.y - 2.0 * m)
