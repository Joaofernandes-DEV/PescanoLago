class_name FollowCamera
extends Camera3D
## Câmera em terceira pessoa atrás do barco (Fase 5): segue com suavização, vira
## com atraso para acompanhar a direção do barco, olha um pouco à frente e abre
## o campo de visão com a velocidade. Parâmetros em presentation.json, camera.

var target: BoatController
var _distance: float
var _height: float
var _follow_speed: float
var _yaw_follow: float
var _look_ahead: float
var _look_height: float
var _base_fov: float
var _fov_boost: float
var _heading := Vector3.FORWARD


func setup(cfg: Dictionary, p_target: BoatController) -> void:
	target = p_target
	_distance = float(cfg["distance_m"])
	_height = float(cfg["height_m"])
	_follow_speed = float(cfg["follow_speed"])
	_yaw_follow = float(cfg["yaw_follow"])
	_look_ahead = float(cfg["look_ahead_m"])
	_look_height = float(cfg["look_height_m"])
	_base_fov = float(cfg["fov_deg"])
	_fov_boost = float(cfg["fov_speed_boost_deg"])
	fov = _base_fov
	snap()


func _desired_position() -> Vector3:
	return target.global_position - _heading * _distance + Vector3.UP * _height


func _look_point() -> Vector3:
	return target.global_position + _heading * _look_ahead + Vector3.UP * _look_height


func snap() -> void:
	_heading = _flat(target.forward())
	global_position = _desired_position()
	look_at(_look_point(), Vector3.UP)


func step(dt: float) -> void:
	if target == null:
		return
	var turn: float = clampf(_yaw_follow * dt, 0.0, 1.0)
	_heading = _flat(_heading.slerp(_flat(target.forward()), turn))
	var weight: float = clampf(_follow_speed * dt, 0.0, 1.0)
	global_position = global_position.lerp(_desired_position(), weight)
	look_at(_look_point(), Vector3.UP)
	var speed_ratio: float = clampf(
		absf(target.speed_m_s) / maxf(target.max_speed(), 0.01), 0.0, 1.0
	)
	fov = lerpf(fov, _base_fov + _fov_boost * speed_ratio, weight)


static func _flat(v: Vector3) -> Vector3:
	var flat := Vector3(v.x, 0.0, v.z)
	return flat.normalized() if flat.length() > 0.0001 else Vector3.FORWARD
