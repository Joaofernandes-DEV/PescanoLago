extends GdUnitTestSuite
## Shop: isca equipada antes do dia e isca de socorro de Dona Marô (P-22).

var db: ContentDB
var shop: Shop


func before() -> void:
	db = TestContent.db()
	shop = Shop.new(db)


func _broke_without_bait() -> PlayerState:
	var state := PlayerState.new_game(db)
	state.bait_inventory = {}
	state.coins = 0
	return state


func test_bait_ids_follow_content_order() -> void:
	assert_str(db.bait_ids()[0]).is_equal("worm")
	assert_int(db.bait_ids().size()).is_equal(9)


func test_cheapest_lot_is_worm() -> void:
	# Minhoca: 5 moedas a unidade × lote de 10 (P-16).
	assert_int(shop.cheapest_bait_lot_price()).is_equal(50)


func test_first_bait_in_stock_skips_empty_and_disabled() -> void:
	var state := PlayerState.new_game(db)
	state.bait_inventory = {"worm": 0, "shrimp_fruit": 10, "corn_dough": 3}
	# shrimp_fruit não está no MVP (release.json).
	assert_str(shop.first_bait_in_stock(state)).is_equal("corn_dough")


func test_ensure_bait_switches_when_equipped_runs_out() -> void:
	var state := PlayerState.new_game(db)
	state.bait_inventory = {"worm": 0, "corn_dough": 4}
	state.equipped_bait = "worm"
	assert_bool(shop.ensure_bait_equipped(state)).is_true()
	assert_str(state.equipped_bait).is_equal("corn_dough")


func test_ensure_bait_keeps_equipped_with_stock() -> void:
	var state := PlayerState.new_game(db)
	state.bait_inventory = {"worm": 2, "corn_dough": 4}
	state.equipped_bait = "worm"
	assert_bool(shop.ensure_bait_equipped(state)).is_true()
	assert_str(state.equipped_bait).is_equal("worm")


func test_ensure_bait_fails_without_any_bait() -> void:
	assert_bool(shop.ensure_bait_equipped(_broke_without_bait())).is_false()


func test_rescue_gives_one_lot_of_worms_when_stuck() -> void:
	var state := _broke_without_bait()
	state.equipped_bait = "corn_dough"
	state.coins = 49
	assert_bool(shop.needs_bait_rescue(state)).is_true()
	assert_bool(shop.rescue_bait(state)).is_true()
	assert_int(state.bait_count("worm")).is_equal(db.lot_size())
	assert_str(state.equipped_bait).is_equal("worm")
	assert_int(state.coins).is_equal(49)
	# Com isca no estoque, não há socorro de novo.
	assert_bool(shop.rescue_bait(state)).is_false()


func test_no_rescue_when_player_can_buy_a_lot() -> void:
	var state := _broke_without_bait()
	state.coins = 50
	assert_bool(shop.needs_bait_rescue(state)).is_false()
	assert_bool(shop.rescue_bait(state)).is_false()
	assert_int(state.bait_count("worm")).is_equal(0)


func test_no_rescue_when_player_has_some_bait() -> void:
	var state := _broke_without_bait()
	state.bait_inventory = {"live_lambari": 1}
	assert_bool(shop.needs_bait_rescue(state)).is_false()
