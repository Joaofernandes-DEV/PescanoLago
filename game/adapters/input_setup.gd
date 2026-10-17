class_name InputSetup
extends RefCounted
## Adaptador: registra os comandos do jogo no InputMap (teclado e mouse; no
## celular o toque vira clique e o barco usa o joystick virtual).
## WASD/setas pilotam o barco; Espaço ou clique esquerdo é a ação
## (segurar para carregar o lançamento, clicar para fisgar, segurar para recolher).

const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"
const TURN_LEFT: StringName = &"turn_left"
const TURN_RIGHT: StringName = &"turn_right"
const ACTION: StringName = &"fish_action"

const KEYS: Dictionary = {
	MOVE_FORWARD: [KEY_W, KEY_UP],
	MOVE_BACK: [KEY_S, KEY_DOWN],
	TURN_LEFT: [KEY_A, KEY_LEFT],
	TURN_RIGHT: [KEY_D, KEY_RIGHT],
	ACTION: [KEY_SPACE],
}


static func ensure_actions() -> void:
	for action: StringName in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for keycode: int in KEYS[action]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode as Key
			InputMap.action_add_event(action, key)
	if InputMap.action_get_events(ACTION).size() == KEYS[ACTION].size():
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(ACTION, click)
