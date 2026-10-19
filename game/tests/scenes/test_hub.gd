extends GdUnitTestSuite
## Porto Manso (hub): mundo 3D, mapa dos dias, lojas do Tio Zeca e da Dona Marô
## pelos botões da interface, isca de socorro e piloto automático.

var db: ContentDB
var pres: PresentationConfig
var played: Array[int] = []
var changes: int = 0


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func before_test() -> void:
	played = []
	changes = 0


func _hub(state: PlayerState, day_number: int = 1, plan: ShoppingPlan = null) -> HubController:
	var hub := HubController.new()
	hub.setup(db, state, pres, day_number)
	hub.autopilot = plan
	hub.play_requested.connect(_on_play)
	hub.state_changed.connect(_on_change)
	add_child(hub)
	return auto_free(hub)


func _on_play(day_number: int) -> void:
	played.append(day_number)


func _on_change() -> void:
	changes += 1


func _press(hub: HubController, button_name: String) -> void:
	var button := hub.ui.find_button(button_name)
	assert_object(button).is_not_null()
	assert_bool(button.disabled).is_false()
	button.pressed.emit()


func test_builds_porto_manso_with_boat_at_the_dock() -> void:
	var hub := _hub(PlayerState.new_game(db))
	assert_object(hub.find_child("SM_terrain", true, false)).is_not_null()
	assert_object(hub.find_child("SM_water_surface", true, false)).is_not_null()
	assert_object(hub.boat_model).is_not_null()
	assert_bool(hub.camera.current).is_true()
	# O barco aparece na tela, à esquerda do centro (o painel das lojas fica à direita).
	assert_bool(hub.camera.is_position_in_frustum(hub.boat_model.global_position)).is_true()
	var on_screen := hub.camera.unproject_position(hub.boat_model.global_position)
	assert_float(on_screen.x).is_less(hub.get_viewport().get_visible_rect().size.x * 0.5)


func test_day_map_shows_stars_and_locks() -> void:
	var state := PlayerState.new_game(db)
	state.best_stars = {"1": 3, "2": 1}
	var hub := _hub(state, 3)
	assert_int(hub.ui.stars_shown(1)).is_equal(3)
	assert_int(hub.ui.stars_shown(2)).is_equal(1)
	assert_int(hub.ui.stars_shown(3)).is_equal(0)
	assert_int(hub.ui.stars_shown(4)).is_equal(-1)
	assert_bool(hub.ui.find_button("Day_3").disabled).is_false()
	assert_bool(hub.ui.find_button("Day_4").disabled).is_true()
	assert_str(hub.ui.find_button("Day_4").text).contains("bloqueado")
	assert_str(hub.ui.goal_label.text).contains("Dia 3")
	assert_str(hub.ui.play_button.text).contains("dia 3")


func test_cannot_start_on_a_locked_day() -> void:
	var hub := _hub(PlayerState.new_game(db), 7)
	assert_int(hub.selected_day).is_equal(1)


func test_replay_an_earlier_day_from_the_map() -> void:
	var state := PlayerState.new_game(db)
	state.best_stars = {"1": 1, "2": 1}
	var hub := _hub(state, 3)
	_press(hub, "Day_1")
	_press(hub, "PlayButton")
	assert_array(played).is_equal([1])


func test_tio_zeca_sells_motor_upgrade_through_the_button() -> void:
	var state := PlayerState.new_game(db)
	state.coins = 1000
	var hub := _hub(state)
	_press(hub, "Upgrade_motor")
	assert_int(state.level_of("motor")).is_equal(2)
	assert_int(state.coins).is_equal(100)
	assert_int(changes).is_equal(1)
	assert_str(hub.ui.message_label.text).contains("Tio Zeca")
	# Sem moedas para o próximo nível, o botão fica desligado.
	assert_bool(hub.ui.find_button("Upgrade_motor").disabled).is_true()
	assert_int(hub.buy_upgrade("motor")).is_equal(Shop.Status.NOT_ENOUGH_COINS)
	assert_str(hub.ui.message_label.text).contains("insuficientes")


func test_workshop_shows_only_mvp_upgrades_and_max_level() -> void:
	var state := PlayerState.new_game(db)
	state.upgrade_levels["sonar"] = 3
	var hub := _hub(state)
	assert_object(hub.ui.find_button("Upgrade_hull")).is_null()
	assert_str(hub.ui.find_button("Upgrade_sonar").text).is_equal("Nível máximo")


func test_dona_maro_sells_and_equips_rods_and_baits() -> void:
	var state := PlayerState.new_game(db)
	state.coins = 800
	var hub := _hub(state)
	_press(hub, "Rod_fiberglass")
	assert_bool(state.owned_rods.has("fiberglass")).is_true()
	assert_str(state.equipped_rod).is_equal("fiberglass")
	_press(hub, "Rod_bamboo_grandpa")
	assert_str(state.equipped_rod).is_equal("bamboo_grandpa")
	_press(hub, "Bait_corn_dough")
	assert_int(state.bait_count("corn_dough")).is_equal(db.lot_size())
	assert_int(state.coins).is_equal(800 - 700 - 80)
	_press(hub, "EquipBait_corn_dough")
	assert_str(state.equipped_bait).is_equal("corn_dough")
	assert_int(changes).is_equal(4)


func test_bait_rescue_when_arriving_broke_without_bait() -> void:
	var state := PlayerState.new_game(db)
	state.bait_inventory = {}
	var hub := _hub(state)
	assert_int(state.bait_count("worm")).is_equal(db.lot_size())
	assert_str(hub.ui.message_label.text).contains("Dona Marô")
	assert_int(changes).is_equal(1)


func test_play_switches_to_a_bait_in_stock() -> void:
	var state := PlayerState.new_game(db)
	state.bait_inventory = {"worm": 0, "corn_dough": 3}
	var hub := _hub(state)
	_press(hub, "PlayButton")
	assert_str(state.equipped_bait).is_equal("corn_dough")
	assert_array(played).is_equal([1])


func test_play_is_refused_without_bait_but_with_coins() -> void:
	var state := PlayerState.new_game(db)
	state.bait_inventory = {}
	state.coins = 60
	var hub := _hub(state)
	_press(hub, "PlayButton")
	assert_array(played).is_empty()
	assert_str(hub.ui.message_label.text).contains("Sem isca")
	assert_int(hub.ui.tabs.current_tab).is_equal(HubUi.TAB_STORE)


func test_autopilot_buys_from_plan_and_goes_fishing() -> void:
	var state := PlayerState.new_game(db)
	state.coins = 1000
	var hub := _hub(state, 1, ShoppingPlan.for_release(db))
	await get_tree().process_frame
	assert_str(state.equipped_rod).is_equal("fiberglass")
	assert_int(hub.autopilot_purchases.size()).is_equal(1)
	assert_array(played).is_equal([1])
