class_name LakeWorld
extends RefCounted
## Monta o mundo do Lago Aurora usado pelo dia de pesca e por Porto Manso:
## o cenário do Blender da região, a superfície da água (LakeWater) e os animais.
## Cada região tem a sua cena, carregada só no dia dela (P-32); a que ainda não
## tem cena própria usa a da Margem Rasa.

const HOME_REGION: String = "margem_rasa"
const WALL_PREFIX: String = "COL_wall"
const DECK_PREFIX: String = "COL_deck"
## Margem Rasa e Porto Manso: terreno (com LOC_dock_berth e LOC_boat_start),
## Porto Manso (com as caixas COL_ de colisão), o sítio dos avós na margem em
## frente (casa, cerca e cais, com LOC_walk_start e LOC_sitio_berth; Fase 7),
## vegetação e a mata dos morros.
const LAKE_SCENES: PackedStringArray = [
	"res://assets/models/scenery/margem_rasa_terrain.glb",
	"res://assets/models/scenery/porto_manso.glb",
	"res://assets/models/scenery/sitio_avos.glb",
	"res://assets/models/scenery/margem_rasa_vegetation.glb",
	"res://assets/models/scenery/margem_rasa_forest.glb",
]
## Remanso: terreno com o trapiche (LOC_ do barco e dos animais), plantas aquáticas
## (com as caixas COL_lily_ das manchas de vitórias-régias), a mata ciliar na beira
## do barranco e a mata dos morros.
const REMANSO_SCENES: PackedStringArray = [
	"res://assets/models/scenery/remanso_terrain.glb",
	"res://assets/models/scenery/remanso_plants.glb",
	"res://assets/models/scenery/remanso_bank.glb",
	"res://assets/models/scenery/remanso_forest.glb",
]
## Águas Fundas: terreno com o trapiche, os pontos das boias antigas (com as caixas
## COL_buoy_ das que o barco alcança), pedras, vegetação da beira e a mata.
const AGUAS_FUNDAS_SCENES: PackedStringArray = [
	"res://assets/models/scenery/aguas_fundas_terrain.glb",
	"res://assets/models/scenery/aguas_fundas_rocks.glb",
	"res://assets/models/scenery/aguas_fundas_vegetation.glb",
	"res://assets/models/scenery/aguas_fundas_forest.glb",
]
const REGION_SCENES: Dictionary = {
	"margem_rasa": LAKE_SCENES,
	"remanso": REMANSO_SCENES,
	"aguas_fundas": AGUAS_FUNDAS_SCENES,
}
const WATER_SCENE: String = "res://assets/models/scenery/water_surface.glb"
const BOAT_SCENE: String = "res://assets/models/boat/boat_esperanca_l1.glb"
const WATER_SHADER: String = "res://shaders/water.gdshader"


## Região cujo cenário aparece no dia: a própria ou, sem cena ainda, a Margem Rasa.
static func scenery_region(region_id: String) -> String:
	return region_id if REGION_SCENES.has(region_id) else HOME_REGION


