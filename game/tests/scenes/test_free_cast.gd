extends GdUnitTestSuite
## Lançar onde quiser (Fase 7, Bloco A; P-36), na cena do dia: parado longe dos
## cardumes, o jogador mira e lança em qualquer ponto ao alcance; a sombra do
## peixe nada até a isca antes da mordida; parado num cardume, as regras do
## cardume voltam.

const STEP_S: float = 0.05
const MAX_STEPS: int = 4000

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


## Jogador que já aprendeu a pilotar (a lição de pilotar não cobre a da água aberta).
func _scene() -> DayController:
	var state := PlayerState.new_game(db)
	state.tips_progress["steer"] = 3
	var day := DayController.new()
	day.setup(db, state, 1, 4, pres)
	day.external_stepping = true
	add_child(day)
	day.step(STEP_S)
	return auto_free(day)


## Mira num ponto a `distance_m` à frente, longe dos cardumes, e lança com a força certa.
func _cast_ahead(day: DayController, distance_m: float) -> Vector3:
	var target := day.boat.global_position + day.boat.forward() * distance_m
	target.y = 0.0
	day.input_aim_point = target
	var power := distance_m / day.session.rod_range_m()
	day.input_action_held = true
	while day.cast_charge < power:
		day.step(STEP_S)
	day.input_action_held = false
	day.step(STEP_S)
	return target


func test_open_water_shows_its_hint_meter_and_aim() -> void:
	var day := _scene()
	assert_bool(day.session.in_open_water).is_true()
	assert_str(day.hud.hints.current_id).is_equal("open_water")
	assert_str(day.hud.hints.text()).contains("lançar onde quiser")
	assert_bool(day.hud.cast_meter.visible).is_true()
	assert_bool(day.marker.visible).is_true()
	assert_bool(day.marker.good).is_true()
	day.input_action_held = true
	day.step(STEP_S)
	assert_str(day.hud.cast_meter.find_children("*", "Label", true, false)[0].text).contains(
		"água aberta"
	)
	# Carregando: na água aberta não há risco do cardume para passar.
	assert_str(day.hud.hints.current_id).is_equal("open_water_release")


func test_cast_anywhere_and_the_fish_shadow_swims_to_the_bait() -> void:
	var day := _scene()
	var target := _cast_ahead(day, 5.0)
	assert_int(day.session.stage).is_equal(DaySession.Stage.CASTING)
	var steps := 0
	while day.session.stage != DaySession.Stage.WAITING_BITE and steps < MAX_STEPS:
		day.step(STEP_S)
		steps += 1
	var bait := day.rig.target_point()
	assert_float(Vector2(bait.x - target.x, bait.z - target.z).length()).is_less(0.6)
	assert_bool(day.fish_shadow.visible).is_false()
	var approach := float(pres.section("casting")["shadow_approach_s"])
	var first_distance := -1.0
	while day.session.stage == DaySession.Stage.WAITING_BITE and steps < MAX_STEPS:
		day.step(STEP_S)
		steps += 1
		if day.session.bite_in_s >= 0.0 and day.session.bite_in_s < approach * 0.8:
			assert_bool(day.fish_shadow.visible).is_true()
			var to_bait := Vector2(
				day.fish_shadow.position.x - bait.x, day.fish_shadow.position.z - bait.z
			)
			if first_distance < 0.0:
				first_distance = to_bait.length()
			else:
				assert_float(to_bait.length()).is_less_equal(first_distance + 0.001)
	assert_int(day.session.stage).is_equal(DaySession.Stage.BITE)
	assert_float(first_distance).is_greater(0.0)
	assert_bool(day.fish_shadow.visible).is_false()


func test_stopping_at_a_school_leaves_open_water() -> void:
	var day := _scene()
	assert_bool(day.session.in_open_water).is_true()
	var school: Vector3 = day.schools.positions[0]
	var away := day.boat.global_position - school
	away.y = 0.0
	day.boat.global_position = school + away.normalized() * 4.0
	day.step(STEP_S)
	assert_bool(day.session.in_open_water).is_false()
	assert_int(day.engaged_school).is_equal(0)
	assert_int(day.session.fish_left_in_school()).is_greater(0)


func test_open_water_message_and_cast_text() -> void:
	var day := _scene()
	var types: Array[String] = []
	for event in day.events_seen:
		types.append(String(event["type"]))
	assert_array(types).contains(["open_water"])
	_cast_ahead(day, 4.0)
	assert_str(day.hud.message_label.text).contains("(água aberta)")


func test_autopilot_still_fishes_at_schools() -> void:
	var state := PlayerState.new_game(db)
	var day := DayController.new()
	day.setup(db, state, 1, 7, pres)
	day.external_stepping = true
	day.autopilot = AutoPilot.new(PlayerBot.new(db.bot_profile("skilled"), Rng.new(7)))
	add_child(auto_free(day))
	var steps := 0
	while not day.is_finished() and steps < 20000:
		day.step(STEP_S)
		steps += 1
	var open_casts := 0
	var casts := 0
	for event in day.events_seen:
		if event["type"] == "cast":
			casts += 1
			open_casts += 0 if bool(event["on_target"]) else 1
	assert_int(casts).is_greater(3)
	assert_int(open_casts).is_equal(0)
