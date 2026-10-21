class_name CharacterPuppet
extends Node3D
## Personagem do Blender animado por código (Fase 5). O modelo traz a cabeça,
## os braços, as mãos (filhas dos braços), as pernas e (no Bolota) as quatro patas
## e a cauda como peças com a origem na articulação (SM_<id>_head,
## SM_<id>_arm_left/right, SM_<id>_hand_left/right, SM_<id>_leg_left/right,
## SM_bolota_leg_front_left..., SM_bolota_tail); aqui elas giram.
##
## Sempre: respirar, olhar em volta e, no cão, abanar o rabo. Ações: carregar e
## soltar o lançamento (Tom), latir (Bolota), acenar (Marô e Zeca), comemorar.
## Poses do Tom ao tirar o peixe da água (Fase 7): "net" (passaguá na água),
## "show" (peixe na mão, à mostra) e "store" (guardando na caixa de isopor).
## Falar (Fase 7, Bloco B): com talking, a boca (SM_<id>_mouth, filha da cabeça)
## abre e fecha, a cabeça balança e os braços gesticulam; quem ouve vira a cabeça
## para quem fala (look_target). Só visual: avança por advance(dt).
##
## No lago ninguém anda nem fala e a mão esquerda não faz nada sozinha:
## merge_still_parts() junta as pernas ao corpo, a mão esquerda ao braço e a boca
## à cabeça, uma malha a menos por peça (MeshMerge). Quem fala nos balões pede para
## manter a boca; quem for andar (Bloco B) cria o boneco sem juntar.

const MODEL_PATH: String = "res://assets/models/characters/char_%s.glb"
const BREATH_HZ: float = 0.25
const LOOK_HZ: float = 0.07
const ACTION_S: float = 0.9
## Quão rápido o corpo entra e sai de uma pose (fração por segundo).
const POSE_BLEND_PER_S: float = 7.0
## Falar: sílabas por segundo (a boca abre e fecha), quanto a boca estica aberta e
## o balanço da cabeça e dos braços (radianos).
const TALK_SYLLABLE_HZ: float = 4.5
const MOUTH_OPEN_SCALE: float = 3.2
const TALK_NOD_RAD: float = 0.09
const TALK_ARM_RAD: float = 0.32
## Gritar (balão de grito): a cabeça vai para trás e os braços abrem mais.
const SHOUT_HEAD_RAD: float = -0.18
const SHOUT_ARM_RAD: float = 0.5
## Quão rápido a cabeça vira para quem fala (fração por segundo) e o giro máximo.
const LOOK_TURN_PER_S: float = 5.0
const LOOK_MAX_RAD: float = 1.1
## Pose -> rotação de cada peça (radianos). Braço: x negativo levanta para a
## frente; z positivo leva para a esquerda do personagem.
const POSES: Dictionary = {
	"net":
	{
		"arm_left": Vector3(-0.55, 0.0, 0.55),
		"arm_right": Vector3(-0.7, 0.0, 0.75),
		"head": Vector3(0.3, 0.7, 0.0),
	},
	"show":
	{
		"arm_left": Vector3(-0.35, 0.0, -0.1),
		"arm_right": Vector3(-1.7, 0.0, -0.3),
		"hand_right": Vector3(0.0, 0.0, 0.3),
		"head": Vector3(-0.05, -0.3, 0.0),
	},
	"store":
	{
		"arm_left": Vector3(-0.15, 0.0, 0.0),
		"arm_right": Vector3(-0.2, 0.0, 0.15),
		"head": Vector3(0.45, 0.0, 0.0),
	},
}

var character_id: String
var model: Node3D
var head: Node3D
var arm_left: Node3D
var arm_right: Node3D
var hand_left: Node3D
var hand_right: Node3D
var mouth: Node3D
var tail: Node3D
## Pernas: "left"/"right" nas pessoas; "front_left", "back_right"... no Bolota.
var legs: Dictionary = {}
## Ação em andamento ("", "bark", "wave", "cheer") e quanto falta.
var action: String = ""
var action_left_s: float = 0.0
## Pose em que o corpo está entrando ("" = solto, só a animação de sempre).
var pose: String = ""
## 0 a 1 enquanto o Tom carrega o lançamento.
var cast_charge: float = 0.0
## Falando num balão (a boca mexe) e se é um grito.
var talking: bool = false
var shouting: bool = false
## Ponto do mundo para onde a cabeça vira (quem ouve olha quem fala); null = olhar
## em volta, como sempre.
var look_target: Variant = null
var time_s: float = 0.0

var _phase: float = 0.0
var _release_left_s: float = 0.0
var _pose_weight: float = 0.0
## Peça -> rotação atual da pose (vai suavemente até a rotação da pose nova).
var _pose_rotation: Dictionary = {}
var _talk_weight: float = 0.0
var _look_yaw: float = 0.0
var _look_weight: float = 0.0


