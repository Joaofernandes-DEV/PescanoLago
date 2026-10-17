class_name SpawnTable
extends RefCounted
## Qual espécie morde: pesos da região × período do dia × afinidade da isca (P-12).

var _db: ContentDB


func _init(db: ContentDB) -> void:
	_db = db


## Pesos por espécie, na ordem do arquivo regions.json (ordem estável = sorteio determinístico).
func weights(region_id: String, phase: String, bait_id: String) -> Dictionary:
	var affinity: Dictionary = _db.economy["bait_affinity"]
	var result: Dictionary = {}
	for spawn: Dictionary in _db.region(region_id)["spawns"]:
		if spawn.get("mvp_only", false) and not _db.is_mvp():
			continue
		var species_id: String = spawn["species"]
		var weight: float = float(spawn["weight"]) * float(spawn["period_multipliers"][phase])
		if _db.is_ideal_bait(species_id, bait_id):
			weight *= float(affinity["ideal_multiplier"])
		elif not _db.is_common(species_id):
			weight *= float(affinity["non_ideal_rare_multiplier"])
		result[species_id] = weight
	return result


## Sorteia a espécie que morde. Devolve "" se a região não tem peixe.
func pick(region_id: String, phase: String, bait_id: String, rng: Rng) -> String:
	var table: Dictionary = weights(region_id, phase, bait_id)
	var index: int = rng.weighted_index(PackedFloat64Array(table.values()))
	if index < 0:
		return ""
	return table.keys()[index]
