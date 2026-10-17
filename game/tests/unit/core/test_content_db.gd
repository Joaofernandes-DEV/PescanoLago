extends GdUnitTestSuite
## ContentDB: consultas sobre o conteúdo real.

var db: ContentDB


func before() -> void:
	db = TestContent.db()


func test_species_lookup() -> void:
	assert_str(db.species("lambari")["scientific_name"]).is_equal("Astyanax lacustris")
	assert_bool(db.is_common("lambari")).is_true()
	assert_bool(db.is_common("traira")).is_false()


func test_ideal_bait_uses_both_game_design_tables() -> void:
	# Minhoca lista o lambari (tabela de iscas) e o lambari lista a minhoca (tabela de peixes).
	assert_bool(db.is_ideal_bait("lambari", "worm")).is_true()
	# Só a tabela de peixes liga o Mandi à minhoca.
	assert_bool(db.is_ideal_bait("mandi", "worm")).is_true()
	# Só a tabela de peixes liga o Pirarucu ao lambari vivo.
	assert_bool(db.is_ideal_bait("pirarucu", "live_lambari")).is_true()
	assert_bool(db.is_ideal_bait("lambari", "corn_dough")).is_false()


func test_upgrade_levels_and_mvp_cap() -> void:
	assert_int(int(db.upgrade_level("livewell", 1)["capacity"])).is_equal(8)
	assert_int(int(db.upgrade_level("motor", 3)["cost"])).is_equal(2200)
	assert_int(db.upgrade_max_level("motor")).is_equal(3)
	assert_int(db.upgrade_max_level("hull")).is_equal(1)


func test_rods_and_reel_speed() -> void:
	assert_float(float(db.rod("fiberglass")["range_m"])).is_equal(12.0)
	assert_float(db.reel_speed_m_s("bamboo_grandpa")).is_equal(1.0)
	assert_float(db.reel_speed_m_s("light_carbon")).is_equal(1.5)


func test_release_flags() -> void:
	assert_bool(db.is_mvp()).is_true()
	assert_bool(db.is_enabled("rods", "fiberglass")).is_true()
	assert_bool(db.is_enabled("rods", "pro_carbon")).is_false()
	assert_bool(db.is_enabled("variants", "golden")).is_false()
	assert_int(db.day_count()).is_equal(10)


func test_days_and_baits() -> void:
	assert_int(int(db.day(1)["goal"]["count"])).is_equal(8)
	assert_bool(db.is_natural_bait("worm")).is_true()
	assert_bool(db.is_natural_bait("jig_spoon")).is_false()
	assert_int(db.lot_size()).is_equal(10)
