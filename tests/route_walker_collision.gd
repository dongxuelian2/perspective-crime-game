extends SceneTree
## godot --headless --path . --script tests/route_walker_collision.gd
const Walker = preload("res://scripts/chapter/route_walker.gd")
var walker
var results: Array = []
var reached: Array = []
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label_text: String) -> void:
	print(("PASS " if value else "FAIL ") + label_text)
	if not value: failures += 1
func solid(size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	root.add_child(body)
	body.position = at
	return body
func ticks(count: int) -> void:
	for i in count: await physics_frame
func wait_route() -> void:
	for i in 1200:
		await physics_frame
		if not walker.active: return
	check(false, "route finishes within bounded time")
func run() -> void:
	Engine.physics_ticks_per_second = 120
	Engine.time_scale = 4.0
	solid(Vector3(20, 1, 20), Vector3(0, -0.5, 0))
	walker = Walker.new()
	root.add_child(walker)
	walker.finished.connect(func(success): results.append(success))
	walker.waypoint_reached.connect(func(index): reached.append(index))
	await ticks(3)
	check(walker.collision_layer == 2 and walker.collision_mask == 1, "dedicated actor layer and world collision mask")
	check(walker.start_route([Vector3(2,0,0), Vector3(3,0,0)]), "accepts two ordinary waypoints")
	await wait_route()
	check(results == [true] and reached == [0,1], "supported route reaches each waypoint and succeeds")
	check(absf(walker.position.y) < 0.08, "gravity and floor snap preserve foot-origin height")
	var wall := solid(Vector3(0.3, 3, 5), Vector3(4, 1, 0))
	await ticks(3)
	check(not walker.can_occupy(Vector3(4,0,0)), "occupancy query rejects solid wall")
	check(walker.can_occupy(Vector3(2,0,0)), "occupancy query accepts clear supported landing")
	results.clear()
	reached.clear()
	walker.start_route([Vector3(6,0,0)])
	await wait_route()
	check(walker.position.x < 3.70, "solid wall stops capsule before wall face")
	check(results == [false] and reached.is_empty() and walker.failure_reason == "blocked", "blocked route reports failure without claiming waypoint")
	var stopped: Vector3 = walker.position
	await ticks(60)
	check(walker.position.distance_to(stopped) < 0.001 and walker.velocity == Vector3.ZERO, "failed route remains stopped")
	wall.queue_free()
	await ticks(3)
	results.clear()
	walker.start_route([Vector3(-4,0,0)])
	await ticks(10)
	walker.cancel()
	stopped = walker.position
	await ticks(60)
	check(walker.position == stopped and not walker.active and results.is_empty(), "cancel stops safely without stale completion")
	check(not walker.start_route(["bad"]), "malformed route rejected")
	walker.carried = true
	walker.position = Vector3(0, 4, 0)
	await ticks(10)
	check(walker.position == Vector3(0,4,0), "stationary carrier owns position without gravity drift")
	walker.carried = false
	await ticks(10)
	check(walker.position.y < 4, "ordinary idle walker responds to gravity")
	walker.carried = true
	walker.position = Vector3.ZERO
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0,8,12)
	camera.look_at(Vector3.ZERO)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12
	camera.current = true
	var landing := camera.position.normalized() * 3.0
	check(not walker.transfer_projection_seam(landing, camera), "aligned seam cannot transfer to unsupported air")
	solid(Vector3(1.4,0.2,1.4), landing - Vector3.UP * 0.1)
	await ticks(3)
	check(not walker.transfer_projection_seam(landing + Vector3.RIGHT * 2, camera), "unaligned seam refuses transfer")
	check(walker.transfer_projection_seam(landing, camera) and walker.position == landing, "explicit aligned portal reaches clear supported landing")
	check(walker.collision_mask == 1, "portal preserves world collision mask")
	print("Collision test failures: ", failures)
	quit(0 if failures == 0 else 1)
