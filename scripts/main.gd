class_name GameLevel
extends Node3D
## Bir oyun seviyesi: oyuncu, karakterler, diyaloglar, arayüz ve (isteğe bağlı) dövüş.
## Hikâye sahneleri bu sınıftan türeyip _on_story_event() ile kendi olaylarını işler.

## false ise can barı, SALDIR düğmesi ve sayaçlar gizlenir.
@export var combat_enabled: bool = true
## Oyuncunun diyaloglardaki konuşmacı kimliği (DENIZ, önsözde EVREN).
@export var player_speaker_id: String = "DENIZ"

@onready var _player: Player = $Player
@onready var _hud: CanvasLayer = $HUD
@onready var _dialog: CanvasLayer = $DialogUI

var _nearby_npc: Npc = null
var _talking_to: Npc = null
var _dialog_cam: Camera3D
var _player_cam: Camera3D
var _shake_time: float = 0.0
var _shake_strength: float = 0.0


func _ready() -> void:
	get_tree().paused = false
	Game.mark_level_started()

	_hud.joystick.changed.connect(func(v: Vector2) -> void: _player.move_input = v)
	_hud.restart_requested.connect(func() -> void: get_tree().reload_current_scene())
	_hud.set_combat_enabled(combat_enabled)

	_player.health_changed.connect(_hud.set_health)
	_player.died.connect(_on_player_died)
	_hud.set_health(_player.health, _player.max_health)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.died.connect(_on_enemy_died)
	_hud.set_enemies(get_tree().get_nodes_in_group("enemies").size())

	Game.gems_changed.connect(_on_gems_changed)
	Game.reset(get_tree().get_nodes_in_group("gems").size())

	# Diyalog
	_player_cam = _player.get_node("CameraPivot/SpringArm3D/Camera3D")
	_dialog_cam = Camera3D.new()
	_dialog_cam.fov = 45.0
	add_child(_dialog_cam)
	for npc: Npc in get_tree().get_nodes_in_group("npcs"):
		npc.player_nearby.connect(_on_npc_nearby)
	_dialog.speaker_changed.connect(_on_speaker_changed)
	_dialog.event_fired.connect(_on_dialog_event)
	_dialog.dialog_finished.connect(_on_dialog_finished)


func _exit_tree() -> void:
	if Game.gems_changed.is_connected(_on_gems_changed):
		Game.gems_changed.disconnect(_on_gems_changed)


func _process(delta: float) -> void:
	if _nearby_npc and _nearby_npc.interactable and not _dialog.active and not _player.is_dead \
			and Input.is_action_just_pressed("interact"):
		_start_dialog(_nearby_npc)
	_update_shake(delta)


# --- Diyalog ---------------------------------------------------------------

func _start_dialog(npc: Npc) -> void:
	_talking_to = npc
	_enter_dialog_mode()
	if npc.model:
		npc.model.process_mode = Node.PROCESS_MODE_ALWAYS
		npc.face_point(_player.global_position)
	_player.face_point(npc.global_position)
	_dialog_cam.make_current()
	_dialog.start(npc.dialog_path, npc.start_node)


## Bir karaktere bağlı olmayan diyalog (anlatım, ara sahne). Bitene kadar bekler.
func play_dialog(path: String, node_name: String) -> void:
	_talking_to = null
	_enter_dialog_mode()
	_dialog.start(path, node_name)
	await _dialog.dialog_finished


func _enter_dialog_mode() -> void:
	get_tree().paused = true
	_hud.set_gameplay_visible(false)
	_player.stand_idle()
	# Oyun duraklasa da karakterler diyalogda hareket etmeye devam etsin.
	_player.model.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_dialog_finished() -> void:
	_player.model.process_mode = Node.PROCESS_MODE_INHERIT
	if not _player.is_dead:
		_player.model.play("Idle")
	if _talking_to and _talking_to.model:
		_talking_to.model.process_mode = Node.PROCESS_MODE_INHERIT
		_talking_to.model.play(_talking_to.idle_animation)
	_talking_to = null
	_player_cam.make_current()
	_hud.set_gameplay_visible(true)
	get_tree().paused = false


