class_name FishCatch
extends RefCounted
## Um peixe pego: espécie, peso, variante e o contexto que afeta pontos e venda.

const NO_VARIANT: String = ""

var species_id: String
var weight_kg: float
var variant: String
var combo_multiplier: float = 1.0
var early_hook: bool = false


func _init(p_species_id: String, p_weight_kg: float, p_variant: String = NO_VARIANT) -> void:
	species_id = p_species_id
	weight_kg = p_weight_kg
	variant = p_variant


func is_variant() -> bool:
	return variant != NO_VARIANT


func to_dict() -> Dictionary:
	return {
		"species": species_id,
		"weight_kg": weight_kg,
		"variant": variant,
		"combo_multiplier": combo_multiplier,
		"early_hook": early_hook,
	}


static func from_dict(data: Dictionary) -> FishCatch:
	var fish := FishCatch.new(data["species"], float(data["weight_kg"]), data["variant"])
	fish.combo_multiplier = float(data["combo_multiplier"])
	fish.early_hook = bool(data["early_hook"])
	return fish
