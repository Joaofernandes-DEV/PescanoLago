class_name UiTheme
extends RefCounted
## Tema da interface (Fase 5): painéis arredondados e semitransparentes em
## azul-marinho da paleta do guia de estilo, textos claros com contorno e botões
## com o laranja do colete do Tom. Usado no HUD do dia e em Porto Manso.

const PANEL: Color = Color(0.118, 0.165, 0.31, 0.78)
const PANEL_BORDER: Color = Color(0.97, 0.95, 0.91, 0.25)
const TEXT: Color = Color(0.97, 0.95, 0.91)
const ACCENT: Color = Color(0.949, 0.549, 0.157)
const ACCENT_HOVER: Color = Color(1.0, 0.65, 0.3)
const DISABLED: Color = Color(0.4, 0.42, 0.48, 0.8)
const STAR_ON: Color = Color(1.0, 1.0, 1.0)
const STAR_OFF: Color = Color(0.3, 0.32, 0.38, 0.9)


static func panel_box(radius: int = 14) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = PANEL_BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func _button_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(10)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


static func build() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("panel", "PanelContainer", panel_box())
	theme.set_stylebox("panel", "TabContainer", panel_box(10))
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", Color(0.05, 0.07, 0.12))
	theme.set_constant("outline_size", "Label", 4)
	theme.set_stylebox("normal", "Button", _button_box(ACCENT))
	theme.set_stylebox("hover", "Button", _button_box(ACCENT_HOVER))
	theme.set_stylebox("pressed", "Button", _button_box(ACCENT.darkened(0.2)))
	theme.set_stylebox("disabled", "Button", _button_box(DISABLED))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", Color(0.1, 0.08, 0.06))
	theme.set_color("font_hover_color", "Button", Color(0.1, 0.08, 0.06))
	theme.set_color("font_pressed_color", "Button", Color(0.1, 0.08, 0.06))
	theme.set_color("font_disabled_color", "Button", Color(0.85, 0.85, 0.88))
	theme.set_font_size("font_size", "Button", 18)
	# Caixas de marcar (configurações): texto claro sobre o painel, sem o fundo
	# laranja dos botões.
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		theme.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		theme.set_color(color_name, "CheckBox", TEXT)
	theme.set_color("font_hover_pressed_color", "CheckBox", TEXT)
	theme.set_font_size("font_size", "CheckBox", 17)
	return theme
