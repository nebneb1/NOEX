extends Node

const PACKET_READ_LIMIT : int = 32

enum SendType {
	ALL,
	ALL_EXCLUSIVE,
	ONE
}
enum PacketType {
	HANDSHAKE,
	TRANSFORM,
	VOICE
}

var is_host : bool = false
var lobby_id : int = 0
var lobby_players : Array = []
var max_players = 4

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_session_request)

func _process(delta: float) -> void:
	if lobby_id > 0:
		read_all_packets()


func create_lobby(type : Steam.LobbyType = Steam.LobbyType.LOBBY_TYPE_PUBLIC):
	print("hi")
	if lobby_id == 0: 
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, max_players)

func join_lobby(id : int):
	print("called")
	Steam.joinLobby(id)

func _on_lobby_created(connect: int, id : int):
	print("FRICK ", connect)
	if connect == 1:
		lobby_id = id
		Steam.setLobbyJoinable(lobby_id, true)
		
		Steam.setLobbyData(lobby_id, "name", Steam.getPersonaName() + "'s Lobby")
		print(lobby_id)
		var set_relay : bool = Steam.allowP2PPacketRelay(true)

func _on_lobby_joined(id : int, perms : int, locked : int, response : int):
	print("signal", response)
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("success")
		lobby_id = id
		get_lobby_players()
		send_network_handshake()
	
	

func _on_session_request(id):
	var requester : String = Steam.getFriendPersonaName(id)
	Steam.acceptP2PSessionWithUser(id)

func send_network_handshake():
	send(SendType.ALL, PacketType.HANDSHAKE, Global.steam_username, true)

func get_lobby_players():
	print("lobbyplrsran")
	lobby_players.clear()
	
	var num_players : int = Steam.getNumLobbyMembers(lobby_id)
	print("num", num_players)
	for i in range(num_players):
		var steam_id : int = Steam.getLobbyMemberByIndex(lobby_id, i)
		var steam_username : String = Steam.getFriendPersonaName(steam_id)
		print(steam_username)
		lobby_players.append({"steam_id": steam_id, "steam_name": steam_username})

func send(send_type : SendType, packet_type : PacketType, packet_data, reliable : bool, channel : int = 0, to_id : int = 0):
	print("SENT")
	var packet : Array = [packet_type, packet_data]
	var packet_bytes : PackedByteArray
	var send_method : Steam.P2PSend = Steam.P2PSend.P2P_SEND_RELIABLE if reliable else Steam.P2PSend.P2P_SEND_RELIABLE
	packet_bytes.append_array(var_to_bytes(packet))
	print(send_type)
	match send_type:
		SendType.ONE:
			print("got to here!1")
			Steam.sendP2PPacket(to_id, packet_bytes, send_method, channel)
		SendType.ALL:
			print("got to here!2")
			print("plrs ", lobby_players)
			for player in lobby_players:
				Steam.sendP2PPacket(player["steam_id"], packet_bytes, send_method, channel)
		SendType.ALL_EXCLUSIVE:
			for player in lobby_players:
				print("got to here!3")
				if player["steam_id"] != Global.steam_id:
					Steam.sendP2PPacket(player["steam_id"], packet_bytes, send_method, channel)
		_:
			print("send invalid", send_type)



func read_all_packets(channel : int = 0):
	var read_count : int = 0
	while read_count >= PACKET_READ_LIMIT and Steam.getAvailableP2PPacketSize(channel) > 0:
		print("reading acket")
		read_packet(channel)
		read_count += 1

func read_packet(channel : int = 0):
	var packet_size = Steam.getAvailableP2PPacketSize(channel)
	print("reading acket 2")
	if packet_size > 0:
		print("reading acket 3")
		var packet : Dictionary = Steam.readP2PPacket(packet_size, channel)
		var sender : int = packet["remote_steam_id"] 
		var packet_data_raw : Array = bytes_to_var(packet["data"])
		var packet_type = packet_data_raw[0]
		var packet_data = packet_data_raw[1]
		
		match packet_data[0]:
			PacketType.HANDSHAKE:
				print("Player ", str(packet_data), " joined!")
				get_lobby_players()
			PacketType.TRANSFORM:
				pass
			PacketType.VOICE:
				pass
