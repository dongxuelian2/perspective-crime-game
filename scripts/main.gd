extends Node3D
## The Folded Observatory: a constrained-walking, actual-projection topology puzzle.
const Folds = preload("res://scripts/fold_math.gd")
const Overlay = preload("res://scripts/observatory_ui.gd")
const IVORY := Color("e9ddbd")
const CREAM := Color("fff1d0")
const TEAL := Color("207b7d")
const DEEP := Color("12474f")
const GOLD := Color("dcb978")
const CORAL := Color("dc7769")
const START := Vector3(-4.0, 0.0, 3.0)
const TARGET := Vector3(0.0, 2.35, -1.0)
const VIEW_NAMES := ["DAWN", "NOON", "DUSK", "MIDNIGHT"]
const STAGE_NAMES := ["Wake the sun", "Gather the moon", "Unfold the horizon"]
const STAGE_NOTES := ["Two edges. One silhouette.", "A higher path hides in another view.", "The last distance is a matter of perspective."]
var folds: Array[Dictionary] = Folds.folds()
var goals: Array[Vector3] = []
var paths: Array[Array] = []
var camera: Camera3D
var avatar: Node3D
var avatar_body: Node3D
var lantern: MeshInstance3D
var hud: Control
var world: Node3D
var mode := "title"
var stage := 0
var view_index := 0
var yaw := PI / 4.0
var camera_size := 19.7
var camera_offset := -3.3
var turning := false
var walking := false
var crossing := false
var muted := false
var elapsed := 0.0
var message := ""
var message_time := 0.0
var last_aligned := false
var orbit_tween: Tween
var travel_tween: Tween
var reveal_tween: Tween
var victory_tween: Tween
var reset_generation := 0
var seal_nodes: Array[Node3D] = []
var seal_petals: Array[Array] = []
var seal_lights: Array[MeshInstance3D] = []
var fold_markers: Array[Array] = []
var floaters: Array[Node3D] = []
var floater_origins: Array[Vector3] = []
var rings: Array[Node3D] = []
var audio: Dictionary = {}
var demo := false
var capture_dir := ""
var quit_demo := false
var shutting_down := false
var stats := {"turns": 0, "folds": 0}
var pointer_down := Vector2.ZERO
var pointer_dragged := false
var is_dragging := false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	goals = [Vector3(3.4, 1.9, folds[0].b.z), Vector3(folds[1].b.x, 4.1, -6.3), Vector3(-1.4, 6.0, 1.0)]
	paths = [
		[START, folds[0].a, folds[0].b, goals[0]],
		[goals[0], folds[1].a, folds[1].b, goals[1]],
		[goals[1], Vector3(-3.4, 4.1, -6.3), folds[2].a, folds[2].b, Vector3(folds[2].b.x, 6.0, 1.0), goals[2]]
	]
	build_background()
	build_environment()
	world = Node3D.new()
	world.name = "TheFoldedObservatory"
	add_child(world)
	build_architecture()
	build_avatar()
	build_audio()
	camera = Camera3D.new()
	camera.name = "OrthographicObservatoryCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 90.0
	add_child(camera)
	camera.current = true
	update_camera()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Overlay.new()
	hud.level = self
	layer.add_child(hud)
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo": demo = true
		if arg == "--quit-after-demo": quit_demo = true
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	if demo: demo_run.call_deferred()

func build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var base := ColorRect.new()
	base.color = Color("061b28")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(base)
	if ResourceLoader.exists("res://assets/observatory.png"):
		var artwork := TextureRect.new()
		artwork.texture = load("res://assets/observatory.png")
		artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		artwork.modulate = Color(0.70, 0.78, 0.84, 1.0)
		artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(artwork)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.055, 0.08, 0.25)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)

func build_environment() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CANVAS
	environment.environment.background_canvas_max_layer = -1
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("9ad5d9")
	environment.environment.ambient_light_energy = 0.4
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var key := DirectionalLight3D.new()
	key.name = "WarmSunlight"
	key.rotation_degrees = Vector3(-55, -28, -18)
	key.light_color = Color("ffe2b7")
	key.light_energy = 1.0
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 40.0
	key.shadow_bias = 0.03
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 155, 0)
	fill.light_color = Color("6bdfdc")
	fill.light_energy = 0.3
	add_child(fill)

