class_name Livewell
extends RefCounted
## Viveiro do barco: guarda os peixes até a venda no cais. Capacidade limitada.

var capacity: int
var _fish: Array[FishCatch] = []


func _init(p_capacity: int) -> void:
	capacity = p_capacity


func count() -> int:
	return _fish.size()


func is_full() -> bool:
	return _fish.size() >= capacity


## Guarda o peixe; devolve false se o viveiro já está cheio.
func add(fish: FishCatch) -> bool:
	if is_full():
		return false
	_fish.append(fish)
	return true


func contents() -> Array[FishCatch]:
	return _fish.duplicate()


## Esvazia o viveiro (venda no cais) e devolve os peixes.
func take_all() -> Array[FishCatch]:
	var taken: Array[FishCatch] = _fish
	_fish = []
	return taken
