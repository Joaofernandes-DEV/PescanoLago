class_name DaySession
extends RefCounted
## Um dia de pesca completo, como máquina de estados pura.
##
## O jogo (ou o jogador simulado) envia comandos — cast(), hook(),
## set_reeling(), go_to_dock() — e avança o tempo com tick(dt). A sessão
## gera eventos (drain_events) para a interface e, quando o tempo acaba,
## vende o viveiro (P-15), calcula as estrelas e atualiza o PlayerState.
##
## Dois modos de navegação:
## - simulado (padrão): procurar cardume e ir ao cais custam tempo fixo
##   (P-18), para o simulador e os testes;
## - manual (jogo de verdade): o jogador pilota o barco; o adaptador avisa
##   quando o barco parou num cardume (reach_school) ou chegou ao cais
##   (arrive_at_dock). As regras de pesca são as mesmas nos dois modos.

enum Stage { SEARCHING, AT_SCHOOL, CASTING, WAITING_BITE, BITE, FIGHTING, STORING, TO_DOCK, ENDED }

var day_number: int
var day_def: Dictionary
var stage: Stage = Stage.SEARCHING
var clock: DayClock
var combo: Combo
var livewell: Livewell
var tension_game: TensionMinigame
var catches: Array[FishCatch] = []
var score: int = 0
var coins_from_sales: int = 0
var result: Dictionary = {}
var manual_navigation: bool = false

var _db: ContentDB
var _state: PlayerState
var _rng: Rng
var _market: Market
var _roller: CatchRoller
var _fishing: Dictionary
var _gear: Loadout
var _events: Array[Dictionary] = []
var _stage_left_s: float = 0.0
var _school_left: int = 0
var _school_distance_m: float = 0.0
var _cast_distance_m: float = 0.0
var _bite_elapsed_s: float = 0.0
var _cast_on_target: bool = true
var _hooked_fish: FishCatch
var _reeling: bool = false


## options: {"manual_navigation": true} para o jogo com o barco pilotado.
func _init(
	db: ContentDB, state: PlayerState, p_day_number: int, rng: Rng, options: Dictionary = {}
) -> void:
	manual_navigation = bool(options.get("manual_navigation", false))
	_db = db
	_state = state
	_rng = rng
	day_number = p_day_number
	day_def = db.day(p_day_number)
	_fishing = db.economy["fishing"]
	_gear = Loadout.new(db, state)
	_market = Market.new(db)
	_roller = CatchRoller.new(db)
	var duration: float = float(day_def["duration_s"]) + _gear.extra_time_s()
	clock = DayClock.new(duration, db.economy["day_phases"])
	var combo_cfg: Dictionary = db.economy["combo"]
	combo = Combo.new(float(combo_cfg["step"]), float(combo_cfg["max_multiplier"]))
	var capacity: int = int(db.upgrade_level("livewell", state.level_of("livewell"))["capacity"])
	livewell = Livewell.new(capacity)
	_start_search()


# --- Consultas ---


func is_over() -> bool:
	return stage == Stage.ENDED


## À noite, só com farol (GDD p. 5).
func can_cast() -> bool:
	return (
		stage == Stage.AT_SCHOOL
		and not livewell.is_full()
		and _has_bait()
		and _gear.can_fish_at(clock.phase())
	)


## Distância do cardume atual (ondulações na água; o sonar ajuda a achar).
func school_distance_m() -> float:
	return _school_distance_m


func rod_range_m() -> float:
	return _gear.range_m()


## Peixes que ainda restam no cardume atual (para as ondulações na água).
func fish_left_in_school() -> int:
	return _school_left


## O barco pode atracar e vender agora? (modo manual)
func can_dock() -> bool:
	return manual_navigation and stage in [Stage.SEARCHING, Stage.AT_SCHOOL]


## Peixe fisgado agora (espécie, peso e variante), ou null fora da briga.
func hooked_fish() -> FishCatch:
	return _hooked_fish if stage == Stage.FIGHTING else null


## Segundos desde que o peixe mordeu (para a interface e o jogador simulado).
func bite_elapsed_s() -> float:
	return _bite_elapsed_s


func drain_events() -> Array[Dictionary]:
	var drained: Array[Dictionary] = _events
	_events = []
	return drained


# --- Comandos ---


