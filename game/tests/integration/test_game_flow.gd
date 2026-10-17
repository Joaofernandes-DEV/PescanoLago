extends GdUnitTestSuite
## Fluxo do jogo inteiro, nas cenas de verdade e com save em arquivo (Fase 4):
## Porto Manso → comprar → dia de pesca → vender → próximo dia, e fechar e
## reabrir o jogo mantendo o progresso.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const TEST_ROOT: String = "user://test_flow_saves"
const STEP_S: float = 0.05
const MAX_STEPS: int = 20000

var db: ContentDB
var save_dir: String


func before() -> void:
	db = TestContent.db()


func before_test() -> void:
	save_dir = "%s/%d" % [TEST_ROOT, Time.get_ticks_usec()]


func after_test() -> void:
	SaveService.new(save_dir).erase()
	DirAccess.remove_absolute(save_dir)


func after() -> void:
	DirAccess.remove_absolute(TEST_ROOT)


func _game(options: Dictionary) -> Node:
	var game: Node = (load(MAIN_SCENE) as PackedScene).instantiate()
	game.set("options", options)
	add_child(game)
	return game


func _autoplay_options() -> Dictionary:
	return {"autoplay": "true", "save-dir": save_dir, "days": "99"}


## Espera o próximo dia começar (o hub decide no quadro seguinte) e joga até o fim.
func _play_next_day(game: Node, previous: DayController = null) -> DayController:
	var frames := 0
	while (game.get("current") == null or game.get("current") == previous) and frames < 10:
		await get_tree().process_frame
		frames += 1
	var day := game.get("current") as DayController
	assert_object(day).is_not_same(previous)
	assert_object(day).is_not_null()
	day.external_stepping = true
	var steps := 0
	while not day.is_finished() and steps < MAX_STEPS:
		day.step(STEP_S)
		steps += 1
	assert_bool(day.is_finished()).is_true()
	return day


func test_play_sell_buy_and_go_to_next_day_with_autosave() -> void:
	var start := PlayerState.new_game(db)
	start.coins = 1000
	SaveService.new(save_dir).save(start)
	var game := _game(_autoplay_options())
	# Porto Manso: o piloto compra a vara de fibra (700) antes de sair.
	var first_day: DayController = await _play_next_day(game)
	var result: Dictionary = first_day.session.result
	var state: PlayerState = game.get("state")
	assert_str(state.equipped_rod).is_equal("fiberglass")
	assert_int(int(result["day"])).is_equal(1)
	assert_int(int(result["stars"])).is_greater(0)
	assert_int(int(result["coins_from_sales"])).is_greater(0)
	# O dia salvou sozinho: o arquivo já tem o resultado.
	var saved := SaveService.new(save_dir).load_state()
	assert_int(saved.stars_of(1)).is_equal(int(result["stars"]))
	assert_int(saved.sessions_played).is_equal(1)
	assert_bool(saved.owned_rods.has("fiberglass")).is_true()
	# Volta a Porto Manso e segue para o dia 2.
	var second_day: DayController = await _play_next_day(game, first_day)
	var second: Dictionary = second_day.session.result
	assert_int(int(second["day"])).is_equal(2)
	assert_int(state.sessions_played).is_equal(2)
	game.queue_free()


func test_closing_and_reopening_keeps_progress() -> void:
	# Um dia só: o piloto para no fim do dia, sem voltar ao hub para comprar.
	var first := _game(_autoplay_options().merged({"days": "1"}, true))
	var played: DayController = await _play_next_day(first)
	var result: Dictionary = played.session.result
	var before_close: Dictionary = (first.get("state") as PlayerState).to_dict()
	first.queue_free()
	await get_tree().process_frame
	# Reabre como um jogador (sem piloto), com a mesma pasta de save.
	var reopened := _game({"save-dir": save_dir})
	var state: PlayerState = reopened.get("state")
	assert_dict(state.to_dict()).is_equal(before_close)
	var expected_day: int = 2 if int(result["stars"]) > 0 else 1
	assert_int(int(reopened.get("selected_day"))).is_equal(expected_day)
	reopened.queue_free()


func test_human_flow_uses_the_buttons_and_returns_to_porto_manso() -> void:
	var game := _game({"save-dir": save_dir})
	var hub: HubController = game.get("hub")
	assert_object(hub).is_not_null()
	hub.ui.find_button("PlayButton").pressed.emit()
	var day := game.get("current") as DayController
	assert_object(day).is_not_null()
	day.external_stepping = true
	var steps := 0
	while not day.is_finished() and steps < MAX_STEPS:
		day.step(STEP_S)
		steps += 1
	assert_bool(day.hud.result_panel.visible).is_true()
	assert_str(day.hud.continue_button.text).is_equal("Voltar a Porto Manso")
	day.hud.continue_button.pressed.emit()
	assert_object(game.get("hub")).is_not_null()
	assert_object(game.get("current")).is_null()
	assert_int(SaveService.new(save_dir).load_state().sessions_played).is_equal(1)
	game.queue_free()


func test_no_save_option_never_touches_the_disk() -> void:
	var game := _game({"no-save": "true", "save-dir": save_dir})
	assert_object(game.get("save")).is_null()
	game.call("save_progress")
	assert_bool(SaveService.new(save_dir).has_save()).is_false()
	game.queue_free()
