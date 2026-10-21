class_name DayController
extends Node3D
## Cena de um dia de pesca. Liga o DaySession (regras, núcleo puro) ao mundo 3D,
## à entrada do jogador e à interface. Não tem regra de jogo própria: traduz a
## posição do barco e os botões em comandos (reach_school, cast, hook,
## set_reeling, arrive_at_dock...) e mostra os eventos que a sessão devolve.
## Orienta o jogador com dicas de controle, o medidor de força e o alvo na água.
## O peixe pego sai da água no passaguá e vai para a caixa de isopor (LandingShow,
## CoolerBox), que uma tecla abre para ver os peixes com o nome e o peso. O mapa
## é uma carta náutica do cenário (LakeChart) com o sonar varrendo em volta do
## barco (ping a cada cardume achado); outra tecla abre o mapa grande.
## Com on_foot (Fase 7, Bloco B, item 3), o dia começa a pé no sítio dos avós: o
## Tom anda até o barco amarrado no cais e embarca (OnFoot); o relógio do dia só
## corre depois do embarque.

signal day_finished(result: Dictionary)

const MAX_STEP_S: float = 0.05
const REEL_TICK_S: float = 0.12
const PHASE_NAMES: Dictionary = {
	"dawn": "Amanhecer", "day": "Dia", "dusk": "Entardecer", "night": "Noite"
}
## Ação feita pelo jogador -> dicas que ela ensina (as dicas somem com o uso).
## Destaque das variantes na mensagem da pesca.
const VARIANT_TEXT: Dictionary = {"albino": " ALBINO!", "golden": " DOURADO!"}
const TIPS_BY_EVENT: Dictionary = {
	"school_found": ["steer"],
	"cast": ["cast_hold", "cast_release", "open_water", "open_water_release"],
	"hooked": ["hook_tap"],
	"caught": ["reel_hold"],
}

## Entrada virtual, preenchida pelo jogador (teclado, mouse, toque) ou pelo piloto automático.
var input_throttle: float = 0.0
var input_steer: float = 0.0
var input_action_held: bool = false
var input_aim_point := Vector3.ZERO
## null = jogador humano.
var autopilot: AutoPilot
## Testes avançam a cena chamando step(dt) e desligam o _process.
var external_stepping: bool = false
var time_scale: float = 1.0

var session: DaySession
var boat: BoatController
var camera: FollowCamera
var lighting: DayLighting
var rig: FishingRig
var sfx: SfxPlayer
var hud: DayHud
var schools: SchoolField
var water: LakeWater
var marker: AimMarker
var fish_shadow: FishShadow
## O Tom tira o peixe com o passaguá, mostra e guarda na caixa (só visual).
var landing: LandingShow
## A caixa de isopor do barco, o visual do viveiro (P-37).
var cooler: CoolerBox
## A vista de dentro da caixa está aberta (tecla InputSetup.COOLER_VIEW).
var cooler_view_open: bool = false
## O mapa grande está aberto (tecla InputSetup.MAP_VIEW).
var map_view_open: bool = false
## O jogador está usando a tela de toque (muda as dicas de controle).
var touch_mode: bool = false
## Dicas de controle ligadas (configurações). Os avisos da situação (chegar perto,
## voltar ao cais) aparecem sempre.
var show_hints: bool = true
var birds: Birds
## Começar a pé no sítio (só onde o cenário tem LOC_walk_start; nunca no piloto automático).
var on_foot: bool = false
## O Tom a pé até o barco (null = o dia começou no barco).
var walker: OnFoot
var animals: Animals
var buoys: Buoys
## Região do dia (days.json); o cenário é o dela ou, sem cena ainda, o da Margem Rasa.
var region_id: String = LakeWorld.HOME_REGION
## Personagens: tom e bolota no barco; zeca e maro só no cenário de Porto Manso.
var characters: Dictionary = {}
var dock_point := Vector3.ZERO
var engaged_school: int = -1
var cast_charge: float = 0.0
var events_seen: Array[Dictionary] = []