## Lança a isca com força de 0 a 1 (fração do alcance da vara). on_target:
## a isca caiu na direção do cardume (o jogador mira; o simulador sempre mira).
## Fora do alvo, a mordida demora como num lançamento curto.
func cast(power: float, on_target: bool = true) -> bool:
	if not can_cast():
		return false
	var bait_id: String = _state.equipped_bait
	if _db.is_natural_bait(bait_id):
		_state.bait_inventory[bait_id] = _state.bait_count(bait_id) - 1
	_cast_distance_m = clampf(power, 0.0, 1.0) * _gear.range_m()
	_cast_on_target = on_target
	_set_stage(Stage.CASTING, float(_fishing["cast_s"]))
	_emit("cast", {"distance_m": _cast_distance_m, "bait": bait_id, "on_target": on_target})
	return true


## Fisga. Só vale com o peixe mordendo; o tempo de reação define o resultado.
func hook() -> Bite.Hook:
	if stage != Stage.BITE:
		return Bite.Hook.MISSED
	var outcome: Bite.Hook = Bite.hook(
		_bite_elapsed_s, _gear.hook_window_s(), _db.economy["hook_bonus"]
	)
	if outcome == Bite.Hook.MISSED:
		_lose_bite()
		return outcome
	_hooked_fish.early_hook = outcome == Bite.Hook.HOOKED_EARLY
	var species: Dictionary = _db.species(_hooked_fish.species_id)
	var profile := FightProfile.new(species["fight"], _db.economy["fight_profiles"], _rng)
	tension_game = TensionMinigame.new(
		_db.economy["tension"],
		profile,
		_hooked_fish.weight_kg,
		_gear.line_strength_kg(),
		_gear.reel_speed_m_s(),
		_cast_distance_m
	)
	_reeling = false
	_set_stage(Stage.FIGHTING, 0.0)
	_emit("hooked", {"species": _hooked_fish.species_id, "early": _hooked_fish.early_hook})
	return outcome


## Botão de recolher pressionado (true) ou solto (false) durante a briga.
func set_reeling(reeling: bool) -> void:
	_reeling = reeling


## Volta ao cais para vender o viveiro (modo simulado: custa tempo fixo).
## Não dá para sair no meio da briga.
func go_to_dock() -> bool:
	if manual_navigation or stage in [Stage.FIGHTING, Stage.TO_DOCK, Stage.ENDED]:
		return false
	_set_stage(Stage.TO_DOCK, float(_fishing["dock_round_trip_s"]) / _motor_speed())
	_emit("to_dock", {"fish": livewell.count()})
	return true


## Modo manual: o barco parou perto de um cardume, a esta distância.
func reach_school(distance_m: float) -> bool:
	if not manual_navigation or stage != Stage.SEARCHING:
		return false
	_enter_school(_roll_school_size(), distance_m)
	return true


## Modo manual: o barco andou e a distância até o cardume mudou.
func update_school_distance(distance_m: float) -> void:
	if manual_navigation and stage == Stage.AT_SCHOOL:
		_school_distance_m = distance_m


## Modo manual: o jogador saiu do cardume antes de acabar os peixes.
func leave_school() -> bool:
	if not manual_navigation or stage != Stage.AT_SCHOOL:
		return false
	_emit("school_left", {"fish": _school_left})
	_start_search()
	return true


## Modo manual: o barco chegou ao cais; Dona Marô compra o viveiro.
func arrive_at_dock() -> bool:
	if not can_dock():
		return false
	_sell_livewell()
	_emit("docked", {"coins": coins_from_sales})
	_start_search()
	return true


# --- Tempo ---


func tick(dt: float) -> void:
	if is_over():
		return
	clock.tick(dt)
	match stage:
		Stage.FIGHTING:
			_tick_fight(dt)
		Stage.BITE:
			_bite_elapsed_s += dt
			if _bite_elapsed_s > _gear.hook_window_s():
				_lose_bite()
		_:
			_stage_left_s -= dt
			if _stage_left_s <= 0.0:
				_finish_timed_stage()
	if clock.is_over():
		_end_day()


func _finish_timed_stage() -> void:
	match stage:
		Stage.SEARCHING:
			# Ordem dos sorteios (tamanho, depois distância) fixa: a regressão depende dela.
			var size: int = _roll_school_size()
			var distance: Array = _fishing["school_distance_m"]
			_enter_school(size, _rng.range_float(float(distance[0]), float(distance[-1])))
		Stage.CASTING:
			# A isca atrai num raio em volta de onde caiu (artificiais por nível, P-29).
			var reach: float = 0.0
			if _cast_on_target:
				reach = _cast_distance_m + _gear.attraction_radius_m()
			var wait: float = Bite.wait_time_s(_fishing, reach, _school_distance_m, _rng)
			_set_stage(Stage.WAITING_BITE, wait * _gear.bite_wait_factor(clock.phase()))
		Stage.WAITING_BITE:
			_hooked_fish = _roller.roll(
				day_def["region"],
				clock.phase(),
				_state.equipped_bait,
				_gear.variant_chance_bonus(),
				_rng,
				_gear.surface_multiplier()
			)
			_bite_elapsed_s = 0.0
			_set_stage(Stage.BITE, 0.0)
			_emit("bite", {})
		Stage.STORING:
			_after_fish()
		Stage.TO_DOCK:
			_sell_livewell()
			_emit("docked", {"coins": coins_from_sales})
			_start_search()


