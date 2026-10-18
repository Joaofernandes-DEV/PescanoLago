extends GdUnitTestSuite
## Áudio da Fase 5: a trilha e o ambiente em loop na cena principal e a pancada
## do casco quando o barco bate.

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func test_soundtrack_loops_in_the_main_scene() -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	game.set("options", {"no-save": "true"})
	add_child(auto_free(game))
	var soundtrack: Soundtrack = game.get("soundtrack")
	assert_object(soundtrack).is_not_null()
	for player: AudioStreamPlayer in [soundtrack.music, soundtrack.ambience]:
		var stream := player.stream as AudioStreamWAV
		assert_object(stream).is_not_null()
		assert_int(stream.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
	assert_float(soundtrack.music.stream.get_length()).is_between(44.0, 47.0)
	# Sem placa de som (headless), nada toca, para não vazar áudio ao fechar.
	assert_bool(soundtrack.silent).is_true()
	assert_bool(soundtrack.music.playing).is_false()


func test_hull_bump_plays_when_the_boat_hits_the_shore() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 1, pres)
	day.external_stepping = true
	add_child(auto_free(day))
	# Aponta o barco para fora do lago e acelera até a margem.
	day.boat.rotation.y = atan2(day.boat.position.x, day.boat.position.z)
	day.input_throttle = 1.0
	var steps := 0
	while not day.sfx.played.has("hull_bump") and steps < 3000:
		day.step(0.05)
		steps += 1
	assert_bool(day.sfx.played.has("hull_bump")).is_true()
	assert_int(day.boat.collisions).is_greater(0)
