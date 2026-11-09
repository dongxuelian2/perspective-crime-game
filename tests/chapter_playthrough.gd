extends SceneTree
## Physics regression: --headless --fixed-fps 60 --script tests/chapter_playthrough.gd -- --no-save
## Normal timescale; no actor teleportation or direct mechanism-state assignments.
const Scene = preload("res://scenes/chapter.tscn")
const Router = preload("res://scripts/chapter/input_router.gd")
const Art = preload("res://scripts/chapter/paper_art.gd")
const Layouts = preload("res://scripts/chapter/chapter_layouts.gd")
var level
var checks := 0
var failures := 0
var events: Array = []
var drag_deltas: Array[Vector2] = []
func check(ok: bool, label_text: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label_text)
func frames(count: int) -> void:
	for i in count: await physics_frame
func finish() -> void:
	print("CHAPTER TEST RESULTS: %d checks, %d failures" % [checks, failures])
	level.audio.stop()
	level.queue_free()
	# Fixed-fps simulation can finish before the audio thread releases playback.
	await process_frame
	OS.delay_msec(250)
	await create_timer(.2,true,false,true).timeout
	quit(1 if failures else 0)
func turn(index: int, target: float) -> void:
	var m = level.district.mechanisms[index]
	level.adjust_mechanism(m,target-m.value)
	await frames(3)
	check(absf(m.value-target) < .001, "district %d mechanism %d reaches %.2f safely (actual %.2f)" % [level.checkpoint,index,target,m.value])
	if absf(m.value-target) > .001 and m.kind == "lift":
		var foot: Vector3 = m.to_global(Vector3(cos(m.value+.025)*m.span,sin(m.value+.025)*m.span,0))
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = level.actor._capsule
		q.transform = Transform3D(Basis.IDENTITY,foot+Vector3(0,.48,0))
		q.collision_mask = 1
		q.exclude = [level.actor.get_rid()]
		for hit in level.actor.get_world_3d().direct_space_state.intersect_shape(q,10):
			print("LIFT_BLOCKER ",hit.collider.get_path()," at ",hit.collider.global_position," parent ",hit.collider.get_parent().global_position)
	if level.district.carriers.has(level.actor_id):
		check(level.actor.position.distance_to(level.district.points[level.actor_id]) < .01, "carrier rider follows real mechanism endpoint")
	check(level.actor.can_occupy(level.actor.position), "mechanism leaves actor outside solids")
func walk(id: String) -> bool:
	var district_index: int = level.checkpoint
	var goal: Vector3 = level.district.points[id]
	var exiting: bool = id == level.district.exit_id
	check(level.walk_to(id), "district %d starts route to %s" % [district_index,id])
	for i in 1800:
		if not level.walking and not level.mode in ["transition","delivery"]: break
		await physics_frame
	var arrived: bool = (level.checkpoint == district_index+1 or level.mode == "comic") if exiting else level.actor_id == id and level.actor.position.distance_to(goal) < .21
	check(arrived, "district %d physically arrives at %s (actor %s; %s)" % [district_index,id,level.actor_id,level.actor.failure_reason])
	if not arrived:
		print("BLOCKED position=",level.actor.position," goal=",goal)
		for i in level.actor.get_slide_collision_count():
			var hit = level.actor.get_slide_collision(i)
			print("WALK_BLOCKER ",hit.get_collider().get_path()," at ",hit.get_collider().global_position," normal ",hit.get_normal())
		await finish()
	return arrived
func pin(index: int) -> void:
	check(level.district.toggle_pin(index,level.actor_id), "pin %d can engage at its landing" % index)
	var locked = level.district.mechanisms[level.district.pins[index].locks]
	var previous: float = locked.value
	check(not level.adjust_mechanism(locked,.3) and is_equal_approx(previous,locked.value), "pin rejects further manipulation of locked arm")
