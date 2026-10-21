class_name SettingsPanel
extends PanelContainer
## Tela de configurações (Fase 7, Bloco A), usada na tela inicial e no menu de
## pausa. Abas: Áudio (volumes), Vídeo (tela cheia, resolução, qualidade, limite
## de fps, vsync, contador de fps), Controles (troca da tecla principal de cada
## comando) e Jogo (dicas e velocidade dos balões de fala). Cada mudança é
## aplicada e salva na hora (GameSettings).

signal closed
## Uma configuração mudou (quem abriu a tela aplica o que depende da cena).
signal changed(key: String)

const WIDTH_PX: float = 640.0
const FPS_UNLIMITED: String = "Sem limite"

var settings: GameSettings
var tabs: TabContainer
## Comando esperando a nova tecla ("" = nenhum).
var waiting_action: StringName = &""

var _key_buttons: Dictionary = {}


func setup(p_settings: GameSettings) -> void:
	settings = p_settings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.build()
	custom_minimum_size = Vector2(WIDTH_PX, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = "Configurações"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(WIDTH_PX - 24.0, 330)
	box.add_child(tabs)
	_build_audio(_tab("Áudio"))
	_build_video(_tab("Vídeo"))
	_build_controls(_tab("Controles"))
	_build_game(_tab("Jogo"))
	var back := Button.new()
	back.name = "Back"
	back.text = "Voltar"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_on_back)
	box.add_child(back)
	# Centraliza depois de montar: o tamanho mínimo já inclui as abas.
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH


