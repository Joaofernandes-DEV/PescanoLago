extends GdUnitTestSuite
## Diálogos em balões na cena (Fase 7, Bloco B, item 1; P-39): o balão preso à
## cabeça de quem fala, a voz curta a cada poucas letras, a boca e o corpo
## mexendo, quem ouve olhando, o clique avançando, a dica de continuar e o palco
## de prévia (--dialogue).

const STEP_S: float = 1.0 / 60.0

var db: ContentDB
var story: StoryContent
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	story = ContentLoader.load_story()
	pres = PresentationConfig.load_default()


## Avô e avó (os modelos provisórios) lado a lado, com uma câmera olhando os dois.
func _scene() -> Dictionary:
	var root := Node3D.new()
	add_child(auto_free(root))
	var cast: Dictionary = {}
	for i: int in 2:
		var id: String = ["grandpa", "grandma"][i]
		var puppet := CharacterPuppet.create(story.model_of(id))
		puppet.merge_still_parts(true)
		root.add_child(puppet)
		puppet.position = Vector3(-0.8 + 1.6 * i, 0.0, 0.0)
		cast[id] = puppet
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0.0, 1.6, 5.0)
	camera.look_at(Vector3(0.0, 1.3, 0.0))
	camera.make_current()
	var sfx := SfxPlayer.new()
	root.add_child(sfx)
	return {"root": root, "cast": cast, "camera": camera, "sfx": sfx}


func _player(
	scene: Dictionary, dialogue_id: String = "day1_porch", chars_per_s: float = 40.0
) -> DialoguePlayer:
	var player := DialoguePlayer.new()
	player.setup(
		story,
		dialogue_id,
		chars_per_s,
		pres.section("dialogue"),
		scene["cast"],
		scene["camera"],
		scene["sfx"],
		int(pres.number("hints", "show_until_count"))
	)
	player.external_stepping = true
	(scene["root"] as Node).add_child(player)
	return player


func _run(player: DialoguePlayer, cast: Dictionary, seconds: float) -> void:
	for i in int(seconds / STEP_S):
		player.step(STEP_S)
		for puppet: CharacterPuppet in cast.values():
			puppet.advance(STEP_S)


func test_people_have_a_mouth_that_merges_unless_they_talk() -> void:
	for id: String in ["tom", "maro", "zeca"]:
		var still := CharacterPuppet.create(id)
		auto_free(still)
		assert_object(still.mouth).is_not_null()
		var head := still.head as MeshInstance3D
		var surfaces: int = head.mesh.get_surface_count()
		still.merge_still_parts()
		# A boca vai para a malha da cabeça sem superfície nova (sem draw call a mais).
		assert_object(still.mouth).is_null()
		assert_int(head.mesh.get_surface_count()).is_equal(surfaces)
		var talker := CharacterPuppet.create(id)
		auto_free(talker)
		talker.merge_still_parts(true)
		assert_object(talker.mouth).is_not_null()
		assert_bool(talker.legs.is_empty()).is_true()
	assert_object((auto_free(CharacterPuppet.create("bolota")) as CharacterPuppet).mouth).is_null()


func test_talking_opens_the_mouth_and_moves_the_body() -> void:
	var puppet := CharacterPuppet.create("zeca")
	add_child(auto_free(puppet))
	var mouth_heights: Array[float] = []
	var head_tilts: Array[float] = []
	puppet.talking = true
	for i in 60:
		puppet.advance(STEP_S)
		mouth_heights.append(puppet.mouth.scale.y)
		head_tilts.append(puppet.head.rotation.x)
	assert_float(mouth_heights.max()).is_greater(2.0)
	assert_float(head_tilts.max() - head_tilts.min()).is_greater(0.05)
	puppet.talking = false
	for i in 60:
		puppet.advance(STEP_S)
	assert_float(puppet.mouth.scale.y).is_less(1.05)


func test_listener_turns_the_head_to_the_speaker() -> void:
	var puppet := CharacterPuppet.create("maro")
	add_child(auto_free(puppet))
	# À direita do personagem (que olha para +Z): x negativo.
	puppet.look_target = Vector3(-3.0, 1.5, 1.0)
	for i in 90:
		puppet.advance(STEP_S)
	assert_float(puppet.head.rotation.y).is_less(-0.5)


