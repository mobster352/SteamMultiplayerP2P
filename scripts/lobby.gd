extends Control

@export var game:Game
@export var player_disconnected_banner: PlayerDisconnectedBanner

@onready var lobby_code_label: Label = %LobbyCodeLabel
@onready var join_lobby_code: LineEdit = %JoinLobbyCode
@onready var player_1: Label = %Player1
@onready var player_2: Label = %Player2
@onready var start_game_button: Button = %StartGameButton
@onready var leave_lobby_button: Button = %LeaveLobbyButton

#Google server
#const SERVER_IP:String = "35.196.2.247"
#Local server
const SERVER_IP:String = "192.168.0.100"
const SERVER_PORT:int = 7000

var lobby_owner_id: int
var lobby_owner: String

var steam_peer:SteamMultiplayerPeer

func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		return
	Steam.lobby_created.connect(_lobby_created)
	Steam.lobby_joined.connect(_lobby_joined)
	Steam.lobby_chat_update.connect(_lobby_chat_update)
	Steam.lobby_game_created.connect(_lobby_game_created)
	SteamworksBootstrap.steamworks.connected_to_steam_server.connect(connected_to_steam_server)
	NetworkManager.update_lobby_code.connect(_update_lobby_code)
	NetworkManager.join_host_lobby.connect(_join_host_lobby)
	NetworkManager.load_game.connect(_load_game)


func _on_multiplayer_button_pressed() -> void:
	if not SteamworksBootstrap.steamworks.connected:
		SteamworksBootstrap.steamworks.connect_to_steam_server(SERVER_IP, SERVER_PORT)


func connected_to_steam_server() -> void:
	if SteamworksBootstrap.steamworks.lobby_code:
		NetworkManager.close_lobby.rpc_id(1, SteamworksBootstrap.steamworks.lobby_code)
		SteamworksBootstrap.steamworks.lobby_id = 0
		SteamworksBootstrap.steamworks.lobby_code = ""


func is_in_steam_lobby() -> bool:
	if multiplayer.multiplayer_peer and multiplayer.multiplayer_peer is SteamMultiplayerPeer:
		return multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	return false


func is_in_lobby() -> bool:
	return SteamworksBootstrap.steamworks.lobby_id > 0


func _on_host_lobby_button_pressed() -> void:
	if not SteamworksBootstrap.steamworks.connected:
		return
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PRIVATE)


func _on_join_lobby_button_pressed() -> void:
	if not SteamworksBootstrap.steamworks.connected:
		return
	if join_lobby_code.text:
		NetworkManager.find_lobby.rpc_id(1, multiplayer.multiplayer_peer.get_unique_id(), join_lobby_code.text)


func _on_start_game_button_pressed() -> void:
	NetworkManager.update_is_game_running_for_lobby.rpc_id(1, SteamworksBootstrap.steamworks.lobby_code, true)
	await get_tree().create_timer(1.0).timeout
	steam_peer = SteamMultiplayerPeer.new() #this is when host disconnects from server
	var error = steam_peer.create_host()
	if error != Error.OK:
		push_error("Host could not create server")
		return
	multiplayer.multiplayer_peer = steam_peer
	if not multiplayer.peer_disconnected.is_connected(_peer_disconnected):
		multiplayer.peer_disconnected.connect(_peer_disconnected)
	Steam.setLobbyGameServer(SteamworksBootstrap.steamworks.lobby_id, "0", 0, Steam.getSteamID())
	hide()


func _lobby_created(_result:int, lobby_id:int) -> void:
	SteamworksBootstrap.steamworks.lobby_id = lobby_id
	NetworkManager.create_lobby_code.rpc_id(1, multiplayer.multiplayer_peer.get_unique_id(), lobby_id)
	start_game_button.show()
	leave_lobby_button.show()


func _lobby_joined(lobby_id:int, _permissions:int, _locked:bool, _response:int) -> void:
	print("Lobby joined: ", lobby_id)
	lobby_owner_id = Steam.getLobbyOwner(lobby_id)
	lobby_owner = Steam.getFriendPersonaName(lobby_owner_id)
	if Steam.getSteamID() == lobby_owner_id:
		player_1.text = Steam.getFriendPersonaName(Steam.getSteamID())
	else:
		player_1.text = lobby_owner
		player_2.text = Steam.getFriendPersonaName(Steam.getSteamID())
		NetworkManager.has_game_started.rpc_id(1, multiplayer.multiplayer_peer.get_unique_id(), SteamworksBootstrap.steamworks.lobby_code, lobby_owner_id)
	leave_lobby_button.show()


