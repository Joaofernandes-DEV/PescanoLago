class_name Buoys
extends Node3D
## Boias antigas das Águas Fundas (GDD: "boias antigas"). Cada uma fica num ponto
## LOC_buoy_N do cenário, boiando nas ondas: sobe e desce com a água e inclina
## conforme a onda. As que ficam dentro do alcance do barco têm uma caixa
## COL_buoy_N no cenário (o barco bate nelas). Só visual: avança por advance(dt).

const BUOY_SCENE: String = "res://assets/models/props/buoy_old.glb"

var buoys: Array[Node3D] = []

var _cfg: Dictionary
var _water: LakeWater
var _yaws: Array[float] = []


## cfg: presentation.json, buoys. lake: o cenário com os pontos LOC_buoy_N.
func setup(cfg: Dictionary, lake: Node3D, water: LakeWater) -> void:
	_cfg = cfg
	_water = water
	for node in lake.find_children("LOC_buoy_*", "Node3D", true, false):
		var spot := node as Node3D
		var buoy: Node3D = (load(BUOY_SCENE) as PackedScene).instantiate()
		Palette.apply(buoy)
		add_child(buoy)
		buoy.global_position = spot.global_position
		buoys.append(buoy)
		_yaws.append(spot.global_rotation.y)
	advance(0.0)


func advance(_dt: float) -> void:
	var draft: float = float(_cfg["draft_m"])
	var tilt: float = float(_cfg["tilt_scale"])
	for i in buoys.size():
		var buoy := buoys[i]
		var at := buoy.position
		var surface: float = _water.height_at(at.x, at.z) if _water != null else 0.0
		buoy.position.y = surface - draft
		var up := Vector3.UP
		if _water != null:
			up = Vector3.UP.lerp(_water.normal_at(at.x, at.z), tilt).normalized()
		buoy.basis = _tilted(up, _yaws[i])


## Base com o eixo Y apontando para up e girada yaw em volta dele.
static func _tilted(up: Vector3, yaw: float) -> Basis:
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var side := up.cross(forward).normalized()
	return Basis(side, up, side.cross(up).normalized())
