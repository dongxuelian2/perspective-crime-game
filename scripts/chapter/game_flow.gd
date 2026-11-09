extends Node3D
const Art = preload("res://scripts/chapter/paper_art.gd")
const Module = preload("res://scripts/chapter/chapter_module.gd")
const Router = preload("res://scripts/chapter/input_router.gd")
const Panels = preload("res://scripts/chapter/narrative_panels.gd")
const Hud = preload("res://scripts/chapter/chapter_hud.gd")
const Walker = preload("res://scripts/chapter/route_walker.gd")
const Audio = preload("res://scripts/chapter/audio_director.gd")
const Layouts = preload("res://scripts/chapter/chapter_layouts.gd")
var camera: Camera3D
var district
var router
var hud
var layer: CanvasLayer
var actor
var actor_id := "A"
var checkpoint := 0
var mode := "comic"
var walking := false
var active_mechanism = null
var portal_tween: Tween
var route_queue: Array = []
var generation := 0
var settling := false
var snap_mechanism = null
var snap_target := 0.0
var elapsed := 0.0
var invalid_timer := 0.0
var invalid_at := Vector2.ZERO
var audio
var muted := false
var capture_dir := ""
var no_save := false
var audio_check_requested := false
var shutting_down := false
var foot_distance := 0.0
var foot_index := 0
var last_mechanism_sound := -10.0
func _ready() -> void:
	get_tree().auto_accept_quit = false
	for arg in OS.get_cmdline_user_args():
		if arg == "--no-save": no_save = true
		if arg == "--audio-check": audio_check_requested = true; no_save = true
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	build_backdrop()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CANVAS
	env.environment.background_canvas_max_layer = -1
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c4e2d6")
	env.environment.ambient_light_energy = .4
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-30,0)
	sun.light_color = Color("fff3df")
	sun.light_energy = .8
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0
	camera.position = Vector3(12,15,22)
	add_child(camera)
	camera.look_at(Vector3(0,-1,0))
	camera.current = true
	layer = CanvasLayer.new()
	add_child(layer)
	router = Router.new()
	add_child(router)
	router.tapped.connect(tap)
	router.drag_started.connect(begin_drag)
	router.dragged.connect(drag)
	router.drag_finished.connect(end_drag)
	hud = Hud.new()
	hud.flow = self
	layer.add_child(hud)
	audio = Audio.new()
	add_child(audio)
	if not no_save:
		var config := ConfigFile.new()
		if config.load("user://letter.cfg") == OK and config.get_value("chapter","format",0) == 2:
			checkpoint = clampi(config.get_value("chapter", "district", 0), 0, Layouts.count()-1)
	load_district(checkpoint)
	show_comic(false)
	if audio_check_requested: audio_check.call_deferred()
func load_district(number: int) -> void:
	router.cancel()
	active_mechanism = null
	walking = false
	settling = false
	snap_mechanism = null
	generation += 1
	route_queue.clear()
	if is_instance_valid(portal_tween): portal_tween.kill()
	if is_instance_valid(district):
		remove_child(district)
		district.queue_free()
	if is_instance_valid(actor):
		remove_child(actor)
		actor.queue_free()
	checkpoint = number
	district = Module.new()
	add_child(district)
	district.setup(number, camera)
	actor = Walker.new()
	add_child(actor)
	actor.finished.connect(on_segment_finished)
	actor_id = "A"
	actor.position = district.points.A
	if not no_save:
		var config := ConfigFile.new()
		config.set_value("chapter", "format", 2)
		config.set_value("chapter", "district", checkpoint)
		config.save("user://letter.cfg")
func show_comic(ending: bool) -> void:
	mode = "comic"
	hud.hide()
	var comic = Panels.new()
	comic.ending = ending
	layer.add_child(comic)
	comic.dismissed.connect(func():
		comic.queue_free()
		if ending: load_district(0)
		mode = "play"
		hud.show()
	)
func _process(delta: float) -> void:
	elapsed += delta
	invalid_timer = maxf(0, invalid_timer-delta)
	if is_instance_valid(district):
		district.rebuild()
		district.update_reachable(actor_id, elapsed)
	if is_instance_valid(actor):
		actor.visual.rotation.z = sin(elapsed * (12 if walking else 1.5)) * (.035 if walking else .012)
		for foot_index in [5, 6]:
			actor.visual.get_child(foot_index).position.y = .09 + (absf(sin(elapsed*12 + foot_index*PI/2))*.08 if walking else 0.0)
	hud.queue_redraw()
func feedback(at: Vector2) -> void:
	invalid_at = at
	invalid_timer = 1.0
	audio.play("invalid")
func tap(p: Vector2) -> void:
	if mode != "play" or walking or settling or hud.help.visible: return
	for i in range(district.pins.size()):
		var pin: Dictionary = district.pins[i]
		if pin.at == actor_id and camera.unproject_position(pin.marker.global_position).distance_to(p) < 26:
			if district.toggle_pin(i,actor_id): audio.play("pin")
			return
	var closest := ""
	var distance := 32.0
	for id in district.points:
		var candidate: float = camera.unproject_position(district.points[id]).distance_to(p)
		# At an aligned seam, prefer the far-side landing when already on its near side.
		if candidate < distance and id != actor_id:
			distance = candidate
			closest = id
	if closest.is_empty():
		feedback(p)
		return
	walk_to(closest)
