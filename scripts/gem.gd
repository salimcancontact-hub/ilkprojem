extends Area3D
## Toplanabilir kristal.

var _time: float = 0.0
var _base_y: float = 0.0

@onready var _mesh: Node3D = $Mesh


func _ready() -> void:
	add_to_group("gems")
	_base_y = _mesh.position.y
	_time = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_mesh.rotation.y += 2.0 * delta
	_mesh.position.y = _base_y + sin(_time * 3.0) * 0.15


func _on_body_entered(body: Node3D) -> void:
	if body is Player and not (body as Player).is_dead:
		remove_from_group("gems")
		Game.collect_gem()
		queue_free()
