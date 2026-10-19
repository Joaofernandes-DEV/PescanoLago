class_name LakeWater
extends Node
## Superfície da água do lago: dona do material do shader (water.gdshader) e da
## mesma fórmula das ondas, para quem precisa saber a altura da água num ponto
## (o barco flutua nela). O tempo da água avança só por advance(dt), então a
## superfície é a mesma no shader e no código, e os testes são determinísticos.
##
## Ondas de águas profundas: altura = soma de A·sin(k·(d·p) − ω·t + φ), com
## ω = sqrt(g·k) (relação de dispersão). Os parâmetros vêm de presentation.json.

const GRAVITY_M_S2: float = 9.81
const MAX_WAVES: int = 4
const MAX_WAKE_POINTS: int = 12

var material: ShaderMaterial
var time_s: float = 0.0

var _dirs: Array[Vector2] = []
var _k: PackedFloat32Array = PackedFloat32Array()
var _amp: PackedFloat32Array = PackedFloat32Array()
var _omega: PackedFloat32Array = PackedFloat32Array()
var _phase: PackedFloat32Array = PackedFloat32Array()
## Esteira: x, z, idade (s), intensidade.
var _wake: Array[Vector4] = []
var _wake_cfg: Dictionary
var _wake_clock_s: float = 0.0


## cfg: presentation.json, water. surface: malha da água do Blender (SM_water_surface).
func setup(cfg: Dictionary, lake_radius: float, surface: MeshInstance3D) -> void:
	_wake_cfg = cfg["wake"]
	material = ShaderMaterial.new()
	material.shader = load(LakeWorld.WATER_SHADER)
	for key: String in ["shallow_color", "deep_color", "foam_color"]:
		material.set_shader_parameter(key, PresentationConfig.color(cfg[key]))
	material.set_shader_parameter("lake_radius", lake_radius)
	material.set_shader_parameter("shore_foam_m", float(cfg["shore_foam_m"]))
	material.set_shader_parameter("fresnel_strength", float(cfg["fresnel_strength"]))
	material.set_shader_parameter("detail_strength", float(cfg["detail_strength"]))
	material.set_shader_parameter("wake_life_s", float(_wake_cfg["life_s"]))
	material.set_shader_parameter("wake_spread_m_s", float(_wake_cfg["spread_m_s"]))
	var waves: Array = cfg["waves"]
	assert(waves.size() <= MAX_WAVES, "LakeWater: no máximo %d ondas" % MAX_WAVES)
	var dir_k_amp := PackedVector4Array()
	var omega_phase := PackedVector4Array()
	for wave: Dictionary in waves:
		var angle: float = deg_to_rad(float(wave["dir_deg"]))
		var dir := Vector2(cos(angle), sin(angle))
		var k: float = TAU / float(wave["wavelength_m"])
		var omega: float = sqrt(GRAVITY_M_S2 * k)
		_dirs.append(dir)
		_k.append(k)
		_amp.append(float(wave["amplitude_m"]))
		_omega.append(omega)
		_phase.append(float(wave["phase"]))
		dir_k_amp.append(Vector4(dir.x, dir.y, k, float(wave["amplitude_m"])))
		omega_phase.append(Vector4(omega, float(wave["phase"]), 0.0, 0.0))
	while dir_k_amp.size() < MAX_WAVES:
		dir_k_amp.append(Vector4.ZERO)
		omega_phase.append(Vector4.ZERO)
	material.set_shader_parameter("wave_dir_k_amp", dir_k_amp)
	material.set_shader_parameter("wave_omega_phase", omega_phase)
	surface.material_override = material
	set_schools(PackedVector4Array())
	_upload_wake()
	_upload_time()


## Casco do barco na água: o shader não desenha a água dentro da canoa e faz
## espuma na proa conforme a velocidade (speed_ratio de 0 a 1).
func set_hull(hull: Node3D, speed_ratio: float) -> void:
	material.set_shader_parameter(
		"hull_inverse", Projection(hull.global_transform.affine_inverse())
	)
	material.set_shader_parameter(
		"hull_shape",
		Vector4(
			BoatController.HULL_BEAM_M * 0.5,
			BoatController.HULL_LENGTH_M * 0.5,
			BoatController.HULL_WALL_M,
			1.0
		)
	)
	material.set_shader_parameter("hull_profile", BoatController.HULL_PROFILE)
	material.set_shader_parameter("hull_speed", clampf(speed_ratio, 0.0, 1.0))


## Altura da água (m) no ponto (x, z) do mundo, agora.
func height_at(x: float, z: float) -> float:
	var h: float = 0.0
	for i in _k.size():
		h += _amp[i] * sin(_theta(i, x, z))
	return h


## Inclinação da água (dh/dx, dh/dz) no ponto (x, z), agora.
func slope_at(x: float, z: float) -> Vector2:
	var slope := Vector2.ZERO
	for i in _k.size():
		slope += _dirs[i] * (_amp[i] * _k[i] * cos(_theta(i, x, z)))
	return slope


func normal_at(x: float, z: float) -> Vector3:
	var slope := slope_at(x, z)
	return Vector3(-slope.x, 1.0, -slope.y).normalized()


## Maior altura possível das ondas (soma das amplitudes).
func max_wave_height() -> float:
	var total: float = 0.0
	for amplitude in _amp:
		total += amplitude
	return total


func advance(dt: float) -> void:
	time_s += dt
	for i in range(_wake.size() - 1, -1, -1):
		var point: Vector4 = _wake[i]
		point.z += dt
		if point.z >= float(_wake_cfg["life_s"]):
			_wake.remove_at(i)
		else:
			_wake[i] = point
	_wake_clock_s += dt
	_upload_time()
	_upload_wake()


## Esteira: a popa é a cabeça do "V" e deixa um ponto a cada intervalo, se o barco anda.
func trail_boat(stern: Vector3, speed_m_s: float, top_speed_m_s: float) -> void:
	var moving: bool = absf(speed_m_s) >= float(_wake_cfg["min_speed_m_s"])
	var strength: float = clampf(absf(speed_m_s) / maxf(top_speed_m_s, 0.01), 0.3, 1.0)
	material.set_shader_parameter(
		"wake_head", Vector4(stern.x, stern.z, 0.0, strength if moving else 0.0)
	)
	if not moving or _wake_clock_s < float(_wake_cfg["interval_s"]):
		return
	_wake_clock_s = 0.0
	_wake.push_front(Vector4(stern.x, stern.z, 0.0, strength))
	if _wake.size() > MAX_WAKE_POINTS:
		_wake.resize(MAX_WAKE_POINTS)
	_upload_wake()


func wake_points() -> int:
	return _wake.size()


func set_sky_color(color: Color) -> void:
	material.set_shader_parameter("sky_color", color)


func set_schools(data: PackedVector4Array) -> void:
	var padded := PackedVector4Array(data)
	while padded.size() < 4:
		padded.append(Vector4.ZERO)
	material.set_shader_parameter("schools", padded)


func _theta(i: int, x: float, z: float) -> float:
	return _k[i] * (_dirs[i].x * x + _dirs[i].y * z) - _omega[i] * time_s + _phase[i]


func _upload_time() -> void:
	material.set_shader_parameter("water_time", time_s)


func _upload_wake() -> void:
	var data := PackedVector4Array(_wake)
	while data.size() < MAX_WAKE_POINTS:
		data.append(Vector4.ZERO)
	material.set_shader_parameter("wake", data)
