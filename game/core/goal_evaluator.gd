class_name GoalEvaluator
extends RefCounted
## Metas do dia e estrelas (GDD p. 4 e 11; P-05, P-06, P-13, P-19).

const RARITY_ORDER: PackedStringArray = [
	"common", "uncommon", "rare", "epic", "legendary", "unique_legendary"
]


## A meta do dia (days.json, goal) foi cumprida com estes peixes e esta pontuação?
static func goal_met(
	goal: Dictionary, catches: Array[FishCatch], score: int, db: ContentDB
) -> bool:
	match String(goal["type"]):
		"score":
			return score >= int(goal["score"])
		"species_count":
			return _count_species(catches, goal["species"]) >= int(goal["count"])
		"fish_count":
			if catches.size() < int(goal["count"]):
				return false
			if goal.has("min_rarity"):
				var at_least: int = _count_at_least(catches, goal["min_rarity"], db)
				if at_least < int(goal["min_rarity_count"]):
					return false
			if goal.has("species"):
				if _count_species(catches, goal["species"]) < int(goal["species_count"]):
					return false
			return true
	assert(false, "Tipo de meta desconhecido: %s" % goal["type"])
	return false


## 0 estrelas se a meta falhou; senão 1, 2 ou 3 pela pontuação-alvo do dia (P-05).
static func stars(day_def: Dictionary, catches: Array[FishCatch], score: int, db: ContentDB) -> int:
	if not goal_met(day_def["goal"], catches, score, db):
		return 0
	var config: Dictionary = db.economy["stars"]
	var target: float = float(day_def["target_score"])
	var rewards: Array = config["rewards"]
	var earned: int = 1
	if score >= target * float(config["two_star_score_ratio"]):
		earned += 1
	if score >= target * float(config["three_star_score_ratio"]):
		earned += 1
	return mini(earned, rewards.size())


## Moedas por estrelas (P-13): paga a diferença ao melhorar a melhor marca do dia.
static func star_reward(previous_best: int, new_stars: int, db: ContentDB) -> int:
	if new_stars <= previous_best:
		return 0
	var rewards: Array = db.economy["stars"]["rewards"]
	var paid_before: int = int(rewards[previous_best - 1]) if previous_best > 0 else 0
	return int(rewards[new_stars - 1]) - paid_before


static func _count_species(catches: Array[FishCatch], species_id: String) -> int:
	var total: int = 0
	for fish in catches:
		if fish.species_id == species_id:
			total += 1
	return total


static func _count_at_least(catches: Array[FishCatch], min_rarity: String, db: ContentDB) -> int:
	var min_rank: int = RARITY_ORDER.find(min_rarity)
	var total: int = 0
	for fish in catches:
		if RARITY_ORDER.find(db.species(fish.species_id)["rarity"]) >= min_rank:
			total += 1
	return total
