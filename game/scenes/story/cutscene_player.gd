class_name CutscenePlayer
extends Node
## Toca uma cutscene em passos (Fase 7, Bloco B, item 2; P-40) com os bonecos da
## cena: falar (a conversa de balões, DialoguePlayer), andar ou correr até um
## ponto (as pernas balançam e o corpo vira para onde vai), gestos do roteiro,
## câmera (corte ou movimento suave, olhando um ponto ou acompanhando os
## personagens), esperar e cartela (texto na tela escura). As posições vêm no
## espaço do ponto LOC_ do cenário (anchor), e quem anda segue a altura do chão
## (ground, a grade de alturas do terreno). A ordem e o tempo são do núcleo
## (Cutscene).
##
## Pular: segurar a tecla de pular (Tab, trocável) ou clicar em "Pular cena".
## Tudo vai para o lugar final: quem andava chega, a conversa acaba, a câmera
## fica no último enquadramento e as poses que ficam (hold) ficam.

signal finished
signal step_started(index: int, kind: String)

## Gestos que são ações curtas do boneco (o resto é pose).
const ACTIONS: PackedStringArray = ["bark", "wave", "cheer"]
const LOOK_AROUND: String = "look_around"
## Quão perto do ponto o personagem para de andar (metros).
const ARRIVE_M: float = 0.02
const SKIP_MARGIN_PX: float = 20.0

var cutscene: Cutscene
## Personagem (id) -> boneco na cena.
var cast: Dictionary = {}
var camera: Camera3D
## Ponto do cenário onde ficam as posições da cutscene.
var anchor: Transform3D
## Alturas do terreno (null = o chão é o plano do anchor).
var ground: LakeChart
## Conversa em andamento (null fora do passo de falar).
var dialogue: DialoguePlayer
var card: ColorRect
var card_label: Label
var skip_button: Button
var skip_bar: ProgressBar
## Testes chamam step(dt), press() e hold_skip(dt) em vez do _process e da entrada.
var external_stepping: bool = false
## Progresso das dicas (o save); null = sem dica nos balões.
var state: PlayerState
var show_hints: bool = true

var _story: StoryContent
var _cfg: Dictionary
var _dialogue_cfg: Dictionary
var _sfx: SfxPlayer
var _chars_per_s: float
var _show_until: int
var _talk_step: int = -1
## Passo de andar -> {"puppet", "to", "speed", "face"}.
var _walks: Dictionary = {}
## Boneco -> ângulo (radianos) para onde ele está virando.
var _turns: Dictionary = {}
var _camera_move: Dictionary = {}
var _look_point := Vector3.ZERO
## Cartela: {"step", "t", "seconds"}; vazio = sem cartela.
var _card: Dictionary = {}
var _skip_held_s: float = 0.0
var _done: bool = false


func setup(
	story: StoryContent,
	cutscene_data: Dictionary,
	p_cast: Dictionary,
	p_camera: Camera3D,
	p_anchor: Transform3D,
	sfx: SfxPlayer,
	pres: PresentationConfig,
	chars_per_s: float
) -> void:
	_story = story
	cutscene = Cutscene.new(cutscene_data)
	cast = p_cast
	camera = p_camera
	anchor = p_anchor
	_sfx = sfx
	_cfg = pres.section("cutscene")
	_dialogue_cfg = pres.section("dialogue")
	_chars_per_s = chars_per_s
	_show_until = int(pres.number("hints", "show_until_count"))
	_look_point = camera.global_position - camera.global_basis.z


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UiTheme.build()
	layer.add_child(ui)
	card = ColorRect.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.color = Color.html(String(_cfg["card_color"]))
	card.visible = false
	ui.add_child(card)
	card_label = Label.new()
	card_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_label.add_theme_font_size_override("font_size", int(_cfg["card_font_size"]))
	card_label.add_theme_color_override("font_color", Color.html(String(_cfg["card_text"])))
	card.add_child(card_label)
	var corner := VBoxContainer.new()
	corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE)
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	corner.position += Vector2(-SKIP_MARGIN_PX, SKIP_MARGIN_PX)
	ui.add_child(corner)
	skip_button = Button.new()
	skip_button.name = "SkipCutscene"
	skip_button.text = (
		"Pular cena (segure %s)"
		% InputSetup.key_label(InputSetup.primary_key(InputSetup.SKIP_CUTSCENE))
	)
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.pressed.connect(skip)
	corner.add_child(skip_button)
	skip_bar = ProgressBar.new()
	skip_bar.show_percentage = false
	skip_bar.max_value = 1.0
	skip_bar.custom_minimum_size = Vector2(0.0, 6.0)
	corner.add_child(skip_bar)


