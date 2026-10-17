class_name AutoPlayer
extends RefCounted
## Joga um DaySession inteiro com um PlayerBot: mira no cardume, fisga no seu
## tempo de reação, controla a tensão e volta ao cais quando o viveiro enche.
## Base dos testes de integração e do simulador de balanceamento.

var bot: PlayerBot
var _reaction_s: float = 0.0
var _waiting_hook: bool = false


func _init(p_bot: PlayerBot) -> void:
	bot = p_bot


func play_day(session: DaySession, step_s: float) -> Dictionary:
	while not session.is_over():
		_act(session)
		session.tick(step_s)
	return session.result


func _act(session: DaySession) -> void:
	match session.stage:
		DaySession.Stage.AT_SCHOOL:
			if session.livewell.is_full():
				session.go_to_dock()
			elif session.can_cast():
				var aim_m: float = session.school_distance_m() * bot.aim_factor()
				session.cast(minf(1.0, aim_m / session.rod_range_m()))
		DaySession.Stage.BITE:
			if not _waiting_hook:
				_waiting_hook = true
				_reaction_s = bot.reaction_time_s()
			if session.bite_elapsed_s() >= _reaction_s:
				_waiting_hook = false
				session.hook()
		DaySession.Stage.FIGHTING:
			session.set_reeling(bot.decide_reeling(session.tension_game))
	if session.stage != DaySession.Stage.BITE:
		_waiting_hook = false
