extends GdUnitTestSuite
## Desempenho (Fase 5): os modelos usam a cor nos vértices e poucos materiais
## (cada material é um draw call); a Godot pinta com a cor do vértice.


func _surfaces(root: Node, mesh_name: String) -> int:
	var mesh := root.find_child(mesh_name, true, false) as MeshInstance3D
	return mesh.mesh.get_surface_count()


func test_scenery_meshes_use_few_palette_materials() -> void:
	var holder := Node3D.new()
	add_child(auto_free(holder))
	var lake := LakeWorld.add_lake(holder)
	for mesh_name: String in ["SM_terrain", "SM_vegetation", "SM_forest"]:
		assert_int(_surfaces(lake, mesh_name)).is_less_equal(2)
	# Porto Manso: paleta + o material emissivo dos lampiões.
	assert_int(_surfaces(lake, "SM_porto_manso")).is_less_equal(3)


func test_palette_materials_paint_with_the_vertex_color() -> void:
	var holder := Node3D.new()
	add_child(auto_free(holder))
	var lake := LakeWorld.add_lake(holder)
	var checked := 0
	for node in lake.find_children("SM_*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as BaseMaterial3D
			if material.resource_name.begins_with(Palette.PREFIX):
				assert_bool(material.vertex_color_use_as_albedo).is_true()
				assert_bool(material.vertex_color_is_srgb).is_false()
				assert_object(material.albedo_color).is_equal(Color.WHITE)
				checked += 1
	assert_int(checked).is_greater(3)


func test_boat_and_characters_also_use_the_palette() -> void:
	var tom := CharacterPuppet.create("tom")
	add_child(auto_free(tom))
	assert_int(_surfaces(tom.model, "SM_tom")).is_equal(1)
	var boat := BoatController.new()
	add_child(auto_free(boat))
	boat.set_model(load(LakeWorld.BOAT_SCENE))
	# Alumínio (metálico) e o resto: dois materiais.
	assert_int(_surfaces(boat.model, "SM_boat_esperanca_l1")).is_less_equal(2)


func test_a_lone_mesh_also_gets_the_vertex_color() -> void:
	var material := StandardMaterial3D.new()
	material.resource_name = "M_palette"
	var mesh := BoxMesh.new()
	mesh.material = material
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	assert_int(Palette.apply(piece)).is_equal(1)
	assert_bool(material.vertex_color_use_as_albedo).is_true()
	piece.free()


func test_hud_icons_paint_with_the_vertex_color() -> void:
	# Bug da Fase 5: o ícone é uma malha sozinha e saía branco.
	var icon := HudIcon.create("coin", 40.0)
	add_child(auto_free(icon))
	var piece := icon.viewport.find_child("SM_icon_coin", true, false) as MeshInstance3D
	var painted := 0
	for surface in piece.mesh.get_surface_count():
		var material := piece.mesh.surface_get_material(surface) as BaseMaterial3D
		if material.resource_name.begins_with(Palette.PREFIX):
			assert_bool(material.vertex_color_use_as_albedo).is_true()
			painted += 1
	assert_int(painted).is_greater(0)
