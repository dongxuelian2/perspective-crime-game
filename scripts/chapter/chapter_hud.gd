extends Control
## Screen-space medallions communicate reachability; they aren't hidden auto-walk buttons.
var flow
var hint := false
var controls: HBoxContainer
var help: PanelContainer
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls = HBoxContainer.new()
	controls.position = Vector2(26, 22)
	controls.add_theme_constant_override("separation", 10)
	add_child(controls)
	for item in [["↻", "Restart district", "restart"], ["?", "Show controls", "help"], ["♫", "Toggle sound", "mute"], ["◇", "Show gentle hint", "hint"]]:
		var button := Button.new()
		button.text = item[0]
		button.tooltip_text = item[1]
		button.custom_minimum_size = Vector2(44, 44)
		button.pressed.connect(func(): action(item[2]))
		controls.add_child(button)
	help = PanelContainer.new()
	help.position = Vector2(28, 80)
	help.custom_minimum_size = Vector2(400, 0)
	add_child(help)
	var text := Label.new()
	text.text = "Drag the brass grips to reshape streets.\nClick a glowing landing to walk there.\nYou can stop at any landing.\nRide level carriages as streets fold.\nAn empty cart can lift another platform.\nA brass pin holds one linked street still.\n\nR: restart district  ·  M: sound  ·  Esc: close\nProgress is saved at district entrances."
	text.add_theme_font_size_override("font_size", 18)
	help.add_child(text)
	help.hide()
func action(which: String) -> void:
	if which == "restart": flow.restart()
	elif which == "help":
		help.visible = not help.visible
		flow.cancel_gesture()
	elif which == "mute": flow.toggle_sound()
	elif which == "hint": hint = not hint
func _draw() -> void:
	if flow == null or flow.mode != "play" or not is_instance_valid(flow.district): return
	var chapter = flow.district
	var camera: Camera3D = flow.camera
	for i in range(flow.Layouts.count()):
		draw_circle(Vector2(size.x/2 - 44 + i*22, 35), 4, Color("e5b96c") if i <= flow.checkpoint else Color("45616a"))
	for mechanism in chapter.mechanisms:
		if not mechanism.interactive: continue
		var p := camera.unproject_position(mechanism.handle.global_position)
		var color := Color("e5b96c") if not mechanism.locked else Color("cf7764")
		draw_arc(p, 20, -.7, 4.4, 32, color, 2.5, true)
		draw_circle(p + Vector2(16, -12), 3, color)
	for pin_data in chapter.pins:
		var pin := camera.unproject_position(pin_data.marker.global_position)
		var pin_color := Color("e5b96c") if flow.actor_id == pin_data.at else Color("78989a")
		draw_rect(Rect2(pin-Vector2(16,16),Vector2(32,32)),pin_color,false,2)
		if pin_data.engaged: draw_line(pin-Vector2(8,0),pin+Vector2(8,0),pin_color,3)
		else: draw_line(pin-Vector2(0,8),pin+Vector2(0,8),pin_color,3)
	for id in chapter.points:
		var p := camera.unproject_position(chapter.points[id])
		var route: Array = chapter.graph.route(flow.actor_id, id)
		if not route.is_empty() and id != flow.actor_id:
			draw_arc(p, 12, 0, TAU, 24, Color(1,.85,.5,.7), 2, true)
	if not flow.walking:
		var mouse := get_viewport().get_mouse_position()
		for id in chapter.points:
			if camera.unproject_position(chapter.points[id]).distance_to(mouse) < 24:
				var preview: Array = chapter.graph.route(flow.actor_id,id)
				for i in range(1,preview.size()):
					draw_dashed_line(camera.unproject_position(chapter.points[preview[i-1]]),camera.unproject_position(chapter.points[preview[i]]),Color(1,.8,.4,.45),2,5)
				break
	if flow.invalid_timer > 0:
		draw_arc(flow.invalid_at, 18 + (1-flow.invalid_timer)*12, 0, TAU, 30, Color(1,.5,.4,flow.invalid_timer), 2, true)
	if hint:
		var message: String = flow.hint_text()
		draw_style_box(hint_box(), Rect2(24, size.y-72, size.x-48, 48))
		draw_string(ThemeDB.fallback_font, Vector2(40,size.y-42), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ede2c5"))
func hint_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(.04,.12,.16,.95)
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	return box