var _db: ContentDB
var _state: PlayerState
var _pres: PresentationConfig
var _day_number: int
var _seed: int
var _charging: bool = false
var _prev_action_held: bool = false
var _cast_distance_m: float = 0.0
var _docked_here: bool = false
var _finished: bool = false
var _reel_tick_s: float = 0.0
var _gear: Loadout


func setup(
	db: ContentDB, state: PlayerState, day_number: int, seed_value: int, pres: PresentationConfig
) -> void:
	_db = db
	_state = state
	_day_number = day_number
	_seed = seed_value
	_pres = pres


func _ready() -> void:
	InputSetup.ensure_actions()
	lighting = DayLighting.new()
	add_child(lighting)
	lighting.setup(_pres, _db.economy["day_phases"])
	region_id = String(_db.day(_day_number)["region"])
	var lake: Node3D = LakeWorld.add_lake(self, region_id)
	water = LakeWorld.add_water(self, _pres, region_id)
	birds = LakeWorld.add_birds(self, _pres)
	buoys = LakeWorld.add_buoys(lake, _pres, water)
	animals = LakeWorld.add_animals(lake, _pres, water)
	boat = BoatController.new()
	add_child(boat)
	boat.set_model(load(LakeWorld.BOAT_SCENE))
	BoatLooks.apply(boat.model, _state, _db)
	var motor: Dictionary = _db.upgrade_level("motor", _state.level_of("motor"))
	boat.setup(
		_pres.section("navigation"),
		float(motor["speed_factor"]),
		_pres.number("lake", "boat_limit_radius_m")
	)
	boat.water = water
	boat.bumped.connect(_on_boat_bumped)
	boat.obstacles = LakeWorld.obstacles(lake)
	characters = LakeWorld.add_villagers(lake).merged(LakeWorld.add_crew(boat))
	var start := LakeWorld.locator(lake, "LOC_boat_start")
	dock_point = LakeWorld.locator(lake, "LOC_dock_berth")
	boat.global_position = Vector3(start.x, 0.0, start.z)
	var to_center := -Vector2(start.x, start.z)
	boat.rotation.y = atan2(to_center.x, to_center.y)
	camera = FollowCamera.new()
	add_child(camera)
	camera.setup(_pres.section("camera"), boat)
	camera.make_current()
	if on_foot and autopilot == null and lake.find_child("LOC_walk_start", true, false) != null:
		_start_on_foot(lake)
	rig = FishingRig.new()
	rig.setup(_pres.section("fish"))
	add_child(rig)
	rig.landed.connect(_on_bait_landed)
	marker = AimMarker.new()
	marker.water = water
	add_child(marker)
	fish_shadow = FishShadow.new()
	fish_shadow.setup(_pres.section("casting"), water)
	add_child(fish_shadow)
	cooler = CoolerBox.attach(boat.model, _db, _pres.section("landing"), _pres.section("fish"))
	landing = LandingShow.new()
	(
		landing
		. setup(
			_pres.section("landing"),
			_pres.section("fish"),
			{
				"boat_model": boat.model,
				"tom": characters["tom"],
				"cooler": cooler,
				"camera": camera,
				"rig": rig,
			}
		)
	)
	boat.model.add_child(landing)
	touch_mode = DisplayServer.is_touchscreen_available()
	sfx = SfxPlayer.new()
	add_child(sfx)
	sfx.start_loops()
	hud = DayHud.new()
	add_child(hud)
	schools = SchoolField.new(_pres.section("schools"), Rng.new(_seed + 1))
	schools.populate(boat.global_position)
	session = DaySession.new(_db, _state, _day_number, Rng.new(_seed), {"manual_navigation": true})
	_gear = Loadout.new(_db, _state)
	hud.setup_map(
		_pres.section("minimap"), _pres.number("lake", "shore_radius_m"), dock_point, boat.obstacles
	)
	hud.mini_map.water_color = PresentationConfig.color(
		LakeWorld.looks(_pres, region_id)["map_water"]
	)
	hud.mini_map.set_chart(
		LakeChart.from_lake(lake, _pres.section("minimap"), _pres.number("lake", "shore_radius_m"))
	)
	hud.mini_map.title = String(_db.region(region_id)["name"])
	_update_hud()


