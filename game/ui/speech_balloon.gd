class_name SpeechBalloon
extends Control
## Balão de fala preso a um personagem (Fase 7, Bloco B; P-39): papel claro com
## contorno de tinta, o nome de quem fala em cima, o texto aparecendo aos poucos e
## um rabicho apontando para a cabeça. O balão fica acima da cabeça e não sai da
## tela (se a cabeça sai, o rabicho aponta para a borda). Estilos: fala (cantos
## redondos), grito (borda em pontas) e cochicho (contorno tracejado). Uma seta
## pisca no canto quando a fala está inteira (o clique continua).
##
## O balão, o rabicho e a seta vão num comando só (ShapeBatch); o texto vai em
## outro. As linhas são quebradas uma vez, com a fala inteira, para as palavras
## não pularem de linha enquanto aparecem.

const CORNER_SEGMENTS: int = 5
const TAIL_BASE_RATIO: float = 0.45
const SHADOW_OFFSET: Vector2 = Vector2(4.0, 6.0)
const SHADOW_ALPHA: float = 0.35
const NAME_GAP_PX: float = 4.0
## Quanto o balão vai para o lado de fora (fração da largura dele).
const OUTWARD_SHIFT: float = 0.3

## Linhas da fala atual, já quebradas na largura do balão.
var wrapped: PackedStringArray = []
var speaker_name: String = ""
var style: String = Dialogue.DEFAULT_STYLE
## Letras que já aparecem (das linhas, na ordem).
var revealed: int = 0
var complete: bool = false
## Retângulo do balão na tela e a ponta do rabicho.
var box: Rect2
var tail_tip: Vector2

var _cfg: Dictionary
var _font: Font
var _batch := ShapeBatch.new()
var _anchor := Vector2.ZERO
var _text: String = ""
var _time_s: float = 0.0


func setup(cfg: Dictionary) -> void:
	_cfg = cfg
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


func _ready() -> void:
	_font = get_theme_default_font()


## Mostra a fala (texto inteiro, para quebrar as linhas) começando sem letras.
func show_line(p_name: String, text: String, p_style: String) -> void:
	if _font == null:
		_font = get_theme_default_font()
	speaker_name = p_name
	_text = text
	style = p_style
	revealed = 0
	complete = false
	var padding: float = float(_cfg["padding_px"])
	wrapped = wrap_text(
		text, _font, int(_cfg["font_size"]), float(_cfg["max_width_px"]) - padding * 2.0
	)
	visible = true
	_layout()


## Quebra o texto em linhas de até width pixels, palavra por palavra.
static func wrap_text(text: String, font: Font, font_size: int, width: float) -> PackedStringArray:
	var result: PackedStringArray = []
	var current: String = ""
	for word in text.split(" ", false):
		var candidate: String = word if current.is_empty() else "%s %s" % [current, word]
		if (
			not current.is_empty()
			and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width
		):
			result.append(current)
			current = word
		else:
			current = candidate
	if not current.is_empty():
		result.append(current)
	return result


func set_revealed(count: int, is_complete: bool) -> void:
	revealed = count
	complete = is_complete
	queue_redraw()


## Ponto da tela para onde o rabicho aponta (o alto da cabeça de quem fala).
func point_at(point: Vector2) -> void:
	_anchor = point
	_layout()


func hide_balloon() -> void:
	visible = false
	wrapped = []


## Texto que já aparece, para os testes.
func shown_text() -> String:
	return _text.substr(0, revealed)


func _process(delta: float) -> void:
	_time_s += delta
	if visible and complete:
		queue_redraw()


func _layout() -> void:
	if not visible or _font == null:
		return
	var padding: float = float(_cfg["padding_px"])
	var size_px := int(_cfg["font_size"])
	var name_size := int(_cfg["name_font_size"])
	var width: float = _font.get_string_size(speaker_name, 0, -1, name_size).x
	for text_line in wrapped:
		width = maxf(width, _font.get_string_size(text_line, 0, -1, size_px).x)
	var height: float = (
		_font.get_height(name_size) + NAME_GAP_PX + _font.get_height(size_px) * wrapped.size()
	)
	var box_size := Vector2(width, height) + Vector2.ONE * padding * 2.0
	var screen: Vector2 = get_viewport_rect().size
	var margin: float = float(_cfg["screen_margin_px"])
	tail_tip = _anchor.clamp(Vector2.ONE * margin, screen - Vector2.ONE * margin)
	tail_tip.y -= float(_cfg["gap_px"])
	# O balão vai um pouco para o lado de fora da tela, para não cobrir quem está
	# no meio da conversa.
	var outward: float = signf(tail_tip.x - screen.x / 2.0) * box_size.x * OUTWARD_SHIFT
	var corner := Vector2(
		tail_tip.x - box_size.x / 2.0 + outward, tail_tip.y - float(_cfg["tail_px"]) - box_size.y
	)
	corner = corner.clamp(Vector2.ONE * margin, screen - box_size - Vector2.ONE * margin)
	box = Rect2(corner, box_size)
	queue_redraw()


