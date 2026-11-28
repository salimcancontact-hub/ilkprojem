class_name CharacterModel
extends Node3D
## İnsan karakteri: Quaternius Universal Base gövdesi + üniforma dokusu + saç + animasyonlar.
## Animasyonlar Universal Animation Library'den (UAL1/UAL2) gelir; aynı iskeleti paylaşırlar.

const ANIM_SOURCES := {
	"ual1": "res://assets/animations/UAL1.glb",
	"ual2": "res://assets/animations/UAL2.glb",
}

@export var base_scene: PackedScene
@export var body_texture: Texture2D
@export var hair_scene: PackedScene
@export var hair_color: Color = Color(0.12, 0.08, 0.06)
@export var extra_scenes: Array[PackedScene] = []  ## Sakal gibi ek parçalar
@export var start_animation: String = "Idle"

var animation_player: AnimationPlayer
var skeleton: Skeleton3D

static var _libraries: Dictionary = {}

var _current: String = ""
## true iken (ör. yerde yatan, bayılmış) karakter başka animasyona geçmez.
var pose_locked: bool = false
var _attachments: Dictionary = {}  # nesne -> BoneAttachment3D
var _iks: Dictionary = {}  # "l"/"r" -> SkeletonIK3D
var _ik_tweens: Dictionary = {}
var _bone_markers: Dictionary = {}


func _ready() -> void:
	var body: Node3D = base_scene.instantiate()
	body.rotation.y = PI  # Modeller +Z'ye bakıyor, oyun -Z'yi ileri kabul ediyor.
	add_child(body)
	skeleton = body.find_child("Skeleton3D", true, false)

	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", false, false):
		var src_mat := mesh.mesh.surface_get_material(0)
		if src_mat == null:
			continue
		if body_texture and src_mat.resource_name.begins_with("MI_Superhero"):
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = body_texture
			mat.roughness = 0.85
			mesh.material_override = mat
		elif src_mat.resource_name.begins_with("MI_Hair"):
			mesh.material_override = _tinted(src_mat, hair_color)  # kaşlar

	if hair_scene:
		_attach_parts(hair_scene, hair_color)
	for part in extra_scenes:
		_attach_parts(part, hair_color)

	animation_player = AnimationPlayer.new()
	body.add_child(animation_player)
	for lib_name in ANIM_SOURCES:
		animation_player.add_animation_library(lib_name, _get_library(lib_name))
	play(start_animation, 0.0)


## Bir animasyonu yumuşak geçişle oynatır. Ad, kütüphane öneki olmadan verilir ("Walk").
func play(anim_name: String, blend: float = 0.2, speed: float = 1.0) -> void:
	if pose_locked:
		return
	var full := resolve(anim_name)
	if full.is_empty():
		push_warning("Animasyon bulunamadı: %s" % anim_name)
		return
	if full == _current and animation_player.is_playing():
		animation_player.speed_scale = speed
		return
	_current = full
	animation_player.play(full, blend)
	animation_player.speed_scale = speed


## Tek seferlik bir hareket oynatır, bitince "then" animasyonuna döner.
func play_once(anim_name: String, then: String = "Idle", blend: float = 0.15) -> void:
	if pose_locked:
		return
	play(anim_name, blend)
	var full := _current
	var len := animation_player.get_animation(full).length if animation_player.has_animation(full) else 0.0
	await get_tree().create_timer(maxf(len - blend, 0.05), false).timeout
	if _current == full:
		play(then, blend)


## Animasyonun son karesinde donar (ör. yerde yatan bir karakter).
func hold_last_frame(anim_name: String, lock: bool = true) -> void:
	var full := resolve(anim_name)
	if full.is_empty():
		return
	pose_locked = lock
	_current = full
	animation_player.play(full, 0.0)
	animation_player.seek(animation_player.get_animation(full).length - 0.02, true)
	animation_player.pause()


## Animasyonun belirli bir oranında (0..1) donar (ör. diz çökük kare); döngüsüz animasyon bitip
## karakteri ayağa kaldırmasın.
func hold_pose(anim_name: String, at: float, blend: float = 0.25) -> void:
	var full := resolve(anim_name)
	if full.is_empty():
		return
	pose_locked = true  # konuşma satırları duruşu bozmasın (unlock_pose ile çözülür)
	_current = full
	animation_player.play(full, blend)
	animation_player.seek(animation_player.get_animation(full).length * at, true)
	# Geçiş (blend) bitmeden durdurulursa beden önceki duruşta asılı kalır: önce geçiş tamamlansın
	animation_player.speed_scale = 1.0
	await get_tree().create_timer(blend + 0.05, true, false, true).timeout
	if _current == full:
		animation_player.pause()


var ragdoll: Ragdoll


## Karakteri fizik iskeletine bırakır (ölüm, bayılma, yere savrulma).
func go_ragdoll(impulse_bone: String = "", impulse := Vector3.ZERO) -> void:
	release_all(0.05)
	if ragdoll == null:
		ragdoll = Ragdoll.new(skeleton)
	pose_locked = true
	animation_player.pause()
	# Beden yerinden uzaklaşınca görünmez olmasın (kaplama kutusu eski yerde kalır)
	for mi: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		mi.extra_cull_margin = 16.0
	ragdoll.start(impulse_bone, impulse)


## Kilitli duruşu bırakır (ör. yerden kalkarken).
func unlock_pose() -> void:
	pose_locked = false
	animation_player.play()


