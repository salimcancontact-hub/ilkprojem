extends Node
## Oturan oyuncu + pencere çekimi hızlı kontrol.
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "Elif"); Story.set_var("cinsiyet", OS.get_environment("CINS"))
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
	level._set_zone(1, false); level._set_zone(2, true)
	level._player.global_position = level.Z2 + Vector3(4.0, 0.1, 7.0)
	await level._raise_seat()
	await level._sit()
	level._on_story_event("kemer_bagla", PackedStringArray())
	await t(1.6)
	(level._z2["earth"] as Node3D).visible = true
	print("oyuncu=", level._player.global_position, " baş=", level._player.model.bone_position("Head"), " kemik_idx=", level._player.model.skeleton.find_bone("Head"), " koltuk=", (level._z2["seat"] as Node3D).global_position, " pencere_çekimi=", level.camera_shots["pencere"])
	for sh in ["pencere", "tutun", "yuz"]:
		level._set_camera(sh); level._dialog_cam.make_current()
		if level._cam_tween: level._cam_tween.kill()
		await t(0.4)
		get_viewport().get_texture().get_image().save_png(out + "/sc_%s_%s.png" % [OS.get_environment("CINS"), sh]); print("foto ", sh)
	get_tree().quit()
