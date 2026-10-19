class_name DayConditions
extends RefCounted
## Clima e eventos de um dia de pesca (GDD p. 5 e 9; P-31), sorteados uma vez
## no começo do dia.
##
## - Clima do dia: sol, nublado, chuva ou tempestade (economy.json, weather). O
##   dia pode fixar o clima (days.json, weather). Na tempestade, o casco segura
##   parte dos efeitos ruins (storm_resistance).
## - Eventos com hora marcada: cardume frenético (mordidas rápidas), névoa (raros
##   mais frequentes, busca difícil sem sonar; o farol ajuda) e rede de Bragança
##   (desvio na busca; obstáculo no mapa). Uma região pode ter um evento o dia
##   todo (regions.json, permanent_events: a névoa da Ilha da Névoa).
##
## Sem gerador (rng nulo), o dia é de sol e sem eventos e nada é sorteado: é o
## caso do MVP, que joga exatamente como antes.

const SUN: String = "sun"
const STORM: String = "storm"
const FRENZY: String = "frenzy"
const FOG: String = "fog"
const NET: String = "net"
## Ordem fixa dos sorteios de eventos (a regressão depende dela).
const EVENT_ORDER: PackedStringArray = [FRENZY, FOG, NET]

var weather: String = SUN
## Eventos marcados: {"id", "start_s", "end_s"}; a rede também tem "spot"
## (ângulo em rad e fração do raio do lago), para a cena pôr a rede.
var events: Array[Dictionary] = []

var _weather: Dictionary = {}
var _events_cfg: Dictionary
var _gear: Loadout


## O perfil de versão sorteia clima ou eventos? (No MVP, não.)
static func rolls(db: ContentDB) -> bool:
	var weather_ids: Array = db.release["enabled_weather"]
	var event_ids: Array = db.release["enabled_events"]
	return weather_ids.size() > 1 or not event_ids.is_empty()


func _init(db: ContentDB, day_def: Dictionary, duration_s: float, gear: Loadout, rng: Rng) -> void:
	_gear = gear
	_events_cfg = db.economy["events"]
	var types: Dictionary = {}
	for weather_type: Dictionary in db.economy["weather"]["types"]:
		types[weather_type["id"]] = weather_type
	if rng == null:
		_weather = types[SUN]
		return
	weather = String(day_def.get("weather", _roll_weather(db, types, rng)))
	_weather = types[weather]
	var permanent: Array = db.region(day_def["region"]).get("permanent_events", [])
	for event_id in EVENT_ORDER:
		if permanent.has(event_id):
			events.append({"id": event_id, "start_s": 0.0, "end_s": duration_s})
	_roll_events(db, duration_s, permanent, rng)


func is_active(event_id: String, time_s: float) -> bool:
	for event in events:
		if event["id"] == event_id and time_s >= event["start_s"] and time_s < event["end_s"]:
			return true
	return false


## Fator sobre a espera pela mordida agora (clima e cardume frenético).
func bite_wait_factor(time_s: float) -> float:
	var factor: float = _weather_factor("bite_wait_factor")
	if is_active(FRENZY, time_s):
		factor *= float(_events_cfg[FRENZY]["bite_wait_factor"])
	return factor


## Fator sobre o tempo de procurar um cardume agora (clima, névoa e rede).
func search_time_factor(time_s: float) -> float:
	var factor: float = _weather_factor("search_time_factor")
	if is_active(FOG, time_s):
		var fog: Dictionary = _events_cfg[FOG]
		var penalty: float = float(fog["search_time_factor"]) - 1.0
		if _gear.has_sonar():
			penalty *= float(fog["sonar_relief"])
		factor *= 1.0 + penalty * _gear.fog_visibility_factor()
	if is_active(NET, time_s):
		factor *= float(_events_cfg[NET]["search_time_factor"])
	return factor


## Fator sobre a chance das espécies que não são comuns agora (clima e névoa).
func rare_multiplier(time_s: float) -> float:
	var factor: float = float(_weather["rare_multiplier"])
	if is_active(FOG, time_s):
		factor *= float(_events_cfg[FOG]["rare_multiplier"])
	return factor


## Eventos que começam e terminam entre os instantes from_s e to_s:
## {"started": [eventos], "ended": [eventos]}.
func changes_between(from_s: float, to_s: float) -> Dictionary:
	var started: Array[Dictionary] = []
	var ended: Array[Dictionary] = []
	for event in events:
		if float(event["start_s"]) > from_s and float(event["start_s"]) <= to_s:
			started.append(event)
		if float(event["end_s"]) > from_s and float(event["end_s"]) <= to_s:
			ended.append(event)
	return {"started": started, "ended": ended}


## Efeitos ruins do clima (fator acima de 1) diminuem na tempestade com o casco.
func _weather_factor(key: String) -> float:
	var factor: float = float(_weather[key])
	if weather == STORM and factor > 1.0:
		factor = 1.0 + (factor - 1.0) * (1.0 - _gear.storm_resistance())
	return factor


func _roll_weather(db: ContentDB, types: Dictionary, rng: Rng) -> String:
	var ids: Array[String] = []
	var weights := PackedFloat64Array()
	for weather_id: String in types:
		if db.is_enabled("weather", weather_id):
			ids.append(weather_id)
			weights.append(float(types[weather_id]["weight"]))
	# Sorteia sempre (mesmo com o clima fixo do dia), para a sequência não mudar.
	var index: int = rng.weighted_index(weights)
	return ids[index] if index >= 0 else SUN


## Cada evento ligado consome sempre os mesmos sorteios (chance, início,
## duração e, para a rede, o lugar), aconteça ou não.
func _roll_events(db: ContentDB, duration_s: float, permanent: Array, rng: Rng) -> void:
	for event_id in EVENT_ORDER:
		if not db.is_enabled("events", event_id):
			continue
		var cfg: Dictionary = _events_cfg[event_id]
		var happens: bool = rng.chance(float(cfg["chance"]))
		var window: Array = cfg["start_fraction"]
		var start: float = duration_s * rng.range_float(float(window[0]), float(window[-1]))
		var length: float = _duration(cfg["duration_s"], rng)
		var spot := Vector2(rng.range_float(0.0, TAU), rng.range_float(0.0, 1.0))
		if not happens or permanent.has(event_id):
			continue
		var event: Dictionary = {
			"id": event_id, "start_s": start, "end_s": minf(duration_s, start + length)
		}
		if event_id == NET:
			event["spot"] = spot
		events.append(event)


static func _duration(value: Variant, rng: Rng) -> float:
	if value is Array:
		var pair: Array = value
		return rng.range_float(float(pair[0]), float(pair[-1]))
	return float(value)
