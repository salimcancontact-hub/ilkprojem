extends OmniLight3D
## Ateş gibi titreyen ışık.

@export var base_energy: float = 2.0
@export var flicker: float = 0.6
@export var speed: float = 9.0

var _t: float = 0.0


func _ready() -> void:
	_t = randf() * 100.0


func _process(delta: float) -> void:
	_t += delta * speed
	light_energy = base_energy + (sin(_t) * 0.5 + sin(_t * 2.3 + 1.7) * 0.35 + sin(_t * 5.1) * 0.15) * flicker
