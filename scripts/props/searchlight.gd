extends SpotLight3D
## Sağa sola tarayan projektör.

@export var sweep_degrees: float = 35.0
@export var sweep_speed: float = 0.35
@export var phase: float = 0.0

var _base_rotation: Vector3
var _t: float = 0.0


func _ready() -> void:
	_base_rotation = rotation
	_t = phase


func _process(delta: float) -> void:
	_t += delta * sweep_speed
	rotation = _base_rotation + Vector3(sin(_t * 1.7) * 0.08, sin(_t) * deg_to_rad(sweep_degrees), 0)
