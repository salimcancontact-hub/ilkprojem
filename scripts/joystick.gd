extends Control
## Çoklu dokunmatik destekli sanal joystick.

signal changed(value: Vector2)

@export var radius: float = 90.0
@export var knob_radius: float = 42.0

var value: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func reset() -> void:
	_touch_index = -1
	_knob = Vector2.ZERO
	_set_value(Vector2.ZERO)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1 and get_global_rect().has_point(touch.position):
			_touch_index = touch.index
			_update(touch.position)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_knob = Vector2.ZERO
			_set_value(Vector2.ZERO)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update(drag.position)
			get_viewport().set_input_as_handled()


func _update(screen_pos: Vector2) -> void:
	var local: Vector2 = screen_pos - global_position - size / 2.0
	_knob = local.limit_length(radius)
	_set_value(_knob / radius)


func _set_value(v: Vector2) -> void:
	value = v
	changed.emit(value)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0
	draw_circle(center, radius, Color(1, 1, 1, 0.15))
	draw_arc(center, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 3.0, true)
	draw_circle(center + _knob, knob_radius, Color(1, 1, 1, 0.55))