func _process(delta: float) -> void:
	if external_stepping:
		return
	hold_skip(delta if Input.is_action_pressed(InputSetup.SKIP_CUTSCENE) else 0.0)
	step(delta)


func step(dt: float) -> void:
	if _done:
		return
	var changes: Dictionary = cutscene.advance(dt)
	for index: int in changes["started"]:
		_start(index)
	for index: int in changes["ended"]:
		_end(index)
	_update_walks(dt)
	_update_turns(dt)
	_update_camera(dt)
	_update_card(dt)
	if dialogue != null and dialogue.external_stepping:
		dialogue.step(dt)
	if cutscene.finished:
		_finish()


## Segurando a tecla de pular por dt segundos (0 = soltou): a barra enche e,
## cheia, a cutscene pula.
func hold_skip(dt: float) -> void:
	if _done:
		return
	_skip_held_s = _skip_held_s + dt if dt > 0.0 else 0.0
	var needed: float = float(_cfg["skip_hold_s"])
	skip_bar.value = clampf(_skip_held_s / needed, 0.0, 1.0) if needed > 0.0 else 0.0
	if dt > 0.0 and _skip_held_s >= needed:
		skip()


## Clique na conversa em andamento (os testes; no jogo, o DialoguePlayer escuta).
func press() -> void:
	if dialogue != null:
		dialogue.press()


## Pula o resto: cada passo vai para o estado final e a cutscene acaba.
func skip() -> void:
	if _done:
		return
	for index in cutscene.skip():
		_finish_step(index)
	_finish()


func _start(index: int) -> void:
	var step_data: Dictionary = cutscene.step_at(index)
	var kind: String = String(step_data["type"])
	match kind:
		"talk":
			_start_talk(index, String(step_data["dialogue"]))
		"walk":
			var puppet: CharacterPuppet = cast[step_data["actor"]]
			var run: bool = bool(step_data.get("run", false))
			var speed: float = float(_cfg["run_speed_m_s" if run else "walk_speed_m_s"])
			puppet.walk_hz = speed * float(_cfg["steps_per_m"])
			_walks[index] = {
				"puppet": puppet,
				"to": _place(step_data["to"]),
				"speed": speed,
				"face": step_data.get("face_deg"),
			}
		"gesture":
			_start_gesture(step_data)
		"camera":
			_camera_move = {
				"from": camera.global_position,
				"to": anchor * _vector3(step_data["position"]),
				"from_look": _look_point,
				"look_at": step_data["look_at"],
				"t": 0.0,
				"seconds": float(step_data["seconds"]),
			}
			_update_camera(0.0)
		"card":
			_card = {"step": index, "t": 0.0, "seconds": float(step_data["seconds"])}
			card_label.text = String(step_data.get("text", ""))
			card.visible = true
			_update_card(0.0)
	step_started.emit(index, kind)


## Passo com tempo que acabou: o gesto sai (menos os que ficam) e a cartela some.
func _end(index: int) -> void:
	var step_data: Dictionary = cutscene.step_at(index)
	match String(step_data["type"]):
		"gesture":
			if not bool(step_data.get("hold", false)):
				_release_gesture(step_data)
		"card":
			_card = {}
			card.visible = false


