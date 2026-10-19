class_name HubController
extends Node3D
## Porto Manso, o hub entre os dias (P-23): o Esperança atracado no cais, a vila
## ao fundo e a interface das lojas e do mapa dos dias. As compras passam pelo
## Shop do núcleo; cada mudança no progresso emite state_changed (o jogo salva).
##
## Com autopilot (ShoppingPlan), compra como o jogador simulado e pede o dia
## escolhido sozinho, pelo mesmo caminho dos botões.

signal play_requested(day_number: int)
signal state_changed

const SHOP_MESSAGES: Dictionary = {
	Shop.Status.NOT_ENOUGH_COINS: "Moedas insuficientes.",
	Shop.Status.MAX_LEVEL: "Essa melhoria já está no nível máximo desta versão.",
	Shop.Status.NOT_AVAILABLE: "Isso não está à venda nesta versão.",
	Shop.Status.ALREADY_OWNED: "Você já tem essa vara.",
	Shop.Status.NOT_OWNED: "Você ainda não tem isso.",
	Shop.Status.NO_FREE_SLOT: "Essa vara já tem as duas peças montadas.",
}

## null = jogador humano.
var autopilot: ShoppingPlan
var selected_day: int = 1
var ui: HubUi
var lighting: DayLighting
var camera: Camera3D
## O Esperança atracado, flutuando na água (física do barco parada).
var boat: BoatController
var boat_model: Node3D
var water: LakeWater
var birds: Birds
## Personagens: zeca e maro nas lojas; tom e bolota no barco atracado.
var characters: Dictionary = {}
## Compras feitas pelo piloto automático (para os testes e o LOG).
var autopilot_purchases: Array[Dictionary] = []

var _db: ContentDB
var _state: PlayerState
var _pres: PresentationConfig
var _shop: Shop


func setup(db: ContentDB, state: PlayerState, pres: PresentationConfig, day_number: int) -> void:
	_db = db
	_state = state
	_pres = pres
	_shop = Shop.new(db)
	selected_day = clampi(day_number, 1, Progression.last_playable_day(db, state))


func _ready() -> void:
	_build_world()
	ui = HubUi.new()
	ui.setup(_db, _state, _shop)
	ui.set_selected_day(selected_day)
	add_child(ui)
	ui.day_selected.connect(_on_day_selected)
	ui.play_pressed.connect(request_play)
	ui.upgrade_requested.connect(buy_upgrade)
	ui.rod_requested.connect(buy_rod)
	ui.rod_equip_requested.connect(equip_rod)
	ui.bait_requested.connect(buy_bait)
	ui.bait_equip_requested.connect(equip_bait)
	ui.set_message("Porto Manso: escolha o dia no mapa, passe nas lojas e vá pescar.")
	_check_bait_rescue()
	if autopilot != null:
		_run_autopilot.call_deferred()


func _build_world() -> void:
	var cfg: Dictionary = _pres.section("hub")
	lighting = DayLighting.new()
	add_child(lighting)
	lighting.setup(_pres, _db.economy["day_phases"])
	lighting.apply(lighting.phase_time(cfg["light_phase"]))
	var lake: Node3D = LakeWorld.add_lake(self)
	water = LakeWorld.add_water(self, _pres)
	birds = LakeWorld.add_birds(self, _pres)
	water.set_sky_color(lighting.horizon_color())
	var berth := LakeWorld.locator(lake, "LOC_dock_berth")
	var dock := Vector3(berth.x, 0.0, berth.z)
	boat = BoatController.new()
	add_child(boat)
	boat.set_model(load(LakeWorld.BOAT_SCENE))
	boat.setup(_pres.section("navigation"), 1.0, _pres.number("lake", "boat_limit_radius_m"))
	boat.water = water
	boat_model = boat.model
	BoatLooks.apply(boat_model, _state, _db)
	boat.position = dock
	var to_center := (-dock).normalized()
	boat.rotation.y = atan2(to_center.x, to_center.z)
	characters = LakeWorld.add_villagers(lake).merged(LakeWorld.add_crew(boat))
	# Câmera do lado do lago, olhando o barco no cais e a vila ao fundo.
	var side := to_center.cross(Vector3.UP).normalized()
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = float(cfg["fov_deg"])
	camera.position = (
		dock
		+ to_center * float(cfg["camera_distance_m"])
		+ side * float(cfg["camera_side_m"])
		+ Vector3.UP * float(cfg["camera_height_m"])
	)
	# Olha um pouco para dentro da vila: o barco no cais e as lojas com os moradores.
	var look := dock - to_center * float(cfg["look_inland_m"])
	camera.look_at(look + Vector3.UP * float(cfg["look_height_m"]), Vector3.UP)
	camera.h_offset = float(cfg["camera_h_offset_m"])
	camera.make_current()


