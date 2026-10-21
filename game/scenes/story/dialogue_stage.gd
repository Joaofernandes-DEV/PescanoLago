class_name DialogueStage
extends Node3D
## Palco de prévia dos balões (Fase 7, Bloco B, item 1): Porto Manso ao
## amanhecer, com quem fala lado a lado em frente ao armazém (presentation.json,
## dialogue.preview_stage) e o Tom e o Bolota no barco atracado, ouvindo. Abre
## com --dialogue ID, ou --dialogue all para todas as conversas na ordem (na web,
## ?dialogo=ID). Até as cutscenes (item 2) e os dias (Bloco C), é por aqui que as
## conversas aparecem no jogo. Quem ainda não tem modelo próprio usa o de outro
## personagem (characters.json, stand_in).

signal stage_finished

var dialogue_ids: PackedStringArray = []
## Conversa tocando agora (null entre uma e outra e no fim).
var current: DialoguePlayer
## Quantas conversas já terminaram.
var played: int = 0
## Personagem (id de characters.json) -> boneco no palco.
var cast: Dictionary = {}
var camera: Camera3D
var sfx: SfxPlayer
var lighting: DayLighting
var water: LakeWater
## Progresso das dicas (o save do jogador).
var state: PlayerState
var show_hints: bool = true
## Testes chamam step(dt) em vez do _process.
var external_stepping: bool = false

var _story: StoryContent
var _pres: PresentationConfig
var _db: ContentDB
var _chars_per_s: float
var _pause_left_s: float = 0.0


func setup(
	story: StoryContent,
	ids: PackedStringArray,
	pres: PresentationConfig,
	db: ContentDB,
	chars_per_s: float
) -> void:
	_story = story
	dialogue_ids = ids
	_pres = pres
	_db = db
	_chars_per_s = chars_per_s


## Ids pedidos na linha de comando: um id, ou "all" para todos na ordem do arquivo.
static func ids_for(story: StoryContent, wanted: String) -> PackedStringArray:
	if wanted == "all" or wanted == "true":
		return story.dialogue_ids()
	if story.has_dialogue(wanted):
		return PackedStringArray([wanted])
	push_warning("Diálogo desconhecido: %s (tocando todos)" % wanted)
	return story.dialogue_ids()


func _ready() -> void:
	sfx = SfxPlayer.new()
	add_child(sfx)
	_build_world()
	_start_next()


func _build_world() -> void:
	var view: Dictionary = _pres.section("dialogue")["preview_stage"]
	lighting = DayLighting.new()
	add_child(lighting)
	lighting.setup(_pres, _db.economy["day_phases"])
	lighting.apply(lighting.phase_time(String(view["light_phase"])))
	var lake: Node3D = LakeWorld.add_lake(self)
	water = LakeWorld.add_water(self, _pres)
	water.set_sky_color(lighting.horizon_color())
	var boat := BoatController.new()
	add_child(boat)
	boat.set_model(load(LakeWorld.BOAT_SCENE))
	boat.setup(_pres.section("navigation"), 1.0, _pres.number("lake", "boat_limit_radius_m"))
	boat.water = water
	var berth := LakeWorld.locator(lake, "LOC_dock_berth")
	boat.position = Vector3(berth.x, 0.0, berth.z)
	boat.rotation.y = atan2(-berth.x, -berth.z)
	cast = LakeWorld.add_crew(boat)
	var speakers: PackedStringArray = []
	for dialogue_id in dialogue_ids:
		for speaker in _story.speakers(dialogue_id):
			if not speakers.has(speaker) and not cast.has(speaker):
				speakers.append(speaker)
	var spot := lake.find_child(String(view["spot"]), true, false) as Node3D
	var facing: Vector3 = spot.global_basis.z
	var side: Vector3 = spot.global_basis.x
	var center: Vector3 = spot.global_position + facing * float(view["forward_m"])
	for i in speakers.size():
		# Lado a lado, cada um virado um pouco para o meio do grupo.
		var offset: float = float(i) - float(speakers.size() - 1) / 2.0
		var puppet := CharacterPuppet.create(_story.model_of(speakers[i]))
		puppet.merge_still_parts(true)
		add_child(puppet)
		puppet.place_at(spot)
		puppet.global_position = center + side * offset * float(view["spacing_m"])
		puppet.rotate_y(-signf(offset) * float(view["turn_rad"]))
		cast[speakers[i]] = puppet
	_place_camera(center, facing, view)


## Câmera na frente do grupo, na altura dos olhos.
func _place_camera(center: Vector3, facing: Vector3, view: Dictionary) -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = float(view["fov_deg"])
	camera.position = (
		center + facing * float(view["distance_m"]) + Vector3.UP * float(view["height_m"])
	)
	camera.look_at(center + Vector3.UP * float(view["look_height_m"]), Vector3.UP)
	camera.make_current()


func _process(delta: float) -> void:
	if not external_stepping:
		step(delta)


func step(dt: float) -> void:
	water.advance(dt)
	for puppet: CharacterPuppet in cast.values():
		puppet.advance(dt)
	if current != null:
		if current.external_stepping:
			current.step(dt)
		return
	if _pause_left_s > 0.0:
		_pause_left_s -= dt
		if _pause_left_s <= 0.0:
			_start_next()


func _start_next() -> void:
	if played >= dialogue_ids.size():
		stage_finished.emit()
		return
	current = DialoguePlayer.new()
	current.setup(
		_story,
		dialogue_ids[played],
		_chars_per_s,
		_pres.section("dialogue"),
		cast,
		camera,
		sfx,
		int(_pres.number("hints", "show_until_count"))
	)
	current.state = state
	current.show_hints = show_hints
	current.external_stepping = external_stepping
	add_child(current)
	current.finished.connect(_on_dialogue_finished)


func _on_dialogue_finished() -> void:
	played += 1
	current.queue_free()
	current = null
	_pause_left_s = float(_pres.section("dialogue")["preview_stage"]["end_pause_s"])
	if _pause_left_s <= 0.0:
		_start_next()
