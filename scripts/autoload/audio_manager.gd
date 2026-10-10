class_name AudioManagerClass
extends Node

var _player_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 6

var _sfx_cache: Dictionary = {}

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_player_pool.append(p)
	
	_pregenerate_sounds()

func _pregenerate_sounds() -> void:
	_sfx_cache["tap"] = _generate_tone(520.0, 0.04, 0.25)
	_sfx_cache["merge"] = _generate_chord([440.0, 660.0, 880.0], 0.18, 0.35)
	_sfx_cache["invalid"] = _generate_tone(160.0, 0.08, 0.2)
	_sfx_cache["game_over"] = _generate_sweep(380.0, 180.0, 0.35, 0.3)
	_sfx_cache["milestone"] = _generate_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.32, 0.35)
	
	for length in range(1, 10):
		var freq: float = 392.0 * pow(1.05946, (length - 1) * 2)
		_sfx_cache["select_" + str(length)] = _generate_tone(freq, 0.07, 0.28)

func play_tap() -> void:
	_play_sfx("tap")

func play_select(chain_length: int) -> void:
	var key := "select_" + str(clampi(chain_length, 1, 9))
	_play_sfx(key)

func play_merge() -> void:
	_play_sfx("merge")

func play_invalid() -> void:
	_play_sfx("invalid")

func play_game_over() -> void:
	_play_sfx("game_over")

func play_milestone() -> void:
	_play_sfx("milestone")

func _play_sfx(key: String) -> void:
	if not _is_sound_enabled():
		return
	if not _sfx_cache.has(key):
		return
	
	var stream: AudioStreamWAV = _sfx_cache[key]
	var player := _get_available_player()
	if player:
		player.stream = stream
		player.play()

func _is_sound_enabled() -> bool:
	if Engine.has_singleton("SettingsManager"):
		var sm = Engine.get_singleton("SettingsManager")
		if "sound_enabled" in sm:
			return sm.sound_enabled
	# Autoload node access
	var sm_node := get_node_or_null("/root/SettingsManager")
	if sm_node and "sound_enabled" in sm_node:
		return sm_node.sound_enabled
	return true

func _get_available_player() -> AudioStreamPlayer:
	for p in _player_pool:
		if not p.playing:
			return p
	return _player_pool[0]

func _generate_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = 1.0 - (float(i) / float(total_samples))
		envelope = envelope * envelope # Quadratic decay
		var sample: float = sin(2.0 * PI * freq * t) * envelope * volume
		var int_sample: int = clampi(int(sample * 32767.0), -32768, 32767)
		var byte_idx: int = i * 2
		buffer.encode_s16(byte_idx, int_sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = buffer
	return wav

func _generate_chord(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	var count: float = float(freqs.size())
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var envelope: float = 1.0 - (float(i) / float(total_samples))
		envelope = envelope * envelope
		var sample: float = 0.0
		for f in freqs:
			sample += sin(2.0 * PI * float(f) * t)
		sample = (sample / count) * envelope * volume
		var int_sample: int = clampi(int(sample * 32767.0), -32768, 32767)
		buffer.encode_s16(i * 2, int_sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = buffer
	return wav

func _generate_sweep(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	var phase: float = 0.0
	
	for i in range(total_samples):
		var frac: float = float(i) / float(total_samples)
		var freq: float = lerpf(freq_start, freq_end, frac)
		phase += 2.0 * PI * freq / float(sample_rate)
		var envelope: float = 1.0 - frac
		var sample: float = sin(phase) * envelope * volume
		var int_sample: int = clampi(int(sample * 32767.0), -32768, 32767)
		buffer.encode_s16(i * 2, int_sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = buffer
	return wav

func _generate_arpeggio(notes: Array, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var note_count: int = notes.size()
	var samples_per_note: int = total_samples / note_count
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	for n in range(note_count):
		var freq: float = float(notes[n])
		var start_i: int = n * samples_per_note
		var end_i: int = mini(total_samples, (n + 1) * samples_per_note)
		for i in range(start_i, end_i):
			var local_i: int = i - start_i
			var t: float = float(i) / float(sample_rate)
			var env: float = 1.0 - (float(local_i) / float(samples_per_note))
			var sample: float = sin(2.0 * PI * freq * t) * env * volume
			var int_sample: int = clampi(int(sample * 32767.0), -32768, 32767)
			buffer.encode_s16(i * 2, int_sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = buffer
	return wav