## Bir nesneyi kemiğe takar (ör. "hand_r"). Konum/dönüş kemiğe göredir.
func attach(prop: Node3D, bone: String = "hand_r", offset := Vector3.ZERO, rot := Vector3.ZERO) -> void:
	detach(prop)
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skeleton.add_child(ba)
	if prop.get_parent():
		prop.get_parent().remove_child(prop)
	ba.add_child(prop)
	prop.position = offset
	prop.rotation = rot
	_attachments[prop] = ba


## Nesneyi kemikten çıkarır; world verilirse dünya konumunu koruyarak oraya bırakır.
func detach(prop: Node3D, world: Node = null) -> void:
	if not _attachments.has(prop):
		return
	var ba: BoneAttachment3D = _attachments[prop]
	_attachments.erase(prop)
	var xf := prop.global_transform
	ba.remove_child(prop)
	ba.queue_free()
	if world:
		world.add_child(prop)
		prop.global_transform = xf


## Elini (side: "l" veya "r") bir hedefe uzatır (ters kinematik). Hedef hareket ederse el de izler.
## elbow: dirseğin bükülmesi gereken yönde (dünya koordinatında) bir ipucu noktası (isteğe bağlı).
func reach(side: String, target: Node3D, time: float = 0.35, elbow: Node3D = null) -> void:
	var ik: SkeletonIK3D = _iks.get(side)
	if ik == null:
		ik = SkeletonIK3D.new()
		ik.name = "IK_" + side
		ik.root_bone = "upperarm_" + side
		ik.tip_bone = "hand_" + side
		ik.override_tip_basis = false
		ik.max_iterations = 40
		ik.min_distance = 0.005
		skeleton.add_child(ik)
		_iks[side] = ik
	ik.target_node = ik.get_path_to(target)
	ik.use_magnet = elbow != null
	if elbow:
		ik.magnet = skeleton.global_transform.affine_inverse() * elbow.global_position
	ik.interpolation = 0.0 if not ik.is_running() else ik.interpolation
	ik.active = true
	ik.start()
	_tween_ik(side, 1.0, time)


## Eli serbest bırakır (animasyona geri döner).
func release(side: String, time: float = 0.35) -> void:
	if not _iks.has(side):
		return
	var ik: SkeletonIK3D = _iks[side]
	await _tween_ik(side, 0.0, time)
	if ik.interpolation <= 0.001:
		ik.stop()


func release_all(time: float = 0.35) -> void:
	for side in _iks.keys():
		release(side, time)


func _tween_ik(side: String, value: float, time: float) -> void:
	var ik: SkeletonIK3D = _iks[side]
	if _ik_tweens.has(side) and _ik_tweens[side]:
		(_ik_tweens[side] as Tween).kill()
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(ik, "interpolation", value, time).set_trans(Tween.TRANS_SINE)
	_ik_tweens[side] = tw
	await tw.finished


## Bir kemiğin üzerinde duran (onu izleyen) nokta; başka karakterin IK hedefi olabilir.
func bone_marker(bone: String) -> Node3D:
	if _bone_markers.has(bone) and is_instance_valid(_bone_markers[bone]):
		return _bone_markers[bone]
	var ba := BoneAttachment3D.new()
	ba.name = "Isaret_" + bone
	ba.bone_name = bone
	skeleton.add_child(ba)
	_bone_markers[bone] = ba
	return ba


## Bedenin o anki gerçek noktası: fizik iskeletindeyse (yerde, ragdoll) fizik kemiği, değilse kemik işareti.
## Ragdoll'da animasyon pozundan okunan kemik konumu bedenin yattığı yerle uyuşmaz.
func body_point(bone: String) -> Node3D:
	if ragdoll and pose_locked:
		var pb: Node3D = ragdoll.bone(bone)
		if pb == null and bone in ["neck_01", "neck_02"]:
			pb = ragdoll.bone("Head")
		if pb:
			return pb
	return bone_marker(bone)


func body_position(bone: String) -> Vector3:
	return body_point(bone).global_position


func bone_position(bone: String) -> Vector3:
	var idx := skeleton.find_bone(bone)
	if idx < 0:
		return global_position
	return skeleton.global_transform * skeleton.get_bone_global_pose(idx).origin


func resolve(anim_name: String) -> String:
	for lib_name in ANIM_SOURCES:
		var full: String = "%s/%s" % [lib_name, anim_name]
		if animation_player.has_animation(full):
			return full
	return ""


func current_animation() -> String:
	return _current.get_slice("/", 1)


func _attach_parts(scene: PackedScene, color: Color) -> void:
	var part: Node3D = scene.instantiate()
	for mesh: MeshInstance3D in part.find_children("*", "MeshInstance3D", true, false):
		var src_mat := mesh.mesh.surface_get_material(0)
		mesh.owner = null
		mesh.get_parent().remove_child(mesh)
		skeleton.add_child(mesh)
		mesh.skeleton = NodePath("..")
		mesh.material_override = _tinted(src_mat, color)
	part.queue_free()


func _tinted(src: Material, color: Color) -> Material:
	var mat: StandardMaterial3D
	if src is StandardMaterial3D:
		mat = (src as StandardMaterial3D).duplicate()
	else:
		mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	return mat


static func _get_library(lib_name: String) -> AnimationLibrary:
	if not _libraries.has(lib_name):
		var src: Node = (load(ANIM_SOURCES[lib_name]) as PackedScene).instantiate()
		var ap: AnimationPlayer = src.find_child("AnimationPlayer", true, false)
		_libraries[lib_name] = ap.get_animation_library("")
		src.free()
	return _libraries[lib_name]
