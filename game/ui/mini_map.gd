class_name MiniMap
extends Control
## Mapa do lago (P-30), no estilo de carta náutica (Fase 7, Bloco A, item 5; P-38):
## moldura de madeira, terra cor de pergaminho, o contorno real da margem e a
## água em tons pela profundidade (LakeChart), com ícones para o cais, as
## construções, as manchas de vitórias-régias e as boias. Por cima, o barco (seta
## para onde a proa aponta), o rastro e, com sonar, o alcance dele e a varredura
## que gira (SonarSweep): os cardumes acendem quando o feixe passa e vão sumindo.
## Norte para cima. Pequeno no canto da tela; grande no meio dela (tecla M), com
## o nome da região, a escala e a legenda.
##
## Continua 2D e leve: a carta parada é desenhada uma vez (só muda com o tamanho)
## e cada camada vai num comando só (ShapeBatch), em vez de um por forma.

const LILY_PREFIX: String = "COL_lily"
const BUOY_PREFIX: String = "COL_buoy"
const LAND := Color(0.91, 0.85, 0.68)
const INK := Color(0.2, 0.15, 0.1)
const ISOBATH := Color(0.1, 0.18, 0.3, 0.35)
const OBSTACLE := Color(0.55, 0.4, 0.28, 0.95)
const LILY := Color(0.42, 0.7, 0.3)
const LILY_FLOWER := Color(0.96, 0.55, 0.72)
const BUOY := Color(0.86, 0.25, 0.18)
const DOCK := Color(0.98, 0.78, 0.35)
const BOAT := Color(1.0, 0.55, 0.15)
const TRAIL := Color(0.2, 0.15, 0.1, 0.7)
const SONAR := Color(0.45, 1.0, 0.6)
const WOOD_DARK := Color(0.36, 0.22, 0.12)
const WOOD := Color(0.52, 0.33, 0.18)
const WOOD_LIGHT := Color(0.66, 0.45, 0.26)
const BRASS := Color(0.86, 0.7, 0.36)
const WHITE := Color(0.97, 0.95, 0.91)
const TITLE_FONT: int = 15
## Nome de cada linha da legenda do mapa grande.
const LEGEND_TEXT: Dictionary = {
	"dock": "Cais",
	"boat": "Barco",
	"sonar": "Cardume no sonar",
	"lily": "Vitórias-régias",
	"buoy": "Boias",
}

## Lado do mapa em pixels (o pequeno ou o grande).
var size_px: float = 190.0
## Mapa grande, no meio da tela (tecla InputSetup.MAP_VIEW).
var expanded: bool = false
## Nome da região, no alto do mapa grande.
var title: String = ""
## Cor da água (presentation.json, region_looks, map_water): a base dos tons.
var water_color := Color(0.16, 0.42, 0.5):
	set(value):
		water_color = value
		_chart_dirty = true
		queue_redraw()
var shore_radius_m: float = 110.0
var dock := Vector2.ZERO
var obstacles: Array[Dictionary] = []
## Contorno da margem e isóbatas do cenário (sem ela, a margem é o círculo do jogo).
var chart: LakeChart
## Barco agora: posição (x, z), direção (rad, 0 = +z) e rastro (posições antigas).
var boat := Vector2.ZERO
var heading_rad: float = 0.0
var trail: Array[Vector2] = []
var sonar_range_m: float = 0.0
var sonar := SonarSweep.new()

var _cfg: Dictionary = {}
var _trail_max: int = 40
var _trail_every_s: float = 0.5
var _trail_clock_s: float = 0.0
var _chart_batch := ShapeBatch.new()
var _chart_dirty: bool = true
var _overlay: Control
var _overlay_batch := ShapeBatch.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# O sonar e o rastro não passam da moldura.
	_overlay.clip_contents = true
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


## cfg: presentation.json, minimap. dock_point e obstáculos vêm do cenário.
func setup(
	cfg: Dictionary, p_shore_radius_m: float, dock_point: Vector3, p_obstacles: Array[Dictionary]
) -> void:
	_cfg = cfg
	_trail_max = int(cfg["trail_points"])
	_trail_every_s = float(cfg["trail_every_s"])
	sonar.setup(cfg["sonar"])
	shore_radius_m = p_shore_radius_m
	dock = Vector2(dock_point.x, dock_point.z)
	obstacles = p_obstacles
	set_expanded(false)


