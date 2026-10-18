extends GdUnitTestSuite
## Personagens do MVP (Fase 5): Tom e Bolota no barco, Tio Zeca e Dona Marô nas
## lojas de Porto Manso, e a animação por código (respirar, latir, acenar, lançar).

const PARTS: Dictionary = {
	"tom": ["head", "arm_left", "arm_right"],
	"bolota": ["head", "tail"],
	"maro": ["head", "arm_left", "arm_right"],
	"zeca": ["head", "arm_left", "arm_right"],
}

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func _puppet(id: String) -> CharacterPuppet:
	var puppet := CharacterPuppet.create(id)
	add_child(auto_free(puppet))
	return puppet


func _advance(puppet: CharacterPuppet, seconds: float) -> void:
	for i in int(seconds * 60.0):
		puppet.advance(1.0 / 60.0)


func test_models_have_their_animated_parts() -> void:
	for id: String in PARTS:
		var puppet := _puppet(id)
		assert_object(puppet.model.find_child("SM_%s" % id, true, false)).is_not_null()
		for part: String in PARTS[id]:
			(
				assert_object(puppet.model.find_child("SM_%s_%s" % [id, part], true, false))
				. is_not_null()
			)
	assert_object(_puppet("tom").model.find_child("LOC_seat_contact", true, false)).is_not_null()


func test_characters_have_believable_sizes() -> void:
	# Em pé: Marô baixa, Zeca mais alto; Tom sentado; Bolota um cão médio.
	var heights: Dictionary = {}
	for id: String in PARTS:
		var puppet := _puppet(id)
		var top := 0.0
		for node in puppet.model.find_children("SM_*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			var aabb := mesh.global_transform * mesh.get_aabb()
			top = maxf(top, aabb.end.y - puppet.global_position.y)
		heights[id] = top
	assert_float(float(heights["maro"])).is_between(1.2, 1.6)
	assert_float(float(heights["zeca"])).is_between(1.6, 1.95)
	assert_float(float(heights["zeca"])).is_greater(float(heights["maro"]))
	assert_float(float(heights["tom"])).is_between(1.0, 1.4)
	assert_float(float(heights["bolota"])).is_between(0.5, 0.9)


func test_day_puts_the_crew_on_the_boat_and_the_villagers_at_the_shops() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 1, pres)
	day.external_stepping = true
	add_child(auto_free(day))
	var tom: CharacterPuppet = day.characters["tom"]
	var bolota: CharacterPuppet = day.characters["bolota"]
	assert_object(tom.get_parent()).is_same(day.boat.model)
	assert_object(bolota.get_parent()).is_same(day.boat.model)
	var seat := day.boat.model.find_child("LOC_seat", true, false) as Node3D
	var contact := tom.model.find_child("LOC_seat_contact", true, false) as Node3D
	assert_float(contact.global_position.distance_to(seat.global_position)).is_less(0.01)
	# Bolota na proa, olhando para a frente do barco.
	(
		assert_float((bolota.global_position - day.boat.global_position).dot(day.boat.forward()))
		. is_greater(0.8)
	)
	assert_float(bolota.global_transform.basis.z.dot(day.boat.forward())).is_greater(0.95)
	for id: String in ["zeca", "maro"]:
		var puppet: CharacterPuppet = day.characters[id]
		var spot := day.find_child("LOC_%s" % id, true, false) as Node3D
		assert_float(puppet.global_position.distance_to(spot.global_position)).is_less(0.01)
		# Em terra, fora do lago.
		var flat := Vector2(puppet.global_position.x, puppet.global_position.z)
		assert_float(flat.length()).is_greater(pres.number("lake", "shore_radius_m"))


func test_bolota_barks_when_a_school_is_found() -> void:
	var bolota := _puppet("bolota")
	bolota.play("bark")
	var nod := 0.0
	var hop := 0.0
	for i in 30:
		bolota.advance(1.0 / 60.0)
		nod = minf(nod, bolota.head.rotation.x)
		hop = maxf(hop, bolota.model.position.y)
	assert_float(nod).is_less(-0.1)
	assert_float(hop).is_greater(0.03)
	_advance(bolota, 1.0)
	assert_str(bolota.action).is_empty()
	assert_float(bolota.model.position.y).is_equal(0.0)


func test_tail_wags_and_the_body_breathes() -> void:
	var bolota := _puppet("bolota")
	var wag := 0.0
	var breath := 0.0
	for i in 120:
		bolota.advance(1.0 / 60.0)
		wag = maxf(wag, absf(bolota.tail.rotation.y))
		breath = maxf(breath, absf(bolota.model.scale.y - 1.0))
	assert_float(wag).is_greater(0.4)
	assert_float(breath).is_greater(0.005)


func test_villager_waves_and_returns() -> void:
	var zeca := _puppet("zeca")
	zeca.play("wave")
	_advance(zeca, 0.3)
	assert_float(zeca.arm_right.rotation.z).is_less(-1.8)
	_advance(zeca, 1.0)
	assert_float(absf(zeca.arm_right.rotation.z)).is_less(0.1)


func test_tom_raises_the_rod_while_charging_and_swings_on_release() -> void:
	var tom := _puppet("tom")
	tom.cast_charge = 1.0
	tom.advance(1.0 / 60.0)
	assert_float(tom.arm_left.rotation.x).is_less(-0.9)
	tom.release_cast()
	tom.advance(1.0 / 60.0)
	assert_float(tom.arm_left.rotation.x).is_greater(0.3)


func test_shopkeepers_wave_when_you_buy_from_them() -> void:
	var state := PlayerState.new_game(db)
	state.coins = 2000
	var hub := HubController.new()
	hub.setup(db, state, pres, 1)
	add_child(auto_free(hub))
	hub.buy_upgrade("motor")
	assert_str((hub.characters["zeca"] as CharacterPuppet).action).is_equal("wave")
	hub.buy_bait("worm")
	assert_str((hub.characters["maro"] as CharacterPuppet).action).is_equal("wave")
