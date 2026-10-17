extends GdUnitTestSuite
## SaveCodec: formato versionado, migrações e saves de exemplo de cada versão.

const SAVE_V1: String = "res://tests/fixtures/saves/save_v1.json"
const SAVE_V2: String = "res://tests/fixtures/saves/save_v2.json"

var db: ContentDB


func before() -> void:
	db = TestContent.db()


func _rich_state() -> PlayerState:
	var state := PlayerState.new_game(db)
	state.coins = 100000
	return state


func test_save_round_trip() -> void:
	var state := _rich_state()
	Shop.new(db).buy_rod(state, "fiberglass")
	state.best_stars["1"] = 2
	state.register_in_album(FishCatch.new("pacu", 4.2, "albino"))
	var save := SaveCodec.encode(state, "0.2.0")
	# Simula gravar e ler o arquivo: JSON transforma inteiros em float.
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(save))
	var restored := SaveCodec.decode(reloaded)
	assert_object(restored).is_not_null()
	assert_dict(restored.to_dict()).is_equal(state.to_dict())


func test_version_1_fixture_still_loads() -> void:
	var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_V1))
	var state := SaveCodec.decode(save)
	assert_object(state).is_not_null()
	assert_int(state.coins).is_equal(640)
	assert_str(state.equipped_rod).is_equal("fiberglass")
	assert_int(state.stars_of(1)).is_equal(3)
	assert_int(state.level_of("motor")).is_equal(2)
	assert_int(state.unlocked_day(10)).is_equal(4)
	assert_array(state.album["nile_tilapia"]["variants"]).is_equal(["albino"])
	# Migrado para a v2: o save antigo não sabia quantos dias foram jogados.
	assert_int(state.sessions_played).is_equal(0)


func test_version_1_migrates_to_version_2_without_losing_progress() -> void:
	var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_V1))
	var migrated := SaveCodec.migrate(save)
	assert_int(int(migrated["save_version"])).is_equal(SaveCodec.CURRENT_VERSION)
	assert_int(int(migrated["data"]["sessions_played"])).is_equal(0)
	var before: Dictionary = save["data"]
	for key: String in before:
		assert_that(migrated["data"][key]).is_equal(before[key])
	# A migração é pura: o save original não muda.
	assert_bool(save["data"].has("sessions_played")).is_false()


func test_version_2_fixture_loads() -> void:
	var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_V2))
	var state := SaveCodec.decode(save)
	assert_object(state).is_not_null()
	assert_int(state.coins).is_equal(1210)
	assert_int(state.sessions_played).is_equal(7)
	assert_int(state.level_of("livewell")).is_equal(3)
	assert_int(state.unlocked_day(10)).is_equal(6)


func test_day_session_counts_sessions_played() -> void:
	var state := PlayerState.new_game(db)
	var session := DaySession.new(db, state, 1, Rng.new(5))
	while not session.is_over():
		session.tick(1.0)
	assert_int(state.sessions_played).is_equal(1)


func test_invalid_and_future_saves_are_rejected() -> void:
	assert_object(SaveCodec.decode({"data": {}})).is_null()
	assert_object(SaveCodec.decode({"save_version": 99, "data": {}})).is_null()
	assert_str(SaveCodec.validate({"save_version": 99, "data": {}})).contains("mais novo")
	assert_object(SaveCodec.decode({"save_version": 1, "data": {"coins": 1}})).is_null()
	assert_str(SaveCodec.validate({"save_version": 2, "data": []})).contains("não é um objeto")


func test_migrations_run_in_order() -> void:
	var migrations := {1: _migrate_v1_to_v2, 2: _migrate_v2_to_v3}
	var migrated := SaveCodec.migrate({"save_version": 1, "data": {}}, migrations, 3)
	assert_int(int(migrated["save_version"])).is_equal(3)
	assert_str(migrated["data"]["trail"]).is_equal("v2->v3")


func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var out := data.duplicate()
	out["trail"] = "v2"
	return out


func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
	var out := data.duplicate()
	out["trail"] = String(out["trail"]) + "->v3"
	return out
