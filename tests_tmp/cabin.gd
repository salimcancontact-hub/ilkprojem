extends Node
## Kamara: kapı önü (duvar sızıntısı yok), içeri girince kapı kapanır, pencerede bulut yok, işaretler sade.
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "T")
	level = load("res://scenes/binis.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func snap(n): get_viewport().get_texture().get_image().save_png(out + "/cb_" + n + ".png"); print("foto ", n)
func _run():
	var d = level._dialog
	while level._phase == "baslangic":
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0; d._finish_typing(); d._advance()
	level._arrive_deck8()
	await t(2.0)
	var Z2: Vector3 = level.Z2
	level._player.global_position = Z2 + Vector3(0.4, 0.1, 5.0)
	level._player.face_point(Z2 + Vector3(1.6, 0, 7))
	level._on_story_event("kamara_kapi_ac", PackedStringArray())
	var cam := Camera3D.new(); level.add_child(cam); cam.make_current()
	cam.global_position = Z2 + Vector3(-1.0, 1.6, 3.6); cam.look_at(Z2 + Vector3(1.6, 1.2, 7.0))
	await t(1.2); snap("1_kapi_onu")
	level._player.global_position = Z2 + Vector3(3.0, 0.1, 7.0)
	await t(3.0)
	for i in 300:
		await get_tree().process_frame
		if d.active and not d._waiting and i % 6 == 0: d._block_input = 0; d._finish_typing(); d._advance()
		if not d.active and i > 60: break
	cam.make_current()
	cam.global_position = Z2 + Vector3(6.8, 1.9, 8.4); cam.look_at(Z2 + Vector3(2.0, 1.0, 6.5))
	await t(0.6); snap("2_kapi_kapali_oda")
	cam.global_position = Z2 + Vector3(3.0, 1.6, 7.6); cam.look_at(Z2 + Vector3(7.7, 1.4, 7.0))
	await t(0.4); snap("3_pencere_yerde")
	print("kapı z=", (level._z2["cabin_door"] as Node3D).position.z)
	get_tree().quit()
