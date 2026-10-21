extends GdUnitTestSuite
## Mapa lateral (P-30): posição e direção do barco, rastro, cais e o sonar
## acendendo os cardumes no alcance dele (a carta e a varredura estão em
## test_chart_and_sonar.gd).

const STEP_S: float = 0.05

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func _map() -> MiniMap:
	var map := MiniMap.new()
	add_child(auto_free(map))
	var none: Array[Dictionary] = []
	map.setup(pres.section("minimap"), 110.0, Vector3(0.0, 0.0, 100.0), none)
	return map


func test_lake_center_is_the_map_center_and_north_is_up() -> void:
	var map := _map()
	var center := Vector2(map.size_px, map.size_px) * 0.5
	assert_vector(map.to_map(Vector2.ZERO)).is_equal(center)
	# Norte (−z) para cima; leste (+x) para a direita; a margem cabe no mapa.
	assert_float(map.to_map(Vector2(0.0, -110.0)).y).is_less(center.y)
	assert_float(map.to_map(Vector2(110.0, 0.0)).x).is_greater(center.x)
	assert_float(map.to_map(Vector2(110.0, 0.0)).x).is_less_equal(map.size_px)
	assert_float(map.to_map(Vector2(0.0, 110.0)).y).is_less_equal(map.size_px)


func test_boat_position_and_heading() -> void:
	var map := _map()
	var none: Array[Vector3] = []
	map.update_state(STEP_S, Vector3(20.0, 0.0, -30.0), Vector3(1.0, 0.0, 0.0), 0.0, none)
	assert_vector(map.boat).is_equal(Vector2(20.0, -30.0))
	assert_float(map.heading_rad).is_equal_approx(PI / 2.0, 0.0001)


func test_trail_keeps_a_point_every_interval_up_to_the_limit() -> void:
	var map := _map()
	var cfg: Dictionary = pres.section("minimap")
	var every := float(cfg["trail_every_s"])
	var none: Array[Vector3] = []
	for i in 400:
		map.update_state(every, Vector3(float(i), 0.0, 0.0), Vector3.FORWARD, 0.0, none)
	assert_int(map.trail.size()).is_equal(int(cfg["trail_points"]))
	assert_float(map.trail[-1].x).is_equal(399.0)


func test_sonar_shows_only_the_schools_in_range() -> void:
	var map := _map()
	var found: Array[Vector3] = [Vector3(0.0, 0.0, 10.0), Vector3(0.0, 0.0, 80.0)]
	var period := float(pres.section("minimap")["sonar"]["sweep_period_s"])
	var echoes: int = 0
	# Quase uma volta: o feixe sai do leste e passa pelo sul num quarto dela.
	for i in floori(period / STEP_S) - 1:
		echoes += map.update_state(STEP_S, Vector3.ZERO, Vector3.FORWARD, 30.0, found)
	assert_int(echoes).is_equal(1)
	assert_int(map.sonar.blips.size()).is_equal(1)
	assert_vector(map.sonar.blips[0]["at"]).is_equal(Vector2(0.0, 10.0))
	# Sem sonar (nível 1), o mapa não mostra cardumes.
	map.update_state(STEP_S, Vector3.ZERO, Vector3.FORWARD, 0.0, found)
	assert_array(map.sonar.blips).is_empty()


func test_day_scene_feeds_the_map_and_hides_it_at_the_end() -> void:
	var state := PlayerState.new_game(db)
	state.upgrade_levels["sonar"] = 3
	var day := DayController.new()
	day.setup(db, state, 1, 4, pres)
	day.external_stepping = true
	add_child(day)
	auto_free(day)
	day.step(STEP_S)
	var map: MiniMap = day.hud.mini_map
	assert_bool(map.visible).is_true()
	assert_vector(map.dock).is_equal(Vector2(day.dock_point.x, day.dock_point.z))
	assert_float(map.sonar_range_m).is_equal(float(db.upgrade_level("sonar", 3)["range_m"]))
	assert_int(map.obstacles.size()).is_equal(day.boat.obstacles.size())
	day.input_throttle = 1.0
	for i in 40:
		day.step(STEP_S)
	assert_float(map.boat.distance_to(map.trail[0])).is_greater(1.0)
	(
		day
		. hud
		. show_result(
			{
				"day": 1,
				"stars": 1,
				"score": 10,
				"fish": 1,
				"coins_from_sales": 10,
				"star_reward": 50,
				"goal_met": true,
			},
			false
		)
	)
	assert_bool(map.visible).is_false()
