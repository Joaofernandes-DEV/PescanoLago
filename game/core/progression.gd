class_name Progression
extends RefCounted
## Quais dias o jogador pode jogar (P-26): o dia anterior com pelo menos 1
## estrela e o barco cumprindo a regra da região do dia (regions.json, unlock;
## GDD p. 9; nível do barco pela P-11).


## O que falta para jogar o dia, como lista de requisitos; vazia = pode jogar.
## Tipos: {"type": "stars", "day"}, {"type": "day", "day"},
## {"type": "boat_level", "level"}, {"type": "upgrade", "id", "level"}.
static func missing_for_day(
	db: ContentDB, state: PlayerState, day_number: int
) -> Array[Dictionary]:
	var missing: Array[Dictionary] = []
	if day_number > 1 and state.stars_of(day_number - 1) <= 0:
		missing.append({"type": "stars", "day": day_number - 1})
	var region_id: String = db.day(day_number)["region"]
	missing.append_array(missing_for_region(db, state, region_id, day_number))
	return missing


## Requisitos da região que o jogador ainda não cumpre neste dia.
static func missing_for_region(
	db: ContentDB, state: PlayerState, region_id: String, day_number: int
) -> Array[Dictionary]:
	var missing: Array[Dictionary] = []
	var unlock: Dictionary = db.region(region_id)["unlock"]
	if unlock.has("min_day") and day_number < int(unlock["min_day"]):
		missing.append({"type": "day", "day": int(unlock["min_day"])})
	if unlock.has("min_boat_level") and state.boat_level() < int(unlock["min_boat_level"]):
		missing.append({"type": "boat_level", "level": int(unlock["min_boat_level"])})
	var levels: Dictionary = unlock.get("min_upgrade_levels", {})
	for upgrade_id: String in levels:
		if state.level_of(upgrade_id) < int(levels[upgrade_id]):
			missing.append({"type": "upgrade", "id": upgrade_id, "level": int(levels[upgrade_id])})
	return missing


static func can_play(db: ContentDB, state: PlayerState, day_number: int) -> bool:
	if day_number < 1 or day_number > db.day_count():
		return false
	return missing_for_day(db, state, day_number).is_empty()


## Maior dia jogável agora (para abrir o mapa nele). O dia 1 sempre é jogável.
static func last_playable_day(db: ContentDB, state: PlayerState) -> int:
	var best: int = 1
	for day_number in range(1, db.day_count() + 1):
		if can_play(db, state, day_number):
			best = day_number
	return best
