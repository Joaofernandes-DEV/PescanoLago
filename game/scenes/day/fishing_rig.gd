class_name FishingRig
extends Node3D
## A linha e a boia na água; o voo da isca no lançamento; o peixe saltando na
## briga e pendurado na linha quando é pego; respingos onde a isca cai e onde o
## peixe sai e volta à água.
##
## O lançamento dura o tempo de lançar das regras (economy.json, fishing.cast_s):
## a isca sai da ponta da vara, faz um arco com a linha esticada atrás e pousa na
## água quando o DaySession passa a esperar a mordida.
##
## O salto é um arco balístico (gravidade de verdade), com o peixe apontando para
## onde vai; a altura cresce com o tamanho do peixe (presentation.json, fish).

## A isca tocou a água (fim do voo do lançamento).
signal landed(point: Vector3)

const BUOY_SCENE: String = "res://assets/models/_test/test_buoy.glb"
const GRAVITY_M_S2: float = 9.81
## Até onde a linha chega do centro do barco no fim da briga (canoa de 1,1 m de boca).
const BOAT_SIDE_M: float = 1.6
## Barriga da linha: esticada no voo da isca, solta com a boia parada.
const SAG_FLYING_M: float = 0.1
const SAG_RESTING_M: float = 0.6

var buoy: Node3D
## Peixe à mostra agora (modelo da espécie), ou null.
var fish: Node3D
var fish_species: String = ""
var splashes: int = 0
## A isca está voando (lançamento em andamento).
var flying: bool = false

var _cfg: Dictionary
var _line: MeshInstance3D
var _line_mesh: ImmediateMesh
var _splash: CPUParticles3D
var _anchor := Vector3.ZERO
var _time: float = 0.0
var _dip: float = 0.0
## "jump" (arco na água), "catch" (pendurado na linha) ou "" (sem peixe).
var _fish_mode: String = ""
var _fish_t: float = 0.0
var _jump_v0: float = 0.0
var _jump_drift := Vector3.ZERO
var _jump_from := Vector3.ZERO
var _catch_s: float = 0.0
var _flight_from := Vector3.ZERO
var _flight_t: float = 0.0
var _flight_s: float = 0.0
var _flight_apex: float = 0.0


## cfg: presentation.json, fish.
func setup(cfg: Dictionary) -> void:
	_cfg = cfg


func _ready() -> void:
	buoy = (load(BUOY_SCENE) as PackedScene).instantiate()
	buoy.scale = Vector3.ONE * 3.0
	add_child(buoy)
	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.95, 0.95, 0.9)
	_line.material_override = material
	add_child(_line)
	_build_splash()
	hide_all()


func _build_splash() -> void:
	_splash = CPUParticles3D.new()
	_splash.emitting = false
	_splash.one_shot = true
	_splash.explosiveness = 0.9
	_splash.amount = 28
	_splash.lifetime = 0.9
	_splash.direction = Vector3.UP
	_splash.spread = 35.0
	_splash.initial_velocity_min = 1.8
	_splash.initial_velocity_max = 3.4
	_splash.gravity = Vector3(0.0, -GRAVITY_M_S2, 0.0)
	_splash.scale_amount_min = 0.6
	_splash.scale_amount_max = 1.2
	var drop := SphereMesh.new()
	drop.radius = 0.05
	drop.height = 0.1
	drop.radial_segments = 6
	drop.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.98, 1.0)
	material.roughness = 0.2
	drop.material = material
	_splash.mesh = drop
	add_child(_splash)


func hide_all() -> void:
	buoy.visible = false
	_line.visible = false
	flying = false
	_clear_fish()


## Isca na água neste ponto (com respingo).
func show_cast(point: Vector3) -> void:
	_anchor = Vector3(point.x, 0.0, point.z)
	buoy.visible = true
	_line.visible = true
	_dip = 0.0
	splash(_anchor, 0.7)


## Lança a isca da ponta da vara até o ponto na água, num arco de altura
## apex_m, em duration_s segundos. No fim, respingo e sinal landed.
func launch(rod_tip: Vector3, point: Vector3, duration_s: float, apex_m: float) -> void:
	_anchor = Vector3(point.x, 0.0, point.z)
	_flight_from = rod_tip
	_flight_t = 0.0
	_flight_s = maxf(duration_s, 0.01)
	_flight_apex = apex_m
	flying = true
	buoy.visible = true
	_line.visible = true
	_dip = 0.0
	buoy.global_position = rod_tip


## Ponto da água onde a isca caiu (ou vai cair, durante o voo).
func target_point() -> Vector3:
	return _anchor


## Onde a isca está no voo, na fração u (0 = ponta da vara, 1 = água).
func flight_point(u: float) -> Vector3:
	var t: float = clampf(u, 0.0, 1.0)
	return _flight_from.lerp(_anchor, t) + Vector3.UP * (4.0 * _flight_apex * t * (1.0 - t))


## A boia afunda: o peixe mordeu.
func dip() -> void:
	_dip = 1.0


## Respingo na água neste ponto (size: 1 = peixe médio).
func splash(point: Vector3, size: float) -> void:
	_splash.global_position = Vector3(point.x, 0.05, point.z)
	_splash.scale_amount_min = 0.5 * size
	_splash.scale_amount_max = 1.1 * size
	_splash.initial_velocity_max = 2.2 + 1.6 * size
	_splash.restart()
	_splash.emitting = true
	splashes += 1