func set_chart(p_chart: LakeChart) -> void:
	chart = p_chart
	_chart_dirty = true
	queue_redraw()


## Troca entre o mapa pequeno e o grande (o tamanho vem de presentation.json).
func set_expanded(on: bool) -> void:
	expanded = on
	size_px = float(_cfg["big_size_px" if on else "size_px"])
	custom_minimum_size = Vector2(size_px, size_px)
	size = custom_minimum_size
	var frame: float = frame_px()
	_overlay.position = Vector2(frame, frame)
	_overlay.size = Vector2.ONE * (size_px - frame * 2.0)
	_chart_dirty = true
	queue_redraw()
	_overlay.queue_redraw()


## Atualiza o barco, o rastro (um ponto a cada trail_every_s) e a varredura do
## sonar; devolve quantos cardumes o feixe achou agora (um ping cada).
func update_state(
	dt: float,
	boat_position: Vector3,
	forward: Vector3,
	p_sonar_range_m: float,
	school_positions: Array[Vector3]
) -> int:
	boat = Vector2(boat_position.x, boat_position.z)
	heading_rad = atan2(forward.x, forward.z)
	sonar_range_m = p_sonar_range_m
	var flat: Array[Vector2] = []
	for school in school_positions:
		flat.append(Vector2(school.x, school.z))
	var echoes: int = sonar.step(dt, boat, sonar_range_m, flat)
	_trail_clock_s += dt
	if trail.is_empty() or _trail_clock_s >= _trail_every_s:
		_trail_clock_s = 0.0
		trail.append(boat)
		while trail.size() > _trail_max:
			trail.remove_at(0)
	_overlay.queue_redraw()
	return echoes


## Ponto do mundo (x, z) no mapa, em pixels deste Control.
func to_map(world: Vector2) -> Vector2:
	return Vector2(size_px, size_px) * 0.5 + world * map_scale()


## Pixels por metro.
func map_scale() -> float:
	return (size_px * 0.5 - frame_px()) / extent_m()


## Meia largura do mundo mostrado (a margem e um pouco de terra em volta).
func extent_m() -> float:
	if chart != null:
		return chart.extent_m
	return shore_radius_m + float(_cfg.get("chart_margin_m", 0.0))


func frame_px() -> float:
	return float(_cfg.get("big_frame_px" if expanded else "frame_px", 0.0))


## Tom da água na profundidade (metros): mais claro no raso, mais escuro no fundo.
func depth_color(depth_m: float) -> Color:
	var shallow: Color = water_color.lightened(float(_cfg["shallow_lighten"]))
	var deep: Color = water_color.darkened(float(_cfg["deep_darken"]))
	return shallow.lerp(deep, clampf(depth_m / float(_cfg["darkest_depth_m"]), 0.0, 1.0))


## Triângulos da carta parada (para os testes e a medição de desempenho).
func chart_triangles() -> int:
	if _chart_dirty:
		_build_chart()
	return _chart_batch.triangle_count()


func _draw() -> void:
	if _cfg.is_empty():
		return
	if _chart_dirty:
		_build_chart()
	_chart_batch.draw(get_canvas_item())
	var font: Font = get_theme_default_font()
	var rose: Vector2 = _rose_center()
	var rose_px: float = _icon_px() * 1.4
	draw_string(
		font,
		rose + Vector2(-rose_px * 0.3, -rose_px * 1.1),
		"N",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		roundi(rose_px * 0.95),
		INK
	)
	if expanded:
		_draw_big_texts(font)


# --- Carta parada -------------------------------------------------------------


