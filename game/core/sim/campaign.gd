class_name Campaign
extends RefCounted
## Simula a campanha do MVP com um jogador simulado: joga os dias em ordem,
## repete o dia sem estrela, repõe iscas e compra melhorias seguindo um plano
## (sim_profiles.json, campaign). Base do balanceamento por simulação.

var _db: ContentDB
var _plan: Dictionary
var _step_s: float
var _shop: Shop


func _init(db: ContentDB) -> void:
	_db = db
	_plan = db.sim_profiles["campaign"]
	_step_s = float(db.sim_profiles["step_s"])
	_shop = Shop.new(db)


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
			_prepare_bait(state, day_number)
			var session := DaySession.new(_db, state, day_number, rng)
			AutoPlayer.new(bot).play_day(session, _step_s)
			attempts += 1
			stars = int(session.result["stars"])
			var record: Dictionary = session.result.duplicate()
			record["attempt"] = attempts
			record["session"] = sessions.size() + 1
			record["coins_after"] = state.coins
			sessions.append(record)
			_buy_from_plan(state, sessions.size(), purchases)
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


## Escolhe a isca do dia (plano por dia, como um jogador lendo a meta) e repõe o estoque.
func _prepare_bait(state: PlayerState, day_number: int) -> void:
	var day_baits: Dictionary = _plan["day_baits"]
	var bait_id: String = day_baits.get(str(day_number), _plan["default_bait"])
	var reserve: int = int(_plan["bait_reserve"])
	while state.bait_count(bait_id) < reserve:
		if _shop.buy_bait_lot(state, bait_id) != Shop.Status.OK:
			break
	if _shop.equip_bait(state, bait_id) != Shop.Status.OK:
		_shop.equip_bait(state, _plan["default_bait"])


## Compra na ordem do plano; para no primeiro item que ainda não dá para pagar.
func _buy_from_plan(state: PlayerState, session_index: int, purchases: Array[Dictionary]) -> void:
	for item: Dictionary in _plan["purchases"]:
		var kind: String = item["kind"]
		var item_id: String = item["id"]
		if _already_done(state, kind, item_id, int(item.get("level", 0))):
			continue
		var coins_before: int = state.coins
		var status: Shop.Status = Shop.Status.NOT_AVAILABLE
		if kind == "rod":
			status = _shop.buy_rod(state, item_id)
			if status == Shop.Status.OK:
				_shop.equip_rod(state, item_id)
		else:
			status = _shop.buy_upgrade(state, item_id)
		if status != Shop.Status.OK:
			return
		var record: Dictionary = {
			"session": session_index,
			"kind": kind,
			"id": item_id,
			"level": state.level_of(item_id) if kind == "upgrade" else 0,
			"cost": coins_before - state.coins,
		}
		purchases.append(record)


func _already_done(state: PlayerState, kind: String, item_id: String, level: int) -> bool:
	if kind == "rod":
		return state.owned_rods.has(item_id)
	return state.level_of(item_id) >= level
