extends GdUnitTestSuite
## Pontos (P-09), venda (P-03), viveiro e mercado.

var db: ContentDB


func before() -> void:
	db = TestContent.db()


## Peso médio da carpa: 20 kg × (0,1 + 0,3 + 1,0) / 3.
func _carp_mean_kg() -> float:
	return 20.0 * 1.4 / 3.0


func test_size_factor_is_one_at_mean_weight() -> void:
	var factor := Scoring.size_factor(_carp_mean_kg(), db.species("common_carp"), db.economy)
	assert_float(factor).is_equal_approx(1.0, 0.0001)


func test_size_factor_is_clamped() -> void:
	var carp := db.species("common_carp")
	assert_float(Scoring.size_factor(0.01, carp, db.economy)).is_equal(0.5)
	assert_float(Scoring.size_factor(1000.0, carp, db.economy)).is_equal(2.0)


func test_points_of_average_fish_equal_species_points() -> void:
	var fish := FishCatch.new("common_carp", _carp_mean_kg())
	assert_int(Scoring.points(fish, db.species("common_carp"), db.economy)).is_equal(30)


func test_albino_is_worth_three_times() -> void:
	var fish := FishCatch.new("common_carp", _carp_mean_kg(), "albino")
	assert_int(Scoring.points(fish, db.species("common_carp"), db.economy)).is_equal(90)
	assert_int(Scoring.sale_value(fish, db.species("common_carp"), db.economy)).is_equal(90)


func test_combo_and_early_hook_bonus() -> void:
	var fish := FishCatch.new("common_carp", _carp_mean_kg())
	fish.combo_multiplier = 2.0
	fish.early_hook = true
	# 30 × 1 × 1 × 2 + 10% de 30 = 63 pontos; a venda não tem bônus de fisgada.
	assert_int(Scoring.points(fish, db.species("common_carp"), db.economy)).is_equal(63)
	assert_int(Scoring.sale_value(fish, db.species("common_carp"), db.economy)).is_equal(60)


func test_global_sale_multiplier_changes_coins_not_points() -> void:
	var economy: Dictionary = db.economy.duplicate(true)
	economy["sale"]["global_multiplier"] = 1.5
	var fish := FishCatch.new("common_carp", _carp_mean_kg())
	assert_int(Scoring.sale_value(fish, db.species("common_carp"), economy)).is_equal(45)
	assert_int(Scoring.points(fish, db.species("common_carp"), economy)).is_equal(30)


func test_livewell_capacity() -> void:
	var livewell := Livewell.new(8)
	for i in 8:
		assert_bool(livewell.add(FishCatch.new("lambari", 0.03))).is_true()
	assert_bool(livewell.is_full()).is_true()
	assert_bool(livewell.add(FishCatch.new("lambari", 0.03))).is_false()
	assert_int(livewell.take_all().size()).is_equal(8)
	assert_int(livewell.count()).is_equal(0)


func test_contents_is_a_copy() -> void:
	var livewell := Livewell.new(8)
	livewell.add(FishCatch.new("lambari", 0.03))
	livewell.contents().clear()
	assert_int(livewell.count()).is_equal(1)


func test_market_sells_each_fish() -> void:
	var market := Market.new(db)
	var fish: Array[FishCatch] = [
		FishCatch.new("common_carp", _carp_mean_kg()),
		FishCatch.new("common_carp", _carp_mean_kg(), "albino")
	]
	assert_int(market.sell(fish)).is_equal(120)


func test_fish_catch_round_trip() -> void:
	var fish := FishCatch.new("mandi", 0.42, "albino")
	fish.combo_multiplier = 1.75
	fish.early_hook = true
	var copy := FishCatch.from_dict(fish.to_dict())
	assert_dict(copy.to_dict()).is_equal(fish.to_dict())