## O último aparelho usado decide as dicas: toque ou teclado. O mouse não conta,
## porque a Godot também gera mouse a partir do toque.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touch_mode = true
	elif event is InputEventKey:
		touch_mode = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or _finished:
		return
	if event.is_action_pressed(InputSetup.COOLER_VIEW):
		toggle_cooler_view()
	elif event.is_action_pressed(InputSetup.MAP_VIEW):
		toggle_map_view()


func _process(delta: float) -> void:
	if external_stepping or _finished:
		return
	if autopilot == null:
		_read_player_input()
	var remaining: float = delta * time_scale
	while remaining > 0.0 and not _finished:
		var dt: float = minf(remaining, MAX_STEP_S)
		step(dt)
		remaining -= dt


func _read_player_input() -> void:
	input_throttle = clampf(
		Input.get_axis(InputSetup.MOVE_BACK, InputSetup.MOVE_FORWARD) - hud.joystick.value.y,
		-1.0,
		1.0
	)
	input_steer = clampf(
		Input.get_axis(InputSetup.TURN_LEFT, InputSetup.TURN_RIGHT) + hud.joystick.value.x,
		-1.0,
		1.0
	)
	input_action_held = Input.is_action_pressed(InputSetup.ACTION)
	var mouse := get_viewport().get_mouse_position()
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(
		camera.project_ray_origin(mouse), camera.project_ray_normal(mouse)
	)
	if hit != null:
		input_aim_point = hit


## Começo a pé: o barco amarrado no cais do sítio, de proa para o lago, e o Tom e
## o Bolota do barco escondidos até o embarque.
func _start_on_foot(lake: Node3D) -> void:
	var berth := LakeWorld.locator(lake, "LOC_sitio_berth")
	boat.global_position = Vector3(berth.x, 0.0, berth.z)
	boat.rotation.y = atan2(-berth.x, -berth.z)
	for id: String in ["tom", "bolota"]:
		(characters[id] as CharacterPuppet).visible = false
	var cfg: Dictionary = _pres.section("walk")
	var grid: Dictionary = _pres.section("minimap").duplicate()
	grid["chart_margin_m"] = cfg["ground_margin_m"]
	grid["chart_cell_m"] = cfg["ground_cell_m"]
	walker = OnFoot.new()
	walker.setup(
		cfg, lake, boat, LakeChart.from_lake(lake, grid, _pres.number("lake", "shore_radius_m"))
	)
	add_child(walker)
	walker.start(lake.find_child("LOC_walk_start", true, false) as Node3D)
	walker.boarded.connect(_on_boarded)
	camera.close_up(walker.camera_eye(), walker.camera_look())
	camera.close_weight = 1.0


func _on_boarded() -> void:
	for id: String in ["tom", "bolota"]:
		(characters[id] as CharacterPuppet).visible = true
	camera.release_close_up()
	sfx.play("hull_bump")


## A pé: as teclas de pilotar andam, para os lados da câmera; a ação embarca.
func _step_on_foot(dt: float) -> void:
	var yaw: float = walker.camera_yaw
	var forward := Vector2(sin(yaw), cos(yaw))
	var right := Vector2(-cos(yaw), sin(yaw))
	var move: Vector2 = (forward * input_throttle + right * input_steer).limit_length(1.0)
	var pressed: bool = input_action_held and not _prev_action_held
	_prev_action_held = input_action_held
	walker.step(dt, move, pressed)
	if walker.stage == OnFoot.Stage.DONE:
		return
	camera.close_up(walker.camera_eye(), walker.camera_look())
	camera.step(dt)
	boat.throttle = 0.0
	boat.steer = 0.0
	boat.step(dt)
	lighting.apply(session.clock.elapsed_s)
	for scenery: Variant in [water, birds, buoys, animals]:
		scenery.advance(dt)
	for puppet: CharacterPuppet in characters.values():
		puppet.advance(dt)
	var hint: String = "board" if walker.can_board() else "walk"
	if walker.stage != OnFoot.Stage.WALKING or not show_hints:
		hint = ""
	hud.hints.show_hint(hint, touch_mode)


