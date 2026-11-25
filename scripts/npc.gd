class_name Npc
extends StaticBody3D
## Konuşulabilen karakter. Oyuncu yaklaşınca "KONUŞ" düğmesi çıkar.

signal player_nearby(npc: Npc, is_near: bool)

@export var npc_id: String = "ADA"
@export_file("*.dlg") var dialog_path: String = ""
@export var start_node: String = "baslangic"
@export var body_color: Color = Color(0.4, 0.9, 0.6)

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("npcs")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	($Visual/Body as MeshInstance3D).material_override = mat
	$TalkArea.body_entered.connect(func(b: Node3D) -> void:
		if b is Player: player_nearby.emit(self, true))
	$TalkArea.body_exited.connect(func(b: Node3D) -> void:
		if b is Player: player_nearby.emit(self, false))


func head_position() -> Vector3:
	return global_position + Vector3(0, 1.5, 0)


func face_point(point: Vector3) -> void:
	var dir := point - global_position
	if Vector2(dir.x, dir.z).length_squared() > 0.001:
		_visual.rotation.y = atan2(-dir.x, -dir.z)
