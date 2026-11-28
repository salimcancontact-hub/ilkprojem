extends SceneTree
func _initialize():
	var s = load("res://assets/apocalypse/S_VehiclePickup.gltf").instantiate()
	get_root().add_child(s)
	var ab := AABB(); var first := true
	for m in s.find_children("*","MeshInstance3D",true,false):
		var a: AABB = m.global_transform * m.get_aabb()
		if first: ab = a; first = false
		else: ab = ab.merge(a)
	print("yerel AABB ", ab)
	quit()
