extends GdUnitTestSuite
## Águas Fundas (Fase 6, etapa 6; P-32): cena própria nos dias 16 a 22, água azul
## com ondas maiores, boias antigas que boiam nas ondas e bloqueiam o barco (também
## no mapa lateral), martins-pescadores mergulhando das boias e os peixes novos.

const STEP_S: float = 0.05
const MAX_STEPS: int = 20000
const DEEP_DAY: int = 16

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.full_db()
	pres = PresentationConfig.load_default()


func _day(seed_value: int = 5) -> DayController:
	var controller := DayController.new()
	controller.setup(db, PlayerState.new_game(db), DEEP_DAY, seed_value, pres)
	controller.external_stepping = true
	add_child(controller)
	return auto_free(controller)


func _buoy_boxes(controller: DayController) -> Array[Dictionary]:
	var boxes: Array[Dictionary] = []
	for box in controller.boat.obstacles:
		if String(box["name"]).begins_with(MiniMap.BUOY_PREFIX):
			boxes.append(box)
	return boxes


func test_deep_waters_day_loads_its_own_scenery() -> void:
	var c := _day()
	assert_str(c.region_id).is_equal("aguas_fundas")
	for part: String in [
		"SM_aguas_fundas_terrain", "SM_aguas_fundas_rocks", "SM_aguas_fundas_forest"
	]:
		assert_object(c.find_child(part, true, false)).is_not_null()
	assert_object(c.find_child("SM_remanso_terrain", true, false)).is_null()
	assert_object(c.find_child("SM_porto_manso", true, false)).is_null()
	var limit := pres.number("lake", "boat_limit_radius_m")
	assert_float(Vector2(c.dock_point.x, c.dock_point.z).length()).is_less(limit)


func test_deep_water_is_blue_with_bigger_waves() -> void:
	var c := _day()
	var looks: Dictionary = pres.section("region_looks")["aguas_fundas"]
	var deep: Color = c.water.material.get_shader_parameter("deep_color")
	assert_object(deep).is_equal(PresentationConfig.color(looks["water"]["deep_color"]))
	var calm := LakeWorld.water_config(pres, "margem_rasa")
	var rough := LakeWorld.water_config(pres, "aguas_fundas")
	for i: int in (calm["waves"] as Array).size():
		assert_float(float(rough["waves"][i]["amplitude_m"])).is_greater(
			float(calm["waves"][i]["amplitude_m"])
		)
	var calm_height := 0.0
	for wave: Dictionary in calm["waves"]:
		calm_height += float(wave["amplitude_m"])
	assert_float(c.water.max_wave_height()).is_greater(calm_height)


func test_buoys_float_on_the_waves_and_tilt() -> void:
	var c := _day()
	assert_int(c.buoys.buoys.size()).is_equal(9)
	var draft := float(pres.section("buoys")["draft_m"])
	var tilted := false
	for t in 20:
		c.water.advance(0.37)
		c.buoys.advance(0.37)
		for buoy in c.buoys.buoys:
			var surface := c.water.height_at(buoy.position.x, buoy.position.z)
			assert_float(buoy.position.y).is_equal_approx(surface - draft, 0.0001)
			tilted = tilted or buoy.basis.y.angle_to(Vector3.UP) > 0.01
	assert_bool(tilted).is_true()


func test_buoys_in_reach_block_the_boat_outside_the_schools() -> void:
	var c := _day()
	var boxes := _buoy_boxes(c)
	assert_int(boxes.size()).is_equal(5)
	var schools: Dictionary = pres.section("schools")
	var reach := float(schools["spawn_max_radius_m"]) + float(schools["radius_m"])
	var limit := pres.number("lake", "boat_limit_radius_m")
	for box in boxes:
		var center: Vector2 = box["center"]
		assert_float(center.length() - Vector2(box["half"]).length()).is_greater(reach)
		assert_float(center.length()).is_less(limit)
		# Cada caixa tem a sua boia boiando no mesmo lugar.
		var has_buoy := false
		for buoy in c.buoys.buoys:
			has_buoy = (
				has_buoy or Vector2(buoy.position.x, buoy.position.z).distance_to(center) < 0.01
			)
		assert_bool(has_buoy).is_true()


func test_boat_bumps_into_a_buoy() -> void:
	var c := _day()
	var box: Dictionary = _buoy_boxes(c)[0]
	var center: Vector2 = box["center"]
	var toward := -center.normalized()
	var start := center + toward * 8.0
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


func test_kingfishers_perch_on_buoys_and_dive_back() -> void:
	var c := _day()
	# Uma boia sim, outra não.
	assert_int(c.animals.kingfishers.size()).is_equal(5)
	var bird := c.animals.kingfishers[0]
	assert_str(String(bird.get_parent().name)).starts_with("LOC_perch")
	var cfg: Dictionary = pres.section("animals")["kingfisher"]
	var dive := float(cfg["dive_s"])
	# O primeiro pássaro mergulha no começo de cada ciclo: no meio do mergulho, ele
	# está na água, à frente da boia.
	c.animals.time_s = 0.0
	c.animals.advance(dive * 0.5)
	var perch := bird.get_parent() as Node3D
	var water_y := c.water.height_at(perch.global_position.x, perch.global_position.z)
	assert_float(bird.global_position.y).is_equal_approx(water_y, 0.15)
	assert_float(bird.position.z).is_equal_approx(float(cfg["reach_m"]), 0.01)
	# Depois do mergulho, de volta ao poleiro.
	c.animals.advance(dive * 0.5 + 0.1)
	assert_object(bird.position).is_equal(Vector3.ZERO)


func test_map_shows_buoys_on_blue_water() -> void:
	var c := _day()
	assert_object(c.hud.mini_map.water_color).is_equal(
		PresentationConfig.color(pres.section("region_looks")["aguas_fundas"]["map_water"])
	)
	var named := 0
	for box in c.hud.mini_map.obstacles:
		if String(box["name"]).begins_with(MiniMap.BUOY_PREFIX):
			named += 1
	assert_int(named).is_equal(5)


func test_autopilot_plays_a_full_deep_waters_day() -> void:
	var c := _day(7)
	c.autopilot = AutoPilot.new(PlayerBot.new(db.bot_profile("skilled"), Rng.new(7)))
	var steps := 0
	while not c.is_finished() and steps < MAX_STEPS:
		c.step(STEP_S)
		steps += 1
	assert_bool(c.is_finished()).is_true()
	assert_int(int(c.session.result["fish"])).is_greater(3)


func test_new_fish_have_their_own_models() -> void:
	for species_id: String in ["dourado", "pintado", "tambaqui"]:
		assert_str(FishLooks.model_path(species_id)).ends_with("fish_%s.glb" % species_id)
		var model := FishLooks.instance(species_id)
		add_child(auto_free(model))
		assert_object(model.find_child("LOC_mouth", true, false)).is_not_null()
