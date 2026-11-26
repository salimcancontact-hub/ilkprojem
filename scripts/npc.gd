class_name Npc
extends StaticBody3D
## Konuşulabilen karakter. Oyuncu yaklaşınca "KONUŞ" düğmesi çıkar.

signal player_nearby(npc: Npc, is_near: bool)

@export var npc_id: String = "ADA"
@export_file("*.dlg") var dialog_path: String = ""
@export var start_node: String = "baslangic"
@export var model_scene: PackedScene

var model: CharacterModel

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("npcs")
	if model_scene:
		model = model_scene.instantiate()
		_visual.add_child(model)
	$TalkArea.body_entered.connect(func(b: Node3D) -> void:
		if b is Player: player_nearby.emit(self, true))
	$TalkArea.body_exited.connect(func(b: Node3D) -> void:
		if b is Player: player_nearby.emit(self, false))


func head_position() -> Vector3:
	return global_position + Vector3(0, 1.55, 0)


func face_point(point: Vector3) -> void:
	var dir := point - global_position
	if Vector2(dir.x, dir.z).length_squared() > 0.001:
		_visual.rotation.y = atan2(-dir.x, -dir.z)
