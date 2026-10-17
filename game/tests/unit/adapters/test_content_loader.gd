extends GdUnitTestSuite
## ContentLoader lê os JSON reais e monta o ContentDB.


func test_loads_real_content() -> void:
	var db := ContentLoader.load_dir()
	assert_object(db).is_not_null()
	assert_int(db.species_ids().size()).is_equal(17)


func test_missing_directory_returns_null() -> void:
	assert_object(ContentLoader.load_dir("res://pasta_que_nao_existe")).is_null()
