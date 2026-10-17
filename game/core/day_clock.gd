class_name DayClock
extends RefCounted
## Cronômetro de um dia de pesca. O tempo só avança por tick(dt): não há
## relógio global, então a simulação é determinística.

var duration_s: float
var elapsed_s: float = 0.0
var _phase_ids: PackedStringArray = []
var _phase_starts: PackedFloat64Array = []


## phases: lista de {"id", "start_s"} em ordem (economy.json, day_phases).
func _init(p_duration_s: float, phases: Array) -> void:
	duration_s = p_duration_s
	for phase: Dictionary in phases:
		_phase_ids.append(phase["id"])
		_phase_starts.append(float(phase["start_s"]))


func tick(dt: float) -> void:
	elapsed_s = minf(duration_s, elapsed_s + maxf(dt, 0.0))


func remaining_s() -> float:
	return duration_s - elapsed_s


func is_over() -> bool:
	return elapsed_s >= duration_s


## Período do dia agora (dawn, day, dusk, night).
func phase() -> String:
	var current: String = _phase_ids[0]
	for i in _phase_ids.size():
		if elapsed_s >= _phase_starts[i]:
			current = _phase_ids[i]
	return current
