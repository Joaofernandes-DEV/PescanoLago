class_name AimMarker
extends Node3D
## Alvo na água: um anel onde a isca vai cair com a força atual, na direção da
## mira. Fica verde quando o lançamento alcança o cardume e está na direção
## dele; laranja quando cai curto ou fora. Flutua com as ondas (LakeWater).

const GOOD := Color("7ce08a")
const SHORT := Color("ffb347")
const LIFT_M: float = 0.06

var water: LakeWater
var good: bool = false
var _ring: MeshInstance3D
var _material: StandardMaterial3D
var _time: float = 0.0


func _ready() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.75
	torus.rings = 24
	torus.ring_segments = 6
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.no_depth_test = true
	_material.render_priority = 2
	torus.material = _material
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.scale = Vector3(1.0, 0.25, 1.0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	visible = false


## Mostra o anel no ponto (x, z), verde se o lançamento é bom. strength de 0 a 1:
## mais forte quando o jogador está carregando.
func show_at(point: Vector3, is_good: bool, strength: float) -> void:
	good = is_good
	var height: float = water.height_at(point.x, point.z) if water != null else 0.0
	global_position = Vector3(point.x, height + LIFT_M, point.z)
	var color: Color = GOOD if is_good else SHORT
	color.a = lerpf(0.7, 0.95, clampf(strength, 0.0, 1.0))
	_material.albedo_color = color
	visible = true


func hide_marker() -> void:
	visible = false


## Pulsa devagar para chamar a atenção sem piscar.
func advance(dt: float) -> void:
	_time += dt
	var pulse: float = 1.0 + 0.08 * sin(_time * TAU * 0.8)
	_ring.scale = Vector3(pulse, 0.25, pulse)
