class_name Campaign
extends RefCounted
## Simula a campanha do MVP com um jogador simulado: joga os dias em ordem,
## repete o dia sem estrela, repõe iscas e compra melhorias seguindo um plano
## (sim_profiles.json, campaign; ver ShoppingPlan). Base do balanceamento por simulação.

var _db: ContentDB
var _plan: Dictionary
var _step_s: float
var _shopping: ShoppingPlan


func _init(db: ContentDB) -> void:
	_db = db
	_plan = db.sim_profiles["campaign"]
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
		var stars: int = 0
		var attempts: int = 0
		while stars == 0 and attempts < int(_plan["max_attempts_per_day"]):
			_shopping.prepare_bait(state, day_number)
			var session := DaySession.new(_db, state, day_number, rng)
			AutoPlayer.new(bot).play_day(session, _step_s)
			attempts += 1
			stars = int(session.result["stars"])
			var record: Dictionary = session.result.duplicate()
			record["attempt"] = attempts
			record["session"] = sessions.size() + 1
			record["coins_after"] = state.coins
			sessions.append(record)
			_shopping.buy(state, sessions.size(), purchases)
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