func _build_chart() -> void:
	_chart_dirty = false
	var b := _chart_batch
	b.clear()
	var frame: float = frame_px()
	var inner := Rect2(Vector2.ONE * frame, Vector2.ONE * (size_px - frame * 2.0))
	_add_frame(b, inner)
	b.add_rect(inner, LAND)
	var shore_line: PackedVector2Array = _shore_polygon()
	b.add_polygon(shore_line, depth_color(0.0))
	var lines: Array[PackedVector2Array] = []
	if chart != null:
		for isobath in chart.isobaths:
			var polygon := _to_map_polygon(isobath["polygon"])
			b.add_polygon(polygon, depth_color(float(isobath["depth_m"])))
			lines.append(polygon)
	for line in lines:
		b.add_polyline(line, 1.0, ISOBATH, true)
	b.add_polyline(shore_line, 1.6 if expanded else 1.2, INK, true)
	for box in obstacles:
		_add_obstacle(b, box)
	_add_anchor(b, to_map(dock), _icon_px())
	_add_neat_line(b, inner)
	_add_rose(b, _rose_center(), _icon_px() * 1.4)
	if expanded:
		_add_scale_bar(b)
		_add_legend_icons(b)
		_add_title_plate(b)


func _shore_polygon() -> PackedVector2Array:
	if chart != null:
		return _to_map_polygon(chart.shore)
	var circle := PackedVector2Array()
	for i in 64:
		var angle: float = TAU * float(i) / 64.0
		circle.append(to_map(Vector2(cos(angle), sin(angle)) * shore_radius_m))
	return circle


