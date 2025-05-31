extends AudioStreamPlayer

#var voip_input_buffer : PackedByteArray = PackedByteArray()
#var voip_input_playback : AudioStreamGeneratorPlayback

var record_effect : AudioEffectOpusChunked
var vol_effect : AudioEffectSpectrumAnalyzerInstance

func _ready() -> void:
	record_effect = AudioServer.get_bus_effect(AudioServer.get_bus_index("Chunked"), 0)
	#stream.mix_rate = Global.voip_sample_rate
	
	
	#play()
	#voip_input_playback = get_stream_playback()
	#Steam.startVoiceRecording()
	#

func _process(_delta: float):
	
	process_voice()



func process_voice() -> void:
	var prepend = PackedByteArray()
	
	while record_effect.chunk_available():
		var opusdata : PackedByteArray = record_effect.read_opus_packet(prepend)
		record_effect.drop_chunk()
		if true or Global.mic_vol > Settings.voice_threshold:
			Net.send(Net.SendType.ALL_EXCLUSIVE, Net.PacketType.VOICE, opusdata, false)
	
	
	#var stereo_data : PackedVector2Array = record_effect.get_buffer(record_effect.get_frames_available())
	#if stereo_data.size() > 0:
		#print(stereo_data.size())
	#var available_voice: Dictionary = Steam.getAvailableVoice()
	#Steam.getVoiceOptimalSampleRate()
	#if available_voice["result"] == Steam.VOICE_RESULT_OK and available_voice["buffer"] > 0:
		#var voice_data: Dictionary = Steam.getVoice()
		#if voice_data["result"] == Steam.VOICE_RESULT_OK and voice_data["written"]:
			#print("Voice message has data: %s" % voice_data["written"])
			#Net.send(Net.SendType.ALL_EXCLUSIVE, Net.PacketType.VOICE, voice_data["buffer"], false, true)
			#if has_loopback:
				#print("Loopback on")
				#process_voice_data(voice_data, "local")
