extends GdUnitTestSuite
## Peixes do MVP na tela (Fase 5): um modelo por espécie que aparece na Margem
## Rasa, tamanho pelo peso, variante albina, salto em arco e peixe pendurado.

var db: ContentDB
var pres: PresentationConfig
var cfg: Dictionary


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()
	cfg = pres.section("fish")


func _margem_rasa_species() -> PackedStringArray:
	var ids := PackedStringArray()
	for spawn: Dictionary in db.region("margem_rasa")["spawns"]:
		ids.append(spawn["species"])
	return ids


func _rig() -> FishingRig:
	var rig := FishingRig.new()
	rig.setup(cfg)
	add_child(auto_free(rig))
	return rig


func test_every_margem_rasa_species_has_its_own_model() -> void:
	var ids := _margem_rasa_species()
	assert_int(ids.size()).is_equal(8)
	for species_id in ids:
		assert_str(FishLooks.model_path(species_id)).is_not_equal(FishLooks.GENERIC_MODEL)
		var model := FishLooks.instance(species_id)
		add_child(auto_free(model))
		var body := model.find_child("SM_fish_%s" % species_id, true, false) as MeshInstance3D
		assert_object(body).is_not_null()
		assert_object(model.find_child("LOC_mouth", true, false)).is_not_null()
		# A boca fica na frente (+Z na Godot).
		var mouth := model.find_child("LOC_mouth", true, false) as Node3D
		assert_float(mouth.position.z).is_greater(body.get_aabb().get_center().z)


func test_species_without_model_use_the_generic_fish() -> void:
	assert_str(FishLooks.model_path("pirarucu")).is_equal(FishLooks.GENERIC_MODEL)


func test_models_are_built_at_real_size_and_scale_with_weight() -> void:
	# Lambari de 12 cm e carpa de 75 cm, no peso de referência.
	var lambari := FishLooks.instance("lambari")
	var carp := FishLooks.instance("common_carp")
	add_child(auto_free(lambari))
	add_child(auto_free(carp))
	var lambari_body := lambari.find_child("SM_fish_lambari", true, false) as MeshInstance3D
	var carp_body := carp.find_child("SM_fish_common_carp", true, false) as MeshInstance3D
	assert_float(lambari_body.get_aabb().size.z).is_between(0.1, 0.2)
	assert_float(carp_body.get_aabb().size.z).is_between(0.65, 1.0)
	var species := db.species("common_carp")
	var reference := float(species["max_weight_kg"]) * float(cfg["reference_weight_ratio"])
	assert_float(FishLooks.scale_for(species, reference, cfg)).is_equal_approx(1.0, 0.0001)
	# Oito vezes o peso = o dobro do comprimento (peso ∝ comprimento³), dentro dos limites.
	var small := FishLooks.scale_for(species, reference / 8.0, cfg)
	assert_float(small).is_equal_approx(0.5, 0.0001)
	assert_float(FishLooks.scale_for(species, 0.001, cfg)).is_equal(float(cfg["scale_min"]))
	assert_float(FishLooks.scale_for(species, 1000.0, cfg)).is_equal(float(cfg["scale_max"]))


func test_albino_variant_paints_body_and_red_eyes() -> void:
	var model := FishLooks.instance("nile_tilapia")
	add_child(auto_free(model))
	var body := model.find_child("SM_fish_nile_tilapia", true, false) as MeshInstance3D
	FishLooks.apply_variant(model, "albino", cfg)
	var colors: Dictionary = cfg["variants"]["albino"]
	var saw_eye := false
	for surface in body.mesh.get_surface_count():
		var original: Material = body.mesh.surface_get_material(surface)
		var tinted := body.get_surface_override_material(surface) as StandardMaterial3D
		assert_object(tinted).is_not_null()
		if original.resource_name == FishLooks.EYE_MATERIAL:
			saw_eye = true
			assert_object(tinted.albedo_color).is_equal(PresentationConfig.color(colors["eye"]))
		elif original.resource_name != FishLooks.PUPIL_MATERIAL:
			assert_object(tinted.albedo_color).is_equal(PresentationConfig.color(colors["body"]))
	assert_bool(saw_eye).is_true()
	FishLooks.apply_variant(model, "", cfg)
	assert_object(body.get_surface_override_material(0)).is_null()


