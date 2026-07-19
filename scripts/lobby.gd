extends Control

@export var game:Game

@onready var lobby_code_label: Label = %LobbyCodeLabel
@onready var join_lobby_code: LineEdit = %JoinLobbyCode
@onready var player_1: Label = %Player1
@onready var player_2: Label = %Player2
@onready var start_game_button: Button = %StartGameButton


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
	SteamworksBootstrap.steamworks.create_lobby.connect(_create_lobby)
	SteamworksBootstrap.steamworks.join_lobby.connect(_join_lobby)
	NetworkManager.update_lobby_code.connect(_update_lobby_code)
	NetworkManager.join_host_lobby.connect(_join_host_lobby)


func _on_host_lobby_button_pressed() -> void:
	if not SteamworksBootstrap.steamworks.connected:
		SteamworksBootstrap.steamworks.connect_to_steam_server(SERVER_IP, SERVER_PORT, true)
	else:
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PRIVATE)


func _on_join_lobby_button_pressed() -> void:
	if not SteamworksBootstrap.steamworks.connected:
		SteamworksBootstrap.steamworks.connect_to_steam_server(SERVER_IP, SERVER_PORT, false)
	else:
		_join_lobby()


func _on_start_game_button_pressed() -> void:
	steam_peer = SteamMultiplayerPeer.new()
	var error = steam_peer.create_host()
	if error != Error.OK:
		push_error("Host could not create server")
		return
	multiplayer.multiplayer_peer = steam_peer
	print(multiplayer.multiplayer_peer.get_unique_id())
	Steam.setLobbyGameServer(SteamworksBootstrap.steamworks.lobby_id, "0", 0, Steam.getSteamID())
	hide()


func _lobby_created(_result:int, lobby_id:int) -> void:
	SteamworksBootstrap.steamworks.lobby_id = lobby_id
	NetworkManager.create_lobby_code.rpc_id(1, multiplayer.multiplayer_peer.get_unique_id(), lobby_id)
	start_game_button.show()


func _lobby_joined(lobby_id:int, _permissions:int, _locked:bool, _response:int) -> void:
	print("Lobby joined: ", lobby_id)
	lobby_owner_id = Steam.getLobbyOwner(lobby_id)
	lobby_owner = Steam.getFriendPersonaName(lobby_owner_id)
	if Steam.getSteamID() == lobby_owner_id:
		player_1.text = Steam.getFriendPersonaName(Steam.getSteamID())
	else:
		player_1.text = lobby_owner
		player_2.text = Steam.getFriendPersonaName(Steam.getSteamID())


func _lobby_chat_update(lobby_id:int, changed_id:int, _making_change_id:int, chat_state:int) -> void:
	match chat_state:
		Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			player_2.text = Steam.getFriendPersonaName(changed_id)
		Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_LEFT:
			if changed_id == lobby_owner_id:
				player_1.text = ""
				player_2.text = ""
				Steam.leaveLobby(lobby_id)
				lobby_owner_id = 0
				lobby_owner = ""
				lobby_code_label.text = ""
				start_game_button.hide()
			else:
				player_2.text = ""
		Steam.ChatMemberStateChange.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			if changed_id == lobby_owner_id:
				player_1.text = ""
				player_2.text = ""
				Steam.leaveLobby(lobby_id)
				lobby_owner_id = 0
				lobby_owner = ""
				lobby_code_label.text = ""
				start_game_button.hide()
			else:
				player_2.text = ""


func _create_lobby() -> void:
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PRIVATE)
	

func _join_lobby() -> void:
	if join_lobby_code.text:
		NetworkManager.find_lobby.rpc_id(1, multiplayer.multiplayer_peer.get_unique_id(), join_lobby_code.text)


func _update_lobby_code(lobby_code:String) -> void:
	SteamworksBootstrap.steamworks.lobby_code = lobby_code
	lobby_code_label.text = lobby_code


func _join_host_lobby(lobby_id:int) -> void:
	print("host joined: ", lobby_id)
	SteamworksBootstrap.steamworks.lobby_id = lobby_id
	Steam.joinLobby(SteamworksBootstrap.steamworks.lobby_id)


func _lobby_game_created(_lobby_id:int, server_id:int, _server_ip:String, _port:int) -> void:
	if server_id == Steam.getSteamID():
		return
	steam_peer = SteamMultiplayerPeer.new()
	var error = steam_peer.create_client(server_id)
	if error != Error.OK:
		push_error("Client could not join host server")
		return
	multiplayer.multiplayer_peer = steam_peer
	multiplayer.connected_to_server.connect(_connected_to_host)
	print("Game server joined")
	hide()


func _connected_to_host() -> void:
	player_2_connected.rpc(multiplayer.multiplayer_peer.get_unique_id())


@rpc("any_peer")
func player_2_connected(peer:int) -> void:
	game.spawn_test_level(peer)
