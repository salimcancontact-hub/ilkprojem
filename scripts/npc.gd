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
## İnceleme noktalarında oyuncunun oynayacağı hareket (ör. "Interact"). Boşsa sadece bakar.
@export var inspect_anim: String = ""
## false ise oyuncu yaklaşsa da etkileşim düğmesi çıkmaz.
@export var interactable: bool = true
## İnceleme noktalarında parlayan kürenin dünya konumu (nesnenin üstü). INF ise focus_height kullanılır.
var marker_at: Vector3 = Vector3.INF
## TWD sahneleme: oyuncunun bu kişiyle/noktayla sahneye girerken durduğu sabit işaret (dünya konumu).
## INF ise seviye açılışında bir kez, kişinin kendi baktığı yöne / noktanın açık tarafına göre hesaplanır
## (oyuncunun nereden geldiğine bağlı DEĞİLDİR: sahne her seferinde aynı kurulur).
var stand_mark: Vector3 = Vector3.INF

var model: CharacterModel
var _marker: Node3D
var _marker_t: float = 0.0
var _player_ref: Node3D

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("npcs")
	if model_scene:
		model = model_scene.instantiate()
		model.start_animation = idle_animation
		_visual.add_child(model)
	_build_marker()
	$TalkArea.body_entered.connect(func(b: Node3D) -> void:
		if b is Player: player_nearby.emit(self, true))
	$TalkArea.body_exited.connect(func(b: Node3D) -> void:
		if b is Player: player_nearby.emit(self, false))


## Konuşulabilen karakterlerin başında "• • •", incelenebilir noktalarda parlayan küre.
func _build_marker() -> void:
	if model:
		var l := Label3D.new()
		l.text = "• • •"
		l.font_size = 64
		l.outline_size = 10
		l.pixel_size = 0.006
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.modulate = Color(1, 1, 1, 0.9)
		l.position = Vector3(0, 2.15, 0)
		_marker = l
	else:
		# TWD: küçük, sakin beyaz nokta + ince halka (ışık saçmaz, parlama lekesi yapmaz)
		var m := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.028
		sp.height = 0.056
		sp.radial_segments = 12
		sp.rings = 6
		m.mesh = sp
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.97, 0.9)
		mat.no_depth_test = true
		m.material_override = mat
		m.position = Vector3(0, focus_height, 0)
		_marker = m
	_marker.visible = false
	add_child(_marker)
	if model == null and marker_at != Vector3.INF:
		_marker.global_position = marker_at


func _process(delta: float) -> void:
	if _marker == null:
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player")
		return
	var near := global_position.distance_to(_player_ref.global_position) < (12.0 if model else 4.5)
	var lvl := get_tree().get_first_node_in_group("level")
	var in_dialog: bool = lvl != null and lvl.get("_dialog") != null and lvl._dialog.active
	_marker.visible = interactable and near and visible and not in_dialog
	if _marker.visible:
		_marker_t += delta
		_marker.scale = Vector3.ONE * (1.0 + sin(_marker_t * 4.0) * 0.12)


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
