extends Node

const PACKET_READ_LIMIT : int = 32

enum SendType {
	ALL,
	ALL_EXCLUSIVE,
	ONE
}
enum PacketType {
	HANDSHAKE,
	POSITION,
	LOOK_DIR,
	VOICE,
	LEAVE
}



var is_host : bool = false

var lobby_id : int = 0

var lobby_players : Array = []

var max_players = 4

var packet_number : int = 0

#var player_net_data := {
	#
#}

var voip_packet_number : int = 0

# NETWORK DEBUG SETTINGS
const PRINT_PACKET_DEBUG = true
const AUTO_SETUP = true
const AUTO_SETUP_FILE = "res://auto_join.dat"

const ARTIFICIAL_LATENCY = true
const PERCENT_PACKET_DROP = 20
const DELAY = 120.0
const VARIATION = 5.0

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_session_request)
	Debug.track(self, "ARTIFICIAL_LATENCY", false, "Artificial Latency Enabled")
	
	if ARTIFICIAL_LATENCY:
		Debug.track(self, "DELAY", false, "Ping (ms)")
		Debug.track(self, "VARIATION", false, "Ping Variation (ms)")
		Debug.track(self, "PERCENT_PACKET_DROP", false, "Packet Drop %")

func _process(delta: float) -> void:
	if lobby_id > 0:
		#print(Steam.getNumLobbyMembers(lobby_id))
		read_all_packets()

func create_lobby(type : Steam.LobbyType = Steam.LobbyType.LOBBY_TYPE_PUBLIC):
	if lobby_id == 0: 
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, max_players)

func join_lobby(id : int = -2):
	if id != -2:
		Steam.joinLobby(id)
	else:
		Steam.joinLobby(lobby_id)

func leave_lobby(id : int = -2):
	send_network_leave()
	#await get_tree().create_timer(1.0)
	if id != -2:
		Steam.leaveLobby(id)
	else:
		Steam.leaveLobby(lobby_id)

func _on_lobby_created(connect: int, id : int):
	if connect == 1:
		lobby_id = id
		Steam.setLobbyJoinable(lobby_id, true)
		
		Steam.setLobbyData(lobby_id, "name", Steam.getPersonaName() + "'s Lobby")
		Debug.push("lobby id: " + str(lobby_id), Debug.INFO)
		if AUTO_SETUP:
			var file = FileAccess.open(AUTO_SETUP_FILE, FileAccess.WRITE)
			file.store_var(lobby_id)
			file.close()
		else:
			DisplayServer.clipboard_set(str(lobby_id))
			
		var set_relay : bool = Steam.allowP2PPacketRelay(true)

