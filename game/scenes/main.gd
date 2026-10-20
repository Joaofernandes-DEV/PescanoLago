extends Node
## Fluxo do jogo: Porto Manso (hub) → dia de pesca → resultado → Porto Manso.
## O progresso é salvo em arquivo (SaveService) depois de cada dia e de cada
## compra, e carregado ao abrir o jogo.
##
## Argumentos opcionais (depois de "--" na linha de comando):
##   --autoplay              o piloto automático joga e compra (perfil skilled)
##   --bot casual|skilled    perfil do piloto automático
##   --time-scale N          acelera o tempo do jogo
##   --days N                com --autoplay, quantos dias jogar antes de parar
##   --quit-at-end           fecha o jogo ao terminar (teste de fumaça da build)
##   --seed N                semente dos dias
##   --day N                 dia já escolhido no mapa ao abrir
##   --fps-log               imprime a média de quadros por segundo ao fechar
##   --save-dir PASTA        pasta do save (padrão: user://saves)
##   --no-save               não lê nem grava o save
##   --new-game              apaga o save e começa do zero
##   --fps-overlay           mostra o contador de fps no canto (na web: ?fps=1)
##   --release PERFIL        perfil de release.json (padrão: o ativo, mvp). Com full, o
##                           lago inteiro, para testes: use outra --save-dir; região
##                           ainda sem cena própria usa a da Margem Rasa (P-32)
## Com --autoplay e sem --save-dir, o save do jogador não é lido nem gravado.

var db: ContentDB
var state: PlayerState
var pres: PresentationConfig
## null = sem save em arquivo.
var save: SaveService
var selected_day: int = 1
var hub: HubController
var current: DayController
var soundtrack: Soundtrack
## Preenchido antes de entrar na árvore (testes) ou lido da linha de comando.
var options: Dictionary = {}
var _days_played: int = 0
var _fps_samples: Array[float] = []
var _fps_clock: float = 0.0


func _ready() -> void:
	if options.is_empty():
		options = parse_args(OS.get_cmdline_user_args())
	db = ContentLoader.load_dir(ContentLoader.DEFAULT_DIR, options.get("release", ""))
	pres = PresentationConfig.load_default()
	save = _make_save_service()
	state = _load_or_new_game()
	selected_day = int(options.get("day", str(Progression.last_playable_day(db, state))))
	soundtrack = Soundtrack.new()
	add_child(soundtrack)
	if FpsOverlay.wanted(options):
		add_child(FpsOverlay.new())
	_show_hub()


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


func _make_save_service() -> SaveService:
	if options.has("no-save"):
		return null
	if options.has("save-dir"):
		return SaveService.new(options["save-dir"])
	if options.has("autoplay"):
		return null
	return SaveService.new()


func _load_or_new_game() -> PlayerState:
	if save == null:
		return PlayerState.new_game(db)
	if options.has("new-game"):
		save.erase()
	var loaded: PlayerState = save.load_state()
	if not save.last_error.is_empty():
		push_warning("Save: %s" % save.last_error)
	if loaded == null:
		return PlayerState.new_game(db)
	print(
		(
			"SAVE_LOADED %s"
			% (
				JSON
				. stringify(
					{
						"path": save.path(),
						"from": SaveService.Source.keys()[save.loaded_from],
						"coins": loaded.coins,
						"sessions_played": loaded.sessions_played,
						"unlocked_day": loaded.unlocked_day(db.day_count()),
						"best_stars": loaded.best_stars,
					}
				)
			)
		)
	)
	return loaded


func _process(delta: float) -> void:
	if not options.has("fps-log"):
		return
	_fps_clock += delta
	if _fps_clock >= 1.0:
		_fps_clock = 0.0
		_fps_samples.append(Engine.get_frames_per_second())


func _show_hub() -> void:
	hub = HubController.new()
	hub.setup(db, state, pres, selected_day)
	if options.has("autoplay"):
		hub.autopilot = ShoppingPlan.for_release(db)
	add_child(hub)
	hub.play_requested.connect(_on_play_requested)
	hub.state_changed.connect(save_progress)


func _on_play_requested(day_number: int) -> void:
	selected_day = day_number
	hub.queue_free()
	hub = null
	_start_day()


## A semente muda a cada dia jogado (sessions_played, guardado no save), então
## reabrir o jogo não repete a mesma sequência de peixes.
func _start_day() -> void:
	var run_index: int = state.sessions_played + 1
	var base_seed: int = int(options.get("seed", "2026"))
	current = DayController.new()
	current.setup(db, state, selected_day, base_seed + selected_day * 1000 + run_index, pres)
	if options.has("autoplay"):
		var bot_id: String = options.get("bot", "skilled")
		current.autopilot = AutoPilot.new(
			PlayerBot.new(db.bot_profile(bot_id), Rng.new(base_seed + run_index))
		)
		current.time_scale = float(options.get("time-scale", "1"))
	add_child(current)
	current.day_finished.connect(_on_day_finished)
	current.hud.continue_pressed.connect(_on_continue)


func _on_day_finished(result: Dictionary) -> void:
	_days_played += 1
	print("DAY_ENDED %s" % JSON.stringify(result))
	if int(result["stars"]) > 0 and selected_day < db.day_count():
		selected_day += 1
	save_progress()
	if not options.has("autoplay"):
		return
	if _days_played >= int(options.get("days", "1")):
		if options.has("quit-at-end"):
			_report_fps()
			get_tree().quit(0)
		return
	_on_continue.call_deferred()


func _on_continue() -> void:
	current.queue_free()
	current = null
	_show_hub()


func save_progress() -> void:
	if save == null:
		return
	if save.save(state):
		print("SAVE_WRITTEN %s" % save.path())


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
