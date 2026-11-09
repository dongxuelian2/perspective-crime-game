extends Control
## Restrained, resolution-aware presentation; all gameplay lives in main.gd.
var level: Node3D
var display_font: Font
var body_font: Font
var title_group: Control
var game_group: Control
var ending_group: Control
var title_label: Label
var stage_label: Label
var subtitle_label: Label
var feedback_label: Label
var view_label: Label
var begin_button: Button
var replay_button: Button
var walk_button: Button
var previous_button: Button
var next_button: Button
var mute_button: Button
var reset_button: Button
var help_button: Button
var hint_button: Button
var help_panel: Control
var help_open := false
var help_close: Button
var all_labels: Array[Label] = []
const GOLD := Color("e5c48b")
const IVORY := Color("f6e8ca")
const MUTED := Color("90b6b5")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_font = ThemeDB.fallback_font
	display_font = load("res://assets/fonts/DisplaySerif.ttf") if ResourceLoader.exists("res://assets/fonts/DisplaySerif.ttf") else body_font
	title_group = group()
	game_group = group()
	ending_group = group()
	label("P E R S P E C T I V E   C R I M E", 14, GOLD, title_group).position = Vector2(64, 137)
	title_label = label("The Folded\nObservatory", 55, IVORY, title_group, true)
	title_label.position = Vector2(60, 176)
	title_label.add_theme_constant_override("line_spacing", 2)
	var intro := label("Some distances exist\nonly until you change your view.", 20, MUTED, title_group)
	intro.position = Vector2(64, 330)
	intro.add_theme_constant_override("line_spacing", 8)
	begin_button = button("Begin the journey   →", Vector2(64, 425), Vector2(256, 54), title_group, true)
	begin_button.pressed.connect(level.begin)
	var introduction := label("An original, impossible-space miniature\nThree lights. One quiet journey.", 14, MUTED, title_group)
	introduction.position = Vector2(64, 505)
	introduction.add_theme_constant_override("line_spacing", 5)
	label("SPACE TO BEGIN     •     SOUND RECOMMENDED", 11, GOLD, title_group).position = Vector2(64, 576)
	label("THE FOLDED OBSERVATORY", 13, GOLD, game_group).position = Vector2(48, 34)
	stage_label = label("", 31, IVORY, game_group, true)
	stage_label.position = Vector2(46, 65)
	subtitle_label = label("", 15, MUTED, game_group)
	subtitle_label.position = Vector2(48, 111)
	feedback_label = label("", 17, IVORY, game_group)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.size = Vector2(960, 36)
	view_label = label("", 11, GOLD, game_group)
	view_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	previous_button = button("‹", Vector2.ZERO, Vector2(54, 52), game_group)
	next_button = button("›", Vector2.ZERO, Vector2(54, 52), game_group)
	previous_button.add_theme_font_size_override("font_size", 31)
	next_button.add_theme_font_size_override("font_size", 31)
	previous_button.pressed.connect(func(): level.turn_view(-1))
	next_button.pressed.connect(func(): level.turn_view(1))
	walk_button = button("Walk the fold   →", Vector2.ZERO, Vector2(218, 52), game_group, true)
	walk_button.pressed.connect(level.request_journey)
	hint_button = button("Need a nudge?", Vector2.ZERO, Vector2(132, 34), game_group)
	hint_button.add_theme_font_size_override("font_size", 12)
	hint_button.pressed.connect(level.hint)
	label("T H R E E   L I G H T S   R E M E M B E R E D", 12, GOLD, ending_group).position = Vector2(64, 158)
	var end_title := label("A place between\npossibilities.", 46, IVORY, ending_group, true)
	end_title.position = Vector2(60, 204)
	end_title.add_theme_constant_override("line_spacing", 6)
	var end_copy := label("The observatory is whole again.\nNot because its distances changed,\nbut because you did.", 19, MUTED, ending_group)
	end_copy.position = Vector2(64, 342)
	end_copy.add_theme_constant_override("line_spacing", 8)
	replay_button = button("Walk again   ↺", Vector2(64, 465), Vector2(236, 54), ending_group, true)
	replay_button.pressed.connect(level.reset_level)
	label("THANK YOU FOR TAKING THE LONG WAY HOME", 11, GOLD, ending_group).position = Vector2(64, 549)
	mute_button = button("Sound on", Vector2.ZERO, Vector2(103, 35), self)
	mute_button.add_theme_font_size_override("font_size", 12)
	mute_button.pressed.connect(level.toggle_mute)
	reset_button = button("Restart", Vector2.ZERO, Vector2(84, 35), self)
	reset_button.add_theme_font_size_override("font_size", 12)
	reset_button.pressed.connect(level.reset_level)
	help_button = button("?", Vector2.ZERO, Vector2(35, 35), self)
	help_button.pressed.connect(func(): toggle_help(not help_open))
	build_help()
	resized.connect(layout)
	layout()
	refresh()

