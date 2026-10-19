class_name Palette
extends RefCounted
## Materiais de paleta dos modelos do Blender (Fase 5, desempenho): a cor de cada
## face vem gravada nos vértices (COLOR_0) e a malha usa só 1 a 3 materiais
## M_palette*, em vez de um material por cor (cada material é um draw call).
##
## A importação de glTF da Godot nem sempre liga "usar a cor do vértice como
## albedo" nesses materiais; aqui isso é garantido ao carregar a cena. Os valores
## exportados pelo Blender são lineares (vertex_color_is_srgb = false).

const PREFIX: String = "M_palette"


## Liga a cor do vértice nos materiais de paleta de todas as malhas abaixo de root.
## Devolve quantos materiais foram ajustados.
static func apply(root: Node) -> int:
	var fixed: int = 0
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as BaseMaterial3D
			if material == null or not material.resource_name.begins_with(PREFIX):
				continue
			if not material.vertex_color_use_as_albedo:
				material.vertex_color_use_as_albedo = true
				material.vertex_color_is_srgb = false
				fixed += 1
	return fixed
