extends GdUnitTestSuite
## Configurações do jogador (Fase 7, Bloco A): padrões de presentation.json,
## arquivo próprio, volumes nos barramentos, qualidade na cena e troca de teclas.

var pres: PresentationConfig
var file_path: String


func before() -> void:
	pres = PresentationConfig.load_default()


func before_test() -> void:
	file_path = "user://test_settings_%d.cfg" % Time.get_ticks_usec()


func after_test() -> void:
	DirAccess.remove_absolute(file_path)
	InputSetup.reset_bindings()
	for bus: StringName in [
		GameSettings.MASTER_BUS, GameSettings.MUSIC_BUS, GameSettings.EFFECTS_BUS
	]:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_volume_db(index, 0.0)
			AudioServer.set_bus_mute(index, false)
	get_tree().root.scaling_3d_scale = 1.0


func _settings(path: String = "") -> GameSettings:
	return GameSettings.new(pres.section("settings"), path)


func test_defaults_come_from_presentation() -> void:
	var settings := _settings()
	var defaults: Dictionary = pres.section("settings")["defaults"]
	for key: String in defaults:
		assert_that(settings.values[key]).is_equal(defaults[key])
	assert_dict(settings.quality()).is_equal(pres.section("settings")["quality"]["high"])


func test_file_round_trip_and_bad_values_fall_back() -> void:
	var settings := _settings(file_path)
	settings.set_value("music_volume", 0.35)
	settings.set_value("quality", "low")
	settings.set_value("show_hints", false)
	settings.bind_key(InputSetup.ACTION, KEY_E)
	assert_int(settings.save_file()).is_equal(OK)
	InputSetup.reset_bindings()
	var reread := _settings(file_path)
	reread.load_file()
	assert_float(float(reread.values["music_volume"])).is_equal_approx(0.35, 0.0001)
	assert_str(String(reread.values["quality"])).is_equal("low")
	assert_bool(bool(reread.values["show_hints"])).is_false()
	assert_int(int(reread.keys["fish_action"])).is_equal(KEY_E)
	reread.apply_keys()
	assert_int(InputSetup.primary_key(InputSetup.ACTION)).is_equal(KEY_E)
	# Valor com o tipo errado no arquivo fica no padrão.
	var file := ConfigFile.new()
	file.load(file_path)
	file.set_value(GameSettings.SECTION, "show_fps", "sim")
	file.save(file_path)
	var broken := _settings(file_path)
	broken.load_file()
	assert_bool(bool(broken.values["show_fps"])).is_false()


func test_without_path_nothing_is_written() -> void:
	var settings := _settings()
	settings.set_value("master_volume", 0.2)
	assert_int(settings.save_file()).is_equal(OK)
	assert_bool(FileAccess.file_exists(file_path)).is_false()


func test_volumes_go_to_the_audio_buses() -> void:
	var settings := _settings()
	settings.set_value("master_volume", 0.5)
	settings.set_value("music_volume", 0.0)
	settings.apply_audio()
	var master := AudioServer.get_bus_index(GameSettings.MASTER_BUS)
	var music := AudioServer.get_bus_index(GameSettings.MUSIC_BUS)
	var effects := AudioServer.get_bus_index(GameSettings.EFFECTS_BUS)
	assert_int(music).is_greater(0)
	assert_int(effects).is_greater(0)
	assert_float(AudioServer.get_bus_volume_db(master)).is_equal_approx(linear_to_db(0.5), 0.01)
	assert_bool(AudioServer.is_bus_mute(music)).is_true()
	assert_bool(AudioServer.is_bus_mute(effects)).is_false()
	assert_str(String(AudioServer.get_bus_send(music))).is_equal("Master")


func test_quality_turns_shadows_ssao_and_render_scale() -> void:
	var holder := Node3D.new()
	add_child(auto_free(holder))
	var lighting := DayLighting.new()
	holder.add_child(lighting)
	lighting.setup(pres, TestContent.db().economy["day_phases"])
	var settings := _settings()
	settings.set_value("quality", "low")
	settings.apply_quality(holder)
	assert_bool(lighting.sun.shadow_enabled).is_false()
	assert_bool(lighting.environment.ssao_enabled).is_false()
	var low: Dictionary = pres.section("settings")["quality"]["low"]
	assert_float(holder.get_viewport().scaling_3d_scale).is_equal_approx(
		float(low["render_scale"]), 0.0001
	)
	settings.set_value("quality", "high")
	settings.apply_quality(holder)
	assert_bool(lighting.sun.shadow_enabled).is_true()


func test_rebinding_keeps_arrows_click_and_swaps_conflicts() -> void:
	InputSetup.ensure_actions()
	InputSetup.bind_primary(InputSetup.MOVE_FORWARD, KEY_I)
	assert_int(InputSetup.primary_key(InputSetup.MOVE_FORWARD)).is_equal(KEY_I)
	var keys: Array[int] = []
	for event in InputMap.action_get_events(InputSetup.MOVE_FORWARD):
		if event is InputEventKey:
			keys.append(int((event as InputEventKey).physical_keycode))
	assert_array(keys).contains([KEY_UP])
	assert_array(keys).not_contains([KEY_W])
	# Usar a tecla de outro comando troca as duas.
	InputSetup.bind_primary(InputSetup.MOVE_BACK, KEY_I)
	assert_int(InputSetup.primary_key(InputSetup.MOVE_BACK)).is_equal(KEY_I)
	assert_int(InputSetup.primary_key(InputSetup.MOVE_FORWARD)).is_equal(KEY_S)
	InputSetup.bind_primary(InputSetup.ACTION, KEY_F)
	var has_click := false
	for event in InputMap.action_get_events(InputSetup.ACTION):
		has_click = has_click or event is InputEventMouseButton
	assert_bool(has_click).is_true()
	InputSetup.reset_bindings()
	assert_int(InputSetup.primary_key(InputSetup.MOVE_FORWARD)).is_equal(KEY_W)


func test_hints_show_the_chosen_key() -> void:
	InputSetup.bind_primary(InputSetup.ACTION, KEY_F)
	var hints := ControlHints.new()
	add_child(auto_free(hints))
	hints.show_hint("hook_tap", false)
	assert_str(hints.text()).contains("aperte F ou clique agora")
	InputSetup.reset_bindings()
	hints.show_hint("", false)
	hints.show_hint("reel_hold", false)
	assert_str(hints.text()).contains("Segure Espaço para recolher")
	assert_str(InputSetup.key_label(KEY_UP)).is_equal("Seta para cima")
