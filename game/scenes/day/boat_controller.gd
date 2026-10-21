class_name BoatController
extends Node3D
## Barco pilotado com física de barco pequeno (Fase 5). Recebe throttle/steer
## (-1 a 1) de quem pilota (jogador ou piloto automático) e avança só em
## step(dt), em subpassos fixos, para o mesmo código servir aos testes.
##
## Dinâmica no plano (aceleração por unidade de massa):
## - empuxo do motor na direção da proa (a ré tem menos força);
## - arrasto longitudinal linear + quadrático. O quadrático é calibrado para a
##   velocidade final com o motor no máximo ser exatamente a velocidade máxima;
## - arrasto lateral da quilha: o barco desliza um pouco nas curvas (deriva);
## - guinada com inércia: o leme tem autoridade proporcional à velocidade e o
##   motor de popa ainda vira o barco devagar quando ele está quase parado.
## Colisão: dois círculos no casco (proa e popa) contra a margem do lago e contra
## caixas de obstáculo (cais etc.), com restituição e atrito.
## Atitude (só visual): o casco amostra a água (LakeWater) em seis pontos (proa,
## popa e três pares nos bordos) e segue a superfície com molas amortecidas; a
## proa sobe ao acelerar e o barco inclina para fora nas curvas.
## Casco seco: o contorno interno da canoa (is_inside_hull) é o mesmo perfil do
## gerador do Blender (tools/blender/make_greybox_boat.py, section()); o shader da
## água descarta a superfície dentro dele, então a água não aparece no barco.

signal bumped(impact_m_s: float)

## Distância do centro do casco até a popa (canoa de 4 m do Blender).
const STERN_OFFSET_M: float = 2.0
const HULL_LENGTH_M: float = 4.0
const HULL_BEAM_M: float = 1.1
## Espessura do costado e expoentes do perfil da seção (make_greybox_boat.py).
const HULL_WALL_M: float = 0.035
const HULL_PROFILE := Vector2(2.2, 0.55)
const SUBSTEP_S: float = 1.0 / 120.0

var throttle: float = 0.0
var steer: float = 0.0
## Velocidade para a frente (m/s; negativa de ré).
var speed_m_s: float = 0.0
## Velocidade de lado (deriva), positiva para a direita (estibordo) do barco.
var lateral_speed_m_s: float = 0.0
var yaw_rate_rad_s: float = 0.0
## Velocidade no mundo (x, z).
var velocity := Vector2.ZERO
var model: Node3D
## Água em que o casco flutua (opcional: sem ela, fica na linha d'água).
var water: LakeWater
## Obstáculos: caixas no plano {"center": Vector2, "half": Vector2, "angle": float}.
var obstacles: Array[Dictionary] = []
var collisions: int = 0

var _max_speed: float
var _thrust: float
var _reverse_ratio: float
var _linear_drag: float
var _quadratic_drag: float
var _lateral_drag: float
var _turn_rate_rad: float
var _yaw_response: float
var _prop_turn: float
var _limit_radius: float
var _hull_radius: float
var _hull_offset: float
var _restitution: float
var _wall_friction: float
var _float: Dictionary
var _last_accel: float = 0.0
var _heave: float = 0.0
var _heave_vel: float = 0.0
var _pitch: float = 0.0
var _pitch_vel: float = 0.0
var _roll: float = 0.0
var _roll_vel: float = 0.0


## nav: presentation.json, navigation. O motor (melhoria) multiplica a velocidade máxima.
func setup(nav: Dictionary, motor_speed_factor: float, limit_radius_m: float) -> void:
	_max_speed = float(nav["base_speed_m_s"]) * motor_speed_factor
	_thrust = float(nav["acceleration_m_s2"]) * motor_speed_factor
	_reverse_ratio = float(nav["reverse_thrust_ratio"])
	_linear_drag = float(nav["linear_drag"])
	_quadratic_drag = (_thrust - _linear_drag * _max_speed) / (_max_speed * _max_speed)
	assert(
		_quadratic_drag > 0.0, "BoatController: linear_drag alto demais para a velocidade máxima"
	)
	_lateral_drag = float(nav["lateral_drag"])
	_turn_rate_rad = deg_to_rad(float(nav["turn_rate_deg_s"]))
	_yaw_response = float(nav["yaw_response"])
	_prop_turn = float(nav["prop_turn"])
	_hull_radius = float(nav["hull_circle_radius_m"])
	_hull_offset = float(nav["hull_circle_offset_m"])
	_restitution = float(nav["restitution"])
	_wall_friction = float(nav["wall_friction"])
	_float = nav["flotation"]
	_limit_radius = limit_radius_m


