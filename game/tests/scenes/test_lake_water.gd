extends GdUnitTestSuite
## Água do lago (Fase 5): a fórmula das ondas usada pelo código é a mesma do
## shader, segue a física de águas profundas e a esteira nasce e some da popa.

var pres: PresentationConfig


func before() -> void:
	pres = PresentationConfig.load_default()


func _water(cfg: Dictionary = {}) -> LakeWater:
	var surface := MeshInstance3D.new()
	add_child(auto_free(surface))
	var water := LakeWater.new()
	add_child(auto_free(water))
	water.setup(
		cfg if not cfg.is_empty() else pres.section("water"),
		pres.number("lake", "shore_radius_m"),
		surface
	)
	return water


func _single_wave(wavelength_m: float) -> Dictionary:
	var cfg: Dictionary = pres.section("water").duplicate(true)
	cfg["waves"] = [
		{"dir_deg": 0.0, "wavelength_m": wavelength_m, "amplitude_m": 0.1, "phase": 0.0}
	]
	return cfg


func test_height_stays_within_the_sum_of_amplitudes() -> void:
	var water := _water()
	var limit := water.max_wave_height()
	assert_float(limit).is_greater(0.0)
	for i in 50:
		water.advance(0.37)
		var h := water.height_at(float(i) * 3.1 - 70.0, float(i) * -2.3 + 40.0)
		assert_float(absf(h)).is_less_equal(limit + 0.0001)


func test_slope_is_the_derivative_of_the_height() -> void:
	var water := _water()
	water.advance(12.5)
	var e := 0.001
	for point: Vector2 in [Vector2(3.0, -7.0), Vector2(-40.0, 22.0), Vector2(15.5, 61.0)]:
		var slope := water.slope_at(point.x, point.y)
		var dx := (
			(water.height_at(point.x + e, point.y) - water.height_at(point.x - e, point.y))
			/ (2.0 * e)
		)
		var dz := (
			(water.height_at(point.x, point.y + e) - water.height_at(point.x, point.y - e))
			/ (2.0 * e)
		)
		assert_float(slope.x).is_equal_approx(dx, 0.001)
		assert_float(slope.y).is_equal_approx(dz, 0.001)
	assert_float(water.normal_at(3.0, -7.0).y).is_greater(0.9)


func test_waves_follow_deep_water_dispersion() -> void:
	# Onda de 9 m: período T = 2π / sqrt(g·k) ≈ 2,40 s; depois de um período a água volta igual.
	var wavelength := 9.0
	var water := _water(_single_wave(wavelength))
	var period := TAU / sqrt(LakeWater.GRAVITY_M_S2 * TAU / wavelength)
	assert_float(period).is_equal_approx(2.40, 0.01)
	var before := water.height_at(1.3, 4.0)
	water.advance(period)
	assert_float(water.height_at(1.3, 4.0)).is_equal_approx(before, 0.0001)
	water.advance(period / 2.0)
	assert_float(water.height_at(1.3, 4.0)).is_equal_approx(-before, 0.0001)


func test_shader_receives_the_same_time_and_waves() -> void:
	var water := _water()
	water.advance(4.25)
	assert_float(float(water.material.get_shader_parameter("water_time"))).is_equal_approx(
		4.25, 0.0001
	)
	var waves: PackedVector4Array = water.material.get_shader_parameter("wave_dir_k_amp")
	assert_int(waves.size()).is_equal(LakeWater.MAX_WAVES)
	var first: Dictionary = pres.section("water")["waves"][0]
	assert_float(waves[0].z).is_equal_approx(TAU / float(first["wavelength_m"]), 0.0001)
	assert_float(waves[0].w).is_equal_approx(float(first["amplitude_m"]), 0.0001)


func test_wake_follows_a_moving_boat_and_fades() -> void:
	var water := _water()
	var cfg: Dictionary = pres.section("water")["wake"]
	for i in 30:
		water.advance(0.05)
		water.trail_boat(Vector3(float(i) * 0.35, 0.0, 0.0), 7.0, 7.0)
	assert_int(water.wake_points()).is_greater(3)
	var head: Vector4 = water.material.get_shader_parameter("wake_head")
	assert_float(head.w).is_greater(0.0)
	# Parado: a cabeça some e os pontos envelhecem até sumir.
	water.trail_boat(Vector3.ZERO, 0.0, 7.0)
	head = water.material.get_shader_parameter("wake_head")
	assert_float(head.w).is_equal(0.0)
	water.advance(float(cfg["life_s"]) + 0.1)
	assert_int(water.wake_points()).is_equal(0)


func test_day_scene_uses_lake_water_and_rendering_settings() -> void:
	var db := TestContent.db()
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 1, pres)
	day.external_stepping = true
	add_child(auto_free(day))
	day.input_throttle = 1.0
	for i in 60:
		day.step(0.05)
	assert_float(day.water.time_s).is_equal_approx(3.0, 0.001)
	assert_int(day.water.wake_points()).is_greater(0)
	var env := day.lighting.environment
	assert_int(env.tonemap_mode).is_equal(Environment.TONE_MAPPER_AGX)
	assert_bool(env.glow_enabled).is_true()
	assert_bool(env.fog_enabled).is_true()
	assert_object(env.fog_light_color).is_equal(day.lighting.horizon_color())
