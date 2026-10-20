class_name Bite
extends RefCounted
## Espera pela mordida e fisgada (GDD p. 5; P-09, P-18).

enum Hook { MISSED, HOOKED, HOOKED_EARLY }


## Segundos até o peixe morder. Se o lançamento não alcança o cardume, demora mais.
static func wait_time_s(
	fishing: Dictionary, cast_distance_m: float, school_distance_m: float, rng: Rng
) -> float:
	var wait_range: Array = fishing["bite_wait_s"]
	var wait: float = rng.range_float(float(wait_range[0]), float(wait_range[-1]))
	if cast_distance_m < school_distance_m:
		wait *= float(fishing["short_cast_wait_multiplier"])
	return wait


## Segundos até a mordida na água aberta (P-36): a espera normal vezes o
## multiplicador da água aberta (peixes espalhados).
static func open_water_wait_s(fishing: Dictionary, rng: Rng) -> float:
	var wait_range: Array = fishing["bite_wait_s"]
	var wait: float = rng.range_float(float(wait_range[0]), float(wait_range[-1]))
	return wait * float(fishing["open_water"]["wait_multiplier"])


## Resultado da fisgada pelo tempo de reação do jogador e a janela da vara.
static func hook(reaction_s: float, window_s: float, hook_bonus: Dictionary) -> Hook:
	if reaction_s > window_s:
		return Hook.MISSED
	if reaction_s <= window_s * float(hook_bonus["early_window_fraction"]):
		return Hook.HOOKED_EARLY
	return Hook.HOOKED
