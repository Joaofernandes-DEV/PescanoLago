class_name CharacterPuppet
extends Node3D
## Personagem do Blender animado por código (Fase 5). O modelo traz a cabeça,
## os braços e (no Bolota) a cauda como peças com a origem na articulação
## (SM_<id>_head, SM_<id>_arm_left/right, SM_bolota_tail); aqui elas giram.
##
## Sempre: respirar, olhar em volta e, no cão, abanar o rabo. Ações: carregar e
## soltar o lançamento (Tom), latir (Bolota), acenar (Marô e Zeca), comemorar.
## Só visual: avança por advance(dt).

const MODEL_PATH: String = "res://assets/models/characters/char_%s.glb"
const BREATH_HZ: float = 0.25
const LOOK_HZ: float = 0.07
const ACTION_S: float = 0.9

var character_id: String
var model: Node3D
var head: Node3D
var arm_left: Node3D
var arm_right: Node3D
var tail: Node3D
## Ação em andamento ("", "bark", "wave", "cheer") e quanto falta.
var action: String = ""
var action_left_s: float = 0.0
## 0 a 1 enquanto o Tom carrega o lançamento.
var cast_charge: float = 0.0
var time_s: float = 0.0

var _phase: float = 0.0
var _release_left_s: float = 0.0


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
	puppet.tail = puppet._part("tail")
	# Cada personagem respira e olha num ritmo um pouco diferente.
	puppet._phase = float(id.hash() % 1000) / 1000.0 * TAU
	return puppet


func _part(suffix: String) -> Node3D:
	return model.find_child("SM_%s_%s" % [character_id, suffix], true, false) as Node3D


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
	if head != null:
		head.rotation = Vector3(sin(t * 0.9) * 0.04, sin(t * TAU * LOOK_HZ) * 0.5, 0.0)
	var left := Vector3.ZERO
	var right := Vector3.ZERO
	match action:
		"bark":
			# Latido: a cabeça dá um tranco e o cão dá um pulinho.
			var pulse: float = sin(progress * PI * 3.0)
			if head != null:
				head.rotation.x = -absf(pulse) * 0.35
			model.position.y = absf(sin(progress * PI)) * 0.08
		"wave":
			right = Vector3(0.0, 0.0, -2.4 + sin(progress * PI * 6.0) * 0.35)
		"cheer":
			left = Vector3(0.0, 0.0, 2.2)
			right = Vector3(0.0, 0.0, -2.2)
			model.position.y = absf(sin(progress * PI * 2.0)) * 0.05
	if character_id == "tom":
		# Carregar o lançamento leva os braços para trás e para cima; soltar, para a frente.
		var back: float = -cast_charge * 1.1 + (_release_left_s / 0.35) * 0.6
		left.x += back
		right.x += back
	if arm_left != null:
		arm_left.rotation = left + Vector3(sin(t * 1.3) * 0.03, 0.0, 0.0)
	if arm_right != null:
		arm_right.rotation = right + Vector3(sin(t * 1.3 + 1.0) * 0.03, 0.0, 0.0)
	if tail != null:
		var wag: float = 9.0 if action == "bark" else 4.0
		tail.rotation = Vector3(0.0, sin(time_s * wag) * 0.6, 0.0)