static func add_lake(parent: Node, region_id: String = HOME_REGION) -> Node3D:
	var lake := Node3D.new()
	lake.name = "Lake"
	parent.add_child(lake)
	for path: String in REGION_SCENES[scenery_region(region_id)]:
		lake.add_child((load(path) as PackedScene).instantiate())
	Palette.apply(lake)
	# As malhas COL_ são só colisão (obstacles()); nunca aparecem na tela.
	for node in lake.find_children("COL_*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).visible = false
	return lake


## Moradores de Porto Manso nos seus lugares: Tio Zeca na oficina e Dona Marô no
## armazém (LOC_zeca e LOC_maro do cenário). Fora da Margem Rasa não há ninguém.
static func add_villagers(lake: Node3D) -> Dictionary:
	var villagers: Dictionary = {}
	for id: String in ["zeca", "maro"]:
		var spot := lake.find_child("LOC_%s" % id, true, false) as Node3D
		if spot == null:
			continue
		var puppet := CharacterPuppet.create(id)
		puppet.merge_still_parts()
		lake.add_child(puppet)
		puppet.place_at(spot)
		villagers[id] = puppet
	return villagers


## Tom no banco e Bolota na proa, presos ao modelo do barco (balançam com ele).
static func add_crew(boat: BoatController) -> Dictionary:
	var tom := CharacterPuppet.create("tom")
	tom.merge_still_parts()
	boat.model.add_child(tom)
	tom.place_seated(boat.model.find_child("LOC_seat", true, false) as Node3D)
	var bolota := CharacterPuppet.create("bolota")
	bolota.merge_still_parts()
	boat.model.add_child(bolota)
	bolota.place_at(boat.model.find_child("LOC_bow_dog", true, false) as Node3D)
	return {"tom": tom, "bolota": bolota}


## Garças sobrevoando o lago (presentation.json, birds).
static func add_birds(parent: Node, pres: PresentationConfig) -> Birds:
	var birds := Birds.new()
	birds.name = "Birds"
	parent.add_child(birds)
	birds.setup(pres.section("birds"), pres.number("lake", "shore_radius_m"))
	return birds


## Boias antigas nos pontos LOC_buoy_ do cenário (presentation.json, buoys).
static func add_buoys(lake: Node3D, pres: PresentationConfig, water: LakeWater) -> Buoys:
	var buoys := Buoys.new()
	buoys.name = "Buoys"
	lake.add_child(buoys)
	buoys.setup(pres.section("buoys"), lake, water)
	return buoys


## Capivaras, jacarés e martins-pescadores nos pontos LOC_ do cenário e nos
## poleiros das boias (presentation.json, animals). Vem depois de add_buoys.
static func add_animals(lake: Node3D, pres: PresentationConfig, water: LakeWater) -> Animals:
	var animals := Animals.new()
	animals.name = "Animals"
	lake.add_child(animals)
	animals.setup(pres.section("animals"), lake, water)
	return animals


## Aparência da região (presentation.json, region_looks): água e cor no mapa.
static func looks(pres: PresentationConfig, region_id: String) -> Dictionary:
	return pres.section("region_looks")[scenery_region(region_id)]


## Água da região: a de presentation.json (water) com as cores e a espuma da margem
## da região e as ondas multiplicadas por wave_scale (o Remanso é de água parada).
static func water_config(pres: PresentationConfig, region_id: String) -> Dictionary:
	var cfg: Dictionary = pres.section("water").duplicate(true)
	var region: Dictionary = looks(pres, region_id)["water"]
	for key: String in ["shallow_color", "deep_color", "shore_foam_m"]:
		if region.has(key):
			cfg[key] = region[key]
	var wave_scale: float = float(region.get("wave_scale", 1.0))
	for wave: Dictionary in cfg["waves"]:
		wave["amplitude_m"] = float(wave["amplitude_m"]) * wave_scale
	return cfg


## Água do lago (LakeWater, com o shader e a fórmula das ondas), como filha de parent.
static func add_water(
	parent: Node, pres: PresentationConfig, region_id: String = HOME_REGION
) -> LakeWater:
	var mesh: Node3D = (load(WATER_SCENE) as PackedScene).instantiate()
	parent.add_child(mesh)
	Palette.apply(mesh)
	var water := LakeWater.new()
	water.name = "LakeWater"
	parent.add_child(water)
	var surface := mesh.find_child("SM_water_surface", true, false) as MeshInstance3D
	water.setup(water_config(pres, region_id), pres.number("lake", "shore_radius_m"), surface)
	return water


## Paredes de quem anda em terra (COL_wall_: a casa e as cercas do sítio) e pisos
## acima da água (COL_deck_: o cais), como caixas no plano; o piso traz a altura
## do topo ("top"). As paredes não são obstáculo do barco nem aparecem no mapa.
static func walk_boxes(lake: Node3D, prefix: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in lake.find_children(prefix + "*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box := _box_from_mesh(mesh)
		box["name"] = String(mesh.name)
		box["top"] = (mesh.global_transform * mesh.get_aabb()).end.y
		result.append(box)
	return result


## Obstáculos do barco: cada malha COL_ do cenário (Blender) vira uma caixa no
## plano {"center", "half", "angle", "name"} e some da tela (é só colisão).
static func obstacles(lake: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in lake.find_children("COL_*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.visible = false
		if String(mesh.name).begins_with(WALL_PREFIX):
			continue
		var box := _box_from_mesh(mesh)
		box["name"] = String(mesh.name)
		result.append(box)
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
