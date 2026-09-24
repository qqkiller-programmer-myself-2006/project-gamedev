class_name SettingsPanel
extends Control
## Player settings overlay: text size, reduced motion and volume. Changes
## apply immediately and are remembered on this device.

var _app: ClientApp
var _volume_label: Label


func setup(app: ClientApp) -> void:
	_app = app
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := UiKit.vbox(12)
	box.custom_minimum_size = Vector2(520, 0)
	center.add_child(UiKit.panel(box, "HighlightPanel"))
	box.add_child(UiKit.label("Settings", "title", UiKit.ACCENT))

	box.add_child(UiKit.label("Text size", "heading"))
	var sizes := UiKit.hbox(8)
	var names := ["Small", "Normal", "Large", "Extra large"]
	var first_button: Button = null
	for i in ClientSettings.TEXT_SCALES.size():
		var scale: float = ClientSettings.TEXT_SCALES[i]
		var current := is_equal_approx(scale, app.settings.text_scale)
		var button := UiKit.button(("> %s" if current else "%s") % names[i], func() -> void:
			app.settings.text_scale = scale
			_save_and_apply()
			UiKit.clear(self)
			setup(app))
		sizes.add_child(button)
		if current:
			first_button = button
	box.add_child(sizes)

	box.add_child(UiKit.label("Motion", "heading"))
	var motion := CheckButton.new()
	motion.text = "Reduce motion (no sliding, fading or floating numbers)"
	motion.button_pressed = app.settings.reduced_motion
	motion.toggled.connect(func(on: bool) -> void:
		app.settings.reduced_motion = on
		_save_and_apply())
	box.add_child(motion)

	box.add_child(UiKit.label("Volume", "heading"))
	var volume_row := UiKit.hbox(10)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = round(app.settings.volume * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	_volume_label = UiKit.label("%d%%" % int(slider.value))
	slider.value_changed.connect(func(value: float) -> void:
		app.settings.volume = value / 100.0
		_volume_label.text = "%d%%" % int(value)
		_save_and_apply()
		app.sounds.play("click"))
	volume_row.add_child(slider)
	volume_row.add_child(_volume_label)
	box.add_child(volume_row)
	box.add_child(UiKit.label("Every sound cue also appears on screen as a banner or log line.", "dim"))

	var close := UiKit.button("Close [Esc]", queue_free, true)
	box.add_child(close)
	(first_button if first_button != null else close).grab_focus.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
		get_viewport().set_input_as_handled()


func _save_and_apply() -> void:
	_app.settings.save()
	_app.apply_settings()
