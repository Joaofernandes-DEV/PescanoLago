class_name CastMeter
extends Control
## Medidor de força do lançamento: a barra enche enquanto o jogador segura a ação
## e mostra até onde a isca precisa ir para alcançar o cardume (o risco). Passou
## do risco, a barra fica verde. O texto diz a distância em metros.

const BAR_SIZE := Vector2(340, 20)
const GOOD := Color("7ce08a")
const SHORT := Color("ffb347")
const TRACK := Color(0.08, 0.12, 0.16, 0.65)

## Força de 0 a 1 (fração do alcance da vara).
var power: float = 0.0
## Fração da força que alcança o cardume (pode passar de 1: fora do alcance).
var needed: float = 0.0
var range_m: float = 1.0
var _label: Label


func _init() -> void:
	custom_minimum_size = Vector2(BAR_SIZE.x, BAR_SIZE.y + 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.position = Vector2(0, BAR_SIZE.y + 2)
	_label.size = Vector2(BAR_SIZE.x, 26)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)


## Atualiza a barra. school_m: distância do cardume; p_range_m: alcance da vara;
## attraction_m: raio de atração da isca (artificiais; a isca não precisa cair em cima).
func set_state(
	p_power: float, school_m: float, p_range_m: float, attraction_m: float = 0.0
) -> void:
	power = clampf(p_power, 0.0, 1.0)
	range_m = maxf(p_range_m, 0.01)
	needed = maxf(0.0, school_m - attraction_m) / range_m
	_label.text = (
		"%d m de %d m   ·   cardume a %d m"
		% [roundi(power * range_m), roundi(range_m), roundi(school_m)]
	)
	queue_redraw()


## A força atual já leva a isca até o cardume?
func reaches() -> bool:
	return needed <= 1.0 and power >= needed


func _draw() -> void:
	var track := Rect2(Vector2.ZERO, BAR_SIZE)
	draw_rect(track, TRACK)
	var fill := Rect2(Vector2.ZERO, Vector2(BAR_SIZE.x * power, BAR_SIZE.y))
	draw_rect(fill, GOOD if reaches() else SHORT)
	if needed <= 1.0:
		var x: float = BAR_SIZE.x * needed
		draw_line(Vector2(x, -4), Vector2(x, BAR_SIZE.y + 4), Color.WHITE, 3.0)
	draw_rect(track, Color(1, 1, 1, 0.8), false, 2.0)
