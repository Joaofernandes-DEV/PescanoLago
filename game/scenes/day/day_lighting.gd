class_name DayLighting
extends Node3D
## Sol, céu e luz ambiente que mudam ao longo do dia de pesca (amanhecer, dia,
## entardecer, noite), com as cores do art/STYLE_GUIDE.md (presentation.json).

var sun: DirectionalLight3D
var environment: Environment
var _sky: ProceduralSkyMaterial
var _phases: Dictionary
var _phase_starts: Dictionary
var _blend_s: float


## phases: presentation.json, phases; day_phases: economy.json (início de cada fase).
func setup(phases: Dictionary, day_phases: Array, blend_s: float) -> void:
	_phases = phases
	_blend_s = blend_s
	for phase: Dictionary in day_phases:
		_phase_starts[phase["id"]] = float(phase["start_s"])
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	add_child(sun)
	_sky = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = _sky
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	apply(0.0)


## Aplica a luz do instante `elapsed_s`, misturando com a fase anterior no início de cada fase.
func apply(elapsed_s: float) -> void:
	var current: String = "dawn"
	var previous: String = "dawn"
	for phase_id: String in _phase_starts:
		if elapsed_s >= float(_phase_starts[phase_id]):
			previous = current
			current = phase_id
	var since: float = elapsed_s - float(_phase_starts[current])
	var weight: float = clampf(since / _blend_s, 0.0, 1.0) if current != previous else 1.0
	var a: Dictionary = _phases[previous]
	var b: Dictionary = _phases[current]
	sun.light_color = _mix(a, b, "sun_color", weight)
	sun.light_energy = lerpf(float(a["sun_energy"]), float(b["sun_energy"]), weight)
	var elevation: float = lerpf(
		float(a["sun_elevation_deg"]), float(b["sun_elevation_deg"]), weight
	)
	sun.rotation_degrees = Vector3(-elevation, -35.0, 0.0)
	_sky.sky_top_color = _mix(a, b, "sky_top", weight)
	_sky.sky_horizon_color = _mix(a, b, "sky_horizon", weight)
	_sky.ground_horizon_color = _sky.sky_horizon_color
	_sky.ground_bottom_color = _mix(a, b, "ambient", weight).darkened(0.5)
	environment.ambient_light_color = _mix(a, b, "ambient", weight)
	environment.ambient_light_energy = 0.6


## Instante em que a fase já está inteira (depois da mistura com a anterior),
## para cenas com luz parada, como Porto Manso.
func phase_time(phase_id: String) -> float:
	return float(_phase_starts[phase_id]) + _blend_s


func current_sun_color() -> Color:
	return sun.light_color


static func _mix(a: Dictionary, b: Dictionary, key: String, weight: float) -> Color:
	return PresentationConfig.color(a[key]).lerp(PresentationConfig.color(b[key]), weight)
