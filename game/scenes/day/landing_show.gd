class_name LandingShow
extends Node3D
## Tirar o peixe da água e guardar (Fase 7, Bloco A, item 4). Quando o peixe é
## pego, em três partes (tempos em presentation.json, landing):
##   1. "net": o Tom põe o passaguá na água, o aro passa por baixo do peixe (que
##      ainda está na linha) e o tira da água;
##   2. "hand": o peixe passa para a mão do Tom, que o mostra, com a câmera de perto;
##   3. "store": a tampa da caixa de isopor abre, o peixe cai na vaga dele e a
##      tampa fecha. Aí ele aparece na caixa (CoolerBox).
##
## Só visual: as regras guardam o peixe no viveiro na hora em que ele é pego e
## seguem o tempo de guardar do núcleo (economy.json, fishing.store_s). Se o
## jogador já for lançar de novo (ou atracar, ou o dia acabar), skip() termina
## na hora, com o peixe na caixa: a animação nunca segura o ritmo do dia.
##
## Fica dentro do modelo do barco: tudo acompanha o barco andando e balançando.

const NET_SCENE: String = "res://assets/models/props/landing_net.glb"
## Do cabo ao centro do aro (make_landing_net.py: cabo de 1,2 m e aro de 0,2 m).
const NET_REACH_M: float = 1.4
## Passaguá guardado: empunhadura junto ao banco do Tom, à direita, com o aro
## apoiado na borda perto do banco da frente (no espaço do barco).
const REST_GRIP := Vector3(-0.36, 0.22, -0.3)
const REST_DIR := Vector3(0.0, 0.1, 1.0)
## Empunhadura em uso: diante do peito do Tom (espaço do barco).
const USE_GRIP := Vector3(0.1, 0.7, -0.15)
## O aro afunda até aqui embaixo do peixe e o levanta até aqui acima da água (m).
const SCOOP_DEPTH_M: float = 0.35
const LIFT_M: float = 0.45
## Fase da animação -> pose do Tom (CharacterPuppet.POSES).
const PHASE_POSES: Dictionary = {"net": "net", "hand": "show", "store": "store"}

## "", "net", "hand" ou "store".
var phase: String = ""
var phase_t: float = 0.0
var net: Node3D
var fish: MeshInstance3D
var fish_species: String = ""
## O peixe já está no aro do passaguá (antes, está na linha).
var scooped: bool = false
## A animação está rodando.
var active: bool:
	get:
		return not phase.is_empty()
var splashes: int = 0

var _cfg: Dictionary
var _fish_cfg: Dictionary
var _boat_model: Node3D
var _tom: CharacterPuppet
var _cooler: CoolerBox
var _camera: FollowCamera
var _rig: FishingRig
var _water_point := Vector3.ZERO
var _store_from := Vector3.ZERO
var _store_to := Vector3.ZERO
var _store_basis := Basis.IDENTITY
var _handle: Node3D


## scene: {"boat_model", "tom", "cooler", "camera", "rig"}.
func setup(cfg: Dictionary, fish_cfg: Dictionary, scene: Dictionary) -> void:
	_cfg = cfg
	_fish_cfg = fish_cfg
	_boat_model = scene["boat_model"]
	_tom = scene["tom"]
	_cooler = scene["cooler"]
	_camera = scene["camera"]
	_rig = scene["rig"]


func _ready() -> void:
	net = (load(NET_SCENE) as PackedScene).instantiate()
	Palette.apply(net)
	add_child(net)
	# O aro não se mexe sozinho: vai junto com o cabo numa malha só.
	_handle = net.find_child("SM_landing_net", true, false) as Node3D
	var hoop := net.find_child("SM_landing_net_hoop", true, false) as MeshInstance3D
	if _handle is MeshInstance3D and hoop != null:
		MeshMerge.into(_handle as MeshInstance3D, [hoop])
	LandingShow.no_shadows(net)
	_rest_net()