func _start_talk(index: int, dialogue_id: String) -> void:
	_talk_step = index
	dialogue = DialoguePlayer.new()
	dialogue.setup(
		_story, dialogue_id, _chars_per_s, _dialogue_cfg, cast, camera, _sfx, _show_until
	)
	dialogue.state = state
	dialogue.show_hints = show_hints
	dialogue.external_stepping = external_stepping
	add_child(dialogue)
	dialogue.finished.connect(_on_talk_finished.bind(index))


func _on_talk_finished(index: int) -> void:
	dialogue.queue_free()
	dialogue = null
	_talk_step = -1
	cutscene.complete(index)


func _start_gesture(step_data: Dictionary) -> void:
	var puppet: CharacterPuppet = cast[step_data["actor"]]
	var gesture: String = String(step_data["gesture"])
	if ACTIONS.has(gesture):
		puppet.play(gesture)
		if gesture == "bark" and _sfx != null:
			_sfx.play("bark")
	elif gesture == LOOK_AROUND:
		puppet.looking_around = true
	else:
		puppet.pose = gesture
	if step_data.has("toward"):
		var target: Vector3 = _point_of(step_data["toward"])
		puppet.look_target = Vector3(target.x, puppet.head_top().y, target.z)
		var to_target: Vector3 = target - puppet.global_position
		_turns[puppet] = atan2(to_target.x, to_target.z)


func _release_gesture(step_data: Dictionary) -> void:
	var puppet: CharacterPuppet = cast[step_data["actor"]]
	var gesture: String = String(step_data["gesture"])
	if gesture == LOOK_AROUND:
		puppet.looking_around = false
	elif puppet.pose == gesture:
		puppet.pose = ""
	if step_data.has("toward"):
		puppet.look_target = null


## Estado final de um passo pulado.
func _finish_step(index: int) -> void:
	var step_data: Dictionary = cutscene.step_at(index)
	match String(step_data["type"]):
		"talk":
			if index == _talk_step and dialogue != null:
				dialogue.skip()
		"walk":
			var puppet: CharacterPuppet = cast[step_data["actor"]]
			puppet.global_position = _place(step_data["to"])
			puppet.walk_hz = 0.0
			if step_data.has("face_deg"):
				puppet.rotation.y = _yaw(float(step_data["face_deg"]))
			_walks.erase(index)
		"gesture":
			if bool(step_data.get("hold", false)):
				_start_gesture(step_data)
			else:
				_release_gesture(step_data)
		"camera":
			_camera_move = {
				"from": camera.global_position,
				"to": anchor * _vector3(step_data["position"]),
				"from_look": _look_point,
				"look_at": step_data["look_at"],
				"t": 0.0,
				"seconds": 0.0,
			}
		"card":
			_card = {}
			card.visible = false


func _finish() -> void:
	if _done:
		return
	_done = true
	_update_camera(0.0)
	for puppet: CharacterPuppet in _turns:
		puppet.rotation.y = float(_turns[puppet])
	_turns.clear()
	for puppet: CharacterPuppet in cast.values():
		puppet.walk_hz = 0.0
		puppet.looking_around = false
	skip_button.visible = false
	skip_bar.visible = false
	finished.emit()


func _update_walks(dt: float) -> void:
	var turn_k: float = clampf(dt * float(_cfg["turn_per_s"]), 0.0, 1.0)
	for index: int in _walks.keys():
		var walk: Dictionary = _walks[index]
		var puppet: CharacterPuppet = walk["puppet"]
		var to: Vector3 = walk["to"]
		var gap: Vector3 = to - puppet.global_position
		gap.y = 0.0
		var distance: float = gap.length()
		var move: float = float(walk["speed"]) * dt
		if distance <= maxf(move, ARRIVE_M):
			puppet.global_position = to
			puppet.walk_hz = 0.0
			if walk["face"] != null:
				_turns[puppet] = _yaw(float(walk["face"]))
			_walks.erase(index)
			cutscene.complete(index)
			continue
		puppet.global_position += gap / distance * move
		puppet.global_position.y = ground_height(puppet.global_position, to.y)
		var heading: float = atan2(gap.x, gap.z)
		puppet.rotation.y = lerp_angle(puppet.rotation.y, heading, turn_k)


