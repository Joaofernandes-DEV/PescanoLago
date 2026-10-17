extends GdUnitTestSuite
## Fim do pipeline do Blender: o .glb exportado por tools/blender/pipeline.py
## importa na Godot e mantém nomes, materiais, escala e eixo vertical.

const BUOY_PATH: String = "res://assets/models/_test/test_buoy.glb"


func _instantiate_buoy() -> Node3D:
	var scene: PackedScene = load(BUOY_PATH)
	assert_object(scene).is_not_null()
	return auto_free(scene.instantiate())


func test_glb_imports_as_scene() -> void:
	assert_bool(ResourceLoader.exists(BUOY_PATH)).is_true()
	assert_object(_instantiate_buoy()).is_not_null()


func test_mesh_node_keeps_blender_name() -> void:
	var mesh := _instantiate_buoy().find_child("SM_test_buoy", true, false) as MeshInstance3D
	assert_object(mesh).is_not_null()


func test_line_attach_point_is_exported() -> void:
	var root := _instantiate_buoy()
	var line_point := root.find_child("LOC_line", true, false) as Node3D
	assert_object(line_point).is_not_null()
	# A linha se prende na base da haste: origem do objeto da boia, que é o pai do ponto.
	assert_str(line_point.get_parent().name).is_equal("SM_test_buoy")
	assert_vector(line_point.position).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.001)


func test_materials_come_from_blender() -> void:
	var mesh := _instantiate_buoy().find_child("SM_test_buoy", true, false) as MeshInstance3D
	var names: Array[String] = []
	for i in mesh.mesh.get_surface_count():
		names.append(mesh.mesh.surface_get_material(i).resource_name)
	names.sort()
	assert_array(names).is_equal(["M_buoy_red", "M_buoy_stem", "M_buoy_white"])


func test_scale_in_meters_and_y_up() -> void:
	# Boia de 16 cm de altura, 4,4 cm de diâmetro, base na origem (Blender Z-up -> Godot Y-up).
	var mesh := _instantiate_buoy().find_child("SM_test_buoy", true, false) as MeshInstance3D
	var aabb := mesh.get_aabb()
	assert_float(aabb.size.y).is_equal_approx(0.16, 0.001)
	assert_float(aabb.position.y).is_equal_approx(0.0, 0.001)
	assert_float(aabb.size.x).is_equal_approx(0.044, 0.001)
