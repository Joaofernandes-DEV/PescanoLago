class_name PlayerBot
extends RefCounted
## Jogador simulado: reage à mordida e controla a tensão como uma pessoa
## jogaria. Usado nos testes de integração e no simulador de balanceamento.
## Perfis (casual, skilled) em game/content/sim_profiles.json.

var profile_id: String
var _cfg: Dictionary
var _rng: Rng
var _reeling: bool = false
var _was_jumping: bool = false
var _reacting_to_jump: bool = false


func _init(profile: Dictionary, rng: Rng) -> void:
	profile_id = profile["id"]
	_cfg = profile
	_rng = rng


## Tempo entre a boia afundar e o jogador fisgar.
func reaction_time_s() -> float:
	var reaction: Array = _cfg["reaction_s"]
	return _rng.range_float(float(reaction[0]), float(reaction[-1]))


## Erro de pontaria: o jogador mira no cardume e acerta distância × este fator.
func aim_factor() -> float:
	var aim: Array = _cfg["aim_factor"]
	return _rng.range_float(float(aim[0]), float(aim[-1]))


## Recolhe ou solta, com histerese em torno da tensão-alvo. A cada pulo do
## peixe, o jogador percebe (e afrouxa) com a chance do seu perfil.
func decide_reeling(game: TensionMinigame) -> bool:
	var jumping: bool = game.profile.is_jumping()
	if jumping and not _was_jumping:
		_reacting_to_jump = _rng.chance(float(_cfg["jump_reaction_chance"]))
	_was_jumping = jumping
	if jumping and _reacting_to_jump:
		_reeling = false
		return _reeling
	var target: float = float(_cfg["target_tension"])
	var hysteresis: float = float(_cfg["hysteresis"])
	if _reeling and game.tension > target + hysteresis:
		_reeling = false
	elif not _reeling and game.tension < target - hysteresis:
		_reeling = true
	return _reeling


## Joga o mini-jogo até o fim com passo fixo e devolve o resultado.
func fight(game: TensionMinigame, step_s: float) -> TensionMinigame.Result:
	_reeling = false
	_was_jumping = false
	while not game.is_over():
		game.step(step_s, decide_reeling(game))
	return game.result
