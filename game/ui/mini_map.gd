class_name MiniMap
extends Control
## Mapa lateral do lago (P-30): onde o barco está, para onde aponta e por onde
## passou (rastro), o cais de Porto Manso e as construções do cais; com sonar, o
## alcance dele e os cardumes que ele acha (GDD: o sonar "mostra cardumes e raros
## no mapa"). Norte para cima. Desenhado em 2D, sem segunda câmera (o celular
## está no limite de desempenho).

const WATER := Color(0.16, 0.42, 0.5, 0.82)
const SHORE := Color(0.93, 0.86, 0.68, 0.95)
const OBSTACLE := Color(0.55, 0.4, 0.28, 0.95)
const DOCK := Color(0.98, 0.78, 0.35)
const BOAT := Color(1.0, 0.55, 0.15)
const TRAIL := Color(1.0, 1.0, 1.0, 0.55)
const SONAR := Color(0.6, 1.0, 0.85, 0.35)
const SCHOOL := Color(0.85, 1.0, 0.95)
const NORTH := Color(0.25, 0.18, 0.1)

## Tamanho do mapa em pixels (lado).
var size_px: float = 190.0
var shore_radius_m: float = 110.0
var dock := Vector2.ZERO
var obstacles: Array[Dictionary] = []
## Barco agora: posição (x, z), direção (rad, 0 = +z) e rastro (posições antigas).
var boat := Vector2.ZERO
var heading_rad: float = 0.0
var trail: Array[Vector2] = []
var sonar_range_m: float = 0.0
## Cardumes que o sonar acha agora (x, z).
var schools: Array[Vector2] = []

var _trail_max: int = 40
var _trail_every_s: float = 0.5
var _trail_clock_s: float = 0.0
var _time: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## cfg: presentation.json, minimap. dock_point e obstáculos vêm do cenário.
func setup(
	cfg: Dictionary, p_shore_radius_m: float, dock_point: Vector3, p_obstacles: Array[Dictionary]
) -> void:
	size_px = float(cfg["size_px"])
	_trail_max = int(cfg["trail_points"])
	_trail_every_s = float(cfg["trail_every_s"])
	custom_minimum_size = Vector2(size_px, size_px)
	size = custom_minimum_size
	shore_radius_m = p_shore_radius_m
	dock = Vector2(dock_point.x, dock_point.z)
	obstacles = p_obstacles


## Atualiza o barco, o sonar e os cardumes achados; o rastro guarda um ponto a
## cada trail_every_s.
func update_state(
	dt: float,
	boat_position: Vector3,
	forward: Vector3,
	p_sonar_range_m: float,
	school_positions: Array[Vector3]
) -> void:
	_time += dt
	boat = Vector2(boat_position.x, boat_position.z)
	heading_rad = atan2(forward.x, forward.z)
	sonar_range_m = p_sonar_range_m
	schools.clear()
	if sonar_range_m > 0.0:
		for school in school_positions:
			var at := Vector2(school.x, school.z)
			if at.distance_to(boat) <= sonar_range_m:
				schools.append(at)
	_trail_clock_s += dt
	if trail.is_empty() or _trail_clock_s >= _trail_every_s:
		_trail_clock_s = 0.0
		trail.append(boat)
		while trail.size() > _trail_max:
			trail.remove_at(0)
	queue_redraw()


## Ponto do mundo (x, z) no mapa, em pixels deste Control.
func to_map(world: Vector2) -> Vector2:
	return Vector2(size_px, size_px) * 0.5 + world * _scale()


func _scale() -> float:
	return (size_px * 0.5 - 6.0) / shore_radius_m


func _draw() -> void:
	var center := Vector2(size_px, size_px) * 0.5
	var lake_px: float = shore_radius_m * _scale()
	draw_circle(center, lake_px + 5.0, SHORE)
	draw_circle(center, lake_px, WATER)
	for box in obstacles:
		_draw_box(box)
	draw_circle(to_map(dock), 5.0, DOCK)
	draw_circle(to_map(dock), 5.0, Color(0.3, 0.2, 0.1), false, 1.5)
	if sonar_range_m > 0.0:
		draw_circle(to_map(boat), sonar_range_m * _scale(), SONAR, false, 1.5)
	for i in range(1, trail.size()):
		var alpha: float = float(i) / float(trail.size())
		var color := TRAIL
		color.a *= alpha
		draw_line(to_map(trail[i - 1]), to_map(trail[i]), color, 2.0)
	_draw_boat()
	# Cardumes por cima da seta (um cardume perto do barco ficaria escondido).
	var pulse: float = 0.75 + 0.25 * sin(_time * 5.0)
	for school in schools:
		draw_circle(to_map(school), 5.0 * pulse, SCHOOL, false, 2.0)
		draw_circle(to_map(school), 1.8, SCHOOL)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(center.x - 5.0, 15.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, NORTH)


func _draw_box(box: Dictionary) -> void:
	var half: Vector2 = box["half"]
	var c: Vector2 = box["center"]
	var angle: float = float(box["angle"])
	var corners := PackedVector2Array()
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(to_map(c + (corner * half).rotated(angle)))
	draw_colored_polygon(corners, OBSTACLE)


## Seta do barco: ponta para onde a proa aponta.
func _draw_boat() -> void:
	var at := to_map(boat)
	var dir := Vector2(sin(heading_rad), cos(heading_rad))
	var side := Vector2(-dir.y, dir.x)
	var arrow := PackedVector2Array(
		[at + dir * 9.0, at - dir * 6.0 + side * 6.0, at - dir * 3.0, at - dir * 6.0 - side * 6.0]
	)
	draw_colored_polygon(arrow, BOAT)
	arrow.append(arrow[0])
	draw_polyline(arrow, Color(0.2, 0.1, 0.05), 1.5)
