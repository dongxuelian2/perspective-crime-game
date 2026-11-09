extends SceneTree
## --headless --fixed-fps 60 --path . --script tests/chapter_stress.gd -- --no-save
## Scene checkpoints only; all actor travel uses physical routes or authored seams.
const Scene = preload("res://scenes/chapter.tscn")
const Art = preload("res://scripts/chapter/paper_art.gd")
var level
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_text: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label_text)
func frames(n: int) -> void:
	for i in n: await physics_frame
func clear_actor(label_text: String) -> void:
	check(level.actor.collision_mask == 1 and level.actor.can_occupy(level.actor.position),label_text)
func checkpoint(n: int) -> void:
	level.load_district(n)
	await frames(6)
	check(level.actor_id == "A" and level.actor.position.distance_to(level.district.points.A) < .1,"independent checkpoint %d safe entry" % n)
	clear_actor("checkpoint %d mask and capsule" % n)
func walk(id: String) -> bool:
	if not level.walk_to(id):
		check(false,"route starts " + id)
		return false
	for i in 1800:
		await physics_frame
		if not level.walking: break
	var ok: bool = level.actor_id == id
	check(ok,"physical route reaches " + id)
	clear_actor("arrival " + id + " capsule and mask")
	return ok
func turn(index: int, target: float) -> void:
	var m = level.district.mechanisms[index]
	level.adjust_mechanism(m,target-m.value)
	await frames(3)
	check(absf(m.value-target)<.001,"mechanism %d target %.2f" % [index,target])
	clear_actor("after carrier adjustment")
func gesture(amount: float) -> Vector2:
	var m = level.district.mechanisms[0]
	var p: Vector2 = level.camera.unproject_position(m.handle.global_position)
	level.router.pointer(true,p)
	var end: Vector2 = p+level.mechanism_tangent(m)*amount
	level.router.motion(end)
	return end
func run() -> void:
	if not "--no-save" in OS.get_cmdline_user_args(): quit(2); return
	Engine.time_scale = 1.0
	level = Scene.instantiate()
	root.add_child(level)
	await frames(8)
	for child in level.layer.get_children():
		if child.has_signal("dismissed"): child.dismissed.emit()
	await frames(4)
	for size in [Vector2i(960,600), Vector2i(1280,800)]:
		root.size = size
		await checkpoint(0)
		await turn(0,0)
		var end := gesture(.24)
		check(level.active_mechanism == level.district.mechanisms[0],"viewport %s intended projected grip" % size)
		check(absf(level.district.mechanisms[0].value-.24)<.01,"viewport %s projected drag angle" % size)
		level.router.pointer(false,end)
		check(level.settling,"release snap starts")
		level.restart()
		await frames(60)
		check(not level.settling and level.active_mechanism == null and not level.router.down,"restart cancels snap and capture")
		clear_actor("restart during snap safe")
		await turn(0,0)
		end = gesture(.24)
		level._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		level.router.pointer(false,end)
		await frames(60)
		check(not level.router.down and not level.router.dragging and level.active_mechanism == null and not level.settling and not level.walking,"focus loss cancels capture without stray tap")
		end = gesture(.24)
		var esc := InputEventKey.new()
		esc.keycode = KEY_ESCAPE
		esc.pressed = true
		level._unhandled_key_input(esc)
		level.router.pointer(false,end)
		await frames(60)
		check(not level.router.down and level.active_mechanism == null and not level.settling,"Escape releases capture and settles")
		check(level.walk_to("B"),"repeat click probe starts")
		var all_blocked := true
		for i in 20: all_blocked = not level.walk_to("B") and all_blocked
		check(all_blocked,"repeated route clicks rejected during traversal")
		await frames(240)
		check(level.actor_id == "B" and not level.walking,"repeated clicks do not corrupt route")
		level.adjust_mechanism(level.district.mechanisms[1],PI/2)
		check(level.district.mechanisms[1].value < PI/2-.1,"intermediate lifting arm cannot sweep through pivot occupant")
		clear_actor("unsafe arm sweep retains clear capsule")
	for n in range(5): await checkpoint(n)
	# Portal destination occupancy failure must never transfer the body.
	await checkpoint(2)
	await turn(0,0)
	if not await walk("C"): await finish(); return
	await turn(1,0)
	var start: Vector3 = level.actor.position
	var blocker = Art.box(level,Vector3(.6,1.3,.6),level.district.points.D+Vector3.UP*.65,Art.CORAL,true)
	await frames(3)
	check(level.walk_to("D"),"blocked seam route starts its fade")
	await frames(45)
	check(not level.walking and level.actor_id == "C" and level.actor.position.distance_to(start)<.1,"overlapped portal destination rejects transfer")
	check(level.actor.visual.scale.distance_to(Vector3.ONE)<.01,"failed portal restores visible actor")
	clear_actor("failed seam mask and source capsule")
	blocker.queue_free()
	await frames(4)
	for delay in [3,15]:
		if level.actor_id != "C":
			await checkpoint(2)
			await turn(0,0)
			if not await walk("C"): await finish(); return
			await turn(1,0)
		check(level.walk_to("D"),"reset portal probe starts")
		await frames(delay)
		level.restart()
		await frames(60)
		check(level.actor_id == "A" and not level.walking and level.actor.visual.scale.distance_to(Vector3.ONE)<.01,"reset during portal phase %d cancels stale completion" % delay)
		clear_actor("portal reset safe")
	# Rider destination obstruction while moving a counterweight.
	await checkpoint(1)
	if not await walk("R"): await finish(); return
	var m = level.district.mechanisms[0]
	# One clear outward and return motion before the obstruction test.
	await turn(0,3.5)
	await turn(0,-3.5)
	var target: Vector3 = level.actor.position + Vector3(7,0,0)
	blocker = Art.box(level,Vector3(.7,1.4,.7),target+Vector3.UP*.7,Art.CORAL,true)
	await frames(3)
	level.adjust_mechanism(m,7.0)
	await frames(3)
	check(m.value < 3.49,"occupied shuttle destination blocks full carrier travel")
	clear_actor("blocked carrier retains capsule and mask")
	blocker.queue_free()
	await finish()
func finish() -> void:
	print("CHAPTER STRESS RESULTS: %d checks, %d failures" % [checks,failures])
	level.audio.stop()
	level.queue_free()
	await process_frame
	OS.delay_msec(250)
	quit(1 if failures else 0)
