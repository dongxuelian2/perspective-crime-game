extends RefCounted
const IVORY := Color("ede2c5")
const TEAL := Color("327f80")
const DEEP := Color("193e4c")
const GOLD := Color("e5b96c")
const CORAL := Color("cf7764")
static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color.darkened(.23)
	m.metallic_specular = .15
	m.roughness = .85
	return m
static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	parent.add_child(n)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		n.add_child(body)
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
	return n
static func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	n.mesh = mesh
	n.material_override = material(color)
	n.position = pos
	parent.add_child(n)
	return n
static func messenger(parent: Node3D) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var cloak := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = .13
	cone.bottom_radius = .3
	cone.height = .65
	cloak.mesh = cone
	cloak.material_override = material(CORAL)
	cloak.position.y = .47
	n.add_child(cloak)
	cylinder(n, .17, .22, Vector3(0, .9, 0), IVORY)
	cylinder(n, .3, .08, Vector3(0, 1.04, 0), DEEP)
	box(n, Vector3(.37, .24, .08), Vector3(0, .55, .22), IVORY)
	box(n, Vector3(.08, .08, .025), Vector3(0, .55, .27), GOLD)
	for x in [-.12, .12]: box(n, Vector3(.12, .15, .2), Vector3(x, .09, 0), DEEP)
	return n