func _to_map_polygon(world: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in world:
		result.append(to_map(point))
	return result


## Moldura de madeira: quatro tábuas com veios e um prego de latão em cada canto.
func _add_frame(b: ShapeBatch, inner: Rect2) -> void:
	var outer := Rect2(Vector2.ZERO, Vector2.ONE * size_px)
	var corners_out: Array[Vector2] = [
		outer.position, Vector2(outer.end.x, 0.0), outer.end, Vector2(0.0, outer.end.y)
	]
	var corners_in: Array[Vector2] = [
		inner.position,
		Vector2(inner.end.x, inner.position.y),
		inner.end,
		Vector2(inner.position.x, inner.end.y)
	]
	var shades: Array[Color] = [WOOD_LIGHT, WOOD, WOOD_DARK, WOOD]
	var frame: float = frame_px()
	for side in 4:
		var n: int = (side + 1) % 4
		var plank := PackedVector2Array(
			[corners_out[side], corners_out[n], corners_in[n], corners_in[side]]
		)
		b.add_polygon(plank, shades[side])
		# Veios: duas linhas finas ao longo da tábua.
		for k: float in [0.35, 0.7]:
			var a: Vector2 = corners_out[side].lerp(corners_in[side], k)
			var c: Vector2 = corners_out[n].lerp(corners_in[n], k)
			b.add_line(a.lerp(c, 0.08), c.lerp(a, 0.08), 1.0, Color(WOOD_DARK, 0.45))
	b.add_polyline(PackedVector2Array(corners_out), 1.5, Color(0.2, 0.12, 0.06), true)
	for corner in corners_out:
		var nail: Vector2 = corner.lerp(outer.get_center(), frame * 0.5 / (size_px * 0.5))
		b.add_circle(nail, maxf(1.5, frame * 0.18), BRASS, 8)


## Borda graduada da carta: faixas claras e escuras alternadas na beira de dentro.
func _add_neat_line(b: ShapeBatch, inner: Rect2) -> void:
	var width: float = 3.0 if expanded else 2.0
	var count: int = 12 if expanded else 8
	var piece: float = inner.size.x / float(count)
	for k in count:
		var color: Color = INK if k % 2 == 0 else WHITE
		var t: float = inner.position.x + piece * k
		b.add_rect(Rect2(t, inner.position.y, piece, width), color)
		b.add_rect(Rect2(t, inner.end.y - width, piece, width), color)
		b.add_rect(Rect2(inner.position.x, t, width, piece), color)
		b.add_rect(Rect2(inner.end.x - width, t, width, piece), color)
	b.add_polyline(
		PackedVector2Array(
			[
				inner.position,
				Vector2(inner.end.x, inner.position.y),
				inner.end,
				Vector2(inner.position.x, inner.end.y)
			]
		),
		1.0,
		INK,
		true
	)


func _add_obstacle(b: ShapeBatch, box: Dictionary) -> void:
	var half: Vector2 = box["half"]
	var c: Vector2 = box["center"]
	var box_name := String(box.get("name", ""))
	if box_name.begins_with(LILY_PREFIX):
		_add_lily(b, to_map(c), maxf(minf(half.x, half.y) * map_scale(), _icon_px() * 0.5))
		return
	if box_name.begins_with(BUOY_PREFIX):
		_add_buoy(b, to_map(c), _icon_px() * 0.45)
		return
	var corners := PackedVector2Array()
	var angle: float = float(box["angle"])
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(to_map(c + (corner * half).rotated(angle)))
	b.add_polygon(corners, OBSTACLE)


## Mancha de vitórias-régias: folha redonda com o corte e uma flor rosa.
func _add_lily(b: ShapeBatch, at: Vector2, radius: float) -> void:
	b.add_fan(at, radius, 0.35, TAU - 0.35, LILY, LILY, 12)
	b.add_circle(at + Vector2(-0.3, -0.3) * radius, radius * 0.3, LILY_FLOWER, 6)


## Boia de sinalização: vermelha, com a faixa e o contorno brancos.
func _add_buoy(b: ShapeBatch, at: Vector2, radius: float) -> void:
	b.add_circle(at, radius + 1.0, WHITE, 10)
	b.add_circle(at, radius, BUOY, 10)
	b.add_line(at - Vector2(radius, 0.0), at + Vector2(radius, 0.0), radius * 0.5, WHITE)


## Âncora do cais (ou do trapiche) sobre um disco amarelo.
func _add_anchor(b: ShapeBatch, at: Vector2, icon: float) -> void:
	b.add_circle(at, icon * 0.75, DOCK, 14)
	b.add_ring(at, icon * 0.75, 1.2, INK, 14)
	var s: float = icon * 0.5
	var w: float = maxf(1.2, icon * 0.11)
	b.add_ring(at + Vector2(0.0, -0.62 * s), 0.18 * s, w, INK, 8)
	b.add_line(at + Vector2(0.0, -0.45 * s), at + Vector2(0.0, 0.75 * s), w, INK)
	b.add_line(at + Vector2(-0.4 * s, -0.2 * s), at + Vector2(0.4 * s, -0.2 * s), w, INK)
	b.add_line(at + Vector2(0.0, 0.75 * s), at + Vector2(-0.6 * s, 0.3 * s), w, INK)
	b.add_line(at + Vector2(0.0, 0.75 * s), at + Vector2(0.6 * s, 0.3 * s), w, INK)


## Rosa dos ventos: estrela de quatro pontas, a do norte meio escura, meio clara.
func _add_rose(b: ShapeBatch, at: Vector2, radius: float) -> void:
	b.add_circle(at, radius * 0.55, Color(WHITE, 0.6), 12)
	b.add_ring(at, radius * 0.55, 1.0, INK, 16)
	for k in 4:
		var dir := Vector2.UP.rotated(PI * 0.5 * k)
		var side: Vector2 = dir.orthogonal() * radius * 0.22
		var tip: Vector2 = at + dir * radius
		b.add_triangle(at, tip, at + side, INK, INK, INK)
		b.add_triangle(at, at - side, tip, WHITE, WHITE, WHITE)


func _rose_center() -> Vector2:
	var icon: float = _icon_px() * 1.4
	var frame: float = frame_px()
	return Vector2(frame + icon + 6.0, frame + icon * 1.9 + 4.0)


## Tamanho de referência dos ícones (pixels).
func _icon_px() -> float:
	return 16.0 if expanded else 9.0


# --- Mapa grande: escala, legenda e nome da região -------------------------------


## Placa escura no alto da moldura, atrás do nome da região.
func _add_title_plate(b: ShapeBatch) -> void:
	if title.is_empty():
		return
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT).x
	var frame: float = frame_px()
	var plate := Rect2(
		Vector2((size_px - width) * 0.5 - 12.0, 2.0), Vector2(width + 24.0, frame - 4.0)
	)
	b.add_rect(plate, WOOD_DARK)
	b.add_circle(plate.position + Vector2(5.0, plate.size.y * 0.5), 1.8, BRASS, 6)
	b.add_circle(plate.end - Vector2(5.0, plate.size.y * 0.5), 1.8, BRASS, 6)