func walk_to(id: String) -> bool:
	if mode != "play" or walking or settling or not district.points.has(id): return false
	district.rebuild()
	var route: Array = district.graph.route(actor_id,id)
	if route.is_empty() or (route.size() == 1 and actor.position.distance_to(district.points[id]) < .2):
		feedback(camera.unproject_position(district.points[id]))
		return false
	route_queue = route.slice(1) if route.size() > 1 else route
	walking = true
	active_mechanism = null
	actor.carried = false
	for mechanism in district.mechanisms: mechanism.busy = true
	walk_next()
	return true
func walk_next() -> void:
	if route_queue.is_empty():
		walking = false
		for mechanism in district.mechanisms: mechanism.busy = false
		audio.play("arrive")
		if actor_id == district.exit_id: advance()
		return
	var next: String = route_queue[0]
	if district.is_seam(actor_id,next): cross_portal(next)
	else: actor.start_route([district.points[next]])
func on_segment_finished(success: bool) -> void:
	if not walking: return
	if not success:
		route_queue.clear()
		walking = false
		for mechanism in district.mechanisms: mechanism.busy = false
		feedback(camera.unproject_position(actor.position))
		return
	actor_id = route_queue.pop_front()
	walk_next.call_deferred()
func cross_portal(next: String) -> void:
	var token := generation
	audio.play("seam")
	portal_tween = create_tween()
	portal_tween.tween_property(actor.visual,"scale",Vector3.ONE*.02,.18)
	await get_tree().create_timer(.2).timeout
	if token != generation: return
	var success: bool = actor.transfer_projection_seam(district.points[next],camera)
	portal_tween = create_tween()
	portal_tween.tween_property(actor.visual,"scale",Vector3.ONE,.18)
	await get_tree().create_timer(.2).timeout
	if token != generation: return
	on_segment_finished(success)
func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor) or not is_instance_valid(district): return
	if actor.active and actor.is_on_floor():
		foot_distance += actor.get_real_velocity().length()*delta
		if foot_distance > .85:
			foot_distance = 0
			audio.play("wood%d" % (foot_index%3))
			foot_index += 1
	if settling and is_instance_valid(snap_mechanism):
		var before: float = snap_mechanism.value
		var difference: float = snap_target-before
		adjust_mechanism(snap_mechanism,signf(difference)*minf(absf(difference),delta*4.0))
		if absf(snap_mechanism.value-snap_target) < .001 or is_equal_approx(before,snap_mechanism.value):
			settling = false
			snap_mechanism = null
			audio.play("snap")
	if not walking:
		actor.carried = district.carriers.has(actor_id)
		if actor.carried: actor.position = district.points[actor_id]
func force_colliders(node: Node) -> void:
	if node is CollisionObject3D: node.force_update_transform()
	for child in node.get_children(): force_colliders(child)
func adjust_mechanism(mechanism, amount: float) -> bool:
	if walking or mechanism.locked or mechanism.busy: return false
	var changed := false
	var steps := maxi(1,ceili(absf(amount)/.025))
	for step in range(steps):
		var values: Array = []
		for m in district.mechanisms: values.append(m.value)
		mechanism.adjust(amount/steps)
		district.rebuild()
		force_colliders(district)
		var destination: Vector3 = district.points[actor_id] if district.carriers.has(actor_id) else actor.position
		if not actor.can_occupy(destination):
			district.updating = true
			for i in range(values.size()):
				district.mechanisms[i].value = values[i]
				district.mechanisms[i].apply()
			district.updating = false
			district.rebuild()
			force_colliders(district)
			feedback(camera.unproject_position(actor.position))
			break
		if district.carriers.has(actor_id): actor.position = destination
		changed = true
	return changed
func begin_drag(p: Vector2) -> void:
	if mode != "play" or walking or settling or hud.help.visible: return
	if actor.position.distance_to(district.points[actor_id]) > .3:
		feedback(camera.unproject_position(actor.position))
		return
	var distance := 46.0
	for mechanism in district.mechanisms:
		var candidate: float = camera.unproject_position(mechanism.handle.global_position).distance_to(p)
		if not mechanism.interactive: continue
		if candidate < distance:
			active_mechanism = mechanism
			distance = candidate
	if active_mechanism == null: feedback(p)
	else: audio.play("grab")
func drag(delta: Vector2) -> void:
	if active_mechanism == null or walking: return
	var tangent := mechanism_tangent(active_mechanism)
	if tangent.length_squared() > 1:
		var moved := adjust_mechanism(active_mechanism,clampf(delta.dot(tangent)/tangent.length_squared(),-TAU,TAU))
		if moved and elapsed-last_mechanism_sound > .8:
			audio.play("slide" if active_mechanism.kind in ["slide","shuttle"] else "creak%d" % (foot_index%2))
			last_mechanism_sound = elapsed
