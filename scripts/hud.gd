extends CanvasLayer
## Oyun arayüzü: can barı, kristal sayacı, joystick, düğmeler ve mesaj ekranı.

signal restart_requested

const JoystickScript := preload("res://scripts/joystick.gd")

var joystick: Control

var _health_bar: ProgressBar
var _gem_label: Label
var _enemy_label: Label
var _attack_btn: TouchScreenButton
var _jump_btn: TouchScreenButton
var _talk_btn: TouchScreenButton
var _talk_available: bool = false
var _talk_label: Label
var _objective: Label
var _combat: bool = true
var _gameplay_visible: bool = true
var _overlay: ColorRect
var _message: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_health_bar = ProgressBar.new()
	_health_bar.position = Vector2(24, 24)
	_health_bar.size = Vector2(320, 28)
	_health_bar.show_percentage = false
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.2, 0.25)
	fill.set_corner_radius_all(6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(6)
	_health_bar.add_theme_stylebox_override("fill", fill)
	_health_bar.add_theme_stylebox_override("background", bg)
	add_child(_health_bar)

	_gem_label = _make_label(30)
	_enemy_label = _make_label(22)

	joystick = JoystickScript.new()
	joystick.size = Vector2(260, 260)
	add_child(joystick)

	_attack_btn = _make_button("SALDIR", "attack", 150, Color(0.9, 0.3, 0.3, 0.55))
	_jump_btn = _make_button("ZIPLA", "jump", 110, Color(0.3, 0.6, 0.95, 0.55))
	_talk_btn = _make_button("KONUŞ", "interact", 110, Color(0.3, 0.8, 0.5, 0.6))
	_talk_btn.visible = false
	_talk_label = _talk_btn.get_child(0)

	_objective = _make_label(24)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 24)
	_overlay.add_child(box)
	_message = Label.new()
	_message.add_theme_font_size_override("font_size", 56)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_message)
	var restart := Button.new()
	restart.text = "Tekrar Oyna"
	restart.add_theme_font_size_override("font_size", 32)
	restart.custom_minimum_size = Vector2(280, 80)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(restart)

	get_viewport().size_changed.connect(_layout)
	_layout()


func set_health(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current


func set_gems(collected: int, total: int) -> void:
	_gem_label.text = "Enerji hücresi: %d / %d" % [collected, total]
	_layout()


func set_enemies(count: int) -> void:
	_enemy_label.text = "Düşman: %d" % count
	_layout()


## Yakında konuşulabilecek biri varsa KONUŞ düğmesini göster.
func set_talk_available(available: bool, label: String = "KONUŞ") -> void:
	_talk_available = available
	_talk_label.text = label
	_talk_btn.visible = available and _gameplay_visible


## Dövüşsüz sahnelerde can barı, SALDIR ve sayaçlar gizlenir.
func set_combat_enabled(enabled: bool) -> void:
	_combat = enabled
	set_gameplay_visible(_gameplay_visible)


## Ekranın üstünde görev yazısı ("" = gizle).
func set_objective(text: String) -> void:
	_objective.text = text
	_objective.visible = not text.is_empty() and _gameplay_visible
	_layout()


## Diyalog sırasında oyun arayüzünü gizler.
func set_gameplay_visible(visible_now: bool) -> void:
	_gameplay_visible = visible_now
	for node: CanvasItem in [joystick, _jump_btn]:
		node.visible = visible_now
	for node: CanvasItem in [_health_bar, _gem_label, _enemy_label, _attack_btn]:
		node.visible = visible_now and _combat
	_talk_btn.visible = visible_now and _talk_available
	_objective.visible = visible_now and not _objective.text.is_empty()
	joystick.reset()


func show_message(text: String) -> void:
	_message.text = text
	_overlay.visible = true
	_attack_btn.visible = false
	_jump_btn.visible = false
	_talk_btn.visible = false
	joystick.visible = false


## Telefonun gezinme çubuğu ve çentiği için ekran kenarlarından bırakılacak pay.
func _safe_insets() -> Rect2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0:
		return Rect2(0, 0, 0, 0)
	var s := vp / win
	var left := maxf(safe.position.x * s.x, 0.0)
	var top := maxf(safe.position.y * s.y, 0.0)
	var right := maxf((win.x - safe.end.x) * s.x, 0.0)
	var bottom := maxf((win.y - safe.end.y) * s.y, 0.0)
	return Rect2(left, top, right, bottom)


func _layout() -> void:
	var full: Vector2 = get_viewport().get_visible_rect().size
	var ins := _safe_insets()
	# Gezinme çubuğunu her zaman hesaba katmak için mobilde en az 24 px ek pay
	var extra := 24.0 if OS.has_feature("mobile") else 0.0
	var off := Vector2(ins.position.x + extra, ins.position.y)
	var vp: Vector2 = full - Vector2(ins.position.x + ins.size.x + extra * 2.0, ins.position.y + ins.size.y)
	_gem_label.position = off + Vector2(vp.x - _gem_label.get_minimum_size().x - 24, 18)
	_enemy_label.position = off + Vector2(vp.x - _enemy_label.get_minimum_size().x - 24, 62)
	_health_bar.position = off + Vector2(24, 24)
	joystick.position = off + Vector2(40, vp.y - joystick.size.y - 30)
	_attack_btn.position = off + Vector2(vp.x - 150 - 50, vp.y - 150 - 50)
	_jump_btn.position = off + Vector2(vp.x - 110 - 50, vp.y - 110 - 40)
	_talk_btn.position = off + Vector2(vp.x - 110 - 50, vp.y - 110 - 200)
	_objective.size = Vector2(vp.x * 0.6, 0)
	_objective.position = off + Vector2(vp.x * 0.2, 22)


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label


func _make_button(text: String, action: String, diameter: int, color: Color) -> TouchScreenButton:
	var btn := TouchScreenButton.new()
	btn.texture_normal = _circle_texture(diameter, color)
	btn.texture_pressed = _circle_texture(diameter, Color(color, minf(color.a + 0.3, 1.0)))
	btn.action = action
	btn.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	var shape := CircleShape2D.new()
	shape.radius = diameter / 2.0
	btn.shape = shape
	btn.shape_centered = true
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(diameter, diameter)
	btn.add_child(label)
	add_child(btn)
	return btn


func _circle_texture(diameter: int, color: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r: float = diameter / 2.0
	for y in diameter:
		for x in diameter:
			var d: float = Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var alpha: float = clampf(r - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(color, color.a * alpha))
	return ImageTexture.create_from_image(img)
