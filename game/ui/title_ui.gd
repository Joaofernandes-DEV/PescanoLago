class_name TitleUi
extends CanvasLayer
## Interface da tela inicial (Fase 7, Bloco A): logo, botões (Continuar, Novo
## jogo, Configurações, Créditos, Sair), a confirmação de Novo jogo quando já
## existe progresso salvo, os créditos e a tela de configurações.

signal continue_requested
signal new_game_requested
signal quit_requested

const CREDITS: String = """PescanoLago
Projeto de extensão da UNIP

Desenvolvimento, arte e som: João Vitor Fernandes

Feito com a Godot Engine 4.7 (licença MIT)
Modelos low-poly feitos no Blender 5.2
Música e efeitos por síntese própria

Código: licença MIT
Arte e textos: CC BY-NC 4.0"""

## Margem esquerda do logo e do menu (o cenário fica livre à direita).
const LEFT_PX: float = 56.0

var settings: GameSettings
## Resumo do save ("Dia 3 · 420 moedas"); vazio quando não há progresso salvo.
var save_summary: String = ""
var menu: VBoxContainer
var continue_button: Button
var summary_label: Label
var confirm_panel: PanelContainer
var credits_panel: PanelContainer
var settings_panel: SettingsPanel

var _root: Control


func setup(p_settings: GameSettings, p_save_summary: String) -> void:
	settings = p_settings
	save_summary = p_save_summary


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.build()
	add_child(_root)
	_build_logo()
	_build_menu()
	confirm_panel = _build_confirm()
	credits_panel = _build_credits()
	settings_panel = SettingsPanel.new()
	settings_panel.name = "Settings"
	settings_panel.setup(settings)
	settings_panel.visible = false
	settings_panel.closed.connect(_show_menu)
	_root.add_child(settings_panel)
	var version := Label.new()
	version.text = "versão %s" % String(ProjectSettings.get_setting("application/config/version"))
	version.add_theme_font_size_override("font_size", 14)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -160
	version.offset_top = -30
	version.offset_right = -12
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(version)


func _build_logo() -> void:
	var logo := VBoxContainer.new()
	logo.name = "Logo"
	logo.position = Vector2(LEFT_PX, 40)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(logo)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	logo.add_child(row)
	row.add_child(HudIcon.create("fish", 72.0))
	var title := Label.new()
	title.text = "PescanoLago"
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color(0.06, 0.12, 0.2))
	row.add_child(title)


func _build_menu() -> void:
	var panel := PanelContainer.new()
	panel.name = "Menu"
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.offset_left = LEFT_PX + 12.0
	panel.offset_top = 10
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	menu.custom_minimum_size = Vector2(300, 0)
	panel.add_child(menu)
	continue_button = _menu_button("Continue", "Continuar", continue_requested.emit)
	continue_button.disabled = save_summary.is_empty()
	summary_label = Label.new()
	summary_label.name = "SaveSummary"
	summary_label.text = save_summary if not save_summary.is_empty() else "Nenhum progresso salvo"
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.add_theme_font_size_override("font_size", 15)
	menu.add_child(summary_label)
	_menu_button("NewGame", "Novo jogo", _on_new_game)
	_menu_button("SettingsButton", "Configurações", _show_settings)
	_menu_button("Credits", "Créditos", _show_credits)
	# No navegador, quem fecha o jogo é a aba.
	if not OS.has_feature("web"):
		_menu_button("Quit", "Sair", quit_requested.emit)


func _menu_button(button_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	menu.add_child(button)
	return button


func _dialog(dialog_name: String, text: String) -> Array:
	var panel := PanelContainer.new()
	panel.name = dialog_name
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
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	return [panel, buttons]


func _build_confirm() -> PanelContainer:
	var parts := _dialog(
		"ConfirmNewGame",
		"Começar um jogo novo apaga o progresso salvo. Quer mesmo começar do zero?"
	)
	var buttons: HBoxContainer = parts[1]
	for entry: Array in [["ConfirmYes", "Começar do zero"], ["ConfirmNo", "Cancelar"]]:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[1]
		buttons.add_child(button)
	(buttons.get_child(0) as Button).pressed.connect(new_game_requested.emit)
	(buttons.get_child(1) as Button).pressed.connect(_show_menu)
	return parts[0]


func _build_credits() -> PanelContainer:
	var parts := _dialog("CreditsPanel", CREDITS)
	var back := Button.new()
	back.name = "CreditsBack"
	back.text = "Voltar"
	back.pressed.connect(_show_menu)
	(parts[1] as HBoxContainer).add_child(back)
	return parts[0]


func _on_new_game() -> void:
	if save_summary.is_empty():
		new_game_requested.emit()
		return
	_show_only(confirm_panel)


func _show_settings() -> void:
	_show_only(settings_panel)


func _show_credits() -> void:
	_show_only(credits_panel)


func _show_menu() -> void:
	_show_only(menu.get_parent() as Control)


func _show_only(panel: Control) -> void:
	for candidate: Control in [menu.get_parent(), confirm_panel, credits_panel, settings_panel]:
		candidate.visible = candidate == panel
	# O logo só aparece com o menu: os painéis ficam no centro e cobririam parte dele.
	(_root.find_child("Logo", true, false) as Control).visible = panel == menu.get_parent()


func find_button(button_name: String) -> Button:
	return _root.find_child(button_name, true, false) as Button
