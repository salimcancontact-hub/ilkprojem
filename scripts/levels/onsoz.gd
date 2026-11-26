extends GameLevel
## "Seçim Gecesi" — oyunun başlangıcı. Dünya, 2526.
## Akış: açılış -> Ada'nın araması -> sokak (ipuçları, Deniz Arman, muhafız)
##       -> isyan (QTE) -> ara sokak: Deniz Arman'la yüzleşme -> kart -> kalkış -> "Devam edecek"

const DLG := "res://dialogs/onsoz.dlg"
const MENU_SCENE := "res://scenes/boot.tscn"

@onready var _arman: Npc = $Npcs/Arman
@onready var _guard: Npc = $Npcs/Muhafiz
@onready var _card: Npc = $Card
@onready var _crowd: Node3D = $Crowd
@onready var _alley: Area3D = $AlleyTrigger
@onready var _alarm: Node3D = $AlarmLights
@onready var _blast: OmniLight3D = $BlastLight

## Deniz Arman'ın ara sokakta beklediği yer
const ALLEY_SPOT := Vector3(16.2, -0.15, 10.6)

var _phase: String = "giris"


func _ready() -> void:
	super()
	Story.reset()
	camera_shots = {
		"kalabalik": [Vector3(2.6, 2.1, 59.2), Vector3(-0.8, 1.2, 50.0)],
		"muhafiz": [Vector3(-0.9, 1.75, 55.6), Vector3(0.2, 1.55, 58.6)],
		"arman": [Vector3(-0.6, 3.0, 52.4), Vector3(1.8, 0.3, 55.0)],
		"evren_yakin": [Vector3(0.7, 1.62, -4.7), Vector3(-0.05, 1.38, -6.0)],
		"sokak_genis": [Vector3(13.2, 2.4, 6.4), Vector3(15.6, 1.1, 10.6)],
		"arman_yerde": [Vector3(13.6, 2.6, 12.2), Vector3(16.0, 0.2, 10.4)],
	}
	_card.visible = false
	_card.interactable = false
	_alley.monitoring = false
	_alley.body_entered.connect(_on_alley_entered)
	for l: Light3D in _alarm.get_children():
		l.light_energy = 0.0
	_blast.light_energy = 0.0
	_dialog.fade_to(1.0, 0.0)
	await get_tree().process_frame
	await play_dialog(DLG, "giris")
	# Başlık kartı ve kararmanın açılması bitmeden aramaya geçme
	if _dialog._title_tween and _dialog._title_tween.is_running():
		await _dialog._title_tween.finished
	await _dialog.fade_to(0.0, 1.2)
	_player.face_point(Vector3(0, 0, 60))
	await play_dialog(DLG, "ada_arama")
	_phase = "sokak"


func _on_story_event(event_name: String, _args: PackedStringArray) -> void:
	match event_name:
		"isyan":
			keep_world_running()
			_start_riot()
		"arman_dustu":
			_arman.visible = true
			_arman.position = Vector3(1.8, -0.15, 55.0)
			_arman.rotation = Vector3(0, 2.4, 0)
			_arman.get_node("Visual").rotation = Vector3.ZERO
			_arman.model.hold_last_frame("Death01")
		"arman_kalkti":
			_arman_escape()
		"arman_yerde":
			_arman.model.play("Hit_Knockback", 0.05)
			await get_tree().create_timer(0.6, true, false, true).timeout
			_arman.model.hold_last_frame("Death01")
		"arman_oldu":
			_arman.model.hold_last_frame("Death01")
			_arman.get_node("CollisionShape3D").disabled = true
			_card.global_position = _arman.global_position + Vector3(-0.7, 0, 0.6)
			_card.visible = true
		"telefon":
			_player.face_point(Vector3(0, 0, 60))
			_player.model.play("Idle_TalkingPhone", 0.3)
			# Ekranın soğuk ışığı yüzüne vursun
			var glow := OmniLight3D.new()
			glow.name = "PhoneGlow"
			glow.light_color = Color(0.55, 0.8, 1.0)
			glow.light_energy = 2.2
			glow.omni_range = 1.6
			glow.position = Vector3(0.1, 1.45, -0.45)
			_player.get_node("Visual").add_child(glow)
		"telefon_kapat":
			_player.model.play("Idle", 0.4)
			var g := _player.get_node_or_null("Visual/PhoneGlow")
			if g:
				g.queue_free()
		"final":
			_final()


# --- İsyan -----------------------------------------------------------------

