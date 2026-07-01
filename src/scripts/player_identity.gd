extends RefCounted
class_name PlayerIdentity

const UiStyle := preload("res://scripts/ui_style.gd")

static func chip(display_name: String, avatar: Texture2D = null, px: int = 30, font_size: int = 15, pass_mouse: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", maxi(6, int(px * 0.34)))
	if pass_mouse:
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(avatar_box(display_name, avatar, px))
	var nm := Label.new()
	nm.text = display_name
	nm.add_theme_font_size_override("font_size", font_size)
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if pass_mouse:
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(nm)
	return row

static func avatar_box(display_name: String, avatar: Texture2D, px: int) -> PanelContainer:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(px, px)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", UiStyle.flat_box(Color("222820"), int(px * 0.30), Color("161c0f"), 2, false))
	if avatar != null:
		var tex := TextureRect.new()
		tex.texture = avatar
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tex)
	else:
		var ini := Label.new()
		ini.text = display_name.substr(0, 1).to_upper() if display_name != "" else "?"
		ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ini.add_theme_font_size_override("font_size", int(px * 0.52))
		ini.add_theme_color_override("font_color", Color("dfe6cf"))
		ini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(ini)
	return box
