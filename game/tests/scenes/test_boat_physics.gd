extends GdUnitTestSuite
## Física do barco (Fase 5): velocidade final, frenagem, guinada, deriva,
## colisão com a margem e com obstáculos, flutuação nas ondas e determinismo.

const DT: float = 1.0 / 60.0

var pres: PresentationConfig
var nav: Dictionary


func before() -> void:
	pres = PresentationConfig.load_default()
	nav = pres.section("navigation")


func _boat(motor_factor: float = 1.0, limit_m: float = 10000.0) -> BoatController:
	var boat := BoatController.new()
	add_child(auto_free(boat))
	boat.setup(nav, motor_factor, limit_m)
	return boat


func _run(boat: BoatController, seconds: float) -> void:
	for i in int(seconds / DT):
		boat.step(DT)


func test_full_throttle_reaches_exactly_the_top_speed() -> void:
	var boat := _boat()
	boat.throttle = 1.0
	_run(boat, 40.0)
	assert_float(boat.speed_m_s).is_equal_approx(float(nav["base_speed_m_s"]), 0.05)
	var faster := _boat(1.8)
	faster.throttle = 1.0
	_run(faster, 40.0)
	assert_float(faster.speed_m_s).is_equal_approx(float(nav["base_speed_m_s"]) * 1.8, 0.05)


func test_acceleration_follows_the_motor_at_rest() -> void:
	var boat := _boat()
	boat.throttle = 1.0
	boat.step(0.1)
	assert_float(boat.speed_m_s).is_equal_approx(float(nav["acceleration_m_s2"]) * 0.1, 0.02)


func test_coasting_slows_down_and_reverse_stops_sooner() -> void:
	var coasting := _boat()
	coasting.throttle = 1.0
	_run(coasting, 20.0)
	var braking := _boat()
	braking.throttle = 1.0
	_run(braking, 20.0)
	coasting.throttle = 0.0
	braking.throttle = -1.0
	var predicted := braking.stopping_distance(1.0)
	var start := braking.position
	var previous := coasting.speed_m_s
	var t := 0.0
	while braking.speed_m_s > 0.05 and t < 30.0:
		coasting.step(DT)
		braking.step(DT)
		assert_float(coasting.speed_m_s).is_less_equal(previous)
		previous = coasting.speed_m_s
		t += DT
	assert_float(coasting.speed_m_s).is_greater(braking.speed_m_s)
	# A previsão usada pelo piloto automático bate com a frenagem de verdade.
	assert_float(braking.position.distance_to(start)).is_equal_approx(predicted, 0.5)


func test_reverse_has_less_thrust() -> void:
	var boat := _boat()
	boat.throttle = -1.0
	_run(boat, 40.0)
	assert_float(boat.speed_m_s).is_less(0.0)
	assert_float(absf(boat.speed_m_s)).is_less(float(nav["base_speed_m_s"]) * 0.8)


func test_rudder_needs_speed_but_the_motor_turns_a_little() -> void:
	var drifting := _boat()
	drifting.steer = 1.0
	_run(drifting, 2.0)
	assert_float(drifting.rotation.y).is_equal_approx(0.0, 0.0001)
	var at_full := _boat()
	at_full.throttle = 1.0
	_run(at_full, 20.0)
	at_full.steer = 1.0
	_run(at_full, 3.0)
	# Direita = guinada negativa; perto da taxa máxima com a velocidade máxima.
	assert_float(at_full.yaw_rate_rad_s).is_less(-deg_to_rad(float(nav["turn_rate_deg_s"])) * 0.8)
	var slow := _boat()
	slow.throttle = 0.2
	slow.steer = 1.0
	_run(slow, 0.5)
	assert_float(slow.yaw_rate_rad_s).is_less(0.0)
	assert_float(absf(slow.yaw_rate_rad_s)).is_less(absf(at_full.yaw_rate_rad_s))


func test_hard_turn_drifts_sideways_and_the_keel_kills_the_drift() -> void:
	var boat := _boat()
	boat.throttle = 1.0
	_run(boat, 20.0)
	boat.steer = 1.0
	_run(boat, 0.6)
	var drift := absf(boat.lateral_speed_m_s)
	assert_float(drift).is_greater(0.05)
	boat.steer = 0.0
	_run(boat, 3.0)
	assert_float(absf(boat.lateral_speed_m_s)).is_less(drift * 0.2)


