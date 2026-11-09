extends Node3D
## A rigid paper street folds up while its end carriage remains level.
## The flow owns occupancy: busy means walking, not a rider standing aboard.
signal changed
const Art = preload("res://scripts/chapter/paper_art.gd")
var kind := "lift"
var interactive := true
var carrier_id := ""
var value := 0.0
var initial := 0.0
var locked := false
var busy := false
var span := 4.0
var part: Node3D
var carrier: Node3D
var handle: Node3D
var a := ""
var b := ""
var axis := Vector3.UP

func setup(at: Vector3, start: float, length: float = 4.0) -> void:
	position = at
	span = maxf(length, .5)
	initial = clampf(start, 0.0, PI / 2.0)
	value = initial
	part = Node3D.new()
	part.name = "FoldedStreet"
	add_child(part)
	# Continuous top surface, thin cream edges and embossed brass crease lines.
	Art.box(part, Vector3(span, .16, .82), Vector3(span / 2.0, -.08, 0), Art.TEAL, true)
	for z in [-.43, .43]:
		Art.box(part, Vector3(span, .12, .055), Vector3(span / 2.0, -.10, z), Art.IVORY)
	for i in range(1, int(span * 3.0)):
		Art.box(part, Vector3(.025, .015, .80), Vector3(i / 3.0, -.012, 0), Art.GOLD)
	# A folded underside reads as paper construction, not a mechanical piston.
	for i in range(1, int(span * 2.0)):
		var rib := Art.box(part, Vector3(.32, .045, .65), Vector3(i / 2.0, -.23, 0), Art.IVORY)
		rib.rotation.z = .35 if i % 2 == 0 else -.35
	Art.box(self, Vector3(.7, .20, 1.12), Vector3(0, -.10, 0), Art.IVORY, true)
	for z in [-.51, .51]:
		var pivot := Art.cylinder(self, .22, .12, Vector3(0, -.08, z), Art.GOLD)
		pivot.rotation.x = PI / 2.0
		var pin := Art.cylinder(self, .075, .14, Vector3(0, -.08, z), Art.DEEP)
		pin.rotation.x = PI / 2.0
	carrier = Node3D.new()
	carrier.name = "LevelCarriage"
	part.add_child(carrier)
	carrier.position = Vector3(span, 0, 0)
	Art.box(carrier, Vector3(1.12, .20, 1.22), Vector3(0, -.10, 0), Art.IVORY, true)
	Art.box(carrier, Vector3(.94, .025, 1.02), Vector3(0, -.0125, 0), Art.TEAL)
	# Rear rail leaves both boarding edges open and does not mask the rider.
	for x in [-.46, .46]:
		Art.box(carrier, Vector3(.055, .48, .055), Vector3(x, .23, -.56), Art.GOLD, true)
	Art.box(carrier, Vector3(1.0, .055, .055), Vector3(0, .47, -.56), Art.GOLD, true)
	for x in [-.44, .44]:
		Art.box(carrier, Vector3(.035, .018, 1.0), Vector3(x, .013, 0), Art.GOLD)
	# The brass wheel rides the carriage, remaining visible at either dock.
	handle = Node3D.new()
	handle.name = "BrassHandle"
	carrier.add_child(handle)
	handle.position = Vector3(.10, .36, .63)
	Art.box(handle, Vector3(.065, .40, .065), Vector3(0, -.19, 0), Art.DEEP)
	var wheel := Art.cylinder(handle, .24, .10, Vector3.ZERO, Art.GOLD)
	wheel.rotation.x = PI / 2.0
	var hub := Art.cylinder(handle, .08, .12, Vector3.ZERO, Art.TEAL)
	hub.rotation.x = PI / 2.0
	Art.box(handle, Vector3(.30, .045, .025), Vector3(0, 0, .07), Art.IVORY)
	apply()

func apply() -> void:
	value = clampf(value, 0.0, PI / 2.0)
	if not is_instance_valid(part): return
	part.rotation.z = value
	carrier.rotation.z = -value
	changed.emit()

func adjust(delta: float) -> void:
	if locked or busy: return
	value = clampf(value + delta, 0.0, PI / 2.0)
	apply()

func settle() -> void:
	if locked or busy: return
	value = clampf(snappedf(value, PI / 2.0), 0.0, PI / 2.0)
	apply()

func endpoint() -> Vector3:
	return carrier.global_position if is_instance_valid(carrier) else to_global(Vector3(cos(value) * span, sin(value) * span, 0))
