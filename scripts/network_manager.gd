extends Node

signal update_lobby_code(lobby_code:String)
signal join_host_lobby(lobby_id:int)
signal load_game(server_id:int)

## Has a mapping of {unique code:steam lobby}[br][br]
var active_lobbies:Dictionary[String, Dictionary]
#var active_hosts:Dictionary

func _generate_lobby_code() -> String:
	var random_code:int = randi_range(100000,999999)
	var code:String = str(random_code)
	if active_lobbies.has(code):
		code = _generate_lobby_code()
	return code

@rpc("any_peer")
func create_lobby_code(peer:int, lobby_id:int) -> void:
	var dict:Dictionary = {
		"lobby_id": lobby_id,
		"is_game_running": false
	}
	var code:String = _generate_lobby_code()
	active_lobbies.set(code, dict)
	#Steam.setLobbyData(lobby_id, "lobby_code", code)
	send_lobby_code.rpc_id(peer, code)

@rpc
func send_lobby_code(lobby_code:String) -> void:
	update_lobby_code.emit(lobby_code)

@rpc("any_peer")
func find_lobby(peer:int, lobby_code:String) -> void:
	if active_lobbies.has(lobby_code):
		send_lobby_id.rpc_id(peer, active_lobbies.get(lobby_code).get("lobby_id"), lobby_code)

@rpc
func send_lobby_id(lobby_id:int, lobby_code:String) -> void:
	join_host_lobby.emit(lobby_id)
	update_lobby_code.emit(lobby_code)

@rpc("any_peer")
func update_is_game_running_for_lobby(lobby_code:String, is_game_running:bool) -> void:
	if active_lobbies.has(lobby_code):
		active_lobbies.get(lobby_code).set("is_game_running", is_game_running)
		print("set is_game_running: ", is_game_running)

@rpc("any_peer")
func has_game_started(peer:int, lobby_code:String, server_id:int) -> void:
	if active_lobbies.has(lobby_code):
		var is_game_running:bool = active_lobbies.get(lobby_code).get("is_game_running")
		print("is game running: ", is_game_running)
		if is_game_running:
			load_peer_into_game.rpc_id(peer, server_id)

@rpc
func load_peer_into_game(server_id:int) -> void:
	load_game.emit(server_id)
