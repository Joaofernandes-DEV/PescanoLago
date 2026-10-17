extends GdUnitTestSuite
## DaySession no modo de navegação manual (o jogo com barco pilotado).

const MANUAL: Dictionary = {"manual_navigation": true}

var db: ContentDB
var step_s: float


func before() -> void:
	db = TestContent.db()
	step_s = float(db.sim_profiles["step_s"])


func _session(seed_value: int) -> DaySession:
	return DaySession.new(db, PlayerState.new_game(db), 1, Rng.new(seed_value), MANUAL)


func _count(events: Array[Dictionary], event_type: String) -> int:
	var total := 0
	for event in events:
		if event["type"] == event_type:
			total += 1
	return total


func test_search_waits_for_the_player() -> void:
	var session := _session(1)
	for i in 2000:
		session.tick(step_s)
	assert_int(session.stage).is_equal(DaySession.Stage.SEARCHING)
	assert_int(_count(session.drain_events(), "school_found")).is_equal(0)


func test_reach_school_and_leave() -> void:
	var session := _session(1)
	assert_bool(session.reach_school(7.5)).is_true()
	assert_int(session.stage).is_equal(DaySession.Stage.AT_SCHOOL)
	assert_float(session.school_distance_m()).is_equal(7.5)
	assert_int(session.fish_left_in_school()).is_greater(0)
	session.update_school_distance(6.0)
	assert_float(session.school_distance_m()).is_equal(6.0)
	assert_bool(session.reach_school(3.0)).is_false()
	assert_bool(session.leave_school()).is_true()
	assert_int(session.stage).is_equal(DaySession.Stage.SEARCHING)


func test_simulated_and_manual_commands_do_not_mix() -> void:
	var manual := _session(1)
	assert_bool(manual.go_to_dock()).is_false()
	var simulated := DaySession.new(db, PlayerState.new_game(db), 1, Rng.new(1))
	assert_bool(simulated.reach_school(5.0)).is_false()
	assert_bool(simulated.arrive_at_dock()).is_false()
	assert_bool(simulated.can_dock()).is_false()


func test_arrive_at_dock_sells_the_livewell() -> void:
	var state := PlayerState.new_game(db)
	var session := DaySession.new(db, state, 1, Rng.new(1), MANUAL)
	session.reach_school(6.0)
	session.livewell.add(FishCatch.new("common_carp", 9.0))
	assert_bool(session.arrive_at_dock()).is_true()
	assert_int(session.livewell.count()).is_equal(0)
	assert_int(state.coins).is_greater(0)
	assert_int(session.stage).is_equal(DaySession.Stage.SEARCHING)


func test_cannot_dock_while_fishing() -> void:
	var session := _session(1)
	session.reach_school(6.0)
	session.cast(1.0)
	assert_bool(session.can_dock()).is_false()
	assert_bool(session.arrive_at_dock()).is_false()


func test_off_target_cast_waits_longer() -> void:
	# Mesma semente nos dois casos: só muda se a isca caiu no cardume.
	var on_target := 0.0
	var off_target := 0.0
	for seed_value in 40:
		on_target += _time_to_bite(seed_value, true)
		off_target += _time_to_bite(seed_value, false)
	var penalty := float(db.economy["fishing"]["short_cast_wait_multiplier"])
	# Tolerância pelo passo de tempo fixo (a mordida só é vista no tique seguinte).
	assert_float(off_target / on_target).is_equal_approx(penalty, 0.05)


func _time_to_bite(seed_value: int, on_target: bool) -> float:
	var session := _session(seed_value)
	session.reach_school(4.0)
	session.cast(1.0, on_target)
	while session.stage == DaySession.Stage.CASTING:
		session.tick(step_s)
	var start := session.clock.elapsed_s
	while session.stage != DaySession.Stage.BITE:
		session.tick(step_s)
	return session.clock.elapsed_s - start


func test_full_manual_day_with_auto_player() -> void:
	var state := PlayerState.new_game(db)
	var rng := Rng.new(2)
	var session := DaySession.new(db, state, 1, rng, MANUAL)
	AutoPlayer.new(PlayerBot.new(db.bot_profile("skilled"), rng)).play_day(session, step_s)
	assert_bool(session.is_over()).is_true()
	assert_int(int(session.result["fish"])).is_greater(0)
	assert_int(state.stars_of(1)).is_equal(int(session.result["stars"]))
