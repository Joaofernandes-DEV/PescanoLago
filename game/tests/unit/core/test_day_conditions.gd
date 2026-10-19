extends GdUnitTestSuite
## Clima e eventos do dia (Fase 6, P-31): sorteio determinístico, dias fixos,
## névoa permanente, efeitos na mordida, na procura e nos raros, casco e farol.

var db: ContentDB
var mvp: ContentDB


func before() -> void:
	db = TestContent.full_db()
	mvp = TestContent.db()


func _state() -> PlayerState:
	return PlayerState.new_game(db)


func _conditions(day_number: int, seed_value: int, state: PlayerState = null) -> DayConditions:
	var player: PlayerState = state if state != null else _state()
	var day_def: Dictionary = db.day(day_number)
	return DayConditions.new(
		db, day_def, float(day_def["duration_s"]), Loadout.new(db, player), Rng.new(seed_value)
	)


## Condições com um clima e eventos escolhidos (para testar os efeitos).
func _with(weather: String, events: Array[Dictionary], state: PlayerState) -> DayConditions:
	var conditions := _conditions(1, 1, state)
	conditions.weather = weather
	conditions.events = events
	for weather_type: Dictionary in db.economy["weather"]["types"]:
		if weather_type["id"] == weather:
			conditions._weather = weather_type
	return conditions


func _cfg(event_id: String) -> Dictionary:
	return db.economy["events"][event_id]


func test_mvp_rolls_nothing_and_keeps_sunny_days() -> void:
	assert_bool(DayConditions.rolls(mvp)).is_false()
	assert_bool(DayConditions.rolls(db)).is_true()
	var conditions := DayConditions.new(
		mvp, mvp.day(1), 240.0, Loadout.new(mvp, PlayerState.new_game(mvp)), null
	)
	assert_str(conditions.weather).is_equal("sun")
	assert_array(conditions.events).is_empty()
	assert_float(conditions.bite_wait_factor(10.0)).is_equal(1.0)
	assert_float(conditions.search_time_factor(10.0)).is_equal(1.0)
	assert_float(conditions.rare_multiplier(10.0)).is_equal(1.0)


func test_same_seed_same_day() -> void:
	var a := _conditions(12, 77)
	var b := _conditions(12, 77)
	assert_str(a.weather).is_equal(b.weather)
	assert_array(a.events).is_equal(b.events)


func test_weather_follows_the_weights() -> void:
	var counts := {}
	for seed_value in 2000:
		var weather := _conditions(12, seed_value).weather
		counts[weather] = int(counts.get(weather, 0)) + 1
	# Pesos: sol 45, nublado 30, chuva 17, tempestade 8 (de 100).
	assert_int(int(counts["sun"])).is_between(800, 1000)
	assert_int(int(counts["storm"])).is_between(110, 220)


func test_poco_fundo_days_have_a_storm_and_the_island_has_fog_all_day() -> void:
	assert_str(_conditions(24, 3).weather).is_equal("storm")
	var island := _conditions(23, 3)
	var duration := float(db.day(23)["duration_s"])
	assert_bool(island.is_active("fog", 0.0)).is_true()
	assert_bool(island.is_active("fog", duration - 1.0)).is_true()


func test_events_happen_inside_the_day() -> void:
	var seen := {}
	for seed_value in 300:
		var conditions := _conditions(12, seed_value)
		var duration := float(db.day(12)["duration_s"])
		for event: Dictionary in conditions.events:
			seen[event["id"]] = true
			assert_float(float(event["start_s"])).is_greater_equal(0.0)
			assert_float(float(event["end_s"])).is_less_equal(duration)
			assert_float(float(event["end_s"])).is_greater(float(event["start_s"]))
			if event["id"] == "net":
				assert_bool(event.has("spot")).is_true()
	assert_bool(seen.has("frenzy") and seen.has("fog") and seen.has("net")).is_true()


func test_frenzy_speeds_up_bites_only_while_it_lasts() -> void:
	var frenzy: Array[Dictionary] = [{"id": "frenzy", "start_s": 50.0, "end_s": 60.0}]
	var conditions := _with("sun", frenzy, _state())
	assert_float(conditions.bite_wait_factor(49.0)).is_equal(1.0)
	assert_float(conditions.bite_wait_factor(55.0)).is_equal(
		float(_cfg("frenzy")["bite_wait_factor"])
	)
	assert_float(conditions.bite_wait_factor(60.0)).is_equal(1.0)


func test_a_stronger_hull_takes_the_storm_better() -> void:
	var none: Array[Dictionary] = []
	var state := _state()
	var weak := _with("storm", none, state).search_time_factor(10.0)
	state.upgrade_levels["hull"] = 5
	var strong := _with("storm", none, state).search_time_factor(10.0)
	assert_float(weak).is_greater(strong)
	assert_float(strong).is_greater(1.0)
	# Na chuva, o casco não muda nada.
	var rain := _with("rain", none, state).search_time_factor(10.0)
	state.upgrade_levels["hull"] = 1
	assert_float(_with("rain", none, state).search_time_factor(10.0)).is_equal(rain)


func test_fog_is_hard_without_sonar_and_lights_help() -> void:
	var fog: Array[Dictionary] = [{"id": "fog", "start_s": 0.0, "end_s": 100.0}]
	var state := _state()
	var blind := _with("sun", fog, state).search_time_factor(10.0)
	assert_float(blind).is_equal(float(_cfg("fog")["search_time_factor"]))
	state.upgrade_levels["sonar"] = 2
	var sonar := _with("sun", fog, state).search_time_factor(10.0)
	assert_float(sonar).is_less(blind)
	state.upgrade_levels["lights"] = 5
	assert_float(_with("sun", fog, state).search_time_factor(10.0)).is_less(sonar)
	# Raros mais frequentes na névoa (GDD).
	assert_float(_with("sun", fog, state).rare_multiplier(10.0)).is_equal(
		float(_cfg("fog")["rare_multiplier"])
	)


func test_net_makes_the_search_longer() -> void:
	var net: Array[Dictionary] = [{"id": "net", "start_s": 0.0, "end_s": 100.0}]
	assert_float(_with("sun", net, _state()).search_time_factor(10.0)).is_equal(
		float(_cfg("net")["search_time_factor"])
	)


func test_changes_between_reports_starts_and_ends() -> void:
	var events: Array[Dictionary] = [{"id": "frenzy", "start_s": 50.0, "end_s": 60.0}]
	var conditions := _with("sun", events, _state())
	var changes := conditions.changes_between(49.0, 51.0)
	assert_int((changes["started"] as Array).size()).is_equal(1)
	assert_int((changes["ended"] as Array).size()).is_equal(0)
	changes = conditions.changes_between(59.0, 61.0)
	assert_int((changes["ended"] as Array).size()).is_equal(1)


func test_the_session_announces_the_island_fog_at_dawn() -> void:
	var state := _state()
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 4
	var session := DaySession.new(db, state, 23, Rng.new(9))
	var types: Array[String] = []
	for event in session.drain_events():
		types.append(String(event["type"]))
	assert_array(types).contains(["event_started"])
	assert_str(session.conditions.weather).is_not_empty()


func test_a_full_lake_day_records_its_weather() -> void:
	var state := _state()
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 2
	var session := DaySession.new(db, state, 9, Rng.new(4))
	while not session.is_over():
		session.tick(1.0)
	assert_str(String(session.result["weather"])).is_equal(session.conditions.weather)