func test_balloon_points_at_the_speaker_head_and_text_types_in() -> void:
	var scene := _scene()
	var player := _player(scene)
	var cast: Dictionary = scene["cast"]
	_run(player, cast, 0.5)
	var balloon := player.balloon
	assert_bool(balloon.visible).is_true()
	assert_str(balloon.speaker_name).is_equal("Avô")
	assert_int(balloon.revealed).is_between(15, 25)
	assert_bool(balloon.complete).is_false()
	var head: Vector2 = (scene["camera"] as Camera3D).unproject_position(
		(cast["grandpa"] as CharacterPuppet).head_top()
	)
	assert_float(absf(balloon.tail_tip.x - head.x)).is_less(1.0)
	assert_float(balloon.tail_tip.y).is_less(head.y)
	assert_float(balloon.box.end.y).is_less(balloon.tail_tip.y)
	# Fala falando: a boca mexe; quem ouve olha para quem fala.
	assert_bool((cast["grandpa"] as CharacterPuppet).talking).is_true()
	assert_bool((cast["grandma"] as CharacterPuppet).talking).is_false()
	assert_object((cast["grandma"] as CharacterPuppet).look_target).is_not_null()
	assert_object((cast["grandpa"] as CharacterPuppet).look_target).is_null()


func test_voice_plays_a_syllable_every_few_letters() -> void:
	var scene := _scene()
	var player := _player(scene)
	var sfx: SfxPlayer = scene["sfx"]
	_run(player, scene["cast"], 4.0)
	var line: String = String(story.dialogue("day1_porch")["lines"][0]["text"])
	var every: int = int(pres.section("dialogue")["voice_every_letters"])
	var syllables: int = sfx.played.count("voice_grandpa")
	# Uma no começo da fala e uma a cada voice_every_letters letras.
	assert_int(syllables).is_between(
		Dialogue.letter_count(line) / every - 1, Dialogue.letter_count(line) / every + 2
	)
	assert_bool(sfx.played.has("voice_grandma")).is_false()


func test_clicks_go_through_the_whole_conversation() -> void:
	var scene := _scene()
	var player := _player(scene)
	var lines: Array[String] = []
	player.line_started.connect(func(_i: int, speaker: String) -> void: lines.append(speaker))
	var ended: Array[bool] = []
	player.finished.connect(func() -> void: ended.append(true))
	_run(player, scene["cast"], 0.2)
	assert_int(player.press()).is_equal(Dialogue.Press.COMPLETED_LINE)
	assert_bool(player.balloon.complete).is_true()
	assert_bool((scene["cast"]["grandpa"] as CharacterPuppet).talking).is_false()
	assert_int(player.press()).is_equal(Dialogue.Press.NEXT_LINE)
	assert_str(player.balloon.speaker_name).is_equal("Avó")
	player.press()
	player.press()
	player.press()
	assert_int(player.press()).is_equal(Dialogue.Press.FINISHED)
	# A primeira fala começou ao entrar na cena, antes de ligar o sinal.
	assert_array(lines).contains_exactly(["grandma", "grandpa"])
	assert_array(ended).has_size(1)
	assert_bool(player.balloon.visible).is_false()
	for puppet: CharacterPuppet in (scene["cast"] as Dictionary).values():
		assert_bool(puppet.talking).is_false()
		assert_object(puppet.look_target).is_null()


func test_shout_balloon_and_shouting_pose() -> void:
	var scene := _scene()
	var player := _player(scene, "day1_first_mission")
	player.press()
	player.press()
	_run(player, scene["cast"], 0.3)
	assert_str(player.balloon.style).is_equal("shout")
	assert_bool((scene["cast"]["grandma"] as CharacterPuppet).shouting).is_true()


