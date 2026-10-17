class_name Combo
extends RefCounted
## Combo de peixes seguidos sem perder a linha (P-04):
## multiplicador = min(máximo, 1 + passo × (peixes seguidos − 1)).

var streak: int = 0
var _step: float
var _max_multiplier: float


func _init(step: float, max_multiplier: float) -> void:
	_step = step
	_max_multiplier = max_multiplier


## Registra um peixe pego e devolve o multiplicador que vale para ele.
func register_catch() -> float:
	streak += 1
	return multiplier()


func multiplier() -> float:
	if streak == 0:
		return 1.0
	return minf(_max_multiplier, 1.0 + _step * (streak - 1))


## Linha arrebentou ou o peixe escapou: o combo zera.
func break_chain() -> void:
	streak = 0
