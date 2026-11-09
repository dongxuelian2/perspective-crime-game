extends Node3D
## Independent district: real transform graph, carrier nodes, braces and solid architecture.
const Art = preload("res://scripts/chapter/paper_art.gd")
const Graph = preload("res://scripts/chapter/walkable_graph.gd")
const Mechanism = preload("res://scripts/chapter/spatial_mechanism.gd")
const Lift = preload("res://scripts/chapter/paper_lift.gd")
const Seam = preload("res://scripts/chapter/projection_seam.gd")
const Layouts = preload("res://scripts/chapter/chapter_layouts.gd")
var index := 0
var layout: Dictionary
var points: Dictionary = {}
var mechanisms: Array = []
var carriers: Dictionary = {}
var pins: Array = []
var gates: Array = []
var rings: Dictionary = {}
var graph = Graph.new()
var exit_id := "E"
var camera: Camera3D
var updating := false
var built := false
var cable: Array = []
func setup(number: int, view: Camera3D) -> void:
	index = number
	camera = view
	layout = Layouts.get_layout(index)
	points = layout.points.duplicate(true)
	exit_id = layout.exit
	camera.size = layout.size
	camera.position = layout.target + Vector3(12,16,22)
	camera.look_at(layout.target)
	for spec in layout.mechanisms:
		var m: Variant = Lift.new() if spec.kind == "lift" else Mechanism.new()
		add_child(m)
		var at: Vector3 = spec.get("at", points.get(spec.get("a", ""), Vector3.ZERO))
		m.a = spec.get("a", "")
		m.b = spec.get("b", "")
		m.carrier_id = spec.get("carrier", "")
		m.interactive = spec.get("interactive", true)
		if spec.kind == "lift": m.setup(at, spec.start, spec.get("span", 4.0))
		else: m.setup(spec.kind, at, spec.start, spec.get("span", 4.0))
		m.rotation.y = spec.get("yaw", 0.0)
		if not m.interactive: m.handle.hide()
		var mechanism_index := mechanisms.size()
		mechanisms.append(m)
		if not m.carrier_id.is_empty(): carriers[m.carrier_id] = mechanism_index
		m.changed.connect(func(): mechanism_changed(mechanism_index))
	for id in points:
		if not carriers.has(id): build_landing(id)
		var ring = Art.cylinder(self, .38, .018, points[id]+Vector3(0,.02,0), Art.GOLD)
		rings[id] = ring
	for edge in layout.fixed: street(points[edge[0]], points[edge[1]])
	for spec in layout.pins:
		var marker := Node3D.new()
		add_child(marker)
		marker.position = points[spec.at]+Vector3(.7,.1,.5)
		Art.cylinder(marker,.2,.12,Vector3.ZERO,Art.GOLD)
		Art.box(marker,Vector3(.12,.45,.12),Vector3(0,.25,0),Art.CORAL)
		pins.append({"at":spec.at,"locks":spec.locks,"marker":marker,"engaged":false})
	for spec in layout.gates:
		var gate := Node3D.new()
		add_child(gate)
		var incoming := Vector3.FORWARD
		for mechanism in mechanisms:
			if mechanism.b == spec.at: incoming = (points[spec.at]-points[mechanism.a]).normalized()
		gate.position = points[spec.at]-incoming*.6
		gate.rotation.y = atan2(incoming.x,incoming.z)
		for x in [-.65,.65]: Art.box(gate,Vector3(.09,1.7,.09),Vector3(x,.85,0),Art.GOLD,true)
		var bar = Art.box(gate,Vector3(1.2,.14,.14),Vector3(0,.65,0),Art.CORAL,true)
		gates.append({"at":spec.at,"requires":spec.requires,"value":spec.value,"bar":bar,"open":false})
	build_exit()
	decorate()
	if not layout.counterweight.is_empty():
		for i in range(3): cable.append(Art.box(self,Vector3(.025,.025,1),Vector3.ZERO,Art.GOLD))
	built = true
	rebuild()
