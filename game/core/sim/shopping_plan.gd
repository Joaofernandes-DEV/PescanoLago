class_name ShoppingPlan
extends RefCounted
## Compras de um jogador simulado (sim_profiles.json, campaign): escolhe a isca do
## dia, repõe o estoque e compra varas e melhorias na ordem do plano. Usado pela
## simulação de campanha e pelo piloto automático do jogo, que compra nas lojas
## de Porto Manso pelo mesmo caminho que o jogador.

var _db: ContentDB
var _plan: Dictionary
var _shop: Shop


func _init(db: ContentDB, plan: Dictionary) -> void:
	_db = db
	_plan = plan
	_shop = Shop.new(db)


## Escolhe a isca do dia (plano por dia, como um jogador lendo a meta) e repõe o estoque.
func prepare_bait(state: PlayerState, day_number: int) -> void:
	var day_baits: Dictionary = _plan["day_baits"]
	var bait_id: String = day_baits.get(str(day_number), _plan["default_bait"])
	var reserve: int = int(_plan["bait_reserve"])
	while state.bait_count(bait_id) < reserve:
		if _shop.buy_bait_lot(state, bait_id) != Shop.Status.OK:
			break
	if _shop.equip_bait(state, bait_id) != Shop.Status.OK:
		_shop.equip_bait(state, _plan["default_bait"])


## Compra na ordem do plano; para no primeiro item que ainda não dá para pagar.
## Cada compra feita entra em purchases (sessão, tipo, id, nível e custo).
func buy(state: PlayerState, session_index: int, purchases: Array[Dictionary]) -> void:
	for item: Dictionary in _plan["purchases"]:
		var kind: String = item["kind"]
		var item_id: String = item["id"]
		if _already_done(state, kind, item_id, int(item.get("level", 0))):
			continue
		var coins_before: int = state.coins
		var status: Shop.Status = Shop.Status.NOT_AVAILABLE
		if kind == "rod":
			status = _shop.buy_rod(state, item_id)
			if status == Shop.Status.OK:
				_shop.equip_rod(state, item_id)
		else:
			status = _shop.buy_upgrade(state, item_id)
		if status != Shop.Status.OK:
			return
		var record: Dictionary = {
			"session": session_index,
			"kind": kind,
			"id": item_id,
			"level": state.level_of(item_id) if kind == "upgrade" else 0,
			"cost": coins_before - state.coins,
		}
		purchases.append(record)


func _already_done(state: PlayerState, kind: String, item_id: String, level: int) -> bool:
	if kind == "rod":
		return state.owned_rods.has(item_id)
	return state.level_of(item_id) >= level
