extends Node
## Fluxo do protótipo: dia de pesca → tela de resultado → próximo dia (ou repetir).
## O progresso fica só na memória até existir o save em arquivo (Fase 4).
##
## Argumentos opcionais (depois de "--" na linha de comando):
##   --autoplay              o piloto automático joga (perfil skilled)
##   --bot casual|skilled    perfil do piloto automático
##   --time-scale N          acelera o tempo do jogo
##   --days N                com --autoplay, quantos dias jogar antes de parar
##   --quit-at-end           fecha o jogo ao terminar (teste de fumaça da build)
##   --seed N                semente dos dias
##   --fps-log               imprime a média de quadros por segundo ao fechar

var db: ContentDB
var state: PlayerState
var pres: PresentationConfig
var day_number: int = 1
var current: DayController
var options: Dictionary = {}
var _days_played: int = 0
var _attempt: int = 0
var _fps_samples: Array[float] = []
var _fps_clock: float = 0.0


func _ready() -> void:
	options = parse_args(OS.get_cmdline_user_args())
	db = ContentLoader.load_dir()
	pres = PresentationConfig.load_default()
	state = PlayerState.new_game(db)
	day_number = int(options.get("day", "1"))
	_start_day()


static func parse_args(raw: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	var i := 0
	while i < raw.size():
		var key: String = raw[i].trim_prefix("--")
		if i + 1 < raw.size() and not raw[i + 1].begins_with("--"):
			parsed[key] = raw[i + 1]
			i += 2
		else:
			parsed[key] = "true"
			i += 1
	return parsed


func _process(delta: float) -> void:
	if not options.has("fps-log"):
		return
	_fps_clock += delta
	if _fps_clock >= 1.0:
		_fps_clock = 0.0
		_fps_samples.append(Engine.get_frames_per_second())


func _start_day() -> void:
	_restock_bait()
	_attempt += 1
	current = DayController.new()
	var base_seed: int = int(options.get("seed", "2026"))
	current.setup(db, state, day_number, base_seed + day_number * 1000 + _attempt, pres)
	if options.has("autoplay"):
		var bot_id: String = options.get("bot", "skilled")
		current.autopilot = AutoPilot.new(
			PlayerBot.new(db.bot_profile(bot_id), Rng.new(base_seed + _attempt))
		)
		current.time_scale = float(options.get("time-scale", "1"))
	add_child(current)
	current.day_finished.connect(_on_day_finished)
	current.hud.continue_pressed.connect(_on_continue)


## Protótipo sem loja (a loja é da Fase 4): Dona Marô repõe minhocas no começo do
## dia, se houver moedas, para o jogo não travar sem isca.
func _restock_bait() -> void:
	var shop := Shop.new(db)
	while state.bait_count(state.equipped_bait) < db.lot_size():
		if shop.buy_bait_lot(state, state.equipped_bait) != Shop.Status.OK:
			break


func _on_day_finished(result: Dictionary) -> void:
	_days_played += 1
	print("DAY_ENDED %s" % JSON.stringify(result))
	if not options.has("autoplay"):
		return
	if _days_played >= int(options.get("days", "1")):
		if options.has("quit-at-end"):
			_report_fps()
			get_tree().quit(0)
		return
	_on_continue.call_deferred()


func _on_continue() -> void:
	var result: Dictionary = current.session.result
	if int(result["stars"]) > 0 and day_number < db.day_count():
		day_number += 1
		_attempt = 0
	current.queue_free()
	_start_day()


func _report_fps() -> void:
	if _fps_samples.is_empty():
		return
	var total := 0.0
	for sample in _fps_samples:
		total += sample
	print(
		(
			"FPS_REPORT media=%.1f min=%.1f amostras=%d"
			% [total / _fps_samples.size(), _fps_samples.min(), _fps_samples.size()]
		)
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_report_fps()