## Telltale tarzı karşılıklı omuz üstü çekimler: konuşan kişiyi göster.
func _on_speaker_changed(speaker_id: String) -> void:
	if _talking_to == null:
		return
	# Konuşan el kol hareketi yapar, diğeri dinler.
	_player.model.play("Idle_Talking" if speaker_id == player_speaker_id else "Idle", 0.3)
	if _talking_to.model:
		_talking_to.model.play("Idle_Talking" if speaker_id == _talking_to.npc_id else _talking_to.idle_animation, 0.3)
	var a: Vector3 = _player.head_position()
	var b: Vector3 = _talking_to.head_position()
	var dir: Vector3 = (b - a).normalized()
	var right: Vector3 = dir.cross(Vector3.UP).normalized()
	if not _talking_to.model:
		# Nesne inceleme: oyuncunun omzunun üstünden aşağı bak
		_place_cam(a - dir * 1.2 + right * 0.7 + Vector3.UP * 0.4, b)
	elif speaker_id == _talking_to.npc_id:
		_place_cam(a - dir * 1.9 + right * 1.25 + Vector3.UP * 0.3, b - right * 0.35 - Vector3.UP * 0.1)
	elif speaker_id == "":
		var mid: Vector3 = (a + b) / 2.0
		_place_cam(mid - right * 4.5 + Vector3.UP * 0.8, mid - Vector3.UP * 0.3)
	else:
		_place_cam(b + dir * 1.9 - right * 1.25 + Vector3.UP * 0.3, a + right * 0.35 - Vector3.UP * 0.1)


## Diyalog dosyasındaki @olay satırları.
##   @olay anim KİŞİ Animasyon   -> karakter tek seferlik hareket yapar
##   @olay gorev Metin...        -> ekranın üstündeki görev yazısı
##   @olay sarsinti [güç] [süre] -> kamera sarsıntısı
## Diğer olaylar _on_story_event()'e iletilir.
func _on_dialog_event(event_name: String, args: PackedStringArray) -> void:
	match event_name:
		"anim":
			if args.size() >= 2:
				var model: CharacterModel = null
				if args[0] == player_speaker_id:
					model = _player.model
				elif _talking_to and args[0] == _talking_to.npc_id:
					model = _talking_to.model
				if model:
					model.play_once(args[1], "Idle")
		"gorev":
			_hud.set_objective(" ".join(args))
		"sarsinti":
			shake(float(args[0]) if args.size() > 0 else 0.3, float(args[1]) if args.size() > 1 else 0.6)
		_:
			_on_story_event(event_name, args)


## Alt sınıfların hikâye olaylarını işlediği yer.
func _on_story_event(_event_name: String, _args: PackedStringArray) -> void:
	pass


func _place_cam(from: Vector3, target: Vector3) -> void:
	_dialog_cam.global_position = from
	_dialog_cam.look_at(target, Vector3.UP)


func _on_npc_nearby(npc: Npc, is_near: bool) -> void:
	if is_near and npc.interactable:
		_nearby_npc = npc
	elif _nearby_npc == npc:
		_nearby_npc = null
	_hud.set_talk_available(_nearby_npc != null, _nearby_npc.prompt if _nearby_npc else "KONUŞ")


## Bir karakter etkileşime açılıp kapandığında yakınlık durumunu yeniler.
func refresh_interactions() -> void:
	_nearby_npc = null
	for npc: Npc in get_tree().get_nodes_in_group("npcs"):
		if npc.interactable and npc.is_player_near():
			_nearby_npc = npc
	_hud.set_talk_available(_nearby_npc != null, _nearby_npc.prompt if _nearby_npc else "KONUŞ")


# --- Kamera sarsıntısı -----------------------------------------------------

func shake(strength: float = 0.3, duration: float = 0.6) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time = maxf(_shake_time, duration)


func _update_shake(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if _shake_time > 0.0:
		_shake_time -= delta
		var s := _shake_strength * clampf(_shake_time / 0.4, 0.0, 1.0)
		cam.h_offset = randf_range(-s, s)
		cam.v_offset = randf_range(-s, s)
	elif cam.h_offset != 0.0 or cam.v_offset != 0.0:
		cam.h_offset = 0.0
		cam.v_offset = 0.0
		_shake_strength = 0.0


# --- Dövüş ve toplama ------------------------------------------------------

func _on_gems_changed(collected: int, total: int) -> void:
	_hud.set_gems(collected, total)
	if total > 0 and collected >= total:
		_hud.show_message("Hücreler toplandı!")
		get_tree().paused = true


func _on_enemy_died() -> void:
	# Düşman ölüm sinyalinde gruptan çıkarıldı, kalanları say.
	_hud.set_enemies(get_tree().get_nodes_in_group("enemies").size())


func _on_player_died() -> void:
	_hud.show_message("Öldün!")
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true