func build_landing(id: String) -> void:
	var island := Node3D.new()
	add_child(island)
	island.position = points[id]
	Art.box(island,Vector3(1.5,.3,1.5),Vector3(0,-.15,0),Art.IVORY,true)
	# Narrow piers leave lower-level routes visible and physically unobstructed.
	Art.box(island,Vector3(.75,1.8,.3 if points[id].y > 1 else .75),Vector3(0,-1.2,-.7 if points[id].y > 1 else 0.0),Art.TEAL if index%2 else Art.IVORY,true)
	Art.box(island,Vector3(.95,.1,.4 if points[id].y > 1 else .95),Vector3(0,-2.15,-.7 if points[id].y > 1 else 0.0),Art.GOLD,true)
	for x in [-.58,.58]: Art.box(island,Vector3(.08,.22,.08),Vector3(x,.11,-.6),Art.GOLD)
func build_exit() -> void:
	var exit := Node3D.new()
	add_child(exit)
	exit.position = points[exit_id]
	if index == Layouts.count()-1:
		Art.box(exit,Vector3(.65,.8,.4),Vector3(0,.4,-.45),Art.CORAL,true)
		Art.box(exit,Vector3(.42,.06,.02),Vector3(0,.65,-.23),Art.DEEP)
		Art.box(exit,Vector3(.32,.18,.02),Vector3(0,.38,-.23),Art.IVORY)
	else:
		for x in [-.6,.6]: Art.box(exit,Vector3(.12,1.5,.12),Vector3(x,.75,-.4),Art.GOLD,true)
		Art.box(exit,Vector3(1.32,.14,.14),Vector3(0,1.5,-.4),Art.GOLD,true)
		Art.box(exit,Vector3(.4,.25,.025),Vector3(0,1.2,-.4),Art.IVORY)
func mechanism_changed(source: int) -> void:
	if updating: return
	updating = true
	for group in layout.groups:
		if group.has(source):
			for other in group:
				if other != source and not mechanisms[other].locked:
					var linked: float = mechanisms[source].value-layout.offsets.get(source,0.0)+layout.offsets.get(other,0.0)
					if linked > PI: linked -= TAU
					if linked < -PI: linked += TAU
					mechanisms[other].value = linked
					mechanisms[other].apply()
	if not layout.counterweight.is_empty():
		var driver = mechanisms[layout.counterweight[0]]
		var lift = mechanisms[layout.counterweight[1]]
		lift.value = (3.5-driver.value)/7.0 * PI/2
		lift.apply()
	updating = false
	if built: rebuild()
func toggle_pin(pin_index: int, actor_id: String) -> bool:
	if pin_index < 0 or pin_index >= pins.size() or pins[pin_index].at != actor_id: return false
	var pin: Dictionary = pins[pin_index]
	pin.engaged = not pin.engaged
	mechanisms[pin.locks].locked = pin.engaged
	pin.marker.rotation.z = PI/2 if pin.engaged else 0.0
	return true
func street(a: Vector3, b: Vector3) -> void:
	var strip = Art.box(self,Vector3(.85,.16,a.distance_to(b)),(a+b)/2-Vector3(0,.08,0),Art.IVORY,true)
	strip.look_at(b-Vector3(0,.08,0))
	for i in range(1,9): Art.cylinder(self,.035,.015,a.lerp(b,i/9.0)+Vector3(0,.015,0),Art.GOLD)
