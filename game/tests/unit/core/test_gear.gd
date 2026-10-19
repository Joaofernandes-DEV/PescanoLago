extends GdUnitTestSuite
## Equipamento do lago inteiro (Fase 6, P-29): iscas artificiais por nível, peças
## extras das varas, efeitos somados no Loadout e a briga do pirarucu (fôlego).

var db: ContentDB
var shop: Shop


func before() -> void:
	db = TestContent.full_db()
	shop = Shop.new(db)


func _rich_state() -> PlayerState:
	var state := PlayerState.new_game(db)
	state.coins = 100000
	return state


# --- Iscas artificiais ---


func test_artificial_bait_is_bought_then_levelled_up_to_three() -> void:
	var state := _rich_state()
	var costs: Array = db.bait("propeller_lure")["level_costs"]
	assert_int(shop.artificial_bait_price(state, "propeller_lure")).is_equal(int(costs[0]))
	for level in range(1, 4):
		assert_int(shop.buy_artificial_bait(state, "propeller_lure")).is_equal(Shop.Status.OK)
		assert_int(state.artificial_level("propeller_lure")).is_equal(level)
	assert_int(shop.buy_artificial_bait(state, "propeller_lure")).is_equal(Shop.Status.MAX_LEVEL)
	var total: int = int(costs[0]) + int(costs[1]) + int(costs[2])
	assert_int(state.coins).is_equal(100000 - total)


func test_artificial_bait_must_be_bought_before_equipping_and_never_runs_out() -> void:
	var state := _rich_state()
	assert_int(shop.equip_bait(state, "jig_spoon")).is_equal(Shop.Status.NOT_OWNED)
	shop.buy_artificial_bait(state, "jig_spoon")
	assert_int(shop.equip_bait(state, "jig_spoon")).is_equal(Shop.Status.OK)
	assert_bool(shop.ensure_bait_equipped(state)).is_true()


func test_natural_bait_has_no_levels_and_mvp_sells_no_artificial() -> void:
	var state := _rich_state()
	assert_int(shop.buy_artificial_bait(state, "worm")).is_equal(Shop.Status.NOT_AVAILABLE)
	var mvp_shop := Shop.new(TestContent.db())
	assert_int(mvp_shop.buy_artificial_bait(state, "jig_spoon")).is_equal(Shop.Status.NOT_AVAILABLE)


# --- Peças extras das varas ---


func test_part_is_bought_once_and_mounted_on_the_equipped_rod() -> void:
	var state := _rich_state()
	assert_int(shop.buy_rod_part(state, "braided_line")).is_equal(Shop.Status.OK)
	assert_array(state.parts_on("bamboo_grandpa")).is_equal(["braided_line"])
	assert_int(shop.buy_rod_part(state, "braided_line")).is_equal(Shop.Status.ALREADY_OWNED)
	assert_int(state.coins).is_equal(100000 - int(db.rod_parts["braided_line"]["cost"]))


func test_each_rod_takes_two_parts_and_parts_move_between_rods() -> void:
	var state := _rich_state()
	for part_id: String in ["better_reel", "braided_line", "sharp_hook"]:
		shop.buy_rod_part(state, part_id)
	assert_int(state.parts_on("bamboo_grandpa").size()).is_equal(db.part_slots)
	assert_int(shop.install_part(state, "sharp_hook", "bamboo_grandpa")).is_equal(
		Shop.Status.NO_FREE_SLOT
	)
	shop.buy_rod(state, "fiberglass")
	assert_int(shop.install_part(state, "better_reel", "fiberglass")).is_equal(Shop.Status.OK)
	assert_array(state.parts_on("fiberglass")).is_equal(["better_reel"])
	assert_bool(state.parts_on("bamboo_grandpa").has("better_reel")).is_false()
	assert_int(shop.install_part(state, "sharp_hook", "bamboo_grandpa")).is_equal(Shop.Status.OK)


func test_parts_need_an_owned_rod_and_are_not_sold_in_the_mvp() -> void:
	var state := _rich_state()
	shop.buy_rod_part(state, "glow_float")
	assert_int(shop.install_part(state, "glow_float", "pro_carbon")).is_equal(Shop.Status.NOT_OWNED)
	var mvp_shop := Shop.new(TestContent.db())
	assert_int(mvp_shop.buy_rod_part(state, "sharp_hook")).is_equal(Shop.Status.NOT_AVAILABLE)


# --- Loadout ---


