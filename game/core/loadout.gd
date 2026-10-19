class_name Loadout
extends RefCounted
## Equipamento do jogador num dia de pesca: vara com as peças extras, isca
## equipada e melhorias do barco, já somados (GDD p. 5-7; P-18, P-29).
## O DaySession lê tudo daqui, então o efeito de cada compra fica num lugar só.

const NIGHT: String = "night"

var _db: ContentDB
var _state: PlayerState
var _rod: Dictionary
var _parts: Array[Dictionary] = []


func _init(db: ContentDB, state: PlayerState) -> void:
	_db = db
	_state = state
	_rod = db.rod(state.equipped_rod)
	for part_id: String in state.parts_on(state.equipped_rod):
		if db.is_enabled("rod_parts", part_id):
			_parts.append(db.rod_parts[part_id])


func range_m() -> float:
	return float(_rod["range_m"])


## Resistência da linha, com a linha trançada.
func line_strength_kg() -> float:
	return float(_rod["line_strength_kg"]) * _part_product("line_strength_factor")


## Velocidade de recolher, com a carretilha melhor.
func reel_speed_m_s() -> float:
	return _db.reel_speed_m_s(_state.equipped_rod) * _part_product("reel_speed_factor")


## Janela de fisgada, com o anzol afiado.
func hook_window_s() -> float:
	var bonus: float = 0.0
	for part in _parts:
		bonus += float(part["effects"].get("hook_window_bonus_s", 0.0))
	return float(_rod["hook_window_s"]) + bonus


## Chance extra de variante: sonar, conforto e nível da isca artificial.
func variant_chance_bonus() -> float:
	var bonus: float = float(_upgrade("sonar")["variant_chance_bonus"])
	bonus += float(_upgrade("comfort")["variant_chance_bonus"])
	return bonus + float(_artificial_level().get("variant_chance_bonus", 0.0))


## Raio de atração da isca: um lançamento que cai a essa distância do cardume
## conta como no cardume (GDD: os níveis aumentam o raio de atração).
func attraction_radius_m() -> float:
	return float(_artificial_level().get("attraction_radius_m", 0.0))


## Segundos a mais no dia de pesca (conforto).
func extra_time_s() -> float:
	return float(_upgrade("comfort")["extra_time_s"])


## A noite exige farol (GDD p. 5).
func can_fish_at(phase: String) -> bool:
	return phase != NIGHT or bool(_upgrade("lights")["night_fishing"])


## Fator sobre a espera pela mordida: à noite, as luzes e a boia luminosa ajudam.
func bite_wait_factor(phase: String) -> float:
	if phase != NIGHT:
		return 1.0
	return (
		float(_upgrade("lights")["night_bite_wait_factor"])
		* _part_product("night_bite_wait_factor")
	)


## Fator sobre a chance dos peixes de superfície: o motor barulhento os espanta.
func surface_multiplier() -> float:
	return float(_upgrade("motor")["surface_scare_multiplier"])


func _upgrade(upgrade_id: String) -> Dictionary:
	return _db.upgrade_level(upgrade_id, _state.level_of(upgrade_id))


func _artificial_level() -> Dictionary:
	var bait_id: String = _state.equipped_bait
	var level: int = _state.artificial_level(bait_id)
	if _db.bait(bait_id)["type"] != "artificial" or level <= 0:
		return {}
	return _db.bait(bait_id)["levels"][level - 1]


func _part_product(effect: String) -> float:
	var product: float = 1.0
	for part in _parts:
		product *= float(part["effects"].get(effect, 1.0))
	return product
