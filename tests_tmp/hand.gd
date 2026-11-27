extends Node
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
func _run():
	var d = level._dialog
	while level._phase != "sokak" or d.active:
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 5 == 0:
			d._block_input = 0
			if d._choosing: d._pick(0)
			else: d._finish_typing(); d._advance()
	var a = level._arman
	var cam := Camera3D.new(); level.add_child(cam); cam.make_current()
	var c: Vector3 = a.global_position
	for v in [["on", Vector3(0, 1.3, -1.6)], ["sag", Vector3(1.6, 1.2, 0)], ["sol", Vector3(-1.6, 1.2, 0)], ["arka", Vector3(0, 1.3, 1.6)]]:
		cam.global_position = c + v[1]; cam.look_at(c + Vector3(0, 1.0, 0))
		await t(0.3)
		get_viewport().get_texture().get_image().save_png(out + "/hand_" + v[0] + ".png")
	var sk: Skeleton3D = a.model.skeleton
	for b in ["hand_r", "hand_l", "lowerarm_r", "lowerarm_l"]:
		var i := sk.find_bone(b)
		print(b, " ölçek=", sk.get_bone_global_pose(i).basis.get_scale(), " konum=", sk.to_global(sk.get_bone_global_pose(i).origin))
	print("ekler: ", a.model._attachments.keys(), " ik: ", a.model._iks.keys())
	for m in a.model.find_children("*", "MeshInstance3D", true, false):
		print("mesh ", m.name, " görünür=", m.visible)
	get_tree().quit()