func set_model(scene: PackedScene) -> void:
	model = scene.instantiate()
	Palette.apply(model)
	add_child(model)


## Um empurrão de lado no casco (alguém pulou para dentro): o barco balança e
## volta sozinho, como depois de uma onda.
func rock(roll_rad_s: float) -> void:
	_roll_vel += roll_rad_s


func max_speed() -> float:
	return _max_speed


## Frente do modelo (+Z na Godot, "MODEL_FRONT"; −Y no Blender).
func forward() -> Vector3:
	return global_transform.basis.z.normalized()


func is_stopped(threshold_m_s: float) -> bool:
	return velocity.length() <= threshold_m_s


func step(dt: float) -> void:
	var remaining: float = dt
	while remaining > 0.0:
		var h: float = minf(remaining, SUBSTEP_S)
		_integrate(h)
		_resolve_collisions()
		remaining -= h
	_update_attitude(dt)


## Distância para parar a partir da velocidade atual, com a ré `reverse` (0 a 1)
## e o mesmo modelo de arrasto. O piloto automático usa para frear na hora certa.
func stopping_distance(reverse: float = 1.0) -> float:
	var v: float = absf(speed_m_s)
	var distance: float = 0.0
	var h: float = SUBSTEP_S * 4.0
	while v > 0.05:
		var decel: float = (
			reverse * _thrust * _reverse_ratio + _quadratic_drag * v * v + _linear_drag * v
		)
		v = maxf(0.0, v - decel * h)
		distance += v * h
	return distance


func _integrate(h: float) -> void:
	var f := _flat_forward()
	var right := Vector2(-f.y, f.x)
	var v_long: float = velocity.dot(f)
	var v_lat: float = velocity.dot(right)
	var power: float = clampf(throttle, -1.0, 1.0)
	var thrust: float = power * _thrust * (1.0 if power >= 0.0 else _reverse_ratio)
	var a_long: float = thrust - _quadratic_drag * v_long * absf(v_long) - _linear_drag * v_long
	var a_lat: float = -_lateral_drag * v_lat * absf(v_lat) - _lateral_drag * v_lat
	velocity += (f * a_long + right * a_lat) * h
	_last_accel = a_long
	var authority: float = clampf(v_long / _max_speed + _prop_turn * absf(power), -1.0, 1.0)
	var target_rate: float = -clampf(steer, -1.0, 1.0) * _turn_rate_rad * authority
	yaw_rate_rad_s += (target_rate - yaw_rate_rad_s) * minf(1.0, _yaw_response * h)
	rotate_y(yaw_rate_rad_s * h)
	position.x += velocity.x * h
	position.z += velocity.y * h
	var f_now := _flat_forward()
	speed_m_s = velocity.dot(f_now)
	lateral_speed_m_s = velocity.dot(Vector2(-f_now.y, f_now.x))


func _flat_forward() -> Vector2:
	var f := forward()
	return Vector2(f.x, f.z).normalized()


## Centros dos dois círculos do casco (proa e popa), no plano.
func _hull_circles() -> Array[Vector2]:
	var center := Vector2(position.x, position.z)
	var f := _flat_forward() * _hull_offset
	return [center + f, center - f]


func _resolve_collisions() -> void:
	for circle in _hull_circles():
		var distance: float = circle.length()
		var limit: float = _limit_radius - _hull_radius
		if distance > limit:
			_push(-circle / distance, distance - limit)
		for obstacle in obstacles:
			var hit := _circle_vs_box(circle, obstacle)
			if hit.z > 0.0:
				_push(Vector2(hit.x, hit.y), hit.z)


## (normal x, normal z, penetração) do círculo contra a caixa; penetração 0 se não toca.
func _circle_vs_box(circle: Vector2, box: Dictionary) -> Vector3:
	var angle: float = float(box["angle"])
	var half: Vector2 = box["half"]
	var local: Vector2 = (circle - Vector2(box["center"])).rotated(-angle)
	var closest := Vector2(clampf(local.x, -half.x, half.x), clampf(local.y, -half.y, half.y))
	var delta := local - closest
	var distance: float = delta.length()
	if distance >= _hull_radius:
		return Vector3.ZERO
	var normal: Vector2
	if distance > 0.0001:
		normal = delta / distance
	else:
		# Centro dentro da caixa: sai pelo lado mais próximo.
		var gap := half - local.abs()
		normal = Vector2(signf(local.x), 0.0) if gap.x < gap.y else Vector2(0.0, signf(local.y))
		distance = -minf(gap.x, gap.y)
	normal = normal.rotated(angle)
	return Vector3(normal.x, normal.y, _hull_radius - distance)


