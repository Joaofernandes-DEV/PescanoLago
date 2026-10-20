class_name DayController
extends Node3D
## Cena de um dia de pesca. Liga o DaySession (regras, núcleo puro) ao mundo 3D,
## à entrada do jogador e à interface. Não tem regra de jogo própria: traduz a
## posição do barco e os botões em comandos (reach_school, cast, hook,
## set_reeling, arrive_at_dock...) e mostra os eventos que a sessão devolve.
## Orienta o jogador com dicas de controle, o medidor de força e o alvo na água.

signal day_finished(result: Dictionary)

const MAX_STEP_S: float = 0.05
const REEL_TICK_S: float = 0.12
const PHASE_NAMES: Dictionary = {
	"dawn": "Amanhecer", "day": "Dia", "dusk": "Entardecer", "night": "Noite"
}
## Ação feita pelo jogador -> dicas que ela ensina (as dicas somem com o uso).
const TIPS_BY_EVENT: Dictionary = {
	"school_found": ["steer"],
	"cast": ["cast_hold", "cast_release"],
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
## O jogador está usando a tela de toque (muda as dicas de controle).
var touch_mode: bool = false
var birds: Birds
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
	rig = FishingRig.new()
	rig.setup(_pres.section("fish"))
	add_child(rig)
	rig.landed.connect(_on_bait_landed)
	marker = AimMarker.new()
	marker.water = water
	add_child(marker)
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
	_update_hud()


## O último aparelho usado decide as dicas: toque ou teclado. O mouse não conta,
## porque a Godot também gera mouse a partir do toque.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touch_mode = true
	elif event is InputEventKey:
		touch_mode = false


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


## Um passo da cena: piloto (se houver) → barco → botões → regras → eventos → visual.
func step(dt: float) -> void:
	if _finished:
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
	match session.stage:
		DaySession.Stage.AT_SCHOOL:
			if not session.can_cast():
				_charging = false
			elif input_action_held:
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
			"bite":
				rig.dip()
				sfx.play("bite_plop")
			"bite_missed", "escaped", "school_left":
				rig.hide_all()
			"hooked":
				sfx.play("hook_set")
			"caught":
				var fish: Dictionary = event["fish"]
				sfx.play("catch_jingle")
				(characters["tom"] as CharacterPuppet).play("cheer")
				rig.show_catch(
					_db.species(fish["species"]),
					float(fish["weight_kg"]),
					String(fish["variant"]),
					float(_pres.number("fish", "catch_show_s"))
				)
			"line_broke":
				sfx.play("line_snap")
				rig.hide_all()
		_show_event_message(event)


func _count_tip(event_type: String) -> void:
	if autopilot != null:
		return
	for tip_id: String in TIPS_BY_EVENT.get(event_type, []):
		_state.tips_progress[tip_id] = _state.tip_count(tip_id) + 1


func _show_event_message(event: Dictionary) -> void:
	match String(event["type"]):
		"school_found":
			hud.set_message("Cardume! O Bolota latiu.")
		"cast":
			var aim_text: String = "" if bool(event["on_target"]) else " (fora do cardume)"
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
			var variant: String = " ALBINO!" if fish["variant"] == "albino" else ""
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
	rig.step(dt, boat.attach_point("LOC_rod_tip"), fighting)
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
	hud.mini_map.update_state(
		dt, boat.global_position, boat.forward(), float(sonar["range_m"]), schools.positions
	)
	_update_marker(dt)
	sfx.set_engine_load(absf(boat.speed_m_s) / maxf(boat.max_speed(), 0.01))


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
		session.stage, session.can_cast(), _charging, session.livewell.is_full(), out_of_reach
	)
	var show_until: int = int(_pres.number("hints", "show_until_count"))
	if (
		not hint.is_empty()
		and not ControlHints.still_needed(hint, _state.tip_count(hint), show_until)
	):
		hint = ""
	hud.hints.show_hint(hint, touch_mode)
	if at_school and session.can_cast():
		hud.show_cast(
			cast_charge if _charging else 0.0,
			session.school_distance_m(),
			session.rod_range_m(),
			_gear.attraction_radius_m()
		)
	else:
		hud.hide_cast()


## Alvo na água: carregando, mostra onde a isca vai cair com a mira e a força
## atuais; parado, mostra onde ela precisa cair (na direção do cardume, na
## distância que o alcança, ou no limite da vara se o cardume estiver longe).
func _update_marker(dt: float) -> void:
	if session.stage != DaySession.Stage.AT_SCHOOL or engaged_school < 0 or not session.can_cast():
		marker.hide_marker()
		return
	if _charging:
		var preview: Dictionary = cast_preview(cast_charge)
		var good: bool = bool(preview["on_target"]) and bool(preview["reaches"])
		marker.show_at(preview["point"], good, 1.0)
	else:
		var boat_flat := Vector3(boat.global_position.x, 0.0, boat.global_position.z)
		var to_school: Vector3 = schools.positions[engaged_school] - boat_flat
		to_school.y = 0.0
		var distance: float = minf(power_needed(), 1.0) * session.rod_range_m()
		marker.show_at(boat_flat + to_school.normalized() * distance, power_needed() <= 1.0, 0.0)
	marker.advance(dt)


func _finish() -> void:
	_finished = true
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
