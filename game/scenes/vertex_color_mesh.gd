class_name VertexColorMesh
extends RefCounted
## Monta uma malha de uma superfície só a partir de modelos com vários materiais,
## pintando a cor de cada material nos vértices (Fase 7, desempenho). Um peixe do
## Blender tem três materiais (corpo, olho e pupila, para a variante albina trocar
## o olho): três draw calls. Montado aqui, o peixe custa um, e vários peixes
## juntos (a caixa de isopor) também custam um.

var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()


## Material que usa a cor dos vértices (as cores vêm em sRGB, como no material).
static func material() -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.vertex_color_use_as_albedo = true
	result.vertex_color_is_srgb = true
	result.roughness = 0.5
	return result


## Acrescenta todas as malhas de model, levadas por placed (espaço do modelo ->
## espaço da malha montada). color_of(material) dá a cor de cada superfície.
func append_model(model: Node3D, placed: Transform3D, color_of: Callable) -> void:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		var to_mesh: Transform3D = placed * MeshMerge.relative_transform(part, model)
		var normal_basis: Basis = to_mesh.basis.inverse().transposed()
		for surface in part.mesh.get_surface_count():
			var source: Array = part.mesh.surface_get_arrays(surface)
			var color: Color = color_of.call(part.mesh.surface_get_material(surface))
			var base: int = vertices.size()
			var source_vertices: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
			var source_normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
			for v in source_vertices.size():
				vertices.append(to_mesh * source_vertices[v])
				normals.append((normal_basis * source_normals[v]).normalized())
				colors.append(color)
			var source_indices: PackedInt32Array = source[Mesh.ARRAY_INDEX]
			if source_indices.is_empty():
				source_indices = PackedInt32Array(range(source_vertices.size()))
			for index in source_indices:
				indices.append(base + index)


## A malha montada (sem superfície, se nada foi acrescentado).
func commit() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if vertices.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
