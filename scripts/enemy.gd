extends CharacterBody3D
## HAKEM güvenlik dronu: oyuncuyu görünce kovalar, yakındaysa elektrik şokuyla saldırır.

signal died

@export var speed: float = 3.5
@export var max_health: int = 50
@export var damage: int = 10
@export var detect_range: float = 7.5
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.3

var health: int = 0

var _gravity: float = 9.8
var _attack_timer: float = 0.0
var _flash_timer: float = 0.0
var _home: Vector3
var _player: Player
var _material: StandardMaterial3D
var _base_color: Color
var _dead: bool = false

@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/Hover/Body
@onready var _hover: Node3D = $Visual/Hover
var _time: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	_home = global_position
	# Her düşmanın kendi malzemesi olsun ki sadece vurulan yanıp sönsün.
	_material = (_body_mesh.material_override as StandardMaterial3D).duplicate()
	_body_mesh.material_override = _material
	_base_color = _material.albedo_color
	_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_time += delta
	_hover.position.y = 1.25 + sin(_time * 2.5) * 0.08
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	_material.albedo_color = Color.WHITE if _flash_timer > 0.0 else _base_color

	if not is_on_floor():
		velocity.y -= _gravity * delta

	var target_dir := Vector3.ZERO
	var chasing := false
	if _player != null and not _player.is_dead:
		var to_player: Vector3 = _player.global_position - global_position
		to_player.y = 0.0
		var dist: float = to_player.length()
		if dist < detect_range:
			chasing = true
			_face(to_player)
			if dist > attack_range:
				target_dir = to_player.normalized()
			elif _attack_timer <= 0.0:
				_attack_timer = attack_cooldown
				_player.take_damage(damage, to_player.normalized() * 6.0)
				_lunge()
	if not chasing:
		var to_home: Vector3 = _home - global_position
		to_home.y = 0.0
		if to_home.length() > 0.5:
			target_dir = to_home.normalized() * 0.5
			_face(to_home)

	velocity.x = move_toward(velocity.x, target_dir.x * speed, 20.0 * delta)
	velocity.z = move_toward(velocity.z, target_dir.z * speed, 20.0 * delta)
	move_and_slide()

	if global_position.y < -15.0:
		_die()


func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
	if _dead:
		return
	health -= amount
	_flash_timer = 0.12
	velocity += knockback
	velocity.y = 3.0
	if health <= 0:
		_die()


func _face(dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		_visual.rotation.y = atan2(-dir.x, -dir.z)


func _lunge() -> void:
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3(1.2, 0.85, 1.2), 0.08)
	tween.tween_property(_visual, "scale", Vector3.ONE, 0.15)


func _die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)
	died.emit()
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3(1.4, 0.05, 1.4), 0.25)
	tween.tween_callback(queue_free)
