class_name CoolerBox
extends Node3D
## A caixa de isopor do barco (Fase 7, P-37): o visual do viveiro. Fica dentro da
## peça do viveiro do nível atual (SM_livewell_l<nível>, que o BoatLooks deixa
## visível), abre e fecha a tampa (SM_livewell_l<nível>_lid, origem na dobradiça)
## e mostra deitados no fundo os peixes do viveiro.
##
## Para ficar leve:
## - mostra no máximo max_visible_fish peixes (os mais recentes; presentation.json,
##   landing);
## - junta os peixes numa malha só (contents, VertexColorMesh), com a cor de
##   cada parte nos vértices: um draw call para todos, em vez de três por peixe;
## - só desenha com a tampa aberta (fechada, a caixa esconde tudo) e sem sombra.

const PART_PATTERN: String = "^SM_livewell_l[0-9]+$"
## Folga até o lado de fora da caixa (parede de isopor e um respiro) e altura de
## cada camada de peixes (m).
const PAD_M: float = 0.06
const LAYER_M: float = 0.045
const ROWS_PER_LAYER: int = 3

## 0 = tampa fechada; 1 = aberta.
var lid_open: float = 0.0
var lid: Node3D
## Os peixes à mostra, numa malha só.
var contents: MeshInstance3D
## Quantos peixes a malha mostra.
var shown_count: int = 0
## Peixes do viveiro que a caixa representa (inclusive os que não aparecem).
var fish_count: int = 0

var _cfg: Dictionary
var _fish_cfg: Dictionary
var _db: ContentDB
var _inner := AABB()
var _shown_keys: Array[String] = []


## Encaixa a caixa na peça visível do viveiro do barco. cfg: presentation.json,
## landing; fish_cfg: presentation.json, fish.
static func attach(
	boat_model: Node3D, db: ContentDB, cfg: Dictionary, fish_cfg: Dictionary
) -> CoolerBox:
	var cooler := CoolerBox.new()
	cooler.name = "CoolerBox"
	cooler._db = db
	cooler._cfg = cfg
	cooler._fish_cfg = fish_cfg
	var regex := RegEx.create_from_string(PART_PATTERN)
	for node in boat_model.find_children("SM_livewell_l*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if regex.search(part.name) != null and part.visible:
			part.add_child(cooler)
			cooler.lid = part.find_child("%s_lid" % part.name, false, false) as Node3D
			LandingShow.no_shadows(cooler.lid)
			cooler._inner = part.get_aabb().grow(-PAD_M)
			break
	if cooler.get_parent() == null:
		boat_model.add_child(cooler)
	cooler.contents = MeshInstance3D.new()
	cooler.contents.name = "Fish"
	cooler.contents.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cooler.contents.material_override = VertexColorMesh.material()
	cooler.add_child(cooler.contents)
	cooler._update_visibility()
	return cooler


## Mostra os peixes do viveiro. hold_back: quantos dos últimos ainda não chegaram
## na caixa (o peixe que o Tom está guardando).
func sync(fish: Array[FishCatch], hold_back: int = 0) -> void:
	fish_count = maxi(0, fish.size() - hold_back)
	var first: int = maxi(0, fish_count - int(_cfg["max_visible_fish"]))
	var keys: Array[String] = []
	for i in range(first, fish_count):
		var item: FishCatch = fish[i]
		keys.append("%s|%s|%.3f" % [item.species_id, item.variant, item.weight_kg])
	if keys != _shown_keys:
		_shown_keys = keys
		_rebuild(fish.slice(first, fish_count))
	_update_visibility()


## Ponto (mundo) da vaga do peixe de índice i entre os que aparecem.
func slot_point(index: int) -> Vector3:
	return global_transform * _slot_local(index)


## Vaga onde o próximo peixe guardado vai deitar.
func next_slot_point() -> Vector3:
	return slot_point(mini(fish_count, int(_cfg["max_visible_fish"]) - 1))


## Centro da caixa no mundo, na altura da boca.
func top_point() -> Vector3:
	return global_transform * Vector3(_inner.get_center().x, _inner.end.y, _inner.get_center().z)


func set_lid(open: float) -> void:
	lid_open = clampf(open, 0.0, 1.0)
	if lid != null:
		var eased: float = lid_open * lid_open * (3.0 - 2.0 * lid_open)
		lid.rotation.x = deg_to_rad(float(_cfg["lid_open_deg"])) * eased
	_update_visibility()


func _update_visibility() -> void:
	contents.visible = lid_open > 0.0 and shown_count > 0


func _slot_local(index: int) -> Vector3:
	var slot: int = index % int(_cfg["max_visible_fish"])
	var row: int = slot % ROWS_PER_LAYER
	var layer: int = slot / ROWS_PER_LAYER
	var depth_u: float = (float(row) + 0.5) / float(ROWS_PER_LAYER)
	return Vector3(
		_inner.get_center().x,
		_inner.position.y + LAYER_M * (float(layer) + 0.5),
		lerpf(_inner.position.z, _inner.end.z, depth_u)
	)


## Refaz a malha com estes peixes, cada um na sua vaga.
func _rebuild(fish: Array[FishCatch]) -> void:
	var builder := VertexColorMesh.new()
	for slot in fish.size():
		_append_fish(builder, fish[slot], slot)
	shown_count = fish.size()
	contents.mesh = builder.commit()


func _append_fish(builder: VertexColorMesh, item: FishCatch, slot: int) -> void:
	var model: Node3D = FishLooks.instance(item.species_id)
	var species: Dictionary = _db.species(item.species_id)
	# Deitado de lado, atravessado na caixa; os grandes encolhem para caber.
	var size: float = FishLooks.scale_for(species, item.weight_kg, _fish_cfg)
	var shape: AABB = FishLooks.bounds(model)
	size = minf(size, _inner.size.x / maxf(shape.size.z, 0.01))
	var yaw: float = PI / 2.0 + (0.25 if slot % 2 == 0 else -0.25)
	var lying: Basis = (
		Basis(Vector3.UP, yaw)
		* Basis(Vector3.BACK, PI / 2.0)
		* Basis.from_scale(Vector3.ONE * size)
	)
	# O centro do peixe (não a origem, que fica na barriga) cai na vaga.
	var placed := Transform3D(lying, _slot_local(slot) - lying * shape.get_center())
	var cfg: Dictionary = _fish_cfg
	builder.append_model(
		model,
		placed,
		func(m: Material) -> Color: return FishLooks.surface_color(m, item.variant, cfg)
	)
	model.free()