## Peixe pulando na briga: sai da água perto da boia, faz um arco e volta.
func jump_fish(species: Dictionary, weight_kg: float, variant: String) -> void:
	if _fish_mode == "jump":
		return
	var size: float = _show_species(species, weight_kg, variant)
	var height: float = float(_cfg["jump_height_m"]) * (0.6 + 0.4 * size)
	_jump_v0 = sqrt(2.0 * GRAVITY_M_S2 * height)
	_jump_from = Vector3(buoy.global_position.x, 0.0, buoy.global_position.z)
	var heading: float = _time * 1.7
	_jump_drift = Vector3(cos(heading), 0.0, sin(heading)) * 0.8
	_fish_mode = "jump"
	_fish_t = 0.0
	splash(_jump_from, size)


## Peixe pego: sai da água e fica pendurado na ponta da linha, se debatendo.
func show_catch(species: Dictionary, weight_kg: float, variant: String, duration_s: float) -> void:
	var size: float = _show_species(species, weight_kg, variant)
	splash(buoy.global_position, size)
	_fish_mode = "catch"
	_catch_s = duration_s
	_fish_t = 0.0


## Tempo de voo de um salto agora (s): sobe e desce até a água.
func jump_duration() -> float:
	return 2.0 * _jump_v0 / GRAVITY_M_S2


## Durante a briga, a boia vem em direção ao barco conforme a linha é recolhida.
## A linha termina na água ao lado do casco (BOAT_SIDE_M), nunca dentro do barco.
func pull_toward(target: Vector3, remaining_fraction: float) -> void:
	var flat_target := Vector3(target.x, 0.0, target.z)
	var to_anchor := _anchor - flat_target
	if to_anchor.length() > BOAT_SIDE_M:
		flat_target += to_anchor.normalized() * BOAT_SIDE_M
	buoy.global_position = flat_target.lerp(_anchor, clampf(remaining_fraction, 0.0, 1.0))


func step(dt: float, rod_tip: Vector3, fighting: bool) -> void:
	_time += dt
	if flying:
		_step_flight(dt)
	elif buoy.visible and not fighting:
		_dip = move_toward(_dip, 0.0, dt * 1.5)
		var bob: float = sin(_time * 3.0) * 0.03 - _dip * 0.18
		buoy.global_position = _anchor + Vector3.UP * bob
	match _fish_mode:
		"jump":
			_step_jump(dt)
		"catch":
			_step_catch(dt, rod_tip)
	_draw_line(rod_tip)


func _step_flight(dt: float) -> void:
	_flight_t += dt
	var u: float = _flight_t / _flight_s
	buoy.global_position = flight_point(u)
	if u >= 1.0:
		flying = false
		buoy.global_position = _anchor
		splash(_anchor, 0.7)
		landed.emit(_anchor)


func _step_jump(dt: float) -> void:
	_fish_t += dt
	var height: float = _jump_v0 * _fish_t - 0.5 * GRAVITY_M_S2 * _fish_t * _fish_t
	var vertical_speed: float = _jump_v0 - GRAVITY_M_S2 * _fish_t
	fish.global_position = _jump_from + _jump_drift * _fish_t + Vector3.UP * maxf(height, 0.0)
	# Aponta para onde vai: nariz para cima subindo e para baixo descendo.
	var horizontal: float = _jump_drift.length()
	fish.rotation = Vector3(
		-atan2(vertical_speed, horizontal), atan2(_jump_drift.x, _jump_drift.z), 0.0
	)
	if height <= 0.0 and _fish_t > 0.05:
		splash(fish.global_position, fish.scale.x)
		_clear_fish()


func _step_catch(dt: float, rod_tip: Vector3) -> void:
	_fish_t += dt
	_catch_s -= dt
	# Sobe da água até ficar pendurado abaixo da ponta da vara, balançando.
	var lift: float = clampf(_fish_t / 0.5, 0.0, 1.0)
	var hang := rod_tip + Vector3.DOWN * (0.6 + 0.3 * fish.scale.x)
	var from := Vector3(buoy.global_position.x, 0.0, buoy.global_position.z)
	fish.global_position = from.lerp(hang, lift * lift * (3.0 - 2.0 * lift))
	fish.rotation = Vector3(
		-PI / 2.0 + sin(_time * 9.0) * 0.25, _time * 0.8, sin(_time * 13.0) * 0.4
	)
	buoy.global_position = fish.global_position
	if _catch_s <= 0.0:
		hide_all()


func _show_species(species: Dictionary, weight_kg: float, variant: String) -> float:
	var species_id: String = species["id"]
	if fish == null or fish_species != species_id:
		_clear_fish()
		fish = FishLooks.instance(species_id)
		fish_species = species_id
		add_child(fish)
	fish.visible = true
	var size: float = FishLooks.scale_for(species, weight_kg, _cfg)
	fish.scale = Vector3.ONE * size
	FishLooks.apply_variant(fish, variant, _cfg)
	return size


func _clear_fish() -> void:
	_fish_mode = ""
	if fish != null:
		fish.visible = false


func is_showing_fish() -> bool:
	return fish != null and fish.visible


func _draw_line(rod_tip: Vector3) -> void:
	_line_mesh.clear_surfaces()
	if not _line.visible:
		return
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var end: Vector3 = buoy.global_position + Vector3.UP * (0.0 if flying else 0.3)
	var sag_m: float = SAG_FLYING_M if flying else SAG_RESTING_M
	var sag := (rod_tip + end) / 2.0 + Vector3.DOWN * sag_m
	var points: Array[Vector3] = [rod_tip, rod_tip.lerp(sag, 0.6), sag, sag.lerp(end, 0.5), end]
	for i in points.size() - 1:
		_line_mesh.surface_add_vertex(to_local(points[i]))
		_line_mesh.surface_add_vertex(to_local(points[i + 1]))
	_line_mesh.surface_end()