## Começa a tirar o peixe da água: ele está na linha, neste ponto da água.
func start(species: Dictionary, weight_kg: float, variant: String, from_point: Vector3) -> void:
	if active:
		skip()
	# O peixe numa malha só (um draw call), com a cor da variante nos vértices.
	if fish != null:
		fish.queue_free()
	fish = FishLooks.single_mesh(species["id"], variant, _fish_cfg)
	fish_species = species["id"]
	add_child(fish)
	fish.scale = Vector3.ONE * FishLooks.scale_for(species, weight_kg, _fish_cfg)
	_water_point = (
		_boat_model.global_transform.affine_inverse() * Vector3(from_point.x, 0.0, from_point.z)
	)
	scooped = false
	_set_phase("net")


## Termina na hora: o peixe vai para a caixa, a tampa fecha e a câmera volta.
func skip() -> void:
	if not active:
		return
	_finish()


func step(dt: float) -> void:
	if not active:
		return
	phase_t += dt
	var u: float = clampf(phase_t / float(_cfg["%s_s" % phase]), 0.0, 1.0)
	match phase:
		"net":
			_step_net(u)
		"hand":
			_step_hand(u)
		"store":
			_step_store(u)
	if u >= 1.0:
		match phase:
			"net":
				_set_phase("hand")
			"hand":
				_set_phase("store")
			"store":
				_finish()


func _set_phase(new_phase: String) -> void:
	phase = new_phase
	phase_t = 0.0
	_tom.pose = PHASE_POSES[new_phase]
	if new_phase == "store":
		_store_from = fish.global_position
		# O centro do peixe (a origem fica na barriga) cai na vaga, como na caixa.
		var center: Vector3 = fish.get_aabb().get_center() * fish.scale.x
		_store_to = _cooler.next_slot_point() - _lying_basis() * center
		_store_basis = fish.global_basis


func _finish() -> void:
	phase = ""
	phase_t = 0.0
	_tom.pose = ""
	if fish != null:
		fish.visible = false
	_rest_net()
	_cooler.set_lid(0.0)
	_camera.release_close_up()
	_rig.hide_all()


func _step_net(u: float) -> void:
	var water: Vector3 = _boat_model.global_transform * _water_point
	var bob: float = sin(phase_t * 11.0) * 0.04
	# O aro sai do barco, afunda embaixo do peixe, sobe com ele e volta para o barco.
	var grip: Vector3 = _boat(REST_GRIP).lerp(_boat(USE_GRIP), _smooth(u / 0.3))
	var under: Vector3 = water + Vector3.DOWN * SCOOP_DEPTH_M
	var above: Vector3 = water + Vector3.UP * LIFT_M
	var aim: Vector3
	if u < 0.35:
		aim = (grip + _rest_dir() * NET_REACH_M).lerp(under, _smooth(u / 0.35))
	elif u < 0.65:
		aim = under.lerp(above, _smooth((u - 0.35) / 0.3))
	else:
		aim = above.lerp(_tom.hand_point() + Vector3.UP * 0.2, _smooth((u - 0.65) / 0.35))
	_place_net(grip, aim - grip)
	if not scooped and u >= 0.5:
		scooped = true
		splash_at(water)
	if scooped:
		fish.global_position = hoop_center() + Vector3.UP * 0.05
		fish.global_basis = _side_basis(phase_t * 9.0)
		_rig.hide_all()
	else:
		# Ainda na linha: debatendo-se na superfície, de cabeça para cima.
		fish.global_position = water + Vector3.UP * (0.05 + bob)
		fish.global_basis = (
			Basis(Vector3.UP, phase_t * 2.0)
			* Basis(Vector3.RIGHT, -PI / 3.0 + sin(phase_t * 13.0) * 0.3)
			* Basis.from_scale(fish.scale)
		)
		_rig.lead_line_to(fish.global_position + Vector3.UP * 0.1)
	# Câmera do outro lado do barco, olhando o peixe e o passaguá por cima do Tom.
	var center: Vector3 = _boat_model.global_position
	var away := Vector3(center.x - water.x, 0.0, center.z - water.z).normalized()
	var eye: Vector3 = (
		Vector3(center.x, 0.0, center.z)
		+ away * float(_cfg["net_camera_back_m"])
		+ Vector3.UP * float(_cfg["net_camera_up_m"])
	)
	_camera.close_up(eye, water.lerp(_tom.hand_point(), 0.35))


