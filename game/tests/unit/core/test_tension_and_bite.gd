extends GdUnitTestSuite
## Mini-jogo de tensão (P-10), perfis de briga, mordida e jogador simulado.

const STEP_S: float = 0.05

var db: ContentDB


func before() -> void:
	db = TestContent.db()


func _game(fish_kg: float, rod_id: String, fight: String, seed: int) -> TensionMinigame:
	var rod := db.rod(rod_id)
	var profile := FightProfile.new(fight, db.economy["fight_profiles"], Rng.new(seed))
	return TensionMinigame.new(
		db.economy["tension"],
		profile,
		fish_kg,
		float(rod["line_strength_kg"]),
		db.reel_speed_m_s(rod_id),
		float(rod["range_m"])
	)


func _bot(bot_id: String, seed: int) -> PlayerBot:
	return PlayerBot.new(db.bot_profile(bot_id), Rng.new(seed))


func _play_constant(game: TensionMinigame, reeling: bool) -> TensionMinigame.Result:
	var guard := 0
	while not game.is_over() and guard < 10000:
		game.step(STEP_S, reeling)
		guard += 1
	return game.result


## Quantas de `trials` brigas o bot ganha.
func _wins(fish_kg: float, rod_id: String, fight: String, bot_id: String, trials: int) -> int:
	var wins := 0
	for i in trials:
		var result := _bot(bot_id, i).fight(_game(fish_kg, rod_id, fight, i), STEP_S)
		if result == TensionMinigame.Result.CAUGHT:
			wins += 1
	return wins


func test_reeling_nonstop_breaks_the_line() -> void:
	var result := _play_constant(_game(2.0, "bamboo_grandpa", "standard", 1), true)
	assert_int(result).is_equal(TensionMinigame.Result.LINE_BROKE)


func test_never_reeling_lets_the_fish_escape() -> void:
	var result := _play_constant(_game(2.0, "bamboo_grandpa", "standard", 1), false)
	assert_int(result).is_equal(TensionMinigame.Result.ESCAPED)


func test_skilled_bot_lands_light_fish() -> void:
	assert_int(_wins(0.5, "bamboo_grandpa", "standard", "skilled", 20)).is_equal(20)


func test_green_zone_tires_the_fish_and_reels_line() -> void:
	var game := _game(2.0, "bamboo_grandpa", "standard", 3)
	var bot := _bot("skilled", 3)
	for i in 40:
		game.step(STEP_S, bot.decide_reeling(game))
	assert_float(game.stamina).is_less(1.0)
	assert_float(game.distance_m).is_less(8.0)


func test_stronger_rod_lands_heavy_carp() -> void:
	# Carpa de 15 kg: a linha de 5 kg do bambu quase sempre arrebenta; a de 25 kg aguenta.
	var bamboo := _wins(15.0, "bamboo_grandpa", "standard", "skilled", 30)
	var carbon := _wins(15.0, "light_carbon", "standard", "skilled", 30)
	assert_int(bamboo).is_less_equal(5)
	assert_int(carbon).is_greater_equal(27)


func test_jumper_punishes_players_who_ignore_jumps() -> void:
	var skilled := _wins(3.0, "fiberglass", "jumper", "skilled", 60)
	var casual := _wins(3.0, "fiberglass", "jumper", "casual", 60)
	assert_int(skilled).is_greater(casual)
	assert_int(casual).is_greater(0)


func test_fight_is_deterministic() -> void:
	var a := _game(4.0, "fiberglass", "burst_snagger", 77)
	var b := _game(4.0, "fiberglass", "burst_snagger", 77)
	_bot("casual", 5).fight(a, STEP_S)
	_bot("casual", 5).fight(b, STEP_S)
	assert_int(a.result).is_equal(b.result)
	assert_float(a.elapsed_s).is_equal(b.elapsed_s)
	assert_float(a.tension).is_equal(b.tension)


func test_break_risk_for_hud() -> void:
	var game := _game(2.0, "bamboo_grandpa", "standard", 1)
	assert_float(game.break_risk()).is_equal(0.0)
	_play_constant(game, true)
	assert_float(game.break_risk()).is_equal(1.0)


func test_profiles_modulate_pull() -> void:
	var profiles: Dictionary = db.economy["fight_profiles"]
	var standard := FightProfile.new("standard", profiles, Rng.new(1))
	var deep := FightProfile.new("deep_puller", profiles, Rng.new(1))
	var jumper := FightProfile.new("jumper", profiles, Rng.new(1))
	var total_standard := 0.0
	var total_deep := 0.0
	var jumping_steps := 0
	for i in 2000:
		standard.advance(STEP_S)
		deep.advance(STEP_S)
		jumper.advance(STEP_S)
		total_standard += standard.pull_multiplier()
		total_deep += deep.pull_multiplier()
		if jumper.is_jumping():
			jumping_steps += 1
	assert_float(total_standard / 2000.0).is_equal_approx(1.0, 0.02)
	assert_float(total_deep / 2000.0).is_equal_approx(1.3, 0.03)
	# Pulo de 0,8 s a cada 4 s: 20% do tempo.
	assert_float(jumping_steps / 2000.0).is_equal_approx(0.2, 0.01)


func test_burst_snagger_bursts() -> void:
	var profile := FightProfile.new("burst_snagger", db.economy["fight_profiles"], Rng.new(9))
	var bursting_steps := 0
	for i in 4000:
		profile.advance(STEP_S)
		if profile.is_bursting():
			bursting_steps += 1
	assert_int(bursting_steps).is_between(400, 1200)


func test_bite_wait_and_short_cast() -> void:
	var fishing: Dictionary = db.economy["fishing"]
	var low := float(fishing["bite_wait_s"][0])
	var high := float(fishing["bite_wait_s"][1])
	var penalty := float(fishing["short_cast_wait_multiplier"])
	var rng := Rng.new(4)
	for i in 500:
		var wait := Bite.wait_time_s(fishing, 10.0, 8.0, rng)
		assert_bool(wait >= low and wait <= high).is_true()
		var short := Bite.wait_time_s(fishing, 5.0, 8.0, rng)
		assert_bool(short >= low * penalty and short <= high * penalty).is_true()


func test_hook_window() -> void:
	var bonus: Dictionary = db.economy["hook_bonus"]
	assert_int(Bite.hook(0.2, 0.6, bonus)).is_equal(Bite.Hook.HOOKED_EARLY)
	assert_int(Bite.hook(0.5, 0.6, bonus)).is_equal(Bite.Hook.HOOKED)
	assert_int(Bite.hook(0.65, 0.6, bonus)).is_equal(Bite.Hook.MISSED)
	assert_int(Bite.hook(0.65, 0.7, bonus)).is_equal(Bite.Hook.HOOKED)


func test_bot_reaction_and_cast_ranges() -> void:
	var casual := _bot("casual", 1)
	for i in 200:
		var reaction := casual.reaction_time_s()
		assert_bool(reaction >= 0.3 and reaction <= 0.7).is_true()
		var aim := casual.aim_factor()
		assert_bool(aim >= 0.85 and aim <= 1.2).is_true()
