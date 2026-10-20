extends GdUnitTestSuite
## Passaguá e caixa de isopor (Fase 7, Bloco A, item 4; P-37), na cena do dia:
## o Tom tira o peixe da água com o passaguá, mostra na mão com a câmera de perto
## e guarda na caixa; a caixa mostra os peixes do viveiro (até um limite leve) e
## esvazia na venda do cais; uma tecla trocável abre a vista de dentro.

const STEP_S: float = 0.05
const FRAME_S: float = 1.0 / 30.0
const MAX_STEPS: int = 20000

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func after_test() -> void:
	InputSetup.reset_bindings()


func _scene(seed_value: int = 13) -> DayController:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, seed_value, pres)
	day.external_stepping = true
	add_child(day)
	day.step(STEP_S)
	return auto_free(day)


## Joga com o piloto automático até o primeiro peixe pego; depois o jogador solta tudo.
func _until_caught(day: DayController) -> void:
	day.autopilot = AutoPilot.new(PlayerBot.new(db.bot_profile("skilled"), Rng.new(13)))
	var steps := 0
	while not day.landing.active and steps < MAX_STEPS:
		day.step(STEP_S)
		steps += 1
	day.autopilot = null
	day.input_action_held = false


func _advance(day: DayController, seconds: float) -> void:
	for i in ceili(seconds / FRAME_S):
		day.step(FRAME_S)


func _fill(day: DayController, count: int) -> void:
	for i in count:
		day.session.livewell.add(FishCatch.new("nile_tilapia", 0.8 + 0.1 * i))


func _press_cooler_key(day: DayController) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = InputSetup.primary_key(InputSetup.COOLER_VIEW) as Key
	key.pressed = true
	day._unhandled_input(key)


