extends Node

# Single source of truth for the in-match UI frame. The board no longer fills the
# screen — it's fit (by game_view's camera) into a play rect bounded by reserved UI
# zones. As of the BTD6-style rework the frame is: a top status bar and a bottom
# action strip; the right rail is gone (one tower type + tap-to-build made it dead
# space), so the board spans the FULL width. The tower-detail drawer (right edge) and
# the PVP arena minimap (left edge) FLOAT OVER the board on demand — they are not
# reserved zones, so the board stays full-width whether or not they're open.
#
# The camera, the bars, the drawer/minimap, and build_controller's click gate all
# read these statics so they can never disagree. Consumers preload this script and
# call the statics (no class_name, to stay clear of the class-name cycle pitfall).

# NOTE: these must be ≥ the actual rendered chrome height (content + the wood
# nine-patch's texture_margin min-size), or the panels overflow onto the board. The
# top_edge/horizontal_strip nine-patch margins in ui_style.gd are kept small enough
# that the panels render at exactly these heights (verified via the --uidebug overlay).
const TOP_BAR_H := 70.0
const BOTTOM_STRIP_H := 96.0   # finger-friendly action plank (round buttons + padding)
# Drawer + minimap float over the board (NOT reserved) so the board keeps full width.
const DRAWER_W := 360.0        # tower-detail drawer, slides in from the right edge
const MINIMAP_W := 300.0       # PVP arena minimap, slides in from the left edge
# Board fills the play rect (1.0). The generated board is wider-aspect than the rect,
# so it's width-limited and a small dark letterbox remains top/bottom — inherent.
const PLAY_MARGIN := 1.0
# Kept for the minimap tile-grid internal sizing; no longer a reserved screen zone.
const ARENA_H := 432.0

# High-DPI phones make the 1080p-designed UI illegible at 1x, so scale the whole UI
# (fonts, bars, buttons) AND the in-match board zoom (see game_view) up on touch.
# Desktop stays 1x. The base consts above are the 1x (desktop) values.
# _scale_override lets the capture harness force a scale (e.g. eyeball the 2x touch
# layout on a desktop with no touchscreen); 0 = use the real DisplayServer.
static var _scale_override: float = 0.0

static func set_scale_override(v: float) -> void:
	_scale_override = v

static func scale_factor() -> float:
	if _scale_override > 0.0:
		return _scale_override
	return 2.0 if DisplayServer.is_touchscreen_available() else 1.0

static func top_bar_h() -> float:
	return TOP_BAR_H * scale_factor()

static func bottom_strip_h() -> float:
	return BOTTOM_STRIP_H * scale_factor()

static func drawer_w() -> float:
	return DRAWER_W * scale_factor()

static func minimap_w() -> float:
	return MINIMAP_W * scale_factor()

static func arena_h() -> float:
	return ARENA_H * scale_factor()

# The battlefield is FULL-BLEED (mockup): grass + road + towers fill the whole screen;
# the HUD pills, tower dock, and control clusters float ON TOP in the corners and
# reserve nothing. So the board fits the entire viewport.
static func play_rect(_is_pvp: bool, vp: Vector2) -> Rect2:
	return Rect2(0.0, 0.0, vp.x, vp.y)

# Right-edge band the tower-detail drawer docks into (floats over the board).
static func drawer_region(vp: Vector2) -> Rect2:
	return Rect2(vp.x - drawer_w(), top_bar_h(), drawer_w(), vp.y - top_bar_h() - bottom_strip_h())

# Left-edge band the PVP arena minimap docks into (floats over the board).
static func minimap_region(vp: Vector2) -> Rect2:
	return Rect2(0.0, top_bar_h(), minimap_w(), vp.y - top_bar_h() - bottom_strip_h())
