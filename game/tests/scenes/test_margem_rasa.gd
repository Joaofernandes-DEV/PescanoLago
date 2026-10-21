extends GdUnitTestSuite
## Cenário da Margem Rasa e de Porto Manso (Fase 5): partes do Blender, colisão
## do cais e dos barcos ancorados, e as garças sobrevoando o lago.

var pres: PresentationConfig


func before() -> void:
	pres = PresentationConfig.load_default()


func _lake() -> Node3D:
	var holder := Node3D.new()
	add_child(auto_free(holder))
	return LakeWorld.add_lake(holder)


func test_scenery_parts_and_porto_manso_buildings() -> void:
	var lake := _lake()
	for part: String in ["SM_terrain", "SM_porto_manso", "SM_vegetation"]:
		assert_object(lake.find_child(part, true, false)).is_not_null()
	assert_int(lake.get_child_count()).is_equal(LakeWorld.LAKE_SCENES.size())


func test_dock_and_moored_boats_block_the_boat() -> void:
	var lake := _lake()
	var boxes := LakeWorld.obstacles(lake)
	# Cais e dois barcos ancorados, e o cais do sítio dos avós (as paredes do sítio
	# são só de quem anda a pé).
	assert_int(boxes.size()).is_equal(4)
	for node in lake.find_children("COL_*", "MeshInstance3D", true, false):
		assert_bool((node as MeshInstance3D).visible).is_false()
	# O cais sai da margem para a água no ângulo do cais (o +Y do Blender vira −Z na Godot).
	var angle := deg_to_rad(pres.number("lake", "dock_angle_deg"))
	var shore := pres.number("lake", "shore_radius_m")
	var on_dock := Vector2(cos(angle), -sin(angle)) * (shore - 5.0)
	var inside := false
	for box in boxes:
		# Caixa do cais: 18,6 m × 3,4 m (generator), girada pelos vértices.
		var local: Vector2 = (on_dock - Vector2(box["center"])).rotated(-float(box["angle"]))
		var half: Vector2 = box["half"]
		inside = inside or (absf(local.x) <= half.x and absf(local.y) <= half.y)
	assert_bool(inside).is_true()


func test_berth_is_free_water_next_to_the_dock() -> void:
	var lake := _lake()
	var berth := LakeWorld.locator(lake, "LOC_dock_berth")
	var boat := BoatController.new()
	add_child(auto_free(boat))
	boat.setup(pres.section("navigation"), 1.0, pres.number("lake", "boat_limit_radius_m"))
	boat.obstacles = LakeWorld.obstacles(lake)
	var to_center := -Vector2(berth.x, berth.z).normalized()
	boat.position = Vector3(berth.x, 0.0, berth.z)
	boat.rotation.y = atan2(to_center.x, to_center.y)
	boat.step(0.1)
	# Atracado no ponto do cais, o barco não encosta em nenhum obstáculo.
	assert_int(boat.collisions).is_equal(0)
	assert_float(boat.position.distance_to(Vector3(berth.x, 0.0, berth.z))).is_less(0.01)


func test_day_boat_cannot_cross_the_dock() -> void:
	var db := TestContent.db()
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 1, pres)
	day.external_stepping = true
	add_child(auto_free(day))
	assert_int(day.boat.obstacles.size()).is_equal(4)


func test_herons_fly_in_the_sky_and_flap() -> void:
	var holder := Node3D.new()
	add_child(auto_free(holder))
	var birds := LakeWorld.add_birds(holder, pres)
	var cfg: Dictionary = pres.section("birds")
	assert_int(birds.herons.size()).is_equal(int(cfg["count"]))
	var start := birds.herons[0].position
	var max_wing := 0.0
	for i in 120:
		birds.advance(1.0 / 30.0)
		max_wing = maxf(max_wing, absf(birds.wing_angle(0)))
		for heron in birds.herons:
			assert_float(heron.position.y).is_greater(float(cfg["height_m"][0]) - 2.0)
	assert_float(birds.herons[0].position.distance_to(start)).is_greater(5.0)
	assert_float(max_wing).is_greater(0.1)
	assert_float(max_wing).is_less_equal(deg_to_rad(float(cfg["flap_deg"])) + 0.001)


func test_rotated_collision_box_is_rebuilt_from_the_vertices() -> void:
	var holder := Node3D.new()
	add_child(auto_free(holder))
	var col := MeshInstance3D.new()
	col.name = "COL_test"
	var box := BoxMesh.new()
	box.size = Vector3(4.0, 1.0, 2.0)
	col.mesh = box
	holder.add_child(col)
	col.position = Vector3(3.0, 0.0, 5.0)
	col.rotation.y = 0.5
	var rebuilt: Dictionary = LakeWorld.obstacles(holder)[0]
	assert_vector(Vector2(rebuilt["center"])).is_equal_approx(
		Vector2(3.0, 5.0), Vector2(0.001, 0.001)
	)
	var half: Vector2 = rebuilt["half"]
	assert_float(half.x * half.y * 4.0).is_equal_approx(8.0, 0.001)
	# Um canto da caixa de verdade fica na borda da caixa refeita; fora dela, um ponto
	# que uma caixa alinhada aos eixos ainda cobriria.
	var corner := Vector2(3.0, 5.0) + Vector2(2.0, 1.0).rotated(-0.5)
	var local := (corner - Vector2(3.0, 5.0)).rotated(-float(rebuilt["angle"]))
	assert_float(absf(local.x)).is_less_equal(half.x + 0.001)
	assert_float(absf(local.y)).is_less_equal(half.y + 0.001)
	var aabb_only := Vector2(3.0, 5.0) + Vector2(2.1, -1.6)
	local = (aabb_only - Vector2(3.0, 5.0)).rotated(-float(rebuilt["angle"]))
	assert_bool(absf(local.x) <= half.x and absf(local.y) <= half.y).is_false()
