extends GdUnitTestSuite
## Integração: um dia inteiro (DaySession) e a cadeia
## pesca → viveiro → venda → compra de melhoria → efeito na pesca.

var db: ContentDB
var step_s: float


func before() -> void:
	db = TestContent.db()
	step_s = float(db.sim_profiles["step_s"])


func _play(
	state: PlayerState,
	day_number: int,
	seed: int,
	bot_id: String = "skilled",
	content: ContentDB = null
) -> DaySession:
	var source := content if content != null else db
	var rng := Rng.new(seed)
	var session := DaySession.new(source, state, day_number, rng)
	AutoPlayer.new(PlayerBot.new(source.bot_profile(bot_id), rng)).play_day(session, step_s)
	return session


func _count(events: Array[Dictionary], event_type: String) -> int:
	var total := 0
	for event in events:
		if event["type"] == event_type:
			total += 1
	return total


## Tique até a sessão chegar ao estágio pedido (ou acabar o dia).
func _tick_until(session: DaySession, target: DaySession.Stage) -> void:
	while session.stage != target and not session.is_over():
		if session.can_cast():
			session.cast(1.0)
		session.tick(step_s)


func test_full_day_is_deterministic() -> void:
	var a := _play(PlayerState.new_game(db), 1, 2026)
	var b := _play(PlayerState.new_game(db), 1, 2026)
	assert_dict(a.result).is_equal(b.result)
	assert_array(a.drain_events()).is_equal(b.drain_events())


func test_regression_day_1_with_fixed_seed() -> void:
	# Referência gravada na Fase 2 (atualizada após a afinação por simulação). Se mudar
	# sem mudança intencional de regra ou de dados, algo quebrou; se a mudança for
	# intencional, atualize aqui e registre no LOG.
	# Fase 6: o resultado ganhou o clima do dia (no MVP, sempre sol); os números não mudaram.
	var expected := {
		"day": 1,
		"weather": "sun",
		"stars": 2,
		"score": 296,
		"fish": 8,
		"coins_from_sales": 290,
		"star_reward": 120,
		"goal_met": true,
	}
	var session := _play(PlayerState.new_game(db), 1, 2)
	assert_dict(session.result).is_equal(expected)


func test_day_end_updates_player_state() -> void:
	var state := PlayerState.new_game(db)
	var session := _play(state, 1, 2)
	assert_bool(session.is_over()).is_true()
	assert_int(state.stars_of(1)).is_equal(int(session.result["stars"]))
	assert_int(state.coins).is_equal(
		int(session.result["coins_from_sales"]) + int(session.result["star_reward"])
	)
	assert_int(state.total_sales).is_equal(int(session.result["coins_from_sales"]))
	assert_int(session.livewell.count()).is_equal(0)
	var album_total := 0
	for entry: Dictionary in state.album.values():
		album_total += int(entry["caught"])
	assert_int(album_total).is_equal(int(session.result["fish"]))


func test_replay_without_improvement_pays_no_stars() -> void:
	var state := PlayerState.new_game(db)
	_play(state, 1, 2)
	var best := state.stars_of(1)
	var replay := _play(state, 1, 2)
	if int(replay.result["stars"]) <= best:
		assert_int(int(replay.result["star_reward"])).is_equal(0)
	assert_int(state.stars_of(1)).is_greater_equal(best)


func test_each_cast_spends_one_natural_bait() -> void:
	var state := PlayerState.new_game(db)
	var session := _play(state, 1, 5)
	var casts := _count(session.drain_events(), "cast")
	assert_int(casts).is_greater(0)
	assert_int(state.bait_count("worm")).is_equal(20 - casts)


func test_no_bait_no_fishing() -> void:
	var state := PlayerState.new_game(db)
	state.bait_inventory["worm"] = 0
	var session := _play(state, 1, 5)
	assert_int(int(session.result["fish"])).is_equal(0)
	assert_int(int(session.result["stars"])).is_equal(0)
	assert_int(_count(session.drain_events(), "cast")).is_equal(0)


func test_full_livewell_sends_boat_to_dock() -> void:
	var docs := TestContent.docs()
	docs["boat_upgrades"]["upgrades"][2]["levels"][0]["capacity"] = 2
	var small := ContentDB.new(docs)
	var state := PlayerState.new_game(small)
	var session := _play(state, 1, 3, "skilled", small)
	var events := session.drain_events()
	assert_int(_count(events, "docked")).is_greater(0)
	for event in events:
		if event["type"] == "docked":
			assert_int(int(event["coins"])).is_greater(0)


func test_cast_refused_when_livewell_is_full() -> void:
	var session := DaySession.new(db, PlayerState.new_game(db), 1, Rng.new(1))
	_tick_until(session, DaySession.Stage.AT_SCHOOL)
	for i in session.livewell.capacity:
		session.livewell.add(FishCatch.new("lambari", 0.05))
	assert_bool(session.can_cast()).is_false()
	assert_bool(session.cast(1.0)).is_false()
	assert_bool(session.go_to_dock()).is_true()


func test_bite_is_lost_without_hooking() -> void:
	var session := DaySession.new(db, PlayerState.new_game(db), 1, Rng.new(8))
	_tick_until(session, DaySession.Stage.BITE)
	session.drain_events()
	while session.stage == DaySession.Stage.BITE:
		session.tick(step_s)
	assert_int(_count(session.drain_events(), "bite_missed")).is_equal(1)


func test_commands_out_of_place_are_refused() -> void:
	var session := DaySession.new(db, PlayerState.new_game(db), 1, Rng.new(1))
	assert_int(session.stage).is_equal(DaySession.Stage.SEARCHING)
	assert_bool(session.cast(1.0)).is_false()
	assert_int(session.hook()).is_equal(Bite.Hook.MISSED)
	_tick_until(session, DaySession.Stage.BITE)
	session.hook()
	assert_int(session.stage).is_equal(DaySession.Stage.FIGHTING)
	assert_bool(session.go_to_dock()).is_false()


func test_fish_sell_buy_and_feel_the_upgrade() -> void:
	# 1) Pescar dias seguidos até juntar dinheiro para a vara de fibra de vidro (700).
	var state := PlayerState.new_game(db)
	var shop := Shop.new(db)
	var days_played := 0
	var seed := 100
	while state.coins < shop.bait_lot_price("worm") + int(db.rod("fiberglass")["cost"]):
		_play(state, 1, seed)
		seed += 1
		days_played += 1
		if state.bait_count("worm") < 10:
			assert_int(shop.buy_bait_lot(state, "worm")).is_equal(Shop.Status.OK)
		assert_int(days_played).is_less(30)
	assert_int(state.total_sales).is_greater(0)
	# 2) Comprar e equipar.
	assert_int(shop.buy_rod(state, "fiberglass")).is_equal(Shop.Status.OK)
	assert_int(shop.equip_rod(state, "fiberglass")).is_equal(Shop.Status.OK)
	# 3) Efeito: com a mesma sequência de dias, a vara nova pesca mais.
	var with_bamboo := 0
	var with_fiberglass := 0
	for trial in 20:
		var bamboo_state := PlayerState.from_dict(state.to_dict())
		bamboo_state.equipped_rod = "bamboo_grandpa"
		bamboo_state.bait_inventory["worm"] = 99
		var fiber_state := PlayerState.from_dict(state.to_dict())
		fiber_state.bait_inventory["worm"] = 99
		with_bamboo += int(_play(bamboo_state, 1, 500 + trial).result["fish"])
		with_fiberglass += int(_play(fiber_state, 1, 500 + trial).result["fish"])
	assert_int(with_fiberglass).is_greater(with_bamboo)
