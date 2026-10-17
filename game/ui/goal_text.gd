class_name GoalText
extends RefCounted
## Texto da meta do dia (days.json, goal), para o HUD e o mapa dos dias.
## Com a sessão, mostra também o progresso entre parênteses.


static func describe(goal: Dictionary, db: ContentDB, session: DaySession = null) -> String:
	match String(goal["type"]):
		"score":
			var score_text: String = "%d pontos" % int(goal["score"])
			return score_text + (" (%d)" % session.score if session != null else "")
		"species_count":
			var species_name: String = db.species(goal["species"])["common_name"]
			var text: String = "%d × %s" % [int(goal["count"]), species_name]
			if session != null:
				text += " (%d)" % _count_species(session, goal["species"])
			return text
	var fish_text: String = "%d peixes" % int(goal["count"])
	if session != null:
		fish_text += " (%d)" % session.catches.size()
	if goal.has("min_rarity"):
		fish_text += ", %d incomuns ou mais raros" % int(goal["min_rarity_count"])
	if goal.has("species"):
		fish_text += (
			", %d %s" % [int(goal["species_count"]), db.species(goal["species"])["common_name"]]
		)
	return fish_text


static func _count_species(session: DaySession, species_id: String) -> int:
	var total: int = 0
	for fish in session.catches:
		if fish.species_id == species_id:
			total += 1
	return total
