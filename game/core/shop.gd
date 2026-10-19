class_name Shop
extends RefCounted
## Lojas de Porto Manso: Tio Zeca (melhorias do barco) e Dona Marô (varas, peças
## extras e iscas). Respeita o recorte da versão (release.json), a regra de custos
## (P-14, P-16), a isca de socorro de Dona Marô (P-22) e os números da P-29.

enum Status {OK, NOT_ENOUGH_COINS, MAX_LEVEL, NOT_AVAILABLE, ALREADY_OWNED, NOT_OWNED, NO_FREE_SLOT}

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
	if _is_artificial(bait_id) and state.artificial_level(bait_id) <= 0:
		return Status.NOT_OWNED
	state.equipped_bait = bait_id
	return Status.OK


## Preço do próximo nível da isca artificial (o primeiro é a compra), ou NO_PRICE.
func artificial_bait_price(state: PlayerState, bait_id: String) -> int:
	if not _is_artificial(bait_id):
		return NO_PRICE
	var costs: Array = _db.bait(bait_id)["level_costs"]
	var level: int = state.artificial_level(bait_id)
	if level >= costs.size():
		return NO_PRICE
	return int(costs[level])


## Compra a isca artificial (nível 1) ou sobe um nível. Ela não acaba (GDD p. 7).
func buy_artificial_bait(state: PlayerState, bait_id: String) -> Status:
	if not _db.is_enabled("baits", bait_id) or not _is_artificial(bait_id):
		return Status.NOT_AVAILABLE
	var price: int = artificial_bait_price(state, bait_id)
	if price == NO_PRICE:
		return Status.MAX_LEVEL
	if state.coins < price:
		return Status.NOT_ENOUGH_COINS
	state.coins -= price
	state.artificial_bait_levels[bait_id] = state.artificial_level(bait_id) + 1
	return Status.OK


## Compra uma peça extra (uma de cada) e já a monta na vara equipada, se houver vaga.
func buy_rod_part(state: PlayerState, part_id: String) -> Status:
	if not _db.is_enabled("rod_parts", part_id):
		return Status.NOT_AVAILABLE
	if state.owned_rod_parts.has(part_id):
		return Status.ALREADY_OWNED
	var price: int = int(_db.rod_parts[part_id]["cost"])
	if state.coins < price:
		return Status.NOT_ENOUGH_COINS
	state.coins -= price
	state.owned_rod_parts.append(part_id)
	install_part(state, part_id, state.equipped_rod)
	return Status.OK


## Monta a peça na vara (tirando-a de outra vara, se for o caso). Cada vara tem
## part_slots vagas (GDD: até 2 peças); trocar de vara não custa nada.
func install_part(state: PlayerState, part_id: String, rod_id: String) -> Status:
	if not state.owned_rod_parts.has(part_id) or not state.owned_rods.has(rod_id):
		return Status.NOT_OWNED
	var parts: Array = state.parts_on(rod_id)
	if parts.has(part_id):
		return Status.OK
	if parts.size() >= _db.part_slots:
		return Status.NO_FREE_SLOT
	remove_part(state, part_id)
	parts = state.parts_on(rod_id).duplicate()
	parts.append(part_id)
	state.rod_parts[rod_id] = parts
	return Status.OK


## Tira a peça da vara em que está (ela continua do jogador).
func remove_part(state: PlayerState, part_id: String) -> Status:
	if not state.owned_rod_parts.has(part_id):
		return Status.NOT_OWNED
	for rod_id: String in state.rod_parts.keys():
		var parts: Array = state.parts_on(rod_id).duplicate()
		parts.erase(part_id)
		state.rod_parts[rod_id] = parts
	return Status.OK


## Primeira isca natural desta versão que o jogador tem em estoque, na ordem de
## baits.json, ou "" se não tem nenhuma.
func first_bait_in_stock(state: PlayerState) -> String:
	for bait_id in _db.bait_ids():
		if _db.is_enabled("baits", bait_id) and _db.is_natural_bait(bait_id):
			if state.bait_count(bait_id) > 0:
				return bait_id
	return ""


## Antes do dia: se a isca natural equipada acabou, equipa a primeira com estoque.
## Devolve false se o jogador não tem isca nenhuma para lançar.
func ensure_bait_equipped(state: PlayerState) -> bool:
	if not _db.is_natural_bait(state.equipped_bait):
		return true
	if state.bait_count(state.equipped_bait) > 0:
		return true
	var in_stock: String = first_bait_in_stock(state)
	if in_stock.is_empty():
		return false
	state.equipped_bait = in_stock
	return true


## Preço do lote mais barato entre as iscas naturais desta versão.
func cheapest_bait_lot_price() -> int:
	var cheapest: int = NO_PRICE
	for bait_id in _db.bait_ids():
		if _db.is_enabled("baits", bait_id) and _db.is_natural_bait(bait_id):
			var price: int = bait_lot_price(bait_id)
			if cheapest == NO_PRICE or price < cheapest:
				cheapest = price
	return cheapest


## Sem nenhuma isca e sem moedas para o lote mais barato, o jogador ficaria
## preso: não pesca, não vende e não ganha moedas (P-22).
func needs_bait_rescue(state: PlayerState) -> bool:
	return first_bait_in_stock(state).is_empty() and state.coins < cheapest_bait_lot_price()


## Dona Marô dá a isca de socorro (economy.json, bait_rescue) e já a equipa.
func rescue_bait(state: PlayerState) -> bool:
	if not needs_bait_rescue(state):
		return false
	var rescue: Dictionary = _db.economy["bait_rescue"]
	var bait_id: String = rescue["bait"]
	var units: int = int(rescue["lots"]) * _db.lot_size()
	state.bait_inventory[bait_id] = state.bait_count(bait_id) + units
	state.equipped_bait = bait_id
	return true


func _is_artificial(bait_id: String) -> bool:
	return _db.bait(bait_id)["type"] == "artificial"
