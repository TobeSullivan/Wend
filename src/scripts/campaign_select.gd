extends Control

# Campaign mission list (design/VISUAL_SYSTEM.md "Campaign select"): a row of 5 mission
# cards, all unlocked (the curve is guidance, not gating). Each card shows the mission
# number, its lesson label, and the player's star tier (0–3). Click to drop in.

const UiStyle := preload("res://scripts/ui_style.gd")
const StarRatingScript := preload("res://scripts/star_rating.gd")

# Real lesson content per mission (reinforces "this is the tutorial"). Index 1-based.
# The five-mission curriculum ramps from zero (design/CAMPAIGN.md).
const LESSONS := {
	1: "Intro", 2: "Checkpoints", 3: "Switchbacks", 4: "Zones", 5: "Real match",
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiStyle.menu_backdrop(self)
	_build_header()
	_build_grid()

func _build_header() -> void:
	var title := _label("Campaign", 38, Color.WHITE)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_left = 40
	title.offset_top = 28
	add_child(title)

	var subtitle := _label("A short tutorial. All missions unlocked.", 16, UiStyle.LABEL_COL)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_left = 40
	subtitle.offset_top = 76
	add_child(subtitle)

	var back := Button.new()
	back.text = "← Back"
	back.add_theme_font_size_override("font_size", 16)
	UiStyle.style_menu_button(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back.offset_left = -150
	back.offset_top = 28
	back.offset_right = -40
	back.offset_bottom = 70
	back.pressed.connect(func(): SceneManager.goto_home())
	add_child(back)

func _build_grid() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 40  # nudge below the header
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	center.add_child(grid)

	for i in range(1, SceneManager.CAMPAIGN_MISSION_COUNT + 1):
		grid.add_child(_mission_card(i))

func _mission_card(index: int) -> Control:
	var authored: bool = SceneManager.has_campaign_mission(index)

	var card := Button.new()
	card.custom_minimum_size = Vector2(196, 108)
	UiStyle.style_flat_button(card, UiStyle.PILL_BG, 18, UiStyle.PILL_BORDER, 2, true, 0, 0)
	card.disabled = not authored
	if authored:
		card.pressed.connect(func(): SceneManager.start_campaign_mission(index))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	vbox.add_child(_label("Mission %d" % index, 22, Color.WHITE))
	vbox.add_child(_label(LESSONS.get(index, ""), 15, UiStyle.LABEL_COL))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	if authored:
		var medal: String = SaveData.best_medal(index)
		var stars = StarRatingScript.new()
		stars.configure(StarRatingScript.filled_for_medal(medal), 3, 20.0)
		vbox.add_child(stars)
	else:
		vbox.add_child(_label("Coming soon", 13, Color(0.7, 0.72, 0.66, 0.7)))

	return card

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