func mechanism_tangent(mechanism) -> Vector2:
	var derivative: Vector3
	if mechanism.kind == "hinge": derivative = Vector3(-sin(mechanism.value),0,-cos(mechanism.value))*mechanism.span*.6
	elif mechanism.kind == "lift": derivative = Vector3(-sin(mechanism.value),cos(mechanism.value),0)*mechanism.span
	else: derivative = mechanism.axis
	derivative = mechanism.global_basis*derivative
	var at: Vector3 = mechanism.handle.global_position
	return (camera.unproject_position(at+derivative*.01)-camera.unproject_position(at))/.01
func end_drag() -> void:
	if active_mechanism != null:
		var increment := PI/2 if active_mechanism.kind in ["hinge","lift"] else .25
		snap_target = snappedf(active_mechanism.value,increment)
		snap_mechanism = active_mechanism
		settling = true
		active_mechanism = null
func advance() -> void:
	if checkpoint == Layouts.count()-1:
		audio.milestone(true)
		if not no_save:
			var config := ConfigFile.new()
			config.set_value("chapter", "district", 0)
			config.save("user://letter.cfg")
		mode = "delivery"
		var delivery := create_tween()
		delivery.tween_property(actor.visual.get_child(3),"position",Vector3(0,.65,-.3),.45)
		delivery.parallel().tween_property(actor.visual.get_child(4),"position",Vector3(0,.65,-.27),.45)
		delivery.tween_property(actor.visual.get_child(3),"scale",Vector3.ZERO,.18)
		delivery.parallel().tween_property(actor.visual.get_child(4),"scale",Vector3.ZERO,.18)
		delivery.tween_callback(func(): show_comic(true))
	else:
		audio.milestone()
		mode = "transition"
		var fade := ColorRect.new()
		fade.color = Color("e9dfc4")
		fade.mouse_filter = Control.MOUSE_FILTER_STOP
		fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fade.modulate.a = 0
		layer.add_child(fade)
		var t := create_tween()
		t.tween_property(fade,"modulate:a",1.0,.45)
		t.tween_callback(func(): load_district(checkpoint+1))
		t.tween_property(fade,"modulate:a",0.0,.55)
		t.tween_callback(func(): fade.queue_free(); mode = "play")
func restart() -> void:
	if mode != "play": return
	load_district(checkpoint)
func toggle_sound() -> void:
	audio.toggle()
	muted = audio.muted
func play_chime() -> void: audio.play("arrive")
func hint_text() -> String:
	if actor.failure_reason == "blocked": return "Something solid blocks this route. Return to a landing or restart this district."
	if checkpoint == 1:
		return "The empty cart is a counterweight. Board the lift, then send the cart back."
	for pin in district.pins:
		if pin.at == actor_id and not pin.engaged: return "Pin this street before turning the linked section. The next gate needs both shapes."
	if district.carriers.has(actor_id): return "You are aboard. Drag the carriage or its counterweight to reach another landing."
	if checkpoint in [2,4]: return "Align the two facade medallions. Their overlap opens a marked space-fold, not an ordinary street."
	return "Walk onto the level carriage before folding its street upward. Your weight travels with it."
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event.keycode == KEY_F12 and not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
		get_viewport().get_texture().get_image().save_png(capture_dir.path_join("chapter-%d-%d.png" % [checkpoint, Time.get_ticks_msec()]))
	elif event.keycode == KEY_R: restart()
	elif event.keycode == KEY_M: toggle_sound()
	elif event.keycode == KEY_ESCAPE: hud.help.hide(); cancel_gesture()

func cancel_gesture() -> void:
	end_drag()
	router.cancel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(audio): shutdown()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(router): cancel_gesture()

func build_backdrop() -> void:
	var background := CanvasLayer.new()
	background.layer = -10
	add_child(background)
	var base := ColorRect.new()
	base.color = Color("183e4d")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(base)
	if ResourceLoader.exists("res://assets/chapter_sky.png"):
		var sky := TextureRect.new()
		sky.texture = load("res://assets/chapter_sky.png")
		sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky.modulate = Color(.65,.72,.75,1)
		background.add_child(sky)

func _exit_tree() -> void:
	if is_instance_valid(audio): audio.stop()

func audio_check() -> void:
	await get_tree().create_timer(.5).timeout
	for cue in audio.CUES:
		audio.play(cue)
		await get_tree().create_timer(.65).timeout
	audio.milestone(true)
	await get_tree().create_timer(3.0).timeout
	print("AUDIO_CHECK_COMPLETE sampled_cues=%d" % audio.CUES.size())
	shutdown()

func shutdown() -> void:
	if shutting_down: return
	shutting_down = true
	generation += 1
	if is_instance_valid(actor): actor.cancel()
	audio.stop()
	await get_tree().process_frame
	# Test/movie fixed-fps can outrun the real audio thread. Drain on exit only.
	OS.delay_msec(250)
	get_tree().quit()