func group() -> Control:
	var result := Control.new()
	result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	return result

func label(text: String, size_: int, color: Color, parent: Node, serif := false) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font", display_font if serif else body_font)
	result.add_theme_font_size_override("font_size", size_)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_shadow_color", Color(0.01, 0.05, 0.07, 0.6))
	result.add_theme_constant_override("shadow_offset_x", 0)
	result.add_theme_constant_override("shadow_offset_y", 2)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	all_labels.append(result)
	return result

func style(fill: Color, outline: Color, border := 1) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = outline
	result.set_border_width_all(border)
	result.set_corner_radius_all(5)
	result.content_margin_left = 16
	result.content_margin_right = 16
	return result

func button(text: String, at: Vector2, size_: Vector2, parent: Node, primary := false) -> Button:
	var result := Button.new()
	result.text = text
	result.position = at
	result.size = size_
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_size_override("font_size", 16)
	result.add_theme_color_override("font_color", Color("132f38") if primary else IVORY)
	result.add_theme_color_override("font_hover_color", Color("102c35") if primary else Color.WHITE)
	result.add_theme_color_override("font_pressed_color", Color("132f38") if primary else GOLD)
	result.add_theme_color_override("font_disabled_color", Color("63847e"))
	result.add_theme_stylebox_override("normal", style(GOLD if primary else Color(0.02, 0.10, 0.13, 0.75), GOLD if primary else Color(0.75, 0.70, 0.52, 0.35)))
	result.add_theme_stylebox_override("hover", style(Color("f0d9a7") if primary else Color("244a4e"), IVORY))
	result.add_theme_stylebox_override("pressed", style(Color("bf9e65") if primary else Color("193d43"), GOLD))
	result.add_theme_stylebox_override("disabled", style(Color(0.02, 0.1, 0.13, 0.5), Color(0.5, 0.6, 0.55, 0.14)))
	result.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), Color("fff4d0"), 2))
	parent.add_child(result)
	result.pressed.connect(func(): result.release_focus())
	return result

func build_help() -> void:
	help_panel = Control.new()
	help_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(help_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.05, 0.07, 0.90)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	help_panel.add_child(shade)
	var center := Control.new()
	center.name = "HelpContent"
	center.position = Vector2(320, 185)
	help_panel.add_child(center)
	label("How to see differently", 35, IVORY, center, true).position = Vector2(0, 0)
	label("Turn the floating observatory until the two gold rings overlap.\nSeparate paths become one when they share a silhouette.", 18, MUTED, center).position = Vector2(0, 73)
	var controls := label("Q / E or ← / →     Turn a quarter-circle\nClick the light         Walk to the active celestial shrine\nSpace                     Walk when the edges meet\nH                             A gentle nudge\nR / M                      Restart / sound", 17, IVORY, center)
	controls.position = Vector2(0, 151)
	controls.add_theme_constant_override("line_spacing", 10)
	label("You can also drag left or right across the scene.\nThere is no timer, no falling, and no wrong way to look.", 15, MUTED, center).position = Vector2(0, 355)
	help_close = button("Return to the observatory", Vector2(0, 425), Vector2(290, 49), center, true)
	help_close.pressed.connect(func(): toggle_help(false))
	help_panel.visible = false

func toggle_help(open: bool) -> void:
	help_open = open
	help_panel.visible = open
	if open: help_close.grab_focus()
	else: help_close.release_focus()
	queue_redraw()

func layout() -> void:
	if not is_instance_valid(mute_button): return
	mute_button.position = Vector2(size.x - 286, 32)
	reset_button.position = Vector2(size.x - 174, 32)
	help_button.position = Vector2(size.x - 81, 32)
	previous_button.position = Vector2(size.x * 0.5 - 163, size.y - 94)
	next_button.position = Vector2(size.x * 0.5 + 109, size.y - 94)
	view_label.position = Vector2(size.x * 0.5 - 100, size.y - 78)
	view_label.size = Vector2(200, 24)
	walk_button.position = Vector2(size.x - 287, size.y - 94)
	hint_button.position = Vector2(48, size.y - 79)
	feedback_label.position = Vector2((size.x - 960) / 2.0, size.y - 149)
	var content := help_panel.get_node("HelpContent") as Control
	content.position = Vector2((size.x - 650) * 0.5, maxf(80.0, (size.y - 560) * 0.5))

