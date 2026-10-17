class_name LakeWorld
extends RefCounted
## Monta o mundo do Lago Aurora usado pelo dia de pesca e por Porto Manso:
## o cenário do Blender (Margem Rasa com o cais) e a superfície da água com o shader.

const LAKE_SCENE: String = "res://assets/models/scenery/margem_rasa_greybox.glb"
const WATER_SCENE: String = "res://assets/models/scenery/water_surface.glb"
const BOAT_SCENE: String = "res://assets/models/boat/boat_esperanca_l1.glb"
const WATER_SHADER: String = "res://shaders/water.gdshader"


static func add_lake(parent: Node) -> Node3D:
	var lake: Node3D = (load(LAKE_SCENE) as PackedScene).instantiate()
	parent.add_child(lake)
	return lake


## Água com as cores e ondas de presentation.json (water). Devolve o material,
## que o dia de pesca atualiza com os cardumes.
static func add_water(parent: Node, pres: PresentationConfig) -> ShaderMaterial:
	var water: Node3D = (load(WATER_SCENE) as PackedScene).instantiate()
	parent.add_child(water)
	var cfg: Dictionary = pres.section("water")
	var material := ShaderMaterial.new()
	material.shader = load(WATER_SHADER)
	material.set_shader_parameter("shallow_color", PresentationConfig.color(cfg["shallow_color"]))
	material.set_shader_parameter("deep_color", PresentationConfig.color(cfg["deep_color"]))
	material.set_shader_parameter("wave_height", float(cfg["wave_height_m"]))
	material.set_shader_parameter("wave_speed", float(cfg["wave_speed"]))
	material.set_shader_parameter("lake_radius", pres.number("lake", "shore_radius_m"))
	var surface := water.find_child("SM_water_surface", true, false) as MeshInstance3D
	surface.material_override = material
	return material


static func locator(lake: Node3D, locator_name: String) -> Vector3:
	return (lake.find_child(locator_name, true, false) as Node3D).global_position
