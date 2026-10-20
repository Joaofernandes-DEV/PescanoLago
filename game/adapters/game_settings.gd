class_name GameSettings
extends RefCounted
## Adaptador: configurações do jogador (Fase 7, Bloco A), guardadas em
## user://settings.cfg, separadas do save do jogo. Os padrões, as resoluções, os
## limites de fps e os níveis de qualidade vêm de presentation.json (settings).
##
## Aplica: volume geral, da música e dos efeitos (barramentos de áudio), tela
## cheia ou janela e resolução, limite de fps e vsync, qualidade (sombras, SSAO e
## escala da renderização 3D) e as teclas principais dos comandos (InputSetup).

const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION: String = "settings"
const KEYS_SECTION: String = "keys"
const MUSIC_BUS: StringName = &"Music"
const EFFECTS_BUS: StringName = &"Effects"
const MASTER_BUS: StringName = &"Master"

var path: String
## Valores atuais (mesmas chaves de presentation.json, settings.defaults).
var values: Dictionary = {}
## Teclas principais escolhidas: {comando: tecla}. Vazio = as padrão.
var keys: Dictionary = {}

var _cfg: Dictionary


## cfg: presentation.json, settings.
func _init(cfg: Dictionary, p_path: String = DEFAULT_PATH) -> void:
	_cfg = cfg
	path = p_path
	values = (cfg["defaults"] as Dictionary).duplicate(true)


## Lê o arquivo; valores que faltam ou têm o tipo errado ficam no padrão. Com
## path vazio, as configurações só valem enquanto o jogo está aberto.
func load_file() -> void:
	var file := ConfigFile.new()
	if path.is_empty() or file.load(path) != OK:
		return
	var defaults: Dictionary = _cfg["defaults"]
	for key: String in defaults:
		var saved: Variant = file.get_value(SECTION, key, defaults[key])
		if typeof(saved) == typeof(defaults[key]) or _both_numbers(saved, defaults[key]):
			values[key] = saved
	keys.clear()
	for action: StringName in InputSetup.REBINDABLE:
		var keycode: Variant = file.get_value(KEYS_SECTION, String(action), KEY_NONE)
		if keycode is int and int(keycode) != KEY_NONE:
			keys[String(action)] = int(keycode)


func save_file() -> Error:
	if path.is_empty():
		return OK
	var file := ConfigFile.new()
	for key: String in values:
		file.set_value(SECTION, key, values[key])
	for action: String in keys:
		file.set_value(KEYS_SECTION, action, keys[action])
	return file.save(path)


func set_value(key: String, value: Variant) -> void:
	assert((_cfg["defaults"] as Dictionary).has(key), "Configuração desconhecida: %s" % key)
	values[key] = value


func quality() -> Dictionary:
	return _cfg["quality"][String(values["quality"])]


func quality_ids() -> Array:
	return (_cfg["quality"] as Dictionary).keys()


func quality_label(quality_id: String) -> String:
	return String(_cfg["quality"][quality_id]["label"])


func resolutions() -> Array:
	return _cfg["resolutions"]


func max_fps_options() -> Array:
	return _cfg["max_fps_options"]


## Guarda a tecla principal escolhida para o comando e a aplica.
func bind_key(action: StringName, keycode: int) -> void:
	InputSetup.bind_primary(action, keycode)
	keys = InputSetup.bindings()


func reset_keys() -> void:
	InputSetup.reset_bindings()
	keys.clear()


## Aplica tudo o que não depende da cena: áudio, janela, fps e teclas.
func apply_global() -> void:
	apply_audio()
	apply_display()
	apply_keys()


func apply_audio() -> void:
	ensure_buses()
	var volumes: Dictionary = {
		MASTER_BUS: "master_volume", MUSIC_BUS: "music_volume", EFFECTS_BUS: "effects_volume"
	}
	for bus: StringName in volumes:
		var linear: float = clampf(float(values[volumes[bus]]), 0.0, 1.0)
		var index: int = AudioServer.get_bus_index(bus)
		AudioServer.set_bus_mute(index, linear <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))


## Barramentos de música e efeitos (ligados ao geral), criados uma vez.
static func ensure_buses() -> void:
	for bus: StringName in [MUSIC_BUS, EFFECTS_BUS]:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, MASTER_BUS)


## Janela: tela cheia ou janela com a resolução escolhida (no navegador, só a
## tela cheia; o tamanho é o da página). Também o limite de fps e o vsync.
func apply_display() -> void:
	Engine.max_fps = int(values["max_fps"])
	if DisplayServer.get_name() == "headless":
		return
	if not OS.has_feature("web"):
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if bool(values["vsync"]) else DisplayServer.VSYNC_DISABLED
		)
	if bool(values["fullscreen"]):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if OS.has_feature("web"):
		return
	var size: Array = values["resolution"]
	var wanted := Vector2i(int(size[0]), int(size[1]))
	DisplayServer.window_set_size(wanted)
	var screen: Rect2i = DisplayServer.screen_get_usable_rect()
	DisplayServer.window_set_position(screen.position + (screen.size - wanted) / 2)


func apply_keys() -> void:
	InputSetup.reset_bindings()
	for action: String in keys:
		InputSetup.bind_primary(StringName(action), int(keys[action]))


## Qualidade na cena: sombras do sol, SSAO e escala da renderização 3D.
func apply_quality(scene: Node) -> void:
	var level: Dictionary = quality()
	for node in scene.find_children("*", "DirectionalLight3D", true, false):
		(node as DirectionalLight3D).shadow_enabled = bool(level["shadows"])
	for node in scene.find_children("*", "WorldEnvironment", true, false):
		var environment: Environment = (node as WorldEnvironment).environment
		if environment != null:
			environment.ssao_enabled = bool(level["ssao"])
	if scene.is_inside_tree():
		scene.get_viewport().scaling_3d_scale = float(level["render_scale"])


static func _both_numbers(a: Variant, b: Variant) -> bool:
	var numbers: Array[int] = [TYPE_INT, TYPE_FLOAT]
	return numbers.has(typeof(a)) and numbers.has(typeof(b))