## Um passo da cena: piloto (se houver) → barco → botões → regras → eventos → visual.
func step(dt: float) -> void:
	if _finished:
		return
	if walker != null and walker.stage != OnFoot.Stage.DONE:
		_step_on_foot(dt)
		return
	if autopilot != null:
		autopilot.drive(self, dt)
	_update_boat(dt)
	_update_fishing_input(dt)
	session.tick(dt)
	_update_schools()
	_update_dock()
	_handle_events()
	_update_visuals(dt)
	_update_hud()
	if session.is_over():
		_finish()


func _fishing_stage() -> bool:
	return session.stage not in [DaySession.Stage.SEARCHING, DaySession.Stage.AT_SCHOOL]


func _update_boat(dt: float) -> void:
	var anchored: bool = _fishing_stage()
	boat.throttle = 0.0 if anchored else input_throttle
	boat.steer = 0.0 if anchored else input_steer
	boat.step(dt)
	var stopped_speed: float = _pres.number("navigation", "stopped_speed_m_s")
	if session.stage == DaySession.Stage.AT_SCHOOL and not boat.is_stopped(stopped_speed):
		session.leave_school()
		engaged_school = -1


func _update_fishing_input(dt: float) -> void:
	var pressed_now: bool = input_action_held and not _prev_action_held
	var released_now: bool = not input_action_held and _prev_action_held
	_prev_action_held = input_action_held
	if pressed_now and cooler_view_open:
		toggle_cooler_view()
	if pressed_now and map_view_open:
		toggle_map_view()
	match session.stage:
		DaySession.Stage.AT_SCHOOL:
			if not session.can_cast():
				_charging = false
			elif input_action_held:
				# Já vai lançar de novo: o peixe vai direto para a caixa.
				landing.skip()
				_charging = true
				var charge_time: float = _pres.number("casting", "charge_time_s")
				cast_charge = minf(1.0, cast_charge + dt / charge_time)
			elif released_now and _charging:
				_do_cast()
		DaySession.Stage.BITE:
			if pressed_now:
				session.hook()
		DaySession.Stage.FIGHTING:
			session.set_reeling(input_action_held)
		_:
			_charging = false
	if not _charging:
		cast_charge = 0.0


func _do_cast() -> void:
	_charging = false
	var power: float = cast_charge
	var preview: Dictionary = cast_preview(power)
	(characters["tom"] as CharacterPuppet).release_cast()
	if session.cast(power, bool(preview["on_target"])):
		_cast_distance_m = power * session.rod_range_m()
		# O voo dura o tempo de lançar das regras: a isca pousa quando a espera começa.
		var apex: float = maxf(
			_pres.number("casting", "flight_apex_min_m"),
			_pres.number("casting", "flight_apex_per_m") * _cast_distance_m
		)
		rig.launch(
			boat.attach_point("LOC_rod_tip"),
			preview["point"],
			float(_db.economy["fishing"]["cast_s"]),
			apex
		)
		sfx.play("cast_whoosh")
	cast_charge = 0.0


func _on_bait_landed(_point: Vector3) -> void:
	sfx.play("splash")


