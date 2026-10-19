class_name PlayerState
extends RefCounted
## Progresso do jogador entre os dias: moedas, melhorias, varas e peças,
## iscas, estrelas, álbum e dias jogados. Serializado pelo SaveCodec.

var coins: int = 0
var total_sales: int = 0
var best_stars: Dictionary = {}
var upgrade_levels: Dictionary = {}
var owned_rods: Array[String] = []
var equipped_rod: String = ""
var bait_inventory: Dictionary = {}
var equipped_bait: String = ""
## Iscas artificiais compradas: id -> nível (1 a 3). Não acabam (GDD p. 7).
var artificial_bait_levels: Dictionary = {}
## Peças extras compradas (cada uma uma vez) e em qual vara estão montadas.
var owned_rod_parts: Array[String] = []
var rod_parts: Dictionary = {}
## Dicas de controle: id da dica -> quantas vezes o jogador já fez a ação.
## A interface esconde a dica depois de algumas vezes.
var tips_progress: Dictionary = {}
var album: Dictionary = {}
## Dias de pesca jogados (cada tentativa conta). O jogo usa para variar a semente.
var sessions_played: int = 0


## Estado inicial (P-17): economy.json, start_state; todas as melhorias no nível 1.
static func new_game(db: ContentDB) -> PlayerState:
	var state := PlayerState.new()
	var start: Dictionary = db.economy["start_state"]
	state.coins = int(start["coins"])
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 1
	state.owned_rods.append(start["rod"])
	state.equipped_rod = start["rod"]
	for bait_id: String in start["bait_inventory"]:
		state.bait_inventory[bait_id] = int(start["bait_inventory"][bait_id])
	state.equipped_bait = start["bait"]
	return state


func level_of(upgrade_id: String) -> int:
	return int(upgrade_levels[upgrade_id])


## Nível do barco (P-11): média dos níveis das melhorias, arredondada para baixo.
func boat_level() -> int:
	var total: int = 0
	for level: int in upgrade_levels.values():
		total += level
	return total / upgrade_levels.size()


func stars_of(day_number: int) -> int:
	return int(best_stars.get(str(day_number), 0))


## Último dia liberado: o seguinte ao maior dia com pelo menos 1 estrela.
func unlocked_day(day_count: int) -> int:
	var day_number: int = 1
	while day_number < day_count and stars_of(day_number) > 0:
		day_number += 1
	return day_number


func is_day_unlocked(day_number: int, day_count: int) -> bool:
	return day_number >= 1 and day_number <= unlocked_day(day_count)


func bait_count(bait_id: String) -> int:
	return int(bait_inventory.get(bait_id, 0))


## Nível da isca artificial (0 = não comprada).
func artificial_level(bait_id: String) -> int:
	return int(artificial_bait_levels.get(bait_id, 0))


## Quantas vezes o jogador já fez a ação da dica.
func tip_count(tip_id: String) -> int:
	return int(tips_progress.get(tip_id, 0))


## Peças montadas na vara.
func parts_on(rod_id: String) -> Array:
	return rod_parts.get(rod_id, [])


## Registra a captura no álbum (espécie, variantes vistas e maior peso).
func register_in_album(fish: FishCatch) -> void:
	var entry: Dictionary = album.get(
		fish.species_id, {"caught": 0, "variants": [], "best_weight_kg": 0.0}
	)
	entry["caught"] = int(entry["caught"]) + 1
	var variants: Array = entry["variants"]
	if fish.is_variant() and not variants.has(fish.variant):
		variants.append(fish.variant)
	entry["best_weight_kg"] = maxf(float(entry["best_weight_kg"]), fish.weight_kg)
	album[fish.species_id] = entry


func to_dict() -> Dictionary:
	return {
		"coins": coins,
		"total_sales": total_sales,
		"best_stars": best_stars.duplicate(true),
		"upgrade_levels": upgrade_levels.duplicate(true),
		"owned_rods": owned_rods.duplicate(),
		"equipped_rod": equipped_rod,
		"bait_inventory": bait_inventory.duplicate(true),
		"equipped_bait": equipped_bait,
		"artificial_bait_levels": artificial_bait_levels.duplicate(true),
		"owned_rod_parts": owned_rod_parts.duplicate(),
		"rod_parts": rod_parts.duplicate(true),
		"tips_progress": tips_progress.duplicate(true),
		"album": album.duplicate(true),
		"sessions_played": sessions_played,
	}


## O JSON devolve todo número como float: os inteiros são convertidos aqui.
static func from_dict(data: Dictionary) -> PlayerState:
	var state := PlayerState.new()
	state.coins = int(data["coins"])
	state.total_sales = int(data["total_sales"])
	for day_key: String in data["best_stars"]:
		state.best_stars[day_key] = int(data["best_stars"][day_key])
	for upgrade_id: String in data["upgrade_levels"]:
		state.upgrade_levels[upgrade_id] = int(data["upgrade_levels"][upgrade_id])
	for rod_id: String in data["owned_rods"]:
		state.owned_rods.append(rod_id)
	state.equipped_rod = data["equipped_rod"]
	for bait_id: String in data["bait_inventory"]:
		state.bait_inventory[bait_id] = int(data["bait_inventory"][bait_id])
	state.equipped_bait = data["equipped_bait"]
	for bait_id: String in data["artificial_bait_levels"]:
		state.artificial_bait_levels[bait_id] = int(data["artificial_bait_levels"][bait_id])
	for part_id: String in data["owned_rod_parts"]:
		state.owned_rod_parts.append(part_id)
	for rod_id: String in data["rod_parts"]:
		state.rod_parts[rod_id] = Array(data["rod_parts"][rod_id]).duplicate()
	for tip_id: String in data["tips_progress"]:
		state.tips_progress[tip_id] = int(data["tips_progress"][tip_id])
	for species_id: String in data["album"]:
		var entry: Dictionary = data["album"][species_id]
		state.album[species_id] = {
			"caught": int(entry["caught"]),
			"variants": Array(entry["variants"]).duplicate(),
			"best_weight_kg": float(entry["best_weight_kg"]),
		}
	state.sessions_played = int(data["sessions_played"])
	return state
