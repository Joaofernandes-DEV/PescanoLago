class_name InputSetup
extends RefCounted
## Adaptador: registra os comandos do jogo no InputMap (teclado e mouse; no
## celular o toque vira clique e o barco usa o joystick virtual).
## WASD/setas pilotam o barco; Espaço ou clique esquerdo é a ação
## (segurar para carregar o lançamento, clicar para fisgar, segurar para recolher);
## C abre a vista de dentro da caixa de isopor; M abre o mapa grande; segurar Tab
## pula a cutscene; Esc abre o menu de pausa.
##
## Cada comando tem uma tecla principal, que o jogador troca nas configurações
## (bind_primary); as outras (setas e clique) ficam sempre valendo.

const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"
const TURN_LEFT: StringName = &"turn_left"
const TURN_RIGHT: StringName = &"turn_right"
const ACTION: StringName = &"fish_action"
const PAUSE: StringName = &"pause_menu"
const COOLER_VIEW: StringName = &"cooler_view"
const MAP_VIEW: StringName = &"map_view"
const SKIP_CUTSCENE: StringName = &"skip_cutscene"

## Teclas de cada comando; a primeira é a principal.
const KEYS: Dictionary = {
	MOVE_FORWARD: [KEY_W, KEY_UP],
	MOVE_BACK: [KEY_S, KEY_DOWN],
	TURN_LEFT: [KEY_A, KEY_LEFT],
	TURN_RIGHT: [KEY_D, KEY_RIGHT],
	ACTION: [KEY_SPACE],
	COOLER_VIEW: [KEY_C],
	MAP_VIEW: [KEY_M],
	SKIP_CUTSCENE: [KEY_TAB],
	PAUSE: [KEY_ESCAPE],
}
## Comandos que o jogador pode trocar, na ordem da tela de configurações.
const REBINDABLE: Array[StringName] = [
	MOVE_FORWARD, MOVE_BACK, TURN_LEFT, TURN_RIGHT, ACTION, COOLER_VIEW, MAP_VIEW, SKIP_CUTSCENE
]
const ACTION_NAMES: Dictionary = {
	MOVE_FORWARD: "Acelerar",
	MOVE_BACK: "Ré",
	TURN_LEFT: "Virar à esquerda",
	TURN_RIGHT: "Virar à direita",
	ACTION: "Lançar, fisgar e recolher",
	COOLER_VIEW: "Ver a caixa de isopor",
	MAP_VIEW: "Abrir o mapa grande",
	SKIP_CUTSCENE: "Pular a cutscene (segurar)",
	PAUSE: "Menu de pausa",
}
## Nomes em português das teclas que não são letras nem números.
const KEY_NAMES: Dictionary = {
	KEY_SPACE: "Espaço",
	KEY_ESCAPE: "Esc",
	KEY_ENTER: "Enter",
	KEY_TAB: "Tab",
	KEY_SHIFT: "Shift",
	KEY_CTRL: "Ctrl",
	KEY_ALT: "Alt",
	KEY_BACKSPACE: "Apagar",
	KEY_UP: "Seta para cima",
	KEY_DOWN: "Seta para baixo",
	KEY_LEFT: "Seta para a esquerda",
	KEY_RIGHT: "Seta para a direita",
}


static func ensure_actions() -> void:
	for action: StringName in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for keycode: int in KEYS[action]:
			InputMap.action_add_event(action, _key_event(keycode))
	if _mouse_events(ACTION) == 0:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(ACTION, click)


## Tecla principal do comando (a primeira tecla do InputMap).
static func primary_key(action: StringName) -> int:
	ensure_actions()
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return int((event as InputEventKey).physical_keycode)
	return KEY_NONE


## Troca a tecla principal do comando; as teclas extras (setas) e o clique ficam.
## Se outra ação usava essa tecla como principal, as duas trocam de tecla.
static func bind_primary(action: StringName, keycode: int) -> void:
	ensure_actions()
	var previous: int = primary_key(action)
	for other: StringName in REBINDABLE:
		if other != action and primary_key(other) == keycode:
			_replace_primary(other, previous)
	_replace_primary(action, keycode)


## Volta todas as teclas principais ao padrão.
static func reset_bindings() -> void:
	ensure_actions()
	for action: StringName in REBINDABLE:
		_replace_primary(action, int(KEYS[action][0]))


## Teclas principais atuais, para guardar nas configurações: {comando: tecla}.
static func bindings() -> Dictionary:
	var result: Dictionary = {}
	for action: StringName in REBINDABLE:
		result[String(action)] = primary_key(action)
	return result


## Nome curto da tecla, como aparece nas dicas e nas configurações.
static func key_label(keycode: int) -> String:
	if KEY_NAMES.has(keycode):
		return String(KEY_NAMES[keycode])
	return OS.get_keycode_string(keycode as Key)


static func _replace_primary(action: StringName, keycode: int) -> void:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, _key_event(keycode))
	var skipped_primary := false
	for event in events:
		if event is InputEventKey and not skipped_primary:
			skipped_primary = true
			continue
		InputMap.action_add_event(action, event)


static func _key_event(keycode: int) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = keycode as Key
	return key


static func _mouse_events(action: StringName) -> int:
	var count := 0
	for event in InputMap.action_get_events(action):
		count += 1 if event is InputEventMouseButton else 0
	return count