func dismiss() -> void:
	for child in level.layer.get_children():
		if child.has_signal("dismissed"): child.dismissed.emit()
	await frames(3)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if not "--no-save" in OS.get_cmdline_user_args(): quit(2); return
	root.size = Vector2i(1280,800)
	Engine.time_scale = 1.0
	var router = Router.new()
	root.add_child(router)
	router.tapped.connect(func(_p): events.append("tap"))
	router.drag_started.connect(func(_p): events.append("start"))
	router.dragged.connect(func(delta): events.append("drag"); drag_deltas.append(delta))
	router.drag_finished.connect(func(): events.append("finish"))
	router.pointer(true,Vector2.ZERO)
	router.motion(Vector2(8,0))
	router.pointer(false,Vector2(8,0))
	check(events == ["tap"],"below-threshold motion remains a tap")
	events.clear()
	router.pointer(true,Vector2.ZERO)
	router.motion(Vector2(8,0))
	router.motion(Vector2(9,0))
	router.pointer(false,Vector2(9,0))
	check(events == ["start","drag","finish"],"threshold drag emits no tap")
	check(drag_deltas == [Vector2(9,0)],"crossing drag threshold preserves full press displacement")
	events.clear()
	router.pointer(true,Vector2.ZERO)
	router.cancel()
	router.pointer(false,Vector2.ZERO)
	check(events.is_empty(),"cancelled press cannot become a tap")
	router.queue_free()
	level = Scene.instantiate()
	root.add_child(level)
	await frames(8)
	check(level.no_save and level.actor is CharacterBody3D,"no-save scene uses real character collision controller")
	check(level.mode == "comic" and not level.walk_to("B"),"opening comic gates walking")
	await dismiss()
	check(Layouts.count() == 5,"chapter contains five distinct district layouts")
	var start := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--district="): start = clampi(int(arg.trim_prefix("--district=")),0,4)
	if start == 0:
		# Collision must defeat a graph-valid route, without assigning actor transforms.
		await turn(0,0)
		var grip: Vector2 = level.camera.unproject_position(level.district.mechanisms[0].handle.global_position)
		level.router.pointer(true,grip)
		var drag_delta: Vector2 = level.mechanism_tangent(level.district.mechanisms[0])*.24
		level.router.motion(grip+drag_delta)
		check(level.active_mechanism == level.district.mechanisms[0],"projected tangent gesture captures intended grip")
		check(absf(level.district.mechanisms[0].value-.24) < .01,"projected tangent drag maps to intended angular motion")
		level.router.pointer(false,grip+drag_delta)
		check(level.settling,"release starts validated animated snap")
		level.tap(level.camera.unproject_position(level.district.points.B))
		check(not level.walking and not level.walk_to("B"),"immediate click and route request blocked while snapping")
		await frames(30)
		check(not level.settling and absf(level.district.mechanisms[0].value) < .001,"snap reaches aligned geometry on physics frames")
		if not await walk("B"): return
		level.restart()
		await frames(5)
		await turn(0,0)
		var wall = Art.box(level,Vector3(.3,2,2),Vector3(-4,1,3),Art.CORAL,true)
		await frames(3)
		check(level.walk_to("B"),"collision probe starts graph-valid route")
		await frames(240)
		check(not level.walking and level.actor.failure_reason == "blocked" and level.actor.position.x < -4.2,"solid wall physically stops character and times out safely")
		wall.queue_free()
		level.restart()
		await frames(5)
		check(level.actor_id == "A" and level.actor.position.distance_to(level.district.points.A) < .1,"restart restores safe grounded entry")
		await turn(0,0)
		check(level.walk_to("B"),"interrupt probe starts traversal")
		await frames(10)
		check(not level.adjust_mechanism(level.district.mechanisms[0],.4),"moving character locks mechanisms")
		level.restart()
		await frames(180)
		check(level.actor_id == "A" and not level.walking and level.actor.position.distance_to(level.district.points.A) < .1,"reset cancels old route without stale callbacks")
	else:
		level.load_district(start)
		await frames(8)
	for district_index in range(start,5):
		check(level.checkpoint == district_index,"forward progression reaches district %d" % district_index)
		check(level.district.graph.route("A",level.district.exit_id).is_empty(),"district %d cannot auto-solve from initial topology" % district_index)
		check(not level.walk_to(level.district.exit_id),"district %d rejects disconnected exit" % district_index)
		match district_index:
			0:
				await turn(0,0)
				if not await walk("B"): return
				level.adjust_mechanism(level.district.mechanisms[1],PI/2)
				check(level.district.mechanisms[1].value < PI/2-.1,"non-rider at pivot blocks rising solid arm")
				await turn(1,0)
				if not await walk("R"): return
				await turn(1,PI/2)
				check(level.actor.position.y > 3.9,"lift carries rider to upper storey")
				if not await walk("C"): return
				await turn(2,PI/2)
				if not await walk("E"): return
			1:
				if not await walk("R"): return
				await turn(0,3.5)
				check(absf(level.district.mechanisms[1].value) < .001,"shuttle counterweight lowers distant lift")
				if not await walk("S"): return
				await turn(0,-3.5)
				check(absf(level.district.mechanisms[1].value-PI/2) < .001,"returning empty shuttle lifts boarded counterweight")
				if not await walk("D"): return
				await turn(2,PI/2)
				if not await walk("F"): return
			2:
				await turn(0,0)
				if not await walk("C"): return
				await turn(1,0)
				check_projection("C","D")
				if not await walk("D"): return
				await turn(2,0)
				if not await walk("R"): return
				await turn(3,PI/2)
				if not await walk("F"): return
			3:
				await turn(0,0)
				if not await walk("B"): return
				await turn(1,PI/2)
				check(level.district.graph.route("B","C").is_empty(),"archive gate prevents solving without first pin")
				await turn(0,0)
				pin(0)
				await turn(1,PI/2)
				if not await walk("C"): return
				pin(1)
				await turn(2,0)
				if not await walk("E"): return
			4:
				await turn(0,0)
				if not await walk("R"): return
				await turn(1,PI/2)
				if not await walk("C"): return
				pin(0)
				await turn(2,PI/2)
				if not await walk("D"): return
				await turn(3,0)
				check_projection("D","S")
				if not await walk("S"): return
				await turn(4,0)
				if not await walk("E"): return
	check(level.mode == "comic","final physical delivery opens ending")
	await dismiss()
	check(level.mode == "play" and level.checkpoint == 0 and level.actor_id == "A","replay resets full five-district chapter")
	await finish()
func check_projection(a: String,b: String) -> void:
	var gap: float = level.camera.unproject_position(level.district.points[a]).distance_to(level.camera.unproject_position(level.district.points[b]))
	check(gap < .01 and level.district.points[a].distance_to(level.district.points[b]) > 3.9,"actual camera aligns authored seam across real depth gap")
