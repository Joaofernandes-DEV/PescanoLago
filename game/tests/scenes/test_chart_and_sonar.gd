extends GdUnitTestSuite
## Mapa e sonar (Fase 7, Bloco A, item 5; P-38): a carta náutica tirada do
## terreno de cada região (contorno real da margem e profundidade em tons), a
## varredura do sonar com os pontos que acendem e somem e o ping, e o mapa grande
## numa tecla trocável.

const STEP_S: float = 0.05
const FRAME_S: float = 1.0 / 30.0

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.full_db()
	pres = PresentationConfig.load_default()


func after_test() -> void:
	InputSetup.reset_bindings()


func _chart(region_id: String) -> LakeChart:
	var parent := Node3D.new()
	add_child(auto_free(parent))
	var lake: Node3D = LakeWorld.add_lake(parent, region_id)
	return LakeChart.from_lake(lake, pres.section("minimap"), pres.number("lake", "shore_radius_m"))


func _scene(day_number: int = 1, sonar_level: int = 1) -> DayController:
	var state := PlayerState.new_game(db)
	state.upgrade_levels["sonar"] = sonar_level
	var day := DayController.new()
	day.setup(db, state, day_number, 13, pres)
	day.external_stepping = true
	add_child(day)
	day.step(STEP_S)
	return auto_free(day)


func _press(day: DayController, keycode: int) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = keycode as Key
	key.pressed = true
	day._unhandled_input(key)


func _sweep_cfg() -> Dictionary:
	return pres.section("minimap")["sonar"]


func test_shore_follows_the_real_terrain_not_a_circle() -> void:
	var chart := _chart("margem_rasa")
	var shore_m: float = pres.number("lake", "shore_radius_m")
	assert_int(chart.shore.size()).is_equal(int(pres.section("minimap")["chart_rays"]))
	var nearest: float = INF
	var farthest: float = 0.0
	for point in chart.shore:
		# Na margem, o terreno está na altura da água.
		assert_float(absf(chart.height_at(point))).is_less(0.3)
		nearest = minf(nearest, point.length())
		farthest = maxf(farthest, point.length())
	# As enseadas do Blender: o contorno varia mais de 2 m, perto do raio do jogo.
	assert_float(farthest - nearest).is_greater(2.0)
	assert_float(nearest).is_greater(shore_m - 5.0)
	assert_float(farthest).is_less(shore_m + 5.0)
	assert_array(Array(Geometry2D.triangulate_polygon(chart.shore))).is_not_empty()


func test_depth_lines_are_nested_from_shore_to_the_middle() -> void:
	var chart := _chart("margem_rasa")
	assert_float(chart.depth_at(Vector2.ZERO)).is_equal_approx(
		pres.number("lake", "lakebed_depth_m"), 0.05
	)
	assert_float(chart.depth_at(Vector2(0.0, 125.0))).is_equal(0.0)
	assert_int(chart.isobaths.size()).is_greater_equal(2)
	var outer: PackedVector2Array = chart.shore
	var last_depth: float = 0.0
	for isobath in chart.isobaths:
		var depth: float = float(isobath["depth_m"])
		assert_float(depth).is_greater(last_depth)
		var polygon: PackedVector2Array = isobath["polygon"]
		for ray in polygon.size():
			assert_float(polygon[ray].length()).is_less_equal(outer[ray].length() + 0.01)
			# Na linha, o fundo está na profundidade dela.
			if polygon[ray].length() > 2.0:
				assert_float(chart.depth_at(polygon[ray])).is_equal_approx(depth, 0.3)
		outer = polygon
		last_depth = depth


func test_deep_waters_chart_is_deeper_and_darker() -> void:
	var shallow := _chart("margem_rasa")
	var deep := _chart("aguas_fundas")
	assert_float(deep.max_depth_m).is_greater(shallow.max_depth_m + 1.0)
	assert_int(deep.isobaths.size()).is_greater(shallow.isobaths.size())
	var map := MiniMap.new()
	add_child(auto_free(map))
	var none: Array[Dictionary] = []
	map.setup(pres.section("minimap"), 110.0, Vector3.ZERO, none)
	assert_float(map.depth_color(4.0).get_luminance()).is_less(map.depth_color(0.0).get_luminance())