func _tab(title: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = title
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	tabs.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	return box


func _row(box: Container, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(230, 0)
	row.add_child(label)
	return row


# --- Áudio ----------------------------------------------------------------


func _build_audio(box: VBoxContainer) -> void:
	for entry: Array in [
		["master_volume", "Volume geral"],
		["music_volume", "Música"],
		["effects_volume", "Efeitos e ambiente"],
	]:
		var key: String = entry[0]
		var row := _row(box, entry[1])
		var slider := HSlider.new()
		slider.name = "Volume_%s" % key
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(settings.values[key])
		slider.custom_minimum_size = Vector2(220, 24)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)
		var percent := Label.new()
		percent.text = _percent(slider.value)
		row.add_child(percent)
		slider.value_changed.connect(_on_volume.bind(key, percent))


func _percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


func _on_volume(value: float, key: String, percent: Label) -> void:
	percent.text = _percent(value)
	settings.set_value(key, value)
	settings.apply_audio()
	_save(key)


# --- Vídeo ----------------------------------------------------------------


func _build_video(box: VBoxContainer) -> void:
	var desktop: bool = not OS.has_feature("web")
	_check(box, "fullscreen", "Tela cheia")
	if desktop:
		var resolution := _option(_row(box, "Resolução (em janela)"), "resolution")
		for size: Array in settings.resolutions():
			resolution.add_item("%d x %d" % [int(size[0]), int(size[1])])
			if int(size[0]) == int(settings.values["resolution"][0]):
				if int(size[1]) == int(settings.values["resolution"][1]):
					resolution.select(resolution.item_count - 1)
		resolution.item_selected.connect(_on_resolution)
	var quality := _option(_row(box, "Qualidade"), "quality")
	for quality_id: String in settings.quality_ids():
		quality.add_item(settings.quality_label(quality_id))
		if quality_id == String(settings.values["quality"]):
			quality.select(quality.item_count - 1)
	quality.item_selected.connect(_on_quality)
	var fps := _option(_row(box, "Limite de quadros por segundo"), "max_fps")
	for limit: Variant in settings.max_fps_options():
		fps.add_item(FPS_UNLIMITED if int(limit) == 0 else "%d fps" % int(limit))
		if int(limit) == int(settings.values["max_fps"]):
			fps.select(fps.item_count - 1)
	fps.item_selected.connect(_on_max_fps)
	if desktop:
		_check(box, "vsync", "Sincronia vertical (vsync)")
	_check(box, "show_fps", "Mostrar o contador de fps")


func _option(row: HBoxContainer, key: String) -> OptionButton:
	var option := OptionButton.new()
	option.name = "Option_%s" % key
	option.custom_minimum_size = Vector2(220, 0)
	row.add_child(option)
	return option


func _check(box: VBoxContainer, key: String, text: String) -> CheckBox:
	var check := CheckBox.new()
	check.name = "Check_%s" % key
	check.text = text
	check.button_pressed = bool(settings.values[key])
	check.toggled.connect(_on_check.bind(key))
	box.add_child(check)
	return check


func _on_check(pressed: bool, key: String) -> void:
	settings.set_value(key, pressed)
	if key in ["fullscreen", "vsync"]:
		settings.apply_display()
	_save(key)


func _on_resolution(index: int) -> void:
	var size: Array = settings.resolutions()[index]
	settings.set_value("resolution", [int(size[0]), int(size[1])])
	settings.apply_display()
	_save("resolution")


func _on_quality(index: int) -> void:
	settings.set_value("quality", String(settings.quality_ids()[index]))
	_save("quality")


func _on_max_fps(index: int) -> void:
	settings.set_value("max_fps", int(settings.max_fps_options()[index]))
	settings.apply_display()
	_save("max_fps")


# --- Controles ------------------------------------------------------------


func _build_controls(box: VBoxContainer) -> void:
	var note := Label.new()
	note.text = (
		"Clique no comando e aperte a nova tecla (Esc cancela)."
		+ " As setas e o clique continuam valendo."
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 15)
	box.add_child(note)
	for action: StringName in InputSetup.REBINDABLE:
		var row := _row(box, String(InputSetup.ACTION_NAMES[action]))
		var button := Button.new()
		button.name = "Key_%s" % action
		button.custom_minimum_size = Vector2(200, 0)
		button.pressed.connect(_on_key_pressed.bind(action))
		row.add_child(button)
		_key_buttons[action] = button
	var reset := Button.new()
	reset.name = "ResetKeys"
	reset.text = "Voltar às teclas padrão"
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(_on_reset_keys)
	box.add_child(reset)
	_refresh_keys()


func _refresh_keys() -> void:
	for action: StringName in _key_buttons:
		var button: Button = _key_buttons[action]
		if action == waiting_action:
			button.text = "Aperte uma tecla..."
		else:
			button.text = InputSetup.key_label(InputSetup.primary_key(action))


func _on_key_pressed(action: StringName) -> void:
	waiting_action = action
	_refresh_keys()


## Recebe a tecla nova do comando que está esperando (Esc cancela).
func press_key(keycode: int) -> void:
	if waiting_action == &"":
		return
	if keycode != KEY_ESCAPE:
		settings.bind_key(waiting_action, keycode)
		_save("keys")
	waiting_action = &""
	_refresh_keys()


func _input(event: InputEvent) -> void:
	if waiting_action == &"" or not visible:
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		press_key(int(key.physical_keycode))
		get_viewport().set_input_as_handled()


func _on_reset_keys() -> void:
	settings.reset_keys()
	waiting_action = &""
	_refresh_keys()
	_save("keys")


# --- Jogo -----------------------------------------------------------------


func _build_game(box: VBoxContainer) -> void:
	_check(box, "show_hints", "Mostrar as dicas de controle")
	var speed := _option(_row(box, "Velocidade dos balões"), "balloon_speed")
	for speed_id: String in settings.balloon_speed_ids():
		speed.add_item(settings.balloon_speed_label(speed_id))
		if speed_id == String(settings.values["balloon_speed"]):
			speed.select(speed.item_count - 1)
	speed.item_selected.connect(_on_balloon_speed)


func _on_balloon_speed(index: int) -> void:
	settings.set_value("balloon_speed", String(settings.balloon_speed_ids()[index]))
	_save("balloon_speed")


func _save(key: String) -> void:
	settings.save_file()
	changed.emit(key)


func _on_back() -> void:
	waiting_action = &""
	_refresh_keys()
	closed.emit()


func find_control(control_name: String) -> Control:
	return find_child(control_name, true, false) as Control
