extends GdUnitTestSuite
## Porto Manso do lago inteiro (Fase 6, etapa 5): mapa dos 29 dias com a região e
## o que falta para liberar cada um, peças extras e iscas artificiais na loja e o
## álbum com as fichas (P-28).

var db: ContentDB
var mvp: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.full_db()
	mvp = TestContent.db()
	pres = PresentationConfig.load_default()


func _hub(state: PlayerState, source: ContentDB = null) -> HubController:
	var hub := HubController.new()
	hub.setup(source if source != null else db, state, pres, 1)
	add_child(hub)
	return auto_free(hub)


func _rich(source: ContentDB = null) -> PlayerState:
	var state := PlayerState.new_game(source if source != null else db)
	state.coins = 100000
	return state


func _press(hub: HubController, button_name: String) -> void:
	var button := hub.ui.find_button(button_name)
	assert_object(button).is_not_null()
	assert_bool(button.disabled).is_false()
	button.pressed.emit()


func _label_text(node: Node) -> String:
	var parts := PackedStringArray()
	for label in node.find_children("*", "Label", true, false):
		parts.append((label as Label).text)
	return "\n".join(parts)


# --- Mapa dos dias ---


func test_map_lists_29_days_with_their_regions() -> void:
	var hub := _hub(_rich())
	for day_number: int in [1, 9, 16, 23, 24, 29]:
		assert_object(hub.ui.find_button("Day_%d" % day_number)).is_not_null()
	assert_str(hub.ui.find_button("Day_9").text).contains("Remanso")
	assert_str(hub.ui.find_button("Day_24").text).contains("Poço Fundo")
	assert_object(hub.ui.find_button("Day_30")).is_null()


func test_locked_day_says_what_is_missing() -> void:
	var state := _rich()
	for day in range(1, 9):
		state.best_stars[str(day)] = 1
	var hub := _hub(state)
	var day_9 := hub.ui.find_button("Day_9")
	assert_bool(day_9.disabled).is_true()
	var need := hub.ui.find_child("Missing_9", true, false) as Label
	assert_str(need.text).contains("falta: barco nível 2")
	assert_str(hub.ui.find_button("Day_10").text).contains("bloqueado")
	assert_object(hub.ui.find_child("Missing_10", true, false)).is_null()
	for upgrade_id in db.upgrade_ids():
		state.upgrade_levels[upgrade_id] = 2
	hub.ui.refresh()
	assert_bool(hub.ui.find_button("Day_9").disabled).is_false()


func test_missing_text_names_the_upgrades() -> void:
	var hub := _hub(_rich())
	var missing: Array[Dictionary] = [
		{"type": "upgrade", "id": "hull", "level": 3},
		{"type": "upgrade", "id": "lights", "level": 2}
	]
	assert_str(hub.ui.missing_text(missing)).is_equal("falta: casco 3, farol 2")


# --- Loja ---


func test_workshop_goes_up_to_level_five() -> void:
	var state := _rich()
	var hub := _hub(state)
	for i in 4:
		_press(hub, "Upgrade_hull")
	assert_int(state.level_of("hull")).is_equal(5)
	assert_str(hub.ui.find_button("Upgrade_hull").text).is_equal("Nível máximo")


func test_parts_are_bought_mounted_and_removed() -> void:
	var state := _rich()
	var hub := _hub(state)
	_press(hub, "Part_braided_line")
	assert_array(state.parts_on(state.equipped_rod)).is_equal(["braided_line"])
	assert_str(hub.ui.find_button("Part_braided_line").text).is_equal("Tirar da vara")
	_press(hub, "Part_braided_line")
	assert_array(state.parts_on(state.equipped_rod)).is_empty()
	assert_str(hub.ui.find_button("Part_braided_line").text).is_equal("Montar na vara")
	_press(hub, "Part_braided_line")
	assert_array(state.parts_on(state.equipped_rod)).is_equal(["braided_line"])
	assert_str(hub.ui.find_button("Rod_bamboo_grandpa").get_parent().get_child(0).text).contains(
		"Linha trançada"
	)


func test_third_part_waits_for_a_free_slot() -> void:
	var state := _rich()
	var hub := _hub(state)
	for part_id: String in ["better_reel", "braided_line", "sharp_hook"]:
		_press(hub, "Part_%s" % part_id)
	assert_bool(hub.ui.find_button("Part_sharp_hook").disabled).is_true()


func test_artificial_bait_levels_up_and_can_be_equipped() -> void:
	var state := _rich()
	var hub := _hub(state)
	assert_bool(hub.ui.find_button("EquipBait_jig_spoon").disabled).is_true()
	_press(hub, "Lure_jig_spoon")
	assert_int(state.artificial_level("jig_spoon")).is_equal(1)
	assert_str(hub.ui.find_button("Lure_jig_spoon").text).starts_with("Nível 2")
	_press(hub, "EquipBait_jig_spoon")
	assert_str(state.equipped_bait).is_equal("jig_spoon")
	_press(hub, "Lure_jig_spoon")
	_press(hub, "Lure_jig_spoon")
	assert_str(hub.ui.find_button("Lure_jig_spoon").text).is_equal("Nível máximo")


func test_mvp_store_has_no_parts_nor_artificial_baits() -> void:
	var hub := _hub(_rich(mvp), mvp)
	assert_object(hub.ui.find_button("Part_braided_line")).is_null()
	assert_object(hub.ui.find_button("Lure_jig_spoon")).is_null()


# --- Álbum ---


func test_album_has_a_card_for_each_species() -> void:
	var hub := _hub(_rich())
	var panel: AlbumPanel = hub.ui.album_panel
	for species_id in db.species_ids():
		assert_object(panel.find_child("Card_%s" % species_id, true, false)).is_not_null()
	assert_str(panel.summary_label.text).contains("espécies: 0 de 17")


func test_caught_species_shows_its_card() -> void:
	var state := _rich()
	state.register_in_album(FishCatch.new("pacu", 4.2, "golden"))
	var hub := _hub(state)
	var card := hub.ui.album_panel.find_child("Card_pacu", true, false)
	var text := _label_text(card)
	assert_str(text).contains("Pacu")
	assert_str(text).contains("Piaractus mesopotamicus")
	assert_str(text).contains(String(db.species("pacu")["card"]["curiosity"]))
	assert_str(text).contains("dourada: sim")
	assert_str(text).contains("albina: não")
	assert_str(hub.ui.album_panel.summary_label.text).contains("espécies: 1 de 17")


func test_uncaught_species_hides_its_name_and_hints_where_to_look() -> void:
	var hub := _hub(_rich())
	var text := _label_text(hub.ui.album_panel.find_child("Card_dourado", true, false))
	assert_str(text).contains("???")
	assert_str(text).not_contains("Dourado —")
	assert_str(text).contains("Águas Fundas")
	var king := _label_text(hub.ui.album_panel.find_child("Card_king_of_the_lake", true, false))
	assert_str(king).contains("Ainda não aparece nesta versão")


func test_introduced_species_are_flagged_in_the_card() -> void:
	var state := _rich()
	state.register_in_album(FishCatch.new("nile_tilapia", 1.0))
	var hub := _hub(state)
	var text := _label_text(hub.ui.album_panel.find_child("Card_nile_tilapia", true, false))
	assert_str(text).contains("espécie introduzida no Brasil")


func test_mvp_album_points_the_uncommon_fish_to_margem_rasa() -> void:
	var hub := _hub(_rich(mvp), mvp)
	var text := _label_text(hub.ui.album_panel.find_child("Card_traira", true, false))
	assert_str(text).contains("Margem Rasa")
