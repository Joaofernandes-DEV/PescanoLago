class_name SaveCodec
extends RefCounted
## Save versionado: {"save_version", "game_version", "data"}.
##
## Cada mudança de formato sobe CURRENT_VERSION e registra em migrations() uma
## função pura que leva os dados da versão N para N+1. Todo save antigo
## precisa carregar: game/tests/fixtures/saves/ guarda um exemplo por versão.
## Ler e gravar o arquivo é trabalho do adaptador (SaveService); aqui só há dados.
##
## Versões:
##   1 (Fase 2): progresso do jogador.
##   2 (Fase 4): + sessions_played (dias jogados), para o jogo variar a semente
##      depois de fechar e reabrir.
# lint: números técnicos (versões do formato do save, não de balanceamento)

const CURRENT_VERSION: int = 2
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
	"sessions_played",
]


## versão de origem -> Callable(data: Dictionary) -> Dictionary
static func migrations() -> Dictionary:
	return {1: migrate_v1_to_v2}


## v1 -> v2: o save antigo não sabia quantos dias foram jogados; começa em 0.
static func migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	out["sessions_played"] = 0
	return out


static func encode(state: PlayerState, game_version: String) -> Dictionary:
	return {
		"save_version": CURRENT_VERSION,
		"game_version": game_version,
		"data": state.to_dict(),
	}


## Leva o save até a versão alvo aplicando as migrações em sequência.
## Sem a tabela de migrações, usa a do jogo (migrations()).
static func migrate(
	save: Dictionary, migration_table: Dictionary = {}, target_version: int = CURRENT_VERSION
) -> Dictionary:
	var steps: Dictionary = migration_table if not migration_table.is_empty() else migrations()
	var result: Dictionary = save.duplicate(true)
	var version: int = int(result["save_version"])
	while version < target_version:
		assert(steps.has(version), "Falta a migração do save da versão %d" % version)
		var step: Callable = steps[version]
		result["data"] = step.call(result["data"])
		version += 1
		result["save_version"] = version
	return result


## Mensagem de erro, ou "" se o save pode ser carregado.
static func validate(save: Dictionary, target_version: int = CURRENT_VERSION) -> String:
	if not save.has("save_version") or not save.has("data"):
		return "save sem 'save_version' ou 'data'"
	if not save["data"] is Dictionary:
		return "'data' do save não é um objeto"
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
