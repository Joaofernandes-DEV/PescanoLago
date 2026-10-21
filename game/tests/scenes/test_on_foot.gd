extends GdUnitTestSuite
## A pé no sítio dos avós (Fase 7, Bloco B, item 3; P-41): o Tom anda até o barco
## e embarca, e só então o dia de pesca começa.

const STEP_S: float = 1.0 / 60.0

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func _day(on_foot: bool = true) -> DayController:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 7, pres)
	day.on_foot = on_foot
	day.external_stepping = true
	add_child(day)
	return auto_free(day)


func _run(day: DayController, seconds: float) -> void:
	for i in int(seconds / STEP_S):
		day.step(STEP_S)


func test_sitio_scenery_has_the_walk_points_and_walls() -> void:
	var day := _day(false)
	assert_object(day.walker).is_null()
	assert_object(day.find_child("SM_sitio_avos", true, false)).is_not_null()
	assert_object(day.find_child("LOC_walk_start", true, false)).is_not_null()
	assert_object(day.find_child("LOC_sitio_berth", true, false)).is_not_null()
	# As paredes são só de quem anda: o barco não bate nelas.
	for box in day.boat.obstacles:
		assert_bool(String(box["name"]).begins_with(LakeWorld.WALL_PREFIX)).is_false()
	var tom := CharacterPuppet.create("tom_standing")
	auto_free(tom)
	assert_int(tom.legs.size()).is_equal(2)


func test_walk_to_the_boat_and_board() -> void:
	var day := _day()
	var walker: OnFoot = day.walker
	assert_object(walker).is_not_null()
	assert_bool((day.characters["tom"] as CharacterPuppet).visible).is_false()
	# Andando para trás, a casa e a cerca seguram o Tom (ele não entra na varanda).
	day.input_throttle = -1.0
	_run(day, 6.0)
	assert_bool(is_nan(walker.height_at(walker.tom.global_position))).is_false()
	# Até o cais: o relógio do dia ainda não corre.
	day.input_throttle = 1.0
	var t := 0.0
	while not walker.can_board() and t < 20.0:
		_run(day, 0.25)
		t += 0.25
	assert_bool(walker.can_board()).is_true()
	assert_float(day.session.clock.elapsed_s).is_equal(0.0)
	day.input_throttle = 0.0
	day.input_action_held = true
	day.step(STEP_S)
	day.input_action_held = false
	_run(day, float(pres.section("walk")["board_s"]) * 2.0 + 0.2)
	assert_int(walker.stage).is_equal(OnFoot.Stage.DONE)
	assert_bool((day.characters["tom"] as CharacterPuppet).visible).is_true()
	_run(day, 1.0)
	assert_float(day.session.clock.elapsed_s).is_greater(0.5)


func test_autopilot_starts_on_the_boat() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 7, pres)
	day.on_foot = true
	day.autopilot = AutoPilot.new(PlayerBot.new(db.bot_profile("skilled"), Rng.new(5)))
	day.external_stepping = true
	add_child(auto_free(day))
	assert_object(day.walker).is_null()
