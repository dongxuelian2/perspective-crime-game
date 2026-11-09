extends SceneTree
## Headless mechanism/flow tests, complementary to the rendered playtest.
## Run with a writable XDG_DATA_HOME when using a sandboxed engine.
const Scene = preload("res://scenes/main.tscn")
const Geometry = preload("res://scripts/fold_math.gd")
var level: Node3D
var failures := 0
var checks := 0

func check(condition: bool, label_: String) -> void:
	checks += 1
	if not condition: failures += 1
	print(("PASS " if condition else "FAIL ") + label_)

func frames(count: int) -> void:
	for i in count: await process_frame

func key(code: int, physical_only := false) -> void:
	var event := InputEventKey.new()
	event.keycode = 0 if physical_only else code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = 0 if physical_only else code
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func wait_idle(limit := 1500) -> bool:
	for i in limit:
		if not level.walking and not level.turning: return true
		await process_frame
	check(false, "animation terminates within bounded time")
	return false

func turn_to(index: int) -> void:
	while level.view_index != index:
		check(level.turn_view(1), "normal quarter-turn accepted")
		await wait_idle()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	Engine.time_scale = 12.0
	level = Scene.instantiate()
	root.add_child(level)
	await frames(4)
	check(level.mode == "title" and not level.can_traverse(), "graceful title gates navigation")
	check(level.hud.title_group.visible and not level.hud.game_group.visible, "title and play screens are distinct")
	check(not level.turn_view(1) and not level.request_journey(), "title rejects in-level actions")
	check(level.audio.size() == 5, "all five sound assets loaded")
	var ambience: AudioStreamWAV = level.audio.ambience.stream
	check(ambience.loop_mode == AudioStreamWAV.LOOP_FORWARD and ambience.loop_end > 0, "ambient score loops")
	await key(KEY_M)
	check(level.muted and level.audio.turn.volume_db <= -80.0, "M mutes all feedback")
	await key(KEY_M, true)
	check(not level.muted, "physical-only key fallback unmutes")
	await key(KEY_SPACE)
	await frames(30)
	check(level.mode == "play" and level.hud.game_group.visible, "Space begins real play")
	check(not level.can_traverse(), "initial separated edges cannot be crossed")
	var initial_position: Vector3 = level.avatar.position
	await key(KEY_SPACE)
	check(level.avatar.position == initial_position and level.stage == 0, "invalid Space does not move or advance")
	# Validate the mathematical construction against live Camera3D projections.
	for i in 3:
		var fold: Dictionary = level.folds[i]
		var correct_angle: float = [Geometry.FIRST_VIEW, Geometry.SECOND_VIEW, Geometry.THIRD_VIEW][i]
		var difference: Vector3 = fold.b - fold.a
		check(absf(difference.length() - fold.distance) < 0.0001 and difference.length() > 3.7, "fold %d spans genuinely disconnected 3D endpoints" % (i + 1))
		check(difference.cross(Geometry.view_ray(correct_angle)).length() < 0.00001, "fold %d lies in orthographic projection nullspace" % (i + 1))
		level.yaw = correct_angle
		level.update_camera()
		check(level.alignment_error(i) < 0.02, "fold %d overlaps in actual camera projection" % (i + 1))
		level.yaw = correct_angle + PI / 2.0
		level.update_camera()
		check(level.alignment_error(i) > 80.0, "fold %d rejects another view" % (i + 1))
		level.yaw = correct_angle + 0.18
		level.update_camera()
		check(level.alignment_error(i) > 7.0, "fold %d does not use a canned view index" % (i + 1))
	level.reset_level()
	# View and screen bounds are enforced by actual geometry, independent of stage.
	level.yaw = Geometry.FIRST_VIEW
	level.update_camera()
	level.set_process(false)
	level.camera.look_at(level.camera.position + Vector3(1, 1, 1))
	check(is_inf(level.alignment_error()), "behind-camera endpoints rejected")
	level.update_camera()
	level.camera.h_offset = 100.0
	check(is_inf(level.alignment_error()), "offscreen endpoints rejected")
	level.set_process(true)
	level.reset_level()
	# Input, animation guards, and cancellation.
	await key(KEY_E)
	check(level.turning, "E starts animated rotation")
	check(not level.turn_view(1) and not level.request_journey(), "repeated turns and traversal locked during rotation")
	await wait_idle()
	check(level.view_index == 1 and level.can_traverse(), "rotation settles at first geometric seam")
	await key(KEY_SPACE)
	check(level.walking and not level.turn_view(-1), "Space follows route and locks camera")
	check(not level.request_journey(), "double activation cannot duplicate movement")
	await frames(5)
	await key(KEY_R)
	check(level.stage == 0 and not level.walking and level.avatar.position == Geometry.FIRST_A + Vector3(-2.8, 0, 0), "R cancels an active journey safely")
	await frames(80)
	check(level.stage == 0 and level.avatar.position == level.START, "cancelled journey cannot complete later")
	level.hud.toggle_help(true)
	var old_view: int = level.view_index
	await key(KEY_E)
	check(level.view_index == old_view and not level.turning, "help modal blocks world keyboard input")
	await key(KEY_ESCAPE)
	check(not level.hud.help_open, "Escape closes help")
	# Full ordinary route; test seam motion, completion, and a second complete replay.
	for play in 2:
		for expected_stage in 3:
			await turn_to([1, 2, 0][expected_stage])
			check(level.can_traverse(), "play %d stage %d is available only at seam" % [play + 1, expected_stage + 1])
			check(level.request_journey(), "ordinary journey starts")
			var seam_first := Vector2.ZERO
			var seam_world := Vector3.ZERO
			var saw_seam := false
			var seam_screen_motion := 0.0
			var seam_world_motion := 0.0
			for frame in 1800:
				if not level.walking: break
				if level.crossing:
					var projected: Vector2 = level.camera.unproject_position(level.avatar.position)
					if not saw_seam:
						seam_first = projected
						seam_world = level.avatar.position
						saw_seam = true
					seam_screen_motion = maxf(seam_screen_motion, projected.distance_to(seam_first))
					seam_world_motion = maxf(seam_world_motion, level.avatar.position.distance_to(seam_world))
				await process_frame
			check(saw_seam and seam_world_motion > 3.0 and seam_screen_motion < 0.03, "depth changes continuously while screen position is preserved")
			check(level.stage == expected_stage + 1 and level.avatar.position.distance_to(level.goals[expected_stage]) < 0.001, "arrival activates exactly one shrine at its real location")
		check(level.mode == "won" and level.stats.folds == 3, "three folds produce complete ending")
		check(level.hud.ending_group.visible and not level.hud.game_group.visible, "complete ending replaces gameplay HUD")
		check(not level.request_journey() and not level.turn_view(1), "ending rejects duplicate progress")
		await key(KEY_M)
		var mute_before_reset: bool = level.muted
		await key(KEY_R)
		check(level.mode == "play" and level.stage == 0 and level.stats.folds == 0 and level.view_index == 0, "replay restores progression, stats, and camera")
		check(level.muted == mute_before_reset, "restart preserves audio preference")
		check(level.avatar.position == level.START, "replay restores astronomer position")
	level.reset_level(true)
	check(level.mode == "title" and level.hud.title_group.visible, "return-to-title state is supported")
	print("RESULT: %d checks; %d failures" % [checks, failures])
	# Let the dummy audio backend release its playback buffers before shutdown.
	for player: AudioStreamPlayer in level.audio.values(): player.stop()
	Engine.time_scale = 1.0
	await create_timer(0.2).timeout
	level.queue_free()
	await frames(3)
	quit(0 if failures == 0 else 1)
