class_name OnFoot
extends Node
## A pé em terra (Fase 7, Bloco B, item 3; P-41): o Tom em pé (char_tom_standing,
## com a mochila) anda pelo chão do cenário (a grade de alturas do terreno) e pelo
## cais (COL_deck_), sem atravessar a casa e as cercas (COL_wall_) nem entrar na
## água. O Bolota vai atrás. Perto do barco, a ação embarca: o Bolota pula
## primeiro e o barco balança, depois o Tom pula para o banco. No fim, os dois do
## barco aparecem no lugar deles e o dia de pesca começa (boarded).
##
## A direção de andar vem pronta, no plano do mundo (quem chama converte as teclas
## pela câmera). A câmera fica atrás do Tom, sempre virada para o mesmo lado.

signal boarded

enum Stage { WALKING, BOARDING, DONE }

const MOVE_DEADZONE: float = 0.05

var stage: Stage = Stage.WALKING
var tom: CharacterPuppet
var dog: CharacterPuppet
var boat: BoatController
var ground: LakeChart
var walls: Array[Dictionary] = []
var decks: Array[Dictionary] = []
## Para onde a câmera olha (ângulo no plano, fixo enquanto anda).
var camera_yaw: float = 0.0

var _cfg: Dictionary
var _board_t: float = 0.0
var _rocked: bool = false
var _tom_from := Vector3.ZERO
var _dog_from := Vector3.ZERO


## cfg: presentation.json, walk.
func setup(cfg: Dictionary, lake: Node3D, p_boat: BoatController, chart: LakeChart) -> void:
	_cfg = cfg
	boat = p_boat
	ground = chart
	walls = LakeWorld.walk_boxes(lake, LakeWorld.WALL_PREFIX)
	decks = LakeWorld.walk_boxes(lake, LakeWorld.DECK_PREFIX)


## Põe o Tom no ponto de partida (virado como ele) e o Bolota logo atrás.
func start(spot: Node3D) -> void:
	tom = CharacterPuppet.create("tom_standing")
	tom.merge_for_walking()
	add_child(tom)
	tom.place_at(spot)
	tom.global_position.y = height_at(tom.global_position)
	camera_yaw = tom.rotation.y
	dog = CharacterPuppet.create("bolota")
	add_child(dog)
	dog.global_position = tom.global_position - _forward(camera_yaw) * float(_cfg["dog_follow_m"])
	var dog_height: float = height_at(dog.global_position)
	dog.global_position.y = tom.global_position.y if is_nan(dog_height) else dog_height
	dog.rotation.y = camera_yaw


## Perto o bastante do barco para embarcar.
func can_board() -> bool:
	if stage != Stage.WALKING:
		return false
	var gap := Vector2(
		tom.global_position.x - boat.global_position.x,
		tom.global_position.z - boat.global_position.z
	)
	return gap.length() <= float(_cfg["board_radius_m"])


## move: direção de andar no plano (x, z do mundo), de tamanho até 1.
func step(dt: float, move: Vector2, action_pressed: bool) -> void:
	match stage:
		Stage.WALKING:
			_walk(dt, move)
			_follow(dt)
			if action_pressed and can_board():
				_start_boarding()
		Stage.BOARDING:
			_board(dt)
	if tom != null:
		tom.advance(dt)
		dog.advance(dt)


func camera_eye() -> Vector3:
	return (
		tom.global_position
		- _forward(camera_yaw) * float(_cfg["camera_distance_m"])
		+ Vector3.UP * float(_cfg["camera_height_m"])
	)


func camera_look() -> Vector3:
	return tom.global_position + Vector3.UP * float(_cfg["camera_look_height_m"])


## Altura de quem pisa no ponto: o piso do cais, o terreno, ou NAN (parede ou água).
func height_at(point: Vector3) -> float:
	var flat := Vector2(point.x, point.z)
	for wall in walls:
		if _inside(wall, flat, float(_cfg["radius_m"])):
			return NAN
	for deck in decks:
		if _inside(deck, flat, 0.0):
			return float(deck["top"])
	var height: float = ground.height_at(flat) if ground != null else NAN
	if is_nan(height) or height < float(_cfg["min_ground_m"]):
		return NAN
	return height


