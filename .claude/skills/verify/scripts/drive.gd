extends SceneTree
## Verification driver for VerbEndings. Boots the real main scene with its
## autoloads, then executes a plain-text step file by injecting real input
## events (mouse clicks resolve through GUI hit-testing, keys through the
## project's InputMap). Evidence is written to the --out directory.
##
## Usage (normally through verify.sh):
##   godot4.3 --path <repo> --script drive.gd -- --steps <file> --out <dir>

const MAIN_SCENE := "res://scenes/core/Game.tscn"

var _steps_path := ""
var _out_dir := ""
var _log: Array[String] = []
var _presentation: Node = null
var _failed := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--steps":
				_steps_path = args[i + 1]
				i += 1
			"--out":
				_out_dir = args[i + 1]
				i += 1
		i += 1
	if _steps_path.is_empty() or _out_dir.is_empty():
		printerr("drive.gd: --steps <file> and --out <dir> are required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out_dir)
	change_scene_to_file(MAIN_SCENE)
	_run()


func _run() -> void:
	for _i in 10:
		await process_frame
	_presentation = _find_presentation(current_scene)
	if _presentation == null:
		_fail("TrialPresentation not found under %s" % MAIN_SCENE)
		return _finish()
	var file := FileAccess.open(_steps_path, FileAccess.READ)
	if file == null:
		_fail("cannot open steps file %s" % _steps_path)
		return _finish()
	var line_no := 0
	while not file.eof_reached():
		var raw := file.get_line()
		line_no += 1
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var words := _split(line)
		_note("STEP %d: %s" % [line_no, line])
		var ok: bool = await _execute(words)
		if not ok:
			_fail("step %d failed: %s" % [line_no, line])
			await _shot("failure")
			await _snapshot("failure")
			break
		if words[0] == "quit":
			break
	_finish()


func _execute(w: PackedStringArray) -> bool:
	match w[0]:
		"wait":
			await create_timer(float(w[1])).timeout
			return true
		"click":
			return await _click_button(w[1])
		"click_node":
			return await _click_control(_find_control_by_name(w[1]), w[1])
		"key":
			await _key(w[1], true)
			await process_frame
			await _key(w[1], false)
			return true
		"hold":
			await _key(w[1], true)
			await create_timer(float(w[2])).timeout
			await _key(w[1], false)
			return true
		"type":
			for ch in w[1]:
				var ev := InputEventKey.new()
				ev.pressed = true
				ev.unicode = ch.unicode_at(0)
				Input.parse_input_event(ev)
				await process_frame
			return true
		"mouse":
			var button := MOUSE_BUTTON_LEFT if w[1] == "left" else MOUSE_BUTTON_RIGHT
			await _mouse_button(button, _window_centre())
			return true
		"wait_text":
			return await _wait_for(func() -> bool: return _visible_text().contains(w[1]),
					float(w[2]) if w.size() > 2 else 10.0)
		"wait_screen":
			return await _wait_for(func() -> bool: return String(_presentation.current_screen) == w[1],
					float(w[2]) if w.size() > 2 else 10.0)
		"wait_phase":
			return await _wait_for(func() -> bool: return _phase() == w[1],
					float(w[2]) if w.size() > 2 else 10.0)
		"expect_text":
			return _visible_text().contains(w[1])
		"expect_absent":
			return not _visible_text().contains(w[1])
		"shot":
			await _shot(w[1])
			return true
		"snapshot":
			await _snapshot(w[1])
			return true
		"inspect":
			var value: Variant = _evaluate(w[2])
			_write_json(w[1], {"expression": w[2], "value": value})
			return true
		"expect":
			var result: Variant = _evaluate(w[1])
			_note("expect %s -> %s" % [w[1], result])
			return result == true
		"copy_user":
			return _copy_user(w[1])
		"quit":
			return true
	_note("unknown step verb '%s'" % w[0])
	return false


func _click_button(label: String) -> bool:
	for _attempt in 20:
		for node: Node in _all_nodes(root):
			if node is BaseButton and node.is_visible_in_tree() and not node.disabled \
					and node.get("text") == label:
				return await _click_control(node, label)
		await process_frame
	_note("no visible enabled button with text '%s'; visible buttons: %s" % [label, _button_texts()])
	return false


func _click_control(control: Control, label: String) -> bool:
	if control == null or not control.is_visible_in_tree():
		_note("control '%s' not visible" % label)
		return false
	var pos := root.get_final_transform() * control.get_global_rect().get_center()
	await _mouse_button(MOUSE_BUTTON_LEFT, pos)
	return true


func _mouse_button(button: MouseButton, pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		Input.parse_input_event(ev)
		await process_frame


func _key(spec: String, pressed: bool) -> void:
	var ev := InputEventKey.new()
	var parts := spec.split("+")
	for mod in parts.slice(0, parts.size() - 1):
		match mod.to_lower():
			"ctrl": ev.ctrl_pressed = true
			"shift": ev.shift_pressed = true
			"alt": ev.alt_pressed = true
	var code := OS.find_keycode_from_string(parts[parts.size() - 1])
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	await process_frame


func _wait_for(predicate: Callable, timeout: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await process_frame
	_note("timed out after %.1fs; screen=%s phase=%s" % [timeout, _presentation.current_screen, _phase()])
	return false


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _out_dir.path_join("%s.png" % name)
	root.get_texture().get_image().save_png(path)
	_note("shot %s" % path)


func _snapshot(name: String) -> void:
	await process_frame
	var data: Dictionary = _presentation.presentation_snapshot()
	data["phase"] = _phase()
	data["round_index"] = root.get_node("RoundManager").current_round_index
	data["window_size"] = DisplayServer.window_get_size()
	data["visible_controls"] = _visible_controls()
	_write_json(name, data)


## Observation only: evaluates a Godot Expression against the Game root,
## with every autoload (TrialCoordinator, RoundManager, …) bound by name.
func _evaluate(source: String) -> Variant:
	var names := PackedStringArray()
	var values: Array = []
	for child in root.get_children():
		if child != current_scene:
			names.append(String(child.name))
			values.append(child)
	var expression := Expression.new()
	if expression.parse(source, names) != OK:
		_note("expression did not parse (%s)" % expression.get_error_text())
		return null
	var value: Variant = expression.execute(values, current_scene, false)
	if expression.has_execute_failed():
		_note("expression did not evaluate (%s)" % expression.get_error_text())
		return null
	return value


func _write_json(name: String, data: Dictionary) -> void:
	var path := _out_dir.path_join("%s.json" % name)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	_note("wrote %s" % path)


func _copy_user(relative: String) -> bool:
	var source := "user://".path_join(relative)
	if not FileAccess.file_exists(source):
		_note("user file missing: %s (%s)" % [source, ProjectSettings.globalize_path(source)])
		return false
	var dest := _out_dir.path_join(relative.get_file())
	var err := DirAccess.copy_absolute(ProjectSettings.globalize_path(source), dest)
	_note("copied %s -> %s (err %d)" % [source, dest, err])
	return err == OK


func _phase() -> String:
	var coordinator: Node = root.get_node("TrialCoordinator")
	return String(coordinator.Phase.find_key(coordinator.current_phase))


func _visible_text() -> String:
	var parts: Array[String] = []
	for node: Node in _all_nodes(root):
		if (node is Label or node is Button or node is LineEdit or node is TextEdit) \
				and node.is_visible_in_tree():
			parts.append(node.text)
	return "\n".join(parts)


func _visible_controls() -> Array:
	var out: Array = []
	for node: Node in _all_nodes(root):
		if (node is Label or node is BaseButton or node is LineEdit or node is SpinBox) \
				and node.is_visible_in_tree():
			out.append({"type": node.get_class(), "name": String(node.name),
					"text": str(node.get("text")) if node.get("text") != null else "",
					"rect": str(node.get_global_rect())})
	return out


func _button_texts() -> Array:
	var out: Array = []
	for node: Node in _all_nodes(root):
		if node is BaseButton and node.is_visible_in_tree():
			out.append(node.get("text"))
	return out


func _find_control_by_name(node_name: String) -> Control:
	for node: Node in _all_nodes(root):
		if node is Control and String(node.name) == node_name and node.is_visible_in_tree():
			return node
	return null


func _find_presentation(from: Node) -> Node:
	for node: Node in _all_nodes(from):
		if node.has_method("presentation_snapshot"):
			return node
	return null


func _all_nodes(from: Node) -> Array[Node]:
	var out: Array[Node] = [from]
	for child in from.get_children():
		out.append_array(_all_nodes(child))
	return out


func _window_centre() -> Vector2:
	return Vector2(DisplayServer.window_get_size()) / 2.0


func _split(line: String) -> PackedStringArray:
	var out := PackedStringArray()
	var current := ""
	var quote := ""
	for ch in line:
		if quote.is_empty() and (ch == "\"" or ch == "'"):
			quote = ch
		elif ch == quote:
			quote = ""
		elif ch == " " and quote.is_empty():
			if not current.is_empty():
				out.append(current)
			current = ""
		else:
			current += ch
	if not current.is_empty():
		out.append(current)
	return out


func _note(message: String) -> void:
	print("[verify] ", message)
	_log.append(message)


func _fail(message: String) -> void:
	_failed = true
	_note("FAIL " + message)


func _finish() -> void:
	_note("RESULT %s" % ("FAIL" if _failed else "PASS"))
	var f := FileAccess.open(_out_dir.path_join("steps.log"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_log) + "\n")
		f.close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit(1 if _failed else 0)
