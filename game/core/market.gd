class_name Market
extends RefCounted
## Mercado de Dona Marô no cais: compra os peixes do viveiro.

var _db: ContentDB


func _init(db: ContentDB) -> void:
	_db = db


func value_of(fish: FishCatch) -> int:
	return Scoring.sale_value(fish, _db.species(fish.species_id), _db.economy)


## Valor total da venda (cada peixe arredondado para moedas inteiras).
func sell(fish_list: Array[FishCatch]) -> int:
	var total: int = 0
	for fish in fish_list:
		total += value_of(fish)
	return total
