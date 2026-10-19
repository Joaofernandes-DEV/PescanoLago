class_name ContentDB
extends RefCounted
## Conteúdo do jogo (game/content/*.json) em memória, só para leitura.
##
## O núcleo nunca lê arquivos: quem carrega os JSON é o adaptador
## ContentLoader. Os documentos já chegam validados pelo esquema (CI).
## Todo número de balanceamento vem daqui.
##
## release.json tem perfis (mvp, full): o jogo usa o perfil "active"; testes e
## simulador podem escolher outro (P-26).

const FILES: PackedStringArray = [
	"species",
	"baits",
	"rods",
	"boat_upgrades",
	"regions",
	"days",
	"economy",
	"release",
	"sim_profiles",
]
const COMMON_RARITY: String = "common"

var economy: Dictionary
var release: Dictionary
var sim_profiles: Dictionary
## Peças extras das varas por id (rods.json, parts) e quantas cabem em cada vara.
var rod_parts: Dictionary
var part_slots: int
var _species: Dictionary
var _baits: Dictionary
var _rods: Dictionary
var _upgrades: Dictionary
var _regions: Dictionary
var _days: Array
var _lot_size: int
var _reel_speed: Dictionary


## profile_id: perfil de release.json; vazio usa o perfil ativo.
func _init(docs: Dictionary, profile_id: String = "") -> void:
	for file_name in FILES:
		assert(docs.has(file_name), "ContentDB: falta o documento '%s'" % file_name)
	_species = _index(docs["species"]["species"])
	_baits = _index(docs["baits"]["baits"])
	_rods = _index(docs["rods"]["rods"])
	rod_parts = _index(docs["rods"]["parts"])
	part_slots = int(docs["rods"]["part_slots"])
	_upgrades = _index(docs["boat_upgrades"]["upgrades"])
	_regions = _index(docs["regions"]["regions"])
	_days = docs["days"]["days"]
	_lot_size = int(docs["baits"]["lot_size"])
	_reel_speed = docs["rods"]["reel_speed_m_s"]
	economy = docs["economy"]
	var wanted: String = profile_id if not profile_id.is_empty() else docs["release"]["active"]
	release = _index(docs["release"]["profiles"]).get(wanted, {})
	assert(not release.is_empty(), "Perfil de versão desconhecido: %s" % wanted)
	sim_profiles = docs["sim_profiles"]


static func _index(items: Array) -> Dictionary:
	var result: Dictionary = {}
	for item: Dictionary in items:
		result[item["id"]] = item
	return result


func species(species_id: String) -> Dictionary:
	assert(_species.has(species_id), "Espécie desconhecida: %s" % species_id)
	return _species[species_id]


func species_ids() -> PackedStringArray:
	return PackedStringArray(_species.keys())


func bait(bait_id: String) -> Dictionary:
	assert(_baits.has(bait_id), "Isca desconhecida: %s" % bait_id)
	return _baits[bait_id]


## Iscas na ordem de baits.json.
func bait_ids() -> PackedStringArray:
	return PackedStringArray(_baits.keys())


func is_natural_bait(bait_id: String) -> bool:
	return bait(bait_id)["type"] == "natural"


func lot_size() -> int:
	return _lot_size


func rod(rod_id: String) -> Dictionary:
	assert(_rods.has(rod_id), "Vara desconhecida: %s" % rod_id)
	return _rods[rod_id]


func reel_speed_m_s(rod_id: String) -> float:
	return float(_reel_speed[rod(rod_id)["reel_power"]])


func upgrade(upgrade_id: String) -> Dictionary:
	assert(_upgrades.has(upgrade_id), "Melhoria desconhecida: %s" % upgrade_id)
	return _upgrades[upgrade_id]


func upgrade_ids() -> PackedStringArray:
	return PackedStringArray(_upgrades.keys())


## Dados de um nível (1 a 5) de uma melhoria do barco.
func upgrade_level(upgrade_id: String, level: int) -> Dictionary:
	var levels: Array = upgrade(upgrade_id)["levels"]
	assert(level >= 1 and level <= levels.size(), "Nível inválido %d para %s" % [level, upgrade_id])
	return levels[level - 1]


## Maior nível comprável nesta versão (o recorte do MVP limita níveis e melhorias).
func upgrade_max_level(upgrade_id: String) -> int:
	if not is_enabled("upgrades", upgrade_id):
		return 1
	var levels: Array = upgrade(upgrade_id)["levels"]
	return mini(levels.size(), int(release["max_upgrade_level"]))


func region(region_id: String) -> Dictionary:
	assert(_regions.has(region_id), "Região desconhecida: %s" % region_id)
	return _regions[region_id]


## O dia como esta versão o vê: no MVP, valem os campos de mvp_override (P-26).
func day(day_number: int) -> Dictionary:
	assert(day_number >= 1 and day_number <= _days.size(), "Dia inexistente: %d" % day_number)
	var entry: Dictionary = _days[day_number - 1]
	if is_mvp() and entry.has("mvp_override"):
		var merged: Dictionary = entry.duplicate()
		merged.merge(entry["mvp_override"], true)
		return merged
	return entry


## Quantos dias estão ligados nesta versão.
func day_count() -> int:
	return int(release["days"])


## Isca ideal para a espécie: vale a tabela de peixes OU a de iscas do GDD (P-12).
func is_ideal_bait(species_id: String, bait_id: String) -> bool:
	var species_baits: Array = species(species_id)["ideal_baits"]
	var attracts: Array = bait(bait_id)["attracts"]
	return species_baits.has(bait_id) or attracts.has(species_id)


func is_common(species_id: String) -> bool:
	return species(species_id)["rarity"] == COMMON_RARITY


## O conteúdo está ligado nesta versão?
## kind: rods, baits, upgrades, regions, variants, rod_parts.
func is_enabled(kind: String, content_id: String) -> bool:
	var enabled: Array = release.get("enabled_" + kind, [])
	return enabled.has(content_id)


## Perfil do jogador simulado (sim_profiles.json), para testes e simulador.
func bot_profile(bot_id: String) -> Dictionary:
	for bot: Dictionary in sim_profiles["bots"]:
		if bot["id"] == bot_id:
			return bot
	assert(false, "Perfil de jogador simulado desconhecido: %s" % bot_id)
	return {}


func is_mvp() -> bool:
	return release["mode"] == "mvp"
