class_name CatchRoller
extends RefCounted
## Sorteia o peixe que mordeu: espécie (SpawnTable), peso (P-08) e variante.

var _db: ContentDB
var _spawns: SpawnTable


func _init(db: ContentDB) -> void:
	_db = db
	_spawns = SpawnTable.new(db)


## variant_bonus: chance extra de variante (sonar, conforto, isca; Loadout).
## surface_multiplier: fator dos peixes de superfície (motor; Loadout).
func roll(
	region_id: String,
	phase: String,
	bait_id: String,
	variant_bonus: float,
	rng: Rng,
	surface_multiplier: float = 1.0
) -> FishCatch:
	var species_id: String = _spawns.pick(region_id, phase, bait_id, rng, surface_multiplier)
	if species_id.is_empty():
		return null
	var species: Dictionary = _db.species(species_id)
	return FishCatch.new(
		species_id, roll_weight(species, rng), roll_variant(species, variant_bonus, rng)
	)


## Peso em kg: distribuição triangular entre frações do peso máximo (P-08).
func roll_weight(species: Dictionary, rng: Rng) -> float:
	var dist: Dictionary = _db.economy["size_distribution"]
	var max_kg: float = float(species["max_weight_kg"])
	var low: float = max_kg * float(dist["min_fraction"])
	var mode: float = max_kg * float(dist["mode_fraction"])
	var high: float = max_kg * float(dist["max_fraction"])
	var u: float = rng.next_float()
	if u < (mode - low) / (high - low):
		return low + sqrt(u * (high - low) * (mode - low))
	return high - sqrt((1.0 - u) * (high - low) * (high - mode))


## Variante (albina, dourada...): chance base + bônus (sonar, conforto, isca), só para
## raridades elegíveis e variantes ligadas nesta versão. Sempre consome o mesmo número
## de sorteios.
func roll_variant(species: Dictionary, variant_bonus: float, rng: Rng) -> String:
	var config: Dictionary = _db.economy["variants"]
	var chance: float = float(config["base_chance"]) + variant_bonus
	var hit: bool = rng.chance(chance)
	var types: Array = []
	var type_weights: PackedFloat64Array = []
	for variant_type: Dictionary in config["types"]:
		if _db.is_enabled("variants", variant_type["id"]):
			types.append(variant_type["id"])
			type_weights.append(float(variant_type["weight"]))
	var index: int = rng.weighted_index(type_weights)
	var eligible: Array = config["eligible_rarities"]
	if not hit or index < 0 or not eligible.has(species["rarity"]):
		return FishCatch.NO_VARIANT
	return types[index]
