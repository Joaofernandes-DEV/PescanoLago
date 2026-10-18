class_name LakeWorld
extends RefCounted
## Monta o mundo do Lago Aurora usado pelo dia de pesca e por Porto Manso:
## o cenário do Blender (Margem Rasa com o cais) e a superfície da água (LakeWater).

## Partes do cenário do Blender: terreno (com LOC_dock_berth e LOC_boat_start),
## Porto Manso (com as caixas COL_ de colisão), vegetação e a mata dos morros.
const LAKE_SCENES: PackedStringArray = [
	"res://assets/models/scenery/margem_rasa_terrain.glb",
	"res://assets/models/scenery/porto_manso.glb",
	"res://assets/models/scenery/margem_rasa_vegetation.glb",
	"res://assets/models/scenery/margem_rasa_forest.glb",
]
const WATER_SCENE: String = "res://assets/models/scenery/water_surface.glb"
const BOAT_SCENE: String = "res://assets/models/boat/boat_esperanca_l1.glb"
const WATER_SHADER: String = "res://shaders/water.gdshader"


static func add_lake(parent: Node) -> Node3D:
	var lake := Node3D.new()
	lake.name = "Lake"
	parent.add_child(lake)
	for path in LAKE_SCENES:
		lake.add_child((load(path) as PackedScene).instantiate())
	# As malhas COL_ são só colisão (obstacles()); nunca aparecem na tela.
	for node in lake.find_children("COL_*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).visible = false
	return lake


## Garças sobrevoando o lago (presentation.json, birds).
static func add_birds(parent: Node, pres: PresentationConfig) -> Birds:
	var birds := Birds.new()
	birds.name = "Birds"
	parent.add_child(birds)
	birds.setup(pres.section("birds"), pres.number("lake", "shore_radius_m"))
	return birds


## Água do lago (LakeWater, com o shader e a fórmula das ondas), como filha de parent.
static func add_water(parent: Node, pres: PresentationConfig) -> LakeWater:
	var mesh: Node3D = (load(WATER_SCENE) as PackedScene).instantiate()
	parent.add_child(mesh)
	var water := LakeWater.new()
	water.name = "LakeWater"
	parent.add_child(water)
	var surface := mesh.find_child("SM_water_surface", true, false) as MeshInstance3D
	water.setup(pres.section("water"), pres.number("lake", "shore_radius_m"), surface)
	return water


## Obstáculos do barco: cada malha COL_ do cenário (Blender) vira uma caixa no
## plano {"center", "half", "angle"} e some da tela (é só colisão).
static func obstacles(lake: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in lake.find_children("COL_*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.visible = false
		result.append(_box_from_mesh(mesh))
	return result


## Caixa orientada no plano a partir dos cantos da malha COL_ (o Blender aplica a
## rotação na geometria, então a caixa girada está nos vértices, não no nó).
static func _box_from_mesh(mesh: MeshInstance3D) -> Dictionary:
	var corners: Array[Vector2] = []
	var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for vertex in vertices:
		var world: Vector3 = mesh.global_transform * vertex
		var flat := Vector2(world.x, world.z)
		var known := false
		for corner in corners:
			known = known or corner.distance_to(flat) < 0.001
		if not known:
			corners.append(flat)
	var center := Vector2.ZERO
	for corner in corners:
		center += corner
	center /= float(corners.size())
	# A partir de um canto, os dois vizinhos são os mais próximos (a diagonal é a maior).
	var others: Array[Vector2] = corners.slice(1)
	others.sort_custom(_closer_to.bind(corners[0]))
	var edge_a: Vector2 = others[0] - corners[0]
	var edge_b: Vector2 = others[1] - corners[0]
	return {
		"center": center,
		"half": Vector2(edge_a.length(), edge_b.length()) * 0.5,
		"angle": atan2(edge_a.y, edge_a.x),
	}


static func _closer_to(a: Vector2, b: Vector2, origin: Vector2) -> bool:
	return a.distance_squared_to(origin) < b.distance_squared_to(origin)


static func locator(lake: Node3D, locator_name: String) -> Vector3:
	return (lake.find_child(locator_name, true, false) as Node3D).global_position
