class_name ShapeBatch
extends RefCounted
## Junta formas 2D (polígonos, círculos, anéis, linhas, leques) numa lista de
## triângulos com a cor em cada vértice, desenhada num comando só: um draw call
## para o mapa inteiro, em vez de um por forma (a meta é de até 150 por quadro).

var points := PackedVector2Array()
var colors := PackedColorArray()


func clear() -> void:
	points.clear()
	colors.clear()


func triangle_count() -> int:
	return points.size() / 3


func add_triangle(
	a: Vector2, b: Vector2, c: Vector2, color_a: Color, color_b: Color, color_c: Color
) -> void:
	points.append_array([a, b, c])
	colors.append_array([color_a, color_b, color_c])


## Polígono simples (sem cruzar as próprias bordas), de uma cor.
func add_polygon(polygon: PackedVector2Array, color: Color) -> void:
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	for i in indices:
		points.append(polygon[i])
		colors.append(color)


func add_rect(rect: Rect2, color: Color) -> void:
	add_polygon(
		PackedVector2Array(
			[
				rect.position,
				Vector2(rect.end.x, rect.position.y),
				rect.end,
				Vector2(rect.position.x, rect.end.y)
			]
		),
		color
	)


func add_circle(center: Vector2, radius: float, color: Color, segments: int = 16) -> void:
	add_fan(center, radius, 0.0, TAU, color, color, segments)


## Leque do centro até o arco de from_rad a to_rad; a cor vai de inner (centro) a
## outer (arco), e o arco pode ir de uma cor a outra (a varredura do sonar).
func add_fan(
	center: Vector2,
	radius: float,
	from_rad: float,
	to_rad: float,
	inner: Color,
	outer: Color,
	segments: int = 16,
	outer_end: Variant = null
) -> void:
	var end_color: Color = outer if outer_end == null else outer_end
	for i in segments:
		var t0: float = float(i) / float(segments)
		var t1: float = float(i + 1) / float(segments)
		var a0: float = lerpf(from_rad, to_rad, t0)
		var a1: float = lerpf(from_rad, to_rad, t1)
		add_triangle(
			center,
			center + Vector2(cos(a0), sin(a0)) * radius,
			center + Vector2(cos(a1), sin(a1)) * radius,
			inner,
			outer.lerp(end_color, t0),
			outer.lerp(end_color, t1)
		)


func add_ring(
	center: Vector2, radius: float, width: float, color: Color, segments: int = 32
) -> void:
	var inner: float = maxf(0.0, radius - width * 0.5)
	var outer: float = radius + width * 0.5
	for i in segments:
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		_add_quad(
			center + d0 * inner,
			center + d0 * outer,
			center + d1 * outer,
			center + d1 * inner,
			color
		)


func add_line(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var along: Vector2 = to - from
	if along.length_squared() <= 0.0:
		return
	var side: Vector2 = along.normalized().orthogonal() * width * 0.5
	_add_quad(from - side, from + side, to + side, to - side, color)


## Linha por vários pontos; closed liga o último ao primeiro. Uma cor por ponto
## (colors vazio = color em todos), para o rastro que some aos poucos.
func add_polyline(
	line: PackedVector2Array,
	width: float,
	color: Color,
	closed: bool = false,
	point_colors := PackedColorArray()
) -> void:
	var count: int = line.size() if closed else line.size() - 1
	for i in count:
		var j: int = (i + 1) % line.size()
		var c: Color = color if point_colors.is_empty() else point_colors[j]
		add_line(line[i], line[j], width, c)


## Desenha tudo no CanvasItem (dentro do _draw dele), num comando só.
func draw(canvas_item: RID) -> void:
	if points.is_empty():
		return
	var indices := PackedInt32Array()
	indices.resize(points.size())
	for i in points.size():
		indices[i] = i
	RenderingServer.canvas_item_add_triangle_array(canvas_item, indices, points, colors)


func _add_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	add_triangle(a, b, c, color, color, color)
	add_triangle(a, c, d, color, color, color)
