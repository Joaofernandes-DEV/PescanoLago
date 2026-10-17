class_name BoatLooks
extends RefCounted
## Aparência do Esperança pelo nível das melhorias (GDD: "cada nível muda a
## aparência do barco"). O modelo do Blender traz as peças de cada nível como
## SM_<melhoria>_l<nível> (ex.: SM_motor_l2, SM_livewell_l3, SM_sonar_l2); aqui
## fica visível só a peça do nível atual. Sem peça para o nível, nada aparece
## (o sonar nível 1 é "Sem sonar").

const PART_PATTERN: String = "^SM_([a-z_]+)_l([0-9]+)$"


## Mostra só as peças dos níveis atuais. Devolve os nomes das peças visíveis.
static func apply(model: Node, state: PlayerState, db: ContentDB) -> PackedStringArray:
	var shown := PackedStringArray()
	var upgrades := db.upgrade_ids()
	var regex := RegEx.create_from_string(PART_PATTERN)
	for node in model.find_children("SM_*", "MeshInstance3D", true, false):
		var found := regex.search(node.name)
		if found == null or not upgrades.has(found.get_string(1)):
			continue
		var part := node as MeshInstance3D
		part.visible = int(found.get_string(2)) == state.level_of(found.get_string(1))
		if part.visible:
			shown.append(part.name)
	shown.sort()
	return shown