func refresh() -> void:
	if not is_instance_valid(stage_label): return
	title_group.visible = level.mode == "title"
	game_group.visible = level.mode == "play"
	ending_group.visible = level.mode == "won"
	reset_button.visible = level.mode != "title"
	mute_button.text = "Sound off" if level.muted else "Sound on"
	if level.mode == "play":
		var current: int = mini(level.stage, 2)
		stage_label.text = "%s  /  %s" % [["I", "II", "III"][current], level.STAGE_NAMES[current]]
		subtitle_label.text = level.STAGE_NOTES[current]
		view_label.text = "%s  ·  %s / 4" % [level.VIEW_NAMES[level.view_index], str(level.view_index + 1)]
		previous_button.disabled = level.turning or level.walking
		next_button.disabled = level.turning or level.walking
		walk_button.disabled = not level.can_traverse()
		walk_button.text = "Following the light…" if level.walking else ("Walk the fold   →" if level.can_traverse() else "Join the gold rings")
		hint_button.disabled = level.walking or level.turning
		if level.walking:
			feedback_label.text = "A path made of perspective."
		elif level.can_traverse():
			feedback_label.text = "The edges meet. Touch the light, or press Space."
		elif not level.message.is_empty():
			feedback_label.text = level.message
		elif level.turning:
			feedback_label.text = ""
		else:
			feedback_label.text = "Q / E to turn    ·    Click the light to walk"
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(level.camera): return
	# Fine gallery framing, deliberately quieter than the architecture.
	var line_color := Color(0.78, 0.68, 0.44, 0.23)
	for corner in [Vector2(24, 24), Vector2(size.x - 24, 24), Vector2(24, size.y - 24), Vector2(size.x - 24, size.y - 24)]:
		var dx := 1.0 if corner.x < size.x / 2.0 else -1.0
		var dy := 1.0 if corner.y < size.y / 2.0 else -1.0
		draw_line(corner, corner + Vector2(dx * 30, 0), line_color, 1.0, true)
		draw_line(corner, corner + Vector2(0, dy * 30), line_color, 1.0, true)
	if level.mode == "title" or level.mode == "won":
		var emblem := Vector2(92, 88)
		draw_arc(emblem, 25, 0, TAU, 64, GOLD, 1.0, true)
		draw_arc(emblem, 19, 0, TAU, 64, line_color, 1.0, true)
		draw_line(emblem + Vector2(-35, 0), emblem + Vector2(35, 0), line_color, 1.0, true)
		draw_line(emblem + Vector2(0, -35), emblem + Vector2(0, 35), line_color, 1.0, true)
		var diamond := PackedVector2Array([emblem + Vector2(0, -13), emblem + Vector2(9, 0), emblem + Vector2(0, 13), emblem + Vector2(-9, 0)])
		draw_colored_polygon(diamond, GOLD)
		draw_line(Vector2(64, 613), Vector2(340, 613), line_color, 1.0, true)
		for i in 3:
			var at := Vector2(76 + i * 39, 645)
			draw_arc(at, 7, 0, TAU, 30, GOLD, 1.0, true)
			if level.mode == "won": draw_circle(at, 3, GOLD)
		return
	if level.mode != "play": return
	draw_line(Vector2(48, size.y - 115), Vector2(size.x - 48, size.y - 115), line_color, 1.0, true)
	for i in 3:
		var at := Vector2(55 + i * 30, 159)
		draw_arc(at, 6.0, 0.0, TAU, 24, GOLD if i <= level.stage else Color("486c6c"), 1.0, true)
		if i < level.stage: draw_circle(at, 3, GOLD)
		if i < 2: draw_line(at + Vector2(9, 0), at + Vector2(21, 0), line_color, 1.0, true)
	if level.stage > 2 or level.walking: return
	var active: Vector2 = level.active_goal_screen()
	var pulse := sin(level.elapsed * 2.6) * 0.5 + 0.5
	draw_arc(active, 22.0 + pulse * 3.0, 0, TAU, 48, Color(0.95, 0.80, 0.50, 0.5 + pulse * 0.3), 1.5, true)
	draw_arc(active, 29.0 + pulse * 4.0, -0.5, 1.1, 22, Color(0.95, 0.80, 0.50, 0.35), 1.0, true)
	var tag := ["SUN", "MOON", "HORIZON"][level.stage] as String
	draw_line(active + Vector2(0, -31), active + Vector2(0, -49), GOLD, 1.0, true)
	draw_string(body_font, active + Vector2(-body_font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x / 2.0, -58), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GOLD)
	if not level.turning:
		var a: Vector2 = level.camera.unproject_position(level.folds[level.stage].a + Vector3.UP * 0.04)
		var b: Vector2 = level.camera.unproject_position(level.folds[level.stage].b + Vector3.UP * 0.04)
		var color := Color(1, 0.85, 0.55, 0.8)
		for point: Vector2 in [a, b]:
			draw_arc(point, 13.0 + pulse * 2.0, 0, TAU, 36, color, 1.0, true)
		if level.can_traverse():
			for i in 4:
				var angle := PI / 4.0 + i * PI / 2.0
				var vector := Vector2(cos(angle), sin(angle))
				draw_line(a + vector * 20, a + vector * (25 + pulse * 4), GOLD, 1.2, true)
