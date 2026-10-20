extends GdUnitTestSuite
## Remanso das Vitórias-régias (Fase 6, etapa 6; P-32): cena própria carregada só
## nos dias dele, água verde-escura e parada, manchas de vitórias-régias que o
## barco contorna (também no mapa lateral), capivaras e jacarés, e o tucunaré-azul.

const STEP_S: float = 0.05
const MAX_STEPS: int = 20000
const REMANSO_DAY: int = 9

var db: ContentDB
var mvp: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.full_db()
	mvp = TestContent.db()
	pres = PresentationConfig.load_default()


func _day(source: ContentDB, day_number: int, seed_value: int = 5) -> DayController:
	var controller := DayController.new()
	controller.setup(source, PlayerState.new_game(source), day_number, seed_value, pres)
	controller.external_stepping = true
	add_child(controller)
	return auto_free(controller)


func _lily_boxes(controller: DayController) -> Array[Dictionary]:
	var boxes: Array[Dictionary] = []
	for box in controller.boat.obstacles:
		if String(box["name"]).begins_with(MiniMap.LILY_PREFIX):
			boxes.append(box)
	return boxes


func test_region_without_scene_uses_margem_rasa() -> void:
	assert_str(LakeWorld.scenery_region("remanso")).is_equal("remanso")
	assert_str(LakeWorld.scenery_region("poco_fundo")).is_equal("margem_rasa")
	# Toda região com cena tem aparência em presentation.json, e vice-versa.
	var looks: Array = pres.section("region_looks").keys()
	looks.sort()
	var scenes: Array = LakeWorld.REGION_SCENES.keys()
	scenes.sort()
	assert_array(looks).is_equal(scenes)


func test_remanso_day_loads_only_its_own_scenery() -> void:
	var c := _day(db, REMANSO_DAY)
	assert_str(c.region_id).is_equal("remanso")
	for part: String in [
		"SM_remanso_terrain", "SM_remanso_pier", "SM_remanso_plants", "SM_remanso_bank"
	]:
		assert_object(c.find_child(part, true, false)).is_not_null()
	assert_object(c.find_child("SM_porto_manso", true, false)).is_null()
	assert_object(c.find_child("SM_terrain", true, false)).is_null()
	# Sem Porto Manso, sem Tio Zeca e Dona Marô; a tripulação continua no barco.
	assert_bool(c.characters.has("zeca")).is_false()
	assert_bool(c.characters.has("tom")).is_true()
	var limit := pres.number("lake", "boat_limit_radius_m")
	assert_float(Vector2(c.dock_point.x, c.dock_point.z).length()).is_less(limit)


func test_mvp_day_9_stays_on_margem_rasa() -> void:
	var c := _day(mvp, REMANSO_DAY)
	assert_str(c.region_id).is_equal("margem_rasa")
	assert_object(c.find_child("SM_porto_manso", true, false)).is_not_null()
	assert_object(c.find_child("SM_remanso_terrain", true, false)).is_null()
	assert_object(c.animals).is_not_null()
	assert_int(c.animals.capybaras.size()).is_equal(0)


func test_remanso_water_is_dark_green_and_calm() -> void:
	var c := _day(db, REMANSO_DAY)
	var looks: Dictionary = pres.section("region_looks")["remanso"]
	var shallow: Color = c.water.material.get_shader_parameter("shallow_color")
	assert_object(shallow).is_equal(PresentationConfig.color(looks["water"]["shallow_color"]))
	var base: Array = pres.section("water")["waves"]
	var calm: Array = LakeWorld.water_config(pres, "remanso")["waves"]
	var scale := float(looks["water"]["wave_scale"])
	for i in base.size():
		assert_float(float(calm[i]["amplitude_m"])).is_equal_approx(
			float(base[i]["amplitude_m"]) * scale, 0.0001
		)
	# O config de presentation.json não muda (a Margem Rasa continua com as ondas dela).
	(
		assert_float(float(LakeWorld.water_config(pres, "margem_rasa")["waves"][0]["amplitude_m"]))
		. is_equal(float(base[0]["amplitude_m"]))
	)


