extends Control

# Campaign mission list (DESIGN_MODES "Navigation from Campaign"): missions 1–10,
# all unlocked from the start, each showing the player's best medal. Click a
# mission to drop straight in. Only authored missions are playable; the rest show
# as "Coming soon" (campaign content is intentionally minimal).

const BG_COLOR := Color(0.07, 0.09, 0.13)
const MEDAL_COLORS := {
	"gold":   Color(1.0, 0.85, 0.2),
	"silver": Color(0.85, 0.85, 0.9),
	"bronze": Color(0.85, 0.55, 0.25),
	"none":   Color(0.45, 0.5, 0.6),
}
const MEDAL_GLYPH := {"gold": "●", "silver": "●", "bronze": "●", "none": "○"}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_header()
	_build_grid()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

func _build_header() -> void:
	var title := _label("Campaign", 36, Color.WHITE)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_left = 40
	title.offset_top = 28
	add_child(title)

	var subtitle := _label("A short tutorial. All missions unlocked.", 16, Color(0.6, 0.65, 0.75))
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_left = 40
	subtitle.offset_top = 74
	add_child(subtitle)

	var back := Button.new()
	back.text = "← Back"
	back.add_theme_font_size_override("font_size", 16)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back.offset_left = -150
	back.offset_top = 28
	back.offset_right = -40
	back.offset_bottom = 68
	back.pressed.connect(func(): SceneManager.goto_home())
	add_child(back)

func _build_grid() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	center.add_child(grid)

	for i in range(1, SceneManager.CAMPAIGN_MISSION_COUNT + 1):
		grid.add_child(_mission_card(i))

func _mission_card(index: int) -> Control:
	var authored: bool = SceneManager.has_campaign_mission(index)

	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 10)

	var button := Button.new()
	button.custom_minimum_size = Vector2(260, 56)
	button.add_theme_font_size_override("font_size", 18)
	if authored:
		var medal: String = SaveData.best_medal(index)
		button.text = "Mission %d" % index
		button.pressed.connect(func(): SceneManager.start_campaign_mission(index))
		var medal_label := _label(MEDAL_GLYPH[medal], 22, MEDAL_COLORS[medal])
		card.add_child(button)
		card.add_child(medal_label)
	else:
		button.text = "Mission %d — Coming soon" % index
		button.disabled = true
		card.add_child(button)
	return card

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
