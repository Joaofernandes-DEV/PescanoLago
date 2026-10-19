class_name ControlHints
extends PanelContainer
## Dica de controle do momento (etapa "Navegar e pescar com clareza", Fase 6):
## um cartão discreto acima do medidor, com o comando certo para teclado e mouse
## ou para toque. Cada dica some depois que o jogador faz a ação algumas vezes
## (PlayerState.tips_progress, guardado no save v3).
##
## Texto: trechos entre colchetes viram teclas desenhadas ([Espaço]).

## id da dica -> {"keys": texto para teclado e mouse, "touch": texto para toque}.
const HINTS: Dictionary = {
	"steer":
	{
		"keys": "Pilote com [W] [A] [S] [D] ou as setas e pare perto das ondulações",
		"touch": "Pilote com o joystick à esquerda e pare perto das ondulações",
	},
	"move_closer":
	{
		"keys": "O cardume está longe para a sua vara: chegue mais perto",
		"touch": "O cardume está longe para a sua vara: chegue mais perto",
	},
	"cast_hold":
	{
		"keys": "Mire com o mouse e segure [Espaço] ou o [clique] para carregar",
		"touch": "Toque e segure sobre as ondulações para carregar",
	},
	"cast_release":
	{
		"keys": "Solte quando a barra passar do risco branco",
		"touch": "Solte quando a barra passar do risco branco",
	},
	"hook_tap":
	{
		"keys": "A boia afundou: aperte [Espaço] ou [clique] agora!",
		"touch": "A boia afundou: toque na tela agora!",
	},
	"reel_hold":
	{
		"keys": "Segure [Espaço] para recolher; solte se a barra passar do verde",
		"touch": "Segure o dedo na tela para recolher; solte se a barra passar do verde",
	},
	"dock":
	{
		"keys": "Viveiro cheio: volte ao cais de Porto Manso para vender",
		"touch": "Viveiro cheio: volte ao cais de Porto Manso para vender",
	},
}
## Dicas que aparecem sempre (avisos da situação, não lições de comando).
const ALWAYS: PackedStringArray = ["move_closer", "dock"]

var current_id: String = ""
var _row: HBoxContainer
var _touch: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_theme_stylebox_override("panel", UiTheme.panel_box(16))
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 6)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_row)
	visible = false


## Qual dica cabe no momento do dia, ou "" se nenhuma.
static func pick(
	stage: DaySession.Stage,
	can_cast: bool,
	charging: bool,
	livewell_full: bool,
	school_out_of_reach: bool
) -> String:
	match stage:
		DaySession.Stage.SEARCHING:
			return "dock" if livewell_full else "steer"
		DaySession.Stage.AT_SCHOOL:
			if livewell_full:
				return "dock"
			if school_out_of_reach and not charging:
				return "move_closer"
			if charging:
				return "cast_release"
			return "cast_hold" if can_cast else ""
		DaySession.Stage.BITE:
			return "hook_tap"
		DaySession.Stage.FIGHTING:
			return "reel_hold"
	return ""


## A dica ainda é mostrada para quem já fez a ação `count` vezes?
static func still_needed(hint_id: String, count: int, show_until: int) -> bool:
	return ALWAYS.has(hint_id) or count < show_until


## Mostra a dica (ou esconde, com id vazio) no modo de entrada atual.
func show_hint(hint_id: String, touch: bool) -> void:
	if hint_id == current_id and touch == _touch:
		return
	current_id = hint_id
	_touch = touch
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	visible = not hint_id.is_empty()
	if not visible:
		return
	_build(String(HINTS[hint_id]["touch" if touch else "keys"]))


## Texto da dica atual, sem as marcas das teclas (para os testes).
func text() -> String:
	var parts: PackedStringArray = []
	for child in _row.get_children():
		parts.append(_text_of(child))
	return " ".join(parts)


func _build(template: String) -> void:
	var rest: String = template
	while not rest.is_empty():
		var open: int = rest.find("[")
		if open < 0:
			_add_words(rest)
			break
		_add_words(rest.substr(0, open))
		var close: int = rest.find("]", open)
		_add_key(rest.substr(open + 1, close - open - 1))
		rest = rest.substr(close + 1)


func _add_words(words: String) -> void:
	var trimmed: String = words.strip_edges()
	if trimmed.is_empty():
		return
	var label := Label.new()
	label.text = trimmed
	label.add_theme_font_size_override("font_size", 19)
	_row.add_child(label)


func _add_key(key_name: String) -> void:
	var cap := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.92)
	box.set_corner_radius_all(6)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 1
	box.content_margin_bottom = 2
	cap.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.text = key_name
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.1, 0.16, 0.22))
	cap.add_child(label)
	_row.add_child(cap)


static func _text_of(node: Node) -> String:
	if node is Label:
		return (node as Label).text
	return _text_of(node.get_child(0))
