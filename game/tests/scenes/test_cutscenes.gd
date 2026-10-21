extends GdUnitTestSuite
## Cutscenes na cena (Fase 7, Bloco B, item 2; P-40): gestos e andar dos
## personagens, os passos (falar, andar até, gesto, câmera, esperar, cartela), o
## pular (segurando a tecla ou no botão) e a cutscene do dia 1 no palco.

const STEP_S: float = 1.0 / 60.0

var db: ContentDB
var story: StoryContent
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	story = ContentLoader.load_story()
	pres = PresentationConfig.load_default()


func after_test() -> void:
	InputSetup.reset_bindings()


func _puppet(id: String) -> CharacterPuppet:
	var puppet := CharacterPuppet.create(id)
	add_child(auto_free(puppet))
	return puppet


func _advance(puppet: CharacterPuppet, seconds: float) -> void:
	for i in int(seconds / STEP_S):
		puppet.advance(STEP_S)


## Avô, avó e Bolota na origem, olhando para +Z, e uma câmera atrás.
func _player(steps: Array, chars_per_s: float = 0.0) -> CutscenePlayer:
	var root := Node3D.new()
	add_child(auto_free(root))
	var cast: Dictionary = {}
	var spots: Dictionary = {"grandpa": -1.0, "grandma": 1.0, "bolota": 3.0}
	for id: String in spots:
		var puppet := CharacterPuppet.create(story.model_of(id))
		root.add_child(puppet)
		puppet.position = Vector3(float(spots[id]), 0.0, 0.0)
		cast[id] = puppet
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0.0, 1.6, 6.0)
	camera.make_current()
	var sfx := SfxPlayer.new()
	root.add_child(sfx)
	var player := CutscenePlayer.new()
	player.setup(
		story,
		{"id": "test", "steps": steps},
		cast,
		camera,
		Transform3D.IDENTITY,
		sfx,
		pres,
		chars_per_s
	)
	player.external_stepping = true
	root.add_child(player)
	return player


func _run(player: CutscenePlayer, seconds: float) -> void:
	for i in int(seconds / STEP_S):
		player.step(STEP_S)
		for puppet: CharacterPuppet in player.cast.values():
			puppet.advance(STEP_S)


func test_gestures_move_the_body() -> void:
	var grandpa := _puppet("zeca")
	grandpa.pose = "point"
	_advance(grandpa, 1.0)
	assert_float(grandpa.arm_right.rotation.x).is_less(-1.2)
	grandpa.pose = "cross_arms"
	_advance(grandpa, 1.0)
	assert_float(grandpa.arm_left.rotation.z).is_less(-0.3)
	assert_float(grandpa.arm_right.rotation.z).is_greater(0.3)
	var dog := _puppet("bolota")
	dog.pose = "sit"
	_advance(dog, 1.0)
	assert_float(dog.model.rotation.x).is_less(-0.25)
	assert_float(dog.legs["back_left"].rotation.x).is_less(-0.7)
	dog.pose = "lie_down"
	_advance(dog, 1.0)
	assert_float(dog.model.position.y).is_less(-0.1)
	dog.pose = ""
	_advance(dog, 1.5)
	assert_float(absf(dog.model.position.y)).is_less(0.02)


func test_looking_around_turns_the_head_both_ways() -> void:
	var dog := _puppet("bolota")
	dog.looking_around = true
	var yaws: Array[float] = []
	for i in 180:
		dog.advance(STEP_S)
		yaws.append(dog.head.rotation.y)
	assert_float(yaws.min()).is_less(-0.4)
	assert_float(yaws.max()).is_greater(0.4)


func test_walking_swings_legs_and_arms() -> void:
	var grandma := _puppet("maro")
	grandma.walk_hz = 2.0
	var swings: Array[float] = []
	for i in 60:
		grandma.advance(STEP_S)
		swings.append(grandma.legs["left"].rotation.x)
	assert_float(swings.max() - swings.min()).is_greater(0.5)
	var dog := _puppet("bolota")
	dog.walk_hz = 3.0
	_advance(dog, 0.4)
	# No cão, as patas vão em diagonal: a da frente esquerda com a de trás direita.
	assert_float(dog.legs["front_left"].rotation.x).is_equal_approx(
		dog.legs["back_right"].rotation.x, 0.001
	)


