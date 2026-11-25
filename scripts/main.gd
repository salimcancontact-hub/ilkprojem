extends Node3D
## Ana sahne: oyuncu, düşmanlar, kristaller, karakterler ve arayüzleri birbirine bağlar.

@onready var _player: Player = $Player
@onready var _hud: CanvasLayer = $HUD
@onready var _dialog: CanvasLayer = $DialogUI

var _nearby_npc: Npc = null
var _talking_to: Npc = null
var _dialog_cam: Camera3D
var _player_cam: Camera3D


func _ready() -> void:
	get_tree().paused = false
	Story.reset()

	_hud.joystick.changed.connect(func(v: Vector2) -> void: _player.move_input = v)
	_hud.restart_requested.connect(func() -> void: get_tree().reload_current_scene())

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
	_dialog.dialog_finished.connect(_on_dialog_finished)


func _exit_tree() -> void:
	if Game.gems_changed.is_connected(_on_gems_changed):
		Game.gems_changed.disconnect(_on_gems_changed)


func _process(_delta: float) -> void:
	if _nearby_npc and not _dialog.active and not _player.is_dead \
			and Input.is_action_just_pressed("interact"):
		_start_dialog(_nearby_npc)


func _start_dialog(npc: Npc) -> void:
	_talking_to = npc
	get_tree().paused = true
	_hud.set_gameplay_visible(false)
	_player.move_input = Vector2.ZERO
	_player.face_point(npc.global_position)
	npc.face_point(_player.global_position)
	_dialog_cam.make_current()
	_dialog.start(npc.dialog_path, npc.start_node)


func _on_dialog_finished() -> void:
	_talking_to = null
	_player_cam.make_current()
	_hud.set_gameplay_visible(true)
	get_tree().paused = false


## Telltale tarzı karşılıklı omuz üstü çekimler: konuşan kişiyi göster.
func _on_speaker_changed(speaker_id: String) -> void:
	if _talking_to == null:
		return
	var a: Vector3 = _player.head_position()
	var b: Vector3 = _talking_to.head_position()
	var dir: Vector3 = (b - a).normalized()
	var right: Vector3 = dir.cross(Vector3.UP).normalized()
	if speaker_id == _talking_to.npc_id:
		# Deniz'in omzunun üstünden karşıdakine bak (konuşan kadrajın sağında)
		_place_cam(a - dir * 1.9 + right * 1.25 + Vector3.UP * 0.3, b - right * 0.35 - Vector3.UP * 0.1)
	elif speaker_id == "":
		# Anlatım: iki karakteri yandan gösteren geniş çekim
		var mid: Vector3 = (a + b) / 2.0
		_place_cam(mid - right * 4.5 + Vector3.UP * 0.8, mid - Vector3.UP * 0.3)
	else:
		# Karşıdakinin omzunun üstünden Deniz'e bak (konuşan kadrajın solunda)
		_place_cam(b + dir * 1.9 - right * 1.25 + Vector3.UP * 0.3, a + right * 0.35 - Vector3.UP * 0.1)


func _place_cam(from: Vector3, target: Vector3) -> void:
	_dialog_cam.global_position = from
	_dialog_cam.look_at(target, Vector3.UP)


func _on_npc_nearby(npc: Npc, is_near: bool) -> void:
	if is_near:
		_nearby_npc = npc
	elif _nearby_npc == npc:
		_nearby_npc = null
	_hud.set_talk_available(_nearby_npc != null)


func _on_gems_changed(collected: int, total: int) -> void:
	_hud.set_gems(collected, total)
	if total > 0 and collected >= total:
		_hud.show_message("Kazandın!")
		get_tree().paused = true


func _on_enemy_died() -> void:
	# Düşman ölüm sinyalinde gruptan çıkarıldı, kalanları say.
	_hud.set_enemies(get_tree().get_nodes_in_group("enemies").size())


func _on_player_died() -> void:
	_hud.show_message("Öldün!")
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true
