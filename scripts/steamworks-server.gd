class_name SteamworksServer
extends Node

const APP_ID := 480

var game_port := 7000
var query_port := 27015


func _init() -> void:
	OS.set_environment("SteamAppId", str(APP_ID))
	OS.set_environment("SteamGameId", str(APP_ID))
	
func _ready() -> void:
	var result := SteamServer.serverInitEx("0.0.0.0", game_port, query_port, SteamServer.SERVER_MODE_AUTHENTICATION, "0.0.0.0")
	if result.status != SteamServer.STEAM_API_INIT_RESULT_OK:
		push_error("Steam server initialization failed: %s" % result)
		get_tree().quit(1)
		return
	print("Steam Server Initialized")
	SteamServer.setProduct(str(APP_ID))
	SteamServer.setGameDescription("Steam Multiplayer Test")
	SteamServer.setModDir("steammultiplayertest")
	SteamServer.setDedicatedServer(true)
	SteamServer.logOnAnonymous()
	SteamServer.initRelayNetworkAccess()
	SteamServer.run_callbacks()
	_start_server_host()


func _start_server_host() -> void:
	var steam_peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error := steam_peer.create_server(game_port, 2)
	if error != OK:
		push_error("Could not create Steam multiplayer host: %s" % error)
		return
	multiplayer.multiplayer_peer = steam_peer
	
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
	print("Steam multiplayer server started")
	print("Steam server multiplayer id: ", multiplayer.get_unique_id())

func _peer_connected(peer_id:int) -> void:
	print("Client connected with peer id: ", peer_id)
	
func _peer_disconnected(peer_id:int) -> void:
	print("Client disconnectedd with peer id: ", peer_id)
