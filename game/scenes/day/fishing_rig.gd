class_name FishingRig
extends Node3D
## A linha e a boia na água; o peixe saltando quando é pego ou quando pula.

const BUOY_SCENE: String = "res://assets/models/_test/test_buoy.glb"
const FISH_SCENE: String = "res://assets/models/fish/fish_generic.glb"

var buoy: Node3D
var fish: Node3D
var _line: MeshInstance3D
var _line_mesh: ImmediateMesh
var _anchor := Vector3.ZERO
var _time: float = 0.0
var _dip: float = 0.0
var _fish_show_s: float = 0.0


func _ready() -> void:
	buoy = (load(BUOY_SCENE) as PackedScene).instantiate()
	buoy.scale = Vector3.ONE * 3.0
	add_child(buoy)
	fish = (load(FISH_SCENE) as PackedScene).instantiate()
	add_child(fish)
	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.95, 0.95, 0.9)
	_line.material_override = material
	add_child(_line)
	hide_all()


func hide_all() -> void:
	buoy.visible = false
	fish.visible = false
	_line.visible = false


## Isca na água neste ponto.
func show_cast(point: Vector3) -> void:
	_anchor = Vector3(point.x, 0.0, point.z)
	buoy.visible = true
	_line.visible = true
	_dip = 0.0


## A boia afunda: o peixe mordeu.
func dip() -> void:
	_dip = 1.0


## Mostra o peixe saindo da água (pego ou pulando), proporcional ao peso.
func show_fish(weight_kg: float, duration_s: float) -> void:
	fish.visible = true
	fish.scale = Vector3.ONE * clampf(pow(maxf(weight_kg, 0.01) / 0.5, 1.0 / 3.0), 0.4, 3.0)
	_fish_show_s = duration_s


## Durante a briga, a boia vem em direção ao barco conforme a linha é recolhida.
func pull_toward(target: Vector3, remaining_fraction: float) -> void:
	var flat_target := Vector3(target.x, 0.0, target.z)
	buoy.global_position = flat_target.lerp(_anchor, clampf(remaining_fraction, 0.0, 1.0))


func step(dt: float, rod_tip: Vector3, fighting: bool) -> void:
	_time += dt
	if buoy.visible and not fighting:
		_dip = move_toward(_dip, 0.0, dt * 1.5)
		var bob: float = sin(_time * 3.0) * 0.03 - _dip * 0.18
		buoy.global_position = _anchor + Vector3.UP * bob
	if _fish_show_s > 0.0:
		_fish_show_s -= dt
		fish.global_position = buoy.global_position + Vector3.UP * (0.4 + sin(_time * 6.0) * 0.1)
		fish.rotation.x = sin(_time * 8.0) * 0.5
		if _fish_show_s <= 0.0:
			fish.visible = false
	_draw_line(rod_tip)


func _draw_line(rod_tip: Vector3) -> void:
	_line_mesh.clear_surfaces()
	if not _line.visible:
		return
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var end: Vector3 = buoy.global_position + Vector3.UP * 0.3
	var sag := (rod_tip + end) / 2.0 + Vector3.DOWN * 0.6
	var points: Array[Vector3] = [rod_tip, rod_tip.lerp(sag, 0.6), sag, sag.lerp(end, 0.5), end]
	for i in points.size() - 1:
		_line_mesh.surface_add_vertex(to_local(points[i]))
		_line_mesh.surface_add_vertex(to_local(points[i + 1]))
	_line_mesh.surface_end()
