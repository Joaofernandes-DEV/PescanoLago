extends GdUnitTestSuite
## Contador de fps para a medição no celular (P-21, P-24).


func test_overlay_is_off_unless_asked() -> void:
	assert_bool(FpsOverlay.wanted({})).is_false()
	assert_bool(FpsOverlay.wanted({"fps-overlay": "true"})).is_true()


func test_overlay_counts_frames_per_second() -> void:
	var overlay := FpsOverlay.new()
	add_child(auto_free(overlay))
	# 31 quadros: 30 × (1/30) dá 0,99999 s em ponto flutuante e não fecha o segundo.
	for i in 31:
		overlay._process(1.0 / 30.0)
	assert_str(overlay.label.text).starts_with("30 fps")
	assert_str(overlay.label.text).contains("pior 33 ms")


func test_main_scene_shows_it_with_the_option() -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	game.set("options", {"no-save": "true", "fps-overlay": "true"})
	add_child(auto_free(game))
	var found := false
	for child in game.get_children():
		found = found or child is FpsOverlay
	assert_bool(found).is_true()