func test_jump_is_a_ballistic_arc_back_into_the_water() -> void:
	var rig := _rig()
	rig.show_cast(Vector3(5.0, 0.0, 3.0))
	var splashes_before := rig.splashes
	rig.jump_fish(db.species("black_bass"), 3.0, "")
	assert_bool(rig.is_showing_fish()).is_true()
	var duration := rig.jump_duration()
	var expected_apex: float = float(cfg["jump_height_m"]) * (0.6 + 0.4 * rig.fish.scale.x)
	var apex := 0.0
	var t := 0.0
	while rig.is_showing_fish() and t < 5.0:
		rig.step(1.0 / 120.0, Vector3(0.0, 2.0, 0.0), true)
		apex = maxf(apex, rig.fish.global_position.y)
		t += 1.0 / 120.0
	assert_float(apex).is_equal_approx(expected_apex, 0.02)
	assert_float(t).is_equal_approx(duration, 0.02)
	# Respingo na saída e na volta.
	assert_int(rig.splashes - splashes_before).is_equal(2)


func test_caught_fish_leads_the_line_until_the_net_takes_it() -> void:
	var rig := _rig()
	rig.show_cast(Vector3(6.0, 0.0, 0.0))
	var tip := Vector3(1.0, 2.2, 0.0)
	var mouth := Vector3(1.6, 0.1, 0.0)
	rig.lead_line_to(mouth)
	rig.step(1.0 / 60.0, tip, false)
	# A boia some e a linha vai da ponta da vara até a boca do peixe.
	assert_bool(rig.buoy.visible).is_false()
	assert_bool(rig.is_showing_fish()).is_false()
	var mesh := rig._line_mesh
	assert_int(mesh.get_surface_count()).is_equal(1)
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_vector(rig.to_global(vertices[0])).is_equal_approx(tip, Vector3.ONE * 0.001)
	assert_vector(rig.to_global(vertices[-1])).is_equal_approx(mouth, Vector3.ONE * 0.001)
	rig.hide_all()
	rig.step(1.0 / 60.0, tip, false)
	assert_int(mesh.get_surface_count()).is_equal(0)


func test_day_scene_shows_the_species_that_was_caught() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 7, pres)
	day.external_stepping = true
	day.autopilot = AutoPilot.new(PlayerBot.new(db.bot_profile("skilled"), Rng.new(7)))
	add_child(auto_free(day))
	var shown: Array[String] = []
	var steps := 0
	while not day.is_finished() and steps < 20000:
		day.step(0.05)
		# O peixe pego aparece no passaguá (LandingShow), com o modelo da espécie.
		if day.landing.active and not shown.has(day.landing.fish_species):
			shown.append(day.landing.fish_species)
		steps += 1
	var caught: Array[String] = []
	for event in day.events_seen:
		if event["type"] == "caught":
			var species: String = event["fish"]["species"]
			if not caught.has(species):
				caught.append(species)
	assert_int(caught.size()).is_greater(0)
	for species in caught:
		assert_array(shown).contains([species])


func test_reeled_line_ends_in_the_water_beside_the_boat() -> void:
	var rig := _rig()
	rig.show_cast(Vector3(10.0, 0.0, 0.0))
	rig.pull_toward(Vector3.ZERO, 0.0)
	assert_vector(rig.buoy.global_position).is_equal_approx(
		Vector3(FishingRig.BOAT_SIDE_M, 0.0, 0.0), Vector3(0.001, 0.001, 0.001)
	)
	rig.pull_toward(Vector3.ZERO, 0.5)
	assert_float(rig.buoy.global_position.x).is_equal_approx(
		(10.0 + FishingRig.BOAT_SIDE_M) / 2.0, 0.001
	)
