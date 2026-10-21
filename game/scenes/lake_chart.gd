class_name LakeChart
extends RefCounted
## Carta do lago para o mapa (Fase 7, Bloco A, item 5): o contorno real da margem
## e as linhas de profundidade (isóbatas), tirados da malha do terreno do cenário
## (a malha *terrain* de cada região, feita no Blender). Assim cada região tem a
## carta dela sem números repetidos do Blender: as enseadas da margem e o fundo
## mais fundo das Águas Fundas vêm da própria malha.
##
## Como: o terreno vira uma grade de alturas (presentation.json, minimap,
## chart_cell_m); de cada ângulo (chart_rays), um raio sai do centro do lago e
## marca onde o fundo sobe acima de cada profundidade e onde sai da água (margem).
## Os polígonos ficam no plano (x, z) do mundo.

## Margem: onde o terreno sai da água, um ponto por raio.
var shore := PackedVector2Array()
## Isóbatas que existem no lago, da mais rasa à mais funda:
## {"depth_m": profundidade, "polygon": PackedVector2Array}.
var isobaths: Array[Dictionary] = []
## Ponto mais fundo dentro da margem (metros, positivo).
var max_depth_m: float = 0.0
## Meia largura do quadrado de mundo que a carta mostra (margem + folga em terra).
var extent_m: float = 0.0

var _cell_m: float = 1.0
var _side: int = 0
var _heights := PackedFloat32Array()


## Carta do cenário: lake é a raiz de LakeWorld.add_lake (na origem do mundo).
static func from_lake(lake: Node3D, cfg: Dictionary, shore_radius_m: float) -> LakeChart:
	var chart := LakeChart.new()
	chart.extent_m = shore_radius_m + float(cfg["chart_margin_m"])
	chart._cell_m = float(cfg["chart_cell_m"])
	chart._side = ceili(chart.extent_m * 2.0 / chart._cell_m) + 1
	chart._heights.resize(chart._side * chart._side)
	chart._heights.fill(NAN)
	for node in lake.find_children("*terrain*", "MeshInstance3D", true, false):
		chart._rasterize(node as MeshInstance3D, _to_lake(node as Node3D, lake))
	var depths: Array[float] = []
	for depth: Variant in cfg["isobaths_m"]:
		depths.append(float(depth))
	depths.sort()
	chart._trace(int(cfg["chart_rays"]), depths, shore_radius_m)
	return chart


## Altura do terreno no ponto (x, z) do mundo; NAN fora da carta ou sem terreno.
func height_at(world: Vector2) -> float:
	var g: Vector2 = (world + Vector2.ONE * extent_m) / _cell_m
	var i0: int = floori(g.x)
	var j0: int = floori(g.y)
	if i0 < 0 or j0 < 0 or i0 >= _side - 1 or j0 >= _side - 1:
		return NAN
	var fx: float = g.x - float(i0)
	var fy: float = g.y - float(j0)
	var total: float = 0.0
	var weight: float = 0.0
	for corner: Vector3 in [
		Vector3(0, 0, (1.0 - fx) * (1.0 - fy)),
		Vector3(1, 0, fx * (1.0 - fy)),
		Vector3(0, 1, (1.0 - fx) * fy),
		Vector3(1, 1, fx * fy)
	]:
		var h: float = _heights[(j0 + int(corner.y)) * _side + i0 + int(corner.x)]
		if not is_nan(h):
			total += h * corner.z
			weight += corner.z
	return total / weight if weight > 0.0 else NAN


## Profundidade da água no ponto (metros, 0 em terra).
func depth_at(world: Vector2) -> float:
	var h: float = height_at(world)
	return 0.0 if is_nan(h) else maxf(0.0, -h)


