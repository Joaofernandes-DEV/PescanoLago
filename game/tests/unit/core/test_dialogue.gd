extends GdUnitTestSuite
## Diálogos em balões (Fase 7, Bloco B, item 1; P-39): o texto aparece aos poucos,
## o clique completa a fala ou passa para a próxima, e o elenco e os roteiros vêm
## de characters.json e dialogues.json.

var story: StoryContent


func before() -> void:
	story = ContentLoader.load_story()


func _talk(chars_per_s: float = 10.0) -> Dialogue:
	var lines: Array = [
		{"speaker": "grandpa", "text": "Uai, sô!"},
		{"speaker": "grandma", "text": "Homem!", "style": "shout"},
	]
	return Dialogue.new({"id": "test", "lines": lines}, chars_per_s)


func test_text_appears_letter_by_letter() -> void:
	var talk := _talk()
	assert_int(talk.revealed_count()).is_equal(0)
	assert_bool(talk.is_typing()).is_true()
	assert_str(talk.advance(0.35)).is_equal("Uai")
	assert_str(talk.revealed_text()).is_equal("Uai")
	assert_str(talk.advance(1.0)).is_equal(", sô!")
	assert_bool(talk.is_line_complete()).is_true()
	assert_bool(talk.is_typing()).is_false()
	# Fala inteira: o tempo não muda mais nada.
	assert_str(talk.advance(1.0)).is_empty()


func test_click_completes_then_goes_to_the_next_line_then_finishes() -> void:
	var talk := _talk()
	talk.advance(0.2)
	assert_int(talk.press()).is_equal(Dialogue.Press.COMPLETED_LINE)
	assert_str(talk.revealed_text()).is_equal("Uai, sô!")
	assert_int(talk.press()).is_equal(Dialogue.Press.NEXT_LINE)
	assert_int(talk.index).is_equal(1)
	assert_str(talk.speaker()).is_equal("grandma")
	assert_str(talk.style()).is_equal("shout")
	assert_int(talk.revealed_count()).is_equal(0)
	talk.press()
	assert_int(talk.press()).is_equal(Dialogue.Press.FINISHED)
	assert_bool(talk.finished).is_true()
	assert_int(talk.press()).is_equal(Dialogue.Press.IGNORED)
	assert_dict(talk.line()).is_empty()


func test_instant_speed_shows_the_whole_line_and_one_click_advances() -> void:
	var talk := _talk(0.0)
	assert_bool(talk.is_line_complete()).is_true()
	assert_str(talk.revealed_text()).is_equal("Uai, sô!")
	assert_int(talk.press()).is_equal(Dialogue.Press.NEXT_LINE)


func test_default_style_and_skip() -> void:
	var talk := _talk()
	assert_str(talk.style()).is_equal(Dialogue.DEFAULT_STYLE)
	talk.skip()
	assert_bool(talk.finished).is_true()
	assert_bool(talk.is_typing()).is_false()


func test_only_letters_make_voice() -> void:
	assert_int(Dialogue.letter_count("Ô, meu neto!")).is_equal(8)
	assert_int(Dialogue.letter_count(" ,!?")).is_equal(0)


func test_cast_comes_from_characters_json() -> void:
	assert_str(story.character_name("grandpa")).is_equal("Avô")
	assert_str(story.character_name("grandma")).is_equal("Avó")
	assert_str(story.character_name("cleusa")).is_equal("Dona Cleusa")
	assert_str(story.character_name("ze_barranco")).is_equal("Zé Barranco")
	assert_str(story.voice_of("grandpa")).is_equal("voice_grandpa")
	assert_str(story.voice_of("tom")).is_empty()
	# Até o item 4 do Bloco B, os avós usam os modelos do Zeca e da Marô.
	assert_str(story.model_of("grandpa")).is_equal("zeca")
	assert_str(story.model_of("tom")).is_equal("tom")
	assert_bool(bool(story.character("grandma")["stand_in"])).is_true()
	assert_bool(story.has_character("saci")).is_false()


func test_day_one_dialogues_follow_the_script() -> void:
	assert_array(Array(story.dialogue_ids(1))).contains_exactly(
		["day1_porch", "day1_first_mission", "day1_boarding", "day1_ending"]
	)
	assert_array(Array(story.speakers("day1_porch"))).contains_exactly(["grandpa", "grandma"])
	var first: Dictionary = story.dialogue("day1_porch")["lines"][0]
	assert_str(String(first["text"])).starts_with("Ô, meu neto! Ocê acordô!")
	var shout: Dictionary = story.dialogue("day1_first_mission")["lines"][1]
	assert_str(String(shout.get("style", ""))).is_equal("shout")
	assert_array(Array(story.dialogue_ids(2))).is_empty()
	assert_bool(story.has_dialogue("day1_porch")).is_true()
