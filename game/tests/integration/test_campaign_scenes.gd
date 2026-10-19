extends GdUnitTestSuite
## Critério da Fase 5: "os 10 dias completáveis com 1 a 3 estrelas", provado nas
## cenas de verdade. O piloto automático joga a campanha inteira pelo jogo
## (Porto Manso → compras → dia de pesca → venda → Porto Manso), repetindo o dia
## que ficar sem estrela, como um jogador faria.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const TEST_ROOT: String = "user://test_campaign_saves"
const STEP_S: float = 0.05
const MAX_STEPS_PER_DAY: int = 20000
const MAX_SESSIONS: int = 30

var save_dir: String


func before_test() -> void:
	save_dir = "%s/%d" % [TEST_ROOT, Time.get_ticks_usec()]


func after_test() -> void:
	SaveService.new(save_dir).erase()
	DirAccess.remove_absolute(save_dir)


func after() -> void:
	DirAccess.remove_absolute(TEST_ROOT)


func test_all_ten_days_are_completable_through_the_game() -> void:
	var game: Node = (load(MAIN_SCENE) as PackedScene).instantiate()
	game.set("options", {"autoplay": "true", "save-dir": save_dir, "days": "999", "seed": "2026"})
	add_child(auto_free(game))
	var db := TestContent.db()
	var best: Dictionary = {}
	var previous: DayController = null
	var sessions := 0
	while best.size() < db.day_count() and sessions < MAX_SESSIONS:
		var frames := 0
		while (game.get("current") == null or game.get("current") == previous) and frames < 20:
			await get_tree().process_frame
			frames += 1
		var day := game.get("current") as DayController
		assert_object(day).is_not_null()
		day.external_stepping = true
		var steps := 0
		while not day.is_finished() and steps < MAX_STEPS_PER_DAY:
			day.step(STEP_S)
			steps += 1
		assert_bool(day.is_finished()).is_true()
		var result: Dictionary = day.session.result
		var day_number := int(result["day"])
		best[day_number] = maxi(int(best.get(day_number, 0)), int(result["stars"]))
		if int(best[day_number]) == 0:
			best.erase(day_number)
		previous = day
		sessions += 1
	for day_number in range(1, db.day_count() + 1):
		(
			assert_bool(best.has(day_number))
			. override_failure_message(
				"dia %d sem estrela depois de %d sessões" % [day_number, sessions]
			)
			. is_true()
		)
		assert_int(int(best.get(day_number, 0))).is_between(1, 3)
	# O progresso ficou salvo: o arquivo tem as estrelas dos 10 dias.
	var saved := SaveService.new(save_dir).load_state()
	for day_number in range(1, db.day_count() + 1):
		assert_int(saved.stars_of(day_number)).is_between(1, 3)
	print("CAMPANHA_CENAS sessões=%d estrelas=%s" % [sessions, str(best)])