func test_net_takes_the_fish_out_and_tom_shows_it_up_close() -> void:
	var day := _scene()
	_until_caught(day)
	var cfg: Dictionary = pres.section("landing")
	var landing := day.landing
	assert_str(landing.phase).is_equal("net")
	assert_bool(landing.net.visible).is_true()
	assert_bool(landing.fish.visible).is_true()
	# Passaguá e peixe custam um draw call cada: uma malha, uma superfície, sem sombra.
	var net_meshes := landing.net.find_children("*", "MeshInstance3D", true, false)
	assert_int(net_meshes.size()).is_equal(1)
	assert_int((net_meshes[0] as MeshInstance3D).mesh.get_surface_count()).is_equal(1)
	assert_int(landing.fish.mesh.get_surface_count()).is_equal(1)
	assert_int(landing.fish.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var caught: FishCatch = day.session.livewell.contents()[-1]
	assert_str(landing.fish_species).is_equal(caught.species_id)
	# Antes do passaguá, o peixe está na água; a linha vai até ele.
	day.step(FRAME_S)
	assert_float(landing.fish.global_position.y).is_less(0.3)
	assert_bool(landing.scooped).is_false()
	_advance(day, float(cfg["net_s"]) * 0.9)
	assert_bool(landing.scooped).is_true()
	assert_int(landing.splashes).is_equal(1)
	assert_float(landing.fish.global_position.distance_to(landing.hoop_center())).is_less(0.3)
	assert_float(landing.fish.global_position.y).is_greater(0.4)
	# Na mão do Tom, com a câmera de perto.
	_advance(day, float(cfg["net_s"]) * 0.1 + float(cfg["hand_s"]) * 0.6)
	var tom: CharacterPuppet = day.characters["tom"]
	assert_str(landing.phase).is_equal("hand")
	assert_str(tom.pose).is_equal("show")
	assert_float(landing.fish.global_position.distance_to(tom.hand_point())).is_less(0.15)
	assert_float(day.camera.close_weight).is_greater(0.6)
	assert_float(day.camera.global_position.distance_to(tom.global_position)).is_less(3.0)


func test_tom_stores_the_fish_in_the_cooler_and_the_lid_opens() -> void:
	var day := _scene()
	_until_caught(day)
	var cfg: Dictionary = pres.section("landing")
	# Enquanto o Tom guarda, a caixa ainda não mostra o peixe.
	assert_int(day.cooler.fish_count).is_equal(day.session.livewell.count() - 1)
	_advance(day, float(cfg["net_s"]) + float(cfg["hand_s"]) + float(cfg["store_s"]) * 0.5)
	assert_str(day.landing.phase).is_equal("store")
	assert_float(day.cooler.lid_open).is_greater(0.9)
	assert_float(day.cooler.lid.rotation.x).is_greater(1.0)
	_advance(day, float(cfg["store_s"]) * 0.6)
	assert_bool(day.landing.active).is_false()
	assert_bool(day.landing.fish.visible).is_false()
	assert_str((day.characters["tom"] as CharacterPuppet).pose).is_equal("")
	# O peixe está deitado na caixa, que fechou.
	assert_int(day.cooler.fish_count).is_equal(1)
	assert_int(day.cooler.shown_count).is_equal(1)
	assert_float(day.cooler.lid_open).is_equal(0.0)
	assert_bool(day.cooler.contents.visible).is_false()
	var drawn: AABB = day.cooler.contents.global_transform * day.cooler.contents.get_aabb()
	assert_bool(drawn.grow(0.02).has_point(day.cooler.slot_point(0))).is_true()
	# A câmera volta para trás do barco.
	_advance(day, 1.0)
	assert_float(day.camera.close_weight).is_equal(0.0)


func test_casting_again_skips_the_animation_without_holding_the_day() -> void:
	var day := _scene()
	_until_caught(day)
	# As regras guardam no tempo do núcleo (store_s); a animação é mais longa.
	var store_s: float = float(db.economy["fishing"]["store_s"])
	_advance(day, store_s + 0.1)
	assert_bool(day.session.can_cast()).is_true()
	assert_bool(day.landing.active).is_true()
	day.input_action_held = true
	day.step(FRAME_S)
	assert_bool(day.landing.active).is_false()
	assert_int(day.cooler.shown_count).is_equal(1)
	assert_float(day.cast_charge).is_greater(0.0)


func test_cooler_shows_the_livewell_up_to_a_light_limit() -> void:
	var day := _scene()
	var limit: int = int(pres.number("landing", "max_visible_fish"))
	var capacity: int = day.session.livewell.capacity
	assert_int(capacity).is_greater(limit)
	_fill(day, capacity)
	day.step(FRAME_S)
	assert_int(day.cooler.fish_count).is_equal(capacity)
	assert_int(day.cooler.shown_count).is_equal(limit)
	# Todos os peixes à mostra numa malha só, de uma superfície e sem sombra.
	var contents := day.cooler.contents
	assert_int(contents.mesh.get_surface_count()).is_equal(1)
	assert_int(contents.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	# Fechada, a caixa não desenha os peixes; aberta, sim.
	assert_bool(contents.visible).is_false()
	day.cooler.set_lid(1.0)
	assert_bool(contents.visible).is_true()
	# Os peixes ficam dentro da caixa (a peça do viveiro do nível atual).
	var box := day.cooler.get_parent() as MeshInstance3D
	assert_str(box.name).is_equal("SM_livewell_l1")
	var bounds: AABB = box.global_transform * box.get_aabb()
	var drawn: AABB = contents.global_transform * contents.get_aabb()
	assert_bool(bounds.grow(0.02).encloses(drawn)).is_true()
	for i in limit:
		assert_bool(bounds.has_point(day.cooler.slot_point(i))).is_true()


func test_cooler_empties_when_selling_at_the_dock() -> void:
	var day := _scene()
	_fill(day, 3)
	day.step(FRAME_S)
	assert_int(day.cooler.shown_count).is_equal(3)
	day.boat.global_position = Vector3(day.dock_point.x, 0.0, day.dock_point.z)
	var steps := 0
	while not day.events_seen.any(func(e: Dictionary) -> bool: return e["type"] == "docked"):
		day.step(STEP_S)
		steps += 1
		assert_int(steps).is_less(200)
	day.step(FRAME_S)
	assert_int(day.session.livewell.count()).is_equal(0)
	assert_int(day.cooler.fish_count).is_equal(0)
	assert_int(day.cooler.shown_count).is_equal(0)
	assert_int(day.cooler.contents.mesh.get_surface_count()).is_equal(0)


func test_key_opens_the_inside_view_with_name_and_weight() -> void:
	var day := _scene()
	day.session.livewell.add(FishCatch.new("nile_tilapia", 1.24))
	day.session.livewell.add(FishCatch.new("lambari", 0.08))
	day.session.livewell.add(FishCatch.new("traira", 2.3, "albino"))
	_press_cooler_key(day)
	assert_bool(day.cooler_view_open).is_true()
	var panel := day.hud.cooler_panel
	assert_bool(panel.visible).is_true()
	assert_str(panel.title_label.text).contains("3 de %d" % day.session.livewell.capacity)
	# Do mais recente ao mais antigo, com o nome e o peso.
	var names: Array[String] = [
		"%s albino - 2.3 kg" % db.species("traira")["common_name"],
		"%s - 80 g" % db.species("lambari")["common_name"],
		"%s - 1.2 kg" % db.species("nile_tilapia")["common_name"],
	]
	assert_array(Array(panel.lines())).is_equal(names)
	assert_str(panel.close_hint.text()).contains("C")
	_advance(day, 1.2)
	assert_float(day.cooler.lid_open).is_equal(1.0)
	assert_int(day.cooler.shown_count).is_equal(3)
	assert_bool(day.cooler.contents.visible).is_true()
	assert_float(day.camera.close_weight).is_greater(0.9)
	assert_float(day.camera.global_position.distance_to(day.cooler.top_point())).is_less(1.5)
	# A mesma tecla fecha; a câmera volta e a tampa fecha.
	_press_cooler_key(day)
	assert_bool(day.cooler_view_open).is_false()
	assert_bool(panel.visible).is_false()
	_advance(day, 1.2)
	assert_float(day.cooler.lid_open).is_equal(0.0)
	assert_float(day.camera.close_weight).is_equal(0.0)


func test_cooler_key_can_be_rebound() -> void:
	assert_array(Array(InputSetup.REBINDABLE)).contains([InputSetup.COOLER_VIEW])
	assert_str(String(InputSetup.ACTION_NAMES[InputSetup.COOLER_VIEW])).is_not_empty()
	assert_int(InputSetup.primary_key(InputSetup.COOLER_VIEW)).is_equal(KEY_C)
	InputSetup.bind_primary(InputSetup.COOLER_VIEW, KEY_V)
	var day := _scene()
	_press_cooler_key(day)
	assert_bool(day.cooler_view_open).is_true()
	assert_str(day.hud.cooler_panel.close_hint.text()).contains("V")
	# A tecla antiga não abre mais.
	_press_cooler_key(day)
	var old := InputEventKey.new()
	old.physical_keycode = KEY_C
	old.pressed = true
	day._unhandled_input(old)
	assert_bool(day.cooler_view_open).is_false()


func test_inside_view_lists_a_full_big_cooler_in_columns() -> void:
	var day := _scene()
	day.session.livewell.capacity = 25
	_fill(day, 25)
	_press_cooler_key(day)
	var panel := day.hud.cooler_panel
	assert_int(panel.lines().size()).is_equal(25)
	assert_int(panel.column_count()).is_equal(2)
	# Cabe na tela, abaixo do mapa.
	await get_tree().process_frame
	var screen: Rect2 = panel.get_viewport_rect()
	assert_bool(screen.encloses(panel.get_global_rect())).is_true()
	assert_bool(panel.get_global_rect().intersects(day.hud.mini_map.get_global_rect())).is_false()


func test_hint_teaches_the_cooler_key_while_storing() -> void:
	var day := _scene()
	_until_caught(day)
	day.step(FRAME_S)
	assert_str(day.hud.hints.current_id).is_equal("cooler_view")
	assert_str(day.hud.hints.text()).contains("C")
	# Quem abre a caixa aprende: a dica conta como as outras.
	_press_cooler_key(day)
	day.step(FRAME_S)
	assert_int(day._state.tip_count("cooler_view")).is_equal(1)
	assert_str(day.hud.hints.current_id).is_equal("")


func test_pressing_action_closes_the_inside_view() -> void:
	var day := _scene()
	_press_cooler_key(day)
	assert_bool(day.cooler_view_open).is_true()
	day.input_action_held = true
	day.step(FRAME_S)
	day.input_action_held = false
	assert_bool(day.cooler_view_open).is_false()