func mat(color: Color, emissive := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.76
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.75
	if color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func box(at: Vector3, size: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	node.material_override = mat(color)
	(parent if parent != null else world).add_child(node)
	return node

func cylinder(at: Vector3, radius: float, height: float, color: Color, parent: Node = null, sides := 32, top_radius := -1.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = sides
	node.mesh = mesh
	node.position = at
	node.material_override = mat(color)
	(parent if parent != null else world).add_child(node)
	return node

func sphere(at: Vector3, radius: float, color: Color, parent: Node = null, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 12
	node.mesh = mesh
	node.position = at
	node.material_override = mat(color, glow)
	(parent if parent != null else world).add_child(node)
	return node

func ring(at: Vector3, radius: float, width: float, color: Color, parent: Node = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - width * 0.5
	mesh.outer_radius = radius + width * 0.5
	mesh.rings = 48
	mesh.ring_segments = 10
	node.mesh = mesh
	node.position = at
	node.material_override = mat(color)
	(parent if parent != null else world).add_child(node)
	return node

func walkway(a: Vector3, b: Vector3, width := 0.68) -> void:
	var difference := b - a
	var center := (a + b) * 0.5
	var length := difference.length()
	var angle := atan2(difference.x, difference.z)
	var body := box(center - Vector3(0, 0.19, 0), Vector3(width, 0.36, length + 0.03), TEAL)
	body.rotation.y = angle
	var top := box(center - Vector3(0, 0.025, 0), Vector3(width + 0.025, 0.07, length + 0.04), IVORY)
	top.rotation.y = angle
	for side in [-1.0, 1.0]:
		var strip := box(Vector3(side * (width / 2.0 - 0.055), 0.045, 0), Vector3(0.025, 0.014, length), GOLD, top)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tile_count := maxi(2, int(length / 0.4))
	for i in range(1, tile_count):
		var tile := box(a.lerp(b, float(i) / tile_count) + Vector3(0, 0.016, 0), Vector3(width - 0.1, 0.007, 0.014), Color("beae8d"))
		tile.rotation.y = angle

func terrace(at: Vector3, radius: float, depth: float, tint := TEAL) -> void:
	cylinder(at - Vector3(0, 0.12, 0), radius, 0.24, IVORY, null, 8)
	cylinder(at - Vector3(0, 0.28, 0), radius * 1.02, 0.08, GOLD, null, 8)
	cylinder(at - Vector3(0, depth * 0.5 + 0.32, 0), radius * 0.49, depth, tint, null, 8, radius * 0.91)
	cylinder(at - Vector3(0, depth + 0.36, 0), radius * 0.52, 0.12, GOLD, null, 8)
	cylinder(at - Vector3(0, depth + 0.7, 0), 0.08, 0.6, DEEP, null, 8, radius * 0.45)
	ring(at + Vector3(0, 0.012, 0), radius * 0.75, 0.018, GOLD)
	# Fine fluting turns the hanging supports into carved masonry.
	for i in 8:
		var angle := TAU * i / 8.0 + PI / 8.0
		var offset := Vector3(sin(angle), 0, cos(angle)) * radius * 0.7
		cylinder(at + offset - Vector3(0, depth * 0.4 + 0.34, 0), 0.027, depth * 0.65, Color("579a94"), null, 6)

func build_architecture() -> void:
	terrace(START, 1.08, 1.6)
	terrace(goals[0], 1.15, 2.8)
	terrace(goals[1], 1.0, 3.5)
	terrace(Vector3(-3.4, 4.1, -6.3), 0.67, 1.8, DEEP)
	terrace(goals[2], 1.27, 5.0, Color("226569"))
	for i in 3:
		var path: Array = paths[i]
		for j in range(path.size() - 1):
			if path[j] == folds[i].a and path[j + 1] == folds[i].b: continue
			walkway(path[j], path[j + 1])
		var marker_pair: Array = []
		for endpoint: Vector3 in [folds[i].a, folds[i].b]:
			var marker := ring(endpoint + Vector3(0, 0.035, 0), 0.24, 0.055, GOLD)
			marker_pair.append(marker)
			# Gold cut faces make each open end legible, without building a fake bridge.
			var cap := box(endpoint - Vector3(0, 0.16, 0), Vector3(0.70, 0.32, 0.045), GOLD)
			cap.rotation.y = PI / 2.0 if i == 0 else 0.0
		fold_markers.append(marker_pair)
		build_seal(goals[i], i)
	# An open ivory colonnade, beneath the summit, frames rather than blocks the routes.
	for dx in [-0.87, 0.87]:
		for dz in [-0.78, 0.78]:
			var pos := Vector3(goals[2].x + dx, 3.8, goals[2].z + dz)
			cylinder(pos, 0.115, 3.7, IVORY, null, 12)
			cylinder(pos + Vector3(0, 1.72, 0), 0.19, 0.2, GOLD, null, 8)
			cylinder(pos - Vector3(0, 1.72, 0), 0.18, 0.2, GOLD, null, 8)
	var lower := Vector3(goals[2].x, 1.8, goals[2].z)
	cylinder(lower, 1.18, 0.23, IVORY, null, 8)
	cylinder(lower - Vector3(0, 0.16, 0), 1.12, 0.10, GOLD, null, 8)
	# Portico at the starting court.
	for side in [-1.0, 1.0]:
		box(START + Vector3(-0.50, 0.64, side * 0.57), Vector3(0.15, 1.28, 0.15), IVORY)
		box(START + Vector3(-0.50, 1.33, side * 0.57), Vector3(0.22, 0.16, 0.22), GOLD)
	box(START + Vector3(-0.50, 1.5, 0), Vector3(0.24, 0.26, 1.42), IVORY)
	box(START + Vector3(-0.50, 1.67, 0), Vector3(0.30, 0.08, 1.55), TEAL)
	# Suspended astrolabe, with independently animated gimbals.
	var center := goals[2] + Vector3(0, 1.55, 0)
	for i in 3:
		var gimbal := Node3D.new()
		gimbal.position = center
		gimbal.rotation = Vector3(PI / 2.0 if i == 0 else PI / 3.0, float(i) * PI / 3.0, float(i) * 0.4)
		world.add_child(gimbal)
		ring(Vector3.ZERO, 0.78 + i * 0.18, 0.045 if i < 2 else 0.03, GOLD, gimbal)
		for j in 12:
			var angle := TAU * j / 12.0
			var notch := box(Vector3(sin(angle), 0, cos(angle)) * (0.78 + i * 0.18), Vector3(0.04, 0.07, 0.12), IVORY, gimbal)
			notch.rotation.y = angle
		rings.append(gimbal)
	sphere(center, 0.23, Color("ffe0a0"), null, true)
	var globe := OmniLight3D.new()
	globe.position = center
	globe.light_color = GOLD
	globe.omni_range = 4.0
	globe.light_energy = 0.8
	world.add_child(globe)
	# Small hanging details repeat a restrained architectural vocabulary.
	for entry: Vector3 in [goals[0] + Vector3(0.8, 0, 0.4), goals[1] + Vector3(-0.5, 0, -0.5), START + Vector3(0.3, 0, -0.6)]:
		cylinder(entry + Vector3(0, 0.24, 0), 0.018, 0.48, GOLD, null, 8)
		sphere(entry + Vector3(0, 0.5, 0), 0.06, CREAM, null, true)
	var random := RandomNumberGenerator.new()
	random.seed = 7193
	for i in 35:
		var origin := Vector3(random.randf_range(-6, 6), random.randf_range(-2, 8), random.randf_range(-7, 4))
		var mote := sphere(origin, random.randf_range(0.013, 0.027), GOLD if i % 3 == 0 else Color("65c4bd"), null, true)
		floaters.append(mote)
		floater_origins.append(origin)
	# A quiet tiny stair on the first terrace adds scale without a false route.
	for i in 4:
		box(START + Vector3(0.3 + i * 0.12, -0.23 - i * 0.12, 0.72), Vector3(0.14, 0.14, 0.48), IVORY)

func build_seal(at: Vector3, index: int) -> void:
	var root := Node3D.new()
	root.position = at
	world.add_child(root)
	seal_nodes.append(root)
	cylinder(Vector3(0, 0.035, 0), 0.35, 0.07, DEEP, root, 24)
	ring(Vector3(0, 0.085, 0), 0.29, 0.035, GOLD, root)
	var light := sphere(Vector3(0, 0.48, 0), 0.105, GOLD, root, true)
	seal_lights.append(light)
	var petals: Array = []
	for j in 4:
		var pivot := Node3D.new()
		pivot.rotation.y = TAU * j / 4.0
		root.add_child(pivot)
		var petal := box(Vector3(0, 0.16, 0.25), Vector3(0.17, 0.04, 0.40), CORAL if index == 0 else IVORY, pivot)
		petal.rotation.x = -0.5
		petals.append(petal)
	seal_petals.append(petals)
	if index == 1:
		var moon := ring(Vector3(0, 0.67, 0), 0.30, 0.055, IVORY, root)
		moon.rotation.x = PI / 2.0
		moon.rotation.y = PI / 4.0

func build_avatar() -> void:
	avatar = Node3D.new()
	avatar.name = "TheAstronomer"
	avatar.position = START
	add_child(avatar)
	var shadow := cylinder(Vector3(0, 0.028, 0), 0.23, 0.006, Color(0.01, 0.07, 0.08, 0.3), avatar, 24)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	avatar_body = Node3D.new()
	avatar.add_child(avatar_body)
	cylinder(Vector3(0, 0.28, 0), 0.18, 0.38, CREAM, avatar_body, 20, 0.09)
	var cape := cylinder(Vector3(0, 0.28, 0.065), 0.20, 0.32, CORAL, avatar_body, 16, 0.08)
	cape.scale.z = 0.77
	sphere(Vector3(0, 0.53, 0), 0.115, CREAM, avatar_body)
	# Hood and crescent fin are this traveller's distinctive silhouette.
	cylinder(Vector3(0, 0.67, 0.01), 0.13, 0.23, CREAM, avatar_body, 16, 0.025)
	box(Vector3(0, 0.59, -0.107), Vector3(0.105, 0.035, 0.013), DEEP, avatar_body)
	cylinder(Vector3(0.2, 0.35, -0.03), 0.015, 0.38, GOLD, avatar_body, 8)
	lantern = sphere(Vector3(0.2, 0.49, -0.03), 0.055, Color("ffcf87"), avatar_body, true)
	for side in [-1.0, 1.0]:
		box(Vector3(side * 0.075, 0.04, -0.045), Vector3(0.08, 0.06, 0.14), DEEP, avatar_body)

func build_audio() -> void:
	for sound in ["ambience", "turn", "align", "step", "win"]:
		var path := "res://assets/audio/%s.wav" % sound
		if not ResourceLoader.exists(path): continue
		var player := AudioStreamPlayer.new()
		player.stream = load(path)
		player.volume_db = -18.0 if sound == "ambience" else -8.0
		if sound == "step": player.volume_db = -20.0
		add_child(player)
		audio[sound] = player
		if sound == "ambience":
			var stream := player.stream as AudioStreamWAV
			if stream:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				stream.loop_begin = 0
				stream.loop_end = int(stream.get_length() * stream.mix_rate)
			player.play()

func sound(name_: String) -> void:
	if audio.has(name_): audio[name_].play()

func toggle_mute() -> void:
	muted = not muted
	for player: AudioStreamPlayer in audio.values():
		player.volume_db = -80.0 if muted else (-18.0 if player == audio.get("ambience") else (-20.0 if player == audio.get("step") else -8.0))
	hud.refresh()

func update_camera() -> void:
	camera.position = TARGET + Folds.view_ray(yaw) * 27.0
	camera.look_at(TARGET)
	camera.size = camera_size
	camera.h_offset = camera_offset

func alignment_error(index := -1) -> float:
	var which := stage if index < 0 else index
	if which < 0 or which > 2: return INF
	return Folds.projected_gap(camera, folds[which].a + Vector3.UP * 0.04, folds[which].b + Vector3.UP * 0.04, get_viewport().get_visible_rect())

func aligned() -> bool:
	return alignment_error() <= 7.0 * get_viewport().get_visible_rect().size.y / 800.0

func can_traverse() -> bool:
	return mode == "play" and stage < 3 and not turning and not walking and aligned()

func begin() -> void:
	if mode != "title": return
	mode = "play"
	message = "Turn the observatory. Let the two golden edges meet."
	message_time = 6.0
	reveal_tween = create_tween().set_parallel(true)
	reveal_tween.tween_property(self, "camera_offset", 0.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	reveal_tween.tween_property(self, "camera_size", 17.6, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	hud.refresh()

func turn_view(direction: int) -> bool:
	if mode != "play" or turning or walking: return false
	turning = true
	last_aligned = false
	view_index = posmod(view_index + direction, 4)
	stats.turns += 1
	var target_yaw := yaw + direction * PI / 2.0
	orbit_tween = create_tween()
	orbit_tween.tween_property(self, "yaw", target_yaw, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	orbit_tween.tween_callback(func():
		yaw = wrapf(yaw, 0.0, TAU)
		turning = false
		update_camera()
		hud.refresh()
	)
	sound("turn")
	hud.refresh()
	return true

func request_journey() -> bool:
	if mode != "play" or walking or turning: return false
	if not aligned():
		message = "The edges are still apart. Try another view."
		message_time = 3.6
		hud.refresh()
		return false
	walking = true
	message = ""
	message_time = 0.0
	travel_stage(reset_generation)
	hud.refresh()
	return true

func travel_stage(generation: int) -> void:
	var current_stage := stage
	var route: Array = paths[current_stage]
	for i in range(1, route.size()):
		if generation != reset_generation: return
		var origin: Vector3 = route[i - 1]
		var destination: Vector3 = route[i]
		crossing = origin == folds[current_stage].a and destination == folds[current_stage].b
		var duration := 0.95 if crossing else origin.distance_to(destination) / 1.75
		if not crossing:
			var direction := destination - origin
			avatar.rotation.y = atan2(-direction.x, -direction.z)
		else:
			sound("align")
			stats.folds += 1
		travel_tween = create_tween()
		travel_tween.tween_property(avatar, "position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		while travel_tween.is_valid() and travel_tween.is_running() and generation == reset_generation:
			await get_tree().process_frame
		if generation != reset_generation: return
	crossing = false
	walking = false
	activate_seal(current_stage)
	stage += 1
	last_aligned = false
	if stage == 3:
		finish()
	else:
		message = "The sun is awake. Find the moon's hidden path." if stage == 1 else "Two lights remembered. Return to the horizon."
		message_time = 5.0
	hud.refresh()

func activate_seal(index: int) -> void:
	sound("align")
	seal_lights[index].material_override = mat(Color("fff1b3"), true)
	var tween := create_tween().set_parallel(true)
	for petal: MeshInstance3D in seal_petals[index]:
		tween.tween_property(petal, "rotation:x", -1.3, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(petal, "position:y", 0.27, 1.3)
	tween.tween_property(seal_lights[index], "position:y", 0.80, 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(seal_lights[index], "scale", Vector3.ONE * 1.6, 1.5)

func finish() -> void:
	mode = "won"
	sound("win")
	message = ""
	victory_tween = create_tween().set_parallel(true)
	victory_tween.tween_property(self, "camera_offset", -3.2, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	victory_tween.tween_property(self, "camera_size", 19.7, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	hud.refresh()

func reset_level(to_title := false) -> void:
	reset_generation += 1
	for tween: Tween in [orbit_tween, travel_tween, reveal_tween, victory_tween]:
		if tween and tween.is_valid(): tween.kill()
	# Kill seal animations as well, including a reset during their flourish.
	for tween: Tween in get_tree().get_processed_tweens():
		if tween.is_valid(): tween.kill()
	stage = 0
	view_index = 0
	yaw = PI / 4.0
	walking = false
	crossing = false
	turning = false
	last_aligned = false
	mode = "title" if to_title else "play"
	camera_offset = -3.3 if to_title else 0.0
	camera_size = 19.7 if to_title else 17.6
	avatar.position = START
	avatar.rotation = Vector3.ZERO
	stats = {"turns": 0, "folds": 0}
	message = "Turn the observatory. Let the two golden edges meet."
	message_time = 5.0
	for i in 3:
		seal_lights[i].position.y = 0.48
		seal_lights[i].scale = Vector3.ONE
		seal_lights[i].material_override = mat(GOLD, true)
		for petal: MeshInstance3D in seal_petals[i]:
			petal.rotation.x = -0.5
			petal.position.y = 0.16
	update_camera()
	hud.refresh()

func hint() -> void:
	if mode != "play" or walking: return
	var target_views := [1, 2, 0]
	var difference := posmod(target_views[stage] - view_index, 4)
	if difference == 0:
		message = "The golden circles overlap. Touch the glowing destination, or press Space."
	elif difference == 3:
		message = "Turn one view to the left. Watch the golden edges, not their distance."
	else:
		message = "Turn %s to the right. Watch the golden edges meet." % ("one view" if difference == 1 else "two views")
	message_time = 7.0
	hud.refresh()

func active_goal_screen() -> Vector2:
	if stage > 2: return Vector2(-1000, -1000)
	return camera.unproject_position(goals[stage] + Vector3(0, 0.55, 0))

func _process(delta: float) -> void:
	elapsed += delta
	if is_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): is_dragging = false
	update_camera()
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message = ""
			hud.refresh()
	for i in floaters.size():
		floaters[i].position = floater_origins[i] + Vector3(sin(elapsed * 0.2 + i) * 0.09, sin(elapsed * 0.5 + i * 0.7) * 0.17, 0)
	for i in rings.size():
		rings[i].rotate_y(delta * (0.045 + i * 0.025) * (3.0 if mode == "won" else 1.0))
	for i in seal_lights.size():
		seal_lights[i].rotation.y += delta
		seal_nodes[i].rotation.y = sin(elapsed * 0.35 + i) * 0.05
	avatar_body.position.y = absf(sin(elapsed * 8.5)) * 0.055 if walking and not crossing else sin(elapsed * 2.0) * 0.018
	avatar_body.rotation.z = sin(elapsed * 8.5) * 0.055 if walking and not crossing else 0.0
	if walking and not crossing and int(elapsed * 3.0) != int((elapsed - delta) * 3.0): sound("step")
	if mode == "play" and stage < 3:
		var ready_now := aligned() and not turning and not walking
		if ready_now and not last_aligned: sound("align")
		if ready_now != last_aligned:
			last_aligned = ready_now
			hud.refresh()
		for i in 3:
			for marker: MeshInstance3D in fold_markers[i]:
				var marker_color := Color("ffe8ac") if i == stage and ready_now else (GOLD if i == stage else Color("8f9c81"))
				(marker.material_override as StandardMaterial3D).albedo_color = marker_color
				marker.scale = Vector3.ONE * (1.0 + sin(elapsed * 3.0) * 0.09 if i == stage else 0.85)
	hud.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.keycode if event.keycode != 0 else event.physical_keycode
		if hud.help_open:
			if code == KEY_ESCAPE: hud.toggle_help(false)
			return
		if code == KEY_M: toggle_mute()
		elif code == KEY_F12: capture("manual-%d" % Time.get_ticks_msec())
		elif code == KEY_R: reset_level()
		elif code == KEY_ESCAPE:
			is_dragging = false
			hud.toggle_help(false)
		elif mode == "title" and code in [KEY_SPACE, KEY_ENTER]: begin()
		elif mode == "won" and code in [KEY_SPACE, KEY_ENTER]: reset_level()
		elif code in [KEY_Q, KEY_LEFT, KEY_A]: turn_view(-1)
		elif code in [KEY_E, KEY_RIGHT, KEY_D]: turn_view(1)
		elif code in [KEY_SPACE, KEY_ENTER]: request_journey()
		elif code == KEY_H: hint()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_down = event.position
			pointer_dragged = false
			is_dragging = true
		else:
			if is_dragging and not pointer_dragged and mode == "play" and event.position.distance_to(active_goal_screen()) < 65.0:
				request_journey()
			is_dragging = false
	elif event is InputEventMouseMotion and is_dragging and not pointer_dragged:
		if absf(event.position.x - pointer_down.x) > 65.0:
			pointer_dragged = true
			turn_view(-1 if event.position.x > pointer_down.x else 1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		is_dragging = false
		pointer_dragged = false

func capture(label: String) -> void:
	if capture_dir.is_empty(): return
	await RenderingServer.frame_post_draw
	var file := capture_dir.path_join(label + ".png")
	get_viewport().get_texture().get_image().save_png(file)
	print("CAPTURE ", file)

func demo_run() -> void:
	await get_tree().create_timer(3.0).timeout
	await capture("01-title")
	begin()
	await get_tree().create_timer(2.0).timeout
	await capture("02-observatory")
	for goal_stage in 3:
		var wanted: int = [1, 2, 0][goal_stage]
		while view_index != wanted:
			turn_view(1)
			while turning: await get_tree().process_frame
			await get_tree().create_timer(0.7).timeout
		await capture("03-fold-%d" % (goal_stage + 1))
		await get_tree().create_timer(1.5).timeout
		if not request_journey():
			push_error("Demo could not traverse geometric fold %d" % goal_stage)
			return
		while walking: await get_tree().process_frame
		await get_tree().create_timer(2.0).timeout
	await get_tree().create_timer(3.0).timeout
	await capture("04-finale")
	print("DEMO_COMPLETE folds=", stats.folds, " turns=", stats.turns)
	if quit_demo: quit_game()

func _exit_tree() -> void:
	for player: AudioStreamPlayer in audio.values():
		player.stop()
		player.stream = null
	audio.clear()

func quit_game() -> void:
	if shutting_down: return
	shutting_down = true
	for player: AudioStreamPlayer in audio.values(): player.stop()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
