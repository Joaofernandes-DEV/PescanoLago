extends GdUnitTestSuite
## Regras do lago inteiro (Fase 6): perfis de versão, dias 1 a 29 e liberação das
## regiões (P-26, P-11), surgimento nas regiões novas (P-29), variante dourada e
## o dia de pesca à noite e com tempo extra.

var db: ContentDB
var mvp: ContentDB


func before() -> void:
	db = TestContent.full_db()
	mvp = TestContent.db()


func _state_with_stars_until(day_number: int) -> PlayerState:
	var state := PlayerState.new_game(db)
	for day in range(1, day_number + 1):
		state.best_stars[str(day)] = 1
	return state


# --- Perfis de versão e dias ---


func test_the_game_still_ships_the_mvp_and_the_full_lake_has_29_days() -> void:
	assert_str(mvp.release["id"]).is_equal("mvp")
	assert_int(mvp.day_count()).is_equal(10)
	assert_str(db.release["id"]).is_equal("full")
	assert_int(db.day_count()).is_equal(29)
	assert_int(int(db.release["max_upgrade_level"])).is_equal(5)


func test_days_9_and_10_keep_the_mvp_version_in_the_mvp() -> void:
	assert_str(mvp.day(9)["region"]).is_equal("margem_rasa")
	assert_int(int(mvp.day(9)["target_score"])).is_equal(380)
	assert_str(db.day(9)["region"]).is_equal("remanso")
	assert_str(db.day(16)["region"]).is_equal("aguas_fundas")
	assert_str(db.day(23)["region"]).is_equal("ilha_da_nevoa")
	assert_str(db.day(24)["region"]).is_equal("poco_fundo")


# --- Liberação (P-26) ---


func test_remanso_waits_for_boat_level_two() -> void:
	var state := _state_with_stars_until(8)
	assert_bool(Progression.can_play(db, state, 8)).is_true()
	assert_array(Progression.missing_for_day(db, state, 9)).is_equal(
		[{"type": "boat_level", "level": 2}]
	)
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 2
	assert_bool(Progression.can_play(db, state, 9)).is_true()
	assert_int(Progression.last_playable_day(db, state)).is_equal(9)


func test_deep_waters_also_need_sonar_two() -> void:
	var state := _state_with_stars_until(15)
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 4
	state.upgrade_levels["sonar"] = 1
	assert_int(state.boat_level()).is_equal(3)
	assert_array(Progression.missing_for_day(db, state, 16)).is_equal(
		[{"type": "upgrade", "id": "sonar", "level": 2}]
	)


func test_poco_fundo_needs_hull_three_and_lights_two() -> void:
	var state := _state_with_stars_until(23)
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 4
	state.upgrade_levels["hull"] = 2
	state.upgrade_levels["lights"] = 1
	var missing := Progression.missing_for_day(db, state, 24)
	assert_bool(missing.has({"type": "upgrade", "id": "hull", "level": 3})).is_true()
	assert_bool(missing.has({"type": "upgrade", "id": "lights", "level": 2})).is_true()


func test_a_day_needs_a_star_on_the_previous_day() -> void:
	var state := PlayerState.new_game(db)
	assert_bool(Progression.can_play(db, state, 1)).is_true()
	assert_array(Progression.missing_for_day(db, state, 2)).is_equal([{"type": "stars", "day": 1}])
	assert_bool(Progression.can_play(db, state, 30)).is_false()


func test_mvp_days_follow_the_stars_as_before() -> void:
	var state := PlayerState.new_game(mvp)
	state.best_stars["1"] = 1
	state.best_stars["2"] = 3
	assert_int(Progression.last_playable_day(mvp, state)).is_equal(state.unlocked_day(10))


# --- Surgimento (P-29) ---


func test_new_regions_have_main_and_secondary_species() -> void:
	var spawns := SpawnTable.new(db)
	var remanso := spawns.weights("remanso", "day", "live_lambari")
	assert_bool(remanso.has("traira")).is_true()
	assert_bool(remanso.has("common_carp")).is_true()
	assert_bool(spawns.weights("ilha_da_nevoa", "day", "live_lambari").has("pirarucu")).is_true()
	(
		assert_bool(spawns.weights("ilha_da_nevoa", "day", "live_lambari").has("king_of_the_lake"))
		. is_false()
	)


func test_loud_motor_lowers_only_surface_fish() -> void:
	var spawns := SpawnTable.new(db)
	var quiet := spawns.weights("aguas_fundas", "dawn", "jig_spoon", 1.0)
	var loud := spawns.weights("aguas_fundas", "dawn", "jig_spoon", 0.5)
	assert_float(loud["dourado"]).is_equal(quiet["dourado"] * 0.5)
	assert_float(loud["pintado"]).is_equal(quiet["pintado"])


func test_catfish_peak_at_night() -> void:
	var spawns := SpawnTable.new(db)
	var day := spawns.weights("poco_fundo", "day", "dead_fish")
	var night := spawns.weights("poco_fundo", "night", "dead_fish")
	assert_float(night["jau"]).is_greater(day["jau"])


func test_golden_variant_appears_in_the_full_lake() -> void:
	var roller := CatchRoller.new(db)
	var seen := {}
	var rng := Rng.new(11)
	for i in 4000:
		seen[roller.roll_variant(db.species("lambari"), 0.5, rng)] = true
	assert_bool(seen.has("golden")).is_true()
	assert_bool(seen.has("albino")).is_true()


# --- Dia de pesca ---


func test_comfort_makes_the_day_longer() -> void:
	var state := _state_with_stars_until(8)
	state.upgrade_levels["comfort"] = 3
	var session := DaySession.new(db, state, 1, Rng.new(1))
	var extra: float = float(db.upgrade_level("comfort", 3)["extra_time_s"])
	assert_float(session.clock.duration_s).is_equal(float(db.day(1)["duration_s"]) + extra)


func test_night_fishing_needs_the_lighthouse() -> void:
	var state := _state_with_stars_until(15)
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 3
	state.upgrade_levels["lights"] = 1
	state.bait_inventory["live_lambari"] = 50
	state.equipped_bait = "live_lambari"
	var session := DaySession.new(db, state, 16, Rng.new(2), {"manual_navigation": true})
	var night_start: float = 0.0
	for phase: Dictionary in db.economy["day_phases"]:
		if phase["id"] == "night":
			night_start = float(phase["start_s"])
	session.tick(night_start + 1.0)
	session.reach_school(5.0)
	assert_str(session.clock.phase()).is_equal("night")
	assert_bool(session.can_cast()).is_false()
	state.upgrade_levels["lights"] = 2
	var lit := DaySession.new(db, state, 16, Rng.new(2), {"manual_navigation": true})
	lit.tick(night_start + 1.0)
	lit.reach_school(5.0)
	assert_bool(lit.can_cast()).is_true()


func test_a_full_lake_day_plays_to_the_end() -> void:
	var state := _state_with_stars_until(8)
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 2
	state.bait_inventory["live_lambari"] = 50
	state.equipped_bait = "live_lambari"
	var rng := Rng.new(5)
	var session := DaySession.new(db, state, 9, rng)
	AutoPlayer.new(PlayerBot.new(db.bot_profile("skilled"), rng)).play_day(session, 0.05)
	assert_bool(session.is_over()).is_true()
	assert_int(int(session.result["fish"])).is_greater(0)
	var remanso_species: Array = []
	for spawn: Dictionary in db.region("remanso")["spawns"]:
		remanso_species.append(spawn["species"])
	for fish in session.catches:
		assert_bool(remanso_species.has(fish.species_id)).is_true()
