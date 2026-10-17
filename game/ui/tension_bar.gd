class_name TensionBar
extends Control
## Barra de tensão da linha: zona verde, marcador da tensão e risco de arrebentar.

var tension: float = 0.0
var green_min: float = 0.0
var green_max: float = 0.0
var bar_max: float = 1.0
var break_risk: float = 0.0
var fish_jumping: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(420, 34)


func set_state(
	p_tension: float, p_green_min: float, p_green_max: float, p_bar_max: float, risk: float
) -> void:
	tension = p_tension
	green_min = p_green_min
	green_max = p_green_max
	bar_max = p_bar_max
	break_risk = risk
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.08, 0.1, 0.12, 0.85))
	var x_min: float = size.x * green_min / bar_max
	var x_max: float = size.x * green_max / bar_max
	draw_rect(Rect2(x_min, 0.0, x_max - x_min, size.y), Color(0.36, 0.75, 0.42, 0.9))
	var danger := Color(0.9, 0.3, 0.2).lerp(Color(1.0, 0.1, 0.05), break_risk)
	draw_rect(
		Rect2(x_max, 0.0, size.x - x_max, size.y), danger * Color(1, 1, 1, 0.35 + 0.5 * break_risk)
	)
	var marker_x: float = size.x * clampf(tension / bar_max, 0.0, 1.0)
	draw_rect(Rect2(marker_x - 3.0, -4.0, 6.0, size.y + 8.0), Color.WHITE)
	if fish_jumping:
		draw_rect(rect, Color(1.0, 0.85, 0.2), false, 3.0)
