class_name BoatController
extends Node3D
## Barco pilotado: aceleração, curva e arrasto da água, preso dentro do lago.
## Recebe throttle/steer (-1 a 1) de quem estiver pilotando (jogador ou piloto
## automático) e avança só em step(dt), para o mesmo código servir aos testes.

## Distância do centro do casco até a popa (canoa de 4 m do Blender).
const STERN_OFFSET_M: float = 2.0

var throttle: float = 0.0
var steer: float = 0.0
var speed_m_s: float = 0.0
var model: Node3D

var _max_speed: float
var _acceleration: float
var _turn_rate_rad: float
var _drag: float
var _limit_radius: float
var _bob_time: float = 0.0


## nav: presentation.json, navigation. O motor (melhoria) multiplica a velocidade.
func setup(nav: Dictionary, motor_speed_factor: float, limit_radius_m: float) -> void:
	_max_speed = float(nav["base_speed_m_s"]) * motor_speed_factor
	_acceleration = float(nav["acceleration_m_s2"])
	_turn_rate_rad = deg_to_rad(float(nav["turn_rate_deg_s"]))
	_drag = float(nav["water_drag"])
	_limit_radius = limit_radius_m


func set_model(scene: PackedScene) -> void:
	model = scene.instantiate()
	add_child(model)


func max_speed() -> float:
	return _max_speed


## Frente do modelo (+Z na Godot, "MODEL_FRONT"; −Y no Blender).
func forward() -> Vector3:
	return global_transform.basis.z.normalized()


func is_stopped(threshold_m_s: float) -> bool:
	return absf(speed_m_s) <= threshold_m_s


func step(dt: float) -> void:
	var target: float = clampf(throttle, -1.0, 1.0) * _max_speed
	var rate: float = _acceleration if absf(throttle) > 0.0 else _drag
	speed_m_s = move_toward(speed_m_s, target, rate * dt)
	var grip: float = clampf(absf(speed_m_s) / maxf(_max_speed, 0.01) + 0.35, 0.0, 1.0)
	rotate_y(-clampf(steer, -1.0, 1.0) * _turn_rate_rad * grip * dt)
	position += forward() * speed_m_s * dt
	var flat := Vector2(position.x, position.z)
	if flat.length() > _limit_radius:
		flat = flat.normalized() * _limit_radius
		position.x = flat.x
		position.z = flat.y
		speed_m_s *= 0.5
	_bob(dt)


func _bob(dt: float) -> void:
	if model == null:
		return
	_bob_time += dt
	model.position.y = sin(_bob_time * 1.7) * 0.04
	model.rotation.z = sin(_bob_time * 1.3) * 0.03


## Popa do barco (de onde sai a esteira), na linha d'água.
func stern_point() -> Vector3:
	return global_position - forward() * STERN_OFFSET_M


## Posição global de um ponto de encaixe do modelo (LOC_rod_tip, LOC_seat...).
func attach_point(point_name: String) -> Vector3:
	var node := model.find_child(point_name, true, false) as Node3D if model else null
	return node.global_position if node else global_position
