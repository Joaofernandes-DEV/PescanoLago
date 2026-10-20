class_name FpsOverlay
extends CanvasLayer
## Contador de quadros por segundo no canto (Fase 5, medição de fps no celular).
## Ligado por "--fps-overlay" na linha de comando ou, na build web, por "?fps=1"
## no endereço da página (o celular não tem linha de comando; o modo de medição,
## "?medir=N", também liga). Mostra a média do
## último segundo e o pior quadro.

const LAYER: int = 100

var label: Label
var _frames: int = 0
var _clock: float = 0.0
var _worst_ms: float = 0.0


## O contador deve aparecer? (opções da linha de comando ou endereço da página web)
static func wanted(options: Dictionary) -> bool:
	if options.has("fps-overlay"):
		return true
	if OS.has_feature("web"):
		var query: Variant = JavaScriptBridge.eval("window.location.search", true)
		return query is String and String(query).contains("fps=1")
	return false


func _ready() -> void:
	layer = LAYER
	label = Label.new()
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -220
	label.offset_right = -12
	label.offset_top = 8
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.text = "-- fps"
	add_child(label)


func _process(delta: float) -> void:
	_frames += 1
	_clock += delta
	_worst_ms = maxf(_worst_ms, delta * 1000.0)
	if _clock >= 1.0:
		label.text = "%d fps  (pior %d ms)" % [roundi(_frames / _clock), roundi(_worst_ms)]
		_frames = 0
		_clock = 0.0
		_worst_ms = 0.0
