class_name Steamworks
extends Node

signal create_lobby
signal join_lobby

const APP_ID:int = 480

var lobby_id:int
var lobby_code:String

var connected:bool
var create:bool

func _init() -> void:
	OS.set_environment("SteamAppId", str(APP_ID))
	OS.set_environment("SteamGameId", str(APP_ID))


func _ready() -> void:
	var result:Dictionary = Steam.steamInitEx(APP_ID, true)
	if result.get("status") != 0:
		print("Steam Init Failed")
		print(result)
	else:
		print("Steam Initialized")


func connect_to_steam_server(ip:String, port:int, _create:bool) -> void:
	var steam_peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error := steam_peer.create_client(ip, port)
	if error != OK:
		push_error("Could not create Steam client: %s" % error)
		return
	multiplayer.multiplayer_peer = steam_peer
	
	if not multiplayer.connected_to_server.is_connected(_connected_to_server):
		multiplayer.connected_to_server.connect(_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_connection_failed):
		multiplayer.connection_failed.connect(_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_server_disconnected):
		multiplayer.server_disconnected.connect(_server_disconnected)
	
	print("Connecting to server...")
	create = _create
	
func _connected_to_server() -> void:
	print("Connected to Steam Server")
	connected = true
	if create:
		create_lobby.emit()
	else:
		join_lobby.emit()
	
func _connection_failed() -> void:
	push_error("Steam Server connection failed")

func _server_disconnected() -> void:
	print("Disconnected from Steam Server")
	connected = false