## Transformação do nó até a raiz do cenário (vale também fora da árvore).
static func _to_lake(node: Node3D, lake: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != lake:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform


## Grava a altura de cada ponto da grade coberto por um triângulo da malha.
func _rasterize(mesh_node: MeshInstance3D, xform: Transform3D) -> void:
	var mesh: Mesh = mesh_node.mesh
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = (
			arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		)
		var world := PackedVector3Array()
		world.resize(vertices.size())
		for i in vertices.size():
			world[i] = xform * vertices[i]
		var count: int = indices.size() if not indices.is_empty() else world.size()
		for t in range(0, count, 3):
			if indices.is_empty():
				_fill_triangle(world[t], world[t + 1], world[t + 2])
			else:
				_fill_triangle(world[indices[t]], world[indices[t + 1]], world[indices[t + 2]])


func _fill_triangle(a: Vector3, b: Vector3, c: Vector3) -> void:
	var pa := (Vector2(a.x, a.z) + Vector2.ONE * extent_m) / _cell_m
	var pb := (Vector2(b.x, b.z) + Vector2.ONE * extent_m) / _cell_m
	var pc := (Vector2(c.x, c.z) + Vector2.ONE * extent_m) / _cell_m
	var i_min: int = maxi(0, ceili(minf(pa.x, minf(pb.x, pc.x))))
	var i_max: int = mini(_side - 1, floori(maxf(pa.x, maxf(pb.x, pc.x))))
	var j_min: int = maxi(0, ceili(minf(pa.y, minf(pb.y, pc.y))))
	var j_max: int = mini(_side - 1, floori(maxf(pa.y, maxf(pb.y, pc.y))))
	if i_min > i_max or j_min > j_max:
		return
	var area: float = (pb - pa).cross(pc - pa)
	if absf(area) <= 0.0:
		return
	for j in range(j_min, j_max + 1):
		for i in range(i_min, i_max + 1):
			var p := Vector2(i, j)
			var wa: float = (pb - p).cross(pc - p) / area
			var wb: float = (pc - p).cross(pa - p) / area
			var wc: float = 1.0 - wa - wb
			if wa < 0.0 or wb < 0.0 or wc < 0.0:
				continue
			var h: float = a.y * wa + b.y * wb + c.y * wc
			var k: int = j * _side + i
			# Peças sobrepostas (fundo e beira do terreno): vale a mais alta.
			if is_nan(_heights[k]) or h > _heights[k]:
				_heights[k] = h


## De cada raio, do centro para fora: onde o fundo sobe acima de cada
## profundidade (isóbata) e onde sai da água (margem).
func _trace(rays: int, depths: Array[float], shore_radius_m: float) -> void:
	var levels: Array[float] = []
	for k in range(depths.size() - 1, -1, -1):
		levels.append(-depths[k])
	levels.append(0.0)
	var radii: Array[PackedFloat32Array] = []
	for level in levels:
		radii.append(PackedFloat32Array())
	var step: float = _cell_m * 0.5
	for ray in rays:
		var angle: float = TAU * float(ray) / float(rays)
		var dir := Vector2(cos(angle), sin(angle))
		var found: Array[float] = []
		var prev_h: float = height_at(Vector2.ZERO)
		var r: float = 0.0
		for level in levels:
			found.append(0.0 if prev_h >= level else -1.0)
		while r < extent_m and found[-1] < 0.0:
			var next_r: float = r + step
			var h: float = height_at(dir * next_r)
			if not is_nan(h):
				for k in levels.size():
					if found[k] < 0.0 and h >= levels[k]:
						var t: float = (levels[k] - prev_h) / maxf(h - prev_h, 0.0001)
						found[k] = r + clampf(t, 0.0, 1.0) * step
				prev_h = h
			r = next_r
		for k in levels.size():
			radii[k].append(found[k] if found[k] >= 0.0 else extent_m)
	shore = _polygon(radii[-1], step)
	max_depth_m = 0.0
	for j in _side:
		for i in _side:
			var at := Vector2(i, j) * _cell_m - Vector2.ONE * extent_m
			var h: float = _heights[j * _side + i]
			if not is_nan(h) and at.length() < shore_radius_m:
				max_depth_m = maxf(max_depth_m, -h)
	isobaths.clear()
	for k in range(levels.size() - 2, -1, -1):
		var widest: float = 0.0
		for radius in radii[k]:
			widest = maxf(widest, radius)
		if widest > _cell_m:
			isobaths.append({"depth_m": -levels[k], "polygon": _polygon(radii[k], step)})


## Polígono a partir do raio de cada ângulo (nunca no centro exato, para a
## triangulação não ter pontos repetidos).
static func _polygon(radii: PackedFloat32Array, min_radius: float) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for ray in radii.size():
		var angle: float = TAU * float(ray) / float(radii.size())
		polygon.append(Vector2(cos(angle), sin(angle)) * maxf(radii[ray], min_radius))
	return polygon
