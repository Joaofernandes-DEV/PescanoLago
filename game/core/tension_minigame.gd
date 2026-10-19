class_name TensionMinigame
extends RefCounted
## Mini-jogo de tensão da linha (GDD p. 5; P-10).
##
## A barra sobe quando o jogador recolhe e quando o peixe puxa, e desce quando
## o jogador solta. Na zona verde o peixe cansa e a linha anda mais rápido.
## Acima da zona verde por tempo demais, a linha arrebenta; perto de zero por
## tempo demais, o peixe escapa. Avança só por step(dt, recolhendo).

enum Result { FIGHTING, CAUGHT, LINE_BROKE, ESCAPED }

var tension: float
var distance_m: float
var stamina: float = 1.0
var elapsed_s: float = 0.0
var result: Result = Result.FIGHTING
var profile: FightProfile
var _cfg: Dictionary
var _load: float
var _reel_speed_m_s: float
var _over_s: float = 0.0
var _under_s: float = 0.0


## cfg: economy.json, tension. A carga é peso do peixe ÷ resistência da linha, limitada.
func _init(
	cfg: Dictionary,
	p_profile: FightProfile,
	fish_weight_kg: float,
	line_strength_kg: float,
	reel_speed_m_s: float,
	start_distance_m: float
) -> void:
	_cfg = cfg
	profile = p_profile
	_load = clampf(
		fish_weight_kg / line_strength_kg, float(cfg["load_min"]), float(cfg["load_max"])
	)
	_reel_speed_m_s = reel_speed_m_s
	distance_m = start_distance_m
	tension = float(cfg["start_tension"])


func is_over() -> bool:
	return result != Result.FIGHTING


func in_green_zone() -> bool:
	return tension >= float(_cfg["green_min"]) and tension <= float(_cfg["green_max"])


## Fração da linha que falta para arrebentar (0 = segura, 1 = arrebentou). Para o HUD.
func break_risk() -> float:
	return clampf(_over_s / float(_cfg["break_after_s"]), 0.0, 1.0)


func step(dt: float, reeling: bool) -> Result:
	if is_over():
		return result
	elapsed_s += dt
	profile.advance(dt)

	var tiredness: float = lerpf(float(_cfg["tired_pull_fraction"]), 1.0, stamina)
	var pull: float = float(_cfg["pull_per_s"]) * _load * profile.pull_multiplier() * tiredness
	var player: float = (
		float(_cfg["reel_rise_per_s"]) if reeling else -float(_cfg["release_fall_per_s"])
	)
	tension = clampf(tension + (player + pull) * dt, 0.0, float(_cfg["bar_max"]))

	var green: bool = in_green_zone()
	if green:
		stamina = maxf(0.0, stamina - float(_cfg["stamina_drain_per_s"]) * dt)
	if reeling:
		var progress: float = 1.0 if green else float(_cfg["out_of_zone_progress"])
		progress *= profile.reel_progress_multiplier()
		distance_m -= _reel_speed_m_s * progress * dt

	_update_line(dt)
	if not is_over() and distance_m <= 0.0:
		distance_m = 0.0
		result = Result.CAUGHT
	return result


func _update_line(dt: float) -> void:
	var limit: float = profile.danger_threshold(float(_cfg["green_max"]))
	if tension > limit:
		var speed: float = 1.0
		if tension > float(_cfg["danger_above"]):
			speed = float(_cfg["danger_speed"])
		_over_s += profile.danger_speed(speed) * dt
	else:
		_over_s = 0.0
	if _over_s >= float(_cfg["break_after_s"]):
		result = Result.LINE_BROKE
		return

	if tension < float(_cfg["escape_below"]):
		_under_s += dt
	else:
		_under_s = 0.0
	if _under_s >= float(_cfg["escape_after_s"]):
		result = Result.ESCAPED
