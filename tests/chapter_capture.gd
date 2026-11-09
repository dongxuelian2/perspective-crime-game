extends SceneTree
## Scripted renderer/input demonstration, not independent human playtesting.
## --write-movie /outside/repo/chapter.avi --fixed-fps 60
## --script tests/chapter_capture.gd -- --no-save --capture-dir=/outside/repo
## All navigation/mechanism actions use pointer-router gestures at timescale 1.
const Scene = preload("res://scenes/chapter.tscn")
var level
var failed := false
func _initialize() -> void: call_deferred("run")
func pause(seconds: float) -> void: await create_timer(seconds).timeout
func capture(label_text: String) -> void:
	if level.capture_dir.is_empty() or DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(level.capture_dir)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(level.capture_dir.path_join(label_text+".png"))
func stop(reason: String) -> void:
	failed = true
	push_error("CHAPTER_CAPTURE_FAILED: "+reason)
	level.audio.stop()
	quit(1)
func dismiss() -> void:
	for child in level.layer.get_children():
		if child.has_signal("dismissed"): child.dismissed.emit()
	await pause(.3)
func tap_at(p: Vector2) -> void:
	level.router.pointer(true,p)
	level.router.pointer(false,p)
func drag_to(index: int,target: float) -> void:
	var m = level.district.mechanisms[index]
	var p: Vector2 = level.camera.unproject_position(m.handle.global_position)
	level.router.pointer(true,p)
	# Integrate the live screen-space tangent. The capture follows the same drag
	# projection as a pointer, without assigning architecture or actor transforms.
	var captured := false
	for i in range(400):
		var remaining: float = target-m.value
		if absf(remaining) < .001: break
		var step := clampf(remaining,-.05,.05)
		p += level.mechanism_tangent(m)*step
		level.router.motion(p)
		captured = captured or level.active_mechanism == m
		await pause(1.0/60.0)
	level.router.pointer(false,p)
	if not captured: stop("projected grip drag never crossed capture threshold"); return
	await pause(.35)
	if absf(m.value-target) > .01: stop("district %d grip %d expected %.2f got %.2f" % [level.checkpoint,index,target,m.value])
func walk(id: String) -> void:
	var checkpoint: int = level.checkpoint
	var exiting: bool = id == level.district.exit_id
	tap_at(level.camera.unproject_position(level.district.points[id]))
	for i in range(1800):
		if not level.walking and not level.mode in ["transition","delivery"]: break
		await physics_frame
	await pause(.3)
	var arrived: bool = (level.checkpoint == checkpoint+1 or level.mode == "comic") if exiting else level.actor_id == id
	if not arrived: stop("district %d tap %s reached %s, reason %s" % [checkpoint,id,level.actor_id,level.actor.failure_reason])
func pin(index: int) -> void:
	tap_at(level.camera.unproject_position(level.district.pins[index].marker.global_position))
	await pause(.4)
	if not level.district.pins[index].engaged: stop("pin did not engage")
func run() -> void:
	if not "--no-save" in OS.get_cmdline_user_args(): quit(2); return
	root.size = Vector2i(1280,800)
	Engine.time_scale = 1.0
	level = Scene.instantiate()
	root.add_child(level)
	await pause(1)
	await capture("opening")
	await dismiss()
	var plans := [
		[["drag",0,0.0],["walk","R"],["drag",1,PI/2],["capture","lift-aboard"],["walk","C"],["drag",2,PI/2],["walk","E"]],
		[["walk","R"],["drag",0,3.5],["walk","S"],["drag",0,-3.5],["capture","counterweight-aboard"],["walk","D"],["drag",2,PI/2],["walk","F"]],
		[["drag",0,0.0],["walk","C"],["drag",1,0.0],["capture","facade-aligned"],["walk","D"],["drag",2,0.0],["walk","R"],["drag",3,PI/2],["walk","F"]],
		[["drag",0,0.0],["walk","B"],["pin",0],["drag",1,PI/2],["walk","C"],["pin",1],["drag",2,0.0],["capture","archive-pinned"],["walk","E"]],
		[["drag",0,0.0],["walk","R"],["drag",1,PI/2],["walk","C"],["pin",0],["drag",2,PI/2],["walk","D"],["drag",3,0.0],["walk","S"],["drag",4,0.0],["capture","tower-solved"],["walk","E"]]
	]
	for district_index in range(plans.size()):
		if level.checkpoint != district_index: stop("progression checkpoint mismatch"); return
		await capture("district-%d-entry" % district_index)
		for action in plans[district_index]:
			match action[0]:
				"drag": await drag_to(action[1],action[2])
				"walk": await walk(action[1])
				"pin": await pin(action[1])
				"capture": await capture(action[1])
			if failed: return
	await capture("ending")
	await pause(1)
	print("CHAPTER_RENDER_COMPLETE districts=5")
	level.audio.stop()
	level.queue_free()
	# Fixed-fps simulation can finish before the audio thread releases playback.
	await process_frame
	OS.delay_msec(250)
	await pause(.2)
	quit()
