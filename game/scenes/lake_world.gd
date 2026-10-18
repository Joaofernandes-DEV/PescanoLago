class_name LakeWorld
extends RefCounted
## Monta o mundo do Lago Aurora usado pelo dia de pesca e por Porto Manso:
## o cenário do Blender (Margem Rasa com o cais) e a superfície da água (LakeWater).

const LAKE_SCENE: String = "res://assets/models/scenery/margem_rasa_greybox.glb"
const WATER_SCENE: String = "res://assets/models/scenery/water_surface.glb"
const BOAT_SCENE: String = "res://assets/models/boat/boat_esperanca_l1.glb"
const WATER_SHADER: String = "res://shaders/water.gdshader"


static func add_lake(parent: Node) -> Node3D:
	var lake: Node3D = (load(LAKE_SCENE) as PackedScene).instantiate()
	parent.add_child(lake)
	return lake


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
		var aabb: AABB = mesh.get_aabb()
		var basis: Basis = mesh.global_transform.basis
		var center: Vector3 = mesh.global_transform * aabb.get_center()
		var scale: Vector3 = basis.get_scale()
		var x_axis: Vector3 = basis.x.normalized()
		(
			result
			. append(
				{
					"center": Vector2(center.x, center.z),
					"half": Vector2(aabb.size.x * scale.x, aabb.size.z * scale.z) * 0.5,
					"angle": atan2(x_axis.z, x_axis.x),
				}
			)
		)
	return result


static func locator(lake: Node3D, locator_name: String) -> Vector3:
	return (lake.find_child(locator_name, true, false) as Node3D).global_position
