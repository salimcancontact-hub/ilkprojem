class_name Player
extends CharacterBody3D
## Oyuncu karakteri: hareket, zıplama, kılıç saldırısı ve kamera kontrolü.

signal health_changed(current: int, maximum: int)
signal died

@export var speed: float = 6.0
@export var acceleration: float = 40.0
@export var jump_velocity: float = 7.5
@export var max_health: int = 100
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.45
@export var camera_sensitivity: float = 0.006

var health: int = 0
var is_dead: bool = false
## Sanal joystick'ten gelen girdi (-1..1).
var move_input: Vector2 = Vector2.ZERO

var _gravity: float = 9.8
var _attack_timer: float = 0.0
var _invuln_timer: float = 0.0

@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/Body
@onready var _sword_pivot: Node3D = $Visual/SwordPivot
@onready var _attack_area: Area3D = $Visual/AttackArea
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _spring_arm: SpringArm3D = $CameraPivot/SpringArm3D


func _ready() -> void:
	_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	health = max_health
	_camera_pivot.rotation.x = deg_to_rad(-20.0)
	_spring_arm.add_excluded_object(get_rid())


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)

	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Joystick veya klavye, hangisi güçlüyse onu kullan.
	var input_vec: Vector2 = move_input
	var kb: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if kb.length() > input_vec.length():
		input_vec = kb

	# Hareketi kameranın baktığı yöne göre hesapla.
	var cam_basis: Basis = _camera_pivot.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = cam_basis.x
	right.y = 0.0
	right = right.normalized()
	var direction: Vector3 = right * input_vec.x - forward * input_vec.y
	if direction.length() > 1.0:
		direction = direction.normalized()

	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)

	if direction.length_squared() > 0.01:
		var target_angle: float = atan2(-direction.x, -direction.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, target_angle, 12.0 * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("attack"):
		attack()

	move_and_slide()

	if global_position.y < -15.0:
		_die()

	# Hasar aldıktan sonra kısa süre yanıp sön.
	_body_mesh.visible = _invuln_timer <= 0.0 or fmod(_invuln_timer, 0.2) > 0.1


func _unhandled_input(event: InputEvent) -> void:
	# Ekranın boş bir yerinde parmak sürüklenirse kamerayı döndür.
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_camera_pivot.rotation.y -= drag.relative.x * camera_sensitivity
		_camera_pivot.rotation.x = clampf(
			_camera_pivot.rotation.x - drag.relative.y * camera_sensitivity,
			deg_to_rad(-60.0), deg_to_rad(10.0))


func attack() -> void:
	if _attack_timer > 0.0 or is_dead:
		return
	_attack_timer = attack_cooldown

	_sword_pivot.rotation.y = deg_to_rad(70.0)
	var tween := create_tween()
	tween.tween_property(_sword_pivot, "rotation:y", deg_to_rad(-70.0), 0.12)
	tween.tween_property(_sword_pivot, "rotation:y", 0.0, 0.15)

	for body in _attack_area.get_overlapping_bodies():
		if body != self and body.has_method("take_damage"):
			var push: Vector3 = body.global_position - global_position
			push.y = 0.0
			body.call("take_damage", attack_damage, push.normalized() * 8.0)


func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	if is_dead or _invuln_timer > 0.0:
		return
	health = maxi(health - amount, 0)
	_invuln_timer = 0.8
	if knockback != Vector3.ZERO:
		velocity += knockback
		velocity.y = 3.0
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	health = 0
	_body_mesh.visible = true
	health_changed.emit(health, max_health)
	died.emit()
