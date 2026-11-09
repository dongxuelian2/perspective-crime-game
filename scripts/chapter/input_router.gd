extends Node
## Pointer capture: UI consumes its events before this router sees them.
signal tapped(position: Vector2)
signal drag_started(position: Vector2)
signal dragged(delta: Vector2)
signal drag_finished
var down := false
var dragging := false
var origin := Vector2.ZERO
var last := Vector2.ZERO
const THRESHOLD := 9.0
func cancel() -> void:
	down = false
	dragging = false
func pointer(pressed: bool, p: Vector2) -> void:
	if pressed:
		down = true
		dragging = false
		origin = p
		last = p
	elif down:
		down = false
		if dragging: drag_finished.emit()
		else: tapped.emit(p)
		dragging = false
func motion(p: Vector2) -> void:
	if not down: return
	if not dragging and origin.distance_to(p) >= THRESHOLD:
		dragging = true
		last = origin
		drag_started.emit(origin)
	if dragging: dragged.emit(p - last)
	last = p
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT: pointer(event.pressed, event.position)
	elif event is InputEventMouseMotion: motion(event.position)
	elif event is InputEventScreenTouch and event.index == 0: pointer(event.pressed, event.position)
	elif event is InputEventScreenDrag and event.index == 0: motion(event.position)
