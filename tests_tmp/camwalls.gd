extends Node
## Kamera duvar/tavan dışına çıkıyor mu? Oyuncuyu duvar diplerine koyup kamerayı döndürür.
var level
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.vars.clear(); Story.set_var("oyuncu_adi", "T")
	level = load("res://scenes/binis.tscn").instantiate()
	get_tree().root.add_child.call_deferred(level)
	_run.call_deferred()
func inside(p: Vector3) -> bool:
	var Z2: Vector3 = level.Z2
	var boxes := [
		AABB(Vector3(-2.0, -0.2, -1.6), Vector3(20.0, 5.2, 11.6)),   # iskele
		AABB(Vector3(-2.0, -0.2, 10.0), Vector3(20.0, 10.2, 20.0)),  # meydan
		AABB(Z2 + Vector3(-1.6, -0.2, -1.0), Vector3(3.2, 3.2, 23.0)),  # koridor
		AABB(Z2 + Vector3(1.6, -0.2, 5.0), Vector3(6.0, 3.0, 4.0)),  # kamara
	]
	for b in boxes:
		if b.grow(0.05).has_point(p): return true
	return false
func _run():
	var d = level._dialog
	while level._phase == "baslangic":
		await get_tree().process_frame
		if d.active and not d._waiting and Engine.get_process_frames() % 4 == 0:
			d._block_input = 0; d._finish_typing(); d._advance()
	level._open_gate()
	level._set_zone(2, true)
	(level._z2["cabin_door"] as Node3D).position.z = 8.25
	var Z2: Vector3 = level.Z2
	var spots := [Vector3(-1.2, 0.1, 1.0), Vector3(16.8, 0.1, 1.0), Vector3(-0.9, 0.1, 28.5), Vector3(16.5, 0.1, 28.0), Vector3(8, 0.1, -1.0),
		Z2 + Vector3(-1.2, 0.1, 0.0), Z2 + Vector3(1.2, 0.1, 21.5), Z2 + Vector3(0, 0.1, 10), Z2 + Vector3(2.0, 0.1, 5.4), Z2 + Vector3(7.2, 0.1, 8.6), Z2 + Vector3(7.2, 0.1, 5.4), Z2 + Vector3(4.0, 0.1, 7.6)]
	var bad := 0
	var p = level._player
	var pivot: Node3D = p.get_node("CameraPivot")
	for s in spots:
		p.global_position = s
		p.velocity = Vector3.ZERO
		for yaw in range(0, 360, 30):
			for pitch in [-15.0, -45.0, 10.0]:
				pivot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
				for k in 3: await get_tree().physics_frame
				var c: Vector3 = level._player_cam.global_position
				if not inside(c):
					bad += 1
					if bad < 25:
						var q := PhysicsRayQueryParameters3D.create(pivot.global_position, c, 1)
						q.exclude = [p.get_rid()]
						var hit: Dictionary = level.get_world_3d().direct_space_state.intersect_ray(q)
						var arm: SpringArm3D = pivot.get_node("SpringArm3D")
						print("DIŞARIDA: oyuncu=", s, " yaw=", yaw, " eğim=", pitch, " kamera=", c, " ışın=", hit.get("collider", "YOK"), " kol=", arm.get_hit_length(), " kol_x=", arm.position.x)
	print("KAMERA DIŞARI ÇIKMA SAYISI: ", bad)
	get_tree().quit()
