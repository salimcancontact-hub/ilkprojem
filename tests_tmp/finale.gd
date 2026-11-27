extends Node
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Kerem")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func snap(n): get_viewport().get_texture().get_image().save_png(out + "/fn_" + n + ".png"); print("foto ", n)
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 5 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	var p = level.get_node("Player")
	# Cop
	var cam := Camera3D.new(); level.add_child(cam)
	cam.global_position = Vector3(1.6, 1.7, 56.2); cam.look_at(Vector3(0, 1.2, 58.6)); cam.make_current()
	await t(0.3); snap("cop")
	# Su -> çantaya koy
	p.global_position = Vector3(2.2, 0.1, 30.2); p.face_point(level._arman.global_position)
	level._on_story_event("su_cikar", PackedStringArray()); await t(0.8)
	level._on_story_event("su_al", PackedStringArray()); await t(1.2)
	level._on_story_event("cantaya_koy", PackedStringArray()); await t(0.45)
	var fw = -p.get_node("Visual").global_basis.z; var rt = p.get_node("Visual").global_basis.x
	cam.global_position = p.global_position + Vector3(0, 1.4, 0) - fw * 1.4 + rt * 0.9; cam.look_at(p.global_position + Vector3(0, 1.2, 0)); cam.make_current()
	await t(0.1); snap("cantaya_koy")
	# Final
	Story.set_var("ada_soz", true)
	level._phase = "kart"
	level._final()
	for i in 3000:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 6 == 0:
			d._block_input = 0; d._finish_typing(); d._advance()
		if level._ada_ship and d._text_label.text.begins_with("Kalkıştan") and not FileAccess.file_exists(out + "/fn_koridor.png"):
			await t(0.6); snap("koridor")
		if level._ada_ship and d._text_label.text.begins_with("Sonra elini") :
			await t(0.3); snap("el_ele"); break
	get_tree().quit()
