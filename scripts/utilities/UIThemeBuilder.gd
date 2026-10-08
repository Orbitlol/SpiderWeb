extends RefCounted
class_name UIThemeBuilder

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 22

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.08, 0.88)
	panel.border_color = Color(0.85, 0.18, 0.22, 0.95)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(14)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	theme.set_stylebox("panel", "PanelContainer", panel)

	var normal := _button_box(Color(0.1, 0.12, 0.16, 0.94), Color(0.85, 0.22, 0.26, 0.9))
	var hover := _button_box(Color(0.18, 0.12, 0.14, 0.98), Color(1.0, 0.35, 0.38, 1.0))
	var pressed := _button_box(Color(0.55, 0.1, 0.14, 0.98), Color(1.0, 0.55, 0.5, 1.0))
	var disabled := _button_box(Color(0.08, 0.08, 0.09, 0.7), Color(0.3, 0.3, 0.32, 0.6))
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", hover)
	theme.set_color("font_color", "Button", Color(0.96, 0.96, 0.97))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(0.55, 0.55, 0.58))
	theme.set_font_size("font_size", "Button", 22)

	theme.set_color("font_color", "Label", Color(0.94, 0.95, 0.97))
	theme.set_font_size("font_size", "Label", 20)

	var slider := StyleBoxFlat.new()
	slider.bg_color = Color(0.15, 0.16, 0.2, 1)
	slider.set_corner_radius_all(6)
	slider.content_margin_top = 8
	slider.content_margin_bottom = 8
	theme.set_stylebox("slider", "HSlider", slider)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.9, 0.22, 0.26, 1)
	grabber.set_corner_radius_all(8)
	grabber.content_margin_left = 10
	grabber.content_margin_right = 10
	theme.set_stylebox("grabber_area", "HSlider", grabber)
	theme.set_stylebox("grabber_area_highlight", "HSlider", grabber)

	return theme


static func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(12)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box