func test_every_region_has_a_chart_on_the_map() -> void:
	for day_number: int in [1, 9, 16]:
		var day := _scene(day_number)
		var map: MiniMap = day.hud.mini_map
		assert_object(map.chart).is_not_null()
		assert_int(map.chart.shore.size()).is_greater(0)
		assert_str(map.title).is_equal(String(db.region(day.region_id)["name"]))
		# A carta parada é feita uma vez, em poucos comandos de desenho.
		assert_int(map.chart_triangles()).is_greater(100)


func test_shape_batch_keeps_shapes_as_triangles() -> void:
	var batch := ShapeBatch.new()
	batch.add_circle(Vector2.ZERO, 5.0, Color.WHITE, 12)
	assert_int(batch.triangle_count()).is_equal(12)
	batch.add_rect(Rect2(0, 0, 4, 4), Color.RED)
	assert_int(batch.triangle_count()).is_equal(14)
	batch.add_line(Vector2.ZERO, Vector2(10, 0), 2.0, Color.BLUE)
	assert_int(batch.triangle_count()).is_equal(16)
	assert_int(batch.colors.size()).is_equal(batch.points.size())
	batch.clear()
	assert_int(batch.triangle_count()).is_equal(0)


func test_sweep_turns_clockwise_and_lights_schools_in_range() -> void:
	var sweep := SonarSweep.new()
	sweep.setup(_sweep_cfg())
	var period: float = float(_sweep_cfg()["sweep_period_s"])
	# Um cardume ao sul, a 10 m, e outro a 80 m (fora do alcance de 30 m).
	var schools: Array[Vector2] = [Vector2(0.0, 10.0), Vector2(80.0, 0.0)]
	var echoes: int = 0
	var t: float = 0.0
	while t < period:
		echoes += sweep.step(STEP_S, Vector2.ZERO, 30.0, schools)
		t += STEP_S
	# Uma volta: um ping só, do cardume no alcance.
	assert_int(echoes).is_equal(1)
	assert_int(sweep.blips.size()).is_equal(1)
	assert_int(int(sweep.blips[0]["school"])).is_equal(0)
	# O feixe passa pelo sul (+z) um quarto de volta depois do leste: sentido do relógio.
	var fresh := SonarSweep.new()
	fresh.setup(_sweep_cfg())
	var south: Array[Vector2] = [Vector2(0.0, 10.0)]
	var quarter: int = 0
	t = 0.0
	while t < period * 0.2:
		quarter += fresh.step(STEP_S, Vector2.ZERO, 30.0, south)
		t += STEP_S
	assert_int(quarter).is_equal(0)
	while t < period * 0.3:
		quarter += fresh.step(STEP_S, Vector2.ZERO, 30.0, south)
		t += STEP_S
	assert_int(quarter).is_equal(1)


func test_blips_fade_out_and_no_sonar_means_no_sweep() -> void:
	var sweep := SonarSweep.new()
	sweep.setup(_sweep_cfg())
	var schools: Array[Vector2] = [Vector2(5.0, 0.0)]
	var t: float = 0.0
	while sweep.blips.is_empty():
		sweep.step(STEP_S, Vector2.ZERO, 30.0, schools)
	assert_float(sweep.glow(sweep.blips[0])).is_greater(0.9)
	# Longe do cardume, o ponto vai sumindo até apagar.
	var far: Array[Vector2] = []
	sweep.step(float(_sweep_cfg()["blip_fade_s"]) * 0.5, Vector2.ZERO, 30.0, far)
	assert_float(sweep.glow(sweep.blips[0])).is_between(0.3, 0.7)
	sweep.step(float(_sweep_cfg()["blip_fade_s"]), Vector2.ZERO, 30.0, far)
	assert_array(sweep.blips).is_empty()
	# Sem sonar (nível 1), nada acende.
	while t < float(_sweep_cfg()["sweep_period_s"]) * 2.0:
		assert_int(sweep.step(STEP_S, Vector2.ZERO, 0.0, schools)).is_equal(0)
		t += STEP_S
	assert_array(sweep.blips).is_empty()


func test_day_scene_pings_with_sonar_and_stays_quiet_without() -> void:
	var period: float = float(_sweep_cfg()["sweep_period_s"])
	var with_sonar := _scene(1, 5)
	for i in ceili(period / STEP_S) + 1:
		with_sonar.step(STEP_S)
	assert_bool(with_sonar.sfx.played.has("sonar_ping")).is_true()
	assert_array(with_sonar.hud.mini_map.sonar.blips).is_not_empty()
	var without := _scene(1, 1)
	for i in ceili(period / STEP_S) + 1:
		without.step(STEP_S)
	assert_bool(without.sfx.played.has("sonar_ping")).is_false()
	assert_array(without.hud.mini_map.sonar.blips).is_empty()


