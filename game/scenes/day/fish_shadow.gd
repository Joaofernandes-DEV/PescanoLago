class_name FishShadow
extends MeshInstance3D
## Sombra do peixe chegando à isca (P-36): nos últimos segundos antes da mordida,
## uma mancha escura em forma de peixe nada até a boia, na superfície da água.
## Mostra ao jogador que a isca vai ser atacada, também na água aberta. Só
## visual: a hora da mordida é do núcleo (DaySession.bite_in_s).

## Quanto falta para a mordida (0 a 1) quando a sombra aparece: 0 = longe, 1 = na isca.
var progress: float = 0.0

var _cfg: Dictionary
var _water: LakeWater
var _from := Vector3.ZERO
var _material: StandardMaterial3D


## cfg: presentation.json, casting (shadow_*).
func setup(cfg: Dictionary, water: LakeWater) -> void:
	_cfg = cfg
	_water = water
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(cfg["shadow_length_m"]) * 0.42, float(cfg["shadow_length_m"]))
	mesh = plane
	var gradient := Gradient.new()
	var dark := Color(0.02, 0.05, 0.06, float(cfg["shadow_opacity"]))
	gradient.set_color(0, dark)
	gradient.set_color(1, Color(dark, 0.0))
	# Miolo sólido e borda suave: lê como um peixe, não como um borrão.
	gradient.add_point(0.6, dark)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	_material = StandardMaterial3D.new()
	_material.albedo_texture = texture
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.render_priority = 1
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


## Começa uma espera: a sombra vai sair de `from_angle` (rad) em volta da isca.
func start(bait: Vector3, from_angle: float) -> void:
	var distance: float = float(_cfg["shadow_start_m"])
	_from = bait + Vector3(cos(from_angle), 0.0, sin(from_angle)) * distance
	visible = false


## bite_in_s: segundos até a mordida (-1 = não está esperando). bait: onde a isca está.
func update_shadow(bite_in_s: float, bait: Vector3) -> void:
	var approach: float = float(_cfg["shadow_approach_s"])
	if bite_in_s < 0.0 or bite_in_s > approach:
		visible = false
		progress = 0.0
		return
	progress = 1.0 - bite_in_s / approach
	var eased: float = smoothstep(0.0, 1.0, progress)
	var at: Vector3 = _from.lerp(bait, eased)
	var surface: float = _water.height_at(at.x, at.z) if _water != null else 0.0
	position = Vector3(at.x, surface + 0.03, at.z)
	# O comprimento da mancha (eixo Z do plano) aponta para a isca.
	var heading := bait - _from
	rotation = Vector3(0.0, atan2(heading.x, heading.z), 0.0)
	# Aparece aos poucos, como o peixe subindo do fundo.
	_material.albedo_color = Color(1, 1, 1, clampf(progress * 3.0, 0.0, 1.0))
	visible = true
