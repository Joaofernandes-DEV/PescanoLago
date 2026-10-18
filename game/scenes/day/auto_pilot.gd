class_name AutoPilot
extends RefCounted
## Piloto automático da cena 3D: usa o mesmo PlayerBot do simulador, mas joga
## pela entrada virtual do DayController (acelerar, virar, mirar, segurar e
## soltar a ação), passando pelo mesmo caminho que o jogador humano.
## Usado no teste de cena, no teste de fumaça da build e no GIF de evidência.

var bot: PlayerBot
var _reaction_s: float = 0.0
var _waiting_hook: bool = false
var _target_power: float = -1.0


func _init(p_bot: PlayerBot) -> void:
	bot = p_bot


func drive(c: DayController, _dt: float) -> void:
	var s := c.session
	c.input_throttle = 0.0
	c.input_steer = 0.0
	c.input_action_held = false
	match s.stage:
		DaySession.Stage.SEARCHING:
			if s.livewell.count() > 0 and (s.livewell.is_full() or _late_in_day(s)):
				_steer_to(c, c.dock_point, 0.0)
			else:
				var nearest: int = c.schools.nearest(c.boat.global_position)
				_steer_to(c, c.schools.positions[nearest], _stop_distance(c))
		DaySession.Stage.AT_SCHOOL:
			if s.livewell.is_full():
				_steer_to(c, c.dock_point, 0.0)
			elif s.can_cast():
				_cast(c)
		DaySession.Stage.BITE:
			if not _waiting_hook:
				_waiting_hook = true
				_reaction_s = bot.reaction_time_s()
			if s.bite_elapsed_s() >= _reaction_s:
				_waiting_hook = false
				c.input_action_held = true
		DaySession.Stage.FIGHTING:
			c.input_action_held = bot.decide_reeling(s.tension_game)
	if s.stage != DaySession.Stage.BITE:
		_waiting_hook = false


## Mira no cardume e segura a ação até a força desejada; soltar faz o lançamento.
func _cast(c: DayController) -> void:
	var school: Vector3 = c.schools.positions[c.engaged_school]
	c.input_aim_point = school
	if _target_power < 0.0:
		var aim_m: float = c.session.school_distance_m() * bot.aim_factor()
		_target_power = clampf(aim_m / c.session.rod_range_m(), 0.05, 1.0)
	if c.cast_charge < _target_power:
		c.input_action_held = true
	else:
		_target_power = -1.0


func _stop_distance(c: DayController) -> float:
	return c.session.rod_range_m() * 0.7


func _late_in_day(s: DaySession) -> bool:
	return s.clock.remaining_s() < 20.0


func _steer_to(c: DayController, target: Vector3, stop_distance: float) -> void:
	var boat := c.boat
	var to_target := Vector3(
		target.x - boat.global_position.x, 0.0, target.z - boat.global_position.z
	)
	var distance: float = to_target.length()
	if distance < 0.01:
		return
	var angle: float = boat.forward().signed_angle_to(to_target, Vector3.UP)
	# Leme proporcional ao ângulo, descontando a guinada que o barco já tem (sem zigue-zague).
	c.input_steer = -clampf((angle - boat.yaw_rate_rad_s * 0.4) * 2.0, -1.0, 1.0)
	var braking_distance: float = boat.stopping_distance(0.6) + stop_distance
	if distance > braking_distance:
		c.input_throttle = 1.0 if absf(angle) < 1.2 else 0.35
	elif boat.speed_m_s > 0.3:
		c.input_throttle = -0.6
