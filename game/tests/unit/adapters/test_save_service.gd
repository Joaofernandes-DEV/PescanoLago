extends GdUnitTestSuite
## SaveService: grava e lê o save em arquivo, com escrita atômica e cópia de segurança.

const TEST_ROOT: String = "user://test_saves"

var db: ContentDB
var service: SaveService


func before() -> void:
	db = TestContent.db()


func after() -> void:
	DirAccess.remove_absolute(TEST_ROOT)


func before_test() -> void:
	service = SaveService.new("%s/%d" % [TEST_ROOT, Time.get_ticks_usec()], 1)


func after_test() -> void:
	service.erase()
	DirAccess.remove_absolute(service.dir_path)


func _progress() -> PlayerState:
	var state := PlayerState.new_game(db)
	state.coins = 450
	state.best_stars["1"] = 2
	state.sessions_played = 3
	state.register_in_album(FishCatch.new("lambari", 0.08))
	return state


func _write(file_path: String, text: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_no_save_yet() -> void:
	assert_bool(service.has_save()).is_false()
	assert_object(service.load_state()).is_null()
	assert_int(service.loaded_from).is_equal(SaveService.Source.NONE)
	assert_str(service.last_error).is_empty()


func test_save_and_load_round_trip() -> void:
	var state := _progress()
	assert_bool(service.save(state)).is_true()
	assert_bool(FileAccess.file_exists(service.path())).is_true()
	assert_bool(FileAccess.file_exists(service.temp_path())).is_false()
	var loaded := service.load_state()
	assert_object(loaded).is_not_null()
	assert_int(service.loaded_from).is_equal(SaveService.Source.SLOT)
	assert_dict(loaded.to_dict()).is_equal(state.to_dict())


func test_file_has_current_version_and_game_version() -> void:
	service.save(_progress())
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(service.path()))
	assert_int(int(saved["save_version"])).is_equal(SaveCodec.CURRENT_VERSION)
	assert_str(saved["game_version"]).is_equal(SaveService.game_version())
	assert_str(SaveService.game_version()).is_not_empty()


func test_second_save_keeps_previous_as_backup() -> void:
	var state := _progress()
	service.save(state)
	state.coins = 999
	service.save(state)
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(service.path()))
	var backup: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(service.backup_path()))
	assert_int(int(current["data"]["coins"])).is_equal(999)
	assert_int(int(backup["data"]["coins"])).is_equal(450)


func test_corrupted_slot_falls_back_to_backup() -> void:
	var state := _progress()
	service.save(state)
	state.coins = 999
	service.save(state)
	_write(service.path(), "{ isto não é json")
	var loaded := service.load_state()
	assert_object(loaded).is_not_null()
	assert_int(service.loaded_from).is_equal(SaveService.Source.BACKUP)
	assert_int(loaded.coins).is_equal(450)
	assert_str(service.last_error).contains("não é um JSON válido")


func test_old_version_file_is_migrated_on_load() -> void:
	DirAccess.make_dir_recursive_absolute(service.dir_path)
	var v1 := FileAccess.get_file_as_string("res://tests/fixtures/saves/save_v1.json")
	_write(service.path(), v1)
	var loaded := service.load_state()
	assert_object(loaded).is_not_null()
	assert_int(loaded.coins).is_equal(640)
	assert_int(loaded.sessions_played).is_equal(0)


func test_future_version_is_refused() -> void:
	DirAccess.make_dir_recursive_absolute(service.dir_path)
	_write(service.path(), JSON.stringify({"save_version": 99, "data": {}}))
	assert_object(service.load_state()).is_null()
	assert_str(service.last_error).contains("mais novo")


func test_erase_removes_slot_and_backup() -> void:
	var state := _progress()
	service.save(state)
	service.save(state)
	service.erase()
	assert_bool(service.has_save()).is_false()
