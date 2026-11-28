extends SceneTree
func _initialize():
	var m = load("res://scenes/characters/evren_model.tscn").instantiate()
	get_root().add_child(m)
	await process_frame
	var a = m.animation_player.get_animation(m.resolve("Fixing_Kneeling"))
	print("uzunluk ", a.length)
	for t in [0.1, 0.25, 0.45, 0.6, 0.8, 0.98]:
		m.hold_pose("Fixing_Kneeling", t, 0.0)
		await process_frame
		print(t, " kalça_y=", m.bone_position("pelvis").y, " omuz_y=", m.bone_position("upperarm_r").y)
	quit()
