extends Node

# Single source of truth for the in-match UI frame (rail layout, design/INMATCH_HUD.md).
# ONE reserved panel — the RIGHT RAIL — holds everything persistent (status / score-or-
# standing / buttons). The board MAXIMIZES into the remainder left of the rail, centered,
# with a uniform margin all round. The camera (game_view) fits the board into play_rect;
# the click gate (build_controller) reads the same rect, so UI never overlaps buildable
# tiles. Contextual UI (the tower info panel, the PVP leaderboard pop-out, spectate chrome)
# is NOT reserved — it floats over the board on demand.
#
# This replaces the older v3 bounded layout (top status bar + bottom action strip + a
# PERMANENT right inspector dock). Those three reserved zones are gone — the rail subsumes
# the persistent UI and the tower info is contextual.
#
# Consumers preload this script and call the statics (no class_name, to stay clear of the
# class-name cycle pitfall).

# Reserved right rail (holds the three boxes). 280 at the 1080p reference; scaled on touch.
const RAIL_W := 280.0
# Gap between the board and the surrounding chrome (left/top/bottom breathing + rail gap).
const BOARD_MARGIN := 12.0
# Board fills the play rect (1.0); margins are baked into play_rect itself.
const PLAY_MARGIN := 1.0
# PVP arena leaderboard floats over the board's LEFT edge (NOT reserved).
const MINIMAP_W := 300.0

# High-DPI phones make the 1080p-designed UI illegible at 1x, so scale the whole UI
# (fonts, rail, buttons) up on touch. Desktop stays 1x. The base consts above are the 1x
# (desktop) values. _scale_override lets the capture harness force a scale; 0 = real device.
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

# The board maximizes into the area LEFT of the rail, minus a uniform margin all round, then
# the camera centers the (fixed-count) board in it. _is_pvp is kept for call-signature
# stability and a possible future per-mode rail width; both modes currently share one rail.
static func play_rect(_is_pvp: bool, vp: Vector2) -> Rect2:
	var m := board_margin()
	var w := vp.x - rail_w() - 2.0 * m
	var h := vp.y - 2.0 * m
	return Rect2(m, m, maxf(w, 120.0), maxf(h, 120.0))

# The reserved right-rail rectangle (full viewport height). rail.gd lays the three boxes out
# inside this with its own internal padding.
static func rail_region(vp: Vector2) -> Rect2:
	return Rect2(vp.x - rail_w(), 0.0, rail_w(), vp.y)

# Left-edge band the PVP arena leaderboard floats into (NOT reserved). Aligned to the board's
# top/height (the same uniform margin), since there's no longer a top bar to hang under.
static func minimap_region(vp: Vector2) -> Rect2:
	var m := board_margin()
	return Rect2(0.0, m, minimap_w(), vp.y - 2.0 * m)
