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
			"choices":
				out.append(step["timeout_target"])
				for option in step["options"]:
					out.append(option["target"])
					_collect_targets(option["steps"], out)
