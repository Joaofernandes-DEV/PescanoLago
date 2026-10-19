extends GdUnitTestSuite
## Casco seco (Fase 6, "Navegar e pescar com clareza"): o fundo da canoa fica
## abaixo da linha d'água, então a água é recortada no contorno interno do casco;
## e a flutuação lê a água em seis pontos.

const STEP_S: float = 0.05

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func _boat() -> BoatController:
	var boat := BoatController.new()
	add_child(auto_free(boat))
	boat.setup(pres.section("navigation"), 1.0, 50.0)
	boat.set_model(load(LakeWorld.BOAT_SCENE))
	return boat


func test_the_canoe_floor_is_below_the_waterline() -> void:
	# Por isso o recorte é necessário: sem ele, a água aparece dentro do barco.
	var boat := _boat()
	var hull := boat.model.find_child("SM_boat_esperanca_l1", true, false) as MeshInstance3D
	assert_float(hull.get_aabb().position.y).is_less(-0.1)


func test_interior_follows_the_hull_section() -> void:
	var middle := BoatController.interior_half_width(0.0)
	assert_float(middle).is_equal_approx(
		BoatController.HULL_BEAM_M * 0.5 - BoatController.HULL_WALL_M, 0.0001
	)
	assert_float(BoatController.interior_half_width(0.8)).is_less(middle)
	assert_float(BoatController.interior_half_width(-0.8)).is_equal(
		BoatController.interior_half_width(0.8)
	)


func test_points_inside_and_outside_the_canoe() -> void:
	var boat := _boat()
	boat.global_position = Vector3(10.0, 0.0, -4.0)
	boat.rotation.y = 0.7
	var f := boat.forward()
	var side := Vector3.UP.cross(f).normalized()
	var center := boat.global_position
	assert_bool(boat.is_inside_hull(center)).is_true()
	assert_bool(boat.is_inside_hull(center + f * 1.5)).is_true()
	assert_bool(boat.is_inside_hull(center + side * 0.4)).is_true()
	# Fora do costado, à frente da proa e atrás da popa: água normal.
	assert_bool(boat.is_inside_hull(center + side * 0.6)).is_false()
	assert_bool(boat.is_inside_hull(center + f * 2.1)).is_false()
	assert_bool(boat.is_inside_hull(center - f * 2.1)).is_false()


func test_the_interior_follows_the_model_transform() -> void:
	# O contorno usa o modelo (com arfagem, inclinação e balanço), não só o barco.
	var boat := _boat()
	var ahead := boat.forward() * 1.5
	assert_bool(boat.is_inside_hull(ahead)).is_true()
	boat.model.rotation.y = PI / 2.0
	assert_bool(boat.is_inside_hull(ahead)).is_false()
	boat.model.rotation.y = 0.0
	boat.model.position.y = 0.3
	assert_bool(boat.is_inside_hull(ahead)).is_true()


func test_water_gets_the_hull_in_the_day_and_in_porto_manso() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 4, pres)
	day.external_stepping = true
	add_child(day)
	auto_free(day)
	day.step(STEP_S)
	var shape: Vector4 = day.water.material.get_shader_parameter("hull_shape")
	assert_float(shape.w).is_equal(1.0)
	assert_float(shape.y).is_equal(BoatController.HULL_LENGTH_M * 0.5)
	var inverse: Projection = day.water.material.get_shader_parameter("hull_inverse")
	var back: Vector3 = Transform3D(inverse) * day.boat.model.global_position
	assert_float(back.length()).is_less(0.001)


func test_bow_foam_follows_the_speed() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 4, pres)
	day.external_stepping = true
	add_child(day)
	auto_free(day)
	day.step(STEP_S)
	assert_float(float(day.water.material.get_shader_parameter("hull_speed"))).is_equal(0.0)
	day.input_throttle = 1.0
	for i in 40:
		day.step(STEP_S)
	assert_float(float(day.water.material.get_shader_parameter("hull_speed"))).is_greater(0.3)


func test_flotation_reads_both_sides_along_the_hull() -> void:
	# Onda de lado, com a encosta passando sob a canoa: o casco balança.
	var boat := _boat()
	var water := LakeWater.new()
	add_child(auto_free(water))
	var surface := MeshInstance3D.new()
	add_child(auto_free(surface))
	var cfg: Dictionary = pres.section("water").duplicate(true)
	cfg["waves"] = [{"dir_deg": 0.0, "wavelength_m": 4.4, "amplitude_m": 0.1, "phase": 0.0}]
	water.setup(cfg, 100.0, surface)
	boat.water = water
	# Proa em +z: a onda (em x) chega de lado, pelos bordos.
	for i in 200:
		boat.step(STEP_S)
	var attitude := boat.attitude()
	assert_float(absf(attitude.z)).is_greater(0.01)