## Para onde a isca vai com esta força: ponto na água (point), se está na direção
## do cardume (on_target, tolerância da mira) e se alcança o cardume (reaches,
## contando o raio de atração da isca). Usado no lançamento e no alvo na água.
func cast_preview(power: float) -> Dictionary:
	var boat_flat := Vector3(boat.global_position.x, 0.0, boat.global_position.z)
	var aim := Vector3(input_aim_point.x, 0.0, input_aim_point.z) - boat_flat
	if aim.length() < 0.01:
		aim = boat.forward()
	aim = aim.normalized()
	var on_target: bool = false
	var reaches: bool = false
	if engaged_school >= 0:
		var to_school := schools.positions[engaged_school] - boat_flat
		var tolerance: float = deg_to_rad(_pres.number("casting", "aim_tolerance_deg"))
		on_target = aim.angle_to(to_school.normalized()) <= tolerance
		var reach: float = power * session.rod_range_m() + _gear.attraction_radius_m()
		reaches = reach >= session.school_distance_m()
	var point: Vector3 = boat_flat + aim * power * session.rod_range_m()
	return {"point": point, "on_target": on_target, "reaches": reaches}


## Onde a isca do último lançamento caiu (ou vai cair, durante o voo).
func preview_point() -> Vector3:
	return rig.target_point()


## Força que leva a isca até o cardume (pode passar de 1: fora do alcance da vara).
func power_needed() -> float:
	var distance: float = maxf(0.0, session.school_distance_m() - _gear.attraction_radius_m())
	return distance / session.rod_range_m()


func _update_schools() -> void:
	var stopped_speed: float = _pres.number("navigation", "stopped_speed_m_s")
	var engage: float = _pres.number("schools", "engage_distance_m")
	if session.stage == DaySession.Stage.SEARCHING:
		if engaged_school >= 0 and session.fish_left_in_school() <= 0:
			schools.respawn(engaged_school, boat.global_position)
		engaged_school = -1
		if boat.is_stopped(stopped_speed) and not session.livewell.is_full():
			var nearest: int = schools.nearest(boat.global_position)
			var distance: float = SchoolField.flat_distance(
				boat.global_position, schools.positions[nearest]
			)
			if distance <= engage and session.reach_school(distance):
				engaged_school = nearest
			else:
				# Parado longe dos cardumes: lança na água aberta (P-36).
				session.stop_in_open_water()
	elif session.in_open_water and boat.is_stopped(stopped_speed):
		# Parado na água aberta, mas com um cardume perto: passa para o cardume.
		var near: int = schools.nearest(boat.global_position)
		var near_m: float = SchoolField.flat_distance(boat.global_position, schools.positions[near])
		if near_m <= engage and session.leave_school() and session.reach_school(near_m):
			engaged_school = near
	elif session.stage == DaySession.Stage.AT_SCHOOL and engaged_school >= 0:
		session.update_school_distance(
			SchoolField.flat_distance(boat.global_position, schools.positions[engaged_school])
		)


## Pancada do casco: mais alta quanto mais forte o impacto (até ~3 m/s).
func _on_boat_bumped(impact_m_s: float) -> void:
	if impact_m_s < 0.4:
		return
	sfx.play("hull_bump", lerpf(-18.0, 0.0, clampf(impact_m_s / 3.0, 0.0, 1.0)))


func _update_dock() -> void:
	var near: bool = (
		SchoolField.flat_distance(boat.global_position, dock_point)
		<= _pres.number("dock", "arrive_radius_m")
	)
	if not near:
		_docked_here = false
	elif not _docked_here and session.can_dock() and session.livewell.count() > 0:
		session.arrive_at_dock()
		engaged_school = -1
		_docked_here = true


func _handle_events() -> void:
	for event in session.drain_events():
		events_seen.append(event)
		_count_tip(String(event["type"]))
		match String(event["type"]):
			"school_found":
				sfx.play("bark")
				(characters["bolota"] as CharacterPuppet).play("bark")
			"cast":
				landing.skip()
				# A sombra do peixe vem de um lado que muda a cada lançamento.
				fish_shadow.start(preview_point(), fposmod(float(events_seen.size()) * 2.399, TAU))
			"bite":
				rig.dip()
				sfx.play("bite_plop")
				if cooler_view_open:
					toggle_cooler_view()
				if map_view_open:
					toggle_map_view()
			"bite_missed", "escaped", "school_left":
				rig.hide_all()
			"hooked":
				sfx.play("hook_set")
			"caught":
				var fish: Dictionary = event["fish"]
				sfx.play("catch_jingle")
				landing.start(
					_db.species(fish["species"]),
					float(fish["weight_kg"]),
					String(fish["variant"]),
					rig.buoy.global_position
				)
			"line_broke":
				sfx.play("line_snap")
				rig.hide_all()
			"docked":
				landing.skip()
		_show_event_message(event)
		if cooler_view_open and String(event["type"]) in ["caught", "docked"]:
			_open_cooler_panel()


