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


## O peixe numa malha só, com a cor de cada parte (e da variante) nos vértices:
## um draw call em vez de três (VertexColorMesh). Sem sombra.
static func single_mesh(species_id: String, variant: String, cfg: Dictionary) -> MeshInstance3D:
	var model: Node3D = instance(species_id)
	var builder := VertexColorMesh.new()
	builder.append_model(
		model,
		Transform3D.IDENTITY,
		func(m: Material) -> Color: return FishLooks.surface_color(m, variant, cfg)
	)
	model.free()
	var result := MeshInstance3D.new()
	result.mesh = builder.commit()
	result.material_override = VertexColorMesh.material()
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return result


## Caixa do modelo inteiro no espaço dele, na escala 1 (nariz na direção +Z).
static func bounds(model: Node3D) -> AABB:
	var result := AABB()
	var first: bool = true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box: AABB = MeshMerge.relative_transform(mesh, model) * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result


## Cor de uma parte do peixe (material original), já com a variante (albino:
## corpo e nadadeiras claros, olho vermelho), para pintar nos vértices.
static func surface_color(original: Material, variant: String, cfg: Dictionary) -> Color:
	var colors: Dictionary = (cfg["variants"] as Dictionary).get(variant, {})
	if colors.is_empty():
		return (
			(original as BaseMaterial3D).albedo_color if original is BaseMaterial3D else Color.WHITE
		)
	var key: String = "body"
	if original != null and original.resource_name == EYE_MATERIAL:
		key = "eye"
	elif original != null and original.resource_name == PUPIL_MATERIAL:
		key = "pupil"
	return PresentationConfig.color(colors[key])


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
			var tinted := StandardMaterial3D.new()
			tinted.albedo_color = surface_color(original, variant, cfg)
			tinted.roughness = 0.5
			mesh_instance.set_surface_override_material(surface, tinted)
