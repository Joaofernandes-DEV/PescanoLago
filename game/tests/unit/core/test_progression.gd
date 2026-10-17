extends GdUnitTestSuite
## PlayerState, Shop (P-14, P-16, P-17) e GoalEvaluator (P-05, P-06, P-13).
## O save fica em test_save_codec.gd.

var db: ContentDB


func before() -> void:
	db = TestContent.db()


func _rich_state() -> PlayerState:
	var state := PlayerState.new_game(db)
	state.coins = 100000
	return state


func _fish(species_id: String, count: int) -> Array[FishCatch]:
	var result: Array[FishCatch] = []
	for i in count:
		result.append(FishCatch.new(species_id, 1.0))
	return result


# --- PlayerState ---


func test_new_game_matches_start_state() -> void:
	var state := PlayerState.new_game(db)
	assert_int(state.coins).is_equal(0)
	assert_str(state.equipped_rod).is_equal("bamboo_grandpa")
	assert_int(state.bait_count("worm")).is_equal(20)
	assert_int(state.level_of("motor")).is_equal(1)
	assert_int(state.upgrade_levels.size()).is_equal(6)
	assert_int(state.boat_level()).is_equal(1)


func test_boat_level_is_floor_of_average() -> void:
	var state := PlayerState.new_game(db)
	for upgrade_id: String in ["motor", "hull", "livewell", "sonar", "lights"]:
		state.upgrade_levels[upgrade_id] = 2
	assert_int(state.boat_level()).is_equal(1)
	state.upgrade_levels["comfort"] = 2
	assert_int(state.boat_level()).is_equal(2)


func test_days_unlock_with_one_star() -> void:
	var state := PlayerState.new_game(db)
	assert_int(state.unlocked_day(10)).is_equal(1)
	state.best_stars["1"] = 1
	state.best_stars["2"] = 3
	assert_int(state.unlocked_day(10)).is_equal(3)
	assert_bool(state.is_day_unlocked(4, 10)).is_false()


func test_album_tracks_species_variants_and_best_weight() -> void:
	var state := PlayerState.new_game(db)
	state.register_in_album(FishCatch.new("mandi", 0.4))
	state.register_in_album(FishCatch.new("mandi", 0.7, "albino"))
	state.register_in_album(FishCatch.new("mandi", 0.5, "albino"))
	var entry: Dictionary = state.album["mandi"]
	assert_int(int(entry["caught"])).is_equal(3)
	assert_array(entry["variants"]).is_equal(["albino"])
	assert_float(float(entry["best_weight_kg"])).is_equal(0.7)


# --- Shop ---


func test_upgrade_prices_follow_p14() -> void:
	var shop := Shop.new(db)
	var state := _rich_state()
	assert_int(shop.upgrade_price(state, "motor")).is_equal(900)
	assert_int(shop.buy_upgrade(state, "motor")).is_equal(Shop.Status.OK)
	assert_int(shop.upgrade_price(state, "motor")).is_equal(2200)
	assert_int(shop.buy_upgrade(state, "motor")).is_equal(Shop.Status.OK)
	assert_int(state.coins).is_equal(100000 - 900 - 2200)
	# O MVP para no nível 3.
	assert_int(shop.upgrade_price(state, "motor")).is_equal(Shop.NO_PRICE)
	assert_int(shop.buy_upgrade(state, "motor")).is_equal(Shop.Status.MAX_LEVEL)


func test_upgrade_needs_coins_and_mvp_scope() -> void:
	var shop := Shop.new(db)
	var state := PlayerState.new_game(db)
	state.coins = 899
	assert_int(shop.buy_upgrade(state, "motor")).is_equal(Shop.Status.NOT_ENOUGH_COINS)
	assert_int(state.coins).is_equal(899)
	assert_int(shop.buy_upgrade(_rich_state(), "hull")).is_equal(Shop.Status.NOT_AVAILABLE)


func test_livewell_upgrade_raises_capacity() -> void:
	var shop := Shop.new(db)
	var state := _rich_state()
	shop.buy_upgrade(state, "livewell")
	var capacity := int(db.upgrade_level("livewell", state.level_of("livewell"))["capacity"])
	assert_int(capacity).is_equal(15)


