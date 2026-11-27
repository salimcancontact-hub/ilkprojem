extends Node
## Belirli kamera açılarının hızlı fotoğrafı: SHOTS=ad1,ad2 ZONES=1,3
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif")
	level = load("res://scenes/binis.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func _run():
	var d = level._dialog
	while level._phase == "baslangic":
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0; d._finish_typing(); d._advance()
	await t(0.5)
	for z in OS.get_environment("ZONES").split(","): level._set_zone(int(z), true)
	for sname in OS.get_environment("SHOTS").split(","):
		level._set_camera(sname); level._dialog_cam.make_current()
		if level._cam_tween: level._cam_tween.kill()
		await t(0.4)
		get_viewport().get_texture().get_image().save_png(out + "/q_" + sname + ".png"); print("foto ", sname)
	get_tree().quit()
