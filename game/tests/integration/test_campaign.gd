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
