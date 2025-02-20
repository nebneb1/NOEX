extends CharacterBody3D
var player_name : String = ""
var player_steam_id : int = 0
var debug = false
#var voip_playback : AudioStreamGeneratorPlayback
#var voip_playback_buffer : PackedByteArray = PackedByteArray()
var buffer: Array = []
#var pushed_frames_backup : Array = []
var frames_per_push : int = Global.voip_sample_rate * 0.1
var last_packet_number : int = -1
var audio_playing = false
@onready var playback_node: AudioStreamPlayer3D = $VOIPPlayback


func _ready() -> void:
	audio_stream = playback_node.stream
	$Sprite3D/SubViewport/Label.text = player_name
	#playback_node.stream.mix_rate = Global.voip_sample_rate
	#playback_node.play()
	#voip_playback = playback_node.get_stream_playback()
	Global.puppet_players.append(self)
	Global.menu.update_players()


func update_volume(volume : float):
	playback_node.volume_db = clamp(linear_to_db(volume), -INF, 10.0)
	

@onready var audio_stream : AudioStreamOpusChunked
var prev_pushed_paket_number = -1

func _process(delta):
	#print("qframes:", audio_stream.queue_length_frames())
	#print("getlen:", audio_stream.get_length())
	if debug: return
	if buffer.size() > 10:
		audio_playing = true
	
	elif buffer.size() == 0:
		audio_playing = false
	
	if audio_playing:
		var opus_packet = buffer.pop_front()
		while opus_packet:
			audio_stream.push_opus_packet(opus_packet[1], 0, 0)
			opus_packet = buffer.pop_front()
	#while audio_stream.chunk_space_available():
		#var opus_packet = buffer.pop_front()
		#if opus_packet:
			#prev_pushed_paket_number = opus_packet[0]
			#if opus_packet[0] == prev_pushed_paket_number + 1 or prev_pushed_paket_number == -1: 
				#audio_stream.push_opus_packet(opus_packet[1], 0, 0)
			#else:
				#audio_stream.push_opus_packet(opus_packet[1], 0, 1)
	#if jitter_buffer.size() < 10:
		#return
#
	#if voip_playback.get_frames_available() > frames_per_push:
		#var next_audio = jitter_buffer.pop_front()
#
		#for i in range(0, next_audio.size(), 2):
			#if i + 1 < next_audio.size():
				#var raw_value: int = next_audio[i] | (next_audio[i + 1] << 8)
				#raw_value = (raw_value + 32768) & 0xffff
				##if raw_value > 32767:
					##raw_value -= 65536
				##var amplitude: float = raw_value / 32768.0
				#var amplitude: float = float(raw_value - 32768) / 32768.0
				#
				#voip_playback.push_frame(Vector2(amplitude, amplitude))
				#var raw_value: int = voip_playback_buffer[0] | (voip_playback_buffer[1] << 8)
				#
				#var amplitude: float = float(raw_value - 32768) / 32768.0
				##print(amplitude)
				##voip_playback.push_frame(Vector2(amplitude, amplitude))
	#if voip_playback.get_frames_available() > 0:
		## Push up to 128 frames per update (tun	e this for latency/smoothness balance)
		#var frames_to_push = min(voip_playback.get_frames_available(), frames_per_push)
#
		#for _i in range(frames_to_push):
			#if voip_playback_queue.size() > 0:
				#voip_playback.push_frame(voip_playback_queue.pop_front())
			#else:
				#break  # No more buffered frames available
	#if voip_playback_queue.size() > frames_per_push:
		#var frames = voip_playback_queue.slice(0, frames_per_push)
		#voip_playback_queue = voip_playback_queue.slice(frames_per_push, voip_playback_queue.size())
		#pushed_frames_backup.append_array(frames)
	#
	#if pushed_frames_backup.size() > 0:
		#var to_push = min(voip_playback.get_frames_available(), frames_per_push)
		#for i in range(to_push):
			#if pushed_frames_backup.size() > 0:
				#voip_playback.push_frame(pushed_frames_backup.pop_front())
			#else:
				#break  # No more buffered frames available

func sort_ascending(a, b):
	return a[0] < b[0]

func delete():
	Global.puppet_players.erase(self)
	Global.menu.update_players()
	queue_free()

func process_voice_data(voice_data: PackedByteArray, packet_number : int) -> void:
	if debug: return
	buffer.append([packet_number, voice_data])
	buffer.sort_custom(sort_ascending)
	
	#if packet_number <= last_packet_number: # toss old data
		#return
	#
	#last_packet_number = packet_number
	#
	#var decompressed_voice: Dictionary = Steam.decompressVoice(voice_data, Global.voip_sample_rate)
	##print(decompressed_voice['result'])
	#
	#if decompressed_voice['result'] == Steam.VOICE_RESULT_OK and decompressed_voice['uncompressed'].size() > 0:
		#print("Decompressed voice: %s" % decompressed_voice['size'])
		#jitter_buffer.append(decompressed_voice['uncompressed'])
		#voip_playback_buffer = decompressed_voice['uncompressed']
		#voip_playback_buffer.resize(decompressed_voice['uncompressed'].size())
		
		#for i: int in range(0, mini(voip_playback.get_frames_available() * 2, voip_playback_buffer.size()), 2):
			#var raw_value: int = voip_playback_buffer[0] | (voip_playback_buffer[1] << 8)
			#raw_value = (raw_value + 32768) & 0xffff
			#var amplitude: float = float(raw_value - 32768) / 32768.0
			##print(amplitude)
			##voip_playback.push_frame(Vector2(amplitude, amplitude))
			#voip_playback_queue.append(Vector2(amplitude, amplitude))
			#voip_playback_buffer.remove_at(0)
			#voip_playback_buffer.remove_at(0)
