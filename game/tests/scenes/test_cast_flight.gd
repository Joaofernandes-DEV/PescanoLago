extends GdUnitTestSuite
## Lançamento animado (Fase 6, "Navegar e pescar com clareza"): a isca voa da
## ponta da vara em arco e pousa na água no tempo de lançar das regras.

const STEP_S: float = 0.05

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func _rig() -> FishingRig:
	var rig := FishingRig.new()
	rig.setup(pres.section("fish"))
	add_child(rig)
	return auto_free(rig)


func test_bait_flies_in_an_arc_and_lands_on_time() -> void:
	var rig := _rig()
	var landed: Array[Vector3] = []
	rig.landed.connect(func(point: Vector3) -> void: landed.append(point))
	var tip := Vector3(0.0, 2.0, 0.0)
	var target := Vector3(8.0, 0.0, 0.0)
	rig.launch(tip, target, 1.2, 1.5)
	assert_bool(rig.flying).is_true()
	assert_bool(rig.buoy.visible).is_true()
	var splashes_before := rig.splashes
	for i in 12:
		rig.step(STEP_S, tip, false)
	# Metade do voo: no meio do caminho e acima da água.
	assert_float(rig.buoy.global_position.x).is_between(3.0, 5.0)
	assert_float(rig.buoy.global_position.y).is_greater(1.0)
	assert_array(landed).is_empty()
	for i in 13:
		rig.step(STEP_S, tip, false)
	assert_bool(rig.flying).is_false()
	assert_int(landed.size()).is_equal(1)
	assert_float(landed[0].distance_to(target)).is_less(0.001)
	assert_int(rig.splashes - splashes_before).is_equal(1)


func test_flight_point_starts_at_the_rod_and_ends_on_the_water() -> void:
	var rig := _rig()
	rig.launch(Vector3(0.0, 2.0, 0.0), Vector3(6.0, 0.0, 0.0), 1.0, 1.0)
	assert_vector(rig.flight_point(0.0)).is_equal(Vector3(0.0, 2.0, 0.0))
	assert_vector(rig.flight_point(1.0)).is_equal(Vector3(6.0, 0.0, 0.0))
	assert_float(rig.flight_point(0.5).y).is_greater(rig.flight_point(1.0).y)


func test_hiding_the_rig_stops_the_flight() -> void:
	var rig := _rig()
	rig.launch(Vector3(0.0, 2.0, 0.0), Vector3(6.0, 0.0, 0.0), 1.0, 1.0)
	rig.hide_all()
	assert_bool(rig.flying).is_false()


func test_in_the_scene_the_bait_lands_when_the_wait_begins() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 4, pres)
	day.external_stepping = true
	add_child(day)
	auto_free(day)
	var school: Vector3 = day.schools.positions[0]
	var away := day.boat.global_position - school
	away.y = 0.0
	day.boat.global_position = school + away.normalized() * 4.0
	day.input_aim_point = school
	for i in 3:
		day.step(STEP_S)
	day.input_action_held = true
	for i in 20:
		day.step(STEP_S)
	day.input_action_held = false
	day.step(STEP_S)
	assert_int(day.session.stage).is_equal(DaySession.Stage.CASTING)
	assert_array(day.sfx.played).contains(["cast_whoosh"])
	assert_array(day.sfx.played).not_contains(["splash"])
	assert_bool(day.rig.flying).is_true()
	var cast_s := float(db.economy["fishing"]["cast_s"])
	for i in int(cast_s / STEP_S) + 2:
		day.step(STEP_S)
	assert_bool(day.rig.flying).is_false()
	assert_array(day.sfx.played).contains(["splash"])
	assert_int(day.session.stage).is_not_equal(DaySession.Stage.CASTING)