func rebuild() -> void:
	if not built: return
	for id in carriers: points[id] = mechanisms[carriers[id]].endpoint()
	for i in range(mechanisms.size()):
		var spec: Dictionary = layout.mechanisms[i]
		if spec.has("follows"): mechanisms[i].position = points[spec.follows]
	for id in rings: rings[id].position = points[id]+Vector3(0,.025,0)
	for gate in gates:
		gate.open = absf(mechanisms[gate.requires].value-gate.value) < .12
		gate.bar.position.y = 1.7 if gate.open else .65
	graph = Graph.new()
	for id in points: graph.add_point(id,points[id])
	for edge in layout.fixed: graph.connect_points(edge[0],edge[1])
	for i in range(mechanisms.size()):
		var m = mechanisms[i]
		var spec: Dictionary = layout.mechanisms[i]
		if m.kind == "hinge":
			var allowed := true
			for gate in gates:
				if gate.at == m.b and not gate.open: allowed = false
			if allowed and m.endpoint().distance_to(points[m.b]) < .22: graph.connect_points(m.a,m.b)
		elif m.kind == "lift":
			if absf(m.value) < .04: graph.connect_points(m.a,m.carrier_id)
			for dock in spec.get("docks",[]):
				if points[dock].distance_to(m.endpoint()) < 1.05 and absf(points[dock].y-m.endpoint().y) < .04: graph.connect_points(m.carrier_id,dock)
		elif m.kind == "shuttle":
			for dock in spec.docks:
				if points[dock].distance_to(m.endpoint()) < 1.55: graph.connect_points(m.carrier_id,dock)
	for seam in layout.seams:
		if Seam.aligned(camera,points[seam[0]],points[seam[1]]): graph.connect_points(seam[0],seam[1])
	update_cable()
func is_seam(a: String, b: String) -> bool:
	for seam in layout.seams:
		if (a == seam[0] and b == seam[1]) or (b == seam[0] and a == seam[1]): return true
	return false
func carrier_for(id: String):
	return mechanisms[carriers[id]] if carriers.has(id) else null
func update_cable() -> void:
	if cable.is_empty(): return
	var a: Vector3 = mechanisms[0].endpoint()+Vector3(0,.4,0)
	var d: Vector3 = mechanisms[1].endpoint()+Vector3(0,.4,0)
	var p := [a,Vector3(a.x,6,a.z),Vector3(5,6,1),d]
	for i in range(3):
		cable[i].position = (p[i]+p[i+1])/2
		cable[i].scale.z = p[i].distance_to(p[i+1])
		var direction: Vector3 = (p[i+1]-p[i]).normalized()
		cable[i].look_at(p[i+1],Vector3.FORWARD if absf(direction.dot(Vector3.UP)) > .95 else Vector3.UP)
func update_reachable(actor_id: String,time: float) -> void:
	for id in rings:
		var reachable: bool = not graph.route(actor_id,id).is_empty()
		var color: Color = Art.GOLD if reachable else Art.TEAL.darkened(.35)
		if id == actor_id: color = Art.CORAL
		rings[id].material_override.albedo_color = color.darkened(.15)
		rings[id].scale = Vector3.ONE*(1+.05*sin(time*3) if reachable and id != actor_id else 1)
func decorate() -> void:
	# Each district has a different silhouette, not a ring of copied islands.
	for i in range(9):
		var p := Vector3(-8+(i%3)*7,-3.0-(i%2),-7+(i/3)*7)
		if index == 1: p = Vector3(-8 if i%2 else 8,-2,-6+i*1.4)
		elif index == 3: p = Vector3(-7+(i%3)*6,-2,-6+(i/3)*5)
		var tower := Node3D.new()
		add_child(tower)
		tower.position = p
		var h := 1.2+(i%3)*.7
		Art.box(tower,Vector3(.9,h,.9),Vector3(0,-h/2,0),Art.TEAL if i%2 else Art.IVORY,true)
		var roof = Art.box(tower,Vector3(.65,.65,.65),Vector3.ZERO,Art.GOLD,true)
		roof.rotation.z = PI/4
		for y in range(3): Art.box(tower,Vector3(.2,.23,.02),Vector3(0,-.4-y*.45,.46),Art.GOLD)
	if index == 3:
		for i in range(7): Art.box(self,Vector3(1.6,.18,.85),Vector3(-6,-.5-i*.24,-2),Art.IVORY if i%2 else Art.TEAL,true)