func test_map_key_opens_the_big_map_beside_the_boat() -> void:
	var day := _scene()
	var map: MiniMap = day.hud.mini_map
	var small: float = map.size_px
	_press(day, KEY_M)
	assert_bool(day.map_view_open).is_true()
	assert_bool(map.expanded).is_true()
	assert_float(map.size_px).is_equal(float(pres.section("minimap")["big_size_px"]))
	assert_float(map.size_px).is_greater(small * 2.0)
	day.step(FRAME_S)
	await get_tree().process_frame
	var screen: Rect2 = map.get_viewport_rect()
	assert_bool(screen.encloses(map.get_global_rect())).is_true()
	# O barco, no meio da tela, e as pílulas da esquerda continuam à vista.
	assert_bool(map.get_global_rect().has_point(screen.get_center())).is_false()
	for label: Label in day.hud.stat_labels.values():
		var pill := label.get_parent().get_parent() as Control
		assert_bool(map.get_global_rect().intersects(pill.get_global_rect())).is_false()
	# A dica mostra a tecla de fechar, e a mesma tecla fecha.
	assert_str(day.hud.hints.current_id).is_equal("map_close")
	assert_str(day.hud.hints.text()).contains("M")
	_press(day, KEY_M)
	assert_bool(day.map_view_open).is_false()
	assert_float(map.size_px).is_equal(small)
	day.step(FRAME_S)
	assert_str(day.hud.hints.current_id).is_not_equal("map_close")


func test_action_bite_and_cooler_close_the_big_map() -> void:
	var day := _scene()
	_press(day, KEY_M)
	day.input_action_held = true
	day.step(FRAME_S)
	day.input_action_held = false
	day.step(FRAME_S)
	assert_bool(day.map_view_open).is_false()
	# Uma mordida fecha o mapa para o jogador ver a boia.
	_press(day, KEY_M)
	day.session._emit("bite", {})
	day.step(FRAME_S)
	assert_bool(day.map_view_open).is_false()
	# A caixa de isopor e o mapa grande não abrem juntos.
	_press(day, KEY_M)
	_press(day, InputSetup.primary_key(InputSetup.COOLER_VIEW))
	assert_bool(day.cooler_view_open).is_true()
	assert_bool(day.map_view_open).is_false()
	_press(day, KEY_M)
	assert_bool(day.map_view_open).is_true()
	assert_bool(day.cooler_view_open).is_false()


func test_map_key_can_be_rebound() -> void:
	assert_array(Array(InputSetup.REBINDABLE)).contains([InputSetup.MAP_VIEW])
	assert_str(String(InputSetup.ACTION_NAMES[InputSetup.MAP_VIEW])).is_not_empty()
	assert_int(InputSetup.primary_key(InputSetup.MAP_VIEW)).is_equal(KEY_M)
	InputSetup.bind_primary(InputSetup.MAP_VIEW, KEY_K)
	var day := _scene()
	_press(day, KEY_M)
	assert_bool(day.map_view_open).is_false()
	_press(day, KEY_K)
	assert_bool(day.map_view_open).is_true()
	day.step(FRAME_S)
	assert_str(day.hud.hints.text()).contains("K")


func test_hint_teaches_the_map_key_after_steering() -> void:
	var day := _scene()
	var show_until: int = int(pres.number("hints", "show_until_count"))
	day.step(FRAME_S)
	assert_str(day.hud.hints.current_id).is_equal("steer")
	# Navegando (procurando peixe), quem já pilota vê a tecla do mapa.
	day._state.tips_progress["steer"] = show_until
	day.input_throttle = 1.0
	for i in 10:
		day.step(FRAME_S)
	assert_int(day.session.stage).is_equal(DaySession.Stage.SEARCHING)
	assert_str(day.hud.hints.current_id).is_equal("map_view")
	assert_str(day.hud.hints.text()).contains("M")
	# Quem abre o mapa aprende: a dica conta como as outras.
	for i in show_until:
		_press(day, KEY_M)
		_press(day, KEY_M)
	day.step(FRAME_S)
	assert_int(day._state.tip_count("map_view")).is_equal(show_until)
	assert_str(day.hud.hints.current_id).is_not_equal("map_view")
