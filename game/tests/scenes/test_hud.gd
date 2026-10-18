extends GdUnitTestSuite
## HUD da Fase 5: ícones do Blender, pílulas com os números do dia e a tela de
## fim de dia com as estrelas.

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func test_blender_model_has_every_hud_icon() -> void:
	var names := HudIcon.available()
	for icon: String in ["clock", "goal", "livewell", "combo", "coin", "bait", "star", "fish"]:
		assert_array(Array(names)).contains([icon])


func test_icon_is_drawn_once_from_its_own_viewport() -> void:
	var icon := HudIcon.create("coin", 40.0)
	add_child(auto_free(icon))
	assert_object(icon.viewport).is_not_null()
	assert_bool(icon.viewport.own_world_3d).is_true()
	assert_bool(icon.viewport.transparent_bg).is_true()
	assert_int(icon.viewport.render_target_update_mode).is_equal(SubViewport.UPDATE_ONCE)
	assert_object(icon.texture).is_not_null()
	assert_object(icon.viewport.find_child("SM_icon_coin", true, false)).is_not_null()


func test_corner_pills_show_the_day_numbers() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 1, pres)
	day.external_stepping = true
	add_child(auto_free(day))
	day.step(0.05)
	var labels: Dictionary = day.hud.stat_labels
	for key: String in ["time", "goal", "livewell", "combo", "coins", "bait"]:
		assert_str((labels[key] as Label).text).is_not_empty()
	assert_str((labels["time"] as Label).text).is_equal("4:00")
	assert_str((labels["livewell"] as Label).text).is_equal("0/8")
	assert_str((labels["goal"] as Label).text).contains("8 peixes")
	assert_str(day.hud.title_label.text).contains("Dia 1")
	# Sem sonar no nível 1, a linha do sonar fica escondida.
	assert_bool(day.hud.sonar_label.visible).is_false()


func test_result_screen_lights_the_earned_stars() -> void:
	var hud := DayHud.new()
	add_child(auto_free(hud))
	(
		hud
		. show_result(
			{
				"day": 3,
				"stars": 2,
				"score": 300,
				"fish": 9,
				"coins_from_sales": 250,
				"star_reward": 120,
				"goal_met": true,
			},
			true
		)
	)
	assert_bool(hud.result_panel.visible).is_true()
	assert_int(hud.stars_shown()).is_equal(2)
	assert_str(hud.result_title.text).is_equal("Fim do dia 3")
	assert_str(hud.result_label.text).contains("Dia 4 liberado")


func test_ui_scales_with_the_window() -> void:
	assert_str(String(ProjectSettings.get_setting("display/window/stretch/mode"))).is_equal(
		"canvas_items"
	)
	assert_int(int(ProjectSettings.get_setting("display/window/size/viewport_width"))).is_equal(
		1280
	)
