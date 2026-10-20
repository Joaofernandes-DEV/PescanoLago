class_name PauseMenu
extends CanvasLayer
## Menu de pausa (Fase 7, Bloco A), aberto com Esc no dia de pesca e em Porto
## Manso: Continuar, Configurações, Voltar à tela inicial (no dia, com aviso de
## que o dia em andamento não conta) e Sair do jogo (fora do navegador).
## Enquanto aberto, a árvore fica pausada; o menu continua funcionando.

signal title_requested
signal quit_requested
## Uma configuração mudou (quem abriu aplica o que depende da cena).
signal settings_changed(key: String)

const LAYER: int = 90

var settings: GameSettings
## No dia de pesca, voltar à tela inicial pede confirmação.
var in_day: bool = false
var menu: VBoxContainer
var confirm_panel: PanelContainer
var settings_panel: SettingsPanel

var _root: Control


func setup(p_settings: GameSettings) -> void:
	settings = p_settings


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.build()
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.1, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var panel := PanelContainer.new()
	panel.name = "PauseBox"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	menu.custom_minimum_size = Vector2(300, 0)
	panel.add_child(menu)
	var title := Label.new()
	title.text = "Pausa"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(title)
	_button("Resume", "Continuar", close)
	_button("PauseSettings", "Configurações", _show_settings)
	_button("ToTitle", "Voltar à tela inicial", _on_to_title)
	if not OS.has_feature("web"):
		_button("QuitGame", "Sair do jogo", quit_requested.emit)
	confirm_panel = _build_confirm()
	settings_panel = SettingsPanel.new()
	settings_panel.name = "Settings"
	settings_panel.setup(settings)
	settings_panel.visible = false
	settings_panel.closed.connect(_show_menu)
	settings_panel.changed.connect(settings_changed.emit)
	_root.add_child(settings_panel)
	visible = false


func _button(button_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	menu.add_child(button)
	return button


func _build_confirm() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ConfirmToTitle"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(420, 0)
	panel.add_child(box)
	var label := Label.new()
	label.text = (
		"O dia em andamento não vai contar: os peixes e as moedas dele se perdem."
		+ " Voltar à tela inicial?"
	)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	for entry: Array in [
		["ConfirmTitleYes", "Voltar à tela inicial"], ["ConfirmTitleNo", "Continuar pescando"]
	]:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[1]
		buttons.add_child(button)
	(buttons.get_child(0) as Button).pressed.connect(_leave_to_title)
	(buttons.get_child(1) as Button).pressed.connect(_show_menu)
	return panel


func is_open() -> bool:
	return visible


func open() -> void:
	visible = true
	_show_menu()
	get_tree().paused = true


func close() -> void:
	visible = false
	settings_panel.waiting_action = &""
	get_tree().paused = false


func toggle() -> void:
	if visible:
		# Esc fecha a tela aberta por dentro do menu antes de fechar o menu.
		if not menu.get_parent().visible:
			_show_menu()
			return
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputSetup.PAUSE) and settings_panel.waiting_action == &"":
		toggle()
		get_viewport().set_input_as_handled()


func _on_to_title() -> void:
	if in_day:
		_show_only(confirm_panel)
		return
	_leave_to_title()


func _leave_to_title() -> void:
	close()
	title_requested.emit()


func _show_settings() -> void:
	_show_only(settings_panel)


func _show_menu() -> void:
	_show_only(menu.get_parent() as Control)


func _show_only(panel: Control) -> void:
	for candidate: Control in [menu.get_parent(), confirm_panel, settings_panel]:
		candidate.visible = candidate == panel


func find_button(button_name: String) -> Button:
	return _root.find_child(button_name, true, false) as Button