func test_loadout_adds_part_effects_to_the_rod() -> void:
	var state := _rich_state()
	var rod: Dictionary = db.rod("bamboo_grandpa")
	var plain := Loadout.new(db, state)
	assert_float(plain.line_strength_kg()).is_equal(float(rod["line_strength_kg"]))
	assert_float(plain.hook_window_s()).is_equal(float(rod["hook_window_s"]))
	shop.buy_rod_part(state, "braided_line")
	shop.buy_rod_part(state, "sharp_hook")
	var gear := Loadout.new(db, state)
	var parts: Dictionary = db.rod_parts
	assert_float(gear.line_strength_kg()).is_equal_approx(
		(
			float(rod["line_strength_kg"])
			* float(parts["braided_line"]["effects"]["line_strength_factor"])
		),
		0.0001
	)
	assert_float(gear.hook_window_s()).is_equal_approx(
		float(rod["hook_window_s"]) + float(parts["sharp_hook"]["effects"]["hook_window_bonus_s"]),
		0.0001
	)
	assert_float(gear.reel_speed_m_s()).is_equal(db.reel_speed_m_s("bamboo_grandpa"))


func test_night_needs_lights_level_two() -> void:
	var state := _rich_state()
	assert_bool(Loadout.new(db, state).can_fish_at("night")).is_false()
	assert_bool(Loadout.new(db, state).can_fish_at("dusk")).is_true()
	state.upgrade_levels["lights"] = 2
	assert_bool(Loadout.new(db, state).can_fish_at("night")).is_true()


func test_glow_float_and_lights_shorten_the_wait_only_at_night() -> void:
	var state := _rich_state()
	state.upgrade_levels["lights"] = 5
	shop.buy_rod_part(state, "glow_float")
	var gear := Loadout.new(db, state)
	assert_float(gear.bite_wait_factor("day")).is_equal(1.0)
	var expected: float = (
		float(db.upgrade_level("lights", 5)["night_bite_wait_factor"])
		* float(db.rod_parts["glow_float"]["effects"]["night_bite_wait_factor"])
	)
	assert_float(gear.bite_wait_factor("night")).is_equal_approx(expected, 0.0001)


func test_comfort_gives_extra_time_and_luck() -> void:
	var state := _rich_state()
	assert_float(Loadout.new(db, state).extra_time_s()).is_equal(0.0)
	state.upgrade_levels["comfort"] = 5
	var gear := Loadout.new(db, state)
	assert_float(gear.extra_time_s()).is_equal(
		float(db.upgrade_level("comfort", 5)["extra_time_s"])
	)
	assert_float(gear.variant_chance_bonus()).is_equal(
		float(db.upgrade_level("comfort", 5)["variant_chance_bonus"])
	)


func test_artificial_bait_level_gives_attraction_radius_and_variant_chance() -> void:
	var state := _rich_state()
	assert_float(Loadout.new(db, state).attraction_radius_m()).is_equal(0.0)
	for i in 3:
		shop.buy_artificial_bait(state, "propeller_lure")
	shop.equip_bait(state, "propeller_lure")
	var level_3: Dictionary = db.bait("propeller_lure")["levels"][2]
	var gear := Loadout.new(db, state)
	assert_float(gear.attraction_radius_m()).is_equal(float(level_3["attraction_radius_m"]))
	assert_float(gear.variant_chance_bonus()).is_equal(float(level_3["variant_chance_bonus"]))


func test_loud_motor_scares_surface_fish_but_the_electric_one_does_not() -> void:
	var state := _rich_state()
	state.upgrade_levels["motor"] = 5
	assert_float(Loadout.new(db, state).surface_multiplier()).is_less(1.0)
	state.upgrade_levels["motor"] = 4
	assert_float(Loadout.new(db, state).surface_multiplier()).is_equal(1.0)


# --- Pirarucu: fôlego ---


func test_breather_surfaces_to_breathe_and_pulls_less_meanwhile() -> void:
	var params: Dictionary = db.economy["fight_profiles"]["breather"]
	var profile := FightProfile.new("breather", db.economy["fight_profiles"], Rng.new(3))
	var every: float = float(params["breath_every_s"])
	var breath: float = float(params["breath_duration_s"])
	profile.advance(every - breath - 0.1)
	assert_bool(profile.is_breathing()).is_false()
	var pulling: float = profile.pull_multiplier()
	profile.advance(0.2)
	assert_bool(profile.is_breathing()).is_true()
	assert_float(profile.pull_multiplier()).is_less(pulling)
	assert_float(profile.reel_progress_multiplier()).is_equal(
		float(params["breath_progress_multiplier"])
	)


func test_reeling_during_the_breath_brings_the_fish_closer_faster() -> void:
	var profiles: Dictionary = db.economy["fight_profiles"]
	var tension: Dictionary = db.economy["tension"]
	var breather := TensionMinigame.new(
		tension, FightProfile.new("breather", profiles, Rng.new(1)), 50.0, 45.0, 2.0, 20.0
	)
	var params: Dictionary = profiles["breather"]
	var to_breath: float = float(params["breath_every_s"]) - float(params["breath_duration_s"])
	breather.profile.advance(to_breath + 0.05)
	breather.tension = 50.0
	var before_breath: float = breather.distance_m
	breather.step(0.1, true)
	var gained_breathing: float = before_breath - breather.distance_m
	assert_float(gained_breathing).is_equal_approx(
		2.0 * float(params["breath_progress_multiplier"]) * 0.1, 0.0001
	)
