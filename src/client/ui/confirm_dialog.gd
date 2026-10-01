class_name ConfirmDialog
extends Control
## Modal "are you sure?" box for destructive actions (Leave, Reset Skills).
## Cancel has the focus, Esc cancels, and keys never reach the screen behind.

var _on_confirm: Callable


func setup(title: String, text: String, confirm_label: String, on_confirm: Callable) -> void:
	_on_confirm = on_confirm
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiKit.BG, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var body := UiKit.vbox(12)
	body.custom_minimum_size = Vector2(460, 0)
	center.add_child(UiKit.panel(body))
	body.add_child(UiKit.label(title, "heading", UiKit.ACCENT))
	body.add_child(UiKit.para(text))
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	var cancel := UiKit.button("Cancel [Esc]", close, false, "secondary", "cancel")
	cancel.set_meta("focus_id", "confirm_cancel")
	var ok := UiKit.button(confirm_label, _confirm, false, "danger", "cancel" if confirm_label.to_lower().begins_with("leave") else "")
	ok.set_meta("focus_id", "confirm_ok")
	row.add_child(cancel)
	row.add_child(ok)
	body.add_child(row)
	# Keep Tab / arrows inside the dialog.
	for pair in [[cancel, ok], [ok, cancel]]:
		var from: Button = pair[0]
		var to: Button = pair[1]
		from.focus_next = from.get_path_to(to)
		from.focus_previous = from.get_path_to(to)
		from.focus_neighbor_left = from.get_path_to(to)
		from.focus_neighbor_right = from.get_path_to(to)
		from.focus_neighbor_top = from.get_path_to(from)
		from.focus_neighbor_bottom = from.get_path_to(from)
	cancel.grab_focus.call_deferred()


func close() -> void:
	queue_free()


func _confirm() -> void:
	queue_free()
	_on_confirm.call()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	if event.keycode == KEY_ESCAPE and not event.echo:
		close()
	get_viewport().set_input_as_handled()