func test_shore_stops_the_boat_and_bounces_it_back() -> void:
	var boat := _boat(1.0, 20.0)
	var bumps: Array[float] = []
	boat.bumped.connect(func(impact: float) -> void: bumps.append(impact))
	boat.throttle = 1.0
	_run(boat, 15.0)
	var center := Vector2(boat.position.x, boat.position.z)
	var bow := (
		center + Vector2(boat.forward().x, boat.forward().z) * float(nav["hull_circle_offset_m"])
	)
	assert_float(bow.length()).is_less_equal(20.0 - float(nav["hull_circle_radius_m"]) + 0.01)
	assert_int(bumps.size()).is_greater(0)
	assert_float(bumps[0]).is_greater(1.0)


func test_obstacle_box_is_never_crossed() -> void:
	var boat := _boat()
	var box := {"center": Vector2(0.0, 12.0), "half": Vector2(4.0, 1.0), "angle": 0.3}
	boat.obstacles = [box]
	boat.throttle = 1.0
	for i in int(10.0 / DT):
		boat.step(DT)
		assert_float(boat.position.z).is_less(12.0)
	assert_int(boat.collisions).is_greater(0)
	assert_float(boat.speed_m_s).is_less(float(nav["base_speed_m_s"]))


func test_hull_rides_the_waves() -> void:
	var surface := MeshInstance3D.new()
	add_child(auto_free(surface))
	var water := LakeWater.new()
	add_child(auto_free(water))
	water.setup(pres.section("water"), 110.0, surface)
	var boat := _boat()
	boat.model = Node3D.new()
	boat.add_child(boat.model)
	boat.water = water
	var error_sum := 0.0
	var moved := 0.0
	for i in int(20.0 / DT):
		water.advance(DT)
		boat.step(DT)
		if i > int(5.0 / DT):
			error_sum += absf(boat.attitude().x - water.height_at(0.0, 0.0))
			moved = maxf(moved, absf(boat.attitude().x))
	var samples := float(int(20.0 / DT) - int(5.0 / DT) - 1)
	# Segue a superfície (média dos 4 pontos do casco) sem ficar parado.
	assert_float(moved).is_greater(0.02)
	assert_float(error_sum / samples).is_less(water.max_wave_height() * 0.5)


## Um quadro longo (travada ao carregar, aba do navegador em segundo plano) não
## pode fazer a flutuação explodir: antes, a mola andava com o quadro inteiro e o
## casco ia para o infinito com quadros de 0,25 s.
func test_long_frames_keep_the_hull_finite() -> void:
	var surface := MeshInstance3D.new()
	add_child(auto_free(surface))
	var water := LakeWater.new()
	add_child(auto_free(water))
	water.setup(pres.section("water"), 110.0, surface)
	var boat := _boat()
	boat.model = Node3D.new()
	boat.add_child(boat.model)
	boat.water = water
	boat.throttle = 1.0
	for i in 300:
		water.advance(0.25)
		boat.step(0.25)
	var attitude := boat.attitude()
	assert_bool(attitude.is_finite()).is_true()
	assert_float(absf(attitude.x)).is_less(water.max_wave_height() * 2.0)


func test_bow_rises_when_accelerating() -> void:
	var boat := _boat()
	boat.model = Node3D.new()
	boat.add_child(boat.model)
	boat.throttle = 1.0
	_run(boat, 1.0)
	assert_float(boat.attitude().y).is_greater(0.0)
	assert_float(boat.model.rotation.x).is_less(0.0)


func test_same_inputs_give_the_same_path() -> void:
	var paths: Array[Vector3] = []
	for run in 2:
		var boat := _boat(1.35, 60.0)
		for i in int(30.0 / DT):
			boat.throttle = 1.0 if (i / 120) % 3 != 2 else -0.5
			boat.steer = sin(float(i) * 0.01)
			boat.step(DT)
		paths.append(boat.position)
	assert_vector(paths[0]).is_equal(paths[1])
