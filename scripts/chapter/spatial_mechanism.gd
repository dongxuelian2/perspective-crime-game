extends Node3D
## Rotating rigid street or sliding facade. No motion is allowed while traversed.
signal changed
const Art = preload("res://scripts/chapter/paper_art.gd")
var kind := "hinge"
var interactive := true
var carrier_id := ""
var value := 0.0
var initial := 0.0
var locked := false
var busy := false
var span := 4.0
var part: Node3D
var handle: Node3D
var a := ""
var b := ""
var axis := Vector3.RIGHT
func setup(type: String, at: Vector3, start: float, length: float = 4.0) -> void:
	kind = type
	position = at
	initial = start
	value = start
	span = length
	part = Node3D.new()
	add_child(part)
	if kind == "hinge":
		Art.box(part, Vector3(span, .18, .9), Vector3(span / 2, -.09, 0), Art.TEAL, true)
		for i in range(1, int(span * 3)):
			Art.box(part, Vector3(.025, .015, .86), Vector3(i / 3.0, .01, 0), Art.GOLD)
		Art.cylinder(self, .26, .28, Vector3.ZERO, Art.GOLD)
	else:
		Art.box(part, Vector3(2.2, .2, 1.4), Vector3(0, -.1, 0), Art.TEAL, true)
		Art.box(self, Vector3(9.0 if kind == "shuttle" else 5.8, .08, .12), Vector3(0, -.4, 0), Art.GOLD)
		if kind == "shuttle":
			for x in [-.65,.65]:
				for layer in range(3):
					Art.box(part,Vector3(.4,.045,.3),Vector3(x,.035+layer*.05,-.45),Art.IVORY,true)
				Art.box(part,Vector3(.05,.02,.32),Vector3(x,.17,-.45),Art.GOLD)
		# Broken arch: the two moving piers visibly frame the impossible seam.
		for z in ([-.65, .65] if kind == "slide" else []):
			Art.box(part, Vector3(.18, 2.2, .18), Vector3(0, 1.0, z), Art.IVORY, true)
		if kind == "slide": Art.box(part, Vector3(.2, .18, 1.5), Vector3(0, 2.05, 0), Art.GOLD, true)
	handle = Node3D.new()
	part.add_child(handle)
	handle.position = Vector3(span * .6 if kind == "hinge" else 0.0, .28, 0)
	Art.cylinder(handle, .3, .12, Vector3.ZERO, Art.GOLD)
	Art.box(handle, Vector3(.12, .06, .4), Vector3(0, .1, 0), Art.DEEP)
	apply()
func apply() -> void:
	if kind == "hinge": part.rotation.y = value
	else: part.position = axis * value
	changed.emit()
func adjust(delta: float) -> void:
	if locked or busy: return
	value = clampf(value + delta, -PI, PI) if kind == "hinge" else clampf(value + delta, -3.5 if kind == "shuttle" else -2.7, 3.5 if kind == "shuttle" else 2.7)
	apply()
func settle() -> void:
	if kind == "hinge": value = snappedf(value, PI / 2.0)
	else: value = snappedf(value, .25)
	apply()
func endpoint() -> Vector3:
	return part.to_global(Vector3(span, 0, 0)) if kind == "hinge" else part.global_position
