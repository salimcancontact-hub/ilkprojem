class_name DialogParser
extends RefCounted
## .dlg diyalog dosyalarını okur. Sözdizimi: docs/DIYALOG_SOZDIZIMI.md

const END := "SON"


static func load_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Diyalog dosyası açılamadı: %s" % path)
		return {}
	return parse(f.get_as_text(), path)


## Metni düğümlere ayırır: { "düğüm_adı": [adım, adım, ...] }
static func parse(text: String, source: String = "<metin>") -> Dictionary:
	var nodes: Dictionary = {}
	var current: Array = []
	var current_name := ""
	var pending_timeout := -1.0
	var pending_timeout_target := ""
	var last_option: Dictionary = {}

	var lines := text.split("\n")
	for i in lines.size():
		var raw: String = lines[i].replace("\r", "")
		var line := raw.strip_edges()
		var where := "%s:%d" % [source, i + 1]
		if line.is_empty() or line.begins_with("#"):
			continue

		if line.begins_with("==="):
			current_name = line.trim_prefix("===").strip_edges()
			if nodes.has(current_name):
				push_error("%s: '%s' düğümü iki kez tanımlanmış" % [where, current_name])
			current = []
			nodes[current_name] = current
			last_option = {}
			continue
		if current_name.is_empty():
			push_error("%s: satır bir düğümün (=== ad) içinde olmalı" % where)
			continue

		# Bir seçeneğin altındaki girintili satırlar o seçeneğe aittir.
		var indented := raw.begins_with(" ") or raw.begins_with("\t")
		if indented and not last_option.is_empty():
			var sub: Variant = _parse_step(line, where)
			if sub != null:
				(last_option["steps"] as Array).append(sub)
			continue

		if line.begins_with("*"):
			var option := _parse_option(line.substr(1).strip_edges())
			var prev: Variant = current.back() if current.size() > 0 else null
			if not last_option.is_empty() and prev is Dictionary and prev["type"] == "choices":
				(prev["options"] as Array).append(option)
			else:
				current.append({
					"type": "choices",
					"options": [option],
					"timeout": pending_timeout,
					"timeout_target": pending_timeout_target,
				})
				pending_timeout = -1.0
				pending_timeout_target = ""
			last_option = option
			continue

		last_option = {}
		if line.begins_with("@sure"):
			var rest := line.trim_prefix("@sure").strip_edges()
			var arrow := rest.find("->")
			if arrow != -1:
				pending_timeout_target = rest.substr(arrow + 2).strip_edges()
				rest = rest.substr(0, arrow).strip_edges()
			pending_timeout = rest.to_float()
			continue

		var step: Variant = _parse_step(line, where)
		if step != null:
			current.append(step)

	_validate(nodes, source)
	return nodes


static func _parse_option(text: String) -> Dictionary:
	var option := {"text": "", "target": "", "cond": "", "steps": []}
	if text.begins_with("{"):
		var close := text.find("}")
		option["cond"] = text.substr(1, close - 1).strip_edges()
		text = text.substr(close + 1).strip_edges()
	var arrow := text.rfind("->")
	if arrow != -1:
		option["target"] = text.substr(arrow + 2).strip_edges()
		text = text.substr(0, arrow).strip_edges()
	option["text"] = text
	return option


