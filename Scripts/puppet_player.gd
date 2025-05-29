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

const BUFFER_ACTIVATE_THRESHOLD = 10
const MAX_DELTA = 0.2
const EPSILON = 0.001

var position_buffer_last_time : float = -1.0
var position_save : Vector3
var position_interpolate_timer = 0.0
var position_idle_timer = 0.0
var position_buffer = []
var read_position_buffer : bool = false

var rotation_buffer_last_time : float = -1.0
var rotation_save : Vector2
var rotation_interpolate_timer = 0.0
var rotation_idle_timer = 0.0
var rotation_buffer = []
var read_rotation_buffer : bool = false
#var interpolate_position : Vector3
#var interpolate_position_time : float
#var interpolate_rotation : Vector2
#var interpolate_rotation_time : float
#var pos_timer : float = 0.0
#var rot_timer : float = 0.0

@onready var playback_node: AudioStreamPlayer3D = $VOIPPlayback


func _ready() -> void:
	position_save = position
	audio_stream = playback_node.stream
	$Sprite3D/SubViewport/Label.text = player_name
	#playback_node.stream.mix_rate = Global.voip_sample_rate
	#playback_node.play()
	#voip_playback = playback_node.get_stream_playback()
	Global.puppet_players.append(self)
	Global.menu.update_players()
	Debug.track(self, "position_buffer", false, "Buffer")
	Debug.track(self, "position_interpolate_timer")
	Debug.track(self, "position_buffer_last_time")
	Debug.track(self, "position_save")
	Debug.track(self, "position_buffer")
	#Debug.track(self, "interpolate_rotation", true)
	#Debug.track(self, "rotation.y", true, "horizontal")
	#Debug.track($Face, "rotation.x", true, "vertical")
	#Debug.track(self, "rot_timer", true)
	#Debug.track(self, "interpolate_position", true)
	#Debug.track(self, "position", true)
	#Debug.track(self, "pos_timer", true)

func push_to_position_buffer(location : Vector3, order : int, time : float):
	if position_buffer_last_time < 0:
		position_buffer_last_time = time
		return
	
	if time - position_buffer_last_time > 0:
		position_buffer.append([order, location, time - position_buffer_last_time])
		position_buffer.sort_custom(sort_ascending)
		position_buffer_last_time = time
		
	#else:
		#Debug.push("Non-trashed, out-of-order packet?? WHAT, skipping", Debug.WARN)


func push_to_rotation_buffer(rot : Vector2, order : int, time : float):
	if rotation_buffer_last_time < 0:
		rotation_buffer_last_time = time
		return
	
	if time - rotation_buffer_last_time > 0:
		rotation_buffer.append([order, rot, time - rotation_buffer_last_time])
		rotation_buffer.sort_custom(sort_ascending)
		rotation_buffer_last_time = time

func update_volume(volume : float):
	playback_node.volume_db = clamp(linear_to_db(volume), -INF, 10.0)

#func update_position(packet_data : Vector3, packet_time : float):
	#position = interpolate_position
	#pos_timer = 0.0
	#interpolate_position = packet_data
	#interpolate_position_time = packet_time
#
#func update_rotation(packet_data : Vector2, packet_time : float):
	#rotation.y  = interpolate_rotation.x
	#$Face.rotation.x = interpolate_rotation.y
	#rot_timer = 0.0
	#interpolate_rotation = Vector2(rotation.y, $Face.rotation.x) - packet_data
	#interpolate_rotation_time = packet_time


@onready var audio_stream : AudioStreamOpusChunked
var prev_pushed_paket_number = -1

func _physics_process(delta: float) -> void:
	pass

func _process(delta):
	if position_buffer.size() >= BUFFER_ACTIVATE_THRESHOLD:
		read_position_buffer = true
	
	elif position_buffer.size() == 0:
		read_position_buffer = false
	
	elif not read_position_buffer:
		position_idle_timer += delta
		if position_idle_timer > MAX_DELTA:
			read_position_buffer = true
			
	else:
		position_idle_timer = 0.0
	
	if read_position_buffer:
		if position_buffer[0][2] > MAX_DELTA:
			position_buffer.pop_front()
			
		if position_buffer.size() != 0:
			var curr_buffer = position_buffer[0]
			
			if position_interpolate_timer < curr_buffer[2]:
				position = position_save.lerp(curr_buffer[1], clamp(position_interpolate_timer / curr_buffer[2], 0.0, 1.0))  
			#
			else:
				position_save = position
				position_interpolate_timer -= curr_buffer[2]
				position_buffer.pop_front()
			
			position_interpolate_timer += delta
	
	if rotation_buffer.size() >= BUFFER_ACTIVATE_THRESHOLD:
		read_rotation_buffer = true
	
	elif rotation_buffer.size() == 0:
		read_rotation_buffer = false
	
	elif not read_rotation_buffer:
		rotation_idle_timer += delta
		if rotation_idle_timer > MAX_DELTA:
			read_rotation_buffer = true
			
	else:
		rotation_idle_timer = 0.0
	
	if read_rotation_buffer:
		if rotation_buffer[0][2] > MAX_DELTA:
			rotation_buffer.pop_front()
			
		if rotation_buffer.size() != 0:
			var curr_buffer = rotation_buffer[0]
			
			if rotation_interpolate_timer < curr_buffer[2]:
				var rot = rotation_save.lerp(curr_buffer[1], clamp(rotation_interpolate_timer / curr_buffer[2], 0.0, 1.0))
				rotation.y = rot.x
				$Face.rotation.x = rot.y
			#
			else:
				rotation_save = Vector2(rotation.y, $Face.rotation.x)
				rotation_interpolate_timer -= curr_buffer[2]
				rotation_buffer.pop_front()
			
			rotation_interpolate_timer += delta
	
	#if pos_timer < interpolate_position_time:
		#position += (position-interpolate_position).normalized()*delta*interpolate_position_time
		#pos_timer += delta
	#else:
		#position = interpolate_position
	#
	#if rot_timer < interpolate_rotation_time:
		#rotation.y += interpolate_rotation.x * delta * interpolate_rotation_time
		#$Face.rotation.x = interpolate_rotation.y * delta * interpolate_rotation_time
		#rot_timer += delta
	#else:
		#rotation.y = interpolate_rotation.x
		#$Face.rotation.x = interpolate_rotation.y
	
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
