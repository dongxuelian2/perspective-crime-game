extends Control
signal dismissed
var ending := false
var picture: TextureRect
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("102b38")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 50
	column.offset_right = -50
	column.offset_top = 45
	column.offset_bottom = -40
	column.add_theme_constant_override("separation", 24)
	add_child(column)
	var title := Label.new()
	title.text = "A LETTER TO NOWHERE" if not ending else "✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	picture = TextureRect.new()
	picture.texture = load("res://assets/chapter_ending.png" if ending else "res://assets/chapter_opening.png")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(picture)
	var next := Button.new()
	next.text = "↻   Replay" if ending else "▷   Enter the city"
	next.custom_minimum_size = Vector2(180, 48)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.pressed.connect(func(): dismissed.emit())
	column.add_child(next)