func _scale_bar_origin() -> Vector2:
	var frame: float = frame_px()
	return Vector2(frame + 18.0, size_px - frame - 22.0)


func _add_scale_bar(b: ShapeBatch) -> void:
	var at: Vector2 = _scale_bar_origin()
	var length: float = float(_cfg["scale_bar_m"]) * map_scale()
	b.add_rect(Rect2(at - Vector2(2, 2), Vector2(length + 4.0, 9.0)), INK)
	b.add_rect(Rect2(at, Vector2(length * 0.5, 5.0)), WHITE)
	b.add_rect(Rect2(at + Vector2(length * 0.5, 0.0), Vector2(length * 0.5, 5.0)), INK)


func _legend_rows() -> Array[String]:
	var rows: Array[String] = ["dock", "boat", "sonar"]
	for box in obstacles:
		var box_name := String(box.get("name", ""))
		if box_name.begins_with(LILY_PREFIX) and not rows.has("lily"):
			rows.append("lily")
		elif box_name.begins_with(BUOY_PREFIX) and not rows.has("buoy"):
			rows.append("buoy")
	return rows


func _legend_rect() -> Rect2:
	var frame: float = frame_px()
	var rows: int = _legend_rows().size() + 2
	var box := Vector2(170.0, 22.0 * rows + 12.0)
	return Rect2(Vector2.ONE * (size_px - frame - 10.0) - box, box)


func _add_legend_icons(b: ShapeBatch) -> void:
	var rect: Rect2 = _legend_rect()
	b.add_rect(rect, Color(LAND, 0.93))
	b.add_polyline(
		PackedVector2Array(
			[
				rect.position,
				Vector2(rect.end.x, rect.position.y),
				rect.end,
				Vector2(rect.position.x, rect.end.y)
			]
		),
		1.0,
		INK,
		true
	)
	var rows: Array[String] = _legend_rows()
	for k in rows.size():
		var at: Vector2 = rect.position + Vector2(18.0, 17.0 + 22.0 * k)
		match rows[k]:
			"dock":
				_add_anchor(b, at, 13.0)
			"boat":
				_add_arrow(b, at, PI * 0.5, 1.0)
			"sonar":
				b.add_circle(at, 6.0, Color(0.05, 0.12, 0.08), 12)
				_add_fish(b, at, 5.0, SONAR)
			"lily":
				_add_lily(b, at, 7.0)
			"buoy":
				_add_buoy(b, at, 5.0)
	var depths: Array[float] = _legend_depths()
	var swatch: float = (rect.size.x - 24.0) / float(depths.size())
	for k in depths.size():
		var at: Vector2 = rect.position + Vector2(12.0 + swatch * k, 22.0 * rows.size() + 26.0)
		b.add_rect(Rect2(at, Vector2(swatch - 2.0, 12.0)), depth_color(depths[k]))


## Profundidades da legenda: a água rasa e cada isóbata do lago.
func _legend_depths() -> Array[float]:
	var depths: Array[float] = [0.0]
	if chart != null:
		for isobath in chart.isobaths:
			depths.append(float(isobath["depth_m"]))
	return depths


