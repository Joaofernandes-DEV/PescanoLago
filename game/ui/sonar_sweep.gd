class_name SonarSweep
extends RefCounted
## Varredura do sonar no mapa (Fase 7, Bloco A, item 5): um feixe gira em volta
## do barco, no sentido do relógio; quando passa por um cardume dentro do alcance,
## o ponto dele acende (eco, com o som de ping) e vai sumindo até a próxima volta.
## Só visual: o alcance é o do sonar do barco (boat_upgrades.json, range_m), e sem
## sonar não há varredura nem pontos (P-30).

## Ângulo do feixe no plano (x, z) do mundo: 0 = leste (+x), crescendo para o sul
## (+z), que no mapa (norte para cima) é o sentido do relógio.
var angle_rad: float = 0.0
var range_m: float = 0.0
## Pontos acesos: {"school": índice, "at": Vector2 (x, z), "age_s": segundos}.
var blips: Array[Dictionary] = []
var period_s: float = 1.0
var fade_s: float = 1.0
var trail_rad: float = 0.0


## cfg: presentation.json, minimap, sonar.
func setup(cfg: Dictionary) -> void:
	period_s = float(cfg["sweep_period_s"])
	fade_s = float(cfg["blip_fade_s"])
	trail_rad = float(cfg["trail_rad"])


## Avança o feixe; devolve quantos cardumes ele achou agora (cada um é um ping).
func step(dt: float, boat: Vector2, p_range_m: float, schools: Array[Vector2]) -> int:
	range_m = p_range_m
	for k in range(blips.size() - 1, -1, -1):
		blips[k]["age_s"] = float(blips[k]["age_s"]) + dt
		if float(blips[k]["age_s"]) >= fade_s:
			blips.remove_at(k)
	if range_m <= 0.0:
		blips.clear()
		return 0
	var swept: float = TAU * dt / period_s
	var from_rad: float = angle_rad
	angle_rad = fposmod(angle_rad + swept, TAU)
	var echoes: int = 0
	for i in schools.size():
		var offset: Vector2 = schools[i] - boat
		if offset.length() > range_m or offset.length_squared() <= 0.0:
			continue
		if fposmod(offset.angle() - from_rad, TAU) < swept:
			_light(i, schools[i])
			echoes += 1
	return echoes


## Brilho do ponto, de 1 (acabou de acender) a 0 (sumiu).
func glow(blip: Dictionary) -> float:
	return clampf(1.0 - float(blip["age_s"]) / fade_s, 0.0, 1.0)


func _light(school: int, at: Vector2) -> void:
	for blip in blips:
		if int(blip["school"]) == school:
			blip["at"] = at
			blip["age_s"] = 0.0
			return
	blips.append({"school": school, "at": at, "age_s": 0.0})
