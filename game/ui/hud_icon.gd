class_name HudIcon
extends TextureRect
## Ícone do HUD feito no Blender (assets/models/ui/hud_icons.glb, SM_icon_<nome>).
## A peça 3D é desenhada uma vez num SubViewport próprio (fundo transparente, luz
## e câmera ortográfica) e a imagem fica nesta TextureRect. Desenhar uma vez só
## mantém o custo por quadro igual ao de uma imagem comum.

const ICONS_SCENE: String = "res://assets/models/ui/hud_icons.glb"
const RENDER_PX: int = 96

var icon_name: String
var viewport: SubViewport


static func create(name_id: String, size_px: float) -> HudIcon:
	var icon := HudIcon.new()
	icon.icon_name = name_id
	icon.custom_minimum_size = Vector2(size_px, size_px)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## Nomes dos ícones que o modelo do Blender traz.
static func available() -> PackedStringArray:
	var names := PackedStringArray()
	var scene_root: Node = (load(ICONS_SCENE) as PackedScene).instantiate()
	for child in scene_root.get_children():
		names.append(String(child.name).trim_prefix("SM_icon_"))
	scene_root.free()
	return names


## Só a peça do ícone pedido (o resto da cena é liberado na hora).
static func _piece(name_id: String) -> MeshInstance3D:
	var scene_root: Node = (load(ICONS_SCENE) as PackedScene).instantiate()
	var piece := scene_root.get_node_or_null("SM_icon_%s" % name_id) as MeshInstance3D
	assert(piece != null, "HudIcon: ícone desconhecido '%s'" % name_id)
	scene_root.remove_child(piece)
	scene_root.free()
	return piece


func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(RENDER_PX, RENDER_PX)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)
	var piece := _piece(icon_name)
	Palette.apply(piece)
	viewport.add_child(piece)
	var aabb := piece.get_aabb()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(aabb.size.x, aabb.size.y) * 1.15
	camera.position = aabb.get_center() + Vector3(0.0, 0.0, 3.0)
	viewport.add_child(camera)
	camera.look_at(aabb.get_center(), Vector3.UP)
	camera.current = true
	# Leve giro para mostrar o volume da peça, como num ícone pintado.
	piece.rotation = Vector3(deg_to_rad(10.0), deg_to_rad(-20.0), 0.0)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-30.0), 0.0)
	sun.light_energy = 1.2
	viewport.add_child(sun)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.97, 0.9)
	env.ambient_light_energy = 0.7
	world.environment = env
	viewport.add_child(world)
	texture = viewport.get_texture()