func _count_tip(event_type: String) -> void:
	if autopilot != null:
		return
	for tip_id: String in TIPS_BY_EVENT.get(event_type, []):
		_state.tips_progress[tip_id] = _state.tip_count(tip_id) + 1


func _show_event_message(event: Dictionary) -> void:
	match String(event["type"]):
		"school_found":
			hud.set_message("Cardume! O Bolota latiu.")
		"open_water":
			hud.set_message(
				"Água aberta: os peixes estão espalhados. Nas ondulações há mais peixe."
			)
		"cast":
			var aim_text: String = "" if bool(event["on_target"]) else " (fora do cardume)"
			if session.in_open_water:
				aim_text = " (água aberta)"
			hud.set_message("Esperando a mordida...%s" % aim_text)
		"bite":
			hud.set_message("Mordeu!")
		"bite_missed":
			hud.set_message("Não deu tempo de fisgar...")
		"hooked":
			var species: Dictionary = _db.species(event["species"])
			var bonus: String = " No tempo certo, bônus!" if bool(event["early"]) else ""
			hud.set_message("Fisgou: %s!%s" % [species["common_name"], bonus])
		"caught":
			var fish: Dictionary = event["fish"]
			var species_name: String = _db.species(fish["species"])["common_name"]
			var variant: String = String(VARIANT_TEXT.get(fish["variant"], ""))
			var weight: String = weight_text(float(fish["weight_kg"]))
			hud.set_message(
				(
					"Pegou %s%s (%s)! +%d pontos"
					% [species_name, variant, weight, int(event["points"])]
				)
			)
		"line_broke":
			hud.set_message("A linha arrebentou! O combo zerou.")
		"escaped":
			hud.set_message("O peixe escapou.")
		"docked":
			hud.set_message(
				"Dona Marô comprou o viveiro. Vendas do dia: %d moedas" % event["coins"]
			)


func _update_visuals(dt: float) -> void:
	fish_shadow.update_shadow(session.bite_in_s, rig.target_point())
	var fighting: bool = session.stage == DaySession.Stage.FIGHTING
	if fighting:
		var game: TensionMinigame = session.tension_game
		var fraction: float = game.distance_m / maxf(_cast_distance_m, 0.01)
		rig.pull_toward(boat.global_position, fraction)
		if game.profile.is_jumping():
			var hooked: FishCatch = session.hooked_fish()
			if hooked != null:
				rig.jump_fish(_db.species(hooked.species_id), hooked.weight_kg, hooked.variant)
		_reel_tick_s -= dt
		if input_action_held and _reel_tick_s <= 0.0:
			sfx.play("reel_tick")
			_reel_tick_s = REEL_TICK_S
	landing.step(dt)
	rig.step(dt, boat.attach_point("LOC_rod_tip"), fighting)
	_update_cooler(dt)
	lighting.apply(session.clock.elapsed_s)
	camera.step(dt)
	var sonar: Dictionary = _db.upgrade_level("sonar", _state.level_of("sonar"))
	water.advance(dt)
	birds.advance(dt)
	buoys.advance(dt)
	animals.advance(dt)
	(characters["tom"] as CharacterPuppet).cast_charge = cast_charge if _charging else 0.0
	for puppet: CharacterPuppet in characters.values():
		puppet.advance(dt)
	water.trail_boat(boat.stern_point(), boat.speed_m_s, boat.max_speed())
	water.set_hull(boat.model, boat.speed_m_s / maxf(boat.max_speed(), 0.01))
	water.set_sky_color(lighting.horizon_color())
	water.set_schools(schools.shader_data(boat.global_position, float(sonar["range_m"])))
	var echoes: int = hud.mini_map.update_state(
		dt, boat.global_position, boat.forward(), float(sonar["range_m"]), schools.positions
	)
	if echoes > 0:
		sfx.play("sonar_ping", float(_pres.section("minimap")["sonar"]["ping_db"]))
	_update_marker(dt)
	sfx.set_engine_load(absf(boat.speed_m_s) / maxf(boat.max_speed(), 0.01))


