class_name TouchJoystick
extends Control
## Joystick virtual para pilotar o barco no celular (aparece só com tela de toque).
## O resto do jogo funciona com toque porque a Godot transforma toque em clique.

var value := Vector2.ZERO
var _touch_index: int = -1
var _center := Vector2.ZERO
var _radius: float = 90.0


func _init() -> void:
	custom_minimum_size = Vector2(_radius * 2.4, _radius * 2.4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var local := touch.position - global_position
		if touch.pressed and _touch_index < 0 and Rect2(Vector2.ZERO, size).has_point(local):
			_touch_index = touch.index
			_center = size / 2.0
			_update(local)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			value = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update(drag.position - global_position)
			get_viewport().set_input_as_handled()


func _update(local: Vector2) -> void:
	value = ((local - size / 2.0) / _radius).limit_length(1.0)
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, _radius, Color(1, 1, 1, 0.15))
	draw_circle(center + value * _radius, _radius * 0.35, Color(1, 1, 1, 0.45))
