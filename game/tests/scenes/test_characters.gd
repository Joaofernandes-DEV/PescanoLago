extends GdUnitTestSuite
## Personagens do MVP (Fase 5): Tom e Bolota no barco, Tio Zeca e Dona Marô nas
## lojas de Porto Manso, e a animação por código (respirar, latir, acenar, lançar).
## Fase 7: pernas e mãos separadas, e as poses do Tom com o peixe.

const PEOPLE_PARTS: Array[String] = [
	"head", "arm_left", "arm_right", "hand_left", "hand_right", "leg_left", "leg_right"
]
const PARTS: Dictionary = {
	"tom": PEOPLE_PARTS,
	"bolota":
	["head", "tail", "leg_front_left", "leg_front_right", "leg_back_left", "leg_back_right"],
	"maro": PEOPLE_PARTS,
	"zeca": PEOPLE_PARTS,
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


func test_hands_are_children_of_the_arms_and_legs_are_separate_pieces() -> void:
	for id: String in ["tom", "maro", "zeca"]:
		var puppet := _puppet(id)
		assert_object(puppet.hand_left.get_parent()).is_same(puppet.arm_left)
		assert_object(puppet.hand_right.get_parent()).is_same(puppet.arm_right)
		assert_int(puppet.legs.size()).is_equal(2)
	assert_int(_puppet("bolota").legs.size()).is_equal(4)
	# A mão acompanha o braço: levantar o braço sobe a mão.
	var tom := _puppet("tom")
	_advance(tom, 0.2)
	var resting: Vector3 = tom.hand_point()
	tom.pose = "show"
	_advance(tom, 1.0)
	assert_float(tom.hand_point().y - resting.y).is_greater(0.2)
	tom.pose = ""
	_advance(tom, 1.5)
	assert_float(tom.hand_point().distance_to(resting)).is_less(0.08)


func test_lake_merges_the_still_parts_to_save_draw_calls() -> void:
	var day := DayController.new()
	day.setup(db, PlayerState.new_game(db), 1, 1, pres)
	day.external_stepping = true
	add_child(auto_free(day))
	# No lago ninguém anda: as pernas vão para o corpo e a mão esquerda para o braço.
	# A mão direita, que segura o peixe, continua separada.
	var tom: CharacterPuppet = day.characters["tom"]
	assert_int(tom.legs.size()).is_equal(0)
	assert_object(tom.hand_left).is_null()
	assert_object(tom.hand_right).is_not_null()
	assert_object(tom.model.find_child("SM_tom_leg_left", true, false)).is_null()
	var meshes: Dictionary = {}
	for id: String in ["tom", "bolota", "maro", "zeca"]:
		var puppet: CharacterPuppet = day.characters[id]
		meshes[id] = puppet.model.find_children("SM_*", "MeshInstance3D", true, false).size()
		var body := puppet.model.find_child("SM_%s" % id, true, false) as MeshInstance3D
		assert_int(body.mesh.get_surface_count()).is_equal(1)
	# Tom: corpo, cabeça, dois braços e a mão direita. Bolota: corpo, cabeça e cauda.
	assert_int(int(meshes["tom"])).is_equal(5)
	assert_int(int(meshes["bolota"])).is_equal(3)
	# Juntar não mexe no tamanho: o corpo ainda vai até o chão.
	var bolota: CharacterPuppet = day.characters["bolota"]
	var body := bolota.model.find_child("SM_bolota", true, false) as MeshInstance3D
	var bottom: float = (body.global_transform * body.get_aabb()).position.y
	assert_float(bottom - bolota.global_position.y).is_less(0.01)


func test_tom_poses_to_net_show_and_store_the_fish() -> void:
	var tom := _puppet("tom")
	_advance(tom, 0.2)
	var head_rest: Vector3 = tom.head.rotation
	for pose: String in ["net", "show", "store"]:
		tom.pose = pose
		_advance(tom, 1.0)
		var target: Vector3 = CharacterPuppet.POSES[pose]["arm_right"]
		assert_float(tom.arm_right.rotation.x).is_equal_approx(target.x, 0.1)
	# Guardando: olha para baixo, para a caixa.
	assert_float(tom.head.rotation.x).is_greater(head_rest.x + 0.3)


func test_bolota_lifts_the_front_legs_when_barking() -> void:
	var bolota := _puppet("bolota")
	bolota.play("bark")
	_advance(bolota, 0.15)
	var front := bolota.legs["front_left"] as Node3D
	var back := bolota.legs["back_left"] as Node3D
	assert_float(front.rotation.x).is_less(-0.1)
	assert_float(back.rotation.x).is_equal(0.0)


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
