class_name DayHud
extends CanvasLayer
## HUD discreto no canto (GDD: tempo, meta, viveiro, combo), mensagens de ajuda,
## barra de força do lançamento, barra de tensão e tela de fim de dia.
## Provisório (greybox): texto em vez dos ícones do Blender, que entram na Fase 5.

signal continue_pressed

const STAR: String = "★"
const NO_STAR: String = "☆"

var status_label: Label
var message_label: Label
var cast_bar: ProgressBar
var tension_bar: TensionBar
var joystick: TouchJoystick
var result_panel: PanelContainer
var result_label: Label
var continue_button: Button


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(16, 16)
	status_panel.self_modulate = Color(1, 1, 1, 0.75)
	root.add_child(status_panel)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	status_panel.add_child(status_label)

	# Faixa de baixo, na largura toda da tela, com tudo centralizado.
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -170
	bottom.offset_bottom = -40
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	message_label.add_theme_constant_override("outline_size", 6)
	bottom.add_child(message_label)
	cast_bar = ProgressBar.new()
	cast_bar.custom_minimum_size = Vector2(320, 22)
	cast_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cast_bar.max_value = 1.0
	cast_bar.show_percentage = false
	bottom.add_child(cast_bar)
	tension_bar = TensionBar.new()
	tension_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom.add_child(tension_bar)

	joystick = TouchJoystick.new()
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(24, -260)
	joystick.visible = DisplayServer.is_touchscreen_available()
	root.add_child(joystick)

	_build_result_panel(root)
	show_cast_power(false, 0.0)
	hide_tension()


func _build_result_panel(root: Control) -> void:
	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.visible = false
	root.add_child(result_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	result_panel.add_child(box)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 24)
	box.add_child(result_label)
	continue_button = Button.new()
	continue_button.text = "Continuar"
	continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	box.add_child(continue_button)


func set_message(text: String) -> void:
	message_label.text = text


func update_status(lines: PackedStringArray) -> void:
	status_label.text = "\n".join(lines)


func show_cast_power(shown: bool, power: float) -> void:
	cast_bar.visible = shown
	cast_bar.value = power


func show_tension(game: TensionMinigame, cfg: Dictionary) -> void:
	tension_bar.visible = true
	tension_bar.fish_jumping = game.profile.is_jumping()
	tension_bar.set_state(
		game.tension,
		float(cfg["green_min"]),
		float(cfg["green_max"]),
		float(cfg["bar_max"]),
		game.break_risk()
	)


func hide_tension() -> void:
	tension_bar.visible = false


func show_result(result: Dictionary, next_unlocked: bool) -> void:
	var stars: int = int(result["stars"])
	var star_text: String = STAR.repeat(stars) + NO_STAR.repeat(3 - stars)
	var verdict: String = "Meta cumprida!" if bool(result["goal_met"]) else "Meta não cumprida"
	result_label.text = (
		"Fim do dia %d\n%s\n%s\n\nPeixes: %d   Pontos: %d\nVendas: %d moedas   Estrelas: +%d moedas"
		% [
			int(result["day"]),
			star_text,
			verdict,
			int(result["fish"]),
			int(result["score"]),
			int(result["coins_from_sales"]),
			int(result["star_reward"]),
		]
	)
	continue_button.text = "Próximo dia" if next_unlocked else "Tentar de novo"
	result_panel.visible = true
	set_message("")
	show_cast_power(false, 0.0)
	hide_tension()