func test_lily_patches_block_the_boat_and_show_on_the_map() -> void:
	var c := _day(db, REMANSO_DAY)
	var lilies := _lily_boxes(c)
	assert_int(lilies.size()).is_equal(6)
	var schools: Dictionary = pres.section("schools")
	var limit := pres.number("lake", "boat_limit_radius_m")
	for box in lilies:
		var center: Vector2 = box["center"]
		var half: Vector2 = box["half"]
		# Entre a área dos cardumes e o limite do barco: um cardume nunca cai numa mancha.
		var reach := float(schools["spawn_max_radius_m"]) + float(schools["radius_m"])
		assert_float(center.length() - minf(half.x, half.y)).is_greater(reach)
		assert_float(center.length()).is_less(limit)
	assert_object(c.hud.mini_map.water_color).is_equal(
		PresentationConfig.color(pres.section("region_looks")["remanso"]["map_water"])
	)
	# A caixa do trapiche também bloqueia.
	assert_int(c.boat.obstacles.size()).is_equal(lilies.size() + 1)


func test_boat_bumps_into_a_lily_patch() -> void:
	var c := _day(db, REMANSO_DAY)
	var box: Dictionary = _lily_boxes(c)[0]
	var center: Vector2 = box["center"]
	var toward := -center.normalized()
	# Barco parado de frente para a mancha, vindo do centro do lago.
	var start := center + toward * 9.0
	c.boat.global_position = Vector3(start.x, 0.0, start.y)
	c.boat.rotation.y = atan2(-toward.x, -toward.y)
	c.input_throttle = 1.0
	var half: Vector2 = box["half"]
	var entered := false
	for i in 200:
		c.step(STEP_S)
		var at := Vector2(c.boat.global_position.x, c.boat.global_position.z)
		var local := (at - center).rotated(-float(box["angle"]))
		entered = entered or (absf(local.x) < half.x and absf(local.y) < half.y)
	assert_bool(entered).is_false()
	assert_array(c.sfx.played).contains(["hull_bump"])


func test_capybaras_graze_and_caimans_float_outside_the_boat_area() -> void:
	var c := _day(db, REMANSO_DAY)
	assert_int(c.animals.capybaras.size()).is_equal(4)
	assert_int(c.animals.caimans.size()).is_equal(2)
	var heads: Array[float] = []
	for i in c.animals.capybaras.size():
		heads.append(c.animals.head_of(i).rotation.x)
	var caiman_start := c.animals.caimans[0].position
	c.animals.advance(3.0)
	var moved := false
	for i in c.animals.capybaras.size():
		moved = moved or absf(c.animals.head_of(i).rotation.x - heads[i]) > 0.01
	assert_bool(moved).is_true()
	var caiman := c.animals.caimans[0]
	assert_float(caiman.position.distance_to(caiman_start)).is_greater(0.05)
	var surface := c.water.height_at(caiman.position.x, caiman.position.z)
	assert_float(caiman.position.y).is_less(surface)
	var limit := pres.number("lake", "boat_limit_radius_m")
	for animal in c.animals.caimans:
		assert_float(Vector2(animal.position.x, animal.position.z).length()).is_greater(limit)


func test_autopilot_plays_a_full_remanso_day() -> void:
	var c := _day(db, REMANSO_DAY, 7)
	c.autopilot = AutoPilot.new(PlayerBot.new(db.bot_profile("skilled"), Rng.new(7)))
	var steps := 0
	while not c.is_finished() and steps < MAX_STEPS:
		c.step(STEP_S)
		steps += 1
	assert_bool(c.is_finished()).is_true()
	assert_int(int(c.session.result["fish"])).is_greater(3)


func test_peacock_bass_has_its_own_model_and_golden_paint() -> void:
	assert_str(FishLooks.model_path("blue_peacock_bass")).ends_with("fish_blue_peacock_bass.glb")
	var cfg: Dictionary = pres.section("fish")
	var model := FishLooks.instance("blue_peacock_bass")
	add_child(auto_free(model))
	FishLooks.apply_variant(model, "golden", cfg)
	var body := model.find_child("SM_fish_blue_peacock_bass", true, false) as MeshInstance3D
	var gold := PresentationConfig.color(cfg["variants"]["golden"]["body"])
	var painted := false
	for surface in body.mesh.get_surface_count():
		var tinted := body.get_surface_override_material(surface) as StandardMaterial3D
		painted = painted or (tinted != null and tinted.albedo_color == gold)
	assert_bool(painted).is_true()