## A caixa mostra o viveiro (menos o peixe que o Tom ainda está guardando). Com a
## vista de dentro aberta, a tampa abre e a câmera fica em cima da caixa.
func _update_cooler(dt: float) -> void:
	cooler.sync(session.livewell.contents(), 1 if landing.active else 0)
	if landing.active:
		return
	cooler.set_lid(move_toward(cooler.lid_open, 1.0 if cooler_view_open else 0.0, dt * 4.0))
	if cooler_view_open:
		var eye: Vector3 = (
			cooler.global_transform * LandingShow.vector(_pres.section("landing")["view_eye_m"])
		)
		camera.close_up(eye, cooler.top_point())


## Abre ou fecha a vista de dentro da caixa de isopor.
func toggle_cooler_view() -> void:
	cooler_view_open = not cooler_view_open
	if cooler_view_open and map_view_open:
		toggle_map_view()
	if not cooler_view_open:
		hud.cooler_panel.close()
		camera.release_close_up()
		return
	landing.skip()
	_open_cooler_panel()
	if autopilot == null:
		_state.tips_progress["cooler_view"] = _state.tip_count("cooler_view") + 1


## Abre ou fecha o mapa grande (no meio da tela; o pequeno some enquanto isso).
func toggle_map_view() -> void:
	map_view_open = not map_view_open
	if map_view_open and cooler_view_open:
		toggle_cooler_view()
	hud.set_map_expanded(map_view_open)
	if map_view_open and autopilot == null:
		_state.tips_progress["map_view"] = _state.tip_count("map_view") + 1


func _open_cooler_panel() -> void:
	hud.cooler_panel.open(session.livewell.contents(), session.livewell.capacity, _db, touch_mode)


func _update_hud() -> void:
	var clock := session.clock
	var remaining: int = ceili(clock.remaining_s())
	var bait_id: String = _state.equipped_bait
	var stats: Dictionary = {
		"title": "Dia %d — %s" % [_day_number, PHASE_NAMES.get(clock.phase(), "")],
		"time": "%d:%02d" % [remaining / 60, remaining % 60],
		"goal": GoalText.describe(session.day_def["goal"], _db, session),
		"livewell": "%d/%d" % [session.livewell.count(), session.livewell.capacity],
		"combo": "x%.2f   %d pts" % [session.combo.multiplier(), session.score],
		"coins": "%d" % _state.coins,
		"bait": "%s (%d)" % [_db.bait(bait_id)["name"], _state.bait_count(bait_id)],
		"sonar": "",
	}
	var sonar_range: float = float(_db.upgrade_level("sonar", _state.level_of("sonar"))["range_m"])
	if sonar_range > 0.0:
		var nearest: int = schools.nearest(boat.global_position)
		var distance: float = SchoolField.flat_distance(
			boat.global_position, schools.positions[nearest]
		)
		if distance <= sonar_range:
			stats["sonar"] = "Sonar: cardume a %d m" % roundi(distance)
	hud.update_stats(stats)
	_update_guidance()
	if session.stage == DaySession.Stage.FIGHTING:
		hud.show_tension(session.tension_game, _db.economy["tension"])
	else:
		hud.hide_tension()