## Empurra o barco para fora do obstáculo e rebate a velocidade contra a normal.
func _push(normal: Vector2, depth: float) -> void:
	position.x += normal.x * depth
	position.z += normal.y * depth
	var v_n: float = velocity.dot(normal)
	if v_n >= 0.0:
		return
	var tangent: Vector2 = velocity - normal * v_n
	velocity = tangent * (1.0 - _wall_friction) - normal * v_n * _restitution
	yaw_rate_rad_s *= 0.5
	collisions += 1
	bumped.emit(-v_n)


func _update_attitude(dt: float) -> void:
	if model == null:
		return
	var heave_target: float = 0.0
	var pitch_target: float = 0.0
	var roll_target: float = 0.0
	if water != null:
		var f := forward()
		var left := Vector3.UP.cross(f).normalized()
		var h_bow: float = _water_at(f * (HULL_LENGTH_M * 0.4))
		var h_stern: float = _water_at(-f * (HULL_LENGTH_M * 0.4))
		# Três pares nos bordos (frente, meio e trás): o balanço é a média deles.
		var h_port: float = 0.0
		var h_star: float = 0.0
		for along: float in [-0.25, 0.0, 0.25]:
			var station: Vector3 = f * (HULL_LENGTH_M * along)
			h_port += _water_at(station + left * (HULL_BEAM_M * 0.5)) / 3.0
			h_star += _water_at(station - left * (HULL_BEAM_M * 0.5)) / 3.0
		heave_target = (h_bow + h_stern + 3.0 * (h_port + h_star)) / 8.0
		pitch_target = atan2(h_bow - h_stern, HULL_LENGTH_M * 0.8)
		roll_target = atan2(h_port - h_star, HULL_BEAM_M)
	var speed_ratio: float = clampf(speed_m_s / _max_speed, -1.0, 1.0)
	pitch_target += deg_to_rad(float(_float["trim_deg"])) * speed_ratio
	pitch_target += deg_to_rad(float(_float["accel_pitch_deg_per_m_s2"])) * _last_accel
	var turn_ratio: float = yaw_rate_rad_s / maxf(_turn_rate_rad, 0.01)
	roll_target += deg_to_rad(float(_float["bank_deg"])) * turn_ratio * speed_ratio
	var k: float = float(_float["stiffness"])
	var c: float = float(_float["damping"])
	# A mola anda em passos curtos, como a física: um quadro longo (uma travada ao
	# carregar, a aba do navegador em segundo plano) faria a conta explodir.
	var remaining: float = dt
	while remaining > 0.0:
		var h: float = minf(remaining, SUBSTEP_S)
		_heave_vel += (k * (heave_target - _heave) - c * _heave_vel) * h
		_heave += _heave_vel * h
		_pitch_vel += (k * (pitch_target - _pitch) - c * _pitch_vel) * h
		_pitch += _pitch_vel * h
		_roll_vel += (k * (roll_target - _roll) - c * _roll_vel) * h
		_roll += _roll_vel * h
		remaining -= h
	model.position.y = _heave
	# Proa (+Z) para cima é rotação negativa em X; bombordo (+X) para cima é rotação positiva em Z.
	model.rotation = Vector3(-_pitch, 0.0, _roll)


## Meia largura interna do casco na posição t ao longo dele (0 = meio, ±1 = pontas).
static func interior_half_width(t: float) -> float:
	var profile: float = pow(maxf(0.02, 1.0 - pow(absf(t), HULL_PROFILE.x)), HULL_PROFILE.y)
	return HULL_BEAM_M * 0.5 * profile - HULL_WALL_M


## O ponto do mundo está dentro da canoa (no contorno interno do casco, como o
## shader da água calcula)?
func is_inside_hull(world_point: Vector3) -> bool:
	var local: Vector3 = model.global_transform.affine_inverse() * world_point
	var t: float = local.z / (HULL_LENGTH_M * 0.5)
	return absf(t) < 1.0 and absf(local.x) < interior_half_width(t)


## Arfagem (m), inclinação da proa e balanço (rad) do casco agora.
func attitude() -> Vector3:
	return Vector3(_heave, _pitch, _roll)


func _water_at(offset: Vector3) -> float:
	var point: Vector3 = global_position + offset
	return water.height_at(point.x, point.z)


## Popa do barco (de onde sai a esteira), na linha d'água.
func stern_point() -> Vector3:
	return global_position - forward() * STERN_OFFSET_M


## Posição global de um ponto de encaixe do modelo (LOC_rod_tip, LOC_seat...).
func attach_point(point_name: String) -> Vector3:
	var node := model.find_child(point_name, true, false) as Node3D if model else null
	return node.global_position if node else global_position
