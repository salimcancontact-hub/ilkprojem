extends Node
## Arman'ın düşüşü ve karar anı açısı: ikisi de kadrajda mı?
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	(func(): get_tree().current_scene = level).call_deferred()
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func snap(n): get_viewport().get_texture().get_image().save_png(out + "/fall_" + n + ".png"); print("foto ", n)
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 5 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	var a = level._arman
	a.visible = true
	a.global_position = level.ALLEY_SPOT
	level._player.global_position = level.ALLEY_SPOT + Vector3(-0.9, 0.1, 0)
	level._player.face_point(a.global_position); a.face_point(level._player.global_position)
	level._dialog_cam.make_current()
	await t(0.3)
	level._on_story_event("arman_yerde", PackedStringArray())
	await t(0.6); snap("1_dusus")
	await t(1.2); snap("2_yerde")
	level._set_camera("arman_yerde"); level._dialog_cam.make_current()
	await t(0.5); snap("3_karar")
	get_tree().quit()
