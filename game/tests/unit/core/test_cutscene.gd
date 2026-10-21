extends GdUnitTestSuite
## Cutscenes em passos (Fase 7, Bloco B, item 2; P-40): a ordem dos passos, os
## que vão juntos, os que acabam sozinhos e o pular.


func _scene(steps: Array) -> Cutscene:
	return Cutscene.new({"id": "test", "steps": steps})


func test_steps_go_one_after_the_other() -> void:
	var scene := _scene(
		[
			{"type": "wait", "seconds": 1.0},
			{"type": "talk", "dialogue": "x"},
			{"type": "wait", "seconds": 0.5},
		]
	)
	assert_array(scene.advance(0.0)["started"]).contains_exactly([0])
	assert_array(scene.advance(0.6)["started"]).is_empty()
	var changes: Dictionary = scene.advance(0.5)
	assert_array(changes["ended"]).contains_exactly([0])
	assert_array(changes["started"]).contains_exactly([1])
	# Falar não tem tempo: espera a cena avisar.
	assert_array(scene.advance(10.0)["started"]).is_empty()
	scene.complete(1)
	assert_array(scene.advance(0.1)["started"]).contains_exactly([2])
	assert_bool(scene.finished).is_false()
	scene.advance(0.5)
	assert_bool(scene.finished).is_true()


func test_together_starts_the_next_step_at_the_same_time() -> void:
	var scene := _scene(
		[
			{"type": "camera", "seconds": 2.0, "together": true},
			{"type": "walk", "actor": "bolota", "together": true},
			{"type": "gesture", "seconds": 1.0},
			{"type": "wait", "seconds": 1.0},
		]
	)
	assert_array(scene.advance(0.0)["started"]).contains_exactly([0, 1, 2])
	var changes: Dictionary = scene.advance(1.0)
	assert_array(changes["ended"]).contains_exactly([2])
	# O passo 3 começa quando o gesto acaba, sem esperar a câmera nem o andar.
	assert_array(changes["started"]).contains_exactly([3])
	assert_array(scene.running()).contains_exactly([0, 1, 3])
	scene.advance(1.0)
	# A câmera e a espera acabaram; a cutscene espera o andar.
	assert_bool(scene.finished).is_false()
	scene.complete(1)
	assert_bool(scene.finished).is_true()


func test_zero_seconds_step_ends_right_away() -> void:
	var scene := _scene(
		[{"type": "camera", "seconds": 0.0}, {"type": "card", "text": "Dia 1", "seconds": 2.0}]
	)
	var changes: Dictionary = scene.advance(0.0)
	assert_array(changes["started"]).contains_exactly([0, 1])
	assert_array(changes["ended"]).contains_exactly([0])


func test_skip_lists_what_did_not_end() -> void:
	var scene := _scene(
		[
			{"type": "wait", "seconds": 1.0},
			{"type": "walk", "actor": "bolota", "together": true},
			{"type": "talk", "dialogue": "x"},
			{"type": "card", "seconds": 1.0},
		]
	)
	scene.advance(0.0)
	scene.advance(1.0)
	assert_array(scene.running()).contains_exactly([1, 2])
	assert_array(scene.skip()).contains_exactly([1, 2, 3])
	assert_bool(scene.finished).is_true()
	assert_bool(scene.skipped).is_true()
	var after: Dictionary = scene.advance(1.0)
	assert_array(after["started"]).is_empty()
	assert_array(after["ended"]).is_empty()
