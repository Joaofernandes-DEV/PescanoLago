extends GdUnitTestSuite
## Cena jogável do dia (Fase 3): barco, entrada virtual, cardumes, lançamento,
## mordida, briga, cais e fim do dia, na cena 3D de verdade (headless).

const STEP_S: float = 0.05
const MAX_STEPS: int = 20000

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func _scene(seed_value: int, with_autopilot: bool) -> DayController:
	var controller := DayController.new()
	controller.setup(db, PlayerState.new_game(db), 1, seed_value, pres)
	controller.external_stepping = true
	if with_autopilot:
		controller.autopilot = AutoPilot.new(
			PlayerBot.new(db.bot_profile("skilled"), Rng.new(seed_value))
		)
	add_child(controller)
	return auto_free(controller)


func _types(controller: DayController) -> Array[String]:
	var types: Array[String] = []
	for event in controller.events_seen:
		types.append(String(event["type"]))
	return types


func _first_event(controller: DayController, event_type: String) -> Dictionary:
	for event in controller.events_seen:
		if event["type"] == event_type:
			return event
	return {}


func test_boat_moves_forward_turns_and_stays_in_the_lake() -> void:
	var boat := BoatController.new()
	add_child(auto_free(boat))
	boat.setup(pres.section("navigation"), 1.0, 20.0)
	var start := boat.global_position
	boat.throttle = 1.0
	for i in 60:
		boat.step(STEP_S)
	assert_float((boat.global_position - start).dot(boat.forward())).is_greater(1.0)
	var heading := boat.rotation.y
	boat.steer = 1.0
	for i in 40:
		boat.step(STEP_S)
	assert_float(boat.rotation.y).is_less(heading)
	boat.steer = 0.0
	for i in 2000:
		boat.step(STEP_S)
	assert_float(Vector2(boat.position.x, boat.position.z).length()).is_less_equal(20.001)


func test_scene_builds_world_from_blender_models() -> void:
	var c := _scene(1, false)
	assert_object(c.boat.model).is_not_null()
	assert_object(c.find_child("SM_terrain", true, false)).is_not_null()
	assert_object(c.find_child("SM_water_surface", true, false)).is_not_null()
	assert_float(c.boat.attach_point("LOC_rod_tip").y).is_greater(1.0)
	assert_int(c.schools.positions.size()).is_equal(int(pres.section("schools")["active"]))
	assert_bool(c.session.manual_navigation).is_true()


func test_autopilot_plays_a_full_day_through_the_scene() -> void:
	var c := _scene(7, true)
	var steps := 0
	while not c.is_finished() and steps < MAX_STEPS:
		c.step(STEP_S)
		steps += 1
	assert_bool(c.is_finished()).is_true()
	var types := _types(c)
	for expected: String in ["school_found", "cast", "bite", "hooked", "caught", "day_ended"]:
		assert_array(types).contains([expected])
	assert_int(int(c.session.result["fish"])).is_greater(3)
	assert_array(c.sfx.played).contains(["splash", "bite_plop", "catch_jingle", "day_end_chime"])
	assert_bool(c.hud.result_panel.visible).is_true()


func test_player_input_path_casts_at_the_school() -> void:
	var c := _scene(3, false)
	# Leva o barco parado até perto do primeiro cardume, como o jogador faria.
	var school: Vector3 = c.schools.positions[0]
	c.boat.global_position = school + Vector3(0.0, 0.0, -5.0)
	c.step(STEP_S)
	assert_int(c.session.stage).is_equal(DaySession.Stage.AT_SCHOOL)
	assert_int(c.engaged_school).is_equal(0)
	c.input_aim_point = school
	c.input_action_held = true
	for i in 10:
		c.step(STEP_S)
	assert_float(c.cast_charge).is_greater(0.0)
	c.input_action_held = false
	c.step(STEP_S)
	assert_int(c.session.stage).is_equal(DaySession.Stage.CASTING)
	assert_bool(c.rig.buoy.visible).is_true()
	var cast_event: Dictionary = _first_event(c, "cast")
	assert_bool(bool(cast_event["on_target"])).is_true()


func test_moving_away_leaves_the_school() -> void:
	var c := _scene(3, false)
	c.boat.global_position = c.schools.positions[0] + Vector3(0.0, 0.0, -5.0)
	c.step(STEP_S)
	assert_int(c.session.stage).is_equal(DaySession.Stage.AT_SCHOOL)
	c.input_throttle = 1.0
	for i in 20:
		c.step(STEP_S)
	assert_int(c.session.stage).is_equal(DaySession.Stage.SEARCHING)
	assert_int(c.engaged_school).is_equal(-1)


func test_docking_sells_the_livewell() -> void:
	var c := _scene(3, false)
	c.session.livewell.add(FishCatch.new("common_carp", 9.0))
	c.boat.global_position = c.dock_point
	c.step(STEP_S)
	assert_int(c.session.livewell.count()).is_equal(0)
	assert_array(_types(c)).contains(["docked"])


func test_weight_text_uses_grams_for_small_fish() -> void:
	assert_str(DayController.weight_text(0.042)).is_equal("42 g")
	assert_str(DayController.weight_text(3.24)).is_equal("3.2 kg")
