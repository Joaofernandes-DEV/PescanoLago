class_name Rng
extends RefCounted
## Gerador pseudoaleatório determinístico do núcleo (xoshiro128**).
##
## Toda aleatoriedade do jogo passa por uma instância injetada desta classe;
## não existe RNG global. A mesma semente gera a mesma sequência em qualquer
## plataforma porque todas as contas são feitas em 32 bits sem estouro de
## inteiro de 64 bits (multiplicações divididas em metades de 16 bits).
## Referência do algoritmo: https://prng.di.unimi.it/xoshiro128starstar.c

const MASK_32: int = 0xFFFFFFFF
const _GOLDEN_GAMMA: int = 0x9E3779B9

var _s: PackedInt64Array = PackedInt64Array([0, 0, 0, 0])


func _init(seed: int = 0) -> void:
	set_seed(seed)


## Reinicia a sequência a partir de uma semente (qualquer int de 64 bits).
func set_seed(seed: int) -> void:
	var x: int = (seed ^ (seed >> 32)) & MASK_32
	for i in 4:
		x = (x + _GOLDEN_GAMMA) & MASK_32
		_s[i] = _fmix32(x)
	if _s[0] == 0 and _s[1] == 0 and _s[2] == 0 and _s[3] == 0:
		_s[0] = 1


## Estado completo, para salvar e restaurar a sequência exatamente.
func get_state() -> PackedInt64Array:
	return _s.duplicate()


func set_state(state: PackedInt64Array) -> void:
	assert(state.size() == 4, "Rng.set_state espera 4 palavras de 32 bits")
	for i in 4:
		_s[i] = state[i] & MASK_32


## Próximo inteiro sem sinal de 32 bits, em [0, 2^32).
func next_u32() -> int:
	var result: int = _mul32(_rotl(_mul32(_s[1], 5), 7), 9)
	var t: int = (_s[1] << 9) & MASK_32
	_s[2] ^= _s[0]
	_s[3] ^= _s[1]
	_s[1] ^= _s[2]
	_s[0] ^= _s[3]
	_s[2] ^= t
	_s[3] = _rotl(_s[3], 11)
	return result


## Float uniforme em [0, 1).
func next_float() -> float:
	return float(next_u32()) / 4294967296.0


## Inteiro uniforme em [min_value, max_value], sem viés (rejeição).
func range_int(min_value: int, max_value: int) -> int:
	assert(min_value <= max_value, "Rng.range_int: min_value > max_value")
	var span: int = max_value - min_value + 1
	assert(span <= 0x100000000, "Rng.range_int: intervalo maior que 2^32")
	var limit: int = 0x100000000 - (0x100000000 % span)
	var value: int = next_u32()
	while value >= limit:
		value = next_u32()
	return min_value + value % span


## Float uniforme em [min_value, max_value).
func range_float(min_value: float, max_value: float) -> float:
	return min_value + (max_value - min_value) * next_float()


## Verdadeiro com probabilidade `probability` (0 = nunca, 1 = sempre).
func chance(probability: float) -> bool:
	return next_float() < probability


## Índice sorteado proporcionalmente aos pesos (pesos <= 0 nunca saem).
## Retorna -1 se nenhum peso for positivo.
func weighted_index(weights: PackedFloat64Array) -> int:
	var total: float = 0.0
	for w in weights:
		if w > 0.0:
			total += w
	if total <= 0.0:
		return -1
	var roll: float = next_float() * total
	var last_positive: int = -1
	for i in weights.size():
		if weights[i] <= 0.0:
			continue
		last_positive = i
		roll -= weights[i]
		if roll < 0.0:
			return i
	return last_positive


static func _rotl(x: int, k: int) -> int:
	return ((x << k) | (x >> (32 - k))) & MASK_32


## Multiplicação módulo 2^32 sem passar de 2^48 em nenhuma parcela.
static func _mul32(a: int, b: int) -> int:
	var low: int = a * (b & 0xFFFF)
	var high: int = ((a * (b >> 16)) & 0xFFFF) << 16
	return (low + high) & MASK_32


## Finalizador do MurmurHash3, usado para espalhar a semente.
static func _fmix32(h: int) -> int:
	h ^= h >> 16
	h = _mul32(h, 0x85EBCA6B)
	h ^= h >> 13
	h = _mul32(h, 0xC2B2AE35)
	h ^= h >> 16
	return h
