extends GdUnitTestSuite
## ShoppingPlan: compras do jogador simulado (sim_profiles.json, campaign).

var db: ContentDB
var plan: ShoppingPlan


func before() -> void:
	db = TestContent.db()
	plan = ShoppingPlan.new(db, db.sim_profiles["campaign"])


func test_prepare_bait_restocks_to_reserve_and_equips() -> void:
	var state := PlayerState.new_game(db)
	state.coins = 1000
	plan.prepare_bait(state, 6)
	# Dia 6: massa de milho (day_baits); reserva de 25 → 3 lotes de 10.
	assert_str(state.equipped_bait).is_equal("corn_dough")
	assert_int(state.bait_count("corn_dough")).is_equal(30)
	assert_int(state.coins).is_equal(1000 - 3 * 80)


func test_prepare_bait_falls_back_to_default_without_coins() -> void:
	var state := PlayerState.new_game(db)
	plan.prepare_bait(state, 9)
	assert_str(state.equipped_bait).is_equal("worm")


func test_buy_follows_plan_order_and_stops_when_short() -> void:
	var state := PlayerState.new_game(db)
	state.coins = 700 + 800 + 100
	var purchases: Array[Dictionary] = []
	plan.buy(state, 4, purchases)
	assert_int(purchases.size()).is_equal(2)
	assert_str(purchases[0]["id"]).is_equal("fiberglass")
	assert_str(state.equipped_rod).is_equal("fiberglass")
	assert_str(purchases[1]["id"]).is_equal("livewell")
	assert_int(int(purchases[1]["level"])).is_equal(2)
	assert_int(int(purchases[1]["session"])).is_equal(4)
	assert_int(state.coins).is_equal(100)


func test_buy_skips_what_is_already_done() -> void:
	var state := PlayerState.new_game(db)
	state.owned_rods.append("fiberglass")
	state.upgrade_levels["livewell"] = 2
	state.coins = 900
	var purchases: Array[Dictionary] = []
	plan.buy(state, 1, purchases)
	assert_str(purchases[0]["id"]).is_equal("motor")
	assert_int(int(purchases[0]["cost"])).is_equal(900)
