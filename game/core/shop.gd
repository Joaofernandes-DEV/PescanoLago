class_name Shop
extends RefCounted
## Lojas de Porto Manso: Tio Zeca (melhorias do barco) e Dona Marô (varas e iscas).
## Respeita o recorte da versão (release.json) e a regra de custos (P-14, P-16).

enum Status { OK, NOT_ENOUGH_COINS, MAX_LEVEL, NOT_AVAILABLE, ALREADY_OWNED, NOT_OWNED }

const NO_PRICE: int = -1

var _db: ContentDB


func _init(db: ContentDB) -> void:
	_db = db


## Preço do próximo nível da melhoria, ou NO_PRICE se não há próximo nível nesta versão.
## O nível 1 é o inicial: comprar o nível N custa o N-ésimo valor da tabela (P-14).
func upgrade_price(state: PlayerState, upgrade_id: String) -> int:
	var next_level: int = state.level_of(upgrade_id) + 1
	if next_level > _db.upgrade_max_level(upgrade_id):
		return NO_PRICE
	return int(_db.upgrade_level(upgrade_id, next_level)["cost"])


func buy_upgrade(state: PlayerState, upgrade_id: String) -> Status:
	if not _db.is_enabled("upgrades", upgrade_id):
		return Status.NOT_AVAILABLE
	var price: int = upgrade_price(state, upgrade_id)
	if price == NO_PRICE:
		return Status.MAX_LEVEL
	if state.coins < price:
		return Status.NOT_ENOUGH_COINS
	state.coins -= price
	state.upgrade_levels[upgrade_id] = state.level_of(upgrade_id) + 1
	return Status.OK


func buy_rod(state: PlayerState, rod_id: String) -> Status:
	var rod: Dictionary = _db.rod(rod_id)
	if not _db.is_enabled("rods", rod_id) or rod.has("requires_mission"):
		return Status.NOT_AVAILABLE
	if state.owned_rods.has(rod_id):
		return Status.ALREADY_OWNED
	var price: int = int(rod["cost"])
	if state.coins < price:
		return Status.NOT_ENOUGH_COINS
	state.coins -= price
	state.owned_rods.append(rod_id)
	return Status.OK


func equip_rod(state: PlayerState, rod_id: String) -> Status:
	if not state.owned_rods.has(rod_id):
		return Status.NOT_OWNED
	state.equipped_rod = rod_id
	return Status.OK


## Preço de um lote de isca natural (unidade × tamanho do lote, P-16).
func bait_lot_price(bait_id: String) -> int:
	return int(_db.bait(bait_id)["cost_per_unit"]) * _db.lot_size()


func buy_bait_lot(state: PlayerState, bait_id: String) -> Status:
	if not _db.is_enabled("baits", bait_id) or not _db.is_natural_bait(bait_id):
		return Status.NOT_AVAILABLE
	var price: int = bait_lot_price(bait_id)
	if state.coins < price:
		return Status.NOT_ENOUGH_COINS
	state.coins -= price
	state.bait_inventory[bait_id] = state.bait_count(bait_id) + _db.lot_size()
	return Status.OK


func equip_bait(state: PlayerState, bait_id: String) -> Status:
	if not _db.is_enabled("baits", bait_id):
		return Status.NOT_AVAILABLE
	if _db.is_natural_bait(bait_id) and state.bait_count(bait_id) <= 0:
		return Status.NOT_OWNED
	state.equipped_bait = bait_id
	return Status.OK
