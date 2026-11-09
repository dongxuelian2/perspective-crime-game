extends CharacterBody3D
## Foot-origin collision controller. Only explicit projection transfers teleport.
signal waypoint_reached(index: int)
signal finished(success: bool)
const Art = preload("res://scripts/chapter/paper_art.gd")
const Seam = preload("res://scripts/chapter/projection_seam.gd")
const SPEED := 3.1
const ACCELERATION := 16.0
const ARRIVAL_RADIUS := 0.075
const BLOCKED_TIMEOUT := 1.2
var visual: Node3D
var active := false
var carried := false
var failure_reason := ""
var _points: Array[Vector3] = []
var _index := 0
var _stalled := 0.0
var _elapsed := 0.0
var _deadline := 0.0
var _best_distance := INF
var _generation := 0
var _capsule: CapsuleShape3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.22
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(46)
	safe_margin = 0.005
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.18
	_capsule.height = 0.9
	var shape := CollisionShape3D.new()
	shape.shape = _capsule
	shape.position.y = 0.48
	add_child(shape)
	visual = Art.messenger(self)

func start_route(waypoints: Array) -> bool:
	cancel()
	failure_reason = ""
	for point in waypoints:
		if not point is Vector3 or not point.is_finite():
			failure_reason = "invalid_waypoint"
			_points.clear()
			return false
		_points.append(point)
	if _points.is_empty(): return false
	active = true
	_index = 0
	_begin_segment()
	return true

func cancel() -> void:
	_generation += 1
	active = false
	velocity = Vector3.ZERO
	_points.clear()

func _begin_segment() -> void:
	_best_distance = global_position.distance_to(_points[_index])
	_stalled = 0.0
	_elapsed = 0.0
	_deadline = maxf(3.0, _best_distance / SPEED * 3.0 + 2.0)

func _finish(success: bool, reason := "") -> void:
	failure_reason = reason
	active = false
	velocity = Vector3.ZERO
	_points.clear()
	finished.emit(success)

func _physics_process(delta: float) -> void:
	# A stationary moving-platform rider is positioned by its mechanism owner.
	if not active:
		if carried: return
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y = -0.1 if is_on_floor() else velocity.y - 20.0 * delta
		move_and_slide()
		return
	var target := _points[_index]
	var offset := target - global_position
	var flat := Vector3(offset.x, 0, offset.z)
	var desired := flat.normalized() * minf(SPEED, flat.length() / maxf(delta, 0.001))
	velocity.x = move_toward(velocity.x, desired.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, desired.z, ACCELERATION * delta)
	if is_on_floor(): velocity.y = -0.1
	else: velocity.y -= 20.0 * delta
	move_and_slide()
	offset = target - global_position
	flat = Vector3(offset.x, 0, offset.z)
	if flat.length() <= ARRIVAL_RADIUS and absf(offset.y) < 0.20 and is_on_floor():
		var reached := _index
		var generation := _generation
		_index += 1
		velocity = Vector3.ZERO
		waypoint_reached.emit(reached)
		if not active or generation != _generation: return
		if _index >= _points.size(): _finish(true)
		else: _begin_segment()
		return
	_elapsed += delta
	var distance := offset.length()
	if distance < _best_distance - 0.025:
		_best_distance = distance
		_stalled = 0.0
	else: _stalled += delta
	if _stalled >= BLOCKED_TIMEOUT: _finish(false, "blocked")
	elif _elapsed >= _deadline: _finish(false, "timeout")

func transfer_projection_seam(target: Vector3, camera: Camera3D) -> bool:
	# Authored topology only: caller fades out/in around this operation. Never
	# interpolate through a solid wall or use this as a fallback for blocked walks.
	if active or not target.is_finite() or not is_instance_valid(camera): return false
	if not Seam.aligned(camera, global_position, target): return false
	if not can_occupy(target): return false
	var space := get_world_3d().direct_space_state
	var support := PhysicsRayQueryParameters3D.create(target + Vector3.UP * 0.12, target - Vector3.UP * 0.22, 1, [get_rid()])
	var hit := space.intersect_ray(support)
	if hit.is_empty() or hit.normal.dot(Vector3.UP) < cos(floor_max_angle): return false
	global_position = target
	velocity = Vector3.ZERO
	return true

func can_occupy(foot_position: Vector3) -> bool:
	if not foot_position.is_finite() or _capsule == null: return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _capsule
	query.transform = Transform3D(Basis.IDENTITY, foot_position + Vector3(0, 0.48, 0))
	query.collision_mask = 1
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
