class_name DialoguePlayer
extends Node
## Toca uma conversa de balões (Fase 7, Bloco B; P-39) com os personagens da
## cena: o balão fica preso à cabeça de quem fala, o texto aparece na velocidade
## das configurações com a voz curta do personagem (uma sílaba a cada poucas
## letras, com a altura variando um pouco), a boca e o corpo de quem fala mexem e
## quem ouve vira a cabeça para ele. O clique (ou a tecla de ação) completa a fala
## ou passa para a próxima; a dica de como continuar some depois de algumas vezes.
## As cutscenes (item 2) usam o mesmo nó no passo de falar.

signal line_started(index: int, speaker: String)
signal finished

const HINT_ID: String = "dialogue_next"
## Semente da variação da voz: a mesma conversa soa sempre igual.
const VOICE_SEED: int = 7

var dialogue: Dialogue
var balloon: SpeechBalloon
var hint: ControlHints
## Quem fala (id de characters.json) -> boneco na cena.
var cast: Dictionary = {}
var camera: Camera3D
## Testes chamam step(dt) e press() em vez do _process e do clique.
var external_stepping: bool = false
## Progresso das dicas (o save); null = sem dica.
var state: PlayerState
var show_hints: bool = true
var touch_mode: bool = false

var _story: StoryContent
var _cfg: Dictionary
var _sfx: SfxPlayer
var _show_until: int = 0
var _letters_since_voice: int = 0
var _rng := RandomNumberGenerator.new()


## cfg: presentation.json, dialogue; show_until: hints.show_until_count.
func setup(
	story: StoryContent,
	dialogue_id: String,
	chars_per_s: float,
	cfg: Dictionary,
	p_cast: Dictionary,
	p_camera: Camera3D,
	sfx: SfxPlayer,
	show_until: int
) -> void:
	_story = story
	_cfg = cfg
	_sfx = sfx
	_show_until = show_until
	cast = p_cast
	camera = p_camera
	dialogue = Dialogue.new(story.dialogue(dialogue_id), chars_per_s)
	_rng.seed = VOICE_SEED


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	balloon = SpeechBalloon.new()
	balloon.setup(_cfg["balloon"])
	balloon.theme = UiTheme.build()
	layer.add_child(balloon)
	var bottom := MarginContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.add_theme_constant_override("margin_bottom", 28)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.theme = UiTheme.build()
	layer.add_child(bottom)
	hint = ControlHints.new()
	bottom.add_child(hint)
	_start_line()


func _process(delta: float) -> void:
	if not external_stepping:
		step(delta)


func _unhandled_input(event: InputEvent) -> void:
	if external_stepping or dialogue.finished:
		return
	var pressed: bool = event.is_action_pressed(InputSetup.ACTION) and not event.is_echo()
	if pressed or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed):
		touch_mode = event is InputEventScreenTouch
		get_viewport().set_input_as_handled()
		press()


func step(dt: float) -> void:
	if dialogue.finished:
		return
	var chunk: String = dialogue.advance(dt)
	_voice(Dialogue.letter_count(chunk))
	_animate()
	balloon.set_revealed(dialogue.revealed_count(), dialogue.is_line_complete())
	balloon.point_at(_anchor_on_screen())


## Clique do jogador: completa a fala, passa para a próxima ou termina.
func press() -> Dialogue.Press:
	var result: Dialogue.Press = dialogue.press()
	if result == Dialogue.Press.IGNORED:
		return result
	if state != null:
		state.tips_progress[HINT_ID] = state.tip_count(HINT_ID) + 1
	match result:
		Dialogue.Press.NEXT_LINE:
			_start_line()
		Dialogue.Press.FINISHED:
			_finish()
		_:
			_animate()
			balloon.set_revealed(dialogue.revealed_count(), true)
	_update_hint()
	return result


## Pula a conversa inteira (a cutscene foi pulada).
func skip() -> void:
	if dialogue.finished:
		return
	dialogue.skip()
	_finish()


func _start_line() -> void:
	_letters_since_voice = 0
	var speaker: String = dialogue.speaker()
	balloon.show_line(_story.character_name(speaker), dialogue.text(), dialogue.style())
	balloon.point_at(_anchor_on_screen())
	balloon.set_revealed(dialogue.revealed_count(), dialogue.is_line_complete())
	# A fala começa com a voz, mesmo com a velocidade instantânea.
	_play_voice()
	_animate()
	_update_hint()
	line_started.emit(dialogue.index, speaker)


func _finish() -> void:
	balloon.hide_balloon()
	hint.show_hint("", touch_mode)
	for puppet: CharacterPuppet in cast.values():
		puppet.talking = false
		puppet.shouting = false
		puppet.look_target = null
	finished.emit()


## Uma sílaba a cada voice_every_letters letras que aparecem.
func _voice(letters: int) -> void:
	if letters <= 0:
		return
	_letters_since_voice += letters
	var every: int = int(_cfg["voice_every_letters"])
	if _letters_since_voice >= every:
		_letters_since_voice %= every
		_play_voice()


func _play_voice() -> void:
	var voice: String = _story.voice_of(dialogue.speaker())
	if voice.is_empty() or _sfx == null:
		return
	var jitter: float = float(_cfg["voice_pitch_jitter"])
	var volume: float = float(_cfg["voice_db"][dialogue.style()])
	_sfx.play(voice, volume, 1.0 + _rng.randf_range(-jitter, jitter))


## Quem fala mexe a boca enquanto o texto aparece; os outros olham para ele.
func _animate() -> void:
	var speaker: String = dialogue.speaker()
	var talker: CharacterPuppet = cast.get(speaker)
	for id: String in cast:
		var puppet: CharacterPuppet = cast[id]
		puppet.talking = id == speaker and dialogue.is_typing()
		puppet.shouting = id == speaker and dialogue.style() == "shout"
		puppet.look_target = (
			null if id == speaker or talker == null else talker.head_top() as Variant
		)


## O alto da cabeça de quem fala, na tela (quem não está na cena: o meio da tela).
func _anchor_on_screen() -> Vector2:
	var talker: CharacterPuppet = cast.get(dialogue.speaker())
	var screen: Vector2 = balloon.get_viewport_rect().size
	if talker == null or camera == null:
		return screen / 2.0
	var top: Vector3 = talker.head_top()
	if camera.is_position_behind(top):
		return Vector2(screen.x / 2.0, 0.0)
	return camera.unproject_position(top)


func _update_hint() -> void:
	var wanted: bool = (
		show_hints
		and state != null
		and not dialogue.finished
		and ControlHints.still_needed(HINT_ID, state.tip_count(HINT_ID), _show_until)
	)
	hint.show_hint(HINT_ID if wanted else "", touch_mode)
