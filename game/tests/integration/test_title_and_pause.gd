extends GdUnitTestSuite
## Tela inicial e menu de pausa (Fase 7, Bloco A), no jogo inteiro (main.tscn)
## com save em arquivo: Continuar, Novo jogo com confirmação, créditos,
## configurações, Esc no hub e no dia, voltar à tela inicial sem contar o dia.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const TEST_ROOT: String = "user://test_title_saves"

var db: ContentDB
var save_dir: String


func before() -> void:
	db = TestContent.db()


func before_test() -> void:
	save_dir = "%s/%d" % [TEST_ROOT, Time.get_ticks_usec()]


func after_test() -> void:
	get_tree().paused = false
	SaveService.new(save_dir).erase()
	DirAccess.remove_absolute(save_dir)
	InputSetup.reset_bindings()


func after() -> void:
	DirAccess.remove_absolute(TEST_ROOT)


func _game() -> Node:
	var game: Node = (load(MAIN_SCENE) as PackedScene).instantiate()
	game.set("options", {"save-dir": save_dir})
	add_child(game)
	return game


func _saved_state(coins: int) -> void:
	var state := PlayerState.new_game(db)
	state.coins = coins
	state.best_stars["1"] = 2
	SaveService.new(save_dir).save(state)


func _title(game: Node) -> TitleScreen:
	return game.get("title") as TitleScreen


func test_continue_opens_porto_manso_with_the_saved_progress() -> void:
	_saved_state(420)
	var game := _game()
	var title := _title(game)
	assert_str(title.ui.summary_label.text).is_equal("Dia 2 - 420 moedas")
	assert_bool(title.ui.continue_button.disabled).is_false()
	title.ui.continue_button.pressed.emit()
	assert_object(game.get("title")).is_null()
	assert_object(game.get("hub")).is_not_null()
	assert_int((game.get("state") as PlayerState).coins).is_equal(420)
	game.queue_free()


func test_new_game_asks_before_erasing_the_save() -> void:
	_saved_state(420)
	var game := _game()
	var ui := _title(game).ui
	ui.find_button("NewGame").pressed.emit()
	assert_bool(ui.confirm_panel.visible).is_true()
	ui.find_button("ConfirmNo").pressed.emit()
	assert_bool(ui.confirm_panel.visible).is_false()
	assert_bool(SaveService.new(save_dir).has_save()).is_true()
	ui.find_button("NewGame").pressed.emit()
	ui.find_button("ConfirmYes").pressed.emit()
	assert_object(game.get("hub")).is_not_null()
	assert_bool(SaveService.new(save_dir).has_save()).is_false()
	assert_int((game.get("state") as PlayerState).coins).is_equal(PlayerState.new_game(db).coins)
	game.queue_free()


func test_credits_and_settings_open_and_close() -> void:
	var game := _game()
	var ui := _title(game).ui
	ui.find_button("Credits").pressed.emit()
	assert_bool(ui.credits_panel.visible).is_true()
	ui.find_button("CreditsBack").pressed.emit()
	assert_bool(ui.credits_panel.visible).is_false()
	ui.find_button("SettingsButton").pressed.emit()
	assert_bool(ui.settings_panel.visible).is_true()
	var slider := ui.settings_panel.find_control("Volume_effects_volume") as HSlider
	slider.value = 0.5
	var effects := AudioServer.get_bus_index(GameSettings.EFFECTS_BUS)
	assert_float(AudioServer.get_bus_volume_db(effects)).is_equal_approx(linear_to_db(0.5), 0.01)
	ui.settings_panel.find_control("Back").pressed.emit()
	assert_bool(ui.settings_panel.visible).is_false()
	assert_bool(ui.menu.get_parent().visible).is_true()
	game.queue_free()
	AudioServer.set_bus_volume_db(effects, 0.0)


func test_escape_pauses_porto_manso_and_resume_continues() -> void:
	var game := _game()
	_title(game).ui.find_button("NewGame").pressed.emit()
	var pause: PauseMenu = game.get("pause_menu")
	var esc := InputEventAction.new()
	esc.action = InputSetup.PAUSE
	esc.pressed = true
	get_viewport().push_input(esc)
	assert_bool(pause.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	pause.find_button("Resume").pressed.emit()
	assert_bool(pause.visible).is_false()
	assert_bool(get_tree().paused).is_false()
	game.queue_free()


func test_escape_does_nothing_on_the_title() -> void:
	var game := _game()
	var pause: PauseMenu = game.get("pause_menu")
	var esc := InputEventAction.new()
	esc.action = InputSetup.PAUSE
	esc.pressed = true
	get_viewport().push_input(esc)
	assert_bool(pause.visible).is_false()
	game.queue_free()


func test_leaving_a_day_from_the_pause_menu_does_not_count_it() -> void:
	_saved_state(300)
	var game := _game()
	_title(game).ui.continue_button.pressed.emit()
	(game.get("hub") as HubController).request_play()
	var day := game.get("current") as DayController
	assert_object(day).is_not_null()
	var state := game.get("state") as PlayerState
	state.coins += 999
	var pause: PauseMenu = game.get("pause_menu")
	pause.open()
	pause.find_button("ToTitle").pressed.emit()
	assert_bool(pause.confirm_panel.visible).is_true()
	pause.find_button("ConfirmTitleYes").pressed.emit()
	assert_bool(get_tree().paused).is_false()
	assert_object(game.get("current")).is_null()
	assert_object(_title(game)).is_not_null()
	# O progresso volta a ser o do save.
	assert_int((game.get("state") as PlayerState).coins).is_equal(300)
	game.queue_free()


func test_quality_and_hints_settings_reach_the_day() -> void:
	var game := _game()
	_title(game).ui.find_button("NewGame").pressed.emit()
	(game.get("hub") as HubController).request_play()
	var day := game.get("current") as DayController
	var pause: PauseMenu = game.get("pause_menu")
	pause.open()
	var settings: GameSettings = game.get("settings")
	var quality := pause.settings_panel.find_control("Option_quality") as OptionButton
	quality.select(settings.quality_ids().find("low"))
	quality.item_selected.emit(settings.quality_ids().find("low"))
	assert_bool(day.lighting.sun.shadow_enabled).is_false()
	var hints := pause.settings_panel.find_control("Check_show_hints") as CheckBox
	hints.button_pressed = false
	assert_bool(day.show_hints).is_false()
	pause.close()
	day.external_stepping = true
	day.step(0.05)
	assert_str(day.hud.hints.current_id).is_equal("")
	game.queue_free()
	get_tree().root.scaling_3d_scale = 1.0
