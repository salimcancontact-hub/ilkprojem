extends Node
## Yörüngeye tırmanış sahnesinin 2 sn'de bir fotoğrafı + kamara penceresinden Dünya.
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "T")
	level = load("res://scenes/binis.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func snap(n): get_viewport().get_texture().get_image().save_png(out + "/as_" + n + ".png"); print("foto ", n)
func _run():
	var d = level._dialog
	while level._phase == "baslangic":
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0; d._finish_typing(); d._advance()
	# Kalkış öncesi: kepenkli meydan ve kamara penceresi
	level._set_camera("c_hologram"); level._dialog_cam.make_current(); await t(0.5); snap("00_meydan")
	level._set_zone(1, false); level._set_zone(2, true)
	level._set_camera("c_pencere"); level._dialog_cam.make_current(); await t(0.5); snap("01_kamara_pencere")
	level._set_zone(2, false); level._set_zone(3, true)
	level._set_camera("kopru"); level._dialog_cam.make_current(); await t(0.5); snap("02_kopru")
	level._set_zone(3, false); level._set_zone(4, true)
	level._set_camera("dis"); level._dialog_cam.make_current(); level._ignite(); await t(3.0); snap("03_atesleme")
	level._set_zone(4, false)
	level._on_story_event("yukselis", PackedStringArray())
	for i in 11:
		await t(2.0)
		snap("1%02d" % (i * 2))
	level._on_story_event("kamara_yorunge", PackedStringArray())
	level._player.global_position = level.Z2 + Vector3(4.5, 0.1, 7.6)
	level._set_camera("pencere"); level._dialog_cam.make_current(); await t(0.6); snap("90_yorunge_pencere")
	get_tree().quit()
