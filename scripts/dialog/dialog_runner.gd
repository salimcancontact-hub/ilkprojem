class_name DialogRunner
extends RefCounted
## Okunmuş bir diyaloğu adım adım yürütür. Arayüzden bağımsızdır; sinyallerle konuşur.

signal line_shown(speaker: String, text: String)
signal narration_shown(text: String)
signal choices_shown(options: PackedStringArray, timeout: float)
signal notification_shown(text: String)
signal event_fired(event_name: String, args: PackedStringArray)
signal qte_started(step: Dictionary)
signal finished

var active: bool = false

var _nodes: Dictionary = {}
var _stack: Array = []  # her eleman: {"steps": Array, "index": int}
var _choice_step: Dictionary = {}
var _visible_options: Array = []
var _qte_step: Dictionary = {}


func start(nodes: Dictionary, node_name: String) -> void:
	_nodes = nodes
	active = true
	_stack.clear()
	_choice_step = {}
	_goto(node_name)
	advance()


func is_choosing() -> bool:
	return not _choice_step.is_empty() or not _qte_step.is_empty()


## Arayüz QTE'yi bitirince çağırır.
func finish_qte(success: bool) -> void:
	if _qte_step.is_empty():
		return
	var step := _qte_step
	_qte_step = {}
	Story.set_var("son_qte_basarili", success)
	_goto(step["success"] if success else step["fail"])
	advance()


## Kullanıcı girdisi gerektiren bir adıma (replik, anlatım, seçim) kadar ilerler.
func advance() -> void:
	if is_choosing():
		return
	while active:
		if _stack.is_empty():
			_finish()
			return
		var frame: Dictionary = _stack.back()
		var steps: Array = frame["steps"]
		if frame["index"] >= steps.size():
			_stack.pop_back()
			continue
		var step: Dictionary = steps[frame["index"]]
		frame["index"] += 1
		match step["type"]:
			"line":
				line_shown.emit(step["speaker"], step["text"])
				return
			"narr":
				narration_shown.emit(step["text"])
				return
			"notify":
				notification_shown.emit(step["text"])
			"set":
				_apply_set(step)
			"goto":
				_goto(step["target"])
			"if":
				if Story.is_true(step["cond"]):
					_goto(step["target"])
			"event":
				event_fired.emit(step["name"], PackedStringArray(step["args"]))
			"qte":
				_qte_step = step
				qte_started.emit(step)
				return
			"choices":
				_visible_options = []
				for option in step["options"]:
					if option["cond"].is_empty() or Story.is_true(option["cond"]):
						_visible_options.append(option)
				if _visible_options.is_empty():
					continue
				_choice_step = step
				var texts := PackedStringArray()
				for option in _visible_options:
					texts.append(option["text"])
				choices_shown.emit(texts, step["timeout"])
				return


func choose(index: int) -> void:
	if not is_choosing() or index < 0 or index >= _visible_options.size():
		return
	var option: Dictionary = _visible_options[index]
	_choice_step = {}
	var steps: Array = (option["steps"] as Array).duplicate()
	if not option["target"].is_empty():
		steps.append({"type": "goto", "target": option["target"]})
	_stack.append({"steps": steps, "index": 0})
	advance()


## Süre dolduğunda çağrılır: hedef varsa oraya gider, yoksa son seçeneği seçer.
func choose_timeout() -> void:
	if not is_choosing():
		return
	var target: String = _choice_step["timeout_target"]
	if target.is_empty():
		choose(_visible_options.size() - 1)
		return
	_choice_step = {}
	_goto(target)
	advance()


func _goto(node_name: String) -> void:
	_stack.clear()
	if node_name == DialogParser.END:
		return
	if not _nodes.has(node_name):
		push_error("Diyalog düğümü bulunamadı: %s" % node_name)
		return
	_stack.append({"steps": _nodes[node_name], "index": 0})


func _apply_set(step: Dictionary) -> void:
	var value: Variant = Story.evaluate(step["expr"])
	if value == null:
		return
	var var_name: String = step["var"]
	match step["op"]:
		"=":
			Story.set_var(var_name, value)
		"+=":
			Story.set_var(var_name, Story.get_var(var_name, 0) + value)
		"-=":
			Story.set_var(var_name, Story.get_var(var_name, 0) - value)


func _finish() -> void:
	if not active:
		return
	active = false
	_stack.clear()
	finished.emit()
