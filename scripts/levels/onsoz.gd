extends GameLevel
## Önsöz: "Seçim Gecesi" — Dünya, 2526.
## Akış: açılış -> Deniz Arman -> muhafız -> isyan -> ara sokak -> karanlık -> uyanış -> kart -> kalkış

const DLG := "res://dialogs/onsoz.dlg"
const NEXT_SCENE := "res://scenes/main.tscn"

@onready var _arman: Npc = $Npcs/Arman
@onready var _guard: Npc = $Npcs/Muhafiz
@onready var _card: Npc = $Card
@onready var _crowd: Node3D = $Crowd
@onready var _alley: Area3D = $AlleyTrigger
@onready var _alarm: Node3D = $AlarmLights
@onready var _blast: OmniLight3D = $BlastLight

var _phase: String = "giris"


func _ready() -> void:
	super()
	Story.reset()
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
	_phase = "sokak"


func _on_story_event(event_name: String, _args: PackedStringArray) -> void:
	match event_name:
		"isyan":
			_start_riot()
		"final":
			_final()


# --- İsyan -----------------------------------------------------------------

func _start_riot() -> void:
	if _phase != "sokak":
		return
	_phase = "isyan"
	if _dialog.active:
		await _dialog.dialog_finished
	_hud.set_objective("Kalabalıktan kaç! Deniz Arman'ın peşinden git.")
	shake(0.12, 3.0)
	_arman.set_interactable(false)
	_guard.set_interactable(false)
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
		var model := person as CharacterModel
		var away := Vector3(randf_range(-7.0, 7.0), 0, person.position.z - randf_range(18.0, 30.0))
		if i % 3 == 0:
			away = Vector3(randf_range(-7.0, 7.0), 0, person.position.z + randf_range(4.0, 8.0))  # barikata yüklenenler
		_run_to(model, person, [away], randf_range(5.0, 7.0), "Sprint" if i % 2 == 0 else "Jog_Fwd", i % 3 != 0)
		i += 1
	for npc: Npc in [$Npcs/Yasli, $Npcs/Kadin]:
		_run_to(npc.model, npc, [npc.position + Vector3(randf_range(-3, 3), 0, -25)], 6.0, "Jog_Fwd", true)

	# Deniz Arman ara sokağa kaçar
	_run_to(_arman.model, _arman, [Vector3(6.5, 0, 12.0), Vector3(13.0, 0, 10.5), Vector3(18.0, 0, 10.0)], 4.5, "Sprint", true)
	await get_tree().create_timer(1.2).timeout
	_alley.monitoring = true
	# Kısa aralıklarla uzak patlamalar
	for k in 3:
		await get_tree().create_timer(randf_range(1.0, 2.0)).timeout
		if _phase != "isyan":
			return
		shake(0.35, 0.5)


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


# --- Ara sokak: patlama, karanlık, uyanış ----------------------------------

func _on_alley_entered(body: Node3D) -> void:
	if not body is Player or _phase != "isyan":
		return
	_phase = "karanlik"
	_alley.set_deferred("monitoring", false)
	_player.input_enabled = false
	_player.velocity = Vector3.ZERO
	_hud.set_objective("")
	# Patlama
	_blast.light_energy = 18.0
	shake(0.8, 1.2)
	create_tween().tween_property(_blast, "light_energy", 0.0, 0.8)
	_player.model.play("Hit_Knockback", 0.05)
	await get_tree().create_timer(0.45).timeout
	await _dialog.fade_to(1.0, 0.35)
	await play_dialog(DLG, "karanlik")

	# Karanlıkta sahneyi hazırla
	for tw in get_tree().get_processed_tweens():
		tw.kill()
	for l: Light3D in _alarm.get_children():
		l.light_energy = 0.0
	_crowd.visible = false
	_guard.visible = false
	$Npcs/Yasli.visible = false
	$Npcs/Kadin.visible = false
	_arman.visible = true
	_arman.position = Vector3(15.4, 0, 9.6)
	_arman.rotation = Vector3(0, 0.6, 0)
	_arman.get_node("Visual").rotation = Vector3.ZERO
	_arman.get_node("CollisionShape3D").disabled = true
	_arman.model.hold_last_frame("Death01")
	_card.visible = true
	_player.global_position = Vector3(13.3, 0.05, 11.7)
	_player.face_point(_arman.global_position)
	_player._camera_pivot.rotation.y = deg_to_rad(-70)
	_player.model.play("LayToIdle", 0.0)

	_dialog.fade_to(0.0, 3.0)
	await get_tree().create_timer(1.2).timeout
	await play_dialog(DLG, "uyanis")
	_player.input_enabled = true
	_card.set_interactable(true)
	_hud.set_objective("Deniz Arman'a bak.")
	_phase = "uyanis"


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
	await get_tree().create_timer(4.0).timeout
	await _dialog.show_title("BÖLÜM 1: İLK İNİŞ", "Yolculuğun dördüncü yılı", 2.5)
	get_tree().change_scene_to_file(NEXT_SCENE)
