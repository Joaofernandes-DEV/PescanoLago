extends Node
## Fluxo do jogo: tela inicial → Porto Manso (hub) → dia de pesca → resultado →
## Porto Manso. O progresso é salvo em arquivo (SaveService) depois de cada dia e
## de cada compra, e carregado ao abrir o jogo. Esc abre o menu de pausa no hub e
## no dia (configurações, voltar à tela inicial, sair). As configurações do
## jogador (GameSettings) ficam num arquivo próprio.
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
##   --measure-day N         modo de medição de fps: abre direto o dia N do lago inteiro,
##                           sem save e com o contador de fps (na web: ?medir=N)
##   --skip-title            abre direto em Porto Manso, sem a tela inicial
##   --settings-file ARQUIVO arquivo das configurações (padrão: user://settings.cfg)
##   --dialogue ID           abre o palco dos balões com a conversa ID de dialogues.json
##                           (ou all: todas na ordem) e depois vai a Porto Manso (na web:
##                           ?dialogo=ID). Até as cutscenes, é onde as conversas aparecem
## Com --autoplay e sem --save-dir, o save do jogador não é lido nem gravado.
## Com --autoplay, --day, --measure-day ou --dialogue, a tela inicial não aparece.
## Sem save em arquivo do jogador (--no-save, --save-dir, --autoplay), as
## configurações também não são lidas nem gravadas, a não ser com --settings-file.

var db: ContentDB
var state: PlayerState
var pres: PresentationConfig
## null = sem save em arquivo.
var save: SaveService
var selected_day: int = 1
var hub: HubController
var current: DayController
var title: TitleScreen
var soundtrack: Soundtrack
var settings: GameSettings
var pause_menu: PauseMenu
var fps_overlay: FpsOverlay
var story: StoryContent
## Palco dos balões (--dialogue); null fora dele.
var stage: DialogueStage
## Preenchido antes de entrar na árvore (testes) ou lido da linha de comando.
var options: Dictionary = {}
var _days_played: int = 0
var _fps_samples: Array[float] = []
var _fps_clock: float = 0.0


func _ready() -> void:
	if options.is_empty():
		options = parse_args(OS.get_cmdline_user_args())
		if OS.has_feature("web"):
			var query: Variant = JavaScriptBridge.eval("window.location.search", true)
			options.merge(web_options(query if query is String else ""))
	if options.has("measure-day"):
		options.merge({"release": "full", "no-save": "true", "fps-overlay": "true"}, true)
	db = ContentLoader.load_dir(ContentLoader.DEFAULT_DIR, options.get("release", ""))
	story = ContentLoader.load_story()
	pres = PresentationConfig.load_default()
	save = _make_save_service()
	state = _load_or_new_game()
	selected_day = int(options.get("day", str(Progression.last_playable_day(db, state))))
	settings = GameSettings.new(pres.section("settings"), _settings_path())
	settings.load_file()
	settings.apply_global()
	soundtrack = Soundtrack.new()
	# A música continua no menu de pausa (dá para ouvir o volume mudando).
	soundtrack.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(soundtrack)
	_set_fps_overlay(FpsOverlay.wanted(options) or bool(settings.values["show_fps"]))
	pause_menu = PauseMenu.new()
	pause_menu.setup(settings)
	add_child(pause_menu)
	pause_menu.title_requested.connect(back_to_title)
	pause_menu.quit_requested.connect(_quit)
	pause_menu.settings_changed.connect(_on_settings_changed)
	# Medição de fps numa região (o celular não tem linha de comando nem save com
	# o barco melhorado): o dia pedido abre direto, sem passar por Porto Manso.
	if options.has("measure-day"):
		selected_day = clampi(int(options["measure-day"]), 1, db.day_count())
		_start_day()
		return
	if options.has("dialogue"):
		_show_stage(String(options["dialogue"]))
		return
	if options.has("autoplay") or options.has("day") or options.has("skip-title"):
		_show_hub()
		return
	_show_title()


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


## Opções que a build web lê do endereço da página (o celular não tem linha de
## comando): "?fps=1" liga o contador de fps, "?medir=N" abre o modo de medição e
## "?dialogo=ID" abre o palco dos balões.
static func web_options(search: String) -> Dictionary:
	var parsed: Dictionary = {}
	for pair in search.trim_prefix("?").split("&", false):
		var parts := pair.split("=")
		var value: String = parts[1] if parts.size() > 1 else ""
		if parts[0] == "fps" and value == "1":
			parsed["fps-overlay"] = "true"
		elif parts[0] == "medir" and value.is_valid_int():
			parsed["measure-day"] = value
		elif parts[0] == "dialogo" and not value.is_empty():
			parsed["dialogue"] = value
	return parsed


