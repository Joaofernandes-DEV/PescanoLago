class_name Soundtrack
extends Node
## Trilha e ambiente provisórios (Fase 5): a música "Lago Aurora" (violão e flauta)
## e o ambiente da Margem Rasa (vento, água no casco, pássaros e sapos), em loop.
## Fica na cena principal, então não recomeça ao trocar Porto Manso pelo dia.
## A música vai pelo barramento de música e o ambiente pelo de efeitos (volumes
## das configurações, GameSettings).

const MUSIC: String = "res://assets/audio/music/lake_theme.wav"
const AMBIENCE: String = "res://assets/audio/music/margem_rasa_ambience.wav"
const MUSIC_DB: float = -11.0
const AMBIENCE_DB: float = -15.0

var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
## Sem placa de som (headless, driver "Dummy") nada toca, como no SfxPlayer.
var silent: bool = AudioServer.get_driver_name() == "Dummy"


func _ready() -> void:
	GameSettings.ensure_buses()
	music = _player(MUSIC, MUSIC_DB)
	music.bus = GameSettings.MUSIC_BUS
	ambience = _player(AMBIENCE, AMBIENCE_DB)
	ambience.bus = GameSettings.EFFECTS_BUS
	if not silent:
		music.play()
		ambience.play()


func _player(path: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = volume_db
	add_child(player)
	return player


## Loops tocando ao fechar o jogo deixariam o áudio preso na memória.
func _exit_tree() -> void:
	music.stop()
	ambience.stop()
