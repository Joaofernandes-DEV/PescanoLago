extends GdUnitTestSuite
## Álbum (P-28): espécies e variantes de cada versão e o progresso do jogador.

var db: ContentDB
var mvp: ContentDB


func before() -> void:
	db = TestContent.full_db()
	mvp = TestContent.db()


func test_variants_follow_rarity_and_release() -> void:
	assert_array(Album.variants_for(db, "lambari")).is_equal(["albino", "golden"])
	assert_array(Album.variants_for(mvp, "lambari")).is_equal(["albino"])
	# Épicos e lendários não têm variantes (GDD: "comum, incomum ou raro").
	assert_array(Album.variants_for(db, "jau")).is_empty()


func test_catchable_species_per_version() -> void:
	assert_bool(Album.catchable(db, "pirarucu")).is_true()
	assert_bool(Album.catchable(db, "king_of_the_lake")).is_false()
	assert_bool(Album.catchable(mvp, "pirarucu")).is_false()
	assert_array(Album.regions_of(mvp, "traira")).is_equal(["margem_rasa"])
	assert_array(Album.regions_of(db, "traira")).is_equal(["remanso", "aguas_fundas"])


func test_progress_counts_species_and_variants() -> void:
	var state := PlayerState.new_game(db)
	var empty := Album.progress(db, state)
	# 17 espécies + 2 variantes para cada uma das 12 comuns, incomuns e raras.
	assert_int(int(empty["total"])).is_equal(17 + 12 * 2)
	assert_int(int(empty["found"])).is_equal(0)
	state.register_in_album(FishCatch.new("lambari", 0.05))
	state.register_in_album(FishCatch.new("lambari", 0.05, "golden"))
	state.register_in_album(FishCatch.new("jau", 40.0))
	var after := Album.progress(db, state)
	assert_int(int(after["found"])).is_equal(3)
	assert_int(int(after["species_found"])).is_equal(2)


func test_goal_text_names_the_rarity() -> void:
	var rare := {"type": "fish_count", "count": 18, "min_rarity": "rare", "min_rarity_count": 4}
	assert_str(GoalText.describe(rare, db)).contains("4 raros ou mais raros")
	var epic := {"type": "fish_count", "count": 25, "min_rarity": "epic", "min_rarity_count": 1}
	assert_str(GoalText.describe(epic, db)).contains("1 épicos ou mais raros")
