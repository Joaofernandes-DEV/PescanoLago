class_name Scoring
extends RefCounted
## Pontos (P-09) e valor de venda (P-03) de um peixe. Todos os números vêm
## de economy.json e species.json.


## Peso ÷ peso médio da espécie, limitado (P-03). O peso médio é a média da
## distribuição triangular de tamanhos (P-08).
static func size_factor(weight_kg: float, species: Dictionary, economy: Dictionary) -> float:
	var dist: Dictionary = economy["size_distribution"]
	var fractions: Array = [dist["min_fraction"], dist["mode_fraction"], dist["max_fraction"]]
	var mean_fraction: float = 0.0
	for fraction: float in fractions:
		mean_fraction += fraction / fractions.size()
	var mean_kg: float = float(species["max_weight_kg"]) * mean_fraction
	var sale: Dictionary = economy["sale"]
	return clampf(
		weight_kg / mean_kg, float(sale["size_factor_min"]), float(sale["size_factor_max"])
	)


static func variant_multiplier(variant: String, economy: Dictionary) -> float:
	if variant == FishCatch.NO_VARIANT:
		return 1.0
	for variant_type: Dictionary in economy["variants"]["types"]:
		if variant_type["id"] == variant:
			return float(variant_type["multiplier"])
	assert(false, "Variante desconhecida: %s" % variant)
	return 1.0


## Pontos = pontos da espécie × tamanho × variante × combo + bônus de fisgada no tempo.
static func points(fish: FishCatch, species: Dictionary, economy: Dictionary) -> int:
	var species_points: float = float(species["points"])
	var total: float = (
		species_points
		* size_factor(fish.weight_kg, species, economy)
		* variant_multiplier(fish.variant, economy)
		* fish.combo_multiplier
	)
	if fish.early_hook:
		total += species_points * float(economy["hook_bonus"]["points_fraction"])
	return roundi(total)


## Moedas = valor base (pontos da espécie) × tamanho × variante × combo × multiplicador global.
static func sale_value(fish: FishCatch, species: Dictionary, economy: Dictionary) -> int:
	return roundi(
		(
			float(species["points"])
			* size_factor(fish.weight_kg, species, economy)
			* variant_multiplier(fish.variant, economy)
			* fish.combo_multiplier
			* float(economy["sale"]["global_multiplier"])
		)
	)
