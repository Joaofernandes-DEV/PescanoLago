class_name FollowCamera
extends Camera3D
## Câmera em terceira pessoa atrás do barco (Fase 5): segue com suavização, vira
## com atraso para acompanhar a direção do barco, olha um pouco à frente e abre
## o campo de visão com a velocidade. Parâmetros em presentation.json, camera.
##
## Câmera de perto (Fase 7): close_up(olho, alvo) leva a câmera suavemente até
## um ponto (o Tom mostrando o peixe, a caixa de isopor aberta); release_close_up()
## devolve a câmera ao barco. O seguir continua por baixo, então a volta é suave.

var target: BoatController
## 0 = atrás do barco; 1 = na câmera de perto.
var close_weight: float = 0.0
var _distance: float
var _height: float
var _follow_speed: float
var _yaw_follow: float
var _look_ahead: float
var _look_height: float
var _base_fov: float
var _fov_boost: float
var _close_blend_per_s: float
var _heading := Vector3.FORWARD
var _follow_position := Vector3.ZERO
var _close_eye := Vector3.ZERO
var _close_look := Vector3.ZERO
var _close_wanted: bool = false


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
	_close_blend_per_s = float(cfg["close_up_blend_per_s"])
	fov = _base_fov
	snap()


func _desired_position() -> Vector3:
	return target.global_position - _heading * _distance + Vector3.UP * _height


func _look_point() -> Vector3:
	return target.global_position + _heading * _look_ahead + Vector3.UP * _look_height


func snap() -> void:
	_heading = _flat(target.forward())
	_follow_position = _desired_position()
	global_position = _follow_position
	look_at(_look_point(), Vector3.UP)


## Pede a câmera de perto: olho em eye, olhando para look (mundo). Chamar a cada
## passo enquanto durar, porque o barco anda e balança.
func close_up(eye: Vector3, look: Vector3) -> void:
	_close_eye = eye
	_close_look = look
	_close_wanted = true


func release_close_up() -> void:
	_close_wanted = false


func step(dt: float) -> void:
	if target == null:
		return
	var turn: float = clampf(_yaw_follow * dt, 0.0, 1.0)
	_heading = _flat(_heading.slerp(_flat(target.forward()), turn))
	var weight: float = clampf(_follow_speed * dt, 0.0, 1.0)
	_follow_position = _follow_position.lerp(_desired_position(), weight)
	close_weight = move_toward(close_weight, 1.0 if _close_wanted else 0.0, _close_blend_per_s * dt)
	var blend: float = close_weight * close_weight * (3.0 - 2.0 * close_weight)
	global_position = _follow_position.lerp(_close_eye, blend)
	look_at(_look_point().lerp(_close_look, blend), Vector3.UP)
	var speed_ratio: float = clampf(
		absf(target.speed_m_s) / maxf(target.max_speed(), 0.01), 0.0, 1.0
	)
	fov = lerpf(fov, _base_fov + _fov_boost * speed_ratio * (1.0 - blend), weight)


static func _flat(v: Vector3) -> Vector3:
	var flat := Vector3(v.x, 0.0, v.z)
	return flat.normalized() if flat.length() > 0.0001 else Vector3.FORWARD
