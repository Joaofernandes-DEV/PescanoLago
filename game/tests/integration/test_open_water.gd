extends GdUnitTestSuite
## Água aberta (P-36): parado longe dos cardumes, o jogador lança onde quiser. Os
## peixes estão espalhados: a mordida demora mais, as espécies não comuns são
## mais raras e nenhum cardume é gasto. Só no modo manual.

const MANUAL: Dictionary = {"manual_navigation": true}
const STEP_S: float = 0.05

var db: ContentDB


func before() -> void:
	db = TestContent.db()


func _session(seed_value: int) -> DaySession:
	return DaySession.new(db, PlayerState.new_game(db), 1, Rng.new(seed_value), MANUAL)


func _wait_for(session: DaySession, wanted: DaySession.Stage) -> float:
	var start := session.clock.elapsed_s
	while session.stage != wanted and not session.is_over():
		session.tick(STEP_S)
	return session.clock.elapsed_s - start


func test_stopping_away_from_schools_allows_casting() -> void:
	var session := _session(1)
	assert_bool(session.in_open_water).is_false()
	assert_bool(session.stop_in_open_water()).is_true()
	assert_int(session.stage).is_equal(DaySession.Stage.AT_SCHOOL)
	assert_bool(session.in_open_water).is_true()
	assert_bool(session.can_cast()).is_true()
	var types: Array = session.drain_events().map(func(e: Dictionary) -> String: return e["type"])
	assert_array(types).contains(["open_water"])
	# Já parado: não entra de novo.
	assert_bool(session.stop_in_open_water()).is_false()


func test_simulated_mode_has_no_open_water() -> void:
	var session := DaySession.new(db, PlayerState.new_game(db), 1, Rng.new(1))
	assert_bool(session.stop_in_open_water()).is_false()
	assert_int(session.stage).is_equal(DaySession.Stage.SEARCHING)


func test_bite_takes_longer_in_open_water() -> void:
	# Média de muitas sementes (os dois caminhos sorteiam em ordens diferentes: o
	# cardume sorteia o tamanho antes).
	var school_s := 0.0
	var open_s := 0.0
	for seed_value in 200:
		var at_school := _session(seed_value)
		at_school.reach_school(4.0)
		at_school.cast(1.0)
		_wait_for(at_school, DaySession.Stage.WAITING_BITE)
		school_s += _wait_for(at_school, DaySession.Stage.BITE)
		var open := _session(seed_value)
		open.stop_in_open_water()
		open.cast(1.0, false)
		_wait_for(open, DaySession.Stage.WAITING_BITE)
		open_s += _wait_for(open, DaySession.Stage.BITE)
	var factor := float(db.economy["fishing"]["open_water"]["wait_multiplier"])
	assert_float(open_s / school_s).is_between(factor * 0.85, factor * 1.15)


func test_open_water_bite_reports_the_time_left() -> void:
	var session := _session(3)
	session.stop_in_open_water()
	assert_float(session.bite_in_s).is_equal(-1.0)
	session.cast(1.0, false)
	_wait_for(session, DaySession.Stage.WAITING_BITE)
	var first := session.bite_in_s
	assert_float(first).is_greater(0.0)
	session.tick(1.0)
	assert_float(session.bite_in_s).is_equal_approx(first - 1.0, 0.0001)


func test_catch_in_open_water_keeps_the_boat_ready_and_spends_no_school() -> void:
	var session := _session(5)
	session.stop_in_open_water()
	session.cast(1.0, false)
	_wait_for(session, DaySession.Stage.BITE)
	session.hook()
	var steps := 0
	while session.stage == DaySession.Stage.FIGHTING and steps < 4000:
		session.set_reeling(session.tension_game.tension < 0.5)
		session.tick(STEP_S)
		steps += 1
	_wait_for(session, DaySession.Stage.AT_SCHOOL)
	assert_int(session.stage).is_equal(DaySession.Stage.AT_SCHOOL)
	assert_bool(session.in_open_water).is_true()
	assert_bool(session.can_cast()).is_true()
	assert_int(session.fish_left_in_school()).is_equal(0)


func test_uncommon_fish_are_rarer_in_open_water() -> void:
	var school_uncommon := 0
	var open_uncommon := 0
	for seed_value in 300:
		school_uncommon += _uncommon_bite(seed_value, false)
		open_uncommon += _uncommon_bite(seed_value, true)
	assert_int(open_uncommon).is_less(school_uncommon)


func _uncommon_bite(seed_value: int, open_water: bool) -> int:
	var session := _session(seed_value)
	if open_water:
		session.stop_in_open_water()
	else:
		session.reach_school(4.0)
	session.cast(1.0, not open_water)
	_wait_for(session, DaySession.Stage.BITE)
	session.hook()
	var fish := session.hooked_fish()
	if fish == null:
		return 0
	return 1 if db.species(fish.species_id)["rarity"] != "common" else 0


func test_leaving_open_water_is_not_leaving_a_school() -> void:
	var session := _session(1)
	session.stop_in_open_water()
	session.drain_events()
	assert_bool(session.leave_school()).is_true()
	assert_int(session.stage).is_equal(DaySession.Stage.SEARCHING)
	assert_bool(session.in_open_water).is_false()
	var types: Array = session.drain_events().map(func(e: Dictionary) -> String: return e["type"])
	assert_array(types).not_contains(["school_left"])
	# Depois, um cardume de verdade volta às regras normais.
	session.reach_school(5.0)
	assert_bool(session.in_open_water).is_false()
	assert_int(session.fish_left_in_school()).is_greater(0)
