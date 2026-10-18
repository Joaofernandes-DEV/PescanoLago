class_name DayHud
extends CanvasLayer
## HUD discreto no canto (GDD: tempo, meta, viveiro, combo, "com ícones desenhados
## à mão"): pílulas com os ícones do Blender (HudIcon) e o tema da interface
## (UiTheme). Também mostra as mensagens de ajuda, a barra de força do
## lançamento, a barra de tensão, o joystick de toque e a tela de fim de dia.

signal continue_pressed

## Ordem das pílulas do canto e o ícone de cada uma.
const STATS: Array[Array] = [
	["time", "clock"],
	["goal", "goal"],
	["livewell", "livewell"],
	["combo", "combo"],
	["coins", "coin"],
	["bait", "bait"],
]
const ICON_PX: float = 34.0

var title_label: Label
var stat_labels: Dictionary = {}
var sonar_label: Label
var message_label: Label
var cast_bar: ProgressBar
var tension_bar: TensionBar
var joystick: TouchJoystick
var result_panel: PanelContainer
var result_title: Label
var result_stars: Array[HudIcon] = []
var result_label: Label
var continue_button: Button

var _pulse: Dictionary = {}


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.build()
	add_child(root)

	var corner := VBoxContainer.new()
	corner.position = Vector2(16, 14)
	corner.add_theme_constant_override("separation", 6)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(corner)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	corner.add_child(title_label)
	for stat: Array in STATS:
		corner.add_child(_pill(stat[0], stat[1]))
	sonar_label = Label.new()
	sonar_label.add_theme_font_size_override("font_size", 16)
	corner.add_child(sonar_label)

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


func _pill(key: String, icon_name: String) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiTheme.panel_box(18))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	pill.add_child(row)
	row.add_child(HudIcon.create(icon_name, ICON_PX))
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 19)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	stat_labels[key] = label
	return pill


func _build_result_panel(root: Control) -> void:
	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	result_panel.add_theme_stylebox_override("panel", UiTheme.panel_box(22))
	result_panel.visible = false
	root.add_child(result_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(440, 0)
	result_panel.add_child(box)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 30)
	box.add_child(result_title)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 10)
	box.add_child(stars)
	for i in 3:
		var star := HudIcon.create("star", 64.0)
		stars.add_child(star)
		result_stars.append(star)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 21)
	box.add_child(result_label)
	continue_button = Button.new()
	continue_button.text = "Continuar"
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.custom_minimum_size = Vector2(280, 46)
	continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(continue_button)


func _on_continue_pressed() -> void:
	continue_pressed.emit()


func set_message(text: String) -> void:
	message_label.text = text


## Atualiza o canto: title, time, goal, livewell, combo, coins, bait e sonar
## (sonar vazio esconde a linha). Uma pílula pulsa quando o valor muda.
func update_stats(stats: Dictionary) -> void:
	title_label.text = String(stats.get("title", ""))
	for key: String in stat_labels:
		var label: Label = stat_labels[key]
		var text: String = String(stats.get(key, ""))
		if label.text != text and not label.text.is_empty() and key != "time":
			_pulse[key] = 1.0
		label.text = text
	sonar_label.text = String(stats.get("sonar", ""))
	sonar_label.visible = not sonar_label.text.is_empty()


func _process(delta: float) -> void:
	for key: String in _pulse.keys():
		var t: float = maxf(0.0, float(_pulse[key]) - delta * 2.5)
		_pulse[key] = t
		var pill := (stat_labels[key] as Label).get_parent().get_parent() as Control
		pill.pivot_offset = pill.size * 0.5
		pill.scale = Vector2.ONE * (1.0 + 0.12 * sin(t * PI))
		if t <= 0.0:
			_pulse.erase(key)


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
	result_title.text = "Fim do dia %d" % int(result["day"])
	for i in result_stars.size():
		result_stars[i].modulate = UiTheme.STAR_ON if i < stars else UiTheme.STAR_OFF
	var verdict: String = "Meta cumprida!" if bool(result["goal_met"]) else "Meta não cumprida"
	result_label.text = (
		"%s\n\nPeixes: %d   Pontos: %d\nVendas: %d moedas   Estrelas: +%d moedas"
		% [
			verdict,
			int(result["fish"]),
			int(result["score"]),
			int(result["coins_from_sales"]),
			int(result["star_reward"]),
		]
	)
	if next_unlocked:
		result_label.text += "\n\nDia %d liberado no mapa!" % (int(result["day"]) + 1)
	continue_button.text = "Voltar a Porto Manso"
	result_panel.visible = true
	set_message("")
	show_cast_power(false, 0.0)
	hide_tension()


func stars_shown() -> int:
	var lit: int = 0
	for star in result_stars:
		if star.modulate == UiTheme.STAR_ON:
			lit += 1
	return lit