func _make_save_service() -> SaveService:
	if options.has("no-save"):
		return null
	if options.has("save-dir"):
		return SaveService.new(options["save-dir"])
	if options.has("autoplay"):
		return null
	return SaveService.new()


func _settings_path() -> String:
	if options.has("settings-file"):
		return String(options["settings-file"])
	if save == null or options.has("save-dir"):
		return ""
	return GameSettings.DEFAULT_PATH


func _load_or_new_game() -> PlayerState:
	if save == null:
		return PlayerState.new_game(db)
	if options.has("new-game"):
		save.erase()
		# Só ao abrir o jogo: voltar à tela inicial depois relê o save.
		options.erase("new-game")
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


# --- Tela inicial ---------------------------------------------------------


## Resumo do progresso salvo para a tela inicial ("" = nada salvo ainda).
func save_summary() -> String:
	if save == null or not save.has_save():
		return ""
	return "Dia %d - %d moedas" % [Progression.last_playable_day(db, state), state.coins]


func _show_title() -> void:
	title = TitleScreen.new()
	title.setup(db, state, pres, settings, save_summary())
	add_child(title)
	title.continue_requested.connect(_on_title_continue)
	title.new_game_requested.connect(_on_title_new_game)
	title.quit_requested.connect(_quit)
	title.ui.settings_panel.changed.connect(_on_settings_changed)
	_update_pause_menu()


func _leave_title() -> void:
	title.queue_free()
	title = null


func _on_title_continue() -> void:
	_leave_title()
	_show_hub()


func _on_title_new_game() -> void:
	if save != null:
		save.erase()
	state = PlayerState.new_game(db)
	selected_day = 1
	_leave_title()
	_show_hub()


## Volta à tela inicial pelo menu de pausa: o dia em andamento não conta, e o
## progresso volta a ser o do save (o que já foi salvo continua valendo).
func back_to_title() -> void:
	get_tree().paused = false
	for scene: Node in [hub, current, stage]:
		if scene != null:
			scene.queue_free()
	hub = null
	current = null
	stage = null
	state = _load_or_new_game()
	selected_day = Progression.last_playable_day(db, state)
	_show_title()


func _quit() -> void:
	_report_fps()
	get_tree().quit()


# --- Configurações --------------------------------------------------------


func _on_settings_changed(key: String) -> void:
	match key:
		"quality":
			for scene: Node in [title, hub, current, stage]:
				if scene != null:
					settings.apply_quality(scene)
		"show_fps":
			_set_fps_overlay(bool(settings.values["show_fps"]) or FpsOverlay.wanted(options))
		"show_hints":
			if current != null:
				current.show_hints = bool(settings.values["show_hints"])


func _set_fps_overlay(wanted: bool) -> void:
	if wanted and fps_overlay == null:
		fps_overlay = FpsOverlay.new()
		fps_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(fps_overlay)
	elif not wanted and fps_overlay != null:
		fps_overlay.queue_free()
		fps_overlay = null


## Esc só abre a pausa em Porto Manso, no dia e no palco dos balões; no dia,
## voltar à tela inicial avisa.
func _update_pause_menu() -> void:
	pause_menu.set_process_unhandled_input(hub != null or current != null or stage != null)
	pause_menu.in_day = current != null


# --- Palco dos balões -----------------------------------------------------


func _show_stage(wanted: String) -> void:
	stage = DialogueStage.new()
	stage.setup(
		story, DialogueStage.ids_for(story, wanted), pres, db, settings.balloon_chars_per_s()
	)
	stage.state = state
	stage.show_hints = bool(settings.values["show_hints"])
	add_child(stage)
	stage.stage_finished.connect(_on_stage_finished)
	settings.apply_quality(stage)
	_update_pause_menu()


func _on_stage_finished() -> void:
	print("DIALOGUE_STAGE_DONE %d" % stage.played)
	save_progress()
	if options.has("quit-at-end"):
		_quit()
		return
	stage.queue_free()
	stage = null
	_show_hub()


# --- Porto Manso e o dia --------------------------------------------------


func _show_hub() -> void:
	hub = HubController.new()
	hub.setup(db, state, pres, selected_day)
	if options.has("autoplay"):
		hub.autopilot = ShoppingPlan.for_release(db)
	add_child(hub)
	hub.play_requested.connect(_on_play_requested)
	hub.state_changed.connect(save_progress)
	settings.apply_quality(hub)
	_update_pause_menu()


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
	current.show_hints = bool(settings.values["show_hints"])
	add_child(current)
	current.day_finished.connect(_on_day_finished)
	current.hud.continue_pressed.connect(_on_continue)
	settings.apply_quality(current)
	_update_pause_menu()


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
