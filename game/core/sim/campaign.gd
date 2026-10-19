class_name Campaign
extends RefCounted
## Simula a campanha com um jogador simulado: joga os dias em ordem, repete o dia
## sem estrela, repõe iscas e compra seguindo um plano (sim_profiles.json,
## campaigns, do perfil de versão em uso; ver ShoppingPlan). Quando o próximo dia
## espera uma melhoria do barco (regra da região, P-26), repete o último dia
## jogável para juntar moedas. Base do balanceamento por simulação.

var _db: ContentDB
var _plan: Dictionary
var _step_s: float
var _shopping: ShoppingPlan


func _init(db: ContentDB) -> void:
	_db = db
	_plan = db.sim_profiles["campaigns"][db.release["id"]]
	_step_s = float(db.sim_profiles["step_s"])
	_shopping = ShoppingPlan.new(db, _plan)


func run(bot_id: String, seed_value: int) -> Dictionary:
	var state := PlayerState.new_game(_db)
	var rng := Rng.new(seed_value)
	var bot := PlayerBot.new(_db.bot_profile(bot_id), rng)
	var sessions: Array[Dictionary] = []
	var purchases: Array[Dictionary] = []
	var day_number: int = 1
	var stuck: bool = false
	while day_number <= _db.day_count() and not stuck:
		var farmed: int = 0
		while (
			not Progression.can_play(_db, state, day_number)
			and farmed < int(_plan["max_farm_sessions"])
		):
			_play(state, day_number - 1, bot, rng, sessions, purchases, true)
			farmed += 1
		var stars: int = 0
		var attempts: int = 0
		if Progression.can_play(_db, state, day_number):
			while stars == 0 and attempts < int(_plan["max_attempts_per_day"]):
				attempts += 1
				var record: Dictionary = _play(state, day_number, bot, rng, sessions, purchases)
				record["attempt"] = attempts
				stars = int(record["stars"])
		stuck = stars == 0
		if not stuck:
			day_number += 1
	return {
		"bot": bot_id,
		"seed": seed_value,
		"completed": not stuck,
		"sessions": sessions,
		"purchases": purchases,
		"final_coins": state.coins,
		"final_state": state.to_dict(),
	}


## Joga um dia e faz as compras do plano. farm: repetição para juntar moedas.
func _play(
	state: PlayerState,
	day_number: int,
	bot: PlayerBot,
	rng: Rng,
	sessions: Array[Dictionary],
	purchases: Array[Dictionary],
	farm: bool = false
) -> Dictionary:
	_shopping.prepare_bait(state, day_number)
	var session := DaySession.new(_db, state, day_number, rng)
	AutoPlayer.new(bot).play_day(session, _step_s)
	var record: Dictionary = session.result
	record["session"] = sessions.size() + 1
	record["coins_after"] = state.coins
	record["farm"] = farm
	record["attempt"] = 0
	sessions.append(record)
	# Próximo dia: o seguinte se este deu estrela (e não é repetição), senão o mesmo.
	var next_day: int = 0
	if bool(_plan["reserve_next_day_bait"]):
		next_day = day_number + 1 if int(record["stars"]) > 0 and not farm else day_number
		next_day = mini(next_day, _db.day_count())
	_shopping.buy(state, sessions.size(), purchases, next_day)
	return record
