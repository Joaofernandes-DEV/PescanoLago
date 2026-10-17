class_name SaveCodec
extends RefCounted
## Save versionado: {"save_version", "game_version", "data"}.
##
## Cada mudança de formato sobe CURRENT_VERSION e registra em MIGRATIONS uma
## função pura que leva os dados da versão N para N+1. Todo save antigo
## precisa carregar: game/tests/fixtures/saves/ guarda um exemplo por versão.
## Ler e gravar o arquivo é trabalho do adaptador (Fase 4); aqui só há dados.

const CURRENT_VERSION: int = 1
## versão de origem -> Callable(data: Dictionary) -> Dictionary
const MIGRATIONS: Dictionary = {}
const REQUIRED_KEYS: PackedStringArray = [
	"coins",
	"total_sales",
	"best_stars",
	"upgrade_levels",
	"owned_rods",
	"equipped_rod",
	"bait_inventory",
	"equipped_bait",
	"album",
]


static func encode(state: PlayerState, game_version: String) -> Dictionary:
	return {
		"save_version": CURRENT_VERSION,
		"game_version": game_version,
		"data": state.to_dict(),
	}


## Leva o save até a versão alvo aplicando as migrações em sequência.
static func migrate(
	save: Dictionary, migrations: Dictionary = MIGRATIONS, target_version: int = CURRENT_VERSION
) -> Dictionary:
	var result: Dictionary = save.duplicate(true)
	var version: int = int(result["save_version"])
	while version < target_version:
		assert(migrations.has(version), "Falta a migração do save da versão %d" % version)
		var step: Callable = migrations[version]
		result["data"] = step.call(result["data"])
		version += 1
		result["save_version"] = version
	return result


## Mensagem de erro, ou "" se o save pode ser carregado.
static func validate(save: Dictionary, target_version: int = CURRENT_VERSION) -> String:
	if not save.has("save_version") or not save.has("data"):
		return "save sem 'save_version' ou 'data'"
	var version: int = int(save["save_version"])
	if version > target_version:
		return "save da versão %d é mais novo que o jogo (%d)" % [version, target_version]
	if version < 1:
		return "versão de save inválida: %d" % version
	return ""


## PlayerState do save (migrado se for antigo), ou null se o save for inválido.
static func decode(save: Dictionary) -> PlayerState:
	if not validate(save).is_empty():
		return null
	var current: Dictionary = migrate(save)
	var data: Dictionary = current["data"]
	for key in REQUIRED_KEYS:
		if not data.has(key):
			return null
	return PlayerState.from_dict(data)
