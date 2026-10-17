extends GdUnitTestSuite
## Campanha simulada (base do balanceamento): determinística e coerente.

var db: ContentDB


func before() -> void:
	db = TestContent.db()


func test_campaign_is_deterministic() -> void:
	var campaign := Campaign.new(db)
	var a := campaign.run("skilled", 7)
	var b := campaign.run("skilled", 7)
	assert_dict(a).is_equal(b)


func test_skilled_campaign_finishes_the_mvp() -> void:
	var run := Campaign.new(db).run("skilled", 3)
	assert_bool(bool(run["completed"])).is_true()
	var sessions: Array = run["sessions"]
	var last: Dictionary = sessions[-1]
	assert_int(int(last["day"])).is_equal(db.day_count())
	assert_bool(bool(last["goal_met"])).is_true()


func test_purchases_follow_the_plan_order() -> void:
	var run := Campaign.new(db).run("skilled", 3)
	var purchases: Array = run["purchases"]
	assert_int(purchases.size()).is_greater(0)
	var first: Dictionary = purchases[0]
	assert_str(first["id"]).is_equal("fiberglass")
	for purchase: Dictionary in purchases:
		assert_int(int(purchase["cost"])).is_greater(0)


func test_regression_full_campaign_with_fixed_seed() -> void:
	# Referência da Fase 2: campanha do MVP (10 dias) do jogador habilidoso, semente 3.
	# Se mudar sem mudança intencional de regra ou de dados, algo quebrou; se a
	# mudança for intencional, atualize aqui e registre no LOG.
	var run := Campaign.new(db).run("skilled", 3)
	var stars: Array[int] = []
	for session: Dictionary in run["sessions"]:
		stars.append(int(session["stars"]))
	var purchases: Array[String] = []
	for purchase: Dictionary in run["purchases"]:
		(
			purchases
			. append(
				(
					"%d:%s:%d:%d"
					% [
						int(purchase["session"]),
						purchase["id"],
						int(purchase["level"]),
						int(purchase["cost"]),
					]
				)
			)
		)
	assert_bool(bool(run["completed"])).is_true()
	assert_array(stars).is_equal([1, 3, 3, 3, 2, 3, 3, 2, 0, 3, 3])
	(
		assert_array(purchases)
		. is_equal(
			[
				"2:fiberglass:0:700",
				"3:livewell:2:800",
				"5:motor:2:900",
				"6:sonar:2:1400",
				"8:light_carbon:0:2000",
				"11:livewell:3:2000",
			]
		)
	)
	assert_int(int(run["final_coins"])).is_equal(530)
	assert_int(int(run["final_state"]["total_sales"])).is_equal(7930)