func _on_lobby_joined(id : int, perms : int, locked : int, response : int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		#Global.update_voice_mode(Global.voice_mode)
		lobby_id = id
		get_lobby_players()
		send_network_handshake()
		Global.trans.switch_scene(Global.trans.start_level)
		Global.trans.fake_trans_to_level("from_black_one_way")


func _on_session_request(id):
	var requester : String = Steam.getFriendPersonaName(id)
	Steam.acceptP2PSessionWithUser(id)

func send_network_handshake():
	send(SendType.ALL, PacketType.HANDSHAKE, Global.steam_username, true)

func send_network_leave():
	print("leave")
	send(SendType.ALL_EXCLUSIVE, PacketType.LEAVE, Global.steam_username, true)

func get_lobby_players():
	lobby_players.clear()
	
	var num_players : int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(num_players):
		var steam_id : int = Steam.getLobbyMemberByIndex(lobby_id, i)
		var steam_username : String = Steam.getFriendPersonaName(steam_id)
		print(steam_username)
		lobby_players.append({"steam_id": steam_id, "steam_name": steam_username})
		
		#if not steam_id in player_net_data.keys():
			#player_net_data.get_or_add(steam_id, {
				#"prev_packet_num": { 
					#"LOOK_DIR" : 0,
					#"POSITION" : 0
				#},
				#"prev_packet_time": {
					#"LOOK_DIR" : 0.0,
					#"POSITION" : 0.0
				#}
			#})


func send(send_type : SendType, packet_type : PacketType, packet_data, reliable : bool, raw : bool = false, channel : int = 0, to_id : int = 0):
	if ARTIFICIAL_LATENCY and packet_type:
		if not reliable and randi_range(1, 100) <= PERCENT_PACKET_DROP:
			return
		await get_tree().create_timer(randf_range((DELAY - VARIATION)/1000.0, (DELAY + VARIATION)/1000.0)).timeout
	var packet
	#if raw:
		#packet = packet_data
	#else:
	match packet_type:
		PacketType.VOICE:
			packet = [voip_packet_number, Time.get_unix_time_from_system(), PacketType.keys()[int(packet_type)], packet_data]
			voip_packet_number += 1
		_:
			packet = [packet_number, Time.get_unix_time_from_system(), PacketType.keys()[int(packet_type)], packet_data]
	packet_number += 1
	
	var packet_bytes : PackedByteArray
	var send_method : Steam.P2PSend = Steam.P2PSend.P2P_SEND_RELIABLE if reliable else Steam.P2PSend.P2P_SEND_UNRELIABLE
	packet_bytes.append_array(var_to_bytes(packet))
	match send_type:
		SendType.ONE:
			Steam.sendP2PPacket(to_id, packet_bytes, send_method, channel)
		SendType.ALL:
			for player in lobby_players:
				Steam.sendP2PPacket(player["steam_id"], packet_bytes, send_method, channel)
		SendType.ALL_EXCLUSIVE:
			for player in lobby_players:
				if player["steam_id"] != Global.steam_id:
					Steam.sendP2PPacket(player["steam_id"], packet_bytes, send_method, channel)
		_:
			Debug.push("Packet send type invalid: " + str(send_type), Debug.ALERT)

func read_all_packets(channel : int = 0):
	var read_count : int = 0
	#print(Steam.getAvailableP2PPacketSize(channel))
	while read_count <= PACKET_READ_LIMIT and Steam.getAvailableP2PPacketSize(channel) > 0:
		read_packet(channel)
		read_count += 1

#func out_of_order(num : int, sender : int,  type : String):
	#var previous_packet_numbers = player_net_data[sender]["prev_packet_num"]
	#if num < previous_packet_numbers[type]:
		#return true
	#previous_packet_numbers[type] = num
	#return false

func read_packet(channel : int = 0):
	var packet_size = Steam.getAvailableP2PPacketSize(channel)
	if packet_size > 0:
		var packet : Dictionary = Steam.readP2PPacket(packet_size, channel)
		var sender : int = packet["remote_steam_id"] 
		var packet_data_raw = bytes_to_var(packet["data"])
		var packet_number = packet_data_raw[0]
		var packet_timestamp = packet_data_raw[1]
		var packet_type = packet_data_raw[2]
		var packet_data = packet_data_raw[3]
		
		#match typeof(packet_data_raw):
			#TYPE_ARRAY:
				#packet_type = packet_data_raw[0]
				#packet_data = packet_data_raw[1]
			#TYPE_PACKED_BYTE_ARRAY:
				#packet_type = "VOICE"
				#packet_data = packet_data_raw
			#
			#_:
				#printerr("Invalid Packet Type: ", typeof(packet_data_raw))
				#return
		if PRINT_PACKET_DEBUG: print(packet_type)
		match packet_type: # using this because enums dont get sent lol
			"HANDSHAKE":
				Debug.push("Player " + str(packet_data) + " joined!")
				get_lobby_players()
				if sender != Global.steam_id and not Global.get_puppet_player(sender):
					Global.create_puppet_player(sender)
			
			"LEAVE":
				Debug.push("Player " + str(packet_data) + " is no longer with us.")
				get_lobby_players()
				if sender != Global.steam_id:
					Global.remove_puppet_player(sender)
			
			"POSITION":
				#if out_of_order(packet_number, sender, "POSITION"): return
				#
				#var time_since_last_packet = Time.get_unix_time_from_system() - player_net_data[sender]["prev_packet_time"]["POSITION"]
				#player_net_data[sender]["prev_packet_time"]["POSITION"] = Time.get_unix_time_from_system()
				
				var puppet_player = Global.get_puppet_player(sender)
				if puppet_player:
					puppet_player.push_to_position_buffer(packet_data, packet_number, packet_timestamp)
					#puppet_player.update_position(packet_data, time_since_last_packet)
					#puppet_player.position = puppet_player.interpolate_position
					#puppet_player.pos_timer = 0.0
					#puppet_player.interpolate_position = packet_data
					#puppet_player.interpolate_position_time = time_since_last_packet
				else : Global.create_puppet_player(sender)
				
			"LOOK_DIR":
				#if out_of_order(packet_number, sender, "LOOK_DIR"): return
				
				#var time_since_last_packet = Time.get_unix_time_from_system() - player_net_data[sender]["prev_packet_time"]["LOOK_DIR"]
				#player_net_data[sender]["prev_packet_time"]["LOOK_DIR"] = Time.get_unix_time_from_system()
				
				var puppet_player = Global.get_puppet_player(sender)
				if puppet_player:
					puppet_player.push_to_rotation_buffer(packet_data, packet_number, packet_timestamp)
					#puppet_player.update_rotation(packet_data, time_since_last_packet)
					#puppet_player.rotation.y  = puppet_player.interpolate_rotation.x
					#puppet_player.get_node("Face").rotation.x = puppet_player.interpolate_rotation.y
					#puppet_player.rot_timer = 0.0
					#puppet_player.interpolate_rotation = Vector2(puppet_player.rotation.y, puppet_player.get_node("Face").rotation.x) - packet_data
					#puppet_player.interpolate_rotation_time = time_since_last_packet
				else : Global.create_puppet_player(sender)
				#
			
			"VOICE":
				var puppet_player = Global.get_puppet_player(sender)
				if puppet_player:
					puppet_player.process_voice_data(packet_data, packet_number)
				else : Global.create_puppet_player(sender)
			




func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("debug"):
		#leave_lobby()
	
	if event.is_action_pressed("invite") and lobby_id > 0:
		print("inv dialog")
		Steam.activateGameOverlayInviteDialog(lobby_id)