static func create(id: String) -> CharacterPuppet:
	var puppet := CharacterPuppet.new()
	puppet.character_id = id
	puppet.name = "Char_%s" % id
	puppet.model = (load(MODEL_PATH % id) as PackedScene).instantiate()
	Palette.apply(puppet.model)
	puppet.add_child(puppet.model)
	puppet.head = puppet._part("head")
	puppet.arm_left = puppet._part("arm_left")
	puppet.arm_right = puppet._part("arm_right")
	puppet.hand_left = puppet._part("hand_left")
	puppet.hand_right = puppet._part("hand_right")
	puppet.mouth = puppet._part("mouth")
	puppet.tail = puppet._part("tail")
	for leg_id: String in ["left", "right", "front_left", "front_right", "back_left", "back_right"]:
		var leg := puppet._part("leg_%s" % leg_id)
		if leg != null:
			puppet.legs[leg_id] = leg
	# Mãos e pernas são peças pequenas: sem sombra, cada uma custa um draw call a
	# menos por quadro (a meta é de até 150 em qualquer cenário).
	for part: Node3D in [puppet.hand_left, puppet.hand_right, puppet.mouth] + puppet.legs.values():
		if part is GeometryInstance3D:
			(part as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cada personagem respira e olha num ritmo um pouco diferente.
	puppet._phase = float(id.hash() % 1000) / 1000.0 * TAU
	return puppet


func _part(suffix: String) -> Node3D:
	return model.find_child("SM_%s_%s" % [character_id, suffix], true, false) as Node3D


## Junta as pernas ao corpo, a mão esquerda ao braço e (sem keep_mouth) a boca
## fechada à cabeça (essas peças param de se mexer; menos draw calls).
func merge_still_parts(keep_mouth: bool = false) -> void:
	var body := model.find_child("SM_%s" % character_id, true, false) as MeshInstance3D
	if body != null and not legs.is_empty():
		var parts: Array[MeshInstance3D] = []
		for leg: Node3D in legs.values():
			parts.append(leg as MeshInstance3D)
		MeshMerge.into(body, parts)
		legs.clear()
	if arm_left is MeshInstance3D and hand_left is MeshInstance3D:
		MeshMerge.into(arm_left as MeshInstance3D, [hand_left as MeshInstance3D])
		hand_left = null
	if not keep_mouth and head is MeshInstance3D and mouth is MeshInstance3D:
		MeshMerge.into(head as MeshInstance3D, [mouth as MeshInstance3D])
		mouth = null


## Alto da cabeça no mundo (onde o balão de fala aponta).
func head_top() -> Vector3:
	var top := head as MeshInstance3D
	if top == null:
		return global_position
	var box: AABB = top.global_transform * top.get_aabb()
	return Vector3(box.get_center().x, box.end.y, box.get_center().z)


## Põe o personagem no ponto de encaixe (posição e direção do LOC_).
func place_at(point: Node3D) -> void:
	global_transform = point.global_transform


## Tom sentado: o ponto LOC_seat_contact do modelo encosta no banco (LOC_seat do barco).
func place_seated(seat: Node3D) -> void:
	place_at(seat)
	var contact := model.find_child("LOC_seat_contact", true, false) as Node3D
	if contact != null:
		global_position += seat.global_position - contact.global_position


func play(new_action: String) -> void:
	action = new_action
	action_left_s = ACTION_S


## Tom solta o lançamento: os braços vão para a frente.
func release_cast() -> void:
	cast_charge = 0.0
	_release_left_s = 0.35


## Centro da mão no mundo (onde o Tom segura o peixe ou o passaguá).
func hand_point(right: bool = true) -> Vector3:
	var hand := (hand_right if right else hand_left) as MeshInstance3D
	if hand == null:
		return global_position
	return hand.global_transform * hand.get_aabb().get_center()


func advance(dt: float) -> void:
	time_s += dt
	action_left_s = maxf(0.0, action_left_s - dt)
	_release_left_s = maxf(0.0, _release_left_s - dt)
	if action_left_s <= 0.0:
		action = ""
	var t: float = time_s + _phase
	var progress: float = 1.0 - action_left_s / ACTION_S
	# Respirar: o corpo sobe e desce um pouquinho.
	model.scale = Vector3(1.0, 1.0 + sin(t * TAU * BREATH_HZ) * 0.012, 1.0)
	model.position.y = 0.0
	var rot: Dictionary = {
		"head": Vector3(sin(t * 0.9) * 0.04, sin(t * TAU * LOOK_HZ) * 0.5, 0.0),
		"arm_left": Vector3.ZERO,
		"arm_right": Vector3.ZERO,
		"hand_left": Vector3.ZERO,
		"hand_right": Vector3.ZERO,
	}
	var leg_lift: float = 0.0
	match action:
		"bark":
			# Latido: a cabeça dá um tranco, o cão dá um pulinho e ergue as patas da frente.
			var pulse: float = sin(progress * PI * 3.0)
			rot["head"].x = -absf(pulse) * 0.35
			model.position.y = absf(sin(progress * PI)) * 0.08
			leg_lift = absf(pulse) * 0.35
		"wave":
			rot["arm_right"] = Vector3(0.0, 0.0, -2.4 + sin(progress * PI * 6.0) * 0.35)
			rot["hand_right"] = Vector3(0.0, 0.0, sin(progress * PI * 6.0 + 1.0) * 0.4)
		"cheer":
			rot["arm_left"] = Vector3(0.0, 0.0, 2.2)
			rot["arm_right"] = Vector3(0.0, 0.0, -2.2)
			model.position.y = absf(sin(progress * PI * 2.0)) * 0.05
			leg_lift = absf(sin(progress * PI * 2.0)) * 0.15
	if character_id == "tom":
		# Carregar o lançamento leva os braços para trás e para cima; soltar, para a frente.
		var back: float = -cast_charge * 1.1 + (_release_left_s / 0.35) * 0.6
		rot["arm_left"].x += back
		rot["arm_right"].x += back
	rot["arm_left"] += Vector3(sin(t * 1.3) * 0.03, 0.0, 0.0)
	rot["arm_right"] += Vector3(sin(t * 1.3 + 1.0) * 0.03, 0.0, 0.0)
	_talk(rot, dt)
	_look(rot, dt)
	_blend_pose(rot, dt)
	_apply(head, rot["head"])
	_apply(arm_left, rot["arm_left"])
	_apply(arm_right, rot["arm_right"])
	_apply(hand_left, rot["hand_left"])
	_apply(hand_right, rot["hand_right"])
	for leg_id: String in legs:
		var front: bool = not String(leg_id).begins_with("back")
		(legs[leg_id] as Node3D).rotation = Vector3(-leg_lift if front else 0.0, 0.0, 0.0)
	if tail != null:
		var wag: float = 9.0 if action == "bark" else 4.0
		tail.rotation = Vector3(0.0, sin(time_s * wag) * 0.6, 0.0)


## Falar: a boca abre e fecha nas sílabas, a cabeça balança e os braços
## gesticulam, um de cada vez; no grito, a cabeça vai para trás e os braços abrem.
func _talk(rot: Dictionary, dt: float) -> void:
	var k: float = clampf(dt * POSE_BLEND_PER_S, 0.0, 1.0)
	_talk_weight = lerpf(_talk_weight, 1.0 if talking else 0.0, k)
	var syllable: float = absf(sin(time_s * PI * TALK_SYLLABLE_HZ))
	if mouth != null:
		mouth.scale = Vector3(1.0, 1.0 + syllable * (MOUTH_OPEN_SCALE - 1.0) * _talk_weight, 1.0)
	if _talk_weight <= 0.0:
		return
	var beat: float = time_s * PI * TALK_SYLLABLE_HZ * 0.5
	var nod: float = sin(beat * 2.0) * TALK_NOD_RAD + (SHOUT_HEAD_RAD if shouting else 0.0)
	rot["head"].x += nod * _talk_weight
	var arm: float = SHOUT_ARM_RAD if shouting else TALK_ARM_RAD
	rot["arm_left"] += Vector3(-maxf(sin(beat), 0.0), 0.0, 0.0) * arm * _talk_weight
	rot["arm_right"] += Vector3(-maxf(-sin(beat), 0.0), 0.0, 0.0) * arm * _talk_weight


## Quem ouve vira a cabeça para quem fala (no lugar do olhar em volta).
func _look(rot: Dictionary, dt: float) -> void:
	var k: float = clampf(dt * LOOK_TURN_PER_S, 0.0, 1.0)
	_look_weight = lerpf(_look_weight, 0.0 if look_target == null else 1.0, k)
	if look_target != null:
		var local: Vector3 = global_transform.affine_inverse() * (look_target as Vector3)
		var wanted: float = clampf(atan2(local.x, local.z), -LOOK_MAX_RAD, LOOK_MAX_RAD)
		_look_yaw = lerpf(_look_yaw, wanted, k)
	rot["head"].y = lerpf(rot["head"].y, _look_yaw, _look_weight)


## Mistura a animação de sempre (rot) com a pose atual, peça por peça.
func _blend_pose(rot: Dictionary, dt: float) -> void:
	var k: float = clampf(dt * POSE_BLEND_PER_S, 0.0, 1.0)
	_pose_weight = lerpf(_pose_weight, 1.0 if POSES.has(pose) else 0.0, k)
	var targets: Dictionary = POSES.get(pose, {})
	for part: String in rot:
		var target: Vector3 = targets.get(part, rot[part])
		var current: Vector3 = _pose_rotation.get(part, rot[part])
		_pose_rotation[part] = current.lerp(target, k)
		rot[part] = (rot[part] as Vector3).lerp(_pose_rotation[part], _pose_weight)


static func _apply(part: Node3D, rotation_rad: Vector3) -> void:
	if part != null:
		part.rotation = rotation_rad
