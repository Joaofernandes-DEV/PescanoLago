extends GdUnitTestSuite
## Efeito visível das melhorias (Fase 4): o Esperança mostra a peça do nível
## atual do motor, do viveiro e do sonar, no dia de pesca e em Porto Manso.

const BOAT: String = "res://assets/models/boat/boat_esperanca_l1.glb"
const MVP_PARTS: PackedStringArray = [
	"SM_motor_l1",
	"SM_motor_l2",
	"SM_motor_l3",
	"SM_livewell_l1",
	"SM_livewell_l2",
	"SM_livewell_l3",
	"SM_sonar_l2",
	"SM_sonar_l3",
]

var db: ContentDB
var pres: PresentationConfig


func before() -> void:
	db = TestContent.db()
	pres = PresentationConfig.load_default()


func _boat() -> Node3D:
	return auto_free((load(BOAT) as PackedScene).instantiate())


func _part(model: Node, part_name: String) -> MeshInstance3D:
	return model.find_child(part_name, true, false) as MeshInstance3D


func _size(model: Node, part_name: String) -> Vector3:
	return _part(model, part_name).get_aabb().size


func test_model_has_a_part_for_each_mvp_level() -> void:
	var boat := _boat()
	for part_name in MVP_PARTS:
		var part := _part(boat, part_name)
		assert_object(part).is_not_null()
		assert_str(part.get_parent().name).is_equal("SM_boat_esperanca_l1")
	# Cada nível é maior que o anterior.
	assert_float(_size(boat, "SM_motor_l2").y).is_greater(_size(boat, "SM_motor_l1").y)
	assert_float(_size(boat, "SM_motor_l3").y).is_greater(_size(boat, "SM_motor_l2").y)
	assert_float(_size(boat, "SM_livewell_l2").x).is_greater(_size(boat, "SM_livewell_l1").x)
	assert_float(_size(boat, "SM_livewell_l3").x).is_greater(_size(boat, "SM_livewell_l2").x)
	assert_float(_size(boat, "SM_sonar_l3").y).is_greater(_size(boat, "SM_sonar_l2").y)


func test_new_boat_shows_level_one_parts_and_no_sonar() -> void:
	var boat := _boat()
	var shown := BoatLooks.apply(boat, PlayerState.new_game(db), db)
	assert_array(Array(shown)).is_equal(["SM_livewell_l1", "SM_motor_l1"])
	assert_bool(_part(boat, "SM_sonar_l2").visible).is_false()
	assert_bool(_part(boat, "SM_boat_esperanca_l1").visible).is_true()
	assert_bool(_part(boat, "SM_rod_bamboo").visible).is_true()


func test_upgraded_boat_shows_current_levels() -> void:
	var state := PlayerState.new_game(db)
	state.upgrade_levels["motor"] = 3
	state.upgrade_levels["livewell"] = 2
	state.upgrade_levels["sonar"] = 2
	var shown := BoatLooks.apply(_boat(), state, db)
	assert_array(Array(shown)).is_equal(["SM_livewell_l2", "SM_motor_l3", "SM_sonar_l2"])


func test_day_scene_boat_uses_the_upgrades() -> void:
	var state := PlayerState.new_game(db)
	state.upgrade_levels["sonar"] = 3
	var day := DayController.new()
	day.setup(db, state, 1, 1, pres)
	day.external_stepping = true
	add_child(auto_free(day))
	assert_bool(_part(day.boat.model, "SM_sonar_l3").visible).is_true()
	assert_bool(_part(day.boat.model, "SM_sonar_l2").visible).is_false()


func test_buying_in_porto_manso_changes_the_boat_right_away() -> void:
	var state := PlayerState.new_game(db)
	state.coins = 2000
	var hub := HubController.new()
	hub.setup(db, state, pres, 1)
	add_child(auto_free(hub))
	assert_bool(_part(hub.boat_model, "SM_livewell_l1").visible).is_true()
	hub.ui.find_button("Upgrade_livewell").pressed.emit()
	assert_bool(_part(hub.boat_model, "SM_livewell_l1").visible).is_false()
	assert_bool(_part(hub.boat_model, "SM_livewell_l2").visible).is_true()