func _update_turns(dt: float) -> void:
	var k: float = clampf(dt * float(_cfg["turn_per_s"]), 0.0, 1.0)
	for puppet: CharacterPuppet in _turns.keys():
		if _is_walking(puppet):
			continue
		puppet.rotation.y = lerp_angle(puppet.rotation.y, float(_turns[puppet]), k)
		if absf(angle_difference(puppet.rotation.y, float(_turns[puppet]))) < ARRIVE_M:
			_turns.erase(puppet)


func _is_walking(puppet: CharacterPuppet) -> bool:
	for walk: Dictionary in _walks.values():
		if walk["puppet"] == puppet:
			return true
	return false


## A câmera vai suave de onde está até a posição do passo, olhando o ponto ou
## acompanhando os personagens (mesmo depois de chegar).
func _update_camera(dt: float) -> void:
	if _camera_move.is_empty():
		return
	var seconds: float = float(_camera_move["seconds"])
	_camera_move["t"] = float(_camera_move["t"]) + dt
	var done: float = (
		1.0 if seconds <= 0.0 else clampf(float(_camera_move["t"]) / seconds, 0.0, 1.0)
	)
	var eased: float = smoothstep(0.0, 1.0, done)
	var look: Vector3 = (_camera_move["from_look"] as Vector3).lerp(
		_look_of(_camera_move["look_at"]), eased
	)
	camera.global_position = (_camera_move["from"] as Vector3).lerp(_camera_move["to"], eased)
	if not camera.global_position.is_equal_approx(look):
		camera.look_at(look, Vector3.UP)
	_look_point = look


## A cartela escurece a tela, mostra o texto e clareia de novo.
func _update_card(dt: float) -> void:
	if _card.is_empty():
		return
	_card["t"] = float(_card["t"]) + dt
	var seconds: float = float(_card["seconds"])
	var fade: float = minf(float(_cfg["card_fade_s"]), seconds / 3.0)
	var t: float = float(_card["t"])
	var alpha: float = 1.0
	if fade > 0.0:
		alpha = clampf(minf(t / fade, (seconds - t) / fade), 0.0, 1.0)
	card.modulate.a = alpha


## Onde a câmera olha: o ponto (espaço do anchor) ou o meio das cabeças.
func _look_of(spec: Array) -> Vector3:
	if spec[0] is String:
		var sum := Vector3.ZERO
		for actor: String in spec:
			sum += (cast[actor] as CharacterPuppet).head_top()
		return sum / float(spec.size()) + Vector3.DOWN * float(_cfg["look_below_head_m"])
	return anchor * _vector3(spec)


## Personagem (id) ou ponto [x, z] no chão (espaço do anchor).
func _point_of(target: Variant) -> Vector3:
	if target is String:
		return (cast[target] as CharacterPuppet).global_position
	return _place(target)


func _place(point: Array) -> Vector3:
	var flat: Vector3 = anchor * Vector3(float(point[0]), 0.0, float(point[1]))
	flat.y = ground_height(flat, flat.y)
	return flat


## Altura do chão no ponto (x, z); fora da grade, fallback.
func ground_height(point: Vector3, fallback: float) -> float:
	if ground == null:
		return fallback
	var height: float = ground.height_at(Vector2(point.x, point.z))
	return fallback if is_nan(height) else height


## Ângulo no mundo de quem olha face_deg graus a partir da frente do anchor.
func _yaw(face_deg: float) -> float:
	return atan2(anchor.basis.z.x, anchor.basis.z.z) + deg_to_rad(face_deg)


static func _vector3(point: Array) -> Vector3:
	return Vector3(float(point[0]), float(point[1]), float(point[2]))