func _lobby_chat_update(lobby_id:int, changed_id:int, _making_change_id:int, chat_state:int) -> void:
	match chat_state:
		Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			player_2.text = Steam.getFriendPersonaName(changed_id)
			print(Steam.getFriendPersonaName(changed_id), " has joined the lobby with ID: ", lobby_id)
		Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_LEFT:
			player_disconnected_banner.update_player_name(Steam.getFriendPersonaName(changed_id))
			if changed_id == lobby_owner_id:
				leave_lobby(lobby_id)
			else:
				player_2.text = ""
			print(Steam.getFriendPersonaName(changed_id), " has disconnected from the lobby with ID: ", lobby_id)
		Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			player_disconnected_banner.update_player_name(Steam.getFriendPersonaName(changed_id))
			if changed_id == lobby_owner_id:
				leave_lobby(lobby_id)
			else:
				player_2.text = ""
			print(Steam.getFriendPersonaName(changed_id), " has disconnected from the lobby with ID: ", lobby_id)


func _update_lobby_code(lobby_code:String) -> void:
	SteamworksBootstrap.steamworks.lobby_code = lobby_code
	lobby_code_label.text = lobby_code


func _join_host_lobby(lobby_id:int) -> void:
	print("host joined: ", lobby_id)
	SteamworksBootstrap.steamworks.lobby_id = lobby_id
	Steam.joinLobby(SteamworksBootstrap.steamworks.lobby_id)


func _lobby_game_created(_lobby_id:int, server_id:int, _server_ip:String, _port:int) -> void:
	print("Lobby Code: ", SteamworksBootstrap.steamworks.lobby_code)
	if server_id == Steam.getSteamID():
		game.spawn_test_level(0)
		return
	load_peer_into_game(server_id)


func _load_game(server_id:int) -> void:
	load_peer_into_game(server_id)


func load_peer_into_game(server_id:int) -> void:
	steam_peer = SteamMultiplayerPeer.new() #this is when the peer disconnects from the server
	var error = steam_peer.create_client(server_id)
	if error != Error.OK:
		push_error("Client could not join host server")
		return
	multiplayer.multiplayer_peer = steam_peer
	if not multiplayer.connected_to_server.is_connected(_connected_to_host):
		multiplayer.connected_to_server.connect(_connected_to_host)
	if not multiplayer.peer_disconnected.is_connected(_peer_disconnected):
		multiplayer.peer_disconnected.connect(_peer_disconnected)
	print("Game server joined")
	hide()
	
	
func _connected_to_host() -> void:
	game.add_peer.rpc_id(1, multiplayer.multiplayer_peer.get_unique_id())


func _peer_disconnected(id:int) -> void:
	if multiplayer.multiplayer_peer.get_unique_id() == id or id == 1:
		multiplayer.connected_to_server.disconnect(_connected_to_host)
		multiplayer.peer_disconnected.disconnect(_peer_disconnected)
		show()
	if multiplayer.is_server() and game.test_level.player2:
		game.test_level.player2.queue_free()


func _process(_delta: float) -> void:
	if visible:
		return
	if Input.is_action_just_pressed("quit"):
		if multiplayer.is_server():
			for peer_id in multiplayer.get_peers():
				multiplayer.multiplayer_peer.disconnect_peer(peer_id)
			game.test_level.queue_free()
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()
		await get_tree().create_timer(1.0).timeout
		leave_lobby(SteamworksBootstrap.steamworks.lobby_id)
		show()


func leave_lobby(lobby_id:int) -> void:
	player_1.text = ""
	player_2.text = ""
	Steam.leaveLobby(lobby_id)
	lobby_owner_id = 0
	lobby_owner = ""
	lobby_code_label.text = ""
	join_lobby_code.text = ""
	start_game_button.hide()
	leave_lobby_button.hide()
	if Steam.getSteamID() == Steam.getLobbyOwner(SteamworksBootstrap.steamworks.lobby_id):
		print(SteamworksBootstrap.steamworks.connected)
		if not SteamworksBootstrap.steamworks.connected:
			_on_multiplayer_button_pressed()
			return
		NetworkManager.close_lobby.rpc_id(1, SteamworksBootstrap.steamworks.lobby_code)
	SteamworksBootstrap.steamworks.lobby_id = 0
	SteamworksBootstrap.steamworks.lobby_code = ""


func _on_leave_lobby_button_pressed() -> void:
	leave_lobby(SteamworksBootstrap.steamworks.lobby_id)
