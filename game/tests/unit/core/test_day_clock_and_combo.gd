extends GdUnitTestSuite
## DayClock (fases do GDD: 0:00, 1:30, 3:30, 5:00) e Combo (P-04).


func _clock(duration: float) -> DayClock:
	return DayClock.new(duration, TestContent.db().economy["day_phases"])


func test_phases_follow_game_design_table() -> void:
	var clock := _clock(360.0)
	assert_str(clock.phase()).is_equal("dawn")
	clock.tick(89.9)
	assert_str(clock.phase()).is_equal("dawn")
	clock.tick(0.1)
	assert_str(clock.phase()).is_equal("day")
	clock.tick(120.0)
	assert_str(clock.phase()).is_equal("dusk")
	clock.tick(90.0)
	assert_str(clock.phase()).is_equal("night")


func test_clock_stops_at_duration() -> void:
	var clock := _clock(240.0)
	clock.tick(239.0)
	assert_bool(clock.is_over()).is_false()
	assert_float(clock.remaining_s()).is_equal_approx(1.0, 0.0001)
	clock.tick(10.0)
	assert_bool(clock.is_over()).is_true()
	assert_float(clock.elapsed_s).is_equal(240.0)


func test_negative_dt_is_ignored() -> void:
	var clock := _clock(240.0)
	clock.tick(-5.0)
	assert_float(clock.elapsed_s).is_equal(0.0)


func test_combo_grows_to_x3_at_ninth_fish() -> void:
	var combo := Combo.new(0.25, 3.0)
	var multipliers: Array[float] = []
	for i in 10:
		multipliers.append(combo.register_catch())
	assert_array(multipliers).is_equal([1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0, 3.0])


func test_combo_resets_when_line_breaks() -> void:
	var combo := Combo.new(0.25, 3.0)
	combo.register_catch()
	combo.register_catch()
	combo.break_chain()
	assert_int(combo.streak).is_equal(0)
	assert_float(combo.register_catch()).is_equal(1.0)
