class_name FightProfile
extends RefCounted
## Como cada espécie puxa a linha (GDD p. 9; P-10). Parâmetros em
## economy.json, fight_profiles. Perfis do MVP: standard, jumper,
## deep_puller e burst_snagger; na Fase 6, breather (pirarucu). O chefe
## (Rei do Lago, 3 fases) entra na Fase 7 (P-27).

const STANDARD: String = "standard"
const JUMPER: String = "jumper"
const DEEP_PULLER: String = "deep_puller"
const BURST_SNAGGER: String = "burst_snagger"
const BREATHER: String = "breather"
const SUPPORTED: PackedStringArray = [STANDARD, JUMPER, DEEP_PULLER, BURST_SNAGGER, BREATHER]

var kind: String
var _params: Dictionary
var _rng: Rng
var _time_s: float = 0.0
var _burst_left_s: float = 0.0


func _init(p_kind: String, all_profiles: Dictionary, rng: Rng) -> void:
	assert(SUPPORTED.has(p_kind), "Perfil de briga ainda não implementado: %s" % p_kind)
	kind = p_kind
	_params = all_profiles[p_kind]
	_rng = rng


func advance(dt: float) -> void:
	_time_s += dt
	if kind != BURST_SNAGGER:
		return
	if _burst_left_s > 0.0:
		_burst_left_s = maxf(0.0, _burst_left_s - dt)
	elif _rng.chance(float(_params["burst_rate_per_s"]) * dt):
		_burst_left_s = float(_params["burst_duration_s"])


## Fator sobre a força base de puxada neste instante.
func pull_multiplier() -> float:
	var wave: float = (
		float(_params["wave_amplitude"]) * sin(TAU * _time_s / float(_params["wave_period_s"]))
	)
	var multiplier: float = 1.0 + wave
	if kind == DEEP_PULLER or kind == BREATHER:
		multiplier *= float(_params["pull_multiplier"])
	if kind == BURST_SNAGGER and is_bursting():
		multiplier *= float(_params["burst_multiplier"])
	if is_breathing():
		multiplier *= float(_params["breath_pull_multiplier"])
	return multiplier


## O pirarucu subiu para respirar: é a hora de recolher (GDD p. 9, "fôlego").
func is_breathing() -> bool:
	if kind != BREATHER:
		return false
	var every: float = float(_params["breath_every_s"])
	return fmod(_time_s, every) >= every - float(_params["breath_duration_s"])


## Fator sobre o avanço da linha ao recolher (o fôlego rende mais).
func reel_progress_multiplier() -> float:
	if is_breathing():
		return float(_params["breath_progress_multiplier"])
	return 1.0


## O peixe está fora d'água (tucunaré, dourado): o jogador precisa afrouxar.
func is_jumping() -> bool:
	if kind != JUMPER:
		return false
	var every: float = float(_params["jump_every_s"])
	return fmod(_time_s, every) >= every - float(_params["jump_duration_s"])


func is_bursting() -> bool:
	return _burst_left_s > 0.0


## Durante o pulo, a linha corre perigo acima de um limite menor e mais depressa.
func danger_threshold(default_threshold: float) -> float:
	if is_jumping():
		return minf(default_threshold, float(_params["jump_safe_max"]))
	return default_threshold


func danger_speed(default_speed: float) -> float:
	if is_jumping():
		return maxf(default_speed, float(_params["jump_danger_speed"]))
	return default_speed