func _draw_big_texts(font: Font) -> void:
	var rect: Rect2 = _legend_rect()
	var rows: Array[String] = _legend_rows()
	for k in rows.size():
		var at: Vector2 = rect.position + Vector2(34.0, 22.0 + 22.0 * k)
		draw_string(font, at, LEGEND_TEXT[rows[k]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
	var depth_at: Vector2 = rect.position + Vector2(12.0, 22.0 * rows.size() + 20.0)
	draw_string(font, depth_at, "Profundidade", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
	var depths: Array[float] = _legend_depths()
	var swatch: float = (rect.size.x - 24.0) / float(depths.size())
	for k in depths.size():
		var at: Vector2 = rect.position + Vector2(12.0 + swatch * k, 22.0 * rows.size() + 51.0)
		var label: String = "raso" if k == 0 else "%d m" % roundi(depths[k])
		draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
	var bar: Vector2 = _scale_bar_origin()
	var bar_text: String = "%d m" % roundi(float(_cfg["scale_bar_m"]))
	draw_string(font, bar + Vector2(0.0, -6.0), bar_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
	if not title.is_empty():
		var frame: float = frame_px()
		draw_string(
			font,
			Vector2(0.0, frame * 0.5 + TITLE_FONT * 0.35),
			title,
			HORIZONTAL_ALIGNMENT_CENTER,
			size_px,
			TITLE_FONT,
			WHITE
		)


# --- Camada que muda a cada quadro: rastro, sonar e barco -----------------------


func _draw_overlay() -> void:
	if _cfg.is_empty():
		return
	var b := _overlay_batch
	b.clear()
	var shift: Vector2 = -_overlay.position
	var points := PackedVector2Array()
	for point in trail:
		points.append(to_map(point) + shift)
	# Rastro tracejado, como a rota riscada na carta, mais forte perto do barco.
	for i in range(1, points.size()):
		if i % 2 == 0:
			continue
		var color := TRAIL
		color.a *= float(i) / float(points.size())
		b.add_line(points[i - 1], points[i], 1.6 if expanded else 1.2, color)
	var at: Vector2 = to_map(boat) + shift
	if sonar_range_m > 0.0:
		_add_sweep(b, at)
	_add_arrow(b, at, heading_rad, 1.6 if expanded else 1.0)
	b.draw(_overlay.get_canvas_item())


func _add_sweep(b: ShapeBatch, at: Vector2) -> void:
	var radius: float = sonar_range_m * map_scale()
	b.add_circle(at, radius, Color(SONAR, 0.07), 32)
	b.add_ring(at, radius, 1.2, Color(SONAR, 0.6), 40)
	var end: float = sonar.angle_rad
	b.add_fan(
		at,
		radius,
		end - sonar.trail_rad,
		end,
		Color(SONAR, 0.12),
		Color(SONAR, 0.0),
		10,
		Color(SONAR, 0.4)
	)
	b.add_line(at, at + Vector2(cos(end), sin(end)) * radius, 1.5, Color(SONAR, 0.9))
	var shift: Vector2 = -_overlay.position
	for blip in sonar.blips:
		var glow: float = sonar.glow(blip)
		var spot: Vector2 = to_map(blip["at"]) + shift
		var blip_px: float = 5.0 if expanded else 3.0
		b.add_ring(spot, blip_px * (3.0 - glow * 2.0), 1.2, Color(SONAR, glow * 0.8), 16)
		if expanded:
			_add_fish(b, spot, blip_px, Color(SONAR, glow))
		else:
			b.add_circle(spot, blip_px * 0.8, Color(SONAR, glow), 8)


## Peixinho do eco do sonar: corpo oval e rabo, virado para a direita.
func _add_fish(b: ShapeBatch, at: Vector2, size: float, color: Color) -> void:
	var body := PackedVector2Array()
	for i in 10:
		var angle: float = TAU * float(i) / 10.0
		body.append(at + Vector2(cos(angle) * size, sin(angle) * size * 0.5))
	b.add_polygon(body, color)
	var tail: Vector2 = at - Vector2(size * 0.9, 0.0)
	b.add_triangle(
		tail,
		tail - Vector2(size * 0.6, size * 0.5),
		tail - Vector2(size * 0.6, -size * 0.5),
		color,
		color,
		color
	)


## Seta do barco: ponta para onde a proa aponta (heading 0 = +z, para baixo no mapa).
func _add_arrow(b: ShapeBatch, at: Vector2, heading: float, grow: float) -> void:
	var dir := Vector2(sin(heading), cos(heading))
	var side := Vector2(-dir.y, dir.x)
	var arrow := PackedVector2Array(
		[
			at + dir * 9.0 * grow,
			at - dir * 6.0 * grow + side * 6.0 * grow,
			at - dir * 3.0 * grow,
			at - dir * 6.0 * grow - side * 6.0 * grow
		]
	)
	b.add_polygon(arrow, BOAT)
	b.add_polyline(arrow, 1.5, Color(0.2, 0.1, 0.05), true)
