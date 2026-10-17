class_name SchoolField
extends RefCounted
## Onde estão os cardumes no lago. As regras de cada cardume (quantos peixes,
## quais espécies) ficam no DaySession; aqui só há posições e visibilidade.
## As ondulações são desenhadas pelo shader da água.

var positions: Array[Vector3] = []
var _cfg: Dictionary
var _rng: Rng


## cfg: presentation.json, schools. O Rng é próprio da cena (não muda o sorteio das regras).
func _init(cfg: Dictionary, rng: Rng) -> void:
	_cfg = cfg
	_rng = rng


func populate(boat_position: Vector3) -> void:
	positions.clear()
	for i in int(_cfg["active"]):
		positions.append(_random_position(boat_position))


func respawn(index: int, boat_position: Vector3) -> void:
	positions[index] = _random_position(boat_position)


func nearest(from: Vector3) -> int:
	var best: int = -1
	var best_distance: float = INF
	for i in positions.size():
		var distance: float = flat_distance(from, positions[i])
		if distance < best_distance:
			best = i
			best_distance = distance
	return best


static func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Dados para o shader: x, z, raio e intensidade. O cardume aparece quando está
## perto o bastante para ver as ondulações ou dentro do alcance do sonar.
func shader_data(boat_position: Vector3, sonar_range_m: float) -> PackedVector4Array:
	var data := PackedVector4Array()
	var radius: float = float(_cfg["radius_m"])
	var visible_m: float = maxf(float(_cfg["ripple_visible_m"]), sonar_range_m)
	for school in positions:
		var strength: float = 1.0 if flat_distance(boat_position, school) <= visible_m else 0.0
		data.append(Vector4(school.x, school.z, radius, strength))
	while data.size() < 4:
		data.append(Vector4.ZERO)
	return data


func _random_position(boat_position: Vector3) -> Vector3:
	var max_r: float = float(_cfg["spawn_max_radius_m"])
	var min_from_boat: float = float(_cfg["spawn_min_from_boat_m"])
	var candidate := Vector3.ZERO
	for attempt in 32:
		var angle: float = _rng.range_float(0.0, TAU)
		var radius: float = sqrt(_rng.next_float()) * max_r
		candidate = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if flat_distance(candidate, boat_position) >= min_from_boat:
			break
	return candidate