func _step_hand(u: float) -> void:
	# O passaguá volta ao lugar enquanto o peixe passa para a mão.
	var grip: Vector3 = _boat(USE_GRIP).lerp(_boat(REST_GRIP), _smooth(u / 0.4))
	var aim: Vector3 = (_tom.hand_point() + Vector3.UP * 0.2).lerp(
		grip + _rest_dir() * NET_REACH_M, _smooth(u / 0.4)
	)
	_place_net(grip, aim - grip)
	var in_hand: Vector3 = _tom.hand_point() + Vector3.DOWN * 0.04
	var reach: float = _smooth(u / 0.25)
	fish.global_position = (hoop_center() + Vector3.UP * 0.05).lerp(in_hand, reach)
	fish.global_basis = _side_basis(phase_t * 7.0)
	_close_camera()


func _step_store(u: float) -> void:
	# Abre a tampa, o peixe cai na vaga dele num arco, e a tampa fecha.
	_cooler.set_lid(minf(_smooth(u / 0.3), 1.0 - _smooth((u - 0.8) / 0.2)))
	var fly: float = _smooth((u - 0.25) / 0.5)
	var point: Vector3 = _store_from.lerp(_store_to, fly) + Vector3.UP * sin(fly * PI) * 0.25
	fish.global_position = point
	var turn := Quaternion(_store_basis.orthonormalized()).slerp(Quaternion(_lying_basis()), fly)
	fish.global_basis = Basis(turn) * Basis.from_scale(fish.scale)
	if u < 0.6:
		_close_camera()
	else:
		_camera.release_close_up()


## Peixe deitado de lado, atravessado na caixa (como na CoolerBox).
func _lying_basis() -> Basis:
	return (
		_cooler.global_basis.orthonormalized()
		* Basis(Vector3.UP, PI / 2.0)
		* Basis(Vector3.BACK, PI / 2.0)
	)


## Centro do aro do passaguá no mundo.
func hoop_center() -> Vector3:
	var handle: Node3D = _handle if _handle != null else net
	return handle.global_transform * (Vector3.UP * NET_REACH_M)


func splash_at(point: Vector3) -> void:
	splashes += 1
	_rig.splash(point, maxf(fish.scale.x, 0.5))


func _close_camera() -> void:
	var eye: Vector3 = _tom.global_transform * LandingShow.vector(_cfg["camera_eye_m"])
	_camera.close_up(eye, fish.global_position)


## Passaguá com o cabo na empunhadura, apontando para direction, com a rede para baixo.
func _place_net(grip: Vector3, direction: Vector3) -> void:
	var along: Vector3 = direction.normalized() if direction.length() > 0.001 else _rest_dir()
	var bag: Vector3 = Vector3.DOWN - along * along.dot(Vector3.DOWN)
	bag = bag.normalized() if bag.length() > 0.001 else _boat_model.global_basis.z
	net.global_transform = Transform3D(Basis(along.cross(bag), along, bag), grip)


func _rest_net() -> void:
	if net != null:
		_place_net(_boat(REST_GRIP), _rest_dir())


func _rest_dir() -> Vector3:
	return (_boat_model.global_basis * REST_DIR).normalized()


func _boat(local: Vector3) -> Vector3:
	return _boat_model.global_transform * local


## Peixe na horizontal, de lado para quem está na frente do Tom, se debatendo.
func _side_basis(wiggle_t: float) -> Basis:
	var facing: Basis = _boat_model.global_basis.orthonormalized()
	return (
		facing
		* Basis(Vector3.UP, PI / 2.0 + sin(wiggle_t) * 0.25)
		* Basis(Vector3.BACK, sin(wiggle_t * 1.7) * 0.2)
		* Basis.from_scale(fish.scale)
	)


static func _smooth(x: float) -> float:
	var t: float = clampf(x, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Peças finas ou passageiras não fazem sombra (menos draw calls por quadro).
static func no_shadows(node: Node) -> void:
	for mesh in node.find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Vetor de uma lista [x, y, z] do presentation.json.
static func vector(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
