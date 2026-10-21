class_name StoryStage
extends Node3D
## Palco da história (Fase 7, Bloco B): Porto Manso ao amanhecer, com o Esperança
## atracado e o Tom e o Bolota a bordo, ouvindo. Toca cutscenes (CutscenePlayer)
## uma depois da outra; cada uma põe os atores nos lugares dela, em volta do ponto
## LOC_ do cenário (anchor). Uma conversa sozinha (--dialogue) vira uma cutscene
## simples: quem fala fica lado a lado em frente ao armazém (presentation.json,
## dialogue.preview_stage), com a câmera na frente.
##
## Abre com --cutscene ID (ou all) e --dialogue ID (ou all); na web, ?cena=ID e
## ?dialogo=ID. Até os dias do Bloco C, é por aqui que a história aparece no jogo.
## Quem ainda não tem modelo próprio usa o de outro personagem (stand_in).

signal stage_finished

var cutscenes: Array[Dictionary] = []
## Cutscene tocando agora (null entre uma e outra e no fim).
var current: CutscenePlayer
## Quantas cutscenes já terminaram.
var played: int = 0
## Quem está na cutscene atual (id -> boneco), com o Tom e o Bolota do barco.
var cast: Dictionary = {}
## O Tom e o Bolota no barco atracado.
var crew: Dictionary = {}
var camera: Camera3D
var sfx: SfxPlayer
var lighting: DayLighting
var water: LakeWater
var lake: Node3D
## Alturas do terreno por onde os atores andam.
var ground: LakeChart
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
var _actors: Array[CharacterPuppet] = []


func setup(
	story: StoryContent,
	p_cutscenes: Array[Dictionary],
	pres: PresentationConfig,
	db: ContentDB,
	chars_per_s: float
) -> void:
	_story = story
	cutscenes = p_cutscenes
	_pres = pres
	_db = db
	_chars_per_s = chars_per_s


## Cutscenes pedidas na linha de comando: um id, ou "all" para todas na ordem.
static func for_cutscenes(story: StoryContent, wanted: String) -> Array[Dictionary]:
	var ids: PackedStringArray = story.cutscene_ids()
	if story.has_cutscene(wanted):
		ids = PackedStringArray([wanted])
	elif wanted != "all" and wanted != "true":
		push_warning("Cutscene desconhecida: %s (tocando todas)" % wanted)
	var result: Array[Dictionary] = []
	for cutscene_id in ids:
		result.append(story.cutscene(cutscene_id))
	return result


## Conversas pedidas na linha de comando (um id ou "all"), cada uma como uma
## cutscene simples.
static func for_dialogues(
	story: StoryContent, wanted: String, pres: PresentationConfig
) -> Array[Dictionary]:
	var ids: PackedStringArray = story.dialogue_ids()
	if story.has_dialogue(wanted):
		ids = PackedStringArray([wanted])
	elif wanted != "all" and wanted != "true":
		push_warning("Diálogo desconhecido: %s (tocando todos)" % wanted)
	var result: Array[Dictionary] = []
	for dialogue_id in ids:
		result.append(dialogue_scene(story, dialogue_id, pres.section("dialogue")["preview_stage"]))
	return result


## A conversa como cutscene: quem fala lado a lado, cada um virado um pouco para
## o meio do grupo, e a câmera na frente, na altura dos olhos.
static func dialogue_scene(
	story: StoryContent, dialogue_id: String, view: Dictionary
) -> Dictionary:
	var speakers: PackedStringArray = story.speakers(dialogue_id)
	var forward: float = float(view["forward_m"])
	var actors: Array[Dictionary] = []
	for i in speakers.size():
		var offset: float = float(i) - float(speakers.size() - 1) / 2.0
		(
			actors
			. append(
				{
					"id": speakers[i],
					"at": [offset * float(view["spacing_m"]), forward],
					"face_deg": rad_to_deg(-signf(offset) * float(view["turn_rad"])),
				}
			)
		)
	var eye: float = float(view["height_m"])
	return {
		"id": "dialogue_%s" % dialogue_id,
		"day": int(story.dialogue(dialogue_id)["day"]),
		"scene": String(story.dialogue(dialogue_id)["scene"]),
		"anchor": String(view["spot"]),
		"actors": actors,
		"steps":
		[
			{
				"type": "camera",
				"position": [0.0, eye, forward + float(view["distance_m"])],
				"look_at": [0.0, float(view["look_height_m"]), forward],
				"seconds": 0.0,
			},
			{"type": "talk", "dialogue": dialogue_id},
		],
	}


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
	lake = LakeWorld.add_lake(self)
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
	crew = LakeWorld.add_crew(boat)
	var cfg: Dictionary = _pres.section("cutscene")
	var grid: Dictionary = _pres.section("minimap").duplicate()
	grid["chart_margin_m"] = cfg["ground_margin_m"]
	grid["chart_cell_m"] = cfg["ground_cell_m"]
	ground = LakeChart.from_lake(lake, grid, _pres.number("lake", "shore_radius_m"))
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = float(view["fov_deg"])
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
	if played >= cutscenes.size():
		stage_finished.emit()
		return
	_clear_actors()
	var data: Dictionary = cutscenes[played]
	var spot := lake.find_child(String(data["anchor"]), true, false) as Node3D
	var anchor: Transform3D = spot.global_transform
	cast = {}
	for actor: Dictionary in data["actors"]:
		# Sem juntar as peças: quem está na cutscene anda, gesticula e fala.
		var puppet := CharacterPuppet.create(_story.model_of(String(actor["id"])))
		add_child(puppet)
		var at: Array = actor["at"]
		puppet.global_position = anchor * Vector3(float(at[0]), 0.0, float(at[1]))
		var height: float = ground.height_at(
			Vector2(puppet.global_position.x, puppet.global_position.z)
		)
		if not is_nan(height):
			puppet.global_position.y = height
		puppet.rotation.y = (
			atan2(anchor.basis.z.x, anchor.basis.z.z) + deg_to_rad(float(actor["face_deg"]))
		)
		cast[String(actor["id"])] = puppet
		_actors.append(puppet)
	for id: String in crew:
		# O Bolota da cutscene sai do barco: o do barco some.
		(crew[id] as CharacterPuppet).visible = not cast.has(id)
		if not cast.has(id):
			cast[id] = crew[id]
	current = CutscenePlayer.new()
	current.setup(_story, data, cast, camera, anchor, sfx, _pres, _chars_per_s)
	current.ground = ground
	current.state = state
	current.show_hints = show_hints
	current.external_stepping = external_stepping
	add_child(current)
	current.finished.connect(_on_cutscene_finished)


func _on_cutscene_finished() -> void:
	played += 1
	current.queue_free()
	current = null
	_pause_left_s = float(_pres.section("dialogue")["preview_stage"]["end_pause_s"])
	if _pause_left_s <= 0.0:
		_start_next()


func _clear_actors() -> void:
	for puppet in _actors:
		puppet.queue_free()
	_actors.clear()
	cast = {}
