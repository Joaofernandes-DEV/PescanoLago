class_name TitleScreen
extends Node3D
## Tela inicial (Fase 7, Bloco A): o lago da Margem Rasa ao amanhecer, com o
## Esperança no cais, as garças e a câmera dando uma volta lenta em torno do
## lago, olhando a margem à frente (presentation.json, title), e a interface por
## cima (TitleUi).
## Reaproveita o cenário de Porto Manso: não carrega nada novo.

signal continue_requested
signal new_game_requested
signal quit_requested

var ui: TitleUi
var lighting: DayLighting
var camera: Camera3D
var water: LakeWater
var birds: Birds
var boat: BoatController
var time_s: float = 0.0

var _pres: PresentationConfig
var _db: ContentDB
var _state: PlayerState
var _settings: GameSettings
var _save_summary: String


## state: o progresso salvo (ou um jogo novo, só para o barco do cais).
## save_summary: "" quando não há progresso salvo.
func setup(
	db: ContentDB,
	state: PlayerState,
	pres: PresentationConfig,
	settings: GameSettings,
	save_summary: String
) -> void:
	_db = db
	_state = state
	_pres = pres
	_settings = settings
	_save_summary = save_summary


func _ready() -> void:
	_build_world()
	ui = TitleUi.new()
	ui.setup(_settings, _save_summary)
	add_child(ui)
	ui.continue_requested.connect(continue_requested.emit)
	ui.new_game_requested.connect(new_game_requested.emit)
	ui.quit_requested.connect(quit_requested.emit)
	ui.settings_panel.changed.connect(_on_settings_changed)
	_settings.apply_quality(self)


func _build_world() -> void:
	var cfg: Dictionary = _pres.section("title")
	lighting = DayLighting.new()
	add_child(lighting)
	lighting.setup(_pres, _db.economy["day_phases"])
	lighting.apply(lighting.phase_time(cfg["light_phase"]))
	var lake: Node3D = LakeWorld.add_lake(self)
	water = LakeWorld.add_water(self, _pres)
	birds = LakeWorld.add_birds(self, _pres)
	water.set_sky_color(lighting.horizon_color())
	var berth := LakeWorld.locator(lake, "LOC_dock_berth")
	boat = BoatController.new()
	add_child(boat)
	boat.set_model(load(LakeWorld.BOAT_SCENE))
	boat.setup(_pres.section("navigation"), 1.0, _pres.number("lake", "boat_limit_radius_m"))
	boat.water = water
	BoatLooks.apply(boat.model, _state, _db)
	boat.position = Vector3(berth.x, 0.0, berth.z)
	var to_center := Vector3(-berth.x, 0.0, -berth.z).normalized()
	boat.rotation.y = atan2(to_center.x, to_center.z)
	camera = Camera3D.new()
	add_child(camera)
	camera.make_current()
	advance(0.0)


func _process(delta: float) -> void:
	advance(delta)


## Câmera em volta do lago, água, garças e o barco boiando no cais.
func advance(dt: float) -> void:
	time_s += dt
	var cfg: Dictionary = _pres.section("title")
	var angle: float = TAU * time_s / float(cfg["orbit_period_s"])
	var radius: float = float(cfg["orbit_radius_m"])
	camera.position = Vector3(
		cos(angle) * radius, float(cfg["orbit_height_m"]), sin(angle) * radius
	)
	# Olha para a margem um pouco à frente na volta: a vila, as árvores e os morros
	# passam devagar, com a água em primeiro plano.
	var ahead: float = angle + float(cfg["look_ahead_rad"])
	var shore: float = float(cfg["look_radius_m"])
	camera.look_at(
		Vector3(cos(ahead) * shore, float(cfg["look_height_m"]), sin(ahead) * shore), Vector3.UP
	)
	water.advance(dt)
	birds.advance(dt)
	boat.step(dt)
	water.set_hull(boat.model, 0.0)


func _on_settings_changed(key: String) -> void:
	if key == "quality":
		_settings.apply_quality(self)
