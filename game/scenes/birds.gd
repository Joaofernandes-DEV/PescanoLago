class_name Birds
extends Node3D
## Garças sobrevoando a Margem Rasa (GDD: "juncos, pássaros"). Cada uma faz uma
## órbita suave sobre o lago, com a altura ondulando, e bate as asas com pausas
## de planeio. Só visual: avança por advance(dt), como a água.

const HERON_SCENE: String = "res://assets/models/props/bird_heron.glb"

var herons: Array[Node3D] = []
var time_s: float = 0.0

var _cfg: Dictionary
var _orbits: Array[Dictionary] = []


## cfg: presentation.json, birds. shore_radius_m: raio da margem do lago.
func setup(cfg: Dictionary, shore_radius_m: float) -> void:
	_cfg = cfg
	var scene: PackedScene = load(HERON_SCENE)
	var count: int = int(cfg["count"])
	var radius_range: Array = cfg["orbit_radius_m"]
	var height_range: Array = cfg["height_m"]
	for i in count:
		var t: float = float(i) / float(maxi(count, 1))
		var angle: float = TAU * t + 0.7
		var spread: float = fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)
		var orbit_r: float = lerpf(float(radius_range[0]), float(radius_range[1]), spread)
		var center_r: float = shore_radius_m * 0.55
		(
			_orbits
			. append(
				{
					"center": Vector2(cos(angle), sin(angle)) * center_r,
					"radius": orbit_r,
					"height": lerpf(float(height_range[0]), float(height_range[1]), 1.0 - spread),
					"omega": float(cfg["speed_m_s"]) / orbit_r * (1.0 if i % 2 == 0 else -1.0),
					"phase": TAU * spread,
				}
			)
		)
		var heron: Node3D = scene.instantiate()
		add_child(heron)
		herons.append(heron)
	advance(0.0)


func advance(dt: float) -> void:
	time_s += dt
	var flap_rad: float = deg_to_rad(float(_cfg["flap_deg"]))
	var flap_w: float = TAU * float(_cfg["flap_hz"])
	for i in herons.size():
		var orbit: Dictionary = _orbits[i]
		var a: float = float(orbit["phase"]) + float(orbit["omega"]) * time_s
		var center: Vector2 = orbit["center"]
		var r: float = float(orbit["radius"])
		var pos := center + Vector2(cos(a), sin(a)) * r
		var height: float = float(orbit["height"]) + sin(time_s * 0.3 + float(i)) * 1.5
		var heron := herons[i]
		heron.position = Vector3(pos.x, height, pos.y)
		# Direção do voo = tangente da órbita (+Z do modelo é a frente).
		var sign_w: float = signf(float(orbit["omega"]))
		var tangent := Vector2(-sin(a), cos(a)) * sign_w
		heron.rotation = Vector3(0.0, atan2(tangent.x, tangent.y), -sign_w * 0.25)
		# Bate as asas e plana de vez em quando.
		var glide: float = clampf(sin(time_s * 0.45 + float(i) * 1.3) * 2.0 + 0.6, 0.0, 1.0)
		var wing: float = sin(time_s * flap_w + float(i)) * flap_rad * glide
		_set_wing(heron, "SM_wing_left", -wing)
		_set_wing(heron, "SM_wing_right", wing)


func wing_angle(index: int) -> float:
	var wing := herons[index].find_child("SM_wing_left", true, false) as Node3D
	return wing.rotation.z


func _set_wing(heron: Node3D, wing_name: String, angle: float) -> void:
	var wing := heron.find_child(wing_name, true, false) as Node3D
	if wing != null:
		wing.rotation.z = angle