static func _parse_step(line: String, where: String) -> Variant:
	if line.begins_with("->"):
		return {"type": "goto", "target": line.substr(2).strip_edges()}
	if line.begins_with(">"):
		return {"type": "narr", "text": line.substr(1).strip_edges()}
	if line.begins_with("!"):
		return {"type": "notify", "text": line.substr(1).strip_edges()}
	if line.begins_with("~"):
		var re := RegEx.new()
		re.compile("^([A-Za-z_][A-Za-z0-9_]*)\\s*(\\+=|-=|=)\\s*(.+)$")
		var m := re.search(line.substr(1).strip_edges())
		if m == null:
			push_error("%s: değişken satırı hatalı: %s" % [where, line])
			return null
		return {"type": "set", "var": m.get_string(1), "op": m.get_string(2), "expr": m.get_string(3)}
	if line.begins_with("@if"):
		var rest := line.trim_prefix("@if").strip_edges()
		var arrow := rest.rfind("->")
		if arrow == -1:
			push_error("%s: @if satırında '-> hedef' eksik" % where)
			return null
		return {"type": "if", "cond": rest.substr(0, arrow).strip_edges(), "target": rest.substr(arrow + 2).strip_edges()}
	if line.begins_with("@qte"):
		return _parse_qte(line.trim_prefix("@qte").strip_edges(), where)
	if line.begins_with("@olay"):
		var parts := line.trim_prefix("@olay").strip_edges().split(" ", false)
		if parts.is_empty():
			push_error("%s: @olay adı eksik" % where)
			return null
		return {"type": "event", "name": parts[0], "args": parts.slice(1)}

	var colon := line.find(":")
	if colon > 0:
		var speaker := line.substr(0, colon).strip_edges()
		if speaker == speaker.to_upper() and not speaker.contains(" "):
			return {"type": "line", "speaker": speaker, "text": line.substr(colon + 1).strip_edges()}
	push_error("%s: anlaşılamayan satır: %s" % [where, line])
	return null


## @qte bas 1.5 "EĞİL" -> başarı | başarısızlık
## @qte vur 3.0 10 "KALDIR" -> başarı | başarısızlık   (3 sn içinde 10 dokunuş)
## @qte kaydir sol 1.2 "KAÇ" -> başarı | başarısızlık  (sol, sag, yukari, asagi)
static func _parse_qte(rest: String, where: String) -> Variant:
	var arrow := rest.find("->")
	if arrow == -1:
		push_error("%s: @qte satırında '-> başarı | başarısızlık' eksik" % where)
		return null
	var targets := rest.substr(arrow + 2).split("|")
	var head := rest.substr(0, arrow).strip_edges()
	var label := ""
	var q1 := head.find("\"")
	if q1 != -1:
		var q2 := head.find("\"", q1 + 1)
		label = head.substr(q1 + 1, q2 - q1 - 1)
		head = head.substr(0, q1).strip_edges()
	var parts := head.split(" ", false)
	if parts.is_empty():
		push_error("%s: @qte türü eksik" % where)
		return null
	var step := {"type": "qte", "kind": parts[0], "label": label, "time": 1.5, "count": 1, "dir": "",
		"success": targets[0].strip_edges(), "fail": targets[1].strip_edges() if targets.size() > 1 else targets[0].strip_edges()}
	match parts[0]:
		"bas":
			step["time"] = parts[1].to_float() if parts.size() > 1 else 1.5
		"vur":
			step["time"] = parts[1].to_float() if parts.size() > 1 else 3.0
			step["count"] = parts[2].to_int() if parts.size() > 2 else 8
		"kaydir":
			step["dir"] = parts[1] if parts.size() > 1 else "sol"
			step["time"] = parts[2].to_float() if parts.size() > 2 else 1.5
		_:
			push_error("%s: bilinmeyen QTE türü: %s" % [where, parts[0]])
			return null
	return step


## Var olmayan düğümlere yapılan atlamaları raporlar.
static func _validate(nodes: Dictionary, source: String) -> void:
	var targets: Array = []
	for node_name in nodes:
		_collect_targets(nodes[node_name], targets)
	for t in targets:
		if t != END and not t.is_empty() and not nodes.has(t):
			push_error("%s: '%s' adlı düğüm bulunamadı" % [source, t])


static func _collect_targets(steps: Array, out: Array) -> void:
	for step in steps:
		match step["type"]:
			"goto", "if":
				out.append(step["target"])
			"qte":
				out.append(step["success"])
				out.append(step["fail"])
			"choices":
				out.append(step["timeout_target"])
				for option in step["options"]:
					out.append(option["target"])
					_collect_targets(option["steps"], out)