func _draw() -> void:
	if not visible or wrapped.is_empty():
		return
	var ink: Color = Color.html(String(_cfg["ink"]))
	var fill: Color = Color.html(String(_cfg["fill"]))
	var shadow: Color = Color.html(String(_cfg["shadow"]))
	shadow.a = SHADOW_ALPHA
	var outline: float = float(_cfg["outline_px"])
	var shape: PackedVector2Array = _outline_shape(box)
	var tail: PackedVector2Array = _tail()
	_batch.clear()
	_batch.add_polygon(_moved(shape, SHADOW_OFFSET), shadow)
	_batch.add_polygon(_moved(tail, SHADOW_OFFSET), shadow)
	if style == "whisper":
		_batch.add_polygon(shape, fill)
		_batch.add_polygon(tail, fill)
		_add_dashes(shape, ink, outline)
	else:
		_batch.add_polygon(_outline_shape(box.grow(outline)), ink)
		_batch.add_polygon(_grown(tail, outline), ink)
		_batch.add_polygon(shape, fill)
		_batch.add_polygon(tail, fill)
	if complete and sin(_time_s * TAU * float(_cfg["next_blink_hz"])) > 0.0:
		_add_next_arrow(ink)
	_batch.draw(get_canvas_item())
	_draw_text(ink)


func _draw_text(ink: Color) -> void:
	var padding: float = float(_cfg["padding_px"])
	var size_px := int(_cfg["font_size"])
	var name_size := int(_cfg["name_font_size"])
	var pen: Vector2 = box.position + Vector2(padding, padding + _font.get_ascent(name_size))
	draw_string(
		_font,
		pen,
		speaker_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		name_size,
		Color.html(String(_cfg["name"]))
	)
	pen.y += _font.get_descent(name_size) + NAME_GAP_PX + _font.get_ascent(size_px)
	var left: int = revealed
	for text_line in wrapped:
		if left <= 0:
			break
		draw_string(
			_font, pen, text_line.substr(0, left), HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, ink
		)
		# O espaço da quebra de linha também conta como letra que já apareceu.
		left -= text_line.length() + 1
		pen.y += _font.get_height(size_px)


## Contorno do balão: cantos redondos; no grito, a borda vira pontas.
func _outline_shape(rect: Rect2) -> PackedVector2Array:
	var corner: float = minf(float(_cfg["corner_px"]), minf(rect.size.x, rect.size.y) / 2.0)
	var points := PackedVector2Array()
	var centers: Array[Vector2] = [
		rect.end - Vector2.ONE * corner,
		Vector2(rect.position.x + corner, rect.end.y - corner),
		rect.position + Vector2.ONE * corner,
		Vector2(rect.end.x - corner, rect.position.y + corner),
	]
	for k in centers.size():
		for step in CORNER_SEGMENTS + 1:
			var angle: float = (float(k) + float(step) / CORNER_SEGMENTS) * PI / 2.0
			points.append(centers[k] + Vector2(cos(angle), sin(angle)) * corner)
	if style == "shout":
		return _spiky(points, rect.get_center())
	return points


## Borda em pontas do grito: pontos novos entre os do contorno, empurrados para fora.
func _spiky(points: PackedVector2Array, center: Vector2) -> PackedVector2Array:
	var spikes: int = int(_cfg["shout_spikes"])
	var spike: float = float(_cfg["shout_spike_px"])
	var perimeter := Curve2D.new()
	for point in points:
		perimeter.add_point(point)
	perimeter.add_point(points[0])
	var length: float = perimeter.get_baked_length()
	var result := PackedVector2Array()
	for i in spikes * 2:
		var point: Vector2 = perimeter.sample_baked(length * float(i) / float(spikes * 2))
		if i % 2 == 0:
			point += (point - center).normalized() * spike
		result.append(point)
	return result


func _tail() -> PackedVector2Array:
	var base_half: float = float(_cfg["tail_px"]) * TAIL_BASE_RATIO
	var corner: float = float(_cfg["corner_px"])
	var x: float = clampf(
		tail_tip.x, box.position.x + corner + base_half, box.end.x - corner - base_half
	)
	# A base entra um pouco no balão para emendar sem fresta.
	var y: float = box.end.y - float(_cfg["outline_px"]) * 2.0
	return PackedVector2Array([Vector2(x - base_half, y), tail_tip, Vector2(x + base_half, y)])


func _add_next_arrow(ink: Color) -> void:
	var padding: float = float(_cfg["padding_px"])
	var tip: Vector2 = box.end - Vector2(padding, padding * 0.5)
	var half: float = padding * 0.4
	_batch.add_triangle(
		tip + Vector2(-half * 2.0, -half * 1.5),
		tip + Vector2(0.0, -half * 1.5),
		tip + Vector2(-half, 0.0),
		ink,
		ink,
		ink
	)


## Contorno tracejado do cochicho.
func _add_dashes(shape: PackedVector2Array, ink: Color, width: float) -> void:
	var dash: float = float(_cfg["whisper_dash_px"])
	var curve := Curve2D.new()
	for point in shape:
		curve.add_point(point)
	curve.add_point(shape[0])
	var length: float = curve.get_baked_length()
	var at: float = 0.0
	while at < length:
		var from: Vector2 = curve.sample_baked(at)
		var to: Vector2 = curve.sample_baked(minf(at + dash, length))
		_batch.add_line(from, to, width, ink)
		at += dash * 2.0


static func _moved(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


## Triângulo um pouco maior (o contorno de tinta do rabicho).
static func _grown(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center := Vector2.ZERO
	for point in points:
		center += point / float(points.size())
	var result := PackedVector2Array()
	for point in points:
		result.append(point + (point - center).normalized() * amount * 2.0)
	return result