func _tick_fight(dt: float) -> void:
	match tension_game.step(dt, _reeling):
		TensionMinigame.Result.CAUGHT:
			_land_fish()
		TensionMinigame.Result.LINE_BROKE:
			combo.break_chain()
			_emit("line_broke", {"species": _hooked_fish.species_id})
			_after_fish()
		TensionMinigame.Result.ESCAPED:
			combo.break_chain()
			_emit("escaped", {"species": _hooked_fish.species_id})
			_after_fish()


func _land_fish() -> void:
	var fish: FishCatch = _hooked_fish
	fish.combo_multiplier = combo.register_catch()
	var points: int = Scoring.points(fish, _db.species(fish.species_id), _db.economy)
	score += points
	catches.append(fish)
	livewell.add(fish)
	_state.register_in_album(fish)
	_emit("caught", {"fish": fish.to_dict(), "points": points, "combo": fish.combo_multiplier})
	_set_stage(Stage.STORING, float(_fishing["store_s"]))


func _lose_bite() -> void:
	_emit("bite_missed", {})
	_after_fish()


## Cada mordida (pega, perdida ou não fisgada) gasta um peixe do cardume.
func _after_fish() -> void:
	_hooked_fish = null
	tension_game = null
	_school_left -= 1
	if _school_left > 0:
		_set_stage(Stage.AT_SCHOOL, 0.0)
	else:
		_start_search()


func _roll_school_size() -> int:
	return _rng.range_int(int(_fishing["school_size"][0]), int(_fishing["school_size"][-1]))


func _enter_school(size: int, distance_m: float) -> void:
	_school_left = size
	_school_distance_m = distance_m
	_set_stage(Stage.AT_SCHOOL, 0.0)
	_emit("school_found", {"fish": _school_left, "distance_m": _school_distance_m})


func _start_search() -> void:
	if manual_navigation:
		_set_stage(Stage.SEARCHING, INF)
		return
	var sonar: Dictionary = _db.upgrade_level("sonar", _state.level_of("sonar"))
	var search: float = (
		float(_fishing["search_time_s"]) * float(sonar["search_time_factor"]) / _motor_speed()
	)
	_set_stage(Stage.SEARCHING, search)


func _motor_speed() -> float:
	return float(_db.upgrade_level("motor", _state.level_of("motor"))["speed_factor"])


func _has_bait() -> bool:
	var bait_id: String = _state.equipped_bait
	return not _db.is_natural_bait(bait_id) or _state.bait_count(bait_id) > 0


func _sell_livewell() -> void:
	var coins: int = _market.sell(livewell.take_all())
	coins_from_sales += coins
	_state.coins += coins
	_state.total_sales += coins


## Fim do dia: briga em andamento é perdida, o viveiro é vendido (P-15),
## estrelas e recompensa (P-05, P-13) entram no PlayerState, e o dia conta como jogado.
func _end_day() -> void:
	if stage == Stage.FIGHTING:
		combo.break_chain()
		_emit("escaped", {"species": _hooked_fish.species_id, "reason": "time_up"})
	if bool(_db.economy["end_of_day"]["auto_sell_livewell"]):
		_sell_livewell()
	var stars: int = GoalEvaluator.stars(day_def, catches, score, _db)
	var previous: int = _state.stars_of(day_number)
	var reward: int = GoalEvaluator.star_reward(previous, stars, _db)
	_state.coins += reward
	if stars > previous:
		_state.best_stars[str(day_number)] = stars
	_state.sessions_played += 1
	result = {
		"day": day_number,
		"stars": stars,
		"score": score,
		"fish": catches.size(),
		"coins_from_sales": coins_from_sales,
		"star_reward": reward,
		"goal_met": stars > 0,
	}
	stage = Stage.ENDED
	tension_game = null
	_emit("day_ended", result)


func _set_stage(new_stage: Stage, duration_s: float) -> void:
	stage = new_stage
	_stage_left_s = duration_s


func _emit(event_type: String, data: Dictionary) -> void:
	var event: Dictionary = data.duplicate()
	event["type"] = event_type
	event["t"] = clock.elapsed_s
	_events.append(event)
