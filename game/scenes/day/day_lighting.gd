class_name DayLighting
extends Node3D
## Sol, céu e luz ambiente que mudam ao longo do dia de pesca (amanhecer, dia,
## entardecer, noite), com as cores do art/STYLE_GUIDE.md (presentation.json).
## O ambiente (tonemap AgX, glow, SSAO, névoa na cor do horizonte e sombras)
## vem de presentation.json, rendering. SSAO só existe no Forward+; nos outros
## renderizadores a Godot ignora o ajuste.

var sun: DirectionalLight3D
var environment: Environment
var _sky: ProceduralSkyMaterial
var _phases: Dictionary
var _phase_starts: Dictionary
var _blend_s: float


## pres: presentation.json (phases, phase_blend_s, rendering); day_phases: economy.json.
func setup(pres: PresentationConfig, day_phases: Array) -> void:
	_phases = pres.section("phases")
	_blend_s = float(pres.data["phase_blend_s"])
	var rendering: Dictionary = pres.section("rendering")
	for phase: Dictionary in day_phases:
		_phase_starts[phase["id"]] = float(phase["start_s"])
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = float(rendering["shadow_max_distance_m"])
	sun.shadow_blur = float(rendering["shadow_blur"])
	sun.light_angular_distance = float(rendering["sun_angular_size_deg"])
	add_child(sun)
	_sky = ProceduralSkyMaterial.new()
	_sky.sun_angle_max = float(rendering["sun_disk_deg"])
	var sky := Sky.new()
	sky.sky_material = _sky
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = float(rendering["exposure"])
	environment.glow_enabled = true
	environment.glow_intensity = float(rendering["glow_intensity"])
	environment.glow_bloom = float(rendering["glow_bloom"])
	environment.ssao_enabled = bool(rendering["ssao"])
	environment.fog_enabled = true
	environment.fog_density = float(rendering["fog_density"])
	environment.fog_sky_affect = 0.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = float(rendering["saturation"])
	environment.adjustment_contrast = float(rendering["contrast"])
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
	environment.fog_light_color = _sky.sky_horizon_color
	environment.ambient_light_energy = 0.6


## Instante em que a fase já está inteira (depois da mistura com a anterior),
## para cenas com luz parada, como Porto Manso.
func phase_time(phase_id: String) -> float:
	return float(_phase_starts[phase_id]) + _blend_s


## Cor do horizonte agora (a água reflete esta cor em ângulo rasante).
func horizon_color() -> Color:
	return _sky.sky_horizon_color


func current_sun_color() -> Color:
	return sun.light_color


static func _mix(a: Dictionary, b: Dictionary, key: String, weight: float) -> Color:
	return PresentationConfig.color(a[key]).lerp(PresentationConfig.color(b[key]), weight)
