extends Node
## Licensed sample playback, never oscillator-generated effects or drone loops.
const CUES := {
	"grab":["foley/bookFlip2.ogg",-8.0],
	"snap":["foley/bookPlace1.ogg",-18.0],
	"pin":["kenney/click_005.ogg",-18.0],
	"invalid":["kenney/click_001.ogg",-30.0],
	"seam":["kenney/glass_005.ogg",-20.0],
	"arrive":["kenney/glass_004.ogg",-22.0],
	"wood0":["foley/footstep_wood_000.ogg",-15.0],
	"wood1":["foley/footstep_wood_001.ogg",-15.0],
	"wood2":["foley/footstep_wood_002.ogg",-15.0],
	"creak0":["foley/creak1.ogg",-16.0],
	"creak1":["foley/creak2.ogg",-16.0],
	"slide":["foley/cloth1.ogg",-18.0]
}
const NOTE_GAIN := {"C4":11.0,"E4":11.0,"G4":17.5,"C5":8.3}
var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var cursor := 0
var muted := false
var bus_index := -1
var cadence: Tween
func _ready() -> void:
	bus_index = AudioServer.get_bus_index("LetterSamples")
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count-1
		AudioServer.set_bus_name(bus_index,"LetterSamples")
		var lowpass := AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = 6500
		AudioServer.add_bus_effect(bus_index,lowpass)
		var room := AudioEffectReverb.new()
		room.room_size = .45
		room.wet = .12
		room.dry = .9
		AudioServer.add_bus_effect(bus_index,room)
	for i in range(10):
		var voice := AudioStreamPlayer.new()
		voice.bus = "LetterSamples"
		add_child(voice)
		voices.append(voice)
	for cue in CUES: streams[cue] = load("res://assets/audio/"+CUES[cue][0])
	for note in ["C4","E4","G4","C5"]: streams[note] = load("res://assets/audio/meta-piano/INSPiano_Vel01_%s_01.ogg" % note)
func play(cue: String) -> void:
	if not streams.has(cue): return
	voice(streams[cue],CUES[cue][1] if CUES.has(cue) else NOTE_GAIN.get(cue,-20.0))
func voice(stream: AudioStream, gain: float) -> void:
	var player := voices[cursor%voices.size()]
	cursor += 1
	player.stream = stream
	player.volume_db = gain
	player.play()
func milestone(final := false) -> void:
	if is_instance_valid(cadence): cadence.kill()
	cadence = create_tween()
	for note in (["C4","E4","G4","C5"] if final else ["C4","G4"]):
		cadence.tween_callback(func(): play(note))
		cadence.tween_interval(.14)
func toggle() -> void:
	muted = not muted
	AudioServer.set_bus_mute(bus_index,muted)
func stop() -> void:
	if is_instance_valid(cadence): cadence.kill()
	for player in voices: player.stop()
func _exit_tree() -> void: stop()