func test_walk_reaches_the_point_and_turns_to_face() -> void:
	var player := _player([{"type": "walk", "actor": "bolota", "to": [3.0, 4.0], "face_deg": 90}])
	var dog: CharacterPuppet = player.cast["bolota"]
	_run(player, 0.5)
	assert_float(dog.walk_hz).is_greater(0.0)
	assert_float(dog.global_position.z).is_between(0.1, 3.9)
	_run(player, 4.0)
	assert_vector(dog.global_position).is_equal_approx(Vector3(3.0, 0.0, 4.0), Vector3.ONE * 0.01)
	assert_float(dog.walk_hz).is_equal(0.0)
	assert_float(dog.rotation.y).is_equal_approx(PI / 2.0, 0.05)
	assert_bool(player.cutscene.finished).is_true()


func test_run_is_faster_than_walk() -> void:
	var walk := _player([{"type": "walk", "actor": "grandpa", "to": [-1.0, 10.0]}])
	var run := _player([{"type": "walk", "actor": "grandma", "to": [1.0, 10.0], "run": true}])
	_run(walk, 1.0)
	_run(run, 1.0)
	var walked: float = (walk.cast["grandpa"] as CharacterPuppet).global_position.z
	var ran: float = (run.cast["grandma"] as CharacterPuppet).global_position.z
	assert_float(walked).is_equal_approx(float(pres.section("cutscene")["walk_speed_m_s"]), 0.1)
	assert_float(ran).is_greater(walked * 2.0)


func test_gesture_toward_turns_to_the_target_and_ends() -> void:
	var player := _player(
		[
			{
				"type": "gesture",
				"actor": "grandma",
				"gesture": "point",
				"toward": "bolota",
				"seconds": 1.0
			},
			{"type": "gesture", "actor": "bolota", "gesture": "sit", "seconds": 0.5, "hold": true},
			{"type": "gesture", "actor": "bolota", "gesture": "bark", "seconds": 0.5},
		]
	)
	var grandma: CharacterPuppet = player.cast["grandma"]
	_run(player, 0.8)
	assert_str(grandma.pose).is_equal("point")
	assert_object(grandma.look_target).is_not_null()
	# O Bolota está à direita (+X): ela vira para ele.
	assert_float(grandma.rotation.y).is_greater(1.2)
	_run(player, 1.5)
	assert_str(grandma.pose).is_empty()
	assert_object(grandma.look_target).is_null()
	# Sentar fica (hold); o latido toca o som.
	assert_str((player.cast["bolota"] as CharacterPuppet).pose).is_equal("sit")
	assert_bool(player._sfx.played.has("bark")).is_true()


func test_camera_cuts_and_moves_smoothly_following_people() -> void:
	var player := _player(
		[
			{
				"type": "camera",
				"position": [0.0, 2.0, 5.0],
				"look_at": [0.0, 1.0, 0.0],
				"seconds": 0
			},
			{"type": "camera", "position": [4.0, 2.0, 5.0], "look_at": ["grandma"], "seconds": 2.0},
		]
	)
	player.step(STEP_S)
	var camera: Camera3D = player.camera
	assert_vector(camera.global_position).is_equal_approx(
		Vector3(0.0, 2.0, 5.0), Vector3.ONE * 0.01
	)
	_run(player, 1.0)
	assert_float(camera.global_position.x).is_between(0.5, 3.5)
	_run(player, 1.5)
	assert_vector(camera.global_position).is_equal_approx(
		Vector3(4.0, 2.0, 5.0), Vector3.ONE * 0.01
	)
	var grandma: CharacterPuppet = player.cast["grandma"]
	var on_screen: Vector2 = camera.unproject_position(grandma.head_top())
	assert_float(on_screen.x).is_equal_approx(
		camera.get_viewport().get_visible_rect().size.x / 2.0, 2.0
	)


func test_card_darkens_shows_the_text_and_clears() -> void:
	var player := _player(
		[{"type": "card", "text": "Dia 1 — O primeiro dia de pescaria", "seconds": 3.0}]
	)
	player.step(STEP_S)
	assert_bool(player.card.visible).is_true()
	assert_str(player.card_label.text).is_equal("Dia 1 — O primeiro dia de pescaria")
	assert_float(player.card.modulate.a).is_less(0.2)
	_run(player, 1.5)
	assert_float(player.card.modulate.a).is_equal(1.0)
	_run(player, 1.6)
	assert_bool(player.card.visible).is_false()
	assert_bool(player.cutscene.finished).is_true()


func test_talk_waits_for_the_clicks() -> void:
	var player := _player(
		[{"type": "talk", "dialogue": "day1_porch"}, {"type": "wait", "seconds": 0.5}]
	)
	var ended: Array[bool] = []
	player.finished.connect(func() -> void: ended.append(true))
	_run(player, 2.0)
	assert_object(player.dialogue).is_not_null()
	assert_str(player.dialogue.balloon.speaker_name).is_equal("Avô")
	for i in 3:
		player.press()
	_run(player, 0.1)
	assert_object(player.dialogue).is_null()
	_run(player, 0.6)
	assert_array(ended).has_size(1)