func _walk(dt: float, move: Vector2) -> void:
	var amount: float = minf(move.length(), 1.0)
	if amount < MOVE_DEADZONE:
		tom.walk_hz = 0.0
		return
	var direction: Vector2 = move / move.length()
	var speed: float = float(_cfg["speed_m_s"]) * amount
	var step_m := Vector3(direction.x, 0.0, direction.y) * speed * dt
	# Bateu numa parede ou na água: tenta deslizar só num eixo.
	for attempt: Vector3 in [step_m, Vector3(step_m.x, 0.0, 0.0), Vector3(0.0, 0.0, step_m.z)]:
		var next: Vector3 = tom.global_position + attempt
		var height: float = height_at(next)
		if not is_nan(height):
			tom.global_position = Vector3(next.x, height, next.z)
			break
	var k: float = clampf(dt * float(_cfg["turn_per_s"]), 0.0, 1.0)
	tom.rotation.y = lerp_angle(tom.rotation.y, atan2(direction.x, direction.y), k)
	tom.walk_hz = speed * float(_cfg["steps_per_m"])


## O Bolota vai até um pouco atrás do Tom.
func _follow(dt: float) -> void:
	var target: Vector3 = (
		tom.global_position - _forward(tom.rotation.y) * float(_cfg["dog_follow_m"])
	)
	var gap := Vector3(target.x - dog.global_position.x, 0.0, target.z - dog.global_position.z)
	var speed: float = float(_cfg["dog_speed_m_s"])
	if gap.length() < float(_cfg["radius_m"]):
		dog.walk_hz = 0.0
		return
	var move: float = minf(gap.length(), speed * dt)
	var next: Vector3 = dog.global_position + gap.normalized() * move
	var height: float = height_at(next)
	dog.global_position = Vector3(
		next.x, dog.global_position.y if is_nan(height) else height, next.z
	)
	var k: float = clampf(dt * float(_cfg["turn_per_s"]), 0.0, 1.0)
	dog.rotation.y = lerp_angle(dog.rotation.y, atan2(gap.x, gap.z), k)
	dog.walk_hz = speed * float(_cfg["steps_per_m"])


func _start_boarding() -> void:
	stage = Stage.BOARDING
	_board_t = 0.0
	_tom_from = tom.global_position
	_dog_from = dog.global_position
	tom.walk_hz = 0.0
	dog.walk_hz = 0.0


## Primeiro o Bolota pula na proa (o barco balança), depois o Tom pula no banco.
func _board(dt: float) -> void:
	var half: float = float(_cfg["board_s"])
	_board_t += dt
	var hop: float = float(_cfg["board_hop_m"])
	var bow: Vector3 = _locator("LOC_bow_dog")
	var seat: Vector3 = _locator("LOC_seat")
	var dog_e: float = clampf(_board_t / half, 0.0, 1.0)
	dog.global_position = _dog_from.lerp(bow, dog_e) + Vector3.UP * sin(dog_e * PI) * hop
	if dog_e >= 1.0 and not _rocked:
		_rocked = true
		boat.rock(float(_cfg["boat_rock_rad_s"]))
	var tom_e: float = clampf((_board_t - half) / half, 0.0, 1.0)
	tom.global_position = _tom_from.lerp(seat, tom_e) + Vector3.UP * sin(tom_e * PI) * hop
	if tom_e >= 1.0:
		stage = Stage.DONE
		tom.queue_free()
		dog.queue_free()
		tom = null
		dog = null
		boarded.emit()


func _locator(locator_name: String) -> Vector3:
	var point := boat.model.find_child(locator_name, true, false) as Node3D
	return point.global_position if point != null else boat.global_position


static func _inside(box: Dictionary, point: Vector2, pad: float) -> bool:
	var local: Vector2 = (point - (box["center"] as Vector2)).rotated(-float(box["angle"]))
	var half: Vector2 = box["half"]
	return absf(local.x) <= half.x + pad and absf(local.y) <= half.y + pad


static func _forward(yaw: float) -> Vector3:
	return Vector3(sin(yaw), 0.0, cos(yaw))
