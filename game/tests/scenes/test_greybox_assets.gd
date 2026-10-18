extends GdUnitTestSuite
## Modelos gerados no Blender (greybox da Fase 3 e cenário da Fase 5): importam
## na Godot com os nós, pontos de encaixe e medidas que as cenas do jogo esperam.

const BOAT: String = "res://assets/models/boat/boat_esperanca_l1.glb"
const FISH: String = "res://assets/models/fish/fish_generic.glb"
const WATER: String = "res://assets/models/scenery/water_surface.glb"


func _load(path: String) -> Node3D:
	var scene: PackedScene = load(path)
	assert_object(scene).is_not_null()
	return auto_free(scene.instantiate())


func _find(root: Node, node_name: String) -> Node3D:
	return root.find_child(node_name, true, false) as Node3D


func test_boat_parts_and_attach_points() -> void:
	var boat := _load(BOAT)
	var hull := _find(boat, "SM_boat_esperanca_l1") as MeshInstance3D
	assert_object(hull).is_not_null()
	# Motor e vara são peças separadas para trocar por nível e por vara.
	assert_str(_find(boat, "SM_motor_l1").get_parent().name).is_equal(hull.name)
	assert_str(_find(boat, "SM_rod_bamboo").get_parent().name).is_equal(hull.name)
	for point: String in ["LOC_rod_tip", "LOC_seat", "LOC_motor"]:
		assert_object(_find(boat, point)).is_not_null()
	# Canoa de ~4 m, origem na linha d'água (casco abaixo de 0, bordas acima).
	var aabb := hull.get_aabb()
	assert_float(aabb.size.z).is_equal_approx(4.0, 0.15)
	assert_float(aabb.position.y).is_less(0.0)
	assert_float(aabb.end.y).is_greater(0.0)
	# A ponta da vara fica acima da água e para fora do barco.
	assert_float(_find(boat, "LOC_rod_tip").position.y).is_greater(1.0)


func test_fish_model() -> void:
	var fish := _load(FISH)
	var body := _find(fish, "SM_fish_generic") as MeshInstance3D
	assert_object(body).is_not_null()
	assert_float(body.get_aabb().position.y).is_equal_approx(0.0, 0.005)
	assert_float(body.get_aabb().size.z).is_equal_approx(0.44, 0.03)
	assert_object(_find(fish, "LOC_mouth")).is_not_null()


func test_lake_has_dock_and_start_points_inside_the_water() -> void:
	var lake := Node3D.new()
	add_child(auto_free(lake))
	for path in LakeWorld.LAKE_SCENES:
		lake.add_child((load(path) as PackedScene).instantiate())
	var cfg: Dictionary = (
		JSON.parse_string(FileAccess.get_file_as_string("res://content/presentation.json"))["lake"]
	)
	var shore := float(cfg["shore_radius_m"])
	for part: String in ["SM_terrain", "SM_porto_manso", "SM_vegetation"]:
		assert_object(_find(lake, part)).is_not_null()
	for point: String in ["LOC_dock_berth", "LOC_boat_start"]:
		var node := _find(lake, point)
		assert_object(node).is_not_null()
		var flat := Vector2(node.position.x, node.position.z)
		assert_float(flat.length()).is_less(shore)


func test_water_surface_covers_the_lake() -> void:
	var water := _load(WATER)
	var surface := _find(water, "SM_water_surface") as MeshInstance3D
	assert_object(surface).is_not_null()
	var cfg: Dictionary = (
		JSON.parse_string(FileAccess.get_file_as_string("res://content/presentation.json"))["lake"]
	)
	assert_float(surface.get_aabb().size.x).is_greater(float(cfg["shore_radius_m"]) * 2.0)
	assert_float(surface.get_aabb().size.y).is_equal_approx(0.0, 0.01)