func _process(delta: float) -> void:
	water.advance(delta)
	birds.advance(delta)
	for puppet: CharacterPuppet in characters.values():
		puppet.advance(delta)
	boat.step(delta)


# --- Pedidos da interface (também usados pelo piloto automático) ---


func buy_upgrade(upgrade_id: String) -> Shop.Status:
	var status: Shop.Status = _shop.buy_upgrade(_state, upgrade_id)
	if status == Shop.Status.OK:
		(characters["zeca"] as CharacterPuppet).play("wave")
	var upgrade_name: String = _db.upgrade(upgrade_id)["name"]
	var level_name: String = _db.upgrade_level(upgrade_id, _state.level_of(upgrade_id))["name"]
	_after_purchase(status, "Tio Zeca instalou: %s (%s)." % [upgrade_name, level_name])
	return status


func buy_rod(rod_id: String) -> Shop.Status:
	var status: Shop.Status = _shop.buy_rod(_state, rod_id)
	if status == Shop.Status.OK:
		(characters["maro"] as CharacterPuppet).play("wave")
	if status == Shop.Status.OK:
		_shop.equip_rod(_state, rod_id)
	_after_purchase(status, "Vara nova equipada: %s." % _db.rod(rod_id)["name"])
	return status


func equip_rod(rod_id: String) -> Shop.Status:
	var status: Shop.Status = _shop.equip_rod(_state, rod_id)
	_after_purchase(status, "Vara equipada: %s." % _db.rod(rod_id)["name"])
	return status


func buy_bait(bait_id: String) -> Shop.Status:
	var status: Shop.Status = _shop.buy_bait_lot(_state, bait_id)
	if status == Shop.Status.OK:
		(characters["maro"] as CharacterPuppet).play("wave")
	var bait_name: String = _db.bait(bait_id)["name"]
	_after_purchase(
		status, "Lote de %s comprado (%d no estoque)." % [bait_name, _state.bait_count(bait_id)]
	)
	return status


func equip_bait(bait_id: String) -> Shop.Status:
	var status: Shop.Status = _shop.equip_bait(_state, bait_id)
	_after_purchase(status, "Isca equipada: %s." % _db.bait(bait_id)["name"])
	return status


## Antes de sair para pescar: isca equipada com estoque, ou a isca de socorro (P-22).
func request_play() -> void:
	if not _shop.ensure_bait_equipped(_state):
		_check_bait_rescue()
	if not _shop.ensure_bait_equipped(_state):
		ui.set_message("Sem isca! Compre um lote no Armazém da Marô antes de sair.")
		ui.tabs.current_tab = HubUi.TAB_STORE
		return
	state_changed.emit()
	play_requested.emit(selected_day)


func _on_day_selected(day_number: int) -> void:
	selected_day = day_number
	ui.refresh()


func _after_purchase(status: Shop.Status, success_message: String) -> void:
	if status == Shop.Status.OK:
		ui.set_message(success_message)
		BoatLooks.apply(boat_model, _state, _db)
		state_changed.emit()
	else:
		ui.set_message(SHOP_MESSAGES.get(status, "Não deu para comprar."))
	ui.refresh()


func _check_bait_rescue() -> void:
	if _shop.rescue_bait(_state):
		ui.set_message(
			(
				"Dona Marô viu que você estava sem isca e sem moedas e deu um lote de %s."
				% _db.bait(_state.equipped_bait)["name"]
			)
		)
		ui.refresh()
		state_changed.emit()


func _run_autopilot() -> void:
	autopilot.buy(_state, _state.sessions_played, autopilot_purchases)
	autopilot.prepare_bait(_state, selected_day)
	BoatLooks.apply(boat_model, _state, _db)
	ui.refresh()
	request_play()
