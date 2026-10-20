class_name MeshMerge
extends RefCounted
## Junta peças paradas numa malha só (Fase 7, desempenho): cada malha é pelo menos
## um draw call por quadro, e a meta é de até 150 em qualquer cenário (P-34).
## As peças continuam separadas no Blender; a Godot junta na hora de carregar só
## onde elas não se mexem (ex.: as pernas no lago, enquanto ninguém anda).
## Superfícies com o mesmo material viram uma superfície só.


## Junta as malhas de parts à malha de target (com a posição de cada uma em
## relação a ele) e apaga as peças. Devolve quantas superfícies a malha ficou.
static func into(target: MeshInstance3D, parts: Array[MeshInstance3D]) -> int:
	var tools: Dictionary = {}
	var materials: Dictionary = {}
	var sources: Array[MeshInstance3D] = [target]
	sources.append_array(parts)
	for source in sources:
		var to_target: Transform3D = relative_transform(source, target)
		for surface in source.mesh.get_surface_count():
			var material: Material = source.mesh.surface_get_material(surface)
			var key: String = material.resource_name if material != null else ""
			if not tools.has(key):
				tools[key] = SurfaceTool.new()
				materials[key] = material
			(tools[key] as SurfaceTool).append_from(source.mesh, surface, to_target)
	var merged := ArrayMesh.new()
	for key: String in tools:
		(tools[key] as SurfaceTool).commit(merged)
		merged.surface_set_material(merged.get_surface_count() - 1, materials[key])
	target.mesh = merged
	for part in parts:
		part.get_parent().remove_child(part)
		part.queue_free()
	return merged.get_surface_count()


## Transformação de part para o espaço de ancestor (funciona fora da árvore).
static func relative_transform(part: Node3D, ancestor: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var walk: Node = part
	while walk != ancestor and walk is Node3D:
		result = (walk as Node3D).transform * result
		walk = walk.get_parent()
	return result
