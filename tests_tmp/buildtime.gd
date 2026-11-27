extends SceneTree
func _initialize():
	var root := Node3D.new()
	get_root().add_child(root)
	var t0 := Time.get_ticks_msec()
	GemiSet.build_zone1(root)
	var t1 := Time.get_ticks_msec()
	GemiSet.build_zone2(root)
	var t2 := Time.get_ticks_msec()
	GemiSet.build_bridge(root); GemiSet.build_exterior(root)
	var t3 := Time.get_ticks_msec()
	print("bölge1 ", t1 - t0, " ms, bölge2 ", t2 - t1, " ms, köprü+dış ", t3 - t2, " ms; düğüm sayısı ", root.get_child_count(), " / toplam ", root.find_children("*", "", true, false).size())
	quit()
