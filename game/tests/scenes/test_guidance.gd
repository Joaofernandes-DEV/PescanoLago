extends GdUnitTestSuite
## Orientações do dia de pesca (Fase 6, "Navegar e pescar com clareza"): dicas de
## controle por momento e por aparelho, que somem com o uso; medidor de força
## com o risco do cardume; alvo na água.

const STEP_S: float = 0.05

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func _scene(state: PlayerState) -> DayController:
	var day := DayController.new()
	day.setup(db, state, 1, 4, pres)
	day.external_stepping = true
	add_child(day)
	return auto_free(day)


## Para o barco ao lado do cardume 0 e mira nele.
func _park_at_school(day: DayController, distance_m: float) -> void:
	var school: Vector3 = day.schools.positions[0]
	var away := day.boat.global_position - school
	away.y = 0.0
	day.boat.global_position = school + away.normalized() * distance_m
	day.boat.velocity = Vector2.ZERO
	day.boat.speed_m_s = 0.0
	day.input_aim_point = school
	for i in 3:
		day.step(STEP_S)


func _hold(day: DayController, seconds: float) -> void:
	day.input_action_held = true
	for i in int(seconds / STEP_S):
		day.step(STEP_S)


func _release(day: DayController) -> void:
	day.input_action_held = false
	day.step(STEP_S)


# --- Escolha da dica ---


func test_each_moment_has_its_hint() -> void:
	var stage := DaySession.Stage
	assert_str(ControlHints.pick(stage.SEARCHING, false, false, false, false)).is_equal("steer")
	assert_str(ControlHints.pick(stage.SEARCHING, false, false, true, false)).is_equal("dock")
	assert_str(ControlHints.pick(stage.AT_SCHOOL, true, false, false, false)).is_equal("cast_hold")
	assert_str(ControlHints.pick(stage.AT_SCHOOL, true, true, false, false)).is_equal(
		"cast_release"
	)
	assert_str(ControlHints.pick(stage.AT_SCHOOL, true, false, false, true)).is_equal("move_closer")
	assert_str(ControlHints.pick(stage.BITE, false, false, false, false)).is_equal("hook_tap")
	assert_str(ControlHints.pick(stage.FIGHTING, false, false, false, false)).is_equal("reel_hold")
	assert_str(ControlHints.pick(stage.WAITING_BITE, false, false, false, false)).is_empty()


func test_lessons_fade_but_warnings_stay() -> void:
	assert_bool(ControlHints.still_needed("cast_hold", 2, 3)).is_true()
	assert_bool(ControlHints.still_needed("cast_hold", 3, 3)).is_false()
	assert_bool(ControlHints.still_needed("dock", 99, 3)).is_true()
	assert_bool(ControlHints.still_needed("move_closer", 99, 3)).is_true()


func test_hint_shows_keys_or_touch() -> void:
	var hints := ControlHints.new()
	add_child(auto_free(hints))
	hints.show_hint("hook_tap", false)
	assert_bool(hints.visible).is_true()
	assert_str(hints.text()).contains("Espaço")
	hints.show_hint("hook_tap", true)
	assert_str(hints.text()).contains("toque na tela")
	assert_str(hints.text()).not_contains("Espaço")
	hints.show_hint("", true)
	assert_bool(hints.visible).is_false()


func test_every_hint_has_both_texts() -> void:
	for hint_id: String in ControlHints.HINTS:
		var texts: Dictionary = ControlHints.HINTS[hint_id]
		assert_str(String(texts["keys"])).is_not_empty()
		assert_str(String(texts["touch"])).is_not_empty()
		assert_str(String(texts["touch"])).not_contains("[")


# --- Medidor de força ---


func test_meter_marks_where_the_bait_reaches_the_school() -> void:
	var meter := CastMeter.new()
	add_child(auto_free(meter))
	meter.set_state(0.5, 6.0, 8.0)
	assert_float(meter.needed).is_equal(0.75)
	assert_bool(meter.reaches()).is_false()
	meter.set_state(0.8, 6.0, 8.0)
	assert_bool(meter.reaches()).is_true()
	# Isca artificial com raio de atração: não precisa cair em cima.
	meter.set_state(0.5, 6.0, 8.0, 2.0)
	assert_bool(meter.reaches()).is_true()
	meter.set_state(1.0, 12.0, 8.0)
	assert_bool(meter.reaches()).is_false()


# --- Na cena ---


func test_scene_guides_from_steering_to_casting() -> void:
	var day := _scene(PlayerState.new_game(db))
	day.step(STEP_S)
	assert_str(day.hud.hints.current_id).is_equal("steer")
	assert_bool(day.marker.visible).is_false()
	_park_at_school(day, 4.0)
	assert_int(day.session.stage).is_equal(DaySession.Stage.AT_SCHOOL)
	assert_str(day.hud.hints.current_id).is_equal("cast_hold")
	assert_bool(day.hud.cast_meter.visible).is_true()
	assert_bool(day.marker.visible).is_true()
	assert_bool(day.marker.good).is_true()
	_hold(day, 0.3)
	assert_str(day.hud.hints.current_id).is_equal("cast_release")
	# Com pouca força a isca ainda cai curta: o alvo fica laranja.
	assert_bool(day.marker.good).is_false()
	_hold(day, 1.0)
	assert_bool(day.marker.good).is_true()
	_release(day)
	assert_int(day.session.stage).is_equal(DaySession.Stage.CASTING)
	assert_bool(day.marker.visible).is_false()


func test_far_school_asks_to_move_closer() -> void:
	var day := _scene(PlayerState.new_game(db))
	# O bambu alcança 8 m; o cardume a 15 m está fora do alcance.
	_park_at_school(day, 15.0)
	assert_int(day.session.stage).is_equal(DaySession.Stage.AT_SCHOOL)
	assert_str(day.hud.hints.current_id).is_equal("move_closer")
	assert_float(day.power_needed()).is_greater(1.0)


func test_cast_lesson_fades_after_three_casts() -> void:
	var state := PlayerState.new_game(db)
	state.tips_progress["cast_hold"] = 3
	var day := _scene(state)
	_park_at_school(day, 4.0)
	assert_str(day.hud.hints.current_id).is_empty()
	# O medidor e o alvo continuam: são parte do lançamento, não lição.
	assert_bool(day.hud.cast_meter.visible).is_true()
	assert_bool(day.marker.visible).is_true()


func test_player_actions_count_toward_the_tips() -> void:
	var state := PlayerState.new_game(db)
	var day := _scene(state)
	_park_at_school(day, 4.0)
	assert_int(state.tip_count("steer")).is_equal(1)
	_hold(day, 1.0)
	_release(day)
	day.step(STEP_S)
	assert_int(state.tip_count("cast_hold")).is_equal(1)
	assert_int(state.tip_count("cast_release")).is_equal(1)


func test_touch_mode_follows_the_last_device() -> void:
	var day := _scene(PlayerState.new_game(db))
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	day._input(touch)
	assert_bool(day.touch_mode).is_true()
	day._input(InputEventKey.new())
	assert_bool(day.touch_mode).is_false()
