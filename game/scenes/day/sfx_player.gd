class_name SfxPlayer
extends Node
## Toca os efeitos sonoros provisórios (game/assets/audio/sfx) e os loops de
## ambiente e motor, todos no barramento de efeitos (volume das configurações).
## As vozes curtas dos balões de fala (voice_<personagem>, Fase 7) também.

const SFX_DIR: String = "res://assets/audio/sfx/%s.wav"
const ONE_SHOTS: PackedStringArray = [
	"cast_whoosh",
	"splash",
	"bite_plop",
	"bark",
	"hook_set",
	"reel_tick",
	"line_snap",
	"catch_jingle",
	"day_end_chime",
	"ui_click",
	"hull_bump",
	"sonar_ping",
	"voice_grandpa",
	"voice_grandma",
	"voice_cleusa",
	"voice_ze_barranco",
]

## Sons pedidos até agora (para testes e depuração).
var played: Array[String] = []
## Sem placa de som (modo headless, driver "Dummy") nada é tocado: o driver nunca
## processa o áudio e os sons iniciados ficariam presos na memória ao fechar.
var silent: bool = AudioServer.get_driver_name() == "Dummy"
var _players: Dictionary = {}
var _engine: AudioStreamPlayer
var _ambience: AudioStreamPlayer


func _ready() -> void:
	GameSettings.ensure_buses()
	for sound in ONE_SHOTS:
		var player := AudioStreamPlayer.new()
		player.stream = load(SFX_DIR % sound)
		player.bus = GameSettings.EFFECTS_BUS
		add_child(player)
		_players[sound] = player
	_engine = _loop("engine_loop", -14.0)
	_ambience = _loop("water_ambience", -10.0)


func _loop(sound: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(SFX_DIR % sound)
	player.volume_db = volume_db
	player.bus = GameSettings.EFFECTS_BUS
	add_child(player)
	return player


## Loops ainda tocando ao fechar o jogo deixam o áudio preso na memória (vazamento).
func _exit_tree() -> void:
	stop_loops()


func start_loops() -> void:
	if silent:
		return
	_ambience.play()
	_engine.play()


func stop_loops() -> void:
	_ambience.stop()
	_engine.stop()


## pitch: altura do som (1 = a gravada); a voz dos balões varia a cada sílaba.
func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	played.append(sound)
	if silent:
		return
	var player: AudioStreamPlayer = _players[sound]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


## Motor mais alto e agudo quanto mais rápido o barco (0 a 1).
func set_engine_load(load_fraction: float) -> void:
	_engine.pitch_scale = lerpf(0.8, 1.4, clampf(load_fraction, 0.0, 1.0))
	_engine.volume_db = lerpf(-22.0, -8.0, clampf(load_fraction, 0.0, 1.0))
