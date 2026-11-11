class_name DialogueVoice
extends AudioStreamPlayer
## The "voice" of a character in dialogue: a short synthesized blip for every couple
## of letters, pitched per character (data/characters/npcs.json "voice"). No audio
## files and no credits. The full audio system arrives in 4.4.

const MIX_RATE: float = 22050.0
const BLIP_SECONDS: float = 0.045
const BASE_FREQ: float = 430.0

var pitch: float = 1.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.25
	stream = gen
	volume_db = -14.0
	play()


func _exit_tree() -> void:
	stop()


func blip() -> void:
	# Fetched each time (not kept in a variable) so nothing outlives the player.
	var pb := get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var frames: int = int(MIX_RATE * BLIP_SECONDS)
	if pb.get_frames_available() < frames:
		return
	var freq: float = BASE_FREQ * pitch * _rng.randf_range(0.9, 1.12)
	var phase: float = 0.0
	for i: int in frames:
		var t: float = float(i) / frames
		var env: float = minf(t * 12.0, 1.0) * (1.0 - t)
		phase += freq / MIX_RATE
		# Soft square wave: sine pushed towards square, friendlier than a pure beep.
		var s: float = clampf(sin(phase * TAU) * 2.2, -1.0, 1.0) * 0.35 * env
		pb.push_frame(Vector2(s, s))
