class_name Npc
extends StaticBody3D
## Konuşulabilen karakter. Oyuncu yaklaşınca "KONUŞ" düğmesi çıkar.

signal player_nearby(npc: Npc, is_near: bool)

@export var npc_id: String = "ADA"
@export_file("*.dlg") var dialog_path: String = ""
@export var start_node: String = "baslangic"
@export var model_scene: PackedScene
## Etkileşim düğmesinde yazan metin.
@export var prompt: String = "KONUŞ"
## Kameranın baktığı yükseklik (yerdeki bir nesne için küçük değer).
@export var focus_height: float = 1.55
## Karakterin boştayken oynattığı animasyon.
@export var idle_animation: String = "Idle"
## false ise oyuncu yaklaşsa da etkileşim düğmesi çıkmaz.
@export var interactable: bool = true

var model: CharacterModel

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("npcs")
	if model_scene:
		model = model_scene.instantiate()
		model.start_animation = idle_animation
		_visual.add_child(model)
	$TalkArea.body_entered.connect(func(b: Node3D) -> void:
		if b is Player: player_nearby.emit(self, true))
	$TalkArea.body_exited.connect(func(b: Node3D) -> void:
		if b is Player: player_nearby.emit(self, false))


func head_position() -> Vector3:
	return global_position + Vector3(0, focus_height, 0)


func is_player_near() -> bool:
	for b in $TalkArea.get_overlapping_bodies():
		if b is Player:
			return true
	return false


## Hikâye ilerledikçe etkileşimi açıp kapatmak için.
func set_interactable(value: bool) -> void:
	interactable = value
	var level := get_tree().get_first_node_in_group("level")
	if level is GameLevel:
		(level as GameLevel).refresh_interactions()


func face_point(point: Vector3) -> void:
	var dir := point - global_position
	if Vector2(dir.x, dir.z).length_squared() > 0.001:
		_visual.rotation.y = atan2(-dir.x, -dir.z)