func test_holding_skip_puts_everything_at_the_end() -> void:
	var player := _player(
		[
			{"type": "card", "text": "Dia 1", "seconds": 2.0},
			{"type": "walk", "actor": "bolota", "to": [3.0, 6.0], "face_deg": 180},
			{"type": "talk", "dialogue": "day1_porch"},
			{
				"type": "gesture",
				"actor": "bolota",
				"gesture": "lie_down",
				"seconds": 1,
				"hold": true
			},
			{"type": "gesture", "actor": "grandpa", "gesture": "point", "seconds": 1},
			{
				"type": "camera",
				"position": [1.0, 3.0, 7.0],
				"look_at": [0.0, 1.0, 0.0],
				"seconds": 3
			},
		]
	)
	var ended: Array[bool] = []
	player.finished.connect(func() -> void: ended.append(true))
	_run(player, 0.5)
	# Segurar pouco não pula.
	var hold: float = float(pres.section("cutscene")["skip_hold_s"])
	player.hold_skip(hold / 2.0)
	player.hold_skip(0.0)
	assert_bool(player.cutscene.finished).is_false()
	player.hold_skip(hold / 2.0)
	assert_bool(player.cutscene.finished).is_false()
	player.hold_skip(0.0)
	player.hold_skip(hold * 0.6)
	player.hold_skip(hold * 0.6)
	assert_bool(player.cutscene.skipped).is_true()
	assert_array(ended).has_size(1)
	var dog: CharacterPuppet = player.cast["bolota"]
	assert_vector(dog.global_position).is_equal_approx(Vector3(3.0, 0.0, 6.0), Vector3.ONE * 0.01)
	assert_float(dog.rotation.y).is_equal_approx(PI, 0.01)
	assert_str(dog.pose).is_equal("lie_down")
	assert_str((player.cast["grandpa"] as CharacterPuppet).pose).is_empty()
	assert_bool(player.card.visible).is_false()
	assert_vector(player.camera.global_position).is_equal_approx(
		Vector3(1.0, 3.0, 7.0), Vector3.ONE * 0.01
	)
	assert_bool(player.skip_button.visible).is_false()


func test_skip_button_and_key() -> void:
	var player := _player([{"type": "wait", "seconds": 5.0}])
	assert_str(player.skip_button.text).contains("Tab")
	assert_array(Array(InputSetup.REBINDABLE)).contains([InputSetup.SKIP_CUTSCENE])
	assert_int(InputSetup.primary_key(InputSetup.SKIP_CUTSCENE)).is_equal(KEY_TAB)
	player.step(STEP_S)
	player.skip_button.pressed.emit()
	assert_bool(player.cutscene.skipped).is_true()


func test_day_one_opening_plays_on_the_stage() -> void:
	var stage := StoryStage.new()
	stage.setup(story, StoryStage.for_cutscenes(story, "day1_opening"), pres, db, 0.0)
	stage.external_stepping = true
	add_child(auto_free(stage))
	var ended: Array[bool] = []
	stage.stage_finished.connect(func() -> void: ended.append(true))
	# O Bolota da cutscene sai do barco: o do barco some.
	assert_bool((stage.crew["bolota"] as CharacterPuppet).visible).is_false()
	assert_bool(stage.cast["bolota"] != stage.crew["bolota"]).is_true()
	assert_object(stage.cast.get("tom")).is_not_null()
	var kinds: Dictionary = {}
	stage.current.step_started.connect(func(_i: int, kind: String) -> void: kinds[kind] = true)
	var player: CutscenePlayer = stage.current
	for i in int(90.0 / STEP_S):
		stage.step(STEP_S)
		if player.dialogue != null:
			player.press()
		if stage.current == null:
			break
	assert_object(stage.current).is_null()
	assert_array(kinds.keys()).contains(["card", "camera", "walk", "gesture", "talk", "wait"])
	# Quem anda segue o chão: o Bolota termina deitado perto da altura do terreno.
	var dog: CharacterPuppet = stage.cast["bolota"]
	var ground: float = stage.ground.height_at(
		Vector2(dog.global_position.x, dog.global_position.z)
	)
	assert_float(dog.global_position.y).is_equal_approx(ground, 0.01)
	assert_str(dog.pose).is_equal("lie_down")
	for i in 120:
		stage.step(STEP_S)
	assert_array(ended).has_size(1)