## Dica de controle e medidor de força do momento.
func _update_guidance() -> void:
	var at_school: bool = session.stage == DaySession.Stage.AT_SCHOOL and engaged_school >= 0
	var out_of_reach: bool = at_school and power_needed() > 1.0
	var hint: String = ControlHints.pick(
		session.stage,
		session.can_cast(),
		_charging,
		session.livewell.is_full(),
		out_of_reach,
		session.in_open_water
	)
	var show_until: int = int(_pres.number("hints", "show_until_count"))
	if (
		not hint.is_empty()
		and not ControlHints.still_needed(hint, _state.tip_count(hint), show_until)
	):
		hint = ""
	# Quem ainda não aprendeu a pilotar vê primeiro a dica de pilotar, mesmo parado
	# na água aberta (o dia começa com o barco parado).
	if (
		hint == "open_water"
		and ControlHints.still_needed("steer", _state.tip_count("steer"), show_until)
	):
		hint = "steer"
	# Guardando o peixe: a dica é a tecla da caixa de isopor.
	if (
		landing.active
		and ControlHints.still_needed("cooler_view", _state.tip_count("cooler_view"), show_until)
	):
		hint = "cooler_view"
	# Quem já pilota e ainda não abriu o mapa grande aprende a tecla dele.
	if (
		hint.is_empty()
		and session.stage == DaySession.Stage.SEARCHING
		and not touch_mode
		and ControlHints.still_needed("map_view", _state.tip_count("map_view"), show_until)
	):
		hint = "map_view"
	if cooler_view_open or (not show_hints and not ControlHints.ALWAYS.has(hint)):
		hint = ""
	if map_view_open:
		hint = "map_close"
	hud.hints.show_hint(hint, touch_mode)
	if session.stage == DaySession.Stage.AT_SCHOOL and session.can_cast():
		hud.show_cast(
			cast_charge if _charging else 0.0,
			session.school_distance_m() if at_school else -1.0,
			session.rod_range_m(),
			_gear.attraction_radius_m()
		)
	else:
		hud.hide_cast()


## Alvo na água: carregando, mostra onde a isca vai cair com a mira e a força
## atuais; parado, mostra onde ela precisa cair (na direção do cardume, na
## distância que o alcança, ou no limite da vara se o cardume estiver longe).
func _update_marker(dt: float) -> void:
	if session.stage != DaySession.Stage.AT_SCHOOL or not session.can_cast():
		marker.hide_marker()
		return
	if _charging:
		var preview: Dictionary = cast_preview(cast_charge)
		# Na água aberta, todo ponto ao alcance vale (P-36).
		var good: bool = (
			session.in_open_water or (bool(preview["on_target"]) and bool(preview["reaches"]))
		)
		marker.show_at(preview["point"], good, 1.0)
	elif engaged_school < 0:
		# Água aberta: o alvo fica para onde o jogador mira, numa distância média.
		var fraction: float = _pres.number("casting", "open_water_aim_fraction")
		marker.show_at(cast_preview(fraction)["point"], true, 0.0)
	else:
		var boat_flat := Vector3(boat.global_position.x, 0.0, boat.global_position.z)
		var to_school: Vector3 = schools.positions[engaged_school] - boat_flat
		to_school.y = 0.0
		var distance: float = minf(power_needed(), 1.0) * session.rod_range_m()
		marker.show_at(boat_flat + to_school.normalized() * distance, power_needed() <= 1.0, 0.0)
	marker.advance(dt)


func _finish() -> void:
	_finished = true
	landing.skip()
	if cooler_view_open:
		toggle_cooler_view()
	if map_view_open:
		toggle_map_view()
	sfx.stop_loops()
	sfx.play("day_end_chime")
	rig.hide_all()
	var next_unlocked: bool = int(session.result["stars"]) > 0 and _day_number < _db.day_count()
	hud.show_result(session.result, next_unlocked)
	day_finished.emit(session.result)


## Peso legível: gramas abaixo de 1 kg (o lambari pesa no máximo 100 g).
static func weight_text(weight_kg: float) -> String:
	if weight_kg < 1.0:
		return "%d g" % roundi(weight_kg * 1000.0)
	return "%.1f kg" % weight_kg


func is_finished() -> bool:
	return _finished