func test_continue_hint_counts_clicks_and_goes_away() -> void:
	var scene := _scene()
	var player := DialoguePlayer.new()
	var state := PlayerState.new_game(db)
	player.state = state
	player.setup(
		story,
		"day1_porch",
		0.0,
		pres.section("dialogue"),
		scene["cast"],
		scene["camera"],
		scene["sfx"],
		2
	)
	player.external_stepping = true
	(scene["root"] as Node).add_child(player)
	assert_str(player.hint.current_id).is_equal(DialoguePlayer.HINT_ID)
	assert_str(player.hint.text()).contains("continuar")
	player.press()
	assert_str(player.hint.current_id).is_equal(DialoguePlayer.HINT_ID)
	player.press()
	assert_int(state.tip_count(DialoguePlayer.HINT_ID)).is_equal(2)
	assert_str(player.hint.current_id).is_empty()


func test_skip_ends_the_conversation() -> void:
	var scene := _scene()
	var player := _player(scene)
	var ended: Array[bool] = []
	player.finished.connect(func() -> void: ended.append(true))
	player.skip()
	player.skip()
	assert_array(ended).has_size(1)
	assert_bool(player.dialogue.finished).is_true()


func test_balloon_wraps_and_stays_on_screen() -> void:
	var balloon := SpeechBalloon.new()
	var cfg: Dictionary = pres.section("dialogue")["balloon"]
	balloon.setup(cfg)
	add_child(auto_free(balloon))
	var font: Font = balloon.get_theme_default_font()
	var text: String = String(story.dialogue("day1_porch")["lines"][1]["text"])
	var width: float = float(cfg["max_width_px"]) - float(cfg["padding_px"]) * 2.0
	for line in SpeechBalloon.wrap_text(text, font, int(cfg["font_size"]), width):
		assert_float(font.get_string_size(line, 0, -1, int(cfg["font_size"])).x).is_less_equal(
			width
		)
	balloon.show_line("Avó", text, "whisper")
	balloon.set_revealed(text.length(), true)
	var screen: Vector2 = balloon.get_viewport_rect().size
	# A cabeça saiu da tela pela esquerda e por cima: o balão fica dentro dela.
	balloon.point_at(Vector2(-300.0, -200.0))
	var margin: float = float(cfg["screen_margin_px"])
	assert_float(balloon.box.position.x).is_greater_equal(margin - 0.01)
	assert_float(balloon.box.position.y).is_greater_equal(margin - 0.01)
	assert_float(balloon.box.end.x).is_less_equal(screen.x)
	assert_str(balloon.shown_text()).is_equal(text)
	await get_tree().process_frame


func test_preview_stage_plays_the_dialogue_and_finishes() -> void:
	var stage := StoryStage.new()
	stage.setup(story, StoryStage.for_dialogues(story, "day1_porch", pres), pres, db, 0.0)
	stage.external_stepping = true
	add_child(auto_free(stage))
	var ended: Array[bool] = []
	stage.stage_finished.connect(func() -> void: ended.append(true))
	assert_object(stage.cast.get("grandpa")).is_not_null()
	assert_object(stage.cast.get("grandma")).is_not_null()
	assert_object(stage.cast.get("tom")).is_not_null()
	stage.step(STEP_S)
	# Os dois em pé, perto um do outro, e a câmera vendo as duas cabeças.
	var grandpa: CharacterPuppet = stage.cast["grandpa"]
	var grandma: CharacterPuppet = stage.cast["grandma"]
	assert_float(grandpa.global_position.distance_to(grandma.global_position)).is_less(3.0)
	var screen: Rect2 = stage.get_viewport().get_visible_rect()
	for puppet: CharacterPuppet in [grandpa, grandma]:
		assert_bool(screen.has_point(stage.camera.unproject_position(puppet.head_top()))).is_true()
	assert_str(stage.current.dialogue.balloon.speaker_name).is_equal("Avô")
	for i in 3:
		stage.current.press()
		stage.step(STEP_S)
	assert_object(stage.current).is_null()
	for i in 120:
		stage.step(STEP_S)
	assert_array(ended).has_size(1)
	assert_int(stage.played).is_equal(1)
	assert_array(StoryStage.for_dialogues(story, "all", pres)).has_size(story.dialogue_ids().size())