func test_rods() -> void:
	var shop := Shop.new(db)
	var state := _rich_state()
	assert_int(shop.buy_rod(state, "fiberglass")).is_equal(Shop.Status.OK)
	assert_int(shop.buy_rod(state, "fiberglass")).is_equal(Shop.Status.ALREADY_OWNED)
	assert_int(shop.buy_rod(state, "pro_carbon")).is_equal(Shop.Status.NOT_AVAILABLE)
	assert_int(shop.buy_rod(state, "master_rod")).is_equal(Shop.Status.NOT_AVAILABLE)
	assert_int(shop.equip_rod(state, "light_carbon")).is_equal(Shop.Status.NOT_OWNED)
	assert_int(shop.equip_rod(state, "fiberglass")).is_equal(Shop.Status.OK)
	assert_int(state.coins).is_equal(100000 - 700)


func test_bait_lots_follow_p16() -> void:
	var shop := Shop.new(db)
	var state := _rich_state()
	assert_int(shop.bait_lot_price("worm")).is_equal(50)
	assert_int(shop.buy_bait_lot(state, "dead_fish")).is_equal(Shop.Status.OK)
	assert_int(state.bait_count("dead_fish")).is_equal(10)
	assert_int(state.coins).is_equal(100000 - 400)
	assert_int(shop.buy_bait_lot(state, "jig_spoon")).is_equal(Shop.Status.NOT_AVAILABLE)
	assert_int(shop.buy_bait_lot(state, "shrimp_fruit")).is_equal(Shop.Status.NOT_AVAILABLE)


func test_equip_bait_needs_stock() -> void:
	var shop := Shop.new(db)
	var state := PlayerState.new_game(db)
	assert_int(shop.equip_bait(state, "corn_dough")).is_equal(Shop.Status.NOT_OWNED)
	assert_int(shop.equip_bait(state, "worm")).is_equal(Shop.Status.OK)


# --- Metas e estrelas ---


func test_fish_count_goal_day_1() -> void:
	var goal: Dictionary = db.day(1)["goal"]
	assert_bool(GoalEvaluator.goal_met(goal, _fish("lambari", 7), 0, db)).is_false()
	assert_bool(GoalEvaluator.goal_met(goal, _fish("lambari", 8), 0, db)).is_true()


func test_score_and_species_goals() -> void:
	assert_bool(GoalEvaluator.goal_met(db.day(5)["goal"], [], 299, db)).is_false()
	assert_bool(GoalEvaluator.goal_met(db.day(5)["goal"], [], 300, db)).is_true()
	var catches := _fish("lambari", 10)
	catches.append_array(_fish("common_carp", 2))
	assert_bool(GoalEvaluator.goal_met(db.day(6)["goal"], catches, 0, db)).is_false()
	catches.append_array(_fish("common_carp", 1))
	assert_bool(GoalEvaluator.goal_met(db.day(6)["goal"], catches, 0, db)).is_true()


func test_rarity_and_species_conditions_days_9_and_10() -> void:
	var catches := _fish("lambari", 14)
	catches.append_array(_fish("pacu", 1))
	assert_bool(GoalEvaluator.goal_met(db.day(9)["goal"], catches, 0, db)).is_false()
	catches.append_array(_fish("traira", 1))
	assert_bool(GoalEvaluator.goal_met(db.day(9)["goal"], catches, 0, db)).is_true()
	var no_traira := _fish("lambari", 13)
	no_traira.append_array(_fish("pacu", 2))
	assert_bool(GoalEvaluator.goal_met(db.day(10)["goal"], no_traira, 0, db)).is_false()
	assert_bool(GoalEvaluator.goal_met(db.day(10)["goal"], catches, 0, db)).is_true()


func test_stars_by_target_score() -> void:
	var day1 := db.day(1)
	var eight := _fish("lambari", 8)
	assert_int(GoalEvaluator.stars(day1, _fish("lambari", 3), 1000, db)).is_equal(0)
	assert_int(GoalEvaluator.stars(day1, eight, 160, db)).is_equal(1)
	assert_int(GoalEvaluator.stars(day1, eight, 239, db)).is_equal(1)
	assert_int(GoalEvaluator.stars(day1, eight, 240, db)).is_equal(2)
	assert_int(GoalEvaluator.stars(day1, eight, 320, db)).is_equal(3)


func test_star_rewards_pay_only_improvements() -> void:
	assert_int(GoalEvaluator.star_reward(0, 1, db)).is_equal(50)
	assert_int(GoalEvaluator.star_reward(0, 3, db)).is_equal(250)
	assert_int(GoalEvaluator.star_reward(1, 3, db)).is_equal(200)
	assert_int(GoalEvaluator.star_reward(3, 2, db)).is_equal(0)
	assert_int(GoalEvaluator.star_reward(2, 2, db)).is_equal(0)
