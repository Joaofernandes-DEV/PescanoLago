class_name FishLooks
extends RefCounted
## Aparência dos peixes (Fase 5): o modelo do Blender de cada espécie, o tamanho
## pelo peso e a variante albina.
##
## Cada modelo foi feito no comprimento real do peixe com uma fração do peso
## máximo da espécie (presentation.json, fish, reference_weight_ratio). Como o
## peso cresce com o cubo do comprimento, a escala é (peso / peso de referência)^(1/3).
## Espécie sem modelo próprio usa o peixe genérico.

const MODEL_PATH: String = "res://assets/models/fish/fish_%s.glb"
const GENERIC_MODEL: String = "res://assets/models/fish/fish_generic.glb"
const EYE_MATERIAL: String = "M_fish_eye"
const PUPIL_MATERIAL: String = "M_fish_pupil"


static func model_path(species_id: String) -> String:
	var path: String = MODEL_PATH % species_id
	return path if ResourceLoader.exists(path) else GENERIC_MODEL


static func instance(species_id: String) -> Node3D:
	return (load(model_path(species_id)) as PackedScene).instantiate()


## Escala do modelo para este peso (cfg: presentation.json, fish).
static func scale_for(species: Dictionary, weight_kg: float, cfg: Dictionary) -> float:
	var reference: float = float(species["max_weight_kg"]) * float(cfg["reference_weight_ratio"])
	var ratio: float = maxf(weight_kg, 0.001) / maxf(reference, 0.001)
	return clampf(pow(ratio, 1.0 / 3.0), float(cfg["scale_min"]), float(cfg["scale_max"]))


## Pinta o modelo com a variante (ex.: albino: corpo e nadadeiras claros, olho vermelho).
## Sem variante, volta às cores do Blender.
static func apply_variant(model: Node3D, variant: String, cfg: Dictionary) -> void:
	var variants: Dictionary = cfg["variants"]
	var colors: Dictionary = variants.get(variant, {})
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		for surface in mesh_instance.mesh.get_surface_count():
			if colors.is_empty():
				mesh_instance.set_surface_override_material(surface, null)
				continue
			var original: Material = mesh_instance.mesh.surface_get_material(surface)
			var key: String = "body"
			if original != null and original.resource_name == EYE_MATERIAL:
				key = "eye"
			elif original != null and original.resource_name == PUPIL_MATERIAL:
				key = "pupil"
			var tinted := StandardMaterial3D.new()
			tinted.albedo_color = PresentationConfig.color(colors[key])
			tinted.roughness = 0.5
			mesh_instance.set_surface_override_material(surface, tinted)