func _start_riot() -> void:
	if _phase != "sokak":
		return
	_phase = "isyan"
	shake(0.12, 3.0)
	for npc: Npc in get_tree().get_nodes_in_group("npcs"):
		if npc != _card:
			npc.interactable = false
	refresh_interactions()
	_guard.model.play("Idle_Shield", 0.2)

	# Alarm ışıkları yanıp söner
	for l: OmniLight3D in _alarm.get_children():
		var tw := create_tween().set_loops()
		tw.tween_property(l, "light_energy", 4.0, 0.35)
		tw.tween_property(l, "light_energy", 0.3, 0.35)

	# Kalabalık dağılır
	var i := 0
	for person: Node3D in _crowd.get_children():
		var away := Vector3(randf_range(-7.0, 7.0), -0.15, person.position.z - randf_range(18.0, 30.0))
		if i % 3 == 0:
			away = Vector3(randf_range(-7.0, 7.0), -0.15, person.position.z + randf_range(4.0, 8.0))
		_run_to(person as CharacterModel, person, [away], randf_range(5.0, 7.0), "Sprint" if i % 2 == 0 else "Jog_Fwd", i % 3 != 0)
		i += 1
	for npc: Npc in [$Npcs/Yasli, $Npcs/Kadin]:
		_run_to(npc.model, npc, [npc.position + Vector3(randf_range(-3, 3), 0, -25)], 6.0, "Jog_Fwd", true)
	_alley.monitoring = true
	for k in 3:
		await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
		if _phase != "isyan":
			return
		shake(0.35, 0.5)


## Deniz Arman yerden kalkıp ara sokağa koşar ve orada nefeslenir.
func _arman_escape() -> void:
	_arman.model.play("LayToIdle", 0.1)
	await get_tree().create_timer(1.6).timeout
	_run_to(_arman.model, _arman, [Vector3(5.0, -0.15, 40.0), Vector3(6.5, -0.15, 13.0), Vector3(12.5, -0.15, 10.6), ALLEY_SPOT], 9.0, "Sprint", false)
	await get_tree().create_timer(9.1).timeout
	_arman.model.play("Idle", 0.3)


func _run_to(model: CharacterModel, mover: Node3D, points: Array, duration: float, anim: String, hide_at_end: bool) -> void:
	if model == null:
		return
	model.play(anim, 0.15)
	var tw := create_tween()
	var prev: Vector3 = mover.position
	var seg := duration / points.size()
	for p: Vector3 in points:
		var dir := p - prev
		var yaw := atan2(-dir.x, -dir.z)
		tw.tween_callback(func() -> void: mover.rotation.y = yaw)
		tw.tween_property(mover, "position", p, seg)
		prev = p
	if hide_at_end:
		tw.tween_callback(func() -> void: mover.visible = false)


# --- Ara sokak: yüzleşme -----------------------------------------------------

func _on_alley_entered(body: Node3D) -> void:
	if not body is Player or _phase != "isyan":
		return
	_phase = "sokak_sonu"
	_alley.set_deferred("monitoring", false)
	_hud.set_objective("")
	# İsyan efektlerini durdur; uzakta bir patlama
	for tw in get_tree().get_processed_tweens():
		tw.kill()
	for l: Light3D in _alarm.get_children():
		l.light_energy = 0.0
	_blast.light_energy = 10.0
	create_tween().tween_property(_blast, "light_energy", 0.0, 1.0)
	shake(0.35, 0.8)
	# Deniz Arman ara sokakta, nefes nefese
	_arman.visible = true
	_arman.rotation = Vector3.ZERO
	_arman.position = ALLEY_SPOT
	_arman.model.play("Idle", 0.2)
	_player.velocity = Vector3.ZERO
	var to_arman := (_arman.global_position - _player.global_position)
	to_arman.y = 0
	if to_arman.length() > 2.6:
		_player.global_position = _arman.global_position - to_arman.normalized() * 2.2
	_arman.start_node = "ara_sokak"
	_start_dialog(_arman)
	await _dialog.dialog_finished
	_arman.model.hold_last_frame("Death01")  # diyalog sonu bekleme duruşunu geri al	_crowd.visible = false
	_guard.visible = false
	_card.set_interactable(true)
	_phase = "kart"


# --- Final -----------------------------------------------------------------

func _final() -> void:
	if _phase == "final":
		return
	_phase = "final"
	if _dialog.active:
		await _dialog.dialog_finished
	_card.set_interactable(false)
	_player.input_enabled = false
	_hud.set_gameplay_visible(false)
	await _dialog.fade_to(1.0, 2.0)
	await play_dialog(DLG, "kalkis")
	_hud.set_gameplay_visible(false)
	await get_tree().create_timer(4.5).timeout
	get_tree().change_scene_to_file(MENU_SCENE)
