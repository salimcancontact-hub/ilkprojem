extends Node
var level
var out := OS.get_environment("OUT")
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "T"); Story.add_item("enerji_bari")
	level = load("res://scenes/onsoz.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func t(s): await get_tree().create_timer(s, true, false, true).timeout
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	Story.add_item("enerji_bari")
	var p = level._player
	p.global_position = Vector3(0.0, 0.1, 14.0)
	p.face_point(Vector3(0, 0, 30))
	await t(0.3)
	var cam := Camera3D.new(); level.add_child(cam); cam.make_current()
	cam.global_position = p.global_position + Vector3(0.6, 1.6, 1.4); cam.look_at(p.global_position + Vector3(0, 1.3, 0))
	level.use_item("enerji_bari")
	for k in 6:
		await t(0.4)
		var bars = level.find_children("EnerjiBari*", "", true, false)
		for b in bars:
			print("bar ", b.global_position, " görünür=", b.is_visible_in_tree(), " el=", p.model.bone_position("hand_r"))
		get_viewport().get_texture().get_image().save_png(out + "/eat_c%d.png" % k)
	get_tree().quit()
