class_name ShoppingPlan
extends RefCounted
## Compras de um jogador simulado (sim_profiles.json, campaigns): escolhe a isca do
## dia, repõe o estoque e compra varas, peças, iscas artificiais e melhorias na
## ordem do plano. Usado pela simulação de campanha e pelo piloto automático do
## jogo, que compra nas lojas de Porto Manso pelo mesmo caminho que o jogador.

var _db: ContentDB
var _plan: Dictionary
var _shop: Shop


func _init(db: ContentDB, plan: Dictionary) -> void:
	_db = db
	_plan = plan
	_shop = Shop.new(db)


## O plano do perfil de versão em uso (release.json).
static func for_release(db: ContentDB) -> ShoppingPlan:
	return ShoppingPlan.new(db, db.sim_profiles["campaigns"][db.release["id"]])


## Escolhe a isca do dia (plano por dia, como um jogador lendo a meta) e repõe o
## estoque. Sem a isca do plano (artificial não comprada), usa a isca padrão.
func prepare_bait(state: PlayerState, day_number: int) -> void:
	var day_baits: Dictionary = _plan["day_baits"]
	var bait_id: String = day_baits.get(str(day_number), _plan["default_bait"])
	if not _ready_bait(state, bait_id):
		_shop.equip_bait(state, _plan["default_bait"])


## Compra na ordem do plano; para no primeiro item que ainda não dá para pagar.
## Cada compra feita entra em purchases (sessão, tipo, id, nível e custo).
## next_day: o próximo dia a jogar; guarda as moedas para repor a isca dele,
## como uma pessoa que não gasta o dinheiro da isca de amanhã (0 = não guarda).
func buy(
	state: PlayerState, session_index: int, purchases: Array[Dictionary], next_day: int = 0
) -> void:
	var reserve: int = _bait_restock_cost(state, next_day) if next_day > 0 else 0
	for item: Dictionary in _plan["purchases"]:
		var kind: String = item["kind"]
		var item_id: String = item["id"]
		var level: int = int(item.get("level", 0))
		while not _already_done(state, kind, item_id, level):
			var coins_before: int = state.coins
			state.coins -= reserve
			var status: Shop.Status = _buy_one(state, kind, item_id)
			state.coins += reserve
			if status != Shop.Status.OK:
				return
			(
				purchases
				. append(
					{
						"session": session_index,
						"kind": kind,
						"id": item_id,
						"level": _level_now(state, kind, item_id),
						"cost": coins_before - state.coins,
					}
				)
			)


## Quanto custa repor a isca (natural) do dia até a reserva do plano.
func _bait_restock_cost(state: PlayerState, day_number: int) -> int:
	var bait_id: String = _plan["day_baits"].get(str(day_number), _plan["default_bait"])
	if not _db.is_natural_bait(bait_id):
		return 0
	var missing: int = maxi(0, int(_plan["bait_reserve"]) - state.bait_count(bait_id))
	var lots: int = ceili(float(missing) / float(_db.lot_size()))
	return lots * _shop.bait_lot_price(bait_id)


func _ready_bait(state: PlayerState, bait_id: String) -> bool:
	if _db.is_natural_bait(bait_id):
		var reserve: int = int(_plan["bait_reserve"])
		while state.bait_count(bait_id) < reserve:
			if _shop.buy_bait_lot(state, bait_id) != Shop.Status.OK:
				break
	return _shop.equip_bait(state, bait_id) == Shop.Status.OK


func _buy_one(state: PlayerState, kind: String, item_id: String) -> Shop.Status:
	match kind:
		"rod":
			var status: Shop.Status = _shop.buy_rod(state, item_id)
			if status == Shop.Status.OK:
				_shop.equip_rod(state, item_id)
				# As peças vão junto para a vara nova.
				for part_id: String in state.owned_rod_parts:
					_shop.install_part(state, part_id, item_id)
			return status
		"bait":
			return _shop.buy_artificial_bait(state, item_id)
		"part":
			return _shop.buy_rod_part(state, item_id)
	return _shop.buy_upgrade(state, item_id)


func _already_done(state: PlayerState, kind: String, item_id: String, level: int) -> bool:
	match kind:
		"rod":
			return state.owned_rods.has(item_id)
		"part":
			return state.owned_rod_parts.has(item_id)
		"bait":
			return state.artificial_level(item_id) >= level
	return state.level_of(item_id) >= level


func _level_now(state: PlayerState, kind: String, item_id: String) -> int:
	match kind:
		"upgrade":
			return state.level_of(item_id)
		"bait":
			return state.artificial_level(item_id)
	return 0
