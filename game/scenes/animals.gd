class_name Animals
extends Node3D
## Animais do cenário (GDD: "capivaras na margem, jacarés distantes"). Cada
## capivara pasta num ponto LOC_capybara_N do cenário, baixando e erguendo a
## cabeça com pausas; cada jacaré boia num ponto LOC_caiman_N, além do limite do
## barco, indo e voltando devagar ao longo da margem, com o dorso de fora e
## acompanhando as ondas. Só visual: avança por advance(dt), como as garças.

const CAPYBARA_SCENE: String = "res://assets/models/props/animal_capybara.glb"
const CAIMAN_SCENE: String = "res://assets/models/props/animal_caiman.glb"

var capybaras: Array[Node3D] = []
var caimans: Array[Node3D] = []
var time_s: float = 0.0

var _cfg: Dictionary
var _water: LakeWater
## Onde cada jacaré começou e a direção em que ele anda (a frente do modelo).
var _caiman_origins: Array[Vector3] = []
var _caiman_dirs: Array[Vector3] = []


## cfg: presentation.json, animals. lake: o cenário com os pontos LOC_.
func setup(cfg: Dictionary, lake: Node3D, water: LakeWater) -> void:
	_cfg = cfg
	_water = water
	for spot in _spots(lake, "LOC_capybara_*"):
		capybaras.append(_place(CAPYBARA_SCENE, spot))
	for spot in _spots(lake, "LOC_caiman_*"):
		var caiman := _place(CAIMAN_SCENE, spot)
		caimans.append(caiman)
		_caiman_origins.append(caiman.position)
		_caiman_dirs.append(caiman.basis.z.normalized())
	advance(0.0)


func advance(dt: float) -> void:
	time_s += dt
	var graze_rad: float = deg_to_rad(float(_cfg["capybara"]["graze_deg"]))
	var graze_w: float = TAU / float(_cfg["capybara"]["graze_cycle_s"])
	for i in capybaras.size():
		# Cabeça baixa a maior parte do tempo (pastando) e erguida de vez em quando.
		var wave: float = sin(time_s * graze_w + float(i) * 2.3)
		var down: float = clampf(wave * 1.6 + 0.6, 0.0, 1.0)
		head_of(i).rotation.x = graze_rad * down
	var caiman_cfg: Dictionary = _cfg["caiman"]
	var drift_w: float = TAU / float(caiman_cfg["drift_cycle_s"])
	for i in caimans.size():
		var offset: float = sin(time_s * drift_w + float(i) * 1.7) * float(caiman_cfg["drift_m"])
		var at: Vector3 = _caiman_origins[i] + _caiman_dirs[i] * offset
		var surface: float = _water.height_at(at.x, at.z) if _water != null else 0.0
		caimans[i].position = Vector3(at.x, surface - float(caiman_cfg["depth_m"]), at.z)


func head_of(index: int) -> Node3D:
	return capybaras[index].find_child("SM_capybara_head", true, false) as Node3D


func _spots(lake: Node3D, pattern: String) -> Array[Node3D]:
	var spots: Array[Node3D] = []
	for node in lake.find_children(pattern, "Node3D", true, false):
		spots.append(node as Node3D)
	return spots


func _place(scene_path: String, spot: Node3D) -> Node3D:
	var animal: Node3D = (load(scene_path) as PackedScene).instantiate()
	Palette.apply(animal)
	add_child(animal)
	animal.global_transform = spot.global_transform
	return animal
