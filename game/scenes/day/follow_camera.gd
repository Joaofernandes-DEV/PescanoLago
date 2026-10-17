class_name FollowCamera
extends Camera3D
## Câmera em terceira pessoa que segue o barco por trás, suavizada.

var target: BoatController
var _distance: float
var _height: float
var _follow_speed: float


func setup(cfg: Dictionary, p_target: BoatController) -> void:
	target = p_target
	_distance = float(cfg["distance_m"])
	_height = float(cfg["height_m"])
	_follow_speed = float(cfg["follow_speed"])
	fov = float(cfg["fov_deg"])
	snap()


func _desired_position() -> Vector3:
	return target.global_position - target.forward() * _distance + Vector3.UP * _height


func snap() -> void:
	global_position = _desired_position()
	look_at(target.global_position + target.forward() * 4.0, Vector3.UP)


func step(dt: float) -> void:
	if target == null:
		return
	var weight: float = clampf(_follow_speed * dt, 0.0, 1.0)
	global_position = global_position.lerp(_desired_position(), weight)
	look_at(target.global_position + target.forward() * 4.0, Vector3.UP)
