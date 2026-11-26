class_name Ragdoll
extends RefCounted
## Quaternius Universal Base iskeleti için kodla kurulan ragdoll (fizik iskeleti).
## Kemikler birbirleriyle çarpışmaz (titreme olmasın diye); yalnızca dünyayla (katman 1) çarpışır.

const LAYER := 8  # 4. fizik katmanı
## kemik -> [boyunun bittiği çocuk kemik (yoksa ""), yarıçap, kütle, eklem: "cone"/"hinge"]
const BONES := {
	"pelvis": ["spine_01", 0.13, 10.0, "none"],
	"spine_01": ["spine_02", 0.12, 6.0, "cone"],
	"spine_02": ["spine_03", 0.12, 6.0, "cone"],
	"spine_03": ["neck_01", 0.13, 7.0, "cone"],
	"Head": ["", 0.1, 4.0, "cone"],
	"upperarm_l": ["lowerarm_l", 0.055, 2.0, "cone"],
	"lowerarm_l": ["hand_l", 0.045, 1.5, "hinge"],
	"hand_l": ["middle_01_l", 0.04, 0.6, "cone"],
	"upperarm_r": ["lowerarm_r", 0.055, 2.0, "cone"],
	"lowerarm_r": ["hand_r", 0.045, 1.5, "hinge"],
	"hand_r": ["middle_01_r", 0.04, 0.6, "cone"],
	"thigh_l": ["calf_l", 0.08, 7.0, "cone"],
	"calf_l": ["foot_l", 0.06, 4.0, "hinge"],
	"foot_l": ["ball_l", 0.05, 1.0, "cone"],
	"thigh_r": ["calf_r", 0.08, 7.0, "cone"],
	"calf_r": ["foot_r", 0.06, 4.0, "hinge"],
	"foot_r": ["ball_r", 0.05, 1.0, "cone"],
}

var simulator: PhysicalBoneSimulator3D
var bones: Dictionary = {}  # ad -> PhysicalBone3D
var skeleton: Skeleton3D


func _init(sk: Skeleton3D) -> void:
	skeleton = sk
	simulator = PhysicalBoneSimulator3D.new()
	simulator.name = "Ragdoll"
	sk.add_child(simulator)
	for bone_name: String in BONES:
		var spec: Array = BONES[bone_name]
		var idx := sk.find_bone(bone_name)
		if idx < 0:
			continue
		var length := 0.24
		var dir := Vector3.UP
		var child: String = spec[0]
		if child != "" and sk.find_bone(child) >= 0:
			var rest: Vector3 = sk.get_bone_global_rest(sk.find_bone(child)).origin - sk.get_bone_global_rest(idx).origin
			# Kemiğin kendi uzayına çevir
			rest = sk.get_bone_global_rest(idx).basis.inverse() * rest
			length = rest.length()
			dir = rest.normalized()
		var radius: float = spec[1]
		var half := length / 2.0

		var pb := PhysicalBone3D.new()
		pb.name = "F_" + bone_name
		pb.bone_name = bone_name
		pb.mass = spec[2]
		pb.friction = 0.5
		pb.linear_damp = 0.4
		pb.angular_damp = 2.5
		pb.collision_layer = LAYER
		pb.collision_mask = 1
		# Gövde kemiğin ortasında, ekseni kemik boyunca (-Z)
		var body := Transform3D(Basis.looking_at(dir, Vector3.FORWARD if absf(dir.y) > 0.9 else Vector3.UP), dir * half)
		pb.body_offset = body
		pb.joint_offset = Transform3D(Basis.IDENTITY, Vector3(0, 0, half))
		match spec[3]:
			"none":
				pb.joint_type = PhysicalBone3D.JOINT_TYPE_NONE
			"hinge":
				pb.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
				pb.set("joint_constraints/swing_span", 75.0)
				pb.set("joint_constraints/twist_span", 10.0)
			_:
				pb.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
				pb.set("joint_constraints/swing_span", 40.0 if bone_name.begins_with("spine") else 55.0)
				pb.set("joint_constraints/twist_span", 20.0)
		var shape := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = radius
		cap.height = maxf(length, radius * 2.0 + 0.01)
		shape.shape = cap
		shape.rotation = Vector3(PI / 2.0, 0, 0)  # kapsülü Z eksenine yatır
		pb.add_child(shape)
		simulator.add_child(pb)
		bones[bone_name] = pb


func start(impulse_bone: String = "", impulse := Vector3.ZERO) -> void:
	simulator.active = true
	simulator.physical_bones_start_simulation()
	if impulse_bone != "" and bones.has(impulse_bone):
		(bones[impulse_bone] as PhysicalBone3D).apply_central_impulse(impulse)


func stop() -> void:
	simulator.physical_bones_stop_simulation()
	simulator.active = false


func bone(name: String) -> PhysicalBone3D:
	return bones.get(name)


## Bir kemiği bir hedefe doğru çeker (sürükleme için). Her fizik karesinde çağrılır.
## Hız, hedefe uzaklıkla orantılı ve sınırlıdır; bu yüzden kararlıdır.
func pull(bone_name: String, target: Vector3, gain: float = 10.0, max_speed: float = 4.0) -> void:
	var pb: PhysicalBone3D = bones.get(bone_name)
	if pb == null:
		return
	var state := PhysicsServer3D.body_get_direct_state(pb.get_rid())
	if state == null:
		return
	var v := (target - state.transform.origin) * gain
	if v.length() > max_speed:
		v = v.normalized() * max_speed
	state.linear_velocity = v
