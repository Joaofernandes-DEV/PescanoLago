extends GdUnitTestSuite
## SpawnTable (P-12) e CatchRoller (peso P-08, variantes).

var db: ContentDB


func before() -> void:
	db = TestContent.db()


func test_weights_with_worm_at_dawn() -> void:
	var table := SpawnTable.new(db).weights("margem_rasa", "dawn", "worm")
	# lambari 40×4, tilápia 30×4, carpa 15×4 (a tabela de iscas do GDD diz que a minhoca
	# atrai a carpa), mandi 10×0,5×4, incomuns com isca não ideal × 0,25.
	assert_float(table["lambari"]).is_equal(160.0)
	assert_float(table["nile_tilapia"]).is_equal(120.0)
	assert_float(table["common_carp"]).is_equal(60.0)
	assert_float(table["mandi"]).is_equal(20.0)
	assert_float(table["traira"]).is_equal(1.5)
	assert_float(table["red_piranha"]).is_equal(1.0)


func test_mandi_peaks_at_dusk_and_ideal_bait_helps_traira() -> void:
	var spawns := SpawnTable.new(db)
	assert_float(spawns.weights("margem_rasa", "dusk", "worm")["mandi"]).is_equal(80.0)
	assert_float(spawns.weights("margem_rasa", "dusk", "live_lambari")["traira"]).is_equal(48.0)


func test_mvp_only_spawns_are_excluded_in_full_mode() -> void:
	var table := SpawnTable.new(TestContent.full_db()).weights("margem_rasa", "day", "worm")
	assert_bool(table.has("traira")).is_false()
	assert_int(table.size()).is_equal(4)


func test_pick_follows_weights() -> void:
	var spawns := SpawnTable.new(db)
	var rng := Rng.new(2026)
	var counts := {}
	for i in 20000:
		var species_id := spawns.pick("margem_rasa", "dawn", "worm", rng)
		counts[species_id] = int(counts.get(species_id, 0)) + 1
	# Total dos pesos = 160 + 120 + 60 + 20 + 1,5 + 1,25 + 1,0 + 1,25 = 365;
	# esperado: lambari ≈ 8.767 e carpa ≈ 3.288 em 20.000 sorteios.
	assert_int(int(counts["lambari"])).is_between(8550, 9100)
	assert_int(int(counts["common_carp"])).is_between(3100, 3520)


func test_empty_region_picks_nothing() -> void:
	assert_str(SpawnTable.new(db).pick("porto_manso", "day", "worm", Rng.new(1))).is_empty()
	assert_object(CatchRoller.new(db).roll("porto_manso", "day", "worm", 0.0, Rng.new(1))).is_null()


func test_weight_distribution() -> void:
	var roller := CatchRoller.new(db)
	var carp := db.species("common_carp")
	var rng := Rng.new(7)
	var total := 0.0
	for i in 20000:
		var kg := roller.roll_weight(carp, rng)
		assert_bool(kg >= 2.0 and kg <= 20.0).is_true()
		total += kg
	# Média triangular: 20 × (0,1 + 0,3 + 1,0) / 3 ≈ 9,33 kg.
	assert_float(total / 20000.0).is_equal_approx(9.333, 0.15)


func test_variant_chance_grows_with_sonar() -> void:
	var roller := CatchRoller.new(db)
	var lambari := db.species("lambari")
	var sonar_3_bonus := float(db.upgrade_level("sonar", 3)["variant_chance_bonus"])
	var hits_sonar_1 := 0
	var hits_sonar_3 := 0
	var rng := Rng.new(99)
	for i in 50000:
		if roller.roll_variant(lambari, 0.0, rng) != "":
			hits_sonar_1 += 1
		if roller.roll_variant(lambari, sonar_3_bonus, rng) != "":
			hits_sonar_3 += 1
	assert_int(hits_sonar_1).is_between(850, 1150)  # 2%
	assert_int(hits_sonar_3).is_between(1350, 1650)  # 3%


func test_only_albino_in_mvp_and_never_for_epics() -> void:
	var roller := CatchRoller.new(db)
	var rng := Rng.new(5)
	for i in 5000:
		var variant := roller.roll_variant(db.species("lambari"), 0.01, rng)
		assert_bool(variant == "" or variant == "albino").is_true()
		assert_str(roller.roll_variant(db.species("jau"), 0.01, rng)).is_empty()


func test_roll_is_deterministic() -> void:
	var roller := CatchRoller.new(db)
	var a := roller.roll("margem_rasa", "day", "worm", 0.0, Rng.new(42))
	var b := roller.roll("margem_rasa", "day", "worm", 0.0, Rng.new(42))
	assert_dict(a.to_dict()).is_equal(b.to_dict())
